import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project_alertify/screens/home.dart';
import 'package:project_alertify/screens/info_section.dart';
import 'package:project_alertify/screens/sound_customization.dart';
import 'package:project_alertify/widgets/bottom_nav_bar.dart';
import 'package:project_alertify/services/websocket_service.dart';
import 'package:project_alertify/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  NotificationService notificationService = NotificationService();
  await notificationService.init();
  
  runApp(MyApp(notificationService: notificationService ));
}

class MyApp extends StatelessWidget {
  final NotificationService notificationService;

  const MyApp({super.key, required this.notificationService});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<NotificationService>.value(value: notificationService,),
      ],
      child: MaterialApp(
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
        home: MainScreen(notificationService: notificationService),
      ),
    );
  }
}
class MainScreen extends StatefulWidget {
  final NotificationService notificationService;

  MainScreen({required this.notificationService});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 1;
  final List<Widget> _screens = [
    InfoSection(),
    HomeScreen(),
    SoundCustomization(),
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
      
      final notificationService = Provider.of<NotificationService>(context, listen:false);
      notificationService.showNotification('Hello World!!');
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
