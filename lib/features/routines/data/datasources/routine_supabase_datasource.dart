import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/foundation.dart';
import '../../domain/entities/habit.dart';
import '../../domain/entities/routine.dart';

const _userId = '1a67d50e-4263-4923-b4bc-1bfa57426aae';

/// How far back completions are loaded.
///
/// The two-day rule only ever looks at the last few days; this window is for
/// the streak, the strip on each tile and the keep rate. Bounded so opening the
/// screen costs the same whether the app is a week or five years old.
const kCompletionWindowDays = 120;

/// `2026-08-09` — the shape Postgres wants for a `date` column.
String dateKey(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

class RoutineSupabaseDatasource {
  final SupabaseClient _client;

  const RoutineSupabaseDatasource(this._client);

  // ── Read ───────────────────────────────────────────────────────────────────

  /// Three queries, assembled locally: groups, their habits, and the recent
  /// completions. Joining in Postgres would return the routine row once per
  /// completion, which is far more data for no gain at this size.
  Future<RoutineBoard> getBoard() async {
    final since = dayOf(DateTime.now())
        .subtract(const Duration(days: kCompletionWindowDays));

    final [routineRows, habitRows, doneRows] = await Future.wait([
      _client
          .from('routines')
          .select('id, name, part_of_day, sort_order')
          .eq('user_id', _userId)
          .isFilter('deleted_at', null)
          .order('sort_order'),
      _client
          .from('routine_habits')
          .select('id, routine_id, name, sort_order, starts_on')
          .eq('user_id', _userId)
          .isFilter('deleted_at', null)
          .order('sort_order'),
      _client
          .from('routine_completions')
          .select('habit_id, done_on')
          .eq('user_id', _userId)
          .gte('done_on', dateKey(since)),
    ]);

    final completions = <String, Set<DateTime>>{};
    for (final row in (doneRows as List).cast<Map<String, dynamic>>()) {
      final habitId = row['habit_id'] as String;
      completions
          .putIfAbsent(habitId, () => <DateTime>{})
          .add(_parseDate(row['done_on'] as String));
    }

    final habitsByRoutine = <String, List<Habit>>{};
    for (final row in (habitRows as List).cast<Map<String, dynamic>>()) {
      final id = row['id'] as String;
      final routineId = row['routine_id'] as String;
      habitsByRoutine.putIfAbsent(routineId, () => <Habit>[]).add(
            Habit(
              id: id,
              routineId: routineId,
              name: row['name'] as String? ?? '',
              startsOn: _parseDate(row['starts_on'] as String),
              sortOrder: row['sort_order'] as int? ?? 0,
              completions: completions[id] ?? const {},
            ),
          );
    }

    final routines = [
      for (final row in (routineRows as List).cast<Map<String, dynamic>>())
        Routine(
          id: row['id'] as String,
          name: row['name'] as String? ?? '',
          partOfDay: PartOfDayX.parse(row['part_of_day'] as String?),
          sortOrder: row['sort_order'] as int? ?? 0,
          habits: habitsByRoutine[row['id'] as String] ?? const [],
        ),
    ];

    return RoutineBoard(routines: routines);
  }

  // ── Completions ────────────────────────────────────────────────────────────

  /// Ticks or clears one habit for one day.
  ///
  /// The insert is an upsert against the (habit_id, done_on) primary key, so
  /// double-tapping can never write the same day twice.
  Future<void> setCompletion({
    required String habitId,
    required DateTime day,
    required bool done,
  }) async {
    if (done) {
      await _client.from('routine_completions').upsert(
        {
          'habit_id': habitId,
          'user_id': _userId,
          'done_on': dateKey(dayOf(day)),
        },
        onConflict: 'habit_id,done_on',
      );
    } else {
      await _client
          .from('routine_completions')
          .delete()
          .eq('habit_id', habitId)
          .eq('done_on', dateKey(dayOf(day)));
    }
  }

  // ── Routines ───────────────────────────────────────────────────────────────

  Future<void> addRoutine({
    required String name,
    required PartOfDay partOfDay,
    required int sortOrder,
  }) async {
    await _client.from('routines').insert({
      'user_id': _userId,
      'name': name,
      'part_of_day': partOfDay.dbValue,
      'sort_order': sortOrder,
    });
  }

  Future<void> updateRoutine({
    required String id,
    String? name,
    PartOfDay? partOfDay,
  }) async {
    final patch = <String, dynamic>{
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (name != null) patch['name'] = name;
    if (partOfDay != null) patch['part_of_day'] = partOfDay.dbValue;

    await _client.from('routines').update(patch).eq('id', id);
  }

  /// Soft delete, matching every other table here — the habits and their
  /// history stay behind the row rather than being destroyed.
  Future<void> deleteRoutine(String id) async {
    await _client.from('routines').update({
      'deleted_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
  }

  // ── Habits ─────────────────────────────────────────────────────────────────

  Future<void> addHabit({
    required String routineId,
    required String name,
    required int sortOrder,
  }) async {
    await _client.from('routine_habits').insert({
      'routine_id': routineId,
      'user_id': _userId,
      'name': name,
      'sort_order': sortOrder,
      // Today, so the rule never judges the days before it existed.
      'starts_on': dateKey(dayOf(DateTime.now())),
    });
  }

  Future<void> updateHabit({required String id, String? name}) async {
    final patch = <String, dynamic>{
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (name != null) patch['name'] = name;

    await _client.from('routine_habits').update(patch).eq('id', id);
  }

  Future<void> deleteHabit(String id) async {
    await _client.from('routine_habits').update({
      'deleted_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
  }

  /// `date` columns come back as `YYYY-MM-DD` with no zone — parsing them as
  /// local keeps them aligned with the local midnights the rule uses.
  static DateTime _parseDate(String value) {
    final parts = value.split('-').map(int.parse).toList();
    return DateTime(parts[0], parts[1], parts[2]);
  }
}
