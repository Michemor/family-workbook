import 'package:cloud_firestore/cloud_firestore.dart';

class UserResponseModel {
  final String contentId;
  final String moduleId;
  final String type;
  final String? selectedOptionId;
  final bool? isCorrect;
  final String? textResponse;
  final bool isCompleted;
  final int xpEarned;
  final Timestamp? timestamp;

  UserResponseModel({
    required this.contentId,
    required this.moduleId,
    required this.type,
    this.selectedOptionId,
    this.isCorrect,
    this.textResponse,
    this.isCompleted = false,
    this.xpEarned = 0,
    this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'contentId': contentId,
      'moduleId': moduleId,
      'type': type,
      'selectedOptionId': selectedOptionId,
      'isCorrect': isCorrect,
      'textResponse': textResponse,
      'isCompleted': isCompleted,
      'xpEarned': xpEarned,
      'timestamp': timestamp ?? FieldValue.serverTimestamp(),
    };
  }

  factory UserResponseModel.fromMap(Map<String, dynamic> map) {
    return UserResponseModel(
      contentId: map['contentId'] ?? '',
      moduleId: map['moduleId'] ?? '',
      type: map['type'] ?? '',
      selectedOptionId: map['selectedOptionId'],
      isCorrect: map['isCorrect'],
      textResponse: map['textResponse'],
      isCompleted: map['isCompleted'] ?? false,
      xpEarned: map['xpEarned'] ?? 0,
      timestamp: map['timestamp'] as Timestamp?,
    );
  }
}
