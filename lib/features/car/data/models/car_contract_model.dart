import '../../domain/entities/car_contract.dart';

class CarContractModel extends CarContract {
  const CarContractModel({
    required super.id,
    required super.startDate,
    required super.startOdometerKm,
    required super.termYears,
    required super.yearlyAllowanceKm,
    required super.yearlyHardLimitKm,
  });

  factory CarContractModel.fromMap(Map<String, dynamic> map) {
    return CarContractModel(
      id: map['id'] as String,
      // date type — parse as-is, no timezone conversion needed.
      startDate: DateTime.parse(map['start_date'] as String),
      startOdometerKm: (map['start_odometer_km'] as num).toInt(),
      termYears: (map['term_years'] as num).toInt(),
      yearlyAllowanceKm: (map['yearly_allowance_km'] as num).toInt(),
      yearlyHardLimitKm: (map['yearly_hard_limit_km'] as num).toInt(),
    );
  }
}
