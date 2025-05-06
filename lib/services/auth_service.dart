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
      profileImageUrl:
          data['profileImageUrl'] ??
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
    final querySnapshot =
        await _firestore
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
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
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
      // First verify if the user is an admin
      final userCredential = await signInWithEmailAndPassword(email, password);
      final isUserAdmin = await isAdmin(userCredential.user!.uid);
      
      if (!isUserAdmin) {
        await signOut();
        throw 'Access denied. Not an admin user.';
      }

      // Enable 2FA if not already enabled
      if (!userCredential.user!.multiFactor.enrolledFactors.isNotEmpty) {
        // TODO: Implement 2FA enrollment flow
        throw '2FA not set up. Please contact system administrator.';
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }
}
