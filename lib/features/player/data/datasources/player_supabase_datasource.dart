import 'package:supabase_flutter/supabase_flutter.dart';

const _userId = '1a67d50e-4263-4923-b4bc-1bfa57426aae';

// Skill UUIDs in the `skill_sessions` table.
const _mindfulnessSkillId = '6e3b1f81-5733-4ada-a65a-d06d923f94ee';
const _sportSkillId = 'e377b7af-d755-4a16-aa7a-d4fdee33b493';
const _socialSkillId = 'a3870777-b8a7-433f-aa32-363799edfbd5';
const _creationSkillId = '1c955a16-ec08-40c4-9855-f3d82b86ea9a';

// ── Raw result types ──────────────────────────────────────────────────────────

class PlayerTimeRaw {
  final int lifetimeMinutes;
  final int last30DaysMinutes;

  const PlayerTimeRaw({
    required this.lifetimeMinutes,
    required this.last30DaysMinutes,
  });
}

class PlayerSportRaw {
  final int lifetimeMinutes;
  final int last30DaysMinutes;
  final int trainedDaysLast30;

  const PlayerSportRaw({
    required this.lifetimeMinutes,
    required this.last30DaysMinutes,
    required this.trainedDaysLast30,
  });
}

class PlayerCreationRaw {
  final int lifetimeMinutes;
  final int last30DaysMinutes;
  final double weightedPoints;

  const PlayerCreationRaw({
    required this.lifetimeMinutes,
    required this.last30DaysMinutes,
    required this.weightedPoints,
  });
}

class PlayerWealthRaw {
  final double currentNetWorthEur;

  const PlayerWealthRaw({required this.currentNetWorthEur});
}

// ── Datasource ────────────────────────────────────────────────────────────────

class PlayerSupabaseDatasource {
  final SupabaseClient _client;

  const PlayerSupabaseDatasource(this._client);

  // ── Japanese ───────────────────────────────────────────────────────────────

