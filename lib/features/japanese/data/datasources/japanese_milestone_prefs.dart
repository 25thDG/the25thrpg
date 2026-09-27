import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/japanese_milestone.dart';

const _prefHours = 'jp_milestone_hours';
const _prefLabel = 'jp_milestone_label';

/// The milestone is a setting, not a record, so it lives on the device.
class JapaneseMilestonePrefs {
  const JapaneseMilestonePrefs();

  Future<JapaneseMilestone> load() async {
    final prefs = await SharedPreferences.getInstance();
    return JapaneseMilestone(
      targetHours:
          prefs.getInt(_prefHours) ?? JapaneseMilestone.fallback.targetHours,
      label: prefs.getString(_prefLabel) ?? JapaneseMilestone.fallback.label,
    );
  }

  Future<void> save(JapaneseMilestone milestone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefHours, milestone.targetHours);
    await prefs.setString(_prefLabel, milestone.label);
  }
}
