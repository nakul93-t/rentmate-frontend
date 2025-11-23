import 'package:flutter/material.dart';
import 'package:rentmate/screens/chat_screen.dart';
import 'package:rentmate/screens/home_screen.dart';
import 'package:rentmate/screens/profile_screen.dart';
import 'package:rentmate/screens/Myadds_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

List<Widget> pages = [
  HomeScreen(),
  ChatScreen(),
  MyAddsListPage(),
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

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _selectedIndex = 2; // Ads page (middle)
          });
        },
        child: Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(
                Icons.home,
                color: _selectedIndex == 0 ? Colors.blue : Colors.grey,
              ),
              onPressed: () => setState(() => _selectedIndex = 0),
            ),

            IconButton(
              icon: Icon(
                Icons.chat,
                color: _selectedIndex == 1 ? Colors.blue : Colors.grey,
              ),
              onPressed: () => setState(() => _selectedIndex = 1),
            ),

            SizedBox(width: 40), // space for FAB

            IconButton(
              icon: Icon(
                Icons.ads_click,
                color: _selectedIndex == 2 ? Colors.blue : Colors.grey,
              ),
              onPressed: () => setState(() => _selectedIndex = 2),
            ),

            IconButton(
              icon: Icon(
                Icons.person,
                color: _selectedIndex == 3 ? Colors.blue : Colors.grey,
              ),
              onPressed: () => setState(() => _selectedIndex = 3),
            ),
          ],
        ),
      ),
    );
    ;
  }
}
