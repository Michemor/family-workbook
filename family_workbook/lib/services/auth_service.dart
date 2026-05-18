import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
    bool? isActive,
    String? subscriptionStatus,
    }) async {
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);

      if (cred.user != null) {
        // Create a new user document in Firestore
        UserModel newUser = UserModel(
          uid: cred.user!.uid,
          username: username,
          email: email,
          createdAt: DateTime.now(),
          role: role,
          contactNumber: phoneNumber,
          familyId: familyId,
          isActive: isActive,
          subscriptionStatus: subscriptionStatus,
        );

          Map<String, dynamic> userMap = newUser.toMap();
          userMap['createdAt'] = FieldValue.serverTimestamp(); // Use server timestamp for createdAt
          await _firestore.collection('users').doc(cred.user!.uid).set(userMap);
        return newUser;
      }
    } catch (e) {
      print('Error signing up: $e');
      rethrow; // Rethrow to handle in UI
    }
    return null;
  }

  Future<UserModel?> signIn({required String email, required String password}) async {
    try {
      UserCredential cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      if (cred.user != null) {
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(cred.user!.uid).get();
        if (userDoc.exists && userDoc.data() != null) {
          return UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
        }
      }
    } catch (e) {
      print('Error signing in: $e');
      rethrow; // Rethrow to handle in UI
    }
    return null;
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Error sending password reset email: $e');
      rethrow; // Rethrow to handle in UI
    }
  }

  Future<void> updateProfile({String? username, String? phoneNumber, String? profilePictureUrl}) async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      Map<String, dynamic> updates = {};
      if (username != null) updates['username'] = username;
      if (phoneNumber != null) updates['contactNumber'] = phoneNumber;
      if (profilePictureUrl != null) updates['profilePictureUrl'] = profilePictureUrl;

      try {
        await _firestore.collection('users').doc(currentUser.uid).update(updates);
      } catch (e) {
        print('Error updating profile: $e');
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
        print('Error deleting account: $e');
        rethrow; // Rethrow to handle in UI
      }
    }
  }

  Future<UserModel?> getCurrentUser() async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      try {
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
        if (userDoc.exists && userDoc.data() != null) {
          return UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
        }
      } catch (e) {
        print('Error fetching current user: $e');
        rethrow; // Rethrow to handle in UI
      }
    }
    return null;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
  Future<User?> signInWithGoogle() async {
    // Implement Google Sign-In logic here
    // This typically involves using the google_sign_in package to authenticate with Google
    // and then using the obtained credentials to sign in with Firebase Auth.
    return null; // Placeholder return
  }
}
