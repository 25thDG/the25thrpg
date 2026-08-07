import '../../domain/entities/player_stats.dart';
import '../../domain/entities/skill_summary.dart';
import '../../domain/repositories/player_repository.dart';
import '../datasources/player_supabase_datasource.dart';

class PlayerRepositoryImpl implements PlayerRepository {
  final PlayerSupabaseDatasource _datasource;

  const PlayerRepositoryImpl(this._datasource);

  @override
  Future<PlayerStats> getPlayerStats() async {
    final (japanese, mindfulness, wealth, resolve, streak) = await (
      _datasource.getJapaneseData(),
      _datasource.getMindfulnessData(),
      _datasource.getWealthData(),
      _datasource.getResolveData(),
      _datasource.getGlobalStreak(),
    ).wait;

    final (meditation, sobriety) = mindfulness;

    final skills = [
      SkillSummary(
        skill: SkillId.japanese,
        lifetimeMinutes: japanese.lifetimeMinutes,
        last30DaysMinutes: japanese.last30DaysMinutes,
        last7DaysMinutes: japanese.last7DaysMinutes,
      ),
      SkillSummary(
        skill: SkillId.wealth,
        currentNetWorthEur: wealth.currentNetWorthEur,
        monthlyGrowthEur: wealth.monthlyGrowthEur,
      ),
      SkillSummary(
        skill: SkillId.mindfulness,
        lifetimeMinutes: meditation.lifetimeMinutes,
        last30DaysMinutes: meditation.last30DaysMinutes,
        last7DaysMinutes: meditation.last7DaysMinutes,
        cleanStreak: sobriety.currentStreak,
        longestCleanStreak: sobriety.longestStreak,
        cleanDays: sobriety.cleanDays,
        relapseDays: sobriety.relapseDays,
        daysSinceLastCleanLog: sobriety.daysSinceLastLog,
      ),
      SkillSummary(
        skill: SkillId.resolve,
        questXp: resolve.questXp,
        questsCompleted: resolve.questsCompleted,
        questsActive: resolve.questsActive,
      ),
    ];

    return PlayerStats(skills: skills, streakDays: streak);
  }
}
