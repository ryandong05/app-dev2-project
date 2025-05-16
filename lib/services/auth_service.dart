import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart' as app_user;
import 'dart:async';

import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:firebase_auth/firebase_auth.dart'
    show FirebaseAuthMultiFactorException;

class Admin2FAChallenge {
  final MultiFactorResolver resolver;
  final String phoneNumber;
  Admin2FAChallenge({required this.resolver, required this.phoneNumber});
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get current user's data
  Future<app_user.User?> getCurrentUserData() async {
    final user = currentUser;
    if (user == null) return null;

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    if (!userDoc.exists) return null;

    final data = userDoc.data()!;
    return app_user.User(
      id: user.uid,
      name: data['name'] ?? user.displayName ?? 'Anonymous',
      handle: data['handle'] ?? user.email?.split('@')[0] ?? 'anonymous',
      profileImageUrl: data['profileImageUrl'] ??
          'https://ui-avatars.com/api/?name=${Uri.encodeComponent(data['name'] ?? user.displayName ?? 'Anonymous')}&background=random',
      isVerified: data['isVerified'] ?? false,
    );
  }

  // Create or update user profile
  Future<void> updateUserProfile({
    String? name,
    String? handle,
    String? profileImageUrl,
    bool? isVerified,
  }) async {
    final user = currentUser;
    if (user == null) return;

    final userData = {
      if (name != null) 'name': name,
      if (handle != null) 'handle': handle,
      if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
      if (isVerified != null) 'isVerified': isVerified,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(userData, SetOptions(merge: true));
  }

  // Get current username
  Future<String?> getCurrentUsername() async {
    final user = currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    return doc.data()?['name'] as String?;
  }

  // Update username
  Future<void> updateUsername(String newUsername) async {
    final user = currentUser;
    if (user == null) throw 'No user logged in';

    // Check if username is already taken by a different user
    final querySnapshot = await _firestore
        .collection('users')
        .where('name', isEqualTo: newUsername)
        .where(
          FieldPath.documentId,
          isNotEqualTo: user.uid,
        ) // Exclude current user
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      throw 'Username is already taken';
    }

    // Update the user's document
    await _firestore.collection('users').doc(user.uid).set({
      'handle': newUsername,
      'email': user.email,
      'updatedAt': FieldValue.serverTimestamp(),
      'uid': user.uid, // Store UID for reference
    }, SetOptions(merge: true));
  }

  // Update password
  Future<void> updatePassword(
    String currentPassword,
    String newPassword,
  ) async {
    final user = currentUser;
    if (user == null || user.email == null) throw 'No user logged in';

    try {
      // Reauthenticate user before changing password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      print('DEBUG: Attempting Firebase sign in for email: $email');
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print(
          'DEBUG: Firebase sign in successful for user: ${credential.user?.uid}');
      return credential;
    } on FirebaseAuthException catch (e) {
      print('DEBUG: Firebase Auth Exception: ${e.code} - ${e.message}');
      switch (e.code) {
        case 'user-not-found':
          throw 'No user found with this email.';
        case 'wrong-password':
          throw 'Wrong password provided.';
        case 'invalid-email':
          throw 'Email is invalid.';
        case 'user-disabled':
          throw 'This user has been disabled.';
        case 'too-many-requests':
          throw 'Too many failed login attempts. Please try again later.';
        case 'network-request-failed':
          throw 'Network error. Please check your internet connection.';
        default:
          print('DEBUG: Unhandled Firebase Auth error code: ${e.code}');
          throw 'Authentication failed: ${e.message}';
      }
    } catch (e, stackTrace) {
      print('DEBUG: Unexpected error during sign in: $e');
      print('DEBUG: Stack trace: $stackTrace');
      throw 'An error occurred during sign in. Please try again.';
    }
  }

