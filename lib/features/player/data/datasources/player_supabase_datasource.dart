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

  /// Minutes logged in the last 7 days — drives the 7d-vs-30d trend.
  final int last7DaysMinutes;

  /// Minutes logged on or after [_trackingStart] (excludes addiction sessions
  /// for mindfulness).
  final int minutesSinceTracking;

  const PlayerTimeRaw({
    required this.lifetimeMinutes,
    required this.last30DaysMinutes,
    this.last7DaysMinutes = 0,
    this.minutesSinceTracking = 0,
  });
}

/// Sobriety (addiction-free) tracking derived from mindfulness day logs.
class PlayerSobrietyRaw {
  /// Consecutive clean days ending today (or yesterday if today is unlogged).
  final int currentStreak;

  /// Longest clean streak ever logged.
  final int longestStreak;

  /// Days logged clean, and days logged as a relapse.
  final int cleanDays;
  final int relapseDays;

  /// Days since the most recent sobriety entry. Null when nothing is logged.
  /// Distinguishes "streak reset by a relapse" from "simply stopped logging".
  final int? daysSinceLastLog;

  const PlayerSobrietyRaw({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.cleanDays = 0,
    this.relapseDays = 0,
    this.daysSinceLastLog,
  });

  int get loggedDays => cleanDays + relapseDays;

  /// Share of logged days that were clean (0–1). 0 when nothing is logged.
  double get cleanRate => loggedDays == 0 ? 0.0 : cleanDays / loggedDays;
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

/// Quest totals behind the Resolve skill.
class PlayerResolveRaw {
  /// XP from completed quests only — an open quest is worth nothing yet.
  final int questXp;
  final int questsCompleted;
  final int questsActive;

  const PlayerResolveRaw({
    this.questXp = 0,
    this.questsCompleted = 0,
    this.questsActive = 0,
  });
}

// ── Datasource ────────────────────────────────────────────────────────────────

class PlayerSupabaseDatasource {
  final SupabaseClient _client;

  const PlayerSupabaseDatasource(this._client);

  // ── Japanese ───────────────────────────────────────────────────────────────

  Future<PlayerTimeRaw> getJapaneseData() async {
    final now = DateTime.now();
    final cutoff30 = now.subtract(const Duration(days: 30));
    final cutoff7 = now.subtract(const Duration(days: 7));

    final res = await _client
        .from('japanese_sessions')
        .select('minutes, session_at')
        .eq('user_id', _userId)
        .isFilter('deleted_at', null);

    int lifetime = 0;
    int last30 = 0;
    int last7 = 0;
    int sinceTracking = 0;

    for (final row in (res as List).cast<Map<String, dynamic>>()) {
      final m = row['minutes'] as int? ?? 0;
      lifetime += m;
      final at = DateTime.parse(row['session_at'] as String).toLocal();
      if (at.isAfter(cutoff30)) last30 += m;
      if (at.isAfter(cutoff7)) last7 += m;
      if (!at.isBefore(_trackingStart)) sinceTracking += m;
    }

    return PlayerTimeRaw(
      lifetimeMinutes: lifetime,
      last30DaysMinutes: last30,
      last7DaysMinutes: last7,
      minutesSinceTracking: sinceTracking,
    );
  }

  // ── Mindfulness ────────────────────────────────────────────────────────────

