import 'package:flutter/material.dart';

class GameModel {
  final String id;
  final String type;
  final String title;
  final String description;
  final String iconName;
  final Color color;
  final int xpReward;

  GameModel({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.iconName,
    required this.color,
    this.xpReward = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'description': description,
      'iconName': iconName,
      'color': color.toValue(), // Custom extension likely needed or just int
      'xpReward': xpReward,
    };
  }

  factory GameModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    return GameModel(
      id: docId ?? map['id'] ?? '',
      type: map['type'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      iconName: map['iconName'] ?? '',
      color: Color(map['color'] ?? 0xFF000000),
      xpReward: map['xpReward'] ?? 0,
    );
  }
}

extension ColorExtension on Color {
  int toValue() => value;
}
