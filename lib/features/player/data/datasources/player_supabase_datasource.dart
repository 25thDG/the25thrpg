import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/activity_history.dart';

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

  /// Minutes per day for the last 7 days, oldest first. Drives the sparkline.
  final List<int> dailyMinutesLast7;

  const PlayerTimeRaw({
    required this.lifetimeMinutes,
    required this.last30DaysMinutes,
    this.last7DaysMinutes = 0,
    this.minutesSinceTracking = 0,
    this.dailyMinutesLast7 = const [],
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

  /// The last 14 days, oldest first: true clean, false relapse, null unlogged.
  final List<bool?> last14Days;

  const PlayerSobrietyRaw({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.cleanDays = 0,
    this.relapseDays = 0,
    this.daysSinceLastLog,
    this.last14Days = const [],
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
    final daily = List<int>.filled(7, 0);
    final today = DateTime(now.year, now.month, now.day);

    for (final row in (res as List).cast<Map<String, dynamic>>()) {
      final m = row['minutes'] as int? ?? 0;
      lifetime += m;
      final at = DateTime.parse(row['session_at'] as String).toLocal();
      if (at.isAfter(cutoff30)) last30 += m;
      if (at.isAfter(cutoff7)) last7 += m;
      if (!at.isBefore(_trackingStart)) sinceTracking += m;

      // Bucket into the last 7 calendar days, oldest first.
      final age = today.difference(DateTime(at.year, at.month, at.day)).inDays;
      if (age >= 0 && age < 7) daily[6 - age] += m;
    }

    return PlayerTimeRaw(
      lifetimeMinutes: lifetime,
      last30DaysMinutes: last30,
      last7DaysMinutes: last7,
      minutesSinceTracking: sinceTracking,
      dailyMinutesLast7: daily,
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

    // Last 14 days, oldest first, for the streak strip.
    final strip = List<bool?>.generate(14, (i) {
      final day = todayMidnight.subtract(Duration(days: 13 - i));
      return dayMap[_dateKey(day)];
    });

    return PlayerSobrietyRaw(
      currentStreak: current,
      longestStreak: longest,
      cleanDays: cleanDays,
      relapseDays: relapseDays,
      daysSinceLastLog: todayMidnight.difference(lastLog).inDays,
      last14Days: strip,
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

  // ── Activity history ───────────────────────────────────────────────────────

  /// Day-by-day activity for the calendar, the analysis and the weekly review.
  ///
  /// Pulls everything — both tables are a few hundred rows — and buckets
  /// locally, so the bucketing rules live next to the rules the rest of this
  /// file already uses. Entries over [kBackfillThresholdMinutes] are held out
  /// of the day cells and reported separately; see the README.
  Future<ActivityHistory> getActivityHistory() async {
    final now = DateTime.now();
    final to = DateTime(now.year, now.month, now.day);

    final [japaneseRes, skillRes] = await Future.wait([
      _client
          .from('japanese_sessions')
          .select('minutes, session_at, category')
          .eq('user_id', _userId)
          .isFilter('deleted_at', null),
      _client
          .from('skill_sessions')
          .select('minutes, session_at, category')
          .eq('user_id', _userId)
          .eq('skill_id', _mindfulnessSkillId)
          .isFilter('deleted_at', null),
    ]);

    final japanese = _DayAccumulator();
    final meditation = _DayAccumulator();
    final sobriety = <String, bool>{};

    for (final row in (japaneseRes as List).cast<Map<String, dynamic>>()) {
      japanese.add(
        at: DateTime.parse(row['session_at'] as String).toLocal(),
        minutes: row['minutes'] as int? ?? 0,
        category: row['category'] as String?,
      );
    }

    for (final row in (skillRes as List).cast<Map<String, dynamic>>()) {
      final at = DateTime.parse(row['session_at'] as String).toLocal();
      final category = row['category'] as String? ?? '';

      // Addiction rows are day verdicts, not meditation time. A relapse wins.
      if (category == 'addiction_relapse') {
        sobriety[_dateKey(at)] = false;
        continue;
      }
      if (category == 'addiction') {
        sobriety[_dateKey(at)] ??= true;
        continue;
      }

      meditation.add(
        at: at,
        minutes: row['minutes'] as int? ?? 0,
        category: category.isEmpty ? null : category,
      );
    }

    // Start the range at the earliest thing on record so "ALL" means all.
    final earliest = [
      japanese.earliest,
      meditation.earliest,
      if (sobriety.isNotEmpty)
        sobriety.keys.map(_parseKey).reduce((a, b) => a.isBefore(b) ? a : b),
    ].nonNulls.fold<DateTime?>(
          null,
          (acc, d) => acc == null || d.isBefore(acc) ? d : acc,
        );

    final from = earliest ?? to;
    final dayCount = to.difference(from).inDays + 1;

    List<DayCell> build(_DayAccumulator? acc, Map<String, bool>? verdicts) =>
        List.generate(dayCount, (i) {
          final day = from.add(Duration(days: i));
          final key = _dateKey(day);
          return DayCell(
            day: day,
            minutes: acc?.minutes[key] ?? 0,
            sessions: acc?.sessions[key] ?? 0,
            categories: acc?.categories[key] ?? const {},
            clean: verdicts?[key],
          );
        });

    return ActivityHistory(
      from: from,
      to: to,
      series: {
        HistoryTrack.japanese: HistorySeries(
          track: HistoryTrack.japanese,
          days: build(japanese, null),
          backfillMinutes: japanese.backfillMinutes,
          backfillEntries: japanese.backfillEntries,
        ),
        HistoryTrack.mindfulness: HistorySeries(
          track: HistoryTrack.mindfulness,
          days: build(meditation, null),
          backfillMinutes: meditation.backfillMinutes,
          backfillEntries: meditation.backfillEntries,
        ),
        HistoryTrack.sobriety: HistorySeries(
          track: HistoryTrack.sobriety,
          days: build(null, sobriety),
        ),
      },
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

/// Buckets entries into days, holding backfill blocks out of the day totals
/// while still counting them toward the lifetime figures reported alongside.
class _DayAccumulator {
  final minutes = <String, int>{};
  final sessions = <String, int>{};
  final categories = <String, Map<String, int>>{};

  int backfillMinutes = 0;
  int backfillEntries = 0;
  DateTime? earliest;

  void add({
    required DateTime at,
    required int minutes,
    String? category,
  }) {
    final day = DateTime(at.year, at.month, at.day);
    if (earliest == null || day.isBefore(earliest!)) earliest = day;

    // Real hours, but the date on them is arbitrary — keep them out of the
    // per-day view, and out of the category split with it, so every figure on
    // the analysis reconciles.
    if (minutes > kBackfillThresholdMinutes) {
      backfillMinutes += minutes;
      backfillEntries++;
      return;
    }

    final key = PlayerSupabaseDatasource._dateKey(at);
    this.minutes.update(key, (v) => v + minutes, ifAbsent: () => minutes);
    sessions.update(key, (v) => v + 1, ifAbsent: () => 1);

    if (category != null) {
      categories
          .putIfAbsent(key, () => <String, int>{})
          .update(category, (v) => v + minutes, ifAbsent: () => minutes);
    }
  }
}
