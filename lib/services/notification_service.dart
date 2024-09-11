import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    
    AndroidNotificationChannel channel = AndroidNotificationChannel(
      'your_channel_id', // ID del canal
      'Alert Notifications', // Nombre del canal
      description: 'This channel is used for alert notifications.',
      importance: Importance.max,
    );

    await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);

    print('se inicio el servicio');
  }

  Future<void> showNotification(String data) async {
    print('entro a funcion mostrar notificacion');
    final prefs = await SharedPreferences.getInstance();
    String? customSound = prefs.getString('selectedSound') ?? 'default_sound1';

    final AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'your_channel_id', // Channel ID
      'Alert Notifications', // Channel Name
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
    );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(0, 'Nuevo Mensaje', data, platformChannelSpecifics);
    print('se envio notificacion');
  }
}