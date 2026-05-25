import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String username;
  final String email;
  final String? profilePictureUrl;
  final DateTime? createdAt;
  final String? familyId;
  final String? role; // e.g., 'admin', 'member'
  final String? contactNumber;
  final bool isPaid; // true = user has paid and has access
  final bool? isActive;
  final int? completionPercentage;
  final int? currentWeek;
  final String? personalityType;
  final int? gamePoints; // points earned from games

  // New field for tracking profile completion

  UserModel({
    required this.uid,
    required this.username,
    required this.email,
    this.profilePictureUrl,
    this.personalityType = 'Unknown',
    this.createdAt,
    this.familyId,
    this.role = 'user',
    this.contactNumber,
    this.isPaid = false,
    this.isActive = true,
    this.completionPercentage = 0,
    this.currentWeek = 1,
    this.gamePoints = 0,
  });

  // converting to map for database storage
  Map<String, dynamic> toMap() {
    return {
      'uid': uid, // BUG FIX: was 'id', must match fromMap key 'uid'
      'username': username,
      'email': email,
      'profilePictureUrl': profilePictureUrl,
      'createdAt': createdAt?.toIso8601String(),
      'familyId': familyId,
      'role': role,
      'personalityType': personalityType,
      'contactNumber': contactNumber,
      'isPaid': isPaid,
      'isActive': isActive,
      'completionPercentage': completionPercentage,
      'currentWeek': currentWeek,
      'gamePoints': gamePoints,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'], // BUG FIX: was map['id']
      username: map['username'],
      email: map['email'],
      profilePictureUrl: map['profilePictureUrl'],
      // BUG FIX: safely handle null and Firestore Timestamp types
      createdAt: map['createdAt'] == null
          ? null
          : (map['createdAt'] is Timestamp
                ? (map['createdAt'] as Timestamp).toDate()
                : DateTime.tryParse(map['createdAt'].toString())),
      familyId:
          map['familyId'],
      role: map['role'],
      contactNumber: map['contactNumber'],
      isPaid: map['isPaid'] as bool? ?? false,
      isActive: map['isActive'],
      personalityType: map['personalityType'],
      completionPercentage: map['completionPercentage'],
      currentWeek: map['currentWeek'],
      gamePoints: map['gamePoints'] as int? ?? 0,
    );
  }
}
