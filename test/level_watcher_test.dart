import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the25thrpg/core/progression/level_watcher.dart';
import 'package:the25thrpg/features/player/domain/entities/player_stats.dart';
import 'package:the25thrpg/features/player/domain/entities/skill_summary.dart';

/// Mindfulness level is exactly cleanDays / 10 when no meditation is logged,
/// which makes it the easiest skill to dial to a chosen level.
PlayerStats statsWith({required int mindfulnessLevel, int questXp = 0}) {
  return PlayerStats(
    skills: [
      const SkillSummary(skill: SkillId.japanese),
      const SkillSummary(skill: SkillId.wealth),
      SkillSummary(
        skill: SkillId.mindfulness,
        cleanDays: mindfulnessLevel * 10,
      ),
      SkillSummary(skill: SkillId.resolve, questXp: questXp),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LevelWatcher.instance.reset();
  });

  test('the first ever check records a baseline and celebrates nothing', () async {
    final events = await LevelWatcher.instance.check(statsWith(mindfulnessLevel: 12));
    expect(events, isEmpty);
  });

  test('a level gained since the last check is reported', () async {
    await LevelWatcher.instance.check(statsWith(mindfulnessLevel: 12));
    final events = await LevelWatcher.instance.check(statsWith(mindfulnessLevel: 13));

    final mind = events.firstWhere((e) => e.skill == SkillId.mindfulness);
    expect(mind.from, 12);
    expect(mind.to, 13);
    expect(mind.gained, 1);
  });

  test('nothing is reported when no level moved', () async {
    await LevelWatcher.instance.check(statsWith(mindfulnessLevel: 12));
    final events = await LevelWatcher.instance.check(statsWith(mindfulnessLevel: 12));
    expect(events, isEmpty);
  });

  test('the same gain is not celebrated twice', () async {
    await LevelWatcher.instance.check(statsWith(mindfulnessLevel: 12));
    await LevelWatcher.instance.check(statsWith(mindfulnessLevel: 13));
    final again = await LevelWatcher.instance.check(statsWith(mindfulnessLevel: 13));
    expect(again, isEmpty);
  });

  test('several levels at once are reported as one jump', () async {
    // Backfilling a long session can cross more than one level.
    await LevelWatcher.instance.check(statsWith(mindfulnessLevel: 10));
    final events = await LevelWatcher.instance.check(statsWith(mindfulnessLevel: 14));

    final mind = events.firstWhere((e) => e.skill == SkillId.mindfulness);
    expect(mind.gained, 4);
  });

  test('a level going down is recorded silently, never celebrated', () async {
    await LevelWatcher.instance.check(statsWith(mindfulnessLevel: 20));
    final down = await LevelWatcher.instance.check(statsWith(mindfulnessLevel: 15));
    expect(down, isEmpty);

    // And the lower value became the new baseline, so recovering to 16 is a
    // gain rather than being swallowed by the old high-water mark.
    final up = await LevelWatcher.instance.check(statsWith(mindfulnessLevel: 16));
    expect(up.any((e) => e.skill == SkillId.mindfulness && e.to == 16), isTrue);
  });

  test('the player level is reported last, after the skill that caused it', () async {
    await LevelWatcher.instance.check(statsWith(mindfulnessLevel: 10));
    final events = await LevelWatcher.instance.check(statsWith(mindfulnessLevel: 40));

    expect(events.length, greaterThan(1));
    expect(events.first.isPlayer, isFalse);
    expect(events.last.isPlayer, isTrue);
  });

  test('reset re-baselines instead of firing on the next check', () async {
    await LevelWatcher.instance.check(statsWith(mindfulnessLevel: 10));
    await LevelWatcher.instance.reset();

    final events = await LevelWatcher.instance.check(statsWith(mindfulnessLevel: 30));
    expect(events, isEmpty);
  });
}
