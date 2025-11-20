import 'package:flutter/material.dart';
import 'package:rentmate/screens/home_screen.dart';
import 'package:rentmate/screens/second_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _selectedIndex == 0 ? HomeScreen() : SecondScreen(),
      bottomNavigationBar: BottomNavigationBar(
        onTap: (value) {
          print(value);
          setState(() {
            _selectedIndex = value;
          });
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.bubble_chart), label: 'dsd'),
        ],
      ),
    );
  }
}
