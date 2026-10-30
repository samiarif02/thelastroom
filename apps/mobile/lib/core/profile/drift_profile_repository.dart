import '../db/app_database.dart';
import '../sync/outbox.dart';
import 'profile_repository.dart';

/// [ProfileRepository] on the device's database. Every save queues the profile for the server
/// in the same transaction; reads never touch the network (the server is a backup only).
class DriftProfileRepository implements ProfileRepository {
  DriftProfileRepository(this._db, {this.legacy, this._signal});

  final AppDatabase _db;
  final OutboxSignal? _signal;

  /// Brief 13's `shared_preferences` store: read once, on a database with no profile yet, so a
  /// player who onboarded before this store existed isn't asked again.
  final ProfileRepository? legacy;

  @override
  Future<PlayerProfile> load() async {
    final stored = await read(_db);
    if (stored != null) return stored;
    final carried = await legacy?.load();
    if (carried == null || !_hasAnswers(carried)) return const PlayerProfile();
    await save(carried);
    return carried;
  }

  @override
  Future<void> save(PlayerProfile profile) async {
    await _db.transaction(() async {
      await write(_db, profile);
      await Outbox(_db).add(OutboxKind.profile, Outbox.profileRef);
    });
    _signal?.ping();
  }

  static bool _hasAnswers(PlayerProfile p) =>
      p.onboarded || p.firstName != null || p.nervesLevel != null;

  /// The stored profile, or null before the first save.
  static Future<PlayerProfile?> read(AppDatabase db) async {
    final row = await db
        .customSelect('select * from profile where id = 1')
        .getSingleOrNull();
    if (row == null) return null;
    final waitlist = row.readNullable<int>('chapter_2_waitlist_at');
    return PlayerProfile(
      firstName: row.readNullable<String>('first_name'),
      experience: enumByName(
        Experience.values,
        row.readNullable<String>('experience'),
      ),
      targetRole: enumByName(
        TargetRole.values,
        row.readNullable<String>('target_role'),
      ),
      nervesLevel: row.readNullable<int>('nerves_level'),
      calmMode: row.read<int>('calm_mode') == 1,
      weeklyGoal: row.readNullable<int>('weekly_goal'),
      autoAdvance: row.read<int>('auto_advance') == 1,
      onboarded: row.read<int>('onboarded') == 1,
      waitlistJoinedAt: waitlist == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(waitlist, isUtc: true),
    );
  }

  /// Writes [p] as the one profile row, without queuing it (the restore uses this directly).
  static Future<void> write(
    AppDatabase db,
    PlayerProfile p,
  ) => db.customStatement(
    'insert into profile (id, first_name, experience, target_role, nerves_level, calm_mode, '
    'weekly_goal, auto_advance, onboarded, chapter_2_waitlist_at) '
    'values (1, ?, ?, ?, ?, ?, ?, ?, ?, ?) on conflict (id) do update set '
    'first_name = excluded.first_name, experience = excluded.experience, '
    'target_role = excluded.target_role, nerves_level = excluded.nerves_level, '
    'calm_mode = excluded.calm_mode, weekly_goal = excluded.weekly_goal, '
    'auto_advance = excluded.auto_advance, onboarded = excluded.onboarded, '
    'chapter_2_waitlist_at = excluded.chapter_2_waitlist_at',
    [
      p.firstName,
      p.experience?.name,
      p.targetRole?.name,
      p.nervesLevel,
      if (p.calmMode) 1 else 0,
      p.weeklyGoal,
      if (p.autoAdvance) 1 else 0,
      if (p.onboarded) 1 else 0,
      p.waitlistJoinedAt?.millisecondsSinceEpoch,
    ],
  );
}
