import 'package:flutter/material.dart';
import 'package:rentmate/screens/chats/chat_list_screen.dart';
import 'package:rentmate/screens/create_ad_screen.dart';
import 'package:rentmate/screens/home/home_screen.dart';
import 'package:rentmate/screens/profile_screen.dart';
import 'package:rentmate/screens/Myadds_screen.dart';

class AppShell extends StatefulWidget {
  final String currentUserId; // Pass user ID from login/auth

  const AppShell({
    super.key,
    required this.currentUserId,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  // Build pages dynamically with required parameters
  List<Widget> _getPages() {
    return [
      HomeScreen(),
      ChatListScreen(currentUserId: widget.currentUserId),
      MyAddsListPage(
        currentUserId: widget.currentUserId,
      ),
      ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final pages = _getPages();

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: pages, // This keeps state of all pages
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateAdScreen(
                currentUserId: widget.currentUserId,
              ),
            ),
          );
        },
        backgroundColor: Colors.blue,
        child: Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        notchMargin: 8,
        elevation: 8,
        child: Container(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home_outlined,
                label: 'Home',
                index: 0,
              ),
              _buildNavItem(
                icon: Icons.chat_bubble_outline,
                label: 'Chats',
                index: 1,
              ),
              SizedBox(width: 40), // Space for FAB
              _buildNavItem(
                icon: Icons.receipt_long_outlined,
                label: 'My Ads',
                index: 2,
              ),
              _buildNavItem(
                icon: Icons.person_outline,
                label: 'Profile',
                index: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;

    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.blue : Colors.grey,
            size: 24,
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isSelected ? Colors.blue : Colors.grey,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
