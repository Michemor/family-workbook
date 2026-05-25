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
    String? phoneNumber,
    String? role,
    String? familyId,
    bool isPaid = false,
  }) async {
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (cred.user != null) {
        // Create a new user document in Firestore
        UserModel newUser = UserModel(
          uid: cred.user!.uid,
          username: username,
          email: email,
          createdAt: DateTime.now(),
          role: role,
          contactNumber: phoneNumber,
          isPaid: isPaid,
        );


        Map<String, dynamic> userMap = newUser.toMap();
        userMap['createdAt'] =
            FieldValue.serverTimestamp(); // Use server timestamp for createdAt
        await _firestore.collection('users').doc(cred.user!.uid).set(userMap);
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

  Future<void> updatePaymentStatus(bool isPaid) async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      try {
        await _firestore.collection('users').doc(currentUser.uid).update({
          'isPaid': isPaid,
        });
      } catch (e) {
        debugPrint('Error updating payment status: $e');
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

  /// Ensures that a default admin user exists in the system.
  Future<void> ensureDefaultAdmin() async {
    const adminEmail = 'admin@familyworkbook.com';
    const adminPassword = 'Admin@123';
    
    try {
      // Attempt to create the admin user directly
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: adminEmail,
        password: adminPassword,
      );

      if (cred.user != null) {
        UserModel adminUser = UserModel(
          uid: cred.user!.uid,
          username: 'System Admin',
          email: adminEmail,
          role: 'admin',
          isPaid: true,
          completionPercentage: 100,
          currentWeek: 8,
          gamePoints: 9999,
        );

        Map<String, dynamic> userMap = adminUser.toMap();
        userMap['createdAt'] = FieldValue.serverTimestamp();
        
        await _firestore.collection('users').doc(cred.user!.uid).set(userMap);
        debugPrint('Default admin user created successfully.');
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        debugPrint('Default admin user already exists.');
      } else {
        debugPrint('Error ensuring default admin: ${e.message}');
      }
    } catch (e) {
      debugPrint('Error ensuring default admin: $e');
    }
  }
}
