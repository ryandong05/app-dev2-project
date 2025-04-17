import 'package:flutter/material.dart';
import 'sign_in_screen.dart';
import 'sign_up_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                const Text(
                  '𝕐',
                  style: TextStyle(
                    fontSize: 120,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),

                // Tagline
                const Column(
                  children: [
                    Text(
                      'Connect.',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Share. Explore.',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 48),

                // Sign up button
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SignUpScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFBDBDBD),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                      elevation: 0,
                    ),
                    child: const Text('Sign up'),
                  ),
                ),
                const SizedBox(height: 16),

                // Sign in button
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SignInScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEBEBEB),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                      elevation: 0,
                    ),
                    child: const Text('Sign in'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}