import 'dart:math';

/// A single entry larger than this is a backfill — a block of practice done
/// before the app existed, typed in long after the fact.
///
/// It counts toward lifetime totals and levels, because the hours are real, but
/// it is kept out of everything measured per day: the date on it is arbitrary,
/// and one such row would claim a 67-hour day and flatten every real day beside
/// it. The largest genuine session in the data is six hours, so eight is a
/// comfortable line.
const kBackfillThresholdMinutes = 480;

/// The three things worth looking at day by day. Wealth moves in months, not
/// days, so it has no place on a calendar.
enum HistoryTrack { japanese, mindfulness, sobriety }

extension HistoryTrackX on HistoryTrack {
  String get displayName => switch (this) {
        HistoryTrack.japanese => 'JAPANESE',
        HistoryTrack.mindfulness => 'MINDFUL',
        HistoryTrack.sobriety => 'SOBRIETY',
      };

  /// What a filled cell means on this track.
  String get unitLabel => switch (this) {
        HistoryTrack.japanese => 'practised',
        HistoryTrack.mindfulness => 'meditated',
        HistoryTrack.sobriety => 'stayed clean',
      };

  /// Sobriety is a verdict per day, the others are an amount.
  bool get isVerdict => this == HistoryTrack.sobriety;
}

/// How far back the analysis looks.
enum HistoryRange { months3, months6, year1, all }

extension HistoryRangeX on HistoryRange {
  String get label => switch (this) {
        HistoryRange.months3 => '3M',
        HistoryRange.months6 => '6M',
        HistoryRange.year1 => '1Y',
        HistoryRange.all => 'ALL',
      };

  /// Null means everything on record.
  int? get days => switch (this) {
        HistoryRange.months3 => 91,
        HistoryRange.months6 => 182,
        HistoryRange.year1 => 365,
        HistoryRange.all => null,
      };
}

/// One calendar day on one track.
class DayCell {
  final DateTime day;

  /// Practice minutes logged on this day, backfill excluded. Always 0 on the
  /// sobriety track.
  final int minutes;

  /// How many separate entries made up [minutes].
  final int sessions;

  /// Minutes per logging category on this day, backfill excluded.
  final Map<String, int> categories;

  /// Sobriety only: true clean, false slipped, null never logged.
  final bool? clean;

  const DayCell({
    required this.day,
    this.minutes = 0,
    this.sessions = 0,
    this.categories = const {},
    this.clean,
  });

  /// True when the day carries anything at all.
  bool get isLogged => minutes > 0 || clean != null;

  /// True when the day counts as a win — practice done, or a clean day.
  bool get isWin => clean ?? (minutes > 0);
}

/// Minutes and days for one calendar month inside the range.
class MonthBucket {
  final DateTime month;
  final int minutes;
  final int activeDays;
  final int daysInRange;

  const MonthBucket({
    required this.month,
    required this.minutes,
    required this.activeDays,
    required this.daysInRange,
  });

  double get rate => daysInRange == 0 ? 0 : activeDays / daysInRange;
}

/// How one weekday performs across the whole range.
class WeekdayBucket {
  /// 1 = Monday, through 7 = Sunday.
  final int weekday;
  final int minutes;
  final int activeDays;
  final int totalDays;

  const WeekdayBucket({
    required this.weekday,
    required this.minutes,
    required this.activeDays,
    required this.totalDays,
  });

  /// Share of this weekday that was worked, 0–1.
  double get rate => totalDays == 0 ? 0 : activeDays / totalDays;

  static const names = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

  String get name => names[weekday - 1];
}

/// A contiguous run of days on one track, oldest first, gaps zero-filled.
///
/// Everything the calendar, the analysis and the weekly review need is derived
/// here rather than recomputed in widgets, so they can never disagree.
class HistorySeries {
  final HistoryTrack track;
  final List<DayCell> days;

  /// Minutes held back from the day cells because they were backfill, and how
  /// many entries that was. Reported so the numbers stay explainable.
  final int backfillMinutes;
  final int backfillEntries;

  const HistorySeries({
    required this.track,
    required this.days,
    this.backfillMinutes = 0,
    this.backfillEntries = 0,
  });

