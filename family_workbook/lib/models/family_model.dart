import 'package:cloud_firestore/cloud_firestore.dart';

class FamilyModel {
  final String familyId;
  final String familyName;
  final DateTime createdAt;
  final double
  overallCompletionPercentage; // New field to track overall family progress
  final double charterReadinessScore;
  final String country;
  final String familyType; // e.g., nuclear, extended, single-parent
  final List<String> members; // List of user IDs

  FamilyModel({
    required this.familyId,
    required this.familyName,
    required this.createdAt,
    required this.country,
    required this.familyType,
    required this.members,
    this.overallCompletionPercentage = 0.0,
    this.charterReadinessScore = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'familyId': familyId,
      'familyName': familyName,
      'createdAt': createdAt.toIso8601String(),
      'country': country,
      'familyType': familyType,
      'members': members,
      'overallCompletionPercentage': overallCompletionPercentage,
      'charterReadinessScore': charterReadinessScore,
    };
  }

  factory FamilyModel.fromMap(Map<String, dynamic> map) {
    return FamilyModel(
      familyId: map['familyId'],
      familyName: map['familyName'],
      // BUG FIX: handle DateTime (pre-converted), Timestamp, or ISO String
      createdAt: map['createdAt'] is DateTime
          ? map['createdAt'] as DateTime
          : (map['createdAt'] is Timestamp
                ? (map['createdAt'] as Timestamp).toDate()
                : DateTime.tryParse(map['createdAt'].toString()) ??
                      DateTime.now()),
      country: map['country'],
      familyType: map['familyType'],
      // BUG FIX: members may be null if not set in Firestore — default to empty list
      members: map['members'] != null ? List<String>.from(map['members']) : [],
      overallCompletionPercentage: map['overallCompletionPercentage'] ?? 0.0,
      charterReadinessScore: map['charterReadinessScore'] ?? 0.0,
    );
  }
}
