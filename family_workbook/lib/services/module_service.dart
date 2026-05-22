import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/module_model.dart';
import '../models/insight_card_model.dart';
import '../models/module_content_model.dart';

/// Provides Firestore streams for the Modules collection and its subcollections:
///   - `Modules/{week_id}`                          → [ModuleModel]
///   - `Modules/{week_id}/InsightCards/{card_id}`   → [InsightCardModel]
///   - `Modules/{week_id}/ModuleContent/{item_id}`  → [ModuleContentModel]
///
/// All streams yield an empty list (never throw) so the UI can show loading/
/// empty states rather than crashing.
class ModuleService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Module Catalogue ────────────────────────────────────────────────────────

  /// Streams active modules ordered by [week].
  ///
  /// Firestore path: `Modules` collection, filtered by `active == true`.
  Stream<List<ModuleModel>> watchModules() async* {
    yield []; // immediate empty yield so the UI is never stuck

    try {
      await for (final snap in _db
          .collection('Modules')
          .where('active', isEqualTo: true)
          .orderBy('week')
          .snapshots()) {
        yield snap.docs
            .map((doc) => ModuleModel.fromMap(doc.id, doc.data()))
            .toList();
      }
    } catch (e) {
      debugPrint('[ModuleService] watchModules error: $e');
      // empty list already yielded — UI shows empty state
    }
  }

  // ── InsightCards Subcollection ──────────────────────────────────────────────

  /// Streams insight cards for a specific module.
  ///
  /// Firestore path: `Modules/{moduleId}/InsightCards`
  Stream<List<InsightCardModel>> watchInsightCards(String moduleId) async* {
    yield [];

    try {
      await for (final snap in _db
          .collection('Modules')
          .doc(moduleId)
          .collection('InsightCards')
          .snapshots()) {
        yield snap.docs
            .map((doc) => InsightCardModel.fromMap(doc.id, doc.data()))
            .toList();
      }
    } catch (e) {
      debugPrint('[ModuleService] watchInsightCards($moduleId) error: $e');
    }
  }

  // ── ModuleContent Subcollection ─────────────────────────────────────────────

  /// Streams content items for a specific module, ordered by [order].
  ///
  /// Firestore path: `Modules/{moduleId}/ModuleContent`, ordered by `order`.
  Stream<List<ModuleContentModel>> watchModuleContent(String moduleId) async* {
    yield [];

    try {
      await for (final snap in _db
          .collection('Modules')
          .doc(moduleId)
          .collection('ModuleContent')
          .orderBy('order')
          .snapshots()) {
        yield snap.docs
            .map((doc) => ModuleContentModel.fromMap(doc.id, doc.data()))
            .toList();
      }
    } catch (e) {
      debugPrint('[ModuleService] watchModuleContent($moduleId) error: $e');
    }
  }
}
