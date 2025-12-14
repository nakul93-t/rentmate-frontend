import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rentmate/screens/app_shell.dart';
import 'package:rentmate/screens/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        textTheme: GoogleFonts.nunitoSansTextTheme(),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
      ),
      home: AuthWrapper(),
    );
  }
}

// This checks if user is logged in
class AuthWrapper extends StatefulWidget {
  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool isLoading = true;
  String? userId;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Check if user is logged in (using SharedPreferences)
    final prefs = await SharedPreferences.getInstance();
    final storedUserId = prefs.getString('user_id');

    setState(() {
      userId = storedUserId;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // If userId exists, go to AppShell, otherwise go to Login
    if (userId != null) {
      return AppShell(currentUserId: userId!);
    } else {
      return LoginScreen(); // Your login screen
    }
  }
}
