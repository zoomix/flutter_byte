import 'package:lag_byte/utils.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rxdart/subjects.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationsMessagebus {
  final _cancelSubject = BehaviorSubject<int>();
  Stream<int> get cancelStream => _cancelSubject.stream;
  void cancel() => _cancelSubject.add(DateTime.now().millisecondsSinceEpoch);

  final _resetSubject = BehaviorSubject<int>();
  Stream<int> get resetStream => _resetSubject.stream;
  void reset() => _resetSubject.add(DateTime.now().millisecondsSinceEpoch);

  final _notifyByteSubject = BehaviorSubject<Duration>();
  Stream<Duration> get notifyByteStream => _notifyByteSubject.stream;
  void notifyByte(Duration timeUntilByte) =>
      _notifyByteSubject.add(timeUntilByte);
}

class Notifications {
  bool supported = false;
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  late final InitializationSettings initializationSettings;

  final NotificationsMessagebus _notificationMB =
      locator<NotificationsMessagebus>();

  DateTime? lastNotificationUpdate;

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
    _notificationMB.cancelStream.listen((_) => _stopAllNotifications());
    _notificationMB.notifyByteStream
        .listen((timeUntilByte) => _notifyByte(timeUntilByte));
  }

  void initNotications() async {
    supported = await flutterLocalNotificationsPlugin
            .initialize(initializationSettings) ??
        false;
    tz.initializeTimeZones();
  }

  void _stopAllNotifications() async {
    if (!supported) {
      return;
    }
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  void _notifyByte(Duration timeUntilByte) async {
    if (!supported) {
      return;
    }
    if (lastNotificationUpdate != null &&
        DateTime.now().difference(lastNotificationUpdate!).inSeconds < 1) {
      return;
    }

    lastNotificationUpdate = DateTime.now();
    await flutterLocalNotificationsPlugin.cancelAll();
    await flutterLocalNotificationsPlugin.zonedSchedule(
        1,
        'Byte!',
        'Dags för byte!',
        tz.TZDateTime.now(tz.local).add(timeUntilByte),
        const NotificationDetails(
            android: AndroidNotificationDetails("if.channel", 'Byte',
                channelDescription: 'Notify when a change is due')),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime);
  }
}
