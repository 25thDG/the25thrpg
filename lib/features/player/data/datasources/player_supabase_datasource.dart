import 'package:supabase_flutter/supabase_flutter.dart';

const _userId = '1a67d50e-4263-4923-b4bc-1bfa57426aae';

// Skill UUIDs in the `skill_sessions` table.
const _mindfulnessSkillId = '6e3b1f81-5733-4ada-a65a-d06d923f94ee';

// Tracking start date for daily averages (April 11, 2026).
final _trackingStart = DateTime(2026, 4, 11);

// ── Raw result types ──────────────────────────────────────────────────────────

class PlayerTimeRaw {
  final int lifetimeMinutes;
  final int last30DaysMinutes;

  /// Minutes logged on or after [_trackingStart] (excludes addiction sessions
  /// for mindfulness).
  final int minutesSinceTracking;

  const PlayerTimeRaw({
    required this.lifetimeMinutes,
    required this.last30DaysMinutes,
    this.minutesSinceTracking = 0,
  });
}

class PlayerWealthRaw {
  final double currentNetWorthEur;

  /// Average monthly net-worth growth computed from all snapshots.
  /// Null when fewer than 2 snapshots exist.
  final double? monthlyGrowthEur;

  const PlayerWealthRaw({
    required this.currentNetWorthEur,
    this.monthlyGrowthEur,
  });
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
    int sinceTracking = 0;

    for (final row in (res as List).cast<Map<String, dynamic>>()) {
      final m = row['minutes'] as int? ?? 0;
      lifetime += m;
      final at = DateTime.parse(row['session_at'] as String).toLocal();
      if (at.isAfter(cutoff)) last30 += m;
      if (!at.isBefore(_trackingStart)) sinceTracking += m;
    }

    return PlayerTimeRaw(
      lifetimeMinutes: lifetime,
      last30DaysMinutes: last30,
      minutesSinceTracking: sinceTracking,
    );
  }

  // ── Mindfulness ────────────────────────────────────────────────────────────

  Future<PlayerTimeRaw> getMindfulnessData() async {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));

    final res = await _client
        .from('skill_sessions')
        .select('minutes, session_at, category')
        .eq('user_id', _userId)
        .eq('skill_id', _mindfulnessSkillId)
        .isFilter('deleted_at', null);

    int lifetime = 0;
    int last30 = 0;
    int sinceTracking = 0;

    for (final row in (res as List).cast<Map<String, dynamic>>()) {
      final m = row['minutes'] as int? ?? 0;
      final category = row['category'] as String? ?? '';
      final isAddiction =
          category == 'addiction' || category == 'addiction_relapse';

      lifetime += m;
      final at = DateTime.parse(row['session_at'] as String).toLocal();
      if (at.isAfter(cutoff)) last30 += m;
      // Exclude addiction sessions from the daily average tracking
      if (!isAddiction && !at.isBefore(_trackingStart)) sinceTracking += m;
    }

    return PlayerTimeRaw(
      lifetimeMinutes: lifetime,
      last30DaysMinutes: last30,
      minutesSinceTracking: sinceTracking,
    );
  }

  // ── Global streak ──────────────────────────────────────────────────────────

  /// Consecutive days with at least one session, ending today (or yesterday
  /// if today has not been logged yet).
  Future<int> getGlobalStreak() async {
    final [japaneseRes, skillRes] = await Future.wait([
      _client
          .from('japanese_sessions')
          .select('session_at')
          .eq('user_id', _userId)
          .isFilter('deleted_at', null),
      _client
          .from('skill_sessions')
          .select('session_at')
          .eq('user_id', _userId)
          .isFilter('deleted_at', null),
    ]);

    final activeDays = <String>{};
    for (final rows in [japaneseRes, skillRes]) {
      for (final row in (rows as List).cast<Map<String, dynamic>>()) {
        final at = DateTime.parse(row['session_at'] as String).toLocal();
        activeDays.add('${at.year}-${at.month}-${at.day}');
      }
    }

    int streak = 0;
    final today = DateTime.now();
    for (int i = 0; ; i++) {
      final day = today.subtract(Duration(days: i));
      final key = '${day.year}-${day.month}-${day.day}';
      if (!activeDays.contains(key)) {
        if (i == 0) continue; // today not yet logged — check from yesterday
        break;
      }
      streak++;
    }

    return streak;
  }

  // ── Wealth ─────────────────────────────────────────────────────────────────

  Future<PlayerWealthRaw> getWealthData() async {
    final res = await _client
        .from('wealth_snapshots')
        .select('net_worth_eur, snapshot_month')
        .eq('user_id', _userId)
        .isFilter('deleted_at', null)
        .order('snapshot_month', ascending: true);

    final rows = (res as List).cast<Map<String, dynamic>>();
    if (rows.isEmpty) return const PlayerWealthRaw(currentNetWorthEur: 0);

    final latestRaw = rows.last['net_worth_eur'];
    final netWorth = latestRaw is num ? latestRaw.toDouble() : 0.0;

    double? monthlyGrowth;
    if (rows.length >= 2) {
      final oldestRaw = rows.first['net_worth_eur'];
      final oldestNetWorth = oldestRaw is num ? oldestRaw.toDouble() : 0.0;

      final oldestMonth = _parseMonth(rows.first['snapshot_month'] as String);
      final latestMonth = _parseMonth(rows.last['snapshot_month'] as String);
      final months = (latestMonth.year - oldestMonth.year) * 12 +
          (latestMonth.month - oldestMonth.month);

      if (months > 0) {
        monthlyGrowth = (netWorth - oldestNetWorth) / months;
      }
    }

    return PlayerWealthRaw(
      currentNetWorthEur: netWorth,
      monthlyGrowthEur: monthlyGrowth,
    );
  }

  /// Parses a snapshot_month string in either `YYYY-MM` or `YYYY-MM-DD` format.
  static DateTime _parseMonth(String s) {
    if (s.length == 7) return DateTime.parse('$s-01');
    return DateTime.parse(s);
  }
}
