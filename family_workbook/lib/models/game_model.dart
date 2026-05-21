import 'package:flutter/material.dart';

/// Represents a single game entry in the Firestore `games` catalogue collection.
class GameModel {
  final String id;
  /// LLM-generated slug (e.g. "family-boundaries-trivia"). Never used as the
  /// Firestore document key — [id] (server UUID) is always the key.
  final String slug;
  final String title;
  final String description;
  final String iconName; // mapped to IconData via icon_mapper.dart
  final String colorHex; // e.g. "#9C27B0"
  final String type; // "trivia" | "matching" | "conversations"
  final bool isActive;
  final int order;
  /// XP awarded when a user completes this game.
  /// Default per schema: trivia=25, matching=20, conversations=15.
  final int xpReward;

  const GameModel({
    required this.id,
    this.slug = '',
    required this.title,
    required this.description,
    required this.iconName,
    required this.colorHex,
    required this.type,
    required this.isActive,
    required this.order,
    this.xpReward = 0,
  });

  /// Parses a Firestore document into a [GameModel].
  factory GameModel.fromMap(String id, Map<String, dynamic> data) {
    return GameModel(
      id: id,
      slug: data['slug'] as String? ?? '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      iconName: data['icon'] as String? ?? 'sports_esports',
      colorHex: data['color'] as String? ?? '#3B67B5',
      type: data['type'] as String? ?? '',
      isActive: data['isActive'] as bool? ?? true,
      order: data['order'] as int? ?? 99,
      xpReward: data['xp_reward'] as int? ?? _defaultXpForType(data['type'] as String? ?? ''),
    );
  }

  /// Returns the default XP for a game type per the content schema.
  static int _defaultXpForType(String type) {
    switch (type) {
      case 'trivia': return 25;
      case 'matching': return 20;
      case 'conversations': return 15;
      default: return 0;
    }
  }

  /// Converts the hex color string to a Flutter [Color].
  Color get color {
    final hex = colorHex.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  Map<String, dynamic> toMap() => {
        'slug': slug,
        'title': title,
        'description': description,
        'icon': iconName,
        'color': colorHex,
        'type': type,
        'isActive': isActive,
        'order': order,
        'xp_reward': xpReward,
      };
}
