import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/skill_summary.dart';

const _userId = '1a67d50e-4263-4923-b4bc-1bfa57426aae';

/// Maps each SkillId to its UUID in the `skill_sessions` table.
const _skillSessionIds = {
  SkillId.social: 'a3870777-b8a7-433f-aa32-363799edfbd5',
  SkillId.sport: 'e377b7af-d755-4a16-aa7a-d4fdee33b493',
  SkillId.mindfulness: '6e3b1f81-5733-4ada-a65a-d06d923f94ee',
  SkillId.creation: '1c955a16-ec08-40c4-9855-f3d82b86ea9a',
};

class PlayerSkillRaw {
  final int lifetimeMinutes;
  final int last30DaysMinutes;

  const PlayerSkillRaw({
    required this.lifetimeMinutes,
    required this.last30DaysMinutes,
  });
}

class PlayerSupabaseDatasource {
  final SupabaseClient _client;

  const PlayerSupabaseDatasource(this._client);

  /// Fetches minute totals for Social, Sport, Mindfulness, and Creation
  /// from `skill_sessions` in a single network call.
  Future<Map<SkillId, PlayerSkillRaw>> getSkillSessionData() async {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));

    final res = await _client
        .from('skill_sessions')
        .select('skill_id, minutes, session_at')
        .eq('user_id', _userId)
        .inFilter('skill_id', _skillSessionIds.values.toList())
        .isFilter('deleted_at', null);

    final rows = (res as List).cast<Map<String, dynamic>>();

    // Reverse lookup: skill_id string → SkillId enum
    final idToSkill = {
      for (final e in _skillSessionIds.entries) e.value: e.key,
    };

    final lifetime = {for (final s in _skillSessionIds.keys) s: 0};
    final last30 = {for (final s in _skillSessionIds.keys) s: 0};

    for (final row in rows) {
      final skillIdStr = row['skill_id'] as String;
      final skillId = idToSkill[skillIdStr];
      if (skillId == null) continue;

      final minutes = row['minutes'] as int? ?? 0;
      lifetime[skillId] = (lifetime[skillId] ?? 0) + minutes;

      final sessionAt =
          DateTime.parse(row['session_at'] as String).toLocal();
      if (sessionAt.isAfter(cutoff)) {
        last30[skillId] = (last30[skillId] ?? 0) + minutes;
      }
    }

    return {
      for (final s in _skillSessionIds.keys)
        s: PlayerSkillRaw(
          lifetimeMinutes: lifetime[s] ?? 0,
          last30DaysMinutes: last30[s] ?? 0,
        ),
    };
  }

  /// Fetches minute totals for Japanese from its dedicated table.
  Future<PlayerSkillRaw> getJapaneseData() async {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));

    final res = await _client
        .from('japanese_sessions')
        .select('minutes, session_at')
        .eq('user_id', _userId)
        .isFilter('deleted_at', null);

    final rows = (res as List).cast<Map<String, dynamic>>();

    int lifetimeMinutes = 0;
    int last30DaysMinutes = 0;

    for (final row in rows) {
      final minutes = row['minutes'] as int? ?? 0;
      lifetimeMinutes += minutes;

      final sessionAt =
          DateTime.parse(row['session_at'] as String).toLocal();
      if (sessionAt.isAfter(cutoff)) {
        last30DaysMinutes += minutes;
      }
    }

    return PlayerSkillRaw(
      lifetimeMinutes: lifetimeMinutes,
      last30DaysMinutes: last30DaysMinutes,
    );
  }
}
