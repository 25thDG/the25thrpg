import '../../domain/entities/player_stats.dart';
import '../../domain/entities/skill_summary.dart';
import '../../domain/repositories/player_repository.dart';
import '../datasources/player_supabase_datasource.dart';

class PlayerRepositoryImpl implements PlayerRepository {
  final PlayerSupabaseDatasource _datasource;

  const PlayerRepositoryImpl(this._datasource);

  @override
  Future<PlayerStats> getPlayerStats() async {
    final (japanese, mindfulness, wealth, streak) = await (
      _datasource.getJapaneseData(),
      _datasource.getMindfulnessData(),
      _datasource.getWealthData(),
      _datasource.getGlobalStreak(),
    ).wait;

    final skills = [
      SkillSummary(
        skill: SkillId.japanese,
        lifetimeMinutes: japanese.lifetimeMinutes,
        last30DaysMinutes: japanese.last30DaysMinutes,
        minutesSinceTracking: japanese.minutesSinceTracking,
      ),
      SkillSummary(
        skill: SkillId.wealth,
        currentNetWorthEur: wealth.currentNetWorthEur,
        monthlyGrowthEur: wealth.monthlyGrowthEur,
      ),
      SkillSummary(
        skill: SkillId.mindfulness,
        lifetimeMinutes: mindfulness.lifetimeMinutes,
        last30DaysMinutes: mindfulness.last30DaysMinutes,
        minutesSinceTracking: mindfulness.minutesSinceTracking,
      ),
    ];

    return PlayerStats(skills: skills, streakDays: streak);
  }
}