  // Sign up with email and password
  Future<UserCredential> signUpWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'Email already in use.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'invalid-email':
        return 'Email is invalid.';
      case 'user-disabled':
        return 'This user has been disabled.';
      case 'requires-recent-login':
        return 'Please log in again before updating your password.';
      default:
        return 'An error occurred. Please try again.';
    }
  }

  // Check if user is admin
  Future<bool> isAdmin(String uid) async {
    final userDoc = await _firestore.collection('admins').doc(uid).get();
    return userDoc.exists;
  }

  // Admin sign in with 2FA
  Future<dynamic> adminSignInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      print('DEBUG: Starting admin sign-in process for email: $email');
      try {
        final userCredential =
            await signInWithEmailAndPassword(email, password);
        if (userCredential.user == null) {
          throw 'Authentication failed. Please try again.';
        }
        final isUserAdmin = await isAdmin(userCredential.user!.uid);
        if (!isUserAdmin) {
          await signOut();
          throw 'Access denied. Not an admin user.';
        }
        // Check if 2FA is required (enrollment)
        final multiFactorData =
            await userCredential.user!.multiFactor.getEnrolledFactors();
        if (multiFactorData.isEmpty) {
          // Enrollment flow (first time)
          final adminDoc = await _firestore
              .collection('admins')
              .doc(userCredential.user!.uid)
              .get();
          if (!adminDoc.exists || adminDoc.data()?['phoneNumber'] == null) {
            throw 'Phone number not found for admin account. Please contact system administrator.';
          }
          final phoneNumber = adminDoc.data()!['phoneNumber'] as String;
          final completer = Completer<String>();
          await _auth.verifyPhoneNumber(
            phoneNumber: phoneNumber,
            verificationCompleted: (PhoneAuthCredential credential) async {
              await userCredential.user!.multiFactor.enroll(
                PhoneMultiFactorGenerator.getAssertion(credential),
              );
              completer.complete(credential.verificationId!);
            },
            verificationFailed: (FirebaseAuthException e) {
              completer
                  .completeError('Failed to verify phone number: ${e.message}');
            },
            codeSent: (String verificationId, int? resendToken) {
              completer.complete(verificationId);
            },
            codeAutoRetrievalTimeout: (String verificationId) {
              completer.complete(verificationId);
            },
          );
          final verificationId = await completer.future;
          return verificationId;
        }
        // If already enrolled, just sign in
        return userCredential;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'second-factor-required' &&
            e is FirebaseAuthMultiFactorException) {
          final resolver = e.resolver;
          // Find the phone number hint
          final phoneHint = resolver.hints.first;
          final phoneNumber = phoneHint.displayName ?? phoneHint.uid;
          return Admin2FAChallenge(
              resolver: resolver, phoneNumber: phoneNumber);
        }
        throw _handleAuthException(e);
      }
    } catch (e, stackTrace) {
      print('DEBUG: Unexpected error during admin sign-in: $e');
      print('DEBUG: Stack trace: $stackTrace');
      if (e is String) {
        throw e;
      }
      throw 'An error occurred during sign-in. Please try again.';
    }
  }

  // Complete 2FA sign-in (not enrollment)
  Future<UserCredential> resolve2FASignIn({
    required MultiFactorResolver resolver,
    required String smsCode,
  }) async {
    final phoneHint = resolver.hints.first;
    final assertion = PhoneAuthProvider.credential(
      verificationId: phoneHint.uid,
      smsCode: smsCode,
    );
    return await resolver.resolveSignIn(
      PhoneMultiFactorGenerator.getAssertion(assertion),
    );
  }

  // Get user data by ID
  Future<app_user.User?> getUserData(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) return null;

    final data = userDoc.data()!;
    return app_user.User(
      id: userId,
      name: data['name'] ?? 'Anonymous',
      handle: data['handle'] ?? 'anonymous',
      profileImageUrl: data['profileImageUrl'] ??
          'https://ui-avatars.com/api/?name=${Uri.encodeComponent(data['name'] ?? 'Anonymous')}&background=random',
      isVerified: data['isVerified'] ?? false,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  // Check if there are any admins in the database
  Future<bool> hasAnyAdmins() async {
    final adminSnapshot = await _firestore.collection('admins').limit(1).get();
    return adminSnapshot.docs.isNotEmpty;
  }

  // Register first admin
  Future<UserCredential> registerFirstAdmin(
    String email,
    String password,
    String phoneNumber,
  ) async {
    try {
      // Check if there are any existing admins
      final hasAdmins = await hasAnyAdmins();
      if (hasAdmins) {
        throw 'Admin registration is not allowed. Please contact an existing admin.';
      }

      // Create the user account
      final userCredential = await signUpWithEmailAndPassword(email, password);

      // Send email verification
      await userCredential.user!.sendEmailVerification();

      // Create admin document
      await _firestore.collection('admins').doc(userCredential.user!.uid).set({
        'email': email,
        'phoneNumber': phoneNumber,
        'isSuperAdmin': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Check if email is verified
  Future<bool> isEmailVerified() async {
    final user = currentUser;
    if (user == null) return false;

    // Reload user to get latest verification status
    await user.reload();
    return user.emailVerified;
  }

  // Resend verification email
  Future<void> resendVerificationEmail() async {
    final user = currentUser;
    if (user == null) throw 'No user logged in';
    await user.sendEmailVerification();
  }

  // Complete 2FA enrollment (first time)
  Future<UserCredential> complete2FAEnrollment(
    String verificationCode,
    String verificationId,
  ) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw 'No user found. Please try signing in again.';
    }
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: verificationCode,
    );
    await user.multiFactor.enroll(
      PhoneMultiFactorGenerator.getAssertion(credential),
    );
    // Re-authenticate with the credential to complete the sign-in process
    final userCredential = await user.reauthenticateWithCredential(credential);
    return userCredential;
  }
}
