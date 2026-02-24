import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/app_exception.dart';
import '../models/wealth_snapshot_model.dart';

const _userId = '1a67d50e-4263-4923-b4bc-1bfa57426aae';

class WealthSupabaseDatasource {
  final SupabaseClient _client;

  const WealthSupabaseDatasource(this._client);

  Future<List<WealthSnapshotModel>> getAllActiveSnapshots() async {
    try {
      final List<Map<String, dynamic>> rows = await _client
          .from('wealth_snapshots')
          .select()
          .eq('user_id', _userId)
          .isFilter('deleted_at', null)
          .order('snapshot_month', ascending: true);

      return rows.map(WealthSnapshotModel.fromMap).toList();
    } catch (e) {
      throw NetworkException('Failed to fetch wealth snapshots: $e');
    }
  }

  Future<WealthSnapshotModel> upsertSnapshot({
    required double netWorthEur,
    required DateTime snapshotMonth,
  }) async {
    try {
      final monthStr = _formatDate(snapshotMonth);

      final Map<String, dynamic> row = await _client
          .from('wealth_snapshots')
          .upsert(
            {
              'user_id': _userId,
              'net_worth_eur': netWorthEur,
              'snapshot_month': monthStr,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
              // Clear soft-delete if re-adding a previously deleted month.
              'deleted_at': null,
            },
            onConflict: 'user_id,snapshot_month',
          )
          .select()
          .single();

      return WealthSnapshotModel.fromMap(row);
    } catch (e) {
      throw NetworkException('Failed to save snapshot: $e');
    }
  }

  Future<void> softDeleteSnapshot(String id) async {
    try {
      await _client
          .from('wealth_snapshots')
          .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', id);
    } catch (e) {
      throw NetworkException('Failed to delete snapshot: $e');
    }
  }

  /// Formats a [DateTime] as `YYYY-MM-DD` without any package dependency.
  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