  /// Minutes per logging category across the days in range, backfill excluded.
  /// Derived rather than stored so it always sums to [totalMinutes] — a split
  /// that disagreed with the total beside it would just look like a bug.
  Map<String, int> get categoryMinutes {
    final out = <String, int>{};
    for (final d in days) {
      d.categories.forEach((k, v) => out.update(
            k,
            (existing) => existing + v,
            ifAbsent: () => v,
          ));
    }
    return out;
  }

  bool get isEmpty => days.isEmpty;

  /// The same series narrowed to the last [count] days. Backfill and category
  /// totals are left whole — they are lifetime figures, not windowed ones.
  HistorySeries lastRange(int? count) {
    if (count == null || count >= days.length) return this;
    return HistorySeries(
      track: track,
      days: days.sublist(days.length - count),
      backfillMinutes: backfillMinutes,
      backfillEntries: backfillEntries,
    );
  }

  /// Trims leading days before anything was ever logged, so "ALL" does not
  /// open on months of blank grid.
  HistorySeries trimmedToFirstEntry() {
    final first = days.indexWhere((d) => d.isLogged);
    if (first <= 0) return this;
    return HistorySeries(
      track: track,
      days: days.sublist(first),
      backfillMinutes: backfillMinutes,
      backfillEntries: backfillEntries,
    );
  }

  // ── Totals ─────────────────────────────────────────────────────────────────

  /// Days with something logged.
  int get loggedDays => days.where((d) => d.isLogged).length;

  /// Days that counted as a win.
  int get winDays => days.where((d) => d.isWin).length;

  int get totalMinutes => days.fold(0, (sum, d) => sum + d.minutes);

  int get sessionCount => days.fold(0, (sum, d) => sum + d.sessions);

  /// Average length of a single logged entry.
  double get avgSessionMinutes =>
      sessionCount == 0 ? 0 : totalMinutes / sessionCount;

  /// Average across every day in the range, blank days included — the honest
  /// one, not the flattering "average of days you showed up".
  double get avgPerDay => days.isEmpty ? 0 : totalMinutes / days.length;

  /// Average across the days actually worked.
  double get avgPerActiveDay => winDays == 0 ? 0 : totalMinutes / winDays;

  /// Share of days in the range that were won, 0–1.
  double get consistency => days.isEmpty ? 0 : winDays / days.length;

  /// The heaviest single day, used to scale the calendar's colour ramp.
  int get bestDayMinutes => days.fold(0, (m, d) => max(m, d.minutes));

  DayCell? get bestDay {
    if (days.isEmpty) return null;
    return days.reduce((a, b) => b.minutes > a.minutes ? b : a);
  }

  // ── Streaks ────────────────────────────────────────────────────────────────

  /// Longest unbroken run of winning days anywhere in the range.
  int get longestStreak {
    int best = 0, run = 0;
    for (final d in days) {
      run = d.isWin ? run + 1 : 0;
      if (run > best) best = run;
    }
    return best;
  }

  /// Longest run of days with nothing, between two days that had something.
  /// Leading and trailing blanks do not count — they are "not started yet" and
  /// "today, still open".
  int get longestGap {
    int best = 0, run = 0;
    bool started = false;
    for (final d in days) {
      if (d.isWin) {
        started = true;
        run = 0;
      } else if (started) {
        run++;
        if (run > best) best = run;
      }
    }
    return best;
  }

  /// Run of winning days ending today, or ending yesterday when today has not
  /// been logged yet — an unlogged today is "not yet", not "broken".
  int get currentStreak {
    if (days.isEmpty) return 0;
    var i = days.length - 1;
    if (!days[i].isLogged) i--; // today still open
    int run = 0;
    for (; i >= 0 && days[i].isWin; i--) {
      run++;
    }
    return run;
  }

  /// The heaviest seven consecutive days, and where they started.
  ({DateTime start, int minutes})? get bestWeek {
    if (days.length < 7) return null;
    int best = 0;
    int bestAt = 0;
    int window = 0;
    for (int i = 0; i < days.length; i++) {
      window += days[i].minutes;
      if (i >= 7) window -= days[i - 7].minutes;
      if (i >= 6 && window > best) {
        best = window;
        bestAt = i - 6;
      }
    }
    return best == 0 ? null : (start: days[bestAt].day, minutes: best);
  }

  // ── Breakdowns ─────────────────────────────────────────────────────────────

