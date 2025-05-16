import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart' as app_user;

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
  Future<UserCredential> adminSignInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      print('DEBUG: Starting admin sign-in process for email: $email');

      // First verify if the user is an admin
      print('DEBUG: Attempting to sign in with email and password');
      UserCredential? userCredential;
      try {
        userCredential = await signInWithEmailAndPassword(email, password);
        print('DEBUG: Basic sign-in successful, checking admin status');
      } catch (e) {
        print('DEBUG: Sign in failed: $e');
        rethrow; // Re-throw the error to be handled by the outer catch
      }

      if (userCredential.user == null) {
        print('DEBUG: User credential is null after successful sign in');
        throw 'Authentication failed. Please try again.';
      }

      final isUserAdmin = await isAdmin(userCredential.user!.uid);
      print('DEBUG: Admin check result: $isUserAdmin');

      if (!isUserAdmin) {
        print('DEBUG: User is not an admin, signing out');
        await signOut();
        throw 'Access denied. Not an admin user.';
      }

      // Check if 2FA is required
      print('DEBUG: Checking if 2FA is required');
      final user = userCredential.user;
      if (user == null) {
        print('DEBUG: User is null when checking 2FA');
        throw 'Authentication failed. Please try again.';
      }

      final multiFactorData = await user.multiFactor.getEnrolledFactors();
      print('DEBUG: Number of enrolled 2FA factors: ${multiFactorData.length}');

      if (multiFactorData.isEmpty) {
        print('DEBUG: No 2FA factors enrolled, starting enrollment process');

        // Get the user's phone number from admin document
        final adminDoc = await _firestore
            .collection('admins')
            .doc(userCredential.user!.uid)
            .get();
        if (!adminDoc.exists || adminDoc.data()?['phoneNumber'] == null) {
          throw 'Phone number not found for admin account. Please contact system administrator.';
        }

        final phoneNumber = adminDoc.data()!['phoneNumber'] as String;
        print('DEBUG: Found phone number for 2FA: $phoneNumber');

        // Start 2FA enrollment
        final session = await user.multiFactor.getSession();

        // Send verification code
        await _auth.verifyPhoneNumber(
          phoneNumber: phoneNumber,
          verificationCompleted: (PhoneAuthCredential credential) async {
            print('DEBUG: Phone verification completed automatically');
            await user.multiFactor.enroll(
              PhoneMultiFactorGenerator.getAssertion(credential),
            );
          },
          verificationFailed: (FirebaseAuthException e) {
            print('DEBUG: Phone verification failed: ${e.code} - ${e.message}');
            throw 'Failed to verify phone number: ${e.message}';
          },
          codeSent: (String verificationId, int? resendToken) {
            print('DEBUG: Verification code sent to phone');
            _verificationId = verificationId;
          },
          codeAutoRetrievalTimeout: (String verificationId) {
            print('DEBUG: Code auto retrieval timeout');
            _verificationId = verificationId;
          },
        );

        // Return a special response indicating 2FA enrollment is needed
        throw '2FA_ENROLLMENT_REQUIRED';
      }

      print('DEBUG: Admin sign-in successful with 2FA');
      return userCredential;
    } catch (e, stackTrace) {
      print('DEBUG: Unexpected error during admin sign-in: $e');
      print('DEBUG: Stack trace: $stackTrace');
      if (e is String) {
        throw e; // Re-throw string errors as they are already formatted
      }
      throw 'An error occurred during sign-in. Please try again.';
    }
  }

  // Complete 2FA enrollment with verification code
  Future<UserCredential> complete2FAEnrollment(String verificationCode) async {
    try {
      print('DEBUG: Completing 2FA enrollment with verification code');

      if (_verificationId == null) {
        throw 'No verification ID found. Please try signing in again.';
      }

      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: verificationCode,
      );

      final user = _auth.currentUser;
      if (user == null) {
        throw 'No user found. Please try signing in again.';
      }

      await user.multiFactor.enroll(
        PhoneMultiFactorGenerator.getAssertion(credential),
      );

      print('DEBUG: 2FA enrollment completed successfully');
      return await user.reauthenticateWithCredential(credential);
    } catch (e) {
      print('DEBUG: Error completing 2FA enrollment: $e');
      rethrow;
    }
  }

  // Verify 2FA code during sign in
  Future<UserCredential> verify2FACode(String verificationCode) async {
    try {
      print('DEBUG: Verifying 2FA code');

      if (_verificationId == null) {
        throw 'No verification ID found. Please try signing in again.';
      }

      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: verificationCode,
      );

      final user = _auth.currentUser;
      if (user == null) {
        throw 'No user found. Please try signing in again.';
      }

      print('DEBUG: 2FA verification successful');
      return await user.reauthenticateWithCredential(credential);
    } catch (e) {
      print('DEBUG: Error verifying 2FA code: $e');
      rethrow;
    }
  }

  // Store verification ID for 2FA
  String? _verificationId;

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
}
