import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_response_model.dart';

/// Handles reading and writing user responses to module content items.
///
/// Firestore path:
///   `users/{uid}/ModuleResponses/{moduleId}/Responses/{contentId}`
///
/// The document ID is always the [contentId] — saves are idempotent:
/// re-submitting the same item overwrites the previous answer while preserving
/// the original [completedAt] timestamp.
class ResponseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Read ────────────────────────────────────────────────────────────────────

  /// Streams all responses for a module as a map keyed by [contentId].
  ///
  /// This lets the lesson UI do O(1) lookup: `responses[item.id]`.
  /// Emits an empty map immediately so the UI renders before the first snapshot.
  Stream<Map<String, UserResponseModel>> watchModuleResponses(
    String uid,
    String moduleId,
  ) async* {
    yield {};

    if (uid.isEmpty || moduleId.isEmpty) return;

    try {
      await for (final snap in _db
          .collection('users')
          .doc(uid)
          .collection('ModuleResponses')
          .doc(moduleId)
          .collection('Responses')
          .snapshots()) {
        final map = <String, UserResponseModel>{};
        for (final doc in snap.docs) {
          map[doc.id] = UserResponseModel.fromMap(doc.id, doc.data());
        }
        yield map;
      }
    } catch (e) {
      debugPrint('[ResponseService] watchModuleResponses error: $e');
    }
  }

  // ── Write ───────────────────────────────────────────────────────────────────

  /// Saves (or updates) a response for a single content item.
  ///
  /// - On the **first** save: writes both the response data **and**
  ///   `completedAt` (server timestamp).
  /// - On **subsequent** saves (same contentId): merges only the mutable
  ///   response fields, leaving `completedAt` unchanged.
  Future<void> saveResponse({
    required String uid,
    required UserResponseModel response,
  }) async {
    if (uid.isEmpty) return;

    final docRef = _db
        .collection('users')
        .doc(uid)
        .collection('ModuleResponses')
        .doc(response.moduleId)
        .collection('Responses')
        .doc(response.contentId);

    try {
      final existing = await docRef.get();

      final data = response.toMap();

      if (!existing.exists) {
        // First submission — set completedAt
        data['completedAt'] = FieldValue.serverTimestamp();
        await docRef.set(data);
      } else {
        // Subsequent edit — update response fields only, never touch completedAt
        await docRef.update(data);
      }
    } catch (e) {
      debugPrint('[ResponseService] saveResponse error: $e');
      rethrow;
    }
  }

  /// Saves multiple responses in a single WriteBatch, and increments XP in the
  /// same batch to minimize writes.
  Future<void> saveResponsesBatch({
    required String uid,
    required List<UserResponseModel> responses,
    required List<bool> isFirstSubmissions,
    String? familyId,
  }) async {
    if (uid.isEmpty || responses.isEmpty) return;

    final batch = _db.batch();
    int totalXpToRecord = 0;

    for (int i = 0; i < responses.length; i++) {
      final response = responses[i];
      final isFirst = isFirstSubmissions[i];
      
      final docRef = _db
          .collection('users')
          .doc(uid)
          .collection('ModuleResponses')
          .doc(response.moduleId)
          .collection('Responses')
          .doc(response.contentId);

      final data = response.toMap();

      if (isFirst) {
        // First submission — set completedAt
        data['completedAt'] = FieldValue.serverTimestamp();
        batch.set(docRef, data);
        totalXpToRecord += response.xpEarned;
      } else {
        // Subsequent edit — update response fields only
        batch.update(docRef, data);
      }
    }

    // Include XP increment in the same batch
    if (totalXpToRecord > 0) {
      batch.update(_db.collection('users').doc(uid), {
        'xp_earned_total': FieldValue.increment(totalXpToRecord),
      });

      if (familyId != null && familyId.isNotEmpty) {
        batch.update(_db.collection('families').doc(familyId), {
          'xp_earned_total': FieldValue.increment(totalXpToRecord),
        });
      }
    }

    try {
      await batch.commit();
    } catch (e) {
      debugPrint('[ResponseService] saveResponsesBatch error: $e');
      rethrow;
    }
  }

  // ── XP Tracking ─────────────────────────────────────────────────────────────

  /// Increments XP totals on both the user and family documents.
  ///
  /// - `users/{uid}.xp_earned_total`          += [xp]
  /// - `families/{familyId}.xp_earned_total`  += [xp]  (if familyId is set)
  ///
  /// This should be called **once** per content item, guarded by checking
  /// whether the response already exists (i.e. [UserResponseModel.xpEarned] > 0)
  /// before calling to prevent double-counting on re-submissions.
  Future<void> recordXp({
    required String uid,
    required String? familyId,
    required int xp,
  }) async {
    if (uid.isEmpty || xp <= 0) return;

    final batch = _db.batch();

    batch.update(_db.collection('users').doc(uid), {
      'xp_earned_total': FieldValue.increment(xp),
    });

    if (familyId != null && familyId.isNotEmpty) {
      batch.update(_db.collection('families').doc(familyId), {
        'xp_earned_total': FieldValue.increment(xp),
      });
    }

    try {
      await batch.commit();
    } catch (e) {
      debugPrint('[ResponseService] recordXp error: $e');
      // Non-fatal — XP tracking failure should not block the user experience.
    }
  }
}
