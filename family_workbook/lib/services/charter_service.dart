import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/family_charter_model.dart';

class CharterService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<FamilyCharterModel?> watchFamilyCharter(String familyId) {
    return _firestore
        .collection('families')
        .doc(familyId)
        .collection('charter')
        .doc('document') // Assuming a single document for the charter
        .snapshots()
        .map((doc) => doc.exists ? FamilyCharterModel.fromMap(doc.data()!, doc.id) : null);
  }

  Stream<List<CharterClause>> watchClauses(String familyId) {
    // In many implementations, clauses might be a subcollection of the charter or the family
    return _firestore
        .collection('families')
        .doc(familyId)
        .collection('charterClauses')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CharterClause.fromMap(doc.data(), doc.id))
            .toList());
  }
}
