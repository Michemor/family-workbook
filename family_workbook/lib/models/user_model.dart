import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String username;
  final String email;
  final String? profilePictureUrl;
  final Timestamp? createdAt;
  final int gamePoints;
  final String? familyId;
  final String? role; // e.g., 'admin', 'member'
  final String? contactNumber;
  final String? subscriptionStatus; // e.g., 'free', 'premium'
  final String? personalityType;
  final bool isActive;
  final double completionPercentage;
  final int? currentWeek;

  bool get isPaid => subscriptionStatus == 'premium' || subscriptionStatus == 'paid';

  const UserModel({
    required this.uid,
    required this.username,
    required this.email,
    this.profilePictureUrl,
    this.createdAt,
    this.gamePoints = 0,
    this.familyId,
    this.role,
    this.contactNumber,
    this.subscriptionStatus = 'trial',
    this.personalityType,
    this.isActive = true,
    this.completionPercentage = 0.0,
    this.currentWeek = 1,
  });

  // converting to map for database storage
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username,
      'email': email,
      'profilePictureUrl': profilePictureUrl,
      'createdAt': createdAt,
      'gamePoints': gamePoints,
      'familyId': familyId,
      'role': role,
      'contactNumber': contactNumber,
      'subscriptionStatus': subscriptionStatus,
      'personalityType': personalityType,
      'isActive': isActive,
      'completionPercentage': completionPercentage,
      'currentWeek': currentWeek,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String,
      username: map['username'] as String,
      email: map['email'] as String,
      profilePictureUrl: map['profilePictureUrl'] as String?,
      createdAt: map['createdAt'] as Timestamp?,
      gamePoints: map['gamePoints'] as int? ?? 0,
      familyId: map['familyId'] as String?,
      role: map['role'] as String?,
      contactNumber: map['contactNumber'] as String?,
      subscriptionStatus: map['subscriptionStatus'] as String?,
      personalityType: map['personalityType'] as String?,
      isActive: map['isActive'] ?? true,
      completionPercentage:
          (map['completionPercentage'] as num?)?.toDouble() ?? 0.0,
      currentWeek: map['currentWeek'],
    );
  }

  UserModel copyWith({
    String? uid,
    String? username,
    String? email,
    String? profilePictureUrl,
    Timestamp? createdAt,
    int? gamePoints,
    String? familyId,
    String? role,
    String? contactNumber,
    String? subscriptionStatus,
    String? personalityType,
    bool? isActive,
    double? completionPercentage,
    int? currentWeek,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      username: username ?? this.username,
      email: email ?? this.email,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      createdAt: createdAt ?? this.createdAt,
      gamePoints: gamePoints ?? this.gamePoints,
      familyId: familyId ?? this.familyId,
      role: role ?? this.role,
      contactNumber: contactNumber ?? this.contactNumber,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      personalityType: personalityType ?? this.personalityType,
      isActive: isActive ?? this.isActive,
      completionPercentage: completionPercentage ?? this.completionPercentage,
      currentWeek: currentWeek ?? this.currentWeek,
    );
  }
}
