import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_last_room/core/profile/profile_repository.dart';

/// The device store, in memory: one map shared by every repository built on it, like the
/// real store across a relaunch.
class _FakePrefs implements SharedPreferencesAsync {
  final Map<String, Object> values = {};

  @override
  Future<String?> getString(String key) async => values[key] as String?;
  @override
  Future<int?> getInt(String key) async => values[key] as int?;
  @override
  Future<bool?> getBool(String key) async => values[key] as bool?;
  @override
  Future<void> setString(String key, String value) async => values[key] = value;
  @override
  Future<void> setInt(String key, int value) async => values[key] = value;
  @override
  Future<void> setBool(String key, bool value) async => values[key] = value;
  @override
  Future<void> remove(String key) async => values.remove(key);

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakePrefs device;
  setUp(() => device = _FakePrefs());

  test(
    'a first launch reads a fresh profile: not onboarded, auto-advance on',
    () async {
      final p = await LocalProfileRepository(device).load();
      expect(p.onboarded, isFalse);
      expect(p.autoAdvance, isTrue);
      expect(p.calmMode, isFalse);
      expect(p.displayName, PlayerProfile.fallbackName);
    },
  );

  test('every field survives a save and a fresh load (a relaunch)', () async {
    const saved = PlayerProfile(
      firstName: 'Sami',
      experience: Experience.freshGraduate,
      targetRole: TargetRole.product,
      nervesLevel: 4,
      calmMode: true,
      weeklyGoal: 3,
      autoAdvance: false,
      onboarded: true,
    );
    await LocalProfileRepository(device).save(saved);
    final p = await LocalProfileRepository(device).load();
    expect(p.firstName, 'Sami');
    expect(p.experience, Experience.freshGraduate);
    expect(p.targetRole, TargetRole.product);
    expect(p.nervesLevel, 4);
    expect(p.calmMode, isTrue);
    expect(p.weeklyGoal, 3);
    expect(p.autoAdvance, isFalse);
    expect(p.onboarded, isTrue);
  });

  test('clearing a field removes it', () async {
    final repo = LocalProfileRepository(device);
    await repo.save(const PlayerProfile(firstName: 'Sami', weeklyGoal: 3));
    await repo.save(const PlayerProfile());
    final p = await repo.load();
    expect(p.firstName, isNull);
    expect(p.weeklyGoal, isNull);
  });

  test('copyWith can clear a nullable field', () {
    const p = PlayerProfile(firstName: 'Sami');
    expect(p.copyWith(firstName: () => null).firstName, isNull);
    expect(p.copyWith(autoAdvance: false).firstName, 'Sami');
  });
}
