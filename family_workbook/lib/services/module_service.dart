import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/module_model.dart';
import '../models/module_content_model.dart';
import '../models/insight_card_model.dart';

class ModuleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<ModuleModel>> watchModules() {
    return _firestore
        .collection('modules')
        .orderBy('week')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ModuleModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<InsightCardModel>> watchInsightCards(String moduleId) {
    return _firestore
        .collection('modules')
        .doc(moduleId)
        .collection('insightCards')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InsightCardModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<ModuleContentModel>> watchModuleContent(String moduleId) {
    return _firestore
        .collection('modules')
        .doc(moduleId)
        .collection('content')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ModuleContentModel.fromMap(doc.data(), doc.id))
            .toList());
  }
}
