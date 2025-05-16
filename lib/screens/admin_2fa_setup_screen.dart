import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'admin_dashboard_screen.dart';

class Admin2FASetupScreen extends StatefulWidget {
  final String phoneNumber;

  const Admin2FASetupScreen({
    Key? key,
    required this.phoneNumber,
  }) : super(key: key);

  @override
  State<Admin2FASetupScreen> createState() => _Admin2FASetupScreenState();
}

class _Admin2FASetupScreenState extends State<Admin2FASetupScreen> {
  final TextEditingController _verificationCodeController =
      TextEditingController();
  bool _isLoading = false;
  bool _isVerifying = false;
  String? _verificationId;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _startPhoneVerification();
  }

  @override
  void dispose() {
    _verificationCodeController.dispose();
    super.dispose();
  }

  Future<void> _startPhoneVerification() async {
    setState(() => _isLoading = true);
    try {
      final user = _authService.currentUser;
      if (user == null) throw 'No user logged in';

      // Start phone verification
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: widget.phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification completed (Android only)
          await _verifyPhoneNumber(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(e.message ?? 'Verification failed'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          if (mounted) {
            setState(() {
              _verificationId = verificationId;
              _isLoading = false;
            });
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          if (mounted) {
            setState(() {
              _verificationId = verificationId;
              _isLoading = false;
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _verifyPhoneNumber(PhoneAuthCredential credential) async {
    setState(() => _isVerifying = true);
    try {
      final user = _authService.currentUser;
      if (user == null) throw 'No user logged in';

      // Create a PhoneAuthCredential with the verification code
      final phoneCredential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _verificationCodeController.text,
      );

      // Get the current user's multi-factor session
      final multiFactorSession = await user.multiFactor.getSession();

      // Create a PhoneMultiFactorGenerator
      final phoneMultiFactorGenerator = PhoneMultiFactorGenerator();

      // Enroll the phone number as a second factor
      await user.multiFactor.enroll(
        PhoneMultiFactorGenerator.getAssertion(phoneCredential),
        displayName: 'Phone Number',
      );

      if (mounted) {
        // Navigate to admin dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
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
        setState(() => _isVerifying = false);
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
          'Set Up Two-Factor Authentication',
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
            // Info message
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.security,
                    color: theme.primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'A verification code has been sent to your phone number. '
                      'Please enter the code below to complete the 2FA setup.',
                      style: TextStyle(
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Phone number display
            Text(
              'Phone Number',
              style: TextStyle(
                fontSize: 16,
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.phone,
                    color: theme.primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.phoneNumber,
                    style: TextStyle(
                      color: theme.textTheme.bodyLarge?.color,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Verification code field
            Text(
              'Verification Code',
              style: TextStyle(
                fontSize: 16,
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _verificationCodeController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: theme.textTheme.bodyLarge?.color),
              decoration: InputDecoration(
                hintText: 'Enter 6-digit code',
                hintStyle: TextStyle(color: theme.textTheme.bodySmall?.color),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: theme.primaryColor),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Verify button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading || _isVerifying
                    ? null
                    : () => _verifyPhoneNumber(
                          PhoneAuthProvider.credential(
                            verificationId: _verificationId!,
                            smsCode: _verificationCodeController.text,
                          ),
                        ),
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
                child: _isLoading || _isVerifying
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Verify Phone Number'),
              ),
            ),
            const SizedBox(height: 16),

            // Resend code button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: TextButton(
                onPressed:
                    _isLoading || _isVerifying ? null : _startPhoneVerification,
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Resend Code'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
