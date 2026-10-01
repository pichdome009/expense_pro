import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _kDailyReminderId = 1001;
  static const _kBudgetAlertBaseId = 2001;

  static const _kDailyReminderEnabledKey = 'notif_daily_reminder_enabled_v1';
  static const _kDailyReminderHourKey = 'notif_daily_reminder_hour_v1';
  static const _kDailyReminderMinuteKey = 'notif_daily_reminder_minute_v1';
  static const _kBudgetAlertsEnabledKey = 'notif_budget_alerts_enabled_v1';

  static const _channelId = 'expense_pro_channel';
  static const _channelName = 'Expense Pro Notifications';
  static const _channelDesc = 'ការរំលឹកកត់ត្រាចំណាយ និងការព្រមានពីកញ្ចប់ថវិកា';

  static Future<void> init() async {
    try {
      // Local push notifications are specifically for mobile devices (Android & iOS)
      if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;

      // 1. Initialize timezone database and set device local timezone
      _ensureTimeZonesInitialized();

      // 2. Setup Android & iOS settings
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _plugin.initialize(settings: initSettings);

      // 3. Create Android notification channel
      final androidImplementation = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDesc,
            importance: Importance.max,
            enableVibration: true,
          ),
        );
      }

      // 4. If daily reminder is enabled, ensure schedule is active
      final isDaily = await isDailyReminderEnabled();
      if (isDaily) {
        final hour = await getDailyReminderHour();
        final min = await getDailyReminderMinute();
        await scheduleDailyReminder(hour: hour, minute: min);
      }
    } catch (e) {
      debugPrint('NotificationService init error: $e');
    }
  }

  /// Ensure timezone database is loaded and local location is configured
  static void _ensureTimeZonesInitialized() {
    try {
      tz.initializeTimeZones();
      _configureLocalTimeZone();
    } catch (e) {
      debugPrint('Initialize timezones error: $e');
    }
  }

  /// Match device current timezone offset to correct IANA timezone location
  static void _configureLocalTimeZone() {
    try {
      final now = DateTime.now();
      final offset = now.timeZoneOffset;
      final name = now.timeZoneName;

      // 1. Check if name directly matches a location in database
      if (tz.timeZoneDatabase.locations.containsKey(name)) {
        tz.setLocalLocation(tz.getLocation(name));
        return;
      }

      // 2. Cambodia / Indochina standard time (UTC+7)
      if (offset.inHours == 7 && offset.inMinutes == 420) {
        if (tz.timeZoneDatabase.locations.containsKey('Asia/Phnom_Penh')) {
          tz.setLocalLocation(tz.getLocation('Asia/Phnom_Penh'));
          return;
        } else if (tz.timeZoneDatabase.locations.containsKey('Asia/Bangkok')) {
          tz.setLocalLocation(tz.getLocation('Asia/Bangkok'));
          return;
        }
      }

      // 3. Fallback: match any location with identical current timezone offset
      for (final loc in tz.timeZoneDatabase.locations.values) {
        final locTime = tz.TZDateTime.now(loc);
        if (locTime.timeZoneOffset == offset) {
          tz.setLocalLocation(loc);
          return;
        }
      }
    } catch (e) {
      debugPrint('Configure local timezone error: $e');
    }
  }

  /// Request permissions for iOS and Android 13+
  static Future<bool> requestPermissions() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return false;
    bool granted = false;

    // Android 13+
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      final res = await androidImpl.requestNotificationsPermission();
      granted = res ?? false;
    }

    // iOS
    final iosImpl = _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (iosImpl != null) {
      final res = await iosImpl.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      granted = res ?? false;
    }

    return granted;
  }

  /// Schedule daily recurring reminder at specified hour and minute (default 20:00)
  static Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;
    await cancelDailyReminder();

    _ensureTimeZonesInitialized();

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // If time for today already passed, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _plugin.zonedSchedule(
      id: _kDailyReminderId,
      title: 'Expense Pro 📝',
      body: '«តើថ្ងៃនេះអ្នកបានចំណាយអ្វីខ្លះ? កុំភ្លេចកត់ត្រាទុកណា៎!»',
      scheduledDate: scheduledDate,
      notificationDetails: notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Cancel daily reminder notification
  static Future<void> cancelDailyReminder() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;
    await _plugin.cancel(id: _kDailyReminderId);
  }

  /// Trigger instant Budget Alert notification
  static Future<void> showBudgetAlert({
    required String title,
    required String body,
    int? id,
  }) async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;
    final enabled = await isBudgetAlertsEnabled();
    if (!enabled) return;

    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _plugin.show(
      id: id ?? _kBudgetAlertBaseId,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
    );
  }

  // --- Preference Persistence ---

  static Future<bool> isDailyReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kDailyReminderEnabledKey) ?? true;
  }

  static Future<void> setDailyReminderEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDailyReminderEnabledKey, enabled);
  }

  static Future<int> getDailyReminderHour() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kDailyReminderHourKey) ?? 20; // 8:00 PM default
  }

  static Future<int> getDailyReminderMinute() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kDailyReminderMinuteKey) ?? 0;
  }

  static Future<void> setDailyReminderTime(int hour, int minute) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kDailyReminderHourKey, hour);
    await prefs.setInt(_kDailyReminderMinuteKey, minute);
  }

  static Future<bool> isBudgetAlertsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kBudgetAlertsEnabledKey) ?? true;
  }

  static Future<void> setBudgetAlertsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kBudgetAlertsEnabledKey, enabled);
  }
}
