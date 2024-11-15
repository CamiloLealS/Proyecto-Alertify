import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:project_alertify/screens/home.dart';
import 'package:project_alertify/screens/info_section.dart';
import 'package:project_alertify/widgets/bottom_nav_bar.dart';
import 'package:project_alertify/screens/disaster_history.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  print('se inicio firebase');
  await saveUserToken();
  print('se guardo token');
  await requestPermissions();
  print('se solicitaron permisos');

  try {
    await setupNotification();
    print('se inicio notificaciones');
  } catch (e) {
    print("Error en setupNotification: $e");

  }

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(MyApp());
}

final StreamController<Map<String, dynamic>> notificationStreamController = StreamController.broadcast();

Future<void> setupNotification() async {
  final prefs = await SharedPreferences.getInstance();

  const androidChannel = AndroidNotificationChannel(
    'disaster_alerts',
    'Alertas de Desastre',
    importance: Importance.max,
    enableVibration: true,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(androidChannel);

  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    String? userSound = prefs.getString('custom_sound');

    notificationStreamController.add({
      'title': message.notification?.title,
      'body': message.notification?.body,
      'data': message.data,
    });

    if (userSound != null){
      flutterLocalNotificationsPlugin.show(
        message.notification.hashCode,
        message.notification?.title,
        message.notification?.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'disaster_alerts',
            'Alertas de Desastre',
            channelDescription: 'Notificaciones urgentes sobre desastres naturales',
            sound: RawResourceAndroidNotificationSound(userSound),
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );
    } else {
      flutterLocalNotificationsPlugin.show(
        message.notification.hashCode,
        message.notification?.title,
        message.notification?.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'disaster_alerts',
            'Alertas de Desastre',
            channelDescription: 'Notificaciones urgentes sobre desastres naturales',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );
    }
    

    _showInAppDialog(message);
  });
}

void _showInAppDialog(RemoteMessage message) async {
  final prefs = await SharedPreferences.getInstance();
  String? userSound = prefs.getString('custom_sound');
  print(userSound);

  // Crea un reproductor de audio y reproduce el sonido personalizado
  final player = AudioPlayer();
  if (userSound != null) {
    await player.play(DeviceFileSource(userSound));  // Ruta del archivo de sonido
  }

  if (navigatorKey.currentContext != null) {
    showDialog(
      context: navigatorKey.currentContext!,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.deepPurple[700], // Fondo color llamativo
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0), // Bordes redondeados
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.yellow, size: 30), // Icono llamativo
            SizedBox(width: 10),
            Text(
              message.notification?.title ?? 'Alerta',
              style: TextStyle(
                color: Colors.white, 
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ],
        ),
        content: Text(
          message.notification?.body ?? 'Desastre cerca de tu posición',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 18,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.orangeAccent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                "OK",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  } else {
    print("El contexto es nulo; no se puede mostrar el diálogo.");
  }
}


Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  final prefs = await SharedPreferences.getInstance();
  String? userSound = prefs.getString('custom_sound');
  print(userSound);

  notificationStreamController.add({
      'title': message.notification?.title,
      'body': message.notification?.body,
      'data': message.data,
    });

  if (userSound != null){
    flutterLocalNotificationsPlugin.show(
      message.notification.hashCode,
      message.notification?.title,
      message.notification?.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'disaster_alerts',
          'Alertas de Desastre',
          channelDescription: 'Notificaciones urgentes sobre desastres naturales',
          sound: RawResourceAndroidNotificationSound(userSound),
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  } else {
    flutterLocalNotificationsPlugin.show(
      message.notification.hashCode,
      message.notification?.title,
      message.notification?.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'disaster_alerts',
          'Alertas de Desastre',
          channelDescription: 'Notificaciones urgentes sobre desastres naturales',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }
}


Future<void> saveUserToken() async {
  final FirebaseMessaging messaging = FirebaseMessaging.instance;
  String? token = await messaging.getToken();

  print('antes del if');
  if (token != null) {
    print('entra al if');
    String userId = await getOrCreateUserId();
    await FirebaseFirestore.instance.collection('usuarios').doc(userId).set({
      'fcmToken': token,
      'userId': userId,
    }, SetOptions(merge: true));
  }
  print('despues del if');
}

Future<String> getOrCreateUserId() async {
  final prefs = await SharedPreferences.getInstance();
  final existingUserId = prefs.getString('userId');

  if (existingUserId != null) return existingUserId;

  final newUserId = Uuid().v4();
  await prefs.setString('userId', newUserId);
  return newUserId;
}

Future<void> requestPermissions() async {
  await [
    Permission.notification,
    Permission.locationAlways,
    Permission.storage,
  ].request();

  if (await Permission.notification.isPermanentlyDenied) {
    openAppSettings();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Alertify',
      navigatorKey: navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: Color(0xFF007BFF),
          secondary: Color(0xFFFF4C4C),
        ),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      home: MainScreen(),
    );
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 1;

  final List<Widget> _screens = [
    InfoSection(),
    HomeScreen(),
    DisasterHistory(),
  ];

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTabSelected: _onTabSelected,
      ),
    );
  }
}