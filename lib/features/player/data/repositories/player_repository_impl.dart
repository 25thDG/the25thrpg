import '../../domain/entities/player_stats.dart';
import '../../domain/entities/skill_summary.dart';
import '../../domain/repositories/player_repository.dart';
import '../datasources/player_supabase_datasource.dart';

class PlayerRepositoryImpl implements PlayerRepository {
  final PlayerSupabaseDatasource _datasource;

  const PlayerRepositoryImpl(this._datasource);

  @override
  Future<PlayerStats> getPlayerStats() async {
    final (japanese, mindfulness, sport, social, creation, wealth) = await (
      _datasource.getJapaneseData(),
      _datasource.getMindfulnessData(),
      _datasource.getSportData(),
      _datasource.getSocialData(),
      _datasource.getCreationData(),
      _datasource.getWealthData(),
    ).wait;

    final skills = [
      SkillSummary(
        skill: SkillId.japanese,
        lifetimeMinutes: japanese.lifetimeMinutes,
        last30DaysMinutes: japanese.last30DaysMinutes,
      ),
      SkillSummary(
        skill: SkillId.wealth,
        currentNetWorthEur: wealth.currentNetWorthEur,
      ),
      SkillSummary(
        skill: SkillId.mindfulness,
        lifetimeMinutes: mindfulness.lifetimeMinutes,
        last30DaysMinutes: mindfulness.last30DaysMinutes,
      ),
      SkillSummary(
        skill: SkillId.creation,
        lifetimeMinutes: creation.lifetimeMinutes,
        last30DaysMinutes: creation.last30DaysMinutes,
        weightedPoints: creation.weightedPoints,
      ),
      SkillSummary(
        skill: SkillId.social,
        lifetimeMinutes: social.lifetimeMinutes,
        last30DaysMinutes: social.last30DaysMinutes,
      ),
      SkillSummary(
        skill: SkillId.sport,
        lifetimeMinutes: sport.lifetimeMinutes,
        last30DaysMinutes: sport.last30DaysMinutes,
        trainedDaysLast30: sport.trainedDaysLast30,
      ),
    ];

    return PlayerStats(skills: skills);
  }
}
