import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/family_charter_model.dart';

/// Provides Firestore streams for the FamilyCharter collection and its
/// Clauses subcollection:
///   - `FamilyCharter/{uuid}`                  → [FamilyCharterModel]
///   - `FamilyCharter/{uuid}/Clauses/{id}`     → [CharterClause]
///
/// Each family owns exactly one charter, identified by a `familyId` field on
/// the root document. Use [watchFamilyCharter] to find it.
class CharterService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Charter Root Document ───────────────────────────────────────────────────

  /// Streams the charter document that belongs to [familyId].
  ///
  /// Firestore path: `FamilyCharter` where `familyId == familyId`, limit 1.
  /// Emits `null` when no charter exists yet for this family.
  Stream<FamilyCharterModel?> watchFamilyCharter(String familyId) async* {
    yield null; // immediate yield so UI can show "not created yet" state

    if (familyId.isEmpty) return;

    try {
      await for (final snap in _db
          .collection('FamilyCharter')
          .where('familyId', isEqualTo: familyId)
          .limit(1)
          .snapshots()) {
        if (snap.docs.isEmpty) {
          yield null;
        } else {
          final doc = snap.docs.first;
          yield FamilyCharterModel.fromMap(doc.id, doc.data());
        }
      }
    } catch (e) {
      debugPrint('[CharterService] watchFamilyCharter($familyId) error: $e');
    }
  }

  // ── Clauses Subcollection ───────────────────────────────────────────────────

  /// Streams clauses for a specific charter, ordered by [weekReference].
  ///
  /// Firestore path: `FamilyCharter/{charterId}/Clauses`, ordered by `week_reference`.
  Stream<List<CharterClause>> watchClauses(String charterId) async* {
    yield [];

    if (charterId.isEmpty) return;

    try {
      await for (final snap in _db
          .collection('FamilyCharter')
          .doc(charterId)
          .collection('Clauses')
          .orderBy('week_reference')
          .snapshots()) {
        yield snap.docs
            .map((doc) => CharterClause.fromMap(doc.id, doc.data()))
            .toList();
      }
    } catch (e) {
      debugPrint('[CharterService] watchClauses($charterId) error: $e');
    }
  }
}
