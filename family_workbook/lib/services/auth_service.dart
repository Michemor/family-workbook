import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String username,
    String? familyId,
    String? role,
    String? phoneNumber,
    String? subscriptionStatus,
    String? personalityType,
  }) async {
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (cred.user != null) {
        UserModel newUser = UserModel(
          uid: cred.user!.uid,
          username: username,
          email: email,
          createdAt: Timestamp.now(),
          familyId: familyId,
          role: role,
          contactNumber: phoneNumber,
          subscriptionStatus: subscriptionStatus,
          personalityType: personalityType,
        );

        await _firestore
            .collection('users')
            .doc(cred.user!.uid)
            .set({
              'uid': cred.user!.uid,
              'username': username,
              'email': email,
              'createdAt': FieldValue.serverTimestamp(),
              'role': role,
              'contactNumber': phoneNumber,
              'subscriptionStatus': subscriptionStatus,
              'personalityType': personalityType,
            }, SetOptions(merge: true));

        return newUser;
      }
    } catch (e) {
      debugPrint('Error signing up: $e');
      rethrow; // Rethrow to handle in UI
    }
    return null;
  }

  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (cred.user != null) {
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(cred.user!.uid)
            .get();
        if (userDoc.exists && userDoc.data() != null) {
          return UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
        }
      }
    } catch (e) {
      debugPrint('Error signing in: $e');
      rethrow; // Rethrow to handle in UI
    }
    return null;
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint('Error sending password reset email: $e');
      rethrow; // Rethrow to handle in UI
    }
  }

  Future<void> updateProfile({
    String? username,
    String? phoneNumber,
    String? profilePictureUrl,
    String? personalityType,
  }) async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      Map<String, dynamic> updates = {};
      if (username != null) {
        updates['username'] = username;
      }
      if (phoneNumber != null) {
        updates['contactNumber'] = phoneNumber;
      }
      if (profilePictureUrl != null) {
        updates['profilePictureUrl'] = profilePictureUrl;
      }
      if (personalityType != null) {
        updates['personalityType'] = personalityType;
      }

      try {
        await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .update(updates);
      } catch (e) {
        debugPrint('Error updating profile: $e');
        rethrow; // Rethrow to handle in UI
      }
    }
  }

  Future<void> deleteAccount() async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      try {
        // Delete user document from Firestore
        await _firestore.collection('users').doc(currentUser.uid).delete();
        // Delete user from Firebase Auth
        await currentUser.delete();
      } catch (e) {
        debugPrint('Error deleting account: $e');
        rethrow; // Rethrow to handle in UI
      }
    }
  }

  Future<UserModel?> getCurrentUser() async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      try {
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .get();
        if (userDoc.exists && userDoc.data() != null) {
          return UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
        }
      } catch (e) {
        debugPrint('Error fetching current user: $e');
        rethrow; // Rethrow to handle in UI
      }
    }
    return null;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Ensures a default admin user exists for development/testing purposes.
  /// This creates a user doc in Firestore if it doesn't exist, but does NOT
  /// create a Firebase Auth account (which must be done manually or via signup).
  Future<void> ensureDefaultAdmin() async {
    try {
      final adminId = 'default_admin_uid'; // This is a placeholder
      final adminDoc = await _firestore.collection('users').doc(adminId).get();
      
      if (!adminDoc.exists) {
        await _firestore.collection('users').doc(adminId).set({
          'uid': adminId,
          'username': 'Admin User',
          'email': 'admin@familytoolbox.com',
          'role': 'admin',
          'createdAt': FieldValue.serverTimestamp(),
          'subscriptionStatus': 'premium',
          'isActive': true,
        });
        debugPrint('Default admin user created in Firestore.');
      }
    } catch (e) {
      debugPrint('Error ensuring default admin: $e');
    }
  }

  Future<void> updateSubscription(String status) async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      try {
        await _firestore.collection('users').doc(currentUser.uid).update({
          'subscriptionStatus': status,
        });
      } catch (e) {
        debugPrint('Error updating subscription: $e');
        rethrow;
      }
    }
  }

  Future<User?> signInWithGoogle() async {
    // Implement Google Sign-In logic here
    // This typically involves using the google_sign_in package to authenticate with Google
    // and then using the obtained credentials to sign in with Firebase Auth.
    return null; // Placeholder return
  }

  Future<void> updatePaymentStatus(String uid, bool isPaid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'subscriptionStatus': isPaid ? 'premium' : 'free',
      });
    } catch (e) {
      debugPrint('Update payment status error: $e');
      rethrow;
    }
  }
}
