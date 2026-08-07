import 'package:flutter_test/flutter_test.dart';
import 'package:the25thrpg/features/player/domain/entities/skill_summary.dart';
import 'package:the25thrpg/features/quests/domain/entities/quest.dart';

Quest _quest({
  QuestStatus status = QuestStatus.active,
  List<QuestObjective> objectives = const [],
  DateTime? createdAt,
  DateTime? targetDate,
  String? rewardText,
  int? rewardCostCents,
  DateTime? rewardClaimedAt,
  DateTime? completedAt,
}) =>
    Quest(
      id: 'q1',
      title: 'Test quest',
      xpReward: 400,
      difficulty: QuestDifficulty.epic,
      status: status,
      objectives: objectives,
      createdAt: createdAt ?? DateTime.now().subtract(const Duration(days: 50)),
      targetDate: targetDate,
      rewardText: rewardText,
      rewardCostCents: rewardCostCents,
      rewardClaimedAt: rewardClaimedAt,
      completedAt: completedAt,
    );

List<QuestObjective> _objectives(int total, int done) => List.generate(
      total,
      (i) => QuestObjective(id: '$i', text: 'm$i', completed: i < done),
    );

void main() {
  group('quest deadline', () {
    test('counts whole days to the target date', () {
      final q = _quest(
        targetDate: DateTime.now().add(const Duration(days: 40)),
      );
      expect(q.daysLeft, 40);
    });

    test('goes negative once overdue', () {
      final q = _quest(
        targetDate: DateTime.now().subtract(const Duration(days: 3)),
      );
      expect(q.daysLeft, -3);
    });

    test('no target date means no countdown', () {
      expect(_quest().daysLeft, isNull);
      expect(_quest().timeElapsedFraction, isNull);
    });
  });

  group('quest pace', () {
    test('milestones ahead of the clock read as on track', () {
      // Half the window gone, three quarters of the milestones done.
      final q = _quest(
        createdAt: DateTime.now().subtract(const Duration(days: 50)),
        targetDate: DateTime.now().add(const Duration(days: 50)),
        objectives: _objectives(4, 3),
      );
      expect(q.pace, QuestPace.onTrack);
    });

    test('milestones lagging the clock read as behind', () {
      // 80% of the window gone, a quarter of the milestones done.
      final q = _quest(
        createdAt: DateTime.now().subtract(const Duration(days: 80)),
        targetDate: DateTime.now().add(const Duration(days: 20)),
        objectives: _objectives(4, 1),
      );
      expect(q.pace, QuestPace.behind);
    });

    test('past the target date is overdue regardless of milestones', () {
      final q = _quest(
        createdAt: DateTime.now().subtract(const Duration(days: 100)),
        targetDate: DateTime.now().subtract(const Duration(days: 1)),
        objectives: _objectives(4, 4),
      );
      expect(q.pace, QuestPace.overdue);
    });

    test('a fresh quest is not instantly behind', () {
      final q = _quest(
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        targetDate: DateTime.now().add(const Duration(days: 180)),
        objectives: _objectives(6, 0),
      );
      expect(q.pace, QuestPace.onTrack);
    });

    test('a completed quest has nothing left to judge', () {
      final q = _quest(
        status: QuestStatus.completed,
        createdAt: DateTime.now().subtract(const Duration(days: 80)),
        targetDate: DateTime.now().add(const Duration(days: 20)),
        objectives: _objectives(4, 1),
      );
      expect(q.pace, QuestPace.unknown);
    });

    test('no milestones means no pace verdict', () {
      final q = _quest(targetDate: DateTime.now().add(const Duration(days: 20)));
      expect(q.pace, QuestPace.unknown);
    });
  });

  group('quest reward', () {
    test('is locked while the quest is open', () {
      final q = _quest(rewardText: 'New phone');
      expect(q.hasReward, isTrue);
      expect(q.isRewardClaimable, isFalse);
      expect(q.isRewardClaimed, isFalse);
    });

    test('becomes claimable once the quest is completed', () {
      final q = _quest(status: QuestStatus.completed, rewardText: 'New phone');
      expect(q.isRewardClaimable, isTrue);
    });

    test('stops being claimable once claimed', () {
      final q = _quest(
        status: QuestStatus.completed,
        rewardText: 'New phone',
        rewardClaimedAt: DateTime.now(),
      );
      expect(q.isRewardClaimed, isTrue);
      expect(q.isRewardClaimable, isFalse);
    });

    test('a blank reward does not count as one', () {
      expect(_quest(rewardText: '  ').hasReward, isFalse);
      expect(_quest().hasReward, isFalse);
    });
  });

  group('copyWith null clearing', () {
    test('reopening clears the completion stamp and the claim', () {
      final done = _quest(
        status: QuestStatus.completed,
        completedAt: DateTime.now(),
        rewardText: 'New phone',
        rewardClaimedAt: DateTime.now(),
      );
      final reopened = done.copyWith(
        status: QuestStatus.active,
        completedAt: null,
        rewardClaimedAt: null,
      );
      expect(reopened.completedAt, isNull);
      expect(reopened.rewardClaimedAt, isNull);
      // The reward itself survives — only the claim was undone.
      expect(reopened.rewardText, 'New phone');
    });

    test('omitting a field leaves it untouched', () {
      final q = _quest(
        targetDate: DateTime.now().add(const Duration(days: 10)),
        rewardText: 'New phone',
      );
      final edited = q.copyWith(title: 'Renamed');
      expect(edited.targetDate, q.targetDate);
      expect(edited.rewardText, 'New phone');
    });

    test('a deadline can be removed', () {
      final q = _quest(targetDate: DateTime.now().add(const Duration(days: 10)));
      expect(q.copyWith(targetDate: null).targetDate, isNull);
    });
  });

  group('resolve skill', () {
    test('quest xp drives the level on a 20,000 xp target', () {
      const s = SkillSummary(skill: SkillId.resolve, questXp: 20000);
      expect(s.level, 100);
    });

    test('one completed epic quest is already worth real levels', () {
      // sqrt(400)/sqrt(20000)*100 = 14.1
      const s = SkillSummary(skill: SkillId.resolve, questXp: 400);
      expect(s.level, 14);
    });

    test('no completed quests floors at level 1', () {
      const s = SkillSummary(skill: SkillId.resolve);
      expect(s.level, 1);
    });

    test('an open quest makes the skill active', () {
      const idle = SkillSummary(skill: SkillId.resolve, questXp: 400);
      const busy = SkillSummary(skill: SkillId.resolve, questsActive: 1);
      expect(idle.isActive, isFalse);
      expect(busy.isActive, isTrue);
    });

    test('mastery accrues past the target', () {
      const s = SkillSummary(skill: SkillId.resolve, questXp: 26000);
      expect(s.mastery, 3);
    });

    test('resolve has no time-based eta', () {
      const s = SkillSummary(skill: SkillId.resolve, questXp: 400);
      expect(s.minutesToNextLevel, isNull);
      expect(s.daysToNextLevel, isNull);
    });

    test('remaining to next level is quoted in xp', () {
      const s = SkillSummary(skill: SkillId.resolve, questXp: 400);
      expect(s.remainingToNextLevel, endsWith('XP'));
    });
  });
}
