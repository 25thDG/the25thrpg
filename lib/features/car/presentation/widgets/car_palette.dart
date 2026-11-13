import 'package:flutter/material.dart';

import '../../domain/entities/car_stats.dart';

const carOnTrack = Color(0xFF26A69A);
const carOverAllowance = Color(0xFFF59E0B);
const carOverHardLimit = Color(0xFFEF5350);

/// The one colour that says how the contract year is heading. Every section
/// of the Car tab takes its accent from here so they cannot disagree.
Color carStatusColor(CarPaceStatus status) => switch (status) {
      CarPaceStatus.onTrack => carOnTrack,
      CarPaceStatus.overAllowance => carOverAllowance,
      CarPaceStatus.overHardLimit => carOverHardLimit,
    };
