import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:rentmate/constants.dart';
import 'package:rentmate/screens/edit_profile_screen.dart';
import 'package:rentmate/screens/login_screen.dart';
import 'package:rentmate/screens/my_rentals_screen.dart';
import 'package:rentmate/screens/my_listings_rentals_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String? _userId;

  // Color scheme - matching app design
  static const Color _primaryBlue = Color(0xFF2563EB);
  static const Color _darkSlate = Color(0xFF1E293B);
  static const Color _lightGrey = Color(0xFFF1F5F9);
  static const Color _mediumGrey = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _userId = prefs.getString('user_id');

      if (_userId == null) {
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
        return;
      }

      final response = await http
          .get(
            Uri.parse('$kBaseUrl/user/$_userId'),
          )
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _userData = data['data'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        _showMessage('Failed to load profile');
      }
    } catch (e, s) {
      log(e.toString(), stackTrace: s);
      if (mounted) {
        setState(() => _isLoading = false);
        _showMessage('Network error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightGrey,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primaryBlue))
          : CustomScrollView(
              slivers: [
                // Header with profile info
                SliverToBoxAdapter(
                  child: _buildProfileHeader(),
                ),
                // Menu items
                SliverToBoxAdapter(
                  child: _buildMenuSection(),
                ),
              ],
            ),
    );
  }

  Widget _buildProfileHeader() {
    final name = _userData?['name'] ?? 'User';
    final email = _userData?['email'] ?? '';
    final profileImage = _userData?['profileImage'];
    final location = _userData?['location']?['addressName'];

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile Image
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _primaryBlue.withOpacity(0.1),
                  border: Border.all(
                    color: _primaryBlue.withOpacity(0.2),
                    width: 3,
                  ),
                ),
                child: ClipOval(
                  child: profileImage != null && profileImage.isNotEmpty
                      ? Image.network(
                          profileImage,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildInitials(name),
                        )
                      : _buildInitials(name),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _navigateToEditProfile,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _primaryBlue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Name
          Text(
            name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _darkSlate,
            ),
          ),

          const SizedBox(height: 4),

          // Email
          Text(
            email,
            style: const TextStyle(
              fontSize: 14,
              color: _mediumGrey,
            ),
          ),

          // Location
          if (location != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: _mediumGrey.withOpacity(0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  location,
                  style: TextStyle(
                    fontSize: 13,
                    color: _mediumGrey.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 20),

          // Edit Profile Button
          OutlinedButton.icon(
            onPressed: _navigateToEditProfile,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Edit Profile'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _primaryBlue,
              side: const BorderSide(color: _primaryBlue),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitials(String name) {
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Center(
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: _primaryBlue,
        ),
      ),
    );
  }

  Widget _buildMenuSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // _buildMenuItem(
          //   icon: Icons.inventory_2_outlined,
          //   title: 'My Rentals',
          //   subtitle: 'View items you\'re renting',
          //   onTap: () {
          //     if (_userId != null) {
          //       Navigator.push(
          //         context,
          //         MaterialPageRoute(
          //           builder: (_) => MyAddsListPage(currentUserId: _userId!),
          //         ),
          //       );
          //     }
          //   },
          // ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.shopping_bag_outlined,
            title: 'My Rentals',
            subtitle: 'Items you\'ve rented from others',
            onTap: () {
              if (_userId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MyRentalsScreen(currentUserId: _userId!),
                  ),
                );
              }
            },
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.receipt_long_outlined,
            title: 'My Listings\' Rentals',
            subtitle: 'Items others are renting from you',
            onTap: () {
              if (_userId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        MyListingsRentalsScreen(currentUserId: _userId!),
                  ),
                );
              }
            },
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy & Terms',
            subtitle: 'Read our policies',
            onTap: () => _showMessage('Privacy policy coming soon!'),
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.info_outline,
            title: 'About',
            subtitle: 'App version 1.0.0',
            onTap: () => _showAboutDialog(),
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.logout,
            title: 'Log Out',
            subtitle: 'Sign out of your account',
            isDestructive: true,
            onTap: _showLogoutDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.red.shade600 : _darkSlate;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDestructive
                    ? Colors.red.shade50
                    : _primaryBlue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isDestructive ? Colors.red.shade600 : _primaryBlue,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: _mediumGrey.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: _mediumGrey.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 74,
      color: Colors.grey.shade100,
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      _showMessage('Failed to log out');
    }
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('About RentMate'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version 1.0.0'),
            SizedBox(height: 8),
            Text(
              'RentMate is a peer-to-peer rental marketplace where you can rent items from others or list your own items for rent.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _navigateToEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(userData: _userData),
      ),
    );
    // Reload profile if changes were saved
    if (result == true) {
      _loadProfile();
    }
  }

  void _showMessage(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Colors.orange.shade700
            : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
