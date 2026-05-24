import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/providers/auth_provider.dart';
import '../widgets/animated_button.dart';
import '../widgets/custom_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _mobileError;
  String? _passwordError;

  @override
  void dispose() {
    _mobileController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _mobileError = null;
      _passwordError = null;
    });

    bool isValid = true;
    if (_mobileController.text.trim().isEmpty) {
      setState(() => _mobileError = 'Mobile number is required');
      isValid = false;
    } else if (_mobileController.text.trim().length != 10) {
      setState(() => _mobileError = 'Please enter valid 10-digit mobile number');
      isValid = false;
    }

    if (_passwordController.text.isEmpty) {
      setState(() => _passwordError = 'Password is required');
      isValid = false;
    }

    if (!isValid) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      mobile: _mobileController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      _showSnackBar('OTP sent to your WhatsApp!', isError: false);
      Navigator.pushNamed(context, '/otp');
    } else {
      final errorMsg = auth.error ?? 'Login failed';
      if (errorMsg.toLowerCase().contains('password')) {
        setState(() {
          _passwordError = 'Password is incorrect';
        });
      } else if (errorMsg.toLowerCase().contains('user') || errorMsg.toLowerCase().contains('mobile') || errorMsg.toLowerCase().contains('found')) {
        setState(() {
          _mobileError = 'Mobile number is not registered';
        });
      } else {
        _showSnackBar(errorMsg);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.phone_android, size: 50, color: Color(0xFF2E7D32)),
            const SizedBox(height: 16),
            const Text(
              'Welcome Back!',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Login to your account',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            CustomTextField(
              controller: _mobileController,
              label: 'Mobile Number',
              hint: 'Enter 10-digit mobile number',
              icon: Icons.phone_android,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              errorText: _mobileError,
              isRequired: true,
              onChanged: (val) {
                if (_mobileError != null) {
                  setState(() => _mobileError = null);
                }
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _passwordController,
              label: 'Password',
              hint: 'Enter your password',
              icon: Icons.lock_outline,
              obscureText: _obscurePassword,
              errorText: _passwordError,
              isRequired: true,
              onChanged: (val) {
                if (_passwordError != null) {
                  setState(() => _passwordError = null);
                }
              },
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            const SizedBox(height: 32),
            AnimatedButton(
              text: 'LOGIN',
              color: const Color(0xFFFF9800),
              isLoading: auth.isLoading,
              onPressed: auth.isLoading ? null : _login,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Don't have an account? "),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/register'),
                  child: const Text(
                    'Register',
                    style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
