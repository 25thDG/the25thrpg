import '../../domain/entities/player_stats.dart';
import '../../domain/entities/skill_summary.dart';
import '../../domain/repositories/player_repository.dart';
import '../datasources/player_supabase_datasource.dart';

class PlayerRepositoryImpl implements PlayerRepository {
  final PlayerSupabaseDatasource _datasource;

  const PlayerRepositoryImpl(this._datasource);

  @override
  Future<PlayerStats> getPlayerStats() async {
    final (skillData, japaneseData) = await (
      _datasource.getSkillSessionData(),
      _datasource.getJapaneseData(),
    ).wait;

    final skills = [
      SkillSummary(
        skill: SkillId.japanese,
        lifetimeMinutes: japaneseData.lifetimeMinutes,
        last30DaysMinutes: japaneseData.last30DaysMinutes,
      ),
      SkillSummary(
        skill: SkillId.mindfulness,
        lifetimeMinutes:
            skillData[SkillId.mindfulness]?.lifetimeMinutes ?? 0,
        last30DaysMinutes:
            skillData[SkillId.mindfulness]?.last30DaysMinutes ?? 0,
      ),
      SkillSummary(
        skill: SkillId.creation,
        lifetimeMinutes:
            skillData[SkillId.creation]?.lifetimeMinutes ?? 0,
        last30DaysMinutes:
            skillData[SkillId.creation]?.last30DaysMinutes ?? 0,
      ),
      SkillSummary(
        skill: SkillId.social,
        lifetimeMinutes: skillData[SkillId.social]?.lifetimeMinutes ?? 0,
        last30DaysMinutes:
            skillData[SkillId.social]?.last30DaysMinutes ?? 0,
      ),
      SkillSummary(
        skill: SkillId.sport,
        lifetimeMinutes: skillData[SkillId.sport]?.lifetimeMinutes ?? 0,
        last30DaysMinutes: skillData[SkillId.sport]?.last30DaysMinutes ?? 0,
      ),
    ];

    return PlayerStats(skills: skills);
  }
}
