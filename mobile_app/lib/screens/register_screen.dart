import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../core/providers/auth_provider.dart';
import '../widgets/animated_button.dart';
import '../widgets/custom_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _fullNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _villageController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _villageController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_fullNameController.text.isEmpty) {
      _showSnackBar('Please enter full name');
      return;
    }
    if (_mobileController.text.length != 10) {
      _showSnackBar('Please enter valid 10-digit mobile number');
      return;
    }
    if (_passwordController.text.length < 6) {
      _showSnackBar('Password must be at least 6 characters');
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackBar('Passwords do not match');
      return;
    }
    if (_villageController.text.isEmpty) {
      _showSnackBar('Please enter your village name');
      return;
    }
    if (_pincodeController.text.isEmpty) {
      _showSnackBar('Please enter your pincode');
      return;
    }

    Position? position;
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
          position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low);
        }
      }
    } catch (e) {
      // Ignore location errors
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      fullName: _fullNameController.text.trim(),
      mobile: _mobileController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      village: _villageController.text.trim(),
      state: _stateController.text.trim(),
      pincode: _pincodeController.text.trim(),
      latitude: position?.latitude,
      longitude: position?.longitude,
    );

    if (!mounted) return;

    if (success) {
      _showSnackBar('OTP sent to your WhatsApp!', isError: false);
      Navigator.pushNamed(context, '/otp');
    } else {
      _showSnackBar(auth.error ?? 'Registration failed');
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
        title: const Text('Register'),
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
            const Icon(Icons.person_add, size: 50, color: Color(0xFF2E7D32)),
            const SizedBox(height: 16),
            const Text(
              'Create Account',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Join Royal Shetkari community',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            CustomTextField(
              controller: _fullNameController,
              label: 'Full Name',
              hint: 'Enter your full name',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _mobileController,
              label: 'Mobile Number',
              hint: 'Enter 10-digit mobile number',
              icon: Icons.phone_android,
              keyboardType: TextInputType.phone,
              maxLength: 10,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _emailController,
              label: 'Email (Optional)',
              hint: 'Enter your email',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _passwordController,
              label: 'Password',
              hint: 'Minimum 6 characters',
              icon: Icons.lock_outline,
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _confirmPasswordController,
              label: 'Confirm Password',
              hint: 'Re-enter your password',
              icon: Icons.verified_user_outlined,
              obscureText: _obscureConfirmPassword,
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
              ),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _villageController,
              label: 'Village',
              hint: 'Enter your village name',
              icon: Icons.location_on_outlined,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _stateController,
              label: 'State (Optional)',
              hint: 'Enter your state',
              icon: Icons.map_outlined,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _pincodeController,
              label: 'Pincode',
              hint: 'Enter 6-digit pincode',
              icon: Icons.pin_drop_outlined,
              keyboardType: TextInputType.number,
              maxLength: 6,
            ),
            const SizedBox(height: 32),
            AnimatedButton(
              text: 'REGISTER',
              color: const Color(0xFF2E7D32),
              isLoading: auth.isLoading,
              onPressed: auth.isLoading ? null : _register,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Already have an account? "),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  child: const Text(
                    'Login',
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
