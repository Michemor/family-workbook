import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/family_model.dart';
import '../models/family_member_model.dart';

class FamilyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> createFamily({
    required String uid,
    required String username,
    required String familyName,
    required String country,
    required String familyType,
    List<String>? members,
    required String role,
  }) async {
    WriteBatch batch = _firestore.batch();

    DocumentReference familyRef = _firestore.collection('families').doc();
    DocumentReference userRef = _firestore.collection('users').doc(uid);
    DocumentReference familyMemberRef = familyRef
        .collection('familyMembers')
        .doc(uid);

    batch.set(familyRef, {
      'familyId': familyRef.id,
      'familyName': familyName,
      'createdAt': FieldValue.serverTimestamp(),
      'country': country,
      'familyType': familyType,
      'overallCompletionPercentage': 0.0,
      'charterReadinessScore': 0.0,
      'members': [uid],
    });

    // Update the user's familyId — use update() not set() to avoid wiping the profile
    batch.update(userRef, {'familyId': familyRef.id});

    // Write the creator as the first family member
    batch.set(familyMemberRef, {
      'memberId': familyMemberRef.id,
      'uid': uid,
      'name': username,
      'role': role,
      'isSystemAdmin': false,
    });

    try {
      await batch.commit();
      return familyRef.id;
    } catch (e) {
      debugPrint('Error creating family: $e');
      rethrow;
    }
  }

  Future<void> joinFamily({
    required String uid,
    required String username,
    required String familyId,
    required String role,
  }) async {
    WriteBatch batch = _firestore.batch();
    DocumentReference familyRef = _firestore.collection('families').doc(familyId);
    DocumentReference userRef = _firestore.collection('users').doc(uid);
    DocumentReference familyMemberRef = familyRef.collection('familyMembers').doc(uid);

    // Update user's familyId
    batch.update(userRef, {'familyId': familyId});

    // Add member to family collection list of members
    batch.update(familyRef, {
      'members': FieldValue.arrayUnion([uid])
    });

    // Write the new family member
    batch.set(familyMemberRef, {
      'memberId': uid,
      'uid': uid,
      'name': username,
      'role': role,
      'isSystemAdmin': false,
    });

    try {
      await batch.commit();
    } catch (e) {
      debugPrint('Error joining family: $e');
      rethrow;
    }
  }

  Future<List<FamilyModel>> getAllFamilies() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('families').get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['createdAt'] is Timestamp) {
          data['createdAt'] = (data['createdAt'] as Timestamp).toDate();
        }
        return FamilyModel.fromMap(data);
      }).toList();
    } catch (e) {
      debugPrint('Error getting all families: $e');
      return [];
    }
  }

  Future<FamilyModel?> getFamilyById(String familyId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('families')
          .doc(familyId)
          .get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;

        if (data['createdAt'] is Timestamp) {
          data['createdAt'] = (data['createdAt'] as Timestamp).toDate();
        }

        // BUG FIX: pass 'data' (already Timestamp-converted) instead of re-reading doc.data()
        return FamilyModel.fromMap(data);
      }
    } catch (e) {
      debugPrint('Error fetching family: $e');
    }
    return null;
  }

  Stream<List<FamilyMemberModel>> streamFamilyMembers(String familyId) {
    return _firestore
        .collection('families')
        .doc(familyId)
        .collection('familyMembers')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return FamilyMemberModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }
}