  /// One bucket per calendar month touched by the range, oldest first.
  List<MonthBucket> byMonth() {
    final minutes = <DateTime, int>{};
    final active = <DateTime, int>{};
    final total = <DateTime, int>{};

    for (final d in days) {
      final key = DateTime(d.day.year, d.day.month);
      minutes.update(key, (v) => v + d.minutes, ifAbsent: () => d.minutes);
      total.update(key, (v) => v + 1, ifAbsent: () => 1);
      if (d.isWin) active.update(key, (v) => v + 1, ifAbsent: () => 1);
    }

    final keys = total.keys.toList()..sort();
    return [
      for (final k in keys)
        MonthBucket(
          month: k,
          minutes: minutes[k] ?? 0,
          activeDays: active[k] ?? 0,
          daysInRange: total[k] ?? 0,
        ),
    ];
  }

  /// Monday through Sunday, showing which days you actually show up on.
  List<WeekdayBucket> byWeekday() {
    final minutes = List<int>.filled(7, 0);
    final active = List<int>.filled(7, 0);
    final total = List<int>.filled(7, 0);

    for (final d in days) {
      final i = d.day.weekday - 1;
      minutes[i] += d.minutes;
      total[i]++;
      if (d.isWin) active[i]++;
    }

    return [
      for (int i = 0; i < 7; i++)
        WeekdayBucket(
          weekday: i + 1,
          minutes: minutes[i],
          activeDays: active[i],
          totalDays: total[i],
        ),
    ];
  }

  /// Strongest and weakest weekday by how often it gets worked. Null when
  /// nothing has been logged.
  ({WeekdayBucket best, WeekdayBucket worst})? get weekdayExtremes {
    if (winDays == 0) return null;
    final buckets = byWeekday().where((b) => b.totalDays > 0).toList();
    if (buckets.isEmpty) return null;
    buckets.sort((a, b) => b.rate.compareTo(a.rate));
    return (best: buckets.first, worst: buckets.last);
  }

  // ── Windows ────────────────────────────────────────────────────────────────

  /// The last [count] days, ending today.
  List<DayCell> lastDays(int count) => _slice(count, 0);

  /// Minutes over the last [count] days, ending today.
  int minutesInLast(int count) =>
      _slice(count, 0).fold(0, (s, d) => s + d.minutes);

  /// Winning days over the last [count] days, ending today.
  int winsInLast(int count) => _slice(count, 0).where((d) => d.isWin).length;

  /// Minutes over the [count] days that ended [count] days ago — the window
  /// before the current one, for week-over-week comparisons.
  int minutesInPrevious(int count) =>
      _slice(count, count).fold(0, (s, d) => s + d.minutes);

  int winsInPrevious(int count) =>
      _slice(count, count).where((d) => d.isWin).length;

  /// [count] days ending [offset] days before today, clamped to the range.
  List<DayCell> _slice(int count, int offset) {
    final end = days.length - offset;
    if (end <= 0) return const [];
    return days.sublist(max(0, end - count), end);
  }

  /// The most recent day, whether or not anything was logged on it.
  DayCell? get today => days.isEmpty ? null : days.last;

  /// The first day anything was ever logged.
  DateTime? get firstLoggedDay {
    for (final d in days) {
      if (d.isLogged) return d.day;
    }
    return null;
  }
}

/// Every track over the same window of days.
class ActivityHistory {
  final Map<HistoryTrack, HistorySeries> series;

  /// First and last day covered, inclusive. Both are local midnights.
  final DateTime from;
  final DateTime to;

  const ActivityHistory({
    required this.series,
    required this.from,
    required this.to,
  });

  static ActivityHistory empty() {
    final today = DateTime.now();
    final midnight = DateTime(today.year, today.month, today.day);
    return ActivityHistory(
      series: {
        for (final t in HistoryTrack.values)
          t: HistorySeries(track: t, days: const []),
      },
      from: midnight,
      to: midnight,
    );
  }

  HistorySeries operator [](HistoryTrack track) =>
      series[track] ?? HistorySeries(track: track, days: const []);

  int get dayCount => to.difference(from).inDays + 1;

  /// True when nothing has ever been logged on any track.
  bool get isEmpty => series.values.every((s) => s.loggedDays == 0);
}
