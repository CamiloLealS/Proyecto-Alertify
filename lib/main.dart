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

Future<void> setupNotification() async {
  final prefs = await SharedPreferences.getInstance();
  String? customSound = prefs.getString('selectedSound') ?? 'default_sound1';

  const androidChannel = AndroidNotificationChannel(
    'disaster_alerts',
    'Alertas de Desastre',
    importance: Importance.max,
    enableVibration: true,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(androidChannel);
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  final prefs = await SharedPreferences.getInstance();
  String? userSound = prefs.getString('custom_sound') ?? 'default_sound';

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
        importance: Importance.high,
        priority: Priority.high,
      ),
    ),
  );
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
