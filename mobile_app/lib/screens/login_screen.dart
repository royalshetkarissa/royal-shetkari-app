import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/auth_provider.dart';
import '../widgets/animated_button.dart';
import '../widgets/custom_text_field.dart';
import '../localization/app_localizations.dart';

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

  void _showResetPasswordBottomSheet(BuildContext context, String mobile) async {
    final auth = context.read<AuthProvider>();
    
    // Show a loading indicator while requesting OTP
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
      ),
    );
    
    final sent = await auth.sendResetOtp(mobile);
    if (!context.mounted) return;
    Navigator.pop(context); // Dismiss loading dialog
    
    if (!sent) {
      _showSnackBar(auth.error ?? 'Failed to send OTP for password reset');
      return;
    }

    final otpController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureNew = true;
    bool obscureConfirm = true;
    String? sheetError;
    bool isSheetLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    mobile == '8605889356' ? Icons.admin_panel_settings : Icons.lock_reset,
                    color: mobile == '8605889356' ? Colors.deepOrange : const Color(0xFF2E7D32),
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    mobile == '8605889356' ? 'Reset Admin Password' : 'Reset User Password',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Verify OTP and enter your new password for mobile number $mobile.',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(height: 20),
              if (auth.devOtp != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: BorderSide(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.amber, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'DEV OTP: ${auth.devOtp}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber),
                      ),
                    ],
                  ),
                ),
              ],
              CustomTextField(
                controller: otpController,
                label: 'OTP Code',
                hint: 'Enter 6-digit verification code',
                icon: Icons.sms_outlined,
                keyboardType: TextInputType.number,
                maxLength: 6,
                isRequired: true,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: newPasswordController,
                label: 'New Password',
                hint: 'At least 6 characters',
                icon: Icons.lock_outline,
                obscureText: obscureNew,
                isRequired: true,
                suffixIcon: IconButton(
                  icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setSheetState(() => obscureNew = !obscureNew),
                ),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: confirmPasswordController,
                label: 'Confirm New Password',
                hint: 'Re-enter your new password',
                icon: Icons.lock_outline,
                obscureText: obscureConfirm,
                isRequired: true,
                suffixIcon: IconButton(
                  icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setSheetState(() => obscureConfirm = !obscureConfirm),
                ),
              ),
              if (sheetError != null) ...[
                const SizedBox(height: 16),
                Text(
                  sheetError!,
                  style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mobile == '8605889356' ? Colors.deepOrange : const Color(0xFF2E7D32),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: isSheetLoading
                      ? null
                      : () async {
                          final otp = otpController.text.trim();
                          final pass = newPasswordController.text;
                          final conf = confirmPasswordController.text;

                          if (otp.length != 6) {
                            setSheetState(() => sheetError = 'OTP must be a 6-digit number');
                            return;
                          }
                          if (pass.length < 6) {
                            setSheetState(() => sheetError = 'Password must be at least 6 characters');
                            return;
                          }
                          if (pass != conf) {
                            setSheetState(() => sheetError = 'Passwords do not match');
                            return;
                          }

                          setSheetState(() {
                            sheetError = null;
                            isSheetLoading = true;
                          });

                          final localContext = this.context;
                          final navigator = Navigator.of(context);
                          try {
                            final success = await auth.resetPassword(mobile: mobile, newPassword: pass, otp: otp);

                            if (!localContext.mounted) return;

                            if (success) {
                              navigator.pop(); // Close sheet
                              _passwordController.text = pass; // Auto-fill password input for ease of use
                              
                              showDialog(
                                context: localContext,
                                builder: (successCtx) => AlertDialog(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  title: Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: mobile == '8605889356' ? Colors.deepOrange : Colors.green,
                                        size: 28,
                                      ),
                                      const SizedBox(width: 12),
                                      const Text('Password Reset', style: TextStyle(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  content: Text(
                                    'The password for mobile number $mobile has been successfully reset! You can now log in.',
                                    style: const TextStyle(fontSize: 14, height: 1.4),
                                  ),
                                  actions: [
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: mobile == '8605889356' ? Colors.deepOrange : const Color(0xFF2E7D32),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      onPressed: () => Navigator.pop(successCtx),
                                      child: const Text('OK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              setSheetState(() {
                                isSheetLoading = false;
                                sheetError = auth.error ?? 'Password reset failed';
                              });
                            }
                          } catch (e) {
                            setSheetState(() {
                              isSheetLoading = false;
                              sheetError = e.toString();
                            });
                          }
                        },
                  child: isSheetLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'CONFIRM & RESET PASSWORD',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
        title: Text(context.translate('login_title')),
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
                setState(() {});
              },
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
            if (_mobileController.text.trim().length == 10) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _showResetPasswordBottomSheet(context, _mobileController.text.trim()),
                  icon: const Icon(Icons.lock_reset, size: 18),
                  label: Text(
                    _mobileController.text.trim() == '8605889356'
                        ? 'RESET ADMIN PASSWORD'
                        : 'RESET PASSWORD',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: _mobileController.text.trim() == '8605889356'
                          ? Colors.deepOrange.shade800
                          : const Color(0xFF2E7D32),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: _mobileController.text.trim() == '8605889356'
                        ? Colors.deepOrange.shade50
                        : Colors.green.shade50,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: _mobileController.text.trim() == '8605889356'
                            ? Colors.deepOrange.shade200
                            : Colors.green.shade200,
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
            AnimatedButton(
              text: context.translate('login_button'),
              color: const Color(0xFFFF9800),
              isLoading: auth.isLoading,
              onPressed: auth.isLoading ? null : _login,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(context.translate('dont_have_account') + " "),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/register'),
                  child: Text(
                    context.translate('register_now'),
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
