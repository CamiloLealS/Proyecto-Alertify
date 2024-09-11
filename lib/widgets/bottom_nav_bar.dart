import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabSelected;

  BottomNavBar({required this.currentIndex, required this.onTabSelected});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        onTabSelected(index);
      },
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.info),
          label: 'Informativo',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications),
          label: 'Sonido',
        ),
      ],
      selectedItemColor: Color.fromARGB(255, 0, 0, 0), // Azul
      unselectedItemColor: Color.fromARGB(255, 255, 255, 255),
    );
  }
}