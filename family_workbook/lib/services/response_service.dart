import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_response_model.dart';

class ResponseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<Map<String, UserResponseModel>> watchModuleResponses(
      String uid, String moduleId) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('responses')
        .where('moduleId', isEqualTo: moduleId)
        .snapshots()
        .map((snapshot) {
      final map = <String, UserResponseModel>{};
      for (var doc in snapshot.docs) {
        final resp = UserResponseModel.fromMap(doc.data());
        map[resp.contentId] = resp;
      }
      return map;
    });
  }

  Future<void> saveResponse(
      {required String uid, required UserResponseModel response}) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('responses')
        .doc(response.contentId)
        .set(response.toMap(), SetOptions(merge: true));
  }

  Future<void> recordXp(
      {required String uid, String? familyId, required int xp}) async {
    final userRef = _firestore.collection('users').doc(uid);
    await userRef.update({'gamePoints': FieldValue.increment(xp)});

    if (familyId != null) {
      // Potentially update family XP too
    }
  }
}
