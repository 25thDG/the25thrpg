import 'dart:math';

/// The three things worth looking at day by day. Wealth and Resolve move in
/// months, not days, so they have no place on a calendar.
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
        HistoryTrack.sobriety => 'clean',
      };

  /// Sobriety is a verdict per day, the others are an amount.
  bool get isVerdict => this == HistoryTrack.sobriety;
}

/// One calendar day on one track.
class DayCell {
  final DateTime day;

  /// Practice minutes logged on this day. Always 0 on the sobriety track.
  final int minutes;

  /// Sobriety only: true clean, false slipped, null never logged.
  final bool? clean;

  const DayCell({required this.day, this.minutes = 0, this.clean});

  /// True when the day carries anything at all.
  bool get isLogged => minutes > 0 || clean != null;

  /// True when the day counts as a win — practice done, or a clean day.
  bool get isWin => clean ?? (minutes > 0);
}

/// A contiguous run of days on one track, oldest first, gaps zero-filled.
///
/// Everything the calendar and the weekly review need is derived here rather
/// than recomputed in widgets, so the two always agree.
class HistorySeries {
  final HistoryTrack track;
  final List<DayCell> days;

  const HistorySeries({required this.track, required this.days});

  bool get isEmpty => days.isEmpty;

  /// Days with something logged.
  int get loggedDays => days.where((d) => d.isLogged).length;

  /// Days that counted as a win.
  int get winDays => days.where((d) => d.isWin).length;

  int get totalMinutes => days.fold(0, (sum, d) => sum + d.minutes);

  /// The heaviest single day, used to scale the calendar's colour ramp.
  int get bestDayMinutes => days.fold(0, (m, d) => max(m, d.minutes));

  DayCell? get bestDay {
    if (days.isEmpty) return null;
    return days.reduce((a, b) => b.minutes > a.minutes ? b : a);
  }

  /// Longest unbroken run of winning days anywhere in the range.
  int get longestStreak {
    int best = 0, run = 0;
    for (final d in days) {
      run = d.isWin ? run + 1 : 0;
      if (run > best) best = run;
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

  /// The last [count] days, ending today.
  List<DayCell> lastDays(int count) => _slice(count, 0);

  /// Minutes over the last [count] days, ending today.
  int minutesInLast(int count) => _slice(count, 0).fold(0, (s, d) => s + d.minutes);

  /// Winning days over the last [count] days, ending today.
  int winsInLast(int count) => _slice(count, 0).where((d) => d.isWin).length;

  /// Minutes over the [count] days that ended [offset] days ago — the window
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
