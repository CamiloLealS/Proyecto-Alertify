import 'package:flutter/material.dart';
import 'package:project_alertify/screens/home.dart';
import 'package:project_alertify/screens/info_section.dart';
import 'package:project_alertify/screens/sound_customization.dart';
import 'package:project_alertify/widgets/bottom_nav_bar.dart';

void main() {
  runApp(const MyApp());
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


  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
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