  Future<PlayerTimeRaw> getJapaneseData() async {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));

    final res = await _client
        .from('japanese_sessions')
        .select('minutes, session_at')
        .eq('user_id', _userId)
        .isFilter('deleted_at', null);

    int lifetime = 0;
    int last30 = 0;
    for (final row in (res as List).cast<Map<String, dynamic>>()) {
      final m = row['minutes'] as int? ?? 0;
      lifetime += m;
      final at = DateTime.parse(row['session_at'] as String).toLocal();
      if (at.isAfter(cutoff)) last30 += m;
    }

    return PlayerTimeRaw(lifetimeMinutes: lifetime, last30DaysMinutes: last30);
  }

  // ── Mindfulness ────────────────────────────────────────────────────────────

  Future<PlayerTimeRaw> getMindfulnessData() async {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));

    final res = await _client
        .from('skill_sessions')
        .select('minutes, session_at')
        .eq('user_id', _userId)
        .eq('skill_id', _mindfulnessSkillId)
        .isFilter('deleted_at', null);

    int lifetime = 0;
    int last30 = 0;
    for (final row in (res as List).cast<Map<String, dynamic>>()) {
      final m = row['minutes'] as int? ?? 0;
      lifetime += m;
      final at = DateTime.parse(row['session_at'] as String).toLocal();
      if (at.isAfter(cutoff)) last30 += m;
    }

    return PlayerTimeRaw(lifetimeMinutes: lifetime, last30DaysMinutes: last30);
  }

  // ── Sport ──────────────────────────────────────────────────────────────────

  Future<PlayerSportRaw> getSportData() async {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));

    final res = await _client
        .from('skill_sessions')
        .select('minutes, session_at')
        .eq('user_id', _userId)
        .eq('skill_id', _sportSkillId)
        .isFilter('deleted_at', null);

    int lifetime = 0;
    int last30 = 0;
    final trainingDays = <String>{};

    for (final row in (res as List).cast<Map<String, dynamic>>()) {
      final m = row['minutes'] as int? ?? 0;
      lifetime += m;
      final at = DateTime.parse(row['session_at'] as String).toLocal();
      if (at.isAfter(cutoff)) {
        last30 += m;
        trainingDays.add('${at.year}-${at.month}-${at.day}');
      }
    }

    return PlayerSportRaw(
      lifetimeMinutes: lifetime,
      last30DaysMinutes: last30,
      trainedDaysLast30: trainingDays.length,
    );
  }

  // ── Social ─────────────────────────────────────────────────────────────────
  //   Hours-based like other skills.

  Future<PlayerTimeRaw> getSocialData() async {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));

    final res = await _client
        .from('skill_sessions')
        .select('minutes, session_at')
        .eq('user_id', _userId)
        .eq('skill_id', _socialSkillId)
        .isFilter('deleted_at', null);

    int lifetime = 0;
    int last30 = 0;
    for (final row in (res as List).cast<Map<String, dynamic>>()) {
      final m = row['minutes'] as int? ?? 0;
      lifetime += m;
      final at = DateTime.parse(row['session_at'] as String).toLocal();
      if (at.isAfter(cutoff)) last30 += m;
    }

    return PlayerTimeRaw(lifetimeMinutes: lifetime, last30DaysMinutes: last30);
  }

  // ── Creation ───────────────────────────────────────────────────────────────
  //   Hours from all creation sessions + project difficulty bonus.

  Future<PlayerCreationRaw> getCreationData() async {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));

    // 1. General creation sessions (from skill_sessions)
    final generalRes = await _client
        .from('skill_sessions')
        .select('minutes, session_at')
        .eq('user_id', _userId)
        .eq('skill_id', _creationSkillId)
        .isFilter('deleted_at', null);

    int lifetime = 0;
    int last30 = 0;
    for (final row in (generalRes as List).cast<Map<String, dynamic>>()) {
      final m = row['minutes'] as int? ?? 0;
      lifetime += m;
      final at = DateTime.parse(row['session_at'] as String).toLocal();
      if (at.isAfter(cutoff)) last30 += m;
    }

    // 2. Project-specific creation sessions (from creation_sessions)
    final projectIds = await _client
        .from('creation_projects')
        .select('id')
        .eq('user_id', _userId)
        .isFilter('deleted_at', null);

    final ids = (projectIds as List)
        .cast<Map<String, dynamic>>()
        .map((r) => r['id'] as String)
        .toList();

    if (ids.isNotEmpty) {
      final projectSessionsRes = await _client
          .from('creation_sessions')
          .select('minutes, session_at')
          .inFilter('project_id', ids)
          .isFilter('deleted_at', null);

      for (final row
          in (projectSessionsRes as List).cast<Map<String, dynamic>>()) {
        final m = row['minutes'] as int? ?? 0;
        lifetime += m;
        final at = DateTime.parse(row['session_at'] as String).toLocal();
        if (at.isAfter(cutoff)) last30 += m;
      }
    }

    // 3. Project difficulty sum
    final projectsRes = await _client
        .from('creation_projects')
        .select('difficulty')
        .eq('user_id', _userId)
        .isFilter('deleted_at', null);

    double points = 0;
    for (final row in (projectsRes as List).cast<Map<String, dynamic>>()) {
      points += (row['difficulty'] as int? ?? 1).toDouble();
    }

    return PlayerCreationRaw(
      lifetimeMinutes: lifetime,
      last30DaysMinutes: last30,
      weightedPoints: points,
    );
  }

  // ── Wealth ─────────────────────────────────────────────────────────────────

  Future<PlayerWealthRaw> getWealthData() async {
    final res = await _client
        .from('wealth_snapshots')
        .select('net_worth_eur')
        .eq('user_id', _userId)
        .isFilter('deleted_at', null)
        .order('snapshot_month', ascending: false)
        .limit(1);

    final rows = (res as List).cast<Map<String, dynamic>>();
    if (rows.isEmpty) return const PlayerWealthRaw(currentNetWorthEur: 0);

    final raw = rows.first['net_worth_eur'];
    final netWorth = raw is num ? raw.toDouble() : 0.0;

    return PlayerWealthRaw(currentNetWorthEur: netWorth);
  }
}
