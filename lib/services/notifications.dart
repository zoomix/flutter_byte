import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class Notifications {
  bool supported = false;
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  late final InitializationSettings initializationSettings;

  Notifications() {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()!
        .requestPermission();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    initializationSettings = const InitializationSettings(
      android: initializationSettingsAndroid,
    );
    initNotications();
  }

  void initNotications() async {
    supported = await flutterLocalNotificationsPlugin
            .initialize(initializationSettings) ??
        false;
    tz.initializeTimeZones();
  }

  void stopAllNotifications() async {
    if (!supported) {
      return;
    }
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  void notifyByte(Duration timeOffset) async {
    if (!supported) {
      return;
    }
    await flutterLocalNotificationsPlugin.cancelAll();
    await flutterLocalNotificationsPlugin.zonedSchedule(
        1,
        'Byte!',
        'Dags för byte!',
        tz.TZDateTime.now(tz.local).add(timeOffset),
        const NotificationDetails(
            android: AndroidNotificationDetails("if.channel", 'Byte',
                channelDescription: 'Notify when a change is due')),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime);
  }
}
