import 'package:cloud_firestore/cloud_firestore.dart';

/// A persisted user response to a single [ModuleContentModel] item.
///
/// Stored at:
///   `users/{uid}/ModuleResponses/{moduleId}/Responses/{contentId}`
///
/// The document ID is always the [contentId], making saves idempotent —
/// re-submitting the same item overwrites the previous answer.
class UserResponseModel {
  /// The Firestore document ID — same as the ModuleContent item ID.
  final String contentId;

  /// The parent module ID (e.g. "week_1").
  final String moduleId;

  /// Mirrors the ModuleContent type: "reflection" | "assessment" | "activity" | "game"
  final String type;

  /// Free-text answer — populated for `reflection` and `activity` types.
  final String? textResponse;

  /// The selected option ID — populated for `assessment` type.
  final String? selectedOptionId;

  /// Whether the selected option was correct — populated for `assessment` type.
  final bool? isCorrect;

  /// XP earned when this item was first completed. 0 until submitted.
  final int xpEarned;

  /// Server timestamp set on the first successful write (never overwritten).
  final DateTime? completedAt;

  const UserResponseModel({
    required this.contentId,
    required this.moduleId,
    required this.type,
    this.textResponse,
    this.selectedOptionId,
    this.isCorrect,
    required this.xpEarned,
    this.completedAt,
  });

  factory UserResponseModel.fromMap(String contentId, Map<String, dynamic> data) {
    DateTime? completedAt;
    final rawTs = data['completedAt'];
    if (rawTs is Timestamp) completedAt = rawTs.toDate();

    return UserResponseModel(
      contentId: contentId,
      moduleId: data['moduleId'] as String? ?? '',
      type: data['type'] as String? ?? '',
      textResponse: data['textResponse'] as String?,
      selectedOptionId: data['selectedOptionId'] as String?,
      isCorrect: data['isCorrect'] as bool?,
      xpEarned: data['xpEarned'] as int? ?? 0,
      completedAt: completedAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'contentId': contentId,
    'moduleId': moduleId,
    'type': type,
    if (textResponse != null) 'textResponse': textResponse,
    if (selectedOptionId != null) 'selectedOptionId': selectedOptionId,
    if (isCorrect != null) 'isCorrect': isCorrect,
    'xpEarned': xpEarned,
    // completedAt is only set on the first write via FieldValue.serverTimestamp()
    // and should not be overwritten on subsequent edits — handled in ResponseService.
  };

  /// Whether the user has actually submitted this item yet.
  bool get isCompleted => xpEarned > 0 || (textResponse?.isNotEmpty ?? false) || selectedOptionId != null;
}
