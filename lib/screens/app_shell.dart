import 'package:flutter/material.dart';
import 'package:rentmate/screens/chat_screen.dart';
import 'package:rentmate/screens/home_screen.dart';
import 'package:rentmate/screens/profile_screen.dart';
import 'package:rentmate/screens/second_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

List<Widget> pages = [
  HomeScreen(),
  ChatScreen(),
  SecondScreen(),
  ProfileScreen(),
];

List<BottomNavigationBarItem> bottomNavigationBarItems = [
  BottomNavigationBarItem(
    icon: Icon(
      Icons.home,
    ),
    label: 'Home',
    activeIcon: Icon(
      Icons.home_outlined,
      color: const Color.fromARGB(255, 19, 19, 18),
    ),
  ),
  BottomNavigationBarItem(
    icon: Icon(Icons.chat),
    label: 'Messages',
    activeIcon: Icon(
      Icons.chat_outlined,
      color: const Color.fromARGB(255, 19, 19, 18),
    ),
  ),
  BottomNavigationBarItem(
    icon: Icon(Icons.ads_click),
    label: 'Ads',
    activeIcon: Icon(
      Icons.ads_click,
      color: const Color.fromARGB(255, 19, 19, 18),
    ),
  ),
  BottomNavigationBarItem(
    icon: Icon(Icons.person),
    label: 'Account',
    activeIcon: Icon(
      Icons.person_outline,
      color: const Color.fromARGB(255, 19, 19, 18),
    ),
  ),
];

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        showUnselectedLabels: true,
        currentIndex: _selectedIndex,
        selectedItemColor: const Color.fromARGB(
          255,
          37,
          153,
          248,
        ), // selected icon color
        unselectedItemColor: const Color.fromARGB(255, 133, 145, 151),
        onTap: (value) {
          print(value);
          setState(() {
            _selectedIndex = value;
          });
        },
        items: bottomNavigationBarItems,
      ),
    );
  }
}
