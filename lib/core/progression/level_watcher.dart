import 'package:shared_preferences/shared_preferences.dart';

import '../../features/player/domain/entities/player_stats.dart';
import '../../features/player/domain/entities/skill_summary.dart';

/// One level gained since the last time the sheet was read.
class LevelUpEvent {
  /// The skill that rose, or null for the overall player level.
  final SkillId? skill;

  final int from;
  final int to;

  const LevelUpEvent({this.skill, required this.from, required this.to});

  bool get isPlayer => skill == null;

  /// Names the subject, not the event — the overlay header already says what
  /// happened.
  String get title => isPlayer ? 'PLAYER LEVEL' : skill!.displayName;

  /// How many levels were crossed at once — backfilling a long session can
  /// cross several.
  int get gained => to - from;
}

/// Notices when a level has gone up since the last check.
///
/// Levels are derived, not stored, so nothing in the database says "you just
/// levelled". The last value seen is kept in [SharedPreferences] and compared
/// on each load; the first ever check records a baseline silently, so
/// installing the app does not fire twelve celebrations at once.
class LevelWatcher {
  LevelWatcher._();

  static final LevelWatcher instance = LevelWatcher._();

  static const _prefPrefix = 'level_seen_';
  static const _prefPlayer = '${_prefPrefix}player';
  static const _prefBaseline = 'level_baseline_set';

  /// Compares [stats] against the last recorded levels and returns everything
  /// that went up. Always records the new values before returning.
  Future<List<LevelUpEvent>> check(PlayerStats stats) async {
    final prefs = await SharedPreferences.getInstance();
    final hasBaseline = prefs.getBool(_prefBaseline) ?? false;

    final events = <LevelUpEvent>[];

    for (final skill in stats.skills) {
      final key = '$_prefPrefix${skill.skill.name}';
      final seen = prefs.getInt(key);
      if (hasBaseline && seen != null && skill.level > seen) {
        events.add(
          LevelUpEvent(skill: skill.skill, from: seen, to: skill.level),
        );
      }
      await prefs.setInt(key, skill.level);
    }

    final seenPlayer = prefs.getInt(_prefPlayer);
    if (hasBaseline && seenPlayer != null && stats.playerLevel > seenPlayer) {
      events.add(LevelUpEvent(from: seenPlayer, to: stats.playerLevel));
    }
    await prefs.setInt(_prefPlayer, stats.playerLevel);

    if (!hasBaseline) await prefs.setBool(_prefBaseline, true);

    // Player level last, so it reads as the consequence of the skill gains.
    events.sort((a, b) {
      if (a.isPlayer == b.isPlayer) return 0;
      return a.isPlayer ? 1 : -1;
    });

    return events;
  }

  /// Forgets every recorded level, so the next [check] re-baselines instead of
  /// firing. Used when clearing state in development.
  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    for (final skill in SkillId.values) {
      await prefs.remove('$_prefPrefix${skill.name}');
    }
    await prefs.remove(_prefPlayer);
    await prefs.remove(_prefBaseline);
  }
}
