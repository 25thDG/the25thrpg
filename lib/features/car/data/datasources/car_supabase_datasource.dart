import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/app_exception.dart';
import '../models/car_contract_model.dart';
import '../models/car_snapshot_model.dart';

const _userId = '1a67d50e-4263-4923-b4bc-1bfa57426aae';

class CarSupabaseDatasource {
  final SupabaseClient _client;

  const CarSupabaseDatasource(this._client);

  Future<CarContractModel> getContract() async {
    final List<Map<String, dynamic>> rows;
    try {
      rows = await _client
          .from('car_contracts')
          .select()
          .eq('user_id', _userId)
          .order('start_date', ascending: false)
          .limit(1);
    } catch (e) {
      throw NetworkException('Failed to fetch car contract: $e');
    }

    if (rows.isEmpty) {
      throw const NotFoundException('No car contract on record.');
    }
    return CarContractModel.fromMap(rows.first);
  }

  Future<List<CarSnapshotModel>> getAllActiveSnapshots() async {
    try {
      final List<Map<String, dynamic>> rows = await _client
          .from('car_snapshots')
          .select()
          .eq('user_id', _userId)
          .isFilter('deleted_at', null)
          .order('snapshot_date', ascending: true);

      return rows.map(CarSnapshotModel.fromMap).toList();
    } catch (e) {
      throw NetworkException('Failed to fetch car snapshots: $e');
    }
  }

  Future<CarSnapshotModel> upsertSnapshot({
    required int odometerKm,
    required DateTime snapshotDate,
  }) async {
    try {
      final Map<String, dynamic> row = await _client
          .from('car_snapshots')
          .upsert(
            {
              'user_id': _userId,
              'odometer_km': odometerKm,
              'snapshot_date': _formatDate(snapshotDate),
              'updated_at': DateTime.now().toUtc().toIso8601String(),
              // Clear soft-delete if re-adding a previously deleted day.
              'deleted_at': null,
            },
            onConflict: 'user_id,snapshot_date',
          )
          .select()
          .single();

      return CarSnapshotModel.fromMap(row);
    } catch (e) {
      throw NetworkException('Failed to save snapshot: $e');
    }
  }

  Future<void> softDeleteSnapshot(String id) async {
    try {
      await _client
          .from('car_snapshots')
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
