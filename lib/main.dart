import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:project_alertify/screens/home.dart';
import 'package:project_alertify/screens/info_section.dart';
import 'package:project_alertify/widgets/bottom_nav_bar.dart';
import 'package:project_alertify/services/websocket_service.dart';
import 'package:project_alertify/screens/disaster_history.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await saveUserToken();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher'); // Asegúrate de tener un ícono de notificación.

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    // iOS: puedes agregar la configuración para iOS aquí si es necesario
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  runApp(MyApp());
}

Future<void> saveUserToken() async {
  final FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Obtener el token de FCM
  String? token = await messaging.getToken();

  if (token != null) {
    // Obtener o crear un userId único
    String userId = await getOrCreateUserId();

    // Guardar el token y el userId en Firestore
    await FirebaseFirestore.instance.collection('usuarios').doc(userId).set({
      'fcmToken': token,
      'userId': userId,
    }, SetOptions(merge: true));
  }
}

Future<String> getOrCreateUserId() async {
  final prefs = await SharedPreferences.getInstance();
  final existingUserId = prefs.getString('userId');

  if (existingUserId != null) {
    // Si ya existe un userId almacenado, úsalo
    return existingUserId;
  } else {
    // Si no existe, crea uno nuevo
    final newUserId = Uuid().v4(); // Genera un UUID único
    await prefs.setString('userId', newUserId);
    return newUserId;
  }
}

Future<void> requestPermissions() async {
  // Revisar el estado de cada permiso y solicitar si no ha sido otorgado
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }

  if (await Permission.locationAlways.isDenied) {
    await Permission.locationAlways.request();
  }

  if (await Permission.storage.isDenied) {
    await Permission.storage.request();
  }

  // Aquí puedes manejar el rechazo permanente de permisos si es necesario
  if (await Permission.notification.isPermanentlyDenied) {
    openAppSettings(); // Abre la configuración de la app para que el usuario otorgue manualmente los permisos
  }
}

class MyApp extends StatelessWidget {

  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Alertify',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: Color(0xFF007BFF),   // Azul
          secondary: Color(0xFFFF4C4C), // Rojo
        ),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      home: MainScreen(),
    );
  }
}
class MainScreen extends StatefulWidget {

  MainScreen();

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 1;

  final List<Widget> _screens = [
    InfoSection(),
    HomeScreen(),
    DisasterHistory()
  ];

  late WebSocketService webSocketService;



  @override
  void initState() {
    super.initState();
    webSocketService = WebSocketService();

  }

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  void dispose() {
    webSocketService.disconnect();
    super.dispose();
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
