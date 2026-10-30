import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Where the player is in their career (onboarding's second question).
enum Experience { student, freshGraduate, earlyCareer, switchingCareers }

/// The kind of role the player is aiming for (onboarding's third question).
enum TargetRole { product, design, data, engineering, marketing, notSure }

/// What the player told us in onboarding, and their two play settings. Nothing here is ever
/// sent as an analytics property except as an enum or a number (docs/rules/analytics.md); the
/// name never leaves the device until brief 08 syncs the profile to the player's own row.
class PlayerProfile {
  const PlayerProfile({
    this.firstName,
    this.experience,
    this.targetRole,
    this.nervesLevel,
    this.calmMode = false,
    this.weeklyGoal,
    this.autoAdvance = true,
    this.onboarded = false,
  });

  /// Null when the player chose "call me Candidate".
  final String? firstName;
  final Experience? experience;
  final TargetRole? targetRole;

  /// 1 (calm) to 5 (very nervous); null when skipped.
  final int? nervesLevel;

  /// No answer timer, ever (FR-13). Onboarding turns it on at nerves 4–5.
  final bool calmMode;

  /// Sessions a week the player means to play; null when skipped.
  final int? weeklyGoal;

  /// Interviewer lines move on by themselves 6 s after they finish typing.
  final bool autoAdvance;

  /// Onboarding is done: launches go straight to the Tower.
  final bool onboarded;

  /// What interviewers call the player.
  String get displayName => firstName ?? fallbackName;

  static const String fallbackName = 'Candidate';

  /// The nerves level from which onboarding turns calm mode on.
  static const int calmFrom = 4;

  PlayerProfile copyWith({
    String? Function()? firstName,
    Experience? Function()? experience,
    TargetRole? Function()? targetRole,
    int? Function()? nervesLevel,
    bool? calmMode,
    int? Function()? weeklyGoal,
    bool? autoAdvance,
    bool? onboarded,
  }) => PlayerProfile(
    firstName: firstName == null ? this.firstName : firstName(),
    experience: experience == null ? this.experience : experience(),
    targetRole: targetRole == null ? this.targetRole : targetRole(),
    nervesLevel: nervesLevel == null ? this.nervesLevel : nervesLevel(),
    calmMode: calmMode ?? this.calmMode,
    weeklyGoal: weeklyGoal == null ? this.weeklyGoal : weeklyGoal(),
    autoAdvance: autoAdvance ?? this.autoAdvance,
    onboarded: onboarded ?? this.onboarded,
  );
}

/// Where the profile is kept. [LocalProfileRepository] keeps it on the device; brief 08 syncs
/// it to Supabase behind this same interface. No sign-up: the silent guest is the only account.
abstract interface class ProfileRepository {
  /// The stored profile, or a fresh one (not onboarded) on first launch.
  Future<PlayerProfile> load();

  Future<void> save(PlayerProfile profile);
}

/// The profile in `shared_preferences`, one key per field.
class LocalProfileRepository implements ProfileRepository {
  LocalProfileRepository([SharedPreferencesAsync? prefs])
    : _prefs = prefs ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _prefs;

  static const String _prefix = 'profile.';
  static const String _name = '${_prefix}first_name';
  static const String _experience = '${_prefix}experience';
  static const String _role = '${_prefix}target_role';
  static const String _nerves = '${_prefix}nerves_level';
  static const String _calm = '${_prefix}calm_mode';
  static const String _goal = '${_prefix}weekly_goal';
  static const String _autoAdvance = '${_prefix}auto_advance';
  static const String _onboarded = '${_prefix}onboarded';

  @override
  Future<PlayerProfile> load() async => PlayerProfile(
    firstName: await _prefs.getString(_name),
    experience: _byName(Experience.values, await _prefs.getString(_experience)),
    targetRole: _byName(TargetRole.values, await _prefs.getString(_role)),
    nervesLevel: await _prefs.getInt(_nerves),
    calmMode: await _prefs.getBool(_calm) ?? false,
    weeklyGoal: await _prefs.getInt(_goal),
    autoAdvance: await _prefs.getBool(_autoAdvance) ?? true,
    onboarded: await _prefs.getBool(_onboarded) ?? false,
  );

  @override
  Future<void> save(PlayerProfile p) async {
    await _setOrRemove(_name, p.firstName, _prefs.setString);
    await _setOrRemove(_experience, p.experience?.name, _prefs.setString);
    await _setOrRemove(_role, p.targetRole?.name, _prefs.setString);
    await _setOrRemove(_nerves, p.nervesLevel, _prefs.setInt);
    await _setOrRemove(_goal, p.weeklyGoal, _prefs.setInt);
    await _prefs.setBool(_calm, p.calmMode);
    await _prefs.setBool(_autoAdvance, p.autoAdvance);
    await _prefs.setBool(_onboarded, p.onboarded);
  }

  Future<void> _setOrRemove<T extends Object>(
    String key,
    T? value,
    Future<void> Function(String, T) set,
  ) => value == null ? _prefs.remove(key) : set(key, value);

  // A value from an older build that no longer names a case reads as unanswered.
  static T? _byName<T extends Enum>(List<T> values, String? name) {
    for (final v in values) {
      if (v.name == name) return v;
    }
    return null;
  }
}

/// The profile for this run only: tests, and anywhere the device store isn't wanted.
class InMemoryProfileRepository implements ProfileRepository {
  InMemoryProfileRepository([this._profile = const PlayerProfile()]);

  PlayerProfile _profile;

  @override
  Future<PlayerProfile> load() async => _profile;

  @override
  Future<void> save(PlayerProfile profile) async => _profile = profile;
}

/// The profile store. Overridden by brief 08 (sync) and in tests.
final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => LocalProfileRepository(),
);

/// The player's profile, loaded once and saved on every change.
final profileProvider = AsyncNotifierProvider<ProfileNotifier, PlayerProfile>(
  ProfileNotifier.new,
);

class ProfileNotifier extends AsyncNotifier<PlayerProfile> {
  @override
  Future<PlayerProfile> build() => ref.read(profileRepositoryProvider).load();

  /// Applies [change] to the profile and stores it.
  Future<void> change(PlayerProfile Function(PlayerProfile) change) async {
    final next = change(await future);
    state = AsyncData(next);
    await ref.read(profileRepositoryProvider).save(next);
  }
}
