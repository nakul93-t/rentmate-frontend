import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:rentmate/constants.dart';
import 'package:rentmate/screens/login_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  // Steps: 0 = Email, 1 = OTP, 2 = New Password
  int _currentStep = 0;

  final _emailFormKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Color scheme - matching login/signup
  static const Color _primaryBlue = Color(0xFF2563EB);
  static const Color _darkSlate = Color(0xFF1E293B);
  static const Color _lightGrey = Color(0xFFF1F5F9);
  static const Color _mediumGrey = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    emailController.dispose();
    otpController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _animateStep() {
    _animationController.reset();
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightGrey,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _darkSlate),
          onPressed: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
              _animateStep();
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _primaryBlue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getStepIcon(),
                      size: 48,
                      color: _primaryBlue,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Title
                  Text(
                    _getStepTitle(),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: _darkSlate,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getStepSubtitle(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      color: _mediumGrey,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Step Progress Indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: index == _currentStep ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: index <= _currentStep
                              ? _primaryBlue
                              : _primaryBlue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 32),

                  // Form Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: _buildStepContent(),
                  ),

                  const SizedBox(height: 24),

                  // Back to Login
                  if (_currentStep == 0)
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Back to Login',
                        style: TextStyle(
                          color: _mediumGrey,
                          fontSize: 14,
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getStepIcon() {
    switch (_currentStep) {
      case 0:
        return Icons.email_outlined;
      case 1:
        return Icons.pin_outlined;
      case 2:
        return Icons.lock_reset_outlined;
      default:
        return Icons.email_outlined;
    }
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Forgot Password?';
      case 1:
        return 'Enter OTP';
      case 2:
        return 'New Password';
      default:
        return '';
    }
  }

  String _getStepSubtitle() {
    switch (_currentStep) {
      case 0:
        return 'Enter your email address and we\'ll send you an OTP to reset your password.';
      case 1:
        return 'Enter the 6-digit code sent to\n${emailController.text}';
      case 2:
        return 'Create a new password for your account.';
      default:
        return '';
    }
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildEmailStep();
      case 1:
        return _buildOtpStep();
      case 2:
        return _buildPasswordStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildEmailStep() {
    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('Email'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: emailController,
            hintText: 'Enter your email',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Email is required";
              }
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value.trim())) {
                return "Enter a valid email";
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          _buildPrimaryButton(
            text: 'Send OTP',
            onPressed: _requestOtp,
          ),
        ],
      ),
    );
  }

  Widget _buildOtpStep() {
    return Form(
      key: _otpFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('OTP Code'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: otpController,
            hintText: 'Enter 6-digit OTP',
            prefixIcon: Icons.pin_outlined,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "OTP is required";
              }
              if (value.length != 6) {
                return "OTP must be 6 digits";
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: _isLoading ? null : _requestOtp,
              child: const Text(
                'Resend OTP',
                style: TextStyle(
                  color: _primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildPrimaryButton(
            text: 'Verify OTP',
            onPressed: _verifyOtp,
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordStep() {
    return Form(
      key: _passwordFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('New Password'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: passwordController,
            hintText: 'Enter new password',
            prefixIcon: Icons.lock_outline,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: _mediumGrey,
                size: 20,
              ),
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Password is required";
              }
              if (value.length < 6) {
                return "Password must be at least 6 characters";
              }
              return null;
            },
          ),
          const SizedBox(height: 18),
          _buildLabel('Confirm Password'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: confirmPasswordController,
            hintText: 'Confirm new password',
            prefixIcon: Icons.lock_outline,
            obscureText: _obscureConfirmPassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: _mediumGrey,
                size: 20,
              ),
              onPressed: () {
                setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword,
                );
              },
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Please confirm your password";
              }
              if (value != passwordController.text) {
                return "Passwords do not match";
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          _buildPrimaryButton(
            text: 'Reset Password',
            onPressed: _resetPassword,
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: _darkSlate,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: const TextStyle(color: _darkSlate, fontSize: 15),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: _mediumGrey.withOpacity(0.7), fontSize: 15),
        prefixIcon: Icon(prefixIcon, color: _mediumGrey, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: _lightGrey,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primaryBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
        ),
        errorStyle: TextStyle(color: Colors.red.shade600, fontSize: 12),
      ),
      validator: validator,
    );
  }

  Widget _buildPrimaryButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryBlue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _primaryBlue.withOpacity(0.6),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
      ),
    );
  }

  // API: Request OTP
  Future<void> _requestOtp() async {
    if (!_emailFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await post(
        Uri.parse('$kBaseUrl/auth/forgot-password'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": emailController.text.trim()}),
      ).timeout(const Duration(seconds: 30));

      if (!mounted) return;

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          _isLoading = false;
          _currentStep = 1;
        });
        _animateStep();
        _showMessage(
          data['message'] ?? 'OTP sent! Check backend console.',
          isError: false,
        );
      } else {
        setState(() => _isLoading = false);
        _showMessage(data['message'] ?? 'Failed to send OTP');
      }
    } catch (e, s) {
      log(e.toString(), stackTrace: s);
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage('Network error. Please try again.');
    }
  }

  // API: Verify OTP
  Future<void> _verifyOtp() async {
    if (!_otpFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await post(
        Uri.parse('$kBaseUrl/auth/verify-otp'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": emailController.text.trim(),
          "otp": otpController.text.trim(),
        }),
      ).timeout(const Duration(seconds: 30));

      if (!mounted) return;

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          _isLoading = false;
          _currentStep = 2;
        });
        _animateStep();
        _showMessage('OTP verified!', isError: false);
      } else {
        setState(() => _isLoading = false);
        _showMessage(data['message'] ?? 'Invalid OTP');
      }
    } catch (e, s) {
      log(e.toString(), stackTrace: s);
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage('Network error. Please try again.');
    }
  }

  // API: Reset Password
  Future<void> _resetPassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await post(
        Uri.parse('$kBaseUrl/auth/reset-password'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": emailController.text.trim(),
          "otp": otpController.text.trim(),
          "newPassword": passwordController.text,
        }),
      ).timeout(const Duration(seconds: 30));

      if (!mounted) return;

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() => _isLoading = false);
        _showMessage(
          data['message'] ?? 'Password reset successful!',
          isError: false,
        );

        // Navigate back to login
        await Future.delayed(const Duration(milliseconds: 1500));
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      } else {
        setState(() => _isLoading = false);
        _showMessage(data['message'] ?? 'Failed to reset password');
      }
    } catch (e, s) {
      log(e.toString(), stackTrace: s);
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage('Network error. Please try again.');
    }
  }

  void _showMessage(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
