import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../core/providers/auth_provider.dart';
import '../widgets/animated_button.dart';
import '../widgets/custom_text_field.dart';
import '../localization/app_localizations.dart';

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

  String? _fullNameError;
  String? _mobileError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _villageError;
  String? _pincodeError;

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
    setState(() {
      _fullNameError = null;
      _mobileError = null;
      _passwordError = null;
      _confirmPasswordError = null;
      _villageError = null;
      _pincodeError = null;
    });

    bool isValid = true;
    if (_fullNameController.text.trim().isEmpty) {
      setState(() => _fullNameError = 'Full name is required');
      isValid = false;
    }
    if (_mobileController.text.trim().isEmpty) {
      setState(() => _mobileError = 'Mobile number is required');
      isValid = false;
    } else if (_mobileController.text.trim().length != 10) {
      setState(() => _mobileError = 'Enter a valid 10-digit mobile number');
      isValid = false;
    }
    if (_passwordController.text.isEmpty) {
      setState(() => _passwordError = 'Password is required');
      isValid = false;
    } else if (_passwordController.text.length < 6) {
      setState(() => _passwordError = 'Password must be at least 6 characters');
      isValid = false;
    }
    if (_confirmPasswordController.text.isEmpty) {
      setState(() => _confirmPasswordError = 'Please confirm your password');
      isValid = false;
    } else if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _confirmPasswordError = 'Passwords do not match');
      isValid = false;
    }
    if (_villageController.text.trim().isEmpty) {
      setState(() => _villageError = 'Village name is required');
      isValid = false;
    }
    if (_pincodeController.text.trim().isEmpty) {
      setState(() => _pincodeError = 'Pincode is required');
      isValid = false;
    } else if (_pincodeController.text.trim().length != 6) {
      setState(() => _pincodeError = 'Pincode must be 6 digits');
      isValid = false;
    }

    if (!isValid) return;

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
        title: Text(context.translate('register_title')),
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
              label: context.translate('full_name'),
              hint: context.translate('enter_full_name'),
              icon: Icons.person_outline,
              errorText: _fullNameError,
              isRequired: true,
              onChanged: (val) {
                if (_fullNameError != null) {
                  setState(() => _fullNameError = null);
                }
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _mobileController,
              label: context.translate('mobile_number'),
              hint: context.translate('enter_mobile'),
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
              controller: _emailController,
              label: 'Email (Optional)',
              hint: 'Enter your email',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _passwordController,
              label: context.translate('password'),
              hint: context.translate('enter_password'),
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
            const SizedBox(height: 16),
            CustomTextField(
              controller: _confirmPasswordController,
              label: 'Confirm Password',
              hint: 'Re-enter your password',
              icon: Icons.verified_user_outlined,
              obscureText: _obscureConfirmPassword,
              errorText: _confirmPasswordError,
              isRequired: true,
              onChanged: (val) {
                if (_confirmPasswordError != null) {
                  setState(() => _confirmPasswordError = null);
                }
              },
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
              errorText: _villageError,
              isRequired: true,
              onChanged: (val) {
                if (_villageError != null) {
                  setState(() => _villageError = null);
                }
              },
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
              errorText: _pincodeError,
              isRequired: true,
              onChanged: (val) {
                if (_pincodeError != null) {
                  setState(() => _pincodeError = null);
                }
              },
            ),
            const SizedBox(height: 32),
            AnimatedButton(
              text: context.translate('register_button'),
              color: const Color(0xFF2E7D32),
              isLoading: auth.isLoading,
              onPressed: auth.isLoading ? null : _register,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  child: Text(
                    context.translate('already_have_account'),
                    style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold),
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
