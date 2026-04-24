import 'package:supabase_flutter/supabase_flutter.dart';

const _userId = '1a67d50e-4263-4923-b4bc-1bfa57426aae';
const _mindfulnessSkillId = '6e3b1f81-5733-4ada-a65a-d06d923f94ee';

class TodayStatus {
  final int jpMinutes;
  final int mindMinutes;

  /// null = not logged today; true = clean; false = relapsed
  final bool? isClean;
  final int budgetCents;

  const TodayStatus({
    required this.jpMinutes,
    required this.mindMinutes,
    required this.isClean,
    required this.budgetCents,
  });
}

class TodayStatusDatasource {
  final SupabaseClient _client;

  const TodayStatusDatasource(this._client);

  Future<TodayStatus> fetch() async {
    final now = DateTime.now();
    final todayStart =
        DateTime(now.year, now.month, now.day).toUtc().toIso8601String();
    final tomorrowStart =
        DateTime(now.year, now.month, now.day + 1).toUtc().toIso8601String();

    final (jpRes, mindRes, budgetRes) = await (
      _client
          .from('japanese_sessions')
          .select('minutes')
          .eq('user_id', _userId)
          .gte('session_at', todayStart)
          .lt('session_at', tomorrowStart)
          .isFilter('deleted_at', null),
      _client
          .from('skill_sessions')
          .select('minutes, category')
          .eq('user_id', _userId)
          .eq('skill_id', _mindfulnessSkillId)
          .gte('session_at', todayStart)
          .lt('session_at', tomorrowStart)
          .isFilter('deleted_at', null),
      _client
          .from('budget_transactions')
          .select('amount_cents')
          .eq('user_id', _userId)
          .gte('spent_at', todayStart)
          .lt('spent_at', tomorrowStart)
          .isFilter('deleted_at', null),
    ).wait;

    int jpMinutes = 0;
    for (final row in (jpRes as List).cast<Map<String, dynamic>>()) {
      jpMinutes += (row['minutes'] as int? ?? 0);
    }

    int mindMinutes = 0;
    bool? isClean;
    for (final row in (mindRes as List).cast<Map<String, dynamic>>()) {
      final cat = row['category'] as String? ?? '';
      if (cat == 'addiction') {
        isClean = true;
      } else if (cat == 'addiction_relapse') {
        isClean = false;
      } else {
        mindMinutes += (row['minutes'] as int? ?? 0);
      }
    }

    int budgetCents = 0;
    for (final row in (budgetRes as List).cast<Map<String, dynamic>>()) {
      budgetCents += (row['amount_cents'] as int? ?? 0);
    }

    return TodayStatus(
      jpMinutes: jpMinutes,
      mindMinutes: mindMinutes,
      isClean: isClean,
      budgetCents: budgetCents,
    );
  }
}
