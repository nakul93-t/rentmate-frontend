import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:rentmate/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool obscureText = true;

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 100,
                ),
                Align(
                  alignment: AlignmentGeometry.center,
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 100,
                  ),
                ),
                SizedBox(height: 100),

                /// Username / Email
                Text(
                  'Email',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                SizedBox(
                  height: 8,
                ),

                TextField(
                  decoration: InputDecoration(
                    fillColor: Colors.white,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                ),
                SizedBox(height: 15),

                Text(
                  'Password',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),

                TextField(
                  obscureText: obscureText,
                  decoration: InputDecoration(
                    fillColor: Colors.white,
                    filled: true,
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureText ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          obscureText = !obscureText;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                ),
                // SizedBox(height: 25),
                // Text(
                //   "Forget Password",
                //   style: TextStyle(
                //     fontSize: 16,
                //     fontWeight: FontWeight.bold,
                //   ),
                // ),
                Center(
                  child: TextButton(
                    onPressed: () {},
                    child: Text("Forgot Password"),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "login",
                      style: TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ),
                ),

                SizedBox(height: 1),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Dont have an account?",
                      style: TextStyle(
                        color: const Color.fromARGB(255, 15, 15, 17),
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        'SIGN UP',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onLoginPressed(String email, String password) async {
    const loginRoute = '$kBaseUrl/auth/signin';

    var body = jsonEncode({
      "email": email,
      "password": password,
    });

    try {
      final response = await post(
        Uri.parse(loginRoute),
        headers: {"Accept": "/", "Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode == 200) {
        final parsedBody = jsonDecode(response.body);

        print(parsedBody);

        final token = parsedBody['token']; // from backend
        final role = parsedBody['data']["role"];

        print('role, ${role}, token: ${token}');

        // Save token locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("jwt_token", token);
        await prefs.setString("user_role", role);

        // Navigate by role
        if (role == 'mother') {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute<void>(
              builder: (context) {
                // return const HomeScreen();
                return SizedBox();
              },
            ),
            (r) => false,
          );
        } else if (role == 'admin') {
          // TODO: replace with your admin screen
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute<void>(builder: (context) => const Placeholder()),
            (r) => false,
          );
        } else if (role == 'doctor') {
          // TODO: replace with your doctor screen
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute<void>(builder: (context) => const Placeholder()),
            (r) => false,
          );
        } else if (role == 'caregiver') {
          // TODO: replace with your caregiver screen
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute<void>(builder: (context) => const Placeholder()),
            (r) => false,
          );
        }
      } else {
        print('error');
        final error = jsonDecode(response.body);
        _showError(error['message'] ?? "Login failed");
      }
    } catch (e) {
      _showError("Something went wrong: $e");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
