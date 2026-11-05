-- Issue 74, from the security audit of 2026-11-05.
--
-- 1. A global daily AI budget. claim_ai_score() counts 30 a day per player, but a player id is
--    free to mint (anonymous sign-in), so the per-player cap alone doesn't bound what the one
--    shared Gemini key spends. private.ai_score_budget counts units per UTC day across everyone,
--    checked in the same atomic claim: a built answer is 1 unit, a voice answer 3 (it sends
--    audio). The player's own 30 a day count units the same way (30 built answers, or 10 voice
--    ones), so one minted id can take at most 30 of the budget. Past the budget every claim is refused and the app shows its offline score, as for a
--    player's own spent quota. The real fix for minted ids is captcha on anonymous sign-in (an
--    owner step in the dashboard, docs/scale-and-security.md); this caps the damage.
--    public.claim_ai_score() keeps its signature (1 unit) for functions deployed before this;
--    public.claim_ai_score(p_units) is the new form (1-3 units).
-- 2. first_name is cleaned on the server: control, zero-width and bidirectional-override
--    characters are stripped before the row is written (a trigger, so an old app build's sync
--    still lands rather than being refused). It is shown to other players on the leaderboard.
--
-- RLS and a policy on the new table in this migration (docs/rules/migrations.md rule 1).
-- Tests: supabase/tests/ai_budget_and_names.test.sql.

-- 1. The budget.
create table private.ai_score_budget (
  day date primary key,
  used integer not null check (used >= 0)
);

comment on table private.ai_score_budget is 'AI units used per UTC day by all players; written only by private.claim_ai_units().';

alter table private.ai_score_budget enable row level security;

-- Never read or written by a client (the private schema isn't exposed either): only the
-- security-definer claim touches it.
create policy "ai_score_budget: no client access"
  on private.ai_score_budget for all to authenticated
  using (false)
  with check (false);

revoke all on table private.ai_score_budget from public, anon, authenticated;

-- Takes [p_units] of the caller's 30 daily units and of today's budget, atomically: true when
-- both had room (and counts them), false when either is spent (and counts neither).
-- 42501 with no signed-in user; 22023 for units outside 1-3.
create function private.claim_ai_units(p_units integer)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  daily_limit constant integer := 30;
  -- About 1,000 built answers and 700 voice answers a day; see docs/scale-and-security.md.
  global_daily_units constant integer := 3000;
  caller uuid := auth.uid();
  today date := (now() at time zone 'utc')::date;
  claimed integer;
begin
  if caller is null then
    raise exception 'not signed in' using errcode = '42501';
  end if;
  if p_units is null or p_units not between 1 and 3 then
    raise exception 'units are 1-3' using errcode = '22023';
  end if;
  insert into public.ai_score_usage as u (user_id, day, used)
  values (caller, today, p_units)
  on conflict (user_id, day) do update
    set used = u.used + p_units
    where u.used + p_units <= daily_limit
  returning used into claimed;
  if claimed is null then
    return false;
  end if;
  insert into private.ai_score_budget as b (day, used)
  values (today, p_units)
  on conflict (day) do update
    set used = b.used + p_units
    where b.used + p_units <= global_daily_units
  returning used into claimed;
  if claimed is null then
    -- The day's budget is spent: give the player's units back.
    update public.ai_score_usage
    set used = used - p_units
    where user_id = caller and day = today;
    return false;
  end if;
  return true;
end;
$$;

revoke all on function private.claim_ai_units(integer) from public, anon, authenticated;

create or replace function public.claim_ai_score()
returns boolean
language sql
security definer
set search_path = ''
as $$
  select private.claim_ai_units(1);
$$;

create function public.claim_ai_score(p_units integer)
returns boolean
language sql
security definer
set search_path = ''
as $$
  select private.claim_ai_units(p_units);
$$;

revoke all on function public.claim_ai_score(integer) from public, anon;
grant execute on function public.claim_ai_score(integer) to authenticated;

-- 2. Clean names.
create function private.clean_first_name()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.first_name := nullif(
    btrim(regexp_replace(
      new.first_name,
      '[\u0001-\u001F\u007F-\u009F\u00AD\u061C\u180E\u200B-\u200F\u202A-\u202E\u2060-\u2069\uFEFF]',
      '',
      'g'
    )),
    ''
  );
  return new;
end;
$$;

revoke all on function private.clean_first_name() from public;

create trigger profiles_clean_first_name
  before insert or update of first_name on public.profiles
  for each row execute function private.clean_first_name();

-- Names already stored are cleaned the same way.
update public.profiles
set first_name = first_name
where first_name ~ '[\u0001-\u001F\u007F-\u009F\u00AD\u061C\u180E\u200B-\u200F\u202A-\u202E\u2060-\u2069\uFEFF]';
