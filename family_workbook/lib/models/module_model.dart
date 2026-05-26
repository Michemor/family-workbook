import 'package:cloud_firestore/cloud_firestore.dart';

class ModuleModel {
  final String id;
  final int week;
  final bool active;
  final String title;
  final String description;
  final List<String> tags;
  final int totalModuleXp;

  ModuleModel({
    required this.id,
    required this.week,
    this.active = true,
    required this.title,
    required this.description,
    this.tags = const [],
    this.totalModuleXp = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'week': week,
      'active': active,
      'title': title,
      'description': description,
      'tags': tags,
      'totalModuleXp': totalModuleXp,
    };
  }

  factory ModuleModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    return ModuleModel(
      id: docId ?? map['id'] ?? '',
      week: map['week'] ?? 1,
      active: map['active'] ?? true,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      tags: List<String>.from(map['tags'] ?? []),
      totalModuleXp: map['totalModuleXp'] ?? 0,
    );
  }
}
