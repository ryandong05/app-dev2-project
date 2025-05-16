import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'admin_dashboard_screen.dart';
import 'admin_2fa_setup_screen.dart';

class FirstAdminRegistrationScreen extends StatefulWidget {
  const FirstAdminRegistrationScreen({Key? key}) : super(key: key);

  @override
  State<FirstAdminRegistrationScreen> createState() =>
      _FirstAdminRegistrationScreenState();
}

class _FirstAdminRegistrationScreenState
    extends State<FirstAdminRegistrationScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  // Password validation states
  bool _hasMinLength = false;
  bool _hasUpperCase = false;
  bool _hasLowerCase = false;
  bool _hasNumber = false;
  bool _hasSpecialChar = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_validatePassword);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _validatePassword() {
    final password = _passwordController.text;
    setState(() {
      _hasMinLength = password.length >= 8;
      _hasUpperCase = password.contains(RegExp(r'[A-Z]'));
      _hasLowerCase = password.contains(RegExp(r'[a-z]'));
      _hasNumber = password.contains(RegExp(r'[0-9]'));
      _hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    });
  }

  bool get _isPasswordValid {
    return _hasMinLength &&
        _hasUpperCase &&
        _hasLowerCase &&
        _hasNumber &&
        _hasSpecialChar;
  }

  Future<void> _registerAdmin() async {
    if (!_isPasswordValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please ensure your password meets all requirements'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate phone number format
    final phoneNumber = _phoneController.text.trim();
    if (!phoneNumber.startsWith('+')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone number must start with country code (e.g., +1)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.registerFirstAdmin(
        _emailController.text.trim(),
        _passwordController.text,
        phoneNumber,
      );

      if (mounted) {
        // Show email verification dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => WillPopScope(
            onWillPop: () async => false, // Prevent back button
            child: AlertDialog(
              title: const Text('Verify Your Email'),
              content: const Text(
                'A verification email has been sent to your email address. '
                'Please verify your email before proceeding with 2FA setup.',
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    // Check email verification status
                    final isVerified = await _authService.isEmailVerified();
                    if (isVerified && mounted) {
                      Navigator.pop(context);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => Admin2FASetupScreen(
                                  phoneNumber: _phoneController.text,
                                )),
                      );
                    } else if (mounted) {
                      // Reload the user to get the latest verification status
                      final user = _authService.currentUser;
                      if (user != null) {
                        await user.reload();
                        final isVerifiedAfterReload =
                            await _authService.isEmailVerified();
                        if (isVerifiedAfterReload && mounted) {
                          Navigator.pop(context);
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => Admin2FASetupScreen(
                                      phoneNumber: _phoneController.text,
                                    )),
                          );
                        } else if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please verify your email first'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }
                  },
                  child: const Text('Check Verification'),
                ),
                TextButton(
                  onPressed: () async {
                    final user = _authService.currentUser;
                    if (user != null) {
                      await user.sendEmailVerification();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Verification email resent'),
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Resend verification email'),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'Create First Admin',
          style: TextStyle(
            color: theme.textTheme.bodyLarge?.color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome message
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.admin_panel_settings,
                    color: theme.primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Welcome! You are creating the first admin account for this application. This account will have super admin privileges.',
                      style: TextStyle(
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Email field
            Text(
              'Admin Email',
              style: TextStyle(
                fontSize: 16,
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(color: theme.textTheme.bodyLarge?.color),
              decoration: InputDecoration(
                hintText: 'Enter admin email',
                hintStyle: TextStyle(color: theme.textTheme.bodySmall?.color),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: theme.primaryColor),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Phone number field
            Text(
              'Phone Number',
              style: TextStyle(
                fontSize: 16,
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: TextStyle(color: theme.textTheme.bodyLarge?.color),
              decoration: InputDecoration(
                hintText: '+1234567890',
                hintStyle: TextStyle(color: theme.textTheme.bodySmall?.color),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: theme.primaryColor),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Password field
            Text(
              'Password',
              style: TextStyle(
                fontSize: 16,
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: TextStyle(color: theme.textTheme.bodyLarge?.color),
              decoration: InputDecoration(
                hintText: 'Enter password',
                hintStyle: TextStyle(color: theme.textTheme.bodySmall?.color),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: theme.primaryColor),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: theme.iconTheme.color,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Password requirements
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Password Requirements:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildRequirement('At least 8 characters', _hasMinLength),
                  _buildRequirement(
                      'At least one uppercase letter', _hasUpperCase),
                  _buildRequirement(
                      'At least one lowercase letter', _hasLowerCase),
                  _buildRequirement('At least one number', _hasNumber),
                  _buildRequirement(
                    'At least one special character (!@#\$%^&*(),.?":{}|<>)',
                    _hasSpecialChar,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Confirm password field
            Text(
              'Confirm Password',
              style: TextStyle(
                fontSize: 16,
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              style: TextStyle(color: theme.textTheme.bodyLarge?.color),
              decoration: InputDecoration(
                hintText: 'Confirm password',
                hintStyle: TextStyle(color: theme.textTheme.bodySmall?.color),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: theme.primaryColor),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: theme.iconTheme.color,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Register button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _registerAdmin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Create Admin Account'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildRequirement(String text, bool isMet) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.circle_outlined,
            color: isMet ? Colors.green : theme.textTheme.bodySmall?.color,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: isMet ? Colors.green : theme.textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }
}
