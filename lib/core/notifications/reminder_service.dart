import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

const _prefEnabled = 'reminder_enabled';
const _prefHour = 'reminder_hour';
const _prefMinute = 'reminder_minute';

/// Fixed id — rescheduling reuses it so there is only ever one daily reminder.
const _reminderId = 1001;

const _channelId = 'daily_reminder';
const _channelName = 'Daily reminder';
const _channelDescription = 'A nudge to log today on your character sheet.';

/// Default reminder time when the user turns reminders on: 20:00.
const _defaultTime = TimeOfDay(hour: 20, minute: 0);

/// Outcome of arming a reminder, so the UI can explain what actually failed.
enum ReminderStatus {
  /// Scheduled successfully.
  ok,

  /// The OS refused — notifications are switched off for the app.
  denied,

  /// The native plugin did not answer. In practice this means the running
  /// binary predates the plugin: a hot restart does not install native code,
  /// so the app needs a full stop and re-run.
  unavailable,
}

/// Schedules a single repeating daily reminder to log the day.
///
/// State lives in [SharedPreferences] so the toggle survives restarts, and the
/// notification itself is owned by the OS — nothing needs to run in the
/// background for it to fire.
class ReminderService extends ChangeNotifier {
  ReminderService._();

  static final ReminderService instance = ReminderService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  bool _ready = false;
  bool _enabled = false;
  TimeOfDay _time = _defaultTime;

  bool get isEnabled => _enabled;
  TimeOfDay get time => _time;
  bool get isReady => _ready;

  /// Loads timezone data and the saved preference. Safe to call once at start.
  Future<void> init() async {
    if (_ready) return;

    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      // Fall back to UTC rather than failing app start; the user can still
      // toggle the reminder, it just may fire on a UTC wall clock.
    }

    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            // Permission is requested when the user opts in, not at app start.
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
          macOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
    } on MissingPluginException {
      // Native side is not present in this binary. The toggle will report
      // "unavailable" rather than throwing when the user tries it.
    }

    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_prefEnabled) ?? false;
    _time = TimeOfDay(
      hour: prefs.getInt(_prefHour) ?? _defaultTime.hour,
      minute: prefs.getInt(_prefMinute) ?? _defaultTime.minute,
    );

    _ready = true;

    // Re-arm on launch — an OS update or reboot can drop pending alarms.
    if (_enabled) await _schedule();

    notifyListeners();
  }

  /// Turns the daily reminder on at [at] (defaults to the saved time).
  Future<ReminderStatus> enable({TimeOfDay? at}) async {
    final status = await _requestPermission();
    if (status != ReminderStatus.ok) return status;

    _time = at ?? _time;
    _enabled = true;
    await _persist();

    final scheduled = await _schedule();
    if (!scheduled) {
      _enabled = false;
      await _persist();
      notifyListeners();
      return ReminderStatus.unavailable;
    }

    notifyListeners();
    return ReminderStatus.ok;
  }

  Future<void> disable() async {
    _enabled = false;
    await _persist();
    try {
      await _plugin.cancel(id: _reminderId);
    } on PlatformException {
      // Nothing scheduled to cancel — the toggle is off either way.
    } on MissingPluginException {
      // Same.
    }
    notifyListeners();
  }

  /// Moves the reminder to a new time, rescheduling if it is already on.
  Future<void> setTime(TimeOfDay at) async {
    _time = at;
    await _persist();
    if (_enabled) await _schedule();
    notifyListeners();
  }

  /// Fires a notification straight away so the user can confirm it works.
  Future<ReminderStatus> sendTestNotification() async {
    final status = await _requestPermission();
    if (status != ReminderStatus.ok) return status;
    try {
      await _plugin.show(
        id: _reminderId + 1,
        title: 'THE 25TH',
        body: 'Reminders are on. This is what they look like.',
        notificationDetails: _details(),
      );
      return ReminderStatus.ok;
    } on PlatformException {
      return ReminderStatus.unavailable;
    } on MissingPluginException {
      return ReminderStatus.unavailable;
    }
  }

  // ── Internals ──────────────────────────────────────────────────────────────

  /// Asks the current platform for permission. Every branch is wrapped because
  /// a missing native implementation throws rather than returning false.
  Future<ReminderStatus> _requestPermission() async {
    ReminderStatus verdict(bool? granted) =>
        (granted ?? false) ? ReminderStatus.ok : ReminderStatus.denied;

    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        return verdict(await android.requestNotificationsPermission());
      }

      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        return verdict(
          await ios.requestPermissions(alert: true, badge: true, sound: true),
        );
      }

      final macos = _plugin.resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin>();
      if (macos != null) {
        return verdict(
          await macos.requestPermissions(alert: true, badge: true, sound: true),
        );
      }

      // No implementation for this platform at all (web, desktop).
      return ReminderStatus.unavailable;
    } on MissingPluginException {
      return ReminderStatus.unavailable;
    } on PlatformException {
      return ReminderStatus.unavailable;
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefEnabled, _enabled);
    await prefs.setInt(_prefHour, _time.hour);
    await prefs.setInt(_prefMinute, _time.minute);
  }

  NotificationDetails _details() => const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      );

  /// Returns false when the platform could not take the schedule.
  Future<bool> _schedule() async {
    try {
      await _plugin.cancel(id: _reminderId);
      await _plugin.zonedSchedule(
        id: _reminderId,
        title: 'THE 25TH',
        body: "Today isn't logged yet. Keep the streak alive.",
        scheduledDate: _nextOccurrence(),
        notificationDetails: _details(),
        // A daily nudge does not need to-the-second accuracy, and inexact
        // alarms avoid the special-access grant that exact alarms need on
        // Android 14+.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      return true;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// The next time the clock reads [_time] — today if it has not passed yet,
  /// otherwise tomorrow.
  tz.TZDateTime _nextOccurrence() {
    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      _time.hour,
      _time.minute,
    );
    if (!next.isAfter(now)) {
      next = next.add(const Duration(days: 1));
    }
    return next;
  }
}
