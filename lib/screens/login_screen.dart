import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:rentmate/constants.dart';
import 'package:rentmate/screens/app_shell.dart';
import 'package:rentmate/screens/signup_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  bool obscureText = true;

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 100),

                  Center(
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 100,
                    ),
                  ),

                  SizedBox(height: 100),

                  /// EMAIL
                  Text(
                    'Email',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 8),
                  TextFormField(
                    controller: emailController,
                    decoration: InputDecoration(
                      fillColor: Colors.white,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Email is required";
                      }
                      if (!RegExp(
                        r'^[^@]+@[^@]+\.[^@]+',
                      ).hasMatch(value.trim())) {
                        return "Enter a valid email";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 15),

                  /// PASSWORD
                  Text(
                    'Password',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 8),
                  TextFormField(
                    controller: passwordController,
                    obscureText: obscureText,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Password is required";
                      }
                      return null;
                    },
                  ),

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
                      onPressed: _isLoading
                          ? null
                          : () {
                              if (_formKey.currentState!.validate()) {
                                _onLoginPressed(
                                  emailController.text.trim(),
                                  passwordController.text,
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text(
                              "Login",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),

                  SizedBox(height: 1),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Don't have an account?"),
                      TextButton(
                        onPressed: () {},
                        child: TextButton(
                          child: Text('Sign UP'),
                          onPressed: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SignupScreen(),
                              ),
                              (route) => false,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // LOGIN API
  Future<void> _onLoginPressed(String email, String password) async {
    setState(() => _isLoading = true);

    const loginRoute = '$kBaseUrl/auth/login';

    var body = jsonEncode({
      "email": email,
      "password": password,
    });

    try {
      final response = await post(
        Uri.parse(loginRoute),
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode == 200){
        final parsedBody = jsonDecode(response.body);

        final token = parsedBody['data']['token'];
        final role = parsedBody['data']["userData"]["role"];
        final userId = parsedBody['data']['userData']['id'];

        if (role != 'user') {
          print(parsedBody);
          _showError("Access denied");
          return;
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("jwt_token", token);
        await prefs.setString('user_id', userId);

        setState(() => _isLoading = false);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => AppShell(currentUserId: userId),
          ),
          (r) => false,
        );
      }else{
        final error = jsonDecode(response.body);
        _showError(error['message'] ?? "Login failed");
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError("Something went wrong: $e");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
