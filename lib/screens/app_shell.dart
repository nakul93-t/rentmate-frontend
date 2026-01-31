import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rentmate/screens/chats/chat_list_screen.dart';
import 'package:rentmate/screens/create_ad_screen.dart';
import 'package:rentmate/screens/home/home_screen.dart';
import 'package:rentmate/screens/profile_screen.dart';
import 'package:rentmate/screens/my_listings_screen.dart';
import 'package:rentmate/theme/app_colors.dart';
import 'package:rentmate/widgets/glassmorphic_container.dart';
import 'package:rentmate/services/notification_service.dart';

class AppShell extends StatefulWidget {
  final String currentUserId;

  const AppShell({
    super.key,
    required this.currentUserId,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  int _unreadNotificationCount = 0;
  Timer? _notificationPollingTimer;

  @override
  void initState() {
    super.initState();
    _fetchUnreadCount();
    _startNotificationPolling();
  }

  @override
  void dispose() {
    _notificationPollingTimer?.cancel();
    super.dispose();
  }

  void _startNotificationPolling() {
    // Poll every 30 seconds
    _notificationPollingTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _fetchUnreadCount(),
    );
  }

  Future<void> _fetchUnreadCount() async {
    final count = await NotificationService.getUnreadCount(
      widget.currentUserId,
    );
    if (mounted && count != _unreadNotificationCount) {
      setState(() {
        _unreadNotificationCount = count;
      });
    }
  }

  /// Public method to refresh notification count after navigation returns
  void refreshNotificationCount() {
    _fetchUnreadCount();
  }

  List<Widget> _getPages() {
    return [
      HomeScreen(
        currentUserId: widget.currentUserId,
        unreadNotificationCount: _unreadNotificationCount,
        onNotificationViewed: _fetchUnreadCount,
      ),
      ChatListScreen(currentUserId: widget.currentUserId),
      MyListingsScreen(currentUserId: widget.currentUserId),
      ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final pages = _getPages();

    return Scaffold(
      extendBody: true,
      body: GradientBackground(
        child: IndexedStack(
          index: _selectedIndex,
          children: pages,
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.primaryGradient,
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryTeal.withAlpha(77),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
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
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0x15000000),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x15000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Home',
                index: 0,
              ),
              _buildNavItem(
                icon: Icons.chat_bubble_outline_rounded,
                activeIcon: Icons.chat_bubble_rounded,
                label: 'Chats',
                index: 1,
              ),
              const SizedBox(width: 56), // Space for FAB
              _buildNavItem(
                icon: Icons.inventory_2_outlined,
                activeIcon: Icons.inventory_2_rounded,
                label: 'Listings',
                index: 2,
              ),
              _buildNavItem(
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Account',
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
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon with circular background when active
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryTeal : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? Colors.white : AppColors.textSecondary,
                size: 22,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isSelected
                    ? AppColors.primaryTeal
                    : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