  /// Returns meditation time stats and sobriety stats from a single query —
  /// both live in `skill_sessions` under the mindfulness skill.
  Future<(PlayerTimeRaw, PlayerSobrietyRaw)> getMindfulnessData() async {
    final now = DateTime.now();
    final cutoff30 = now.subtract(const Duration(days: 30));
    final cutoff7 = now.subtract(const Duration(days: 7));

    final res = await _client
        .from('skill_sessions')
        .select('minutes, session_at, category')
        .eq('user_id', _userId)
        .eq('skill_id', _mindfulnessSkillId)
        .isFilter('deleted_at', null);

    int lifetime = 0;
    int last30 = 0;
    int last7 = 0;
    int sinceTracking = 0;

    // Local date → true (clean) / false (relapsed). A relapse always wins.
    final dayMap = <String, bool>{};

    for (final row in (res as List).cast<Map<String, dynamic>>()) {
      final m = row['minutes'] as int? ?? 0;
      final category = row['category'] as String? ?? '';
      final at = DateTime.parse(row['session_at'] as String).toLocal();

      // Addiction entries are day markers, not meditation time.
      if (category == 'addiction_relapse') {
        dayMap[_dateKey(at)] = false;
        continue;
      }
      if (category == 'addiction') {
        dayMap[_dateKey(at)] ??= true;
        continue;
      }

      lifetime += m;
      if (at.isAfter(cutoff30)) last30 += m;
      if (at.isAfter(cutoff7)) last7 += m;
      if (!at.isBefore(_trackingStart)) sinceTracking += m;
    }

    final time = PlayerTimeRaw(
      lifetimeMinutes: lifetime,
      last30DaysMinutes: last30,
      last7DaysMinutes: last7,
      minutesSinceTracking: sinceTracking,
    );

    return (time, _computeSobriety(dayMap));
  }

  // ── Sobriety helpers ───────────────────────────────────────────────────────

  static String _dateKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  static DateTime _parseKey(String key) {
    final parts = key.split('-').map(int.parse).toList();
    return DateTime(parts[0], parts[1], parts[2]);
  }

  /// Mirrors the streak rules used on the Mindfulness tab so both screens
  /// always show the same numbers.
  static PlayerSobrietyRaw _computeSobriety(Map<String, bool> dayMap) {
    if (dayMap.isEmpty) return const PlayerSobrietyRaw();

    final cleanDays = dayMap.values.where((v) => v).length;
    final relapseDays = dayMap.length - cleanDays;

    // Current streak — stops at the first unlogged or relapsed day.
    final today = DateTime.now();
    int current = 0;
    if (dayMap[_dateKey(today)] != false) {
      final startOffset = dayMap[_dateKey(today)] == true ? 0 : 1;
      for (int i = startOffset; ; i++) {
        if (dayMap[_dateKey(today.subtract(Duration(days: i)))] != true) break;
        current++;
      }
    }

    // Longest streak — any gap in logged days also resets the chain.
    final sorted = dayMap.keys.toList()
      ..sort((a, b) => _parseKey(a).compareTo(_parseKey(b)));

    int longest = 0;
    int run = 0;
    DateTime? prev;
    for (final key in sorted) {
      final date = _parseKey(key);
      if (prev != null && date.difference(prev).inDays > 1) run = 0;
      run = dayMap[key] == true ? run + 1 : 0;
      if (run > longest) longest = run;
      prev = date;
    }

    final todayMidnight = DateTime(today.year, today.month, today.day);
    final lastLog = _parseKey(sorted.last);

    return PlayerSobrietyRaw(
      currentStreak: current,
      longestStreak: longest,
      cleanDays: cleanDays,
      relapseDays: relapseDays,
      daysSinceLastLog: todayMidnight.difference(lastLog).inDays,
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

  // ── Resolve (quests) ───────────────────────────────────────────────────────

  Future<PlayerResolveRaw> getResolveData() async {
    final res = await _client
        .from('quests')
        .select('xp_reward, status')
        .eq('user_id', _userId);

    int xp = 0;
    int completed = 0;
    int active = 0;

    for (final row in (res as List).cast<Map<String, dynamic>>()) {
      if (row['status'] == 'completed') {
        xp += row['xp_reward'] as int? ?? 0;
        completed++;
      } else {
        active++;
      }
    }

    return PlayerResolveRaw(
      questXp: xp,
      questsCompleted: completed,
      questsActive: active,
    );
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
