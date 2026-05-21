/// Represents a root document in the Firestore `Modules/{week_id}` collection.
class ModuleModel {
  final String id; // e.g. "week_1"
  final String title; // e.g. "Boundaries and Safety"
  final int week; // 1–8
  final String description; // warm overview text
  final int totalModuleXp; // e.g. 135
  final List<String> tags; // e.g. ["boundaries", "safety"]
  final bool active;

  const ModuleModel({
    required this.id,
    required this.title,
    required this.week,
    required this.description,
    required this.totalModuleXp,
    required this.tags,
    required this.active,
  });

  factory ModuleModel.fromMap(String id, Map<String, dynamic> data) {
    return ModuleModel(
      id: id,
      title: data['title'] as String? ?? '',
      week: data['week'] as int? ?? 0,
      description: data['description'] as String? ?? '',
      totalModuleXp: data['total_module_xp'] as int? ?? 0,
      tags: List<String>.from(data['tags'] as List? ?? []),
      active: data['active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'week': week,
    'description': description,
    'total_module_xp': totalModuleXp,
    'tags': tags,
    'active': active,
  };
}
