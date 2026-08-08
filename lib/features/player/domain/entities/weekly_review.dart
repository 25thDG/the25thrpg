import 'activity_history.dart';

/// How a track moved against the week before it.
enum TrendVerdict {
  /// Beat last week by a margin worth mentioning.
  up,

  /// Fell behind last week.
  down,

  /// Active, but level with last week.
  flat,

  /// Nothing logged this week or last.
  idle,
}

/// A track's week, next to the week before it.
///
/// [thisWeek] and [lastWeek] are minutes on the time tracks, and clean days on
/// sobriety — [isVerdictTrack] says which.
class TrackWeek {
  final HistoryTrack track;
  final int thisWeek;
  final int lastWeek;

  /// Days out of seven that counted as a win.
  final int activeDays;

  const TrackWeek({
    required this.track,
    required this.thisWeek,
    required this.lastWeek,
    required this.activeDays,
  });

  bool get isVerdictTrack => track.isVerdict;

  int get delta => thisWeek - lastWeek;

  /// Change against last week, 0–n. Null when last week was empty, because a
  /// jump from nothing is not a percentage.
  double? get changeFraction =>
      lastWeek == 0 ? null : (thisWeek - lastWeek) / lastWeek;

  TrendVerdict get verdict {
    if (thisWeek == 0 && lastWeek == 0) return TrendVerdict.idle;
    // A margin, so a single extra minute does not read as progress.
    final margin = isVerdictTrack ? 1 : 5;
    if (delta > margin) return TrendVerdict.up;
    if (delta < -margin) return TrendVerdict.down;
    return TrendVerdict.flat;
  }

  /// True when this track was worked before but not at all this week.
  bool get hasStalled => thisWeek == 0 && lastWeek > 0;
}

/// The last seven days, judged against the seven before them.
///
/// Deliberately built from [ActivityHistory] alone plus the global streak, so
/// the review and the calendar can never disagree.
class WeeklyReview {
  final List<TrackWeek> tracks;

  /// Consecutive days with at least one session, across everything.
  final int streakDays;

  /// Days out of seven with a win on any track at all.
  final int daysWorked;

  /// Inclusive window the review covers.
  final DateTime from;
  final DateTime to;

  const WeeklyReview({
    required this.tracks,
    required this.streakDays,
    required this.daysWorked,
    required this.from,
    required this.to,
  });

  factory WeeklyReview.from({
    required ActivityHistory history,
    required int streakDays,
  }) {
    final tracks = [
      for (final track in HistoryTrack.values)
        () {
          final s = history[track];
          return track.isVerdict
              ? TrackWeek(
                  track: track,
                  thisWeek: s.winsInLast(7),
                  lastWeek: s.winsInPrevious(7),
                  activeDays: s.winsInLast(7),
                )
              : TrackWeek(
                  track: track,
                  thisWeek: s.minutesInLast(7),
                  lastWeek: s.minutesInPrevious(7),
                  activeDays: s.winsInLast(7),
                );
        }(),
    ];

    // A day counts once, however many tracks were touched on it — so this has
    // to come from the day cells, not from summing the per-track counts.
    final worked = <DateTime>{};
    for (final track in HistoryTrack.values) {
      for (final cell in history[track].lastDays(7)) {
        if (cell.isWin) worked.add(cell.day);
      }
    }

    return WeeklyReview(
      tracks: tracks,
      streakDays: streakDays,
      daysWorked: worked.length,
      from: history.to.subtract(const Duration(days: 6)),
      to: history.to,
    );
  }

  TrackWeek byTrack(HistoryTrack track) =>
      tracks.firstWhere((t) => t.track == track);

  /// Nothing at all happened this week.
  bool get isBlank => tracks.every((t) => t.thisWeek == 0);

  /// Tracks that moved up, steepest first.
  List<TrackWeek> get gains => [
        for (final t in tracks)
          if (t.verdict == TrendVerdict.up) t,
      ]..sort((a, b) => b.delta.compareTo(a.delta));

  /// Tracks that fell back, steepest first.
  List<TrackWeek> get drops => [
        for (final t in tracks)
          if (t.verdict == TrendVerdict.down) t,
      ]..sort((a, b) => a.delta.compareTo(b.delta));

  /// Tracks that were worked before but went quiet this week.
  List<TrackWeek> get stalled => [
        for (final t in tracks)
          if (t.hasStalled) t,
      ];

  TrackWeek? get bestMove => gains.isEmpty ? null : gains.first;
  TrackWeek? get worstMove => drops.isEmpty ? null : drops.first;

  /// The track to push next week: the one that fell furthest, or failing that
  /// the one that went quiet. Null when everything is moving up.
  TrackWeek? get focus {
    if (drops.isNotEmpty) return drops.first;
    if (stalled.isNotEmpty) return stalled.first;
    return null;
  }

}
