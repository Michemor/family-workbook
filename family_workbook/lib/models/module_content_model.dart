/// A single selectable option inside an assessment [ModuleContentModel].
class ModuleContentOption {
  final String optionId; // e.g. "opt_a"
  final String optionText; // e.g. "Talk calmly about the rule"
  final bool isCorrect;

  const ModuleContentOption({
    required this.optionId,
    required this.optionText,
    required this.isCorrect,
  });

  factory ModuleContentOption.fromMap(Map<String, dynamic> data) {
    return ModuleContentOption(
      optionId: data['option_id'] as String? ?? '',
      optionText: data['option_text'] as String? ?? '',
      isCorrect: data['is_correct'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    'option_id': optionId,
    'option_text': optionText,
    'is_correct': isCorrect,
  };
}

/// Represents a document in the `Modules/{week_id}/ModuleContent/{item_id}`
/// subcollection.
///
/// [type] is one of: "reflection" | "assessment" | "activity" | "game"
/// [options] is only populated when [type] == "assessment".
class ModuleContentModel {
  final String id; // e.g. "reflection_1_1"
  final String type; // "reflection" | "assessment" | "activity" | "game"
  final String question; // primary prompt shown to the user
  final String description; // optional guiding instructions
  final int xpReward; // 10, 15, or 35
  final List<ModuleContentOption> options; // only for assessment type
  final int order; // display order within the module (auto-assigned)

  const ModuleContentModel({
    required this.id,
    required this.type,
    required this.question,
    required this.description,
    required this.xpReward,
    required this.options,
    required this.order,
  });

  factory ModuleContentModel.fromMap(String id, Map<String, dynamic> data) {
    final rawOptions = data['options'] as List? ?? [];
    return ModuleContentModel(
      id: id,
      type: data['type'] as String? ?? 'reflection',
      question: data['question'] as String? ?? '',
      description: data['description'] as String? ?? '',
      xpReward: data['xp_reward'] as int? ?? 0,
      options:
          rawOptions
              .map(
                (o) =>
                    ModuleContentOption.fromMap(o as Map<String, dynamic>),
              )
              .toList(),
      order: data['order'] as int? ?? 99,
    );
  }

  Map<String, dynamic> toMap() => {
    'type': type,
    'question': question,
    'description': description,
    'xp_reward': xpReward,
    'options': options.map((o) => o.toMap()).toList(),
    'order': order,
  };
}
