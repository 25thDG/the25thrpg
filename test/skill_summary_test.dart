import 'package:flutter_test/flutter_test.dart';
import 'package:the25thrpg/features/player/domain/entities/skill_summary.dart';
import 'package:the25thrpg/features/player/presentation/widgets/skill_radar_chart.dart';

void main() {
  group('mindfulness level', () {
    test('meditation minutes alone use the 2,000 min target', () {
      // sqrt(2000)/sqrt(2000) * 100 = 100
      const s = SkillSummary(
        skill: SkillId.mindfulness,
        lifetimeMinutes: 2000,
      );
      expect(s.level, 100);
    });

    test('clean days add one level per ten days', () {
      const none = SkillSummary(skill: SkillId.mindfulness, lifetimeMinutes: 500);
      const withClean = SkillSummary(
        skill: SkillId.mindfulness,
        lifetimeMinutes: 500,
        cleanDays: 40,
      );
      expect(withClean.cleanDayBonus, 4.0);
      expect(withClean.level, none.level + 4);
    });

    test('clean-day bonus is capped at +30', () {
      const s = SkillSummary(skill: SkillId.mindfulness, cleanDays: 900);
      expect(s.cleanDayBonus, 30.0);
    });

    test('only mindfulness earns a clean-day bonus', () {
      const s = SkillSummary(skill: SkillId.japanese, cleanDays: 100);
      expect(s.cleanDayBonus, 0);
    });

    test('mastery ignores the clean-day bonus', () {
      // 500 meditation min is far below the 2,000 target, so no mastery even
      // though clean days push the raw level past 100.
      const s = SkillSummary(
        skill: SkillId.mindfulness,
        lifetimeMinutes: 500,
        cleanDays: 900,
      );
      expect(s.mastery, 0);
    });

    test('mastery adds one point per 200 min beyond the target', () {
      const s = SkillSummary(
        skill: SkillId.mindfulness,
        lifetimeMinutes: 2600,
      );
      expect(s.mastery, 3);
    });
  });

  group('sobriety', () {
    const s = SkillSummary(
      skill: SkillId.mindfulness,
      cleanDays: 35,
      relapseDays: 36,
      cleanStreak: 0,
      longestCleanStreak: 8,
      daysSinceLastCleanLog: 47,
    );

    test('clean rate is over logged days only', () {
      expect(s.loggedCleanDays, 71);
      expect((s.cleanRate * 100).round(), 49);
    });

    test('a lapse in logging is not a broken streak', () {
      expect(s.isCleanLogStale, isTrue);
    });

    test('logging today or yesterday is not stale', () {
      const fresh = SkillSummary(
        skill: SkillId.mindfulness,
        cleanDays: 5,
        daysSinceLastCleanLog: 1,
      );
      expect(fresh.isCleanLogStale, isFalse);
    });

    test('no logs at all is not stale', () {
      const empty = SkillSummary(skill: SkillId.mindfulness);
      expect(empty.isCleanLogStale, isFalse);
      expect(empty.cleanRate, 0);
    });
  });

  group('japanese pace', () {
    test('7d average beating the 30d average is a positive delta', () {
      // 350 min over 7 days = 50/day; 900 over 30 days = 30/day.
      const s = SkillSummary(
        skill: SkillId.japanese,
        last7DaysMinutes: 350,
        last30DaysMinutes: 900,
      );
      expect(s.avg7PerDay, 50);
      expect(s.avg30PerDay, 30);
      expect(s.paceDeltaPerDay, 20);
    });

    test('a quiet week reads as a negative delta', () {
      const s = SkillSummary(
        skill: SkillId.japanese,
        last7DaysMinutes: 0,
        last30DaysMinutes: 900,
      );
      expect(s.paceDeltaPerDay, -30);
      expect(s.hasPaceData, isTrue);
    });

    test('no recent sessions means no pace to report', () {
      const s = SkillSummary(skill: SkillId.japanese, lifetimeMinutes: 9475);
      expect(s.hasPaceData, isFalse);
    });
  });

  group('eta to next level', () {
    test('days are derived from the 30-day pace', () {
      // 158h lifetime → Lv 26. Reaching Lv 27 needs (27/100)^2 * 2200 = 160.4h,
      // so ~2.4h to go. At 60 min/day that is ~3 days.
      const s = SkillSummary(
        skill: SkillId.japanese,
        lifetimeMinutes: 9480, // 158h
        last30DaysMinutes: 1800, // 60 min/day
      );
      expect(s.level, 26);
      expect(s.nextLevel, 27);
      expect(s.daysToNextLevel, 3);
    });

    test('no recent pace means no eta', () {
      const s = SkillSummary(
        skill: SkillId.japanese,
        lifetimeMinutes: 9480,
        last30DaysMinutes: 0,
      );
      expect(s.minutesToNextLevel, greaterThan(0));
      expect(s.daysToNextLevel, isNull);
    });

    test('wealth has no time-based eta', () {
      const s = SkillSummary(
        skill: SkillId.wealth,
        currentNetWorthEur: 9100,
      );
      expect(s.minutesToNextLevel, isNull);
      expect(s.daysToNextLevel, isNull);
    });

    test('a maxed skill has no next level', () {
      const s = SkillSummary(
        skill: SkillId.japanese,
        lifetimeMinutes: 2200 * 60,
        last30DaysMinutes: 1800,
      );
      expect(s.level, 100);
      expect(s.minutesToNextLevel, isNull);
    });

    test('mindfulness eta accounts for the clean-day bonus', () {
      // Clean days already supply 5 levels, so less meditation is needed.
      const withClean = SkillSummary(
        skill: SkillId.mindfulness,
        lifetimeMinutes: 110,
        cleanDays: 50,
        last30DaysMinutes: 300,
      );
      const without = SkillSummary(
        skill: SkillId.mindfulness,
        lifetimeMinutes: 110,
        last30DaysMinutes: 300,
      );
      expect(withClean.level, greaterThan(without.level));
      expect(withClean.minutesToNextLevel, isNotNull);
    });
  });

  group('radar axis', () {
    test('zooms to the next multiple of ten above the best skill', () {
      expect(
        radarAxisMax(const [
          SkillSummary(skill: SkillId.japanese, lifetimeMinutes: 9480), // Lv 26
          SkillSummary(skill: SkillId.wealth, currentNetWorthEur: 9100), // Lv 9
        ]),
        30,
      );
    });

    test('never zooms tighter than ten', () {
      expect(radarAxisMax(const [SkillSummary(skill: SkillId.wealth)]), 10);
    });

    test('caps at one hundred', () {
      expect(
        radarAxisMax(const [
          SkillSummary(skill: SkillId.japanese, lifetimeMinutes: 2200 * 60),
        ]),
        100,
      );
    });

    test('a lower axis separates skills more than the full 0-100 scale', () {
      const jp = SkillSummary(skill: SkillId.japanese, lifetimeMinutes: 9480);
      const wealth = SkillSummary(skill: SkillId.wealth, currentNetWorthEur: 9100);
      final axis = radarAxisMax(const [jp, wealth]);
      final gapZoomed = (jp.level - wealth.level) / axis;
      final gapFullScale = (jp.level - wealth.level) / 100;
      expect(gapZoomed, greaterThan(gapFullScale));
    });
  });

}
