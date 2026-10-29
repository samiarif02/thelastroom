import { test } from 'node:test'
import assert from 'node:assert/strict'
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { fileURLToPath } from 'node:url'
import { canonical, checkMigration, checkRls, MIGRATIONS_DIR } from './check-rls.mjs'

const REPO = fileURLToPath(new URL('..', import.meta.url))

const LOCKED = `
create table public.notes (id uuid primary key, user_id uuid not null);
alter table public.notes enable row level security;
create policy "notes: owner selects" on public.notes for select using (auth.uid() = user_id);
`

function withMigrations(files, fn) {
	const dir = mkdtempSync(join(tmpdir(), 'check-rls-'))
	try {
		mkdirSync(join(dir, MIGRATIONS_DIR), { recursive: true })
		for (const [name, sql] of Object.entries(files)) writeFileSync(join(dir, MIGRATIONS_DIR, name), sql)
		return fn(dir)
	} finally {
		rmSync(dir, { recursive: true, force: true })
	}
}

test("this repo's migrations pass", () => {
	const r = checkRls(REPO)
	assert.deepEqual(r.errors, [])
	assert.ok(r.tables.includes('public.profiles') && r.tables.includes('public.mission_attempts'))
})

test('a table with RLS and a policy passes', () => {
	assert.deepEqual(checkMigration('m.sql', LOCKED), { tables: ['public.notes'], errors: [] })
})

test('fails on a table without RLS', () => {
	const sql = 'create table notes (id uuid);\ncreate policy p on notes for select using (true);\n'
	assert.match(checkMigration('m.sql', sql).errors.join('\n'), /creates public\.notes without `alter table/)
})

test('fails on a table with RLS but no policy', () => {
	const sql = 'create table notes (id uuid);\nalter table notes enable row level security;\n'
	assert.match(checkMigration('m.sql', sql).errors.join('\n'), /without a `create policy/)
})

test('RLS enabled in a later migration does not count: the table was open in between', () => {
	withMigrations(
		{
			'1_create.sql': 'create table notes (id uuid);',
			'2_lock.sql': 'alter table notes enable row level security;\ncreate policy p on notes using (true);'
		},
		(dir) => assert.equal(checkRls(dir).errors.length, 2)
	)
})

test('a commented-out enable does not count', () => {
	const sql = 'create table notes (id uuid);\n-- alter table notes enable row level security;\n/* create policy p on notes using (true); */'
	assert.equal(checkMigration('m.sql', sql).errors.length, 2)
})

test("another table's RLS does not cover this one", () => {
	const sql = `${LOCKED}\ncreate table if not exists public.other (id uuid);\n`
	assert.equal(checkMigration('m.sql', sql).errors.length, 2)
})

test('fails on disable row level security anywhere', () => {
	const sql = `${LOCKED}\nalter table public.notes disable row level security;\n`
	assert.match(checkMigration('m.sql', sql).errors.join('\n'), /disables row level security/)
})

test('names match across schema-qualified, bare and quoted spellings, case-insensitively', () => {
	assert.equal(canonical('notes'), 'public.notes')
	assert.equal(canonical('Public.Notes'), 'public.notes')
	assert.equal(canonical('"public"."notes"'), 'public.notes')
	const sql = 'CREATE TABLE "public"."notes" (id uuid);\nALTER TABLE ONLY notes ENABLE ROW LEVEL SECURITY;\nCREATE POLICY p ON public.notes USING (true);'
	assert.deepEqual(checkMigration('m.sql', sql).errors, [])
})

test('temporary tables are session-local and skipped', () => {
	assert.deepEqual(checkMigration('m.sql', 'create temp table scratch (id int);'), { tables: [], errors: [] })
})

test('fails rather than passing on nothing to check', () => {
	withMigrations({}, (dir) => assert.match(checkRls(dir).errors.join(), /found no \.sql migrations/))
	withMigrations({ '1_fn.sql': 'create function f() returns int language sql as $$ select 1 $$;' }, (dir) =>
		assert.match(checkRls(dir).errors.join(), /found no `create table`/)
	)
})
