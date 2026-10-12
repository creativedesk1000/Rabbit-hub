import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    timezone_data.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      timezone.setLocalLocation(timezone.getLocation(info.identifier));
    } catch (_) {
      timezone.setLocalLocation(timezone.getLocation('UTC'));
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
    _initialized = true;
  }

  Future<bool> requestPermission() async {
    await initialize();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final androidAllowed = await android?.requestNotificationsPermission();
    final iosAllowed = await ios?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    return androidAllowed ?? iosAllowed ?? false;
  }

  Future<bool> scheduleKindlingReminders({
    required int breedingRecordId,
    required String doeName,
    required DateTime kindlingWindowStart,
    required DateTime typicalKindlingDate,
  }) async {
    if (!await requestPermission()) return false;
    final startId = breedingRecordId * 2;
    await schedule(
      id: startId,
      title: '$doeName: kindling window starts',
      body: 'Check her daily and make sure a clean nest box is available.',
      dueAt: _atReminderTime(kindlingWindowStart),
    );
    await schedule(
      id: startId + 1,
      title: '$doeName: typical kindling date',
      body:
          'This is an estimate. Check on her and contact a rabbit-savvy vet if concerned.',
      dueAt: _atReminderTime(typicalKindlingDate),
    );
    return true;
  }

  Future<void> cancelKindlingReminders(int breedingRecordId) async {
    final startId = breedingRecordId * 2;
    await cancel(startId);
    await cancel(startId + 1);
  }

  DateTime _atReminderTime(DateTime date) =>
      DateTime(date.year, date.month, date.day, 9);

  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime dueAt,
  }) async {
    await initialize();
    if (!dueAt.isAfter(DateTime.now())) return;
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: timezone.TZDateTime.from(dueAt, timezone.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'rabbit_hub_reminders',
          'Rabbit Hub reminders',
          channelDescription: 'Local reminders for rabbit care and records.',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: '$id',
    );
  }

  Future<void> cancel(int id) async {
    await initialize();
    await _plugin.cancel(id: id);
  }

  Future<void> cancelAll() async {
    await initialize();
    await _plugin.cancelAll();
  }
}
