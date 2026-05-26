class ModuleContentModel {
  final String id;
  final String type;
  final String question;
  final String description;
  final int xpReward;
  final List<ContentOption> options;

  ModuleContentModel({
    required this.id,
    required this.type,
    required this.question,
    this.description = '',
    required this.xpReward,
    this.options = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'question': question,
      'description': description,
      'xpReward': xpReward,
      'options': options.map((e) => e.toMap()).toList(),
    };
  }

  factory ModuleContentModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    return ModuleContentModel(
      id: docId ?? map['id'] ?? '',
      type: map['type'] ?? '',
      question: map['question'] ?? '',
      description: map['description'] ?? '',
      xpReward: map['xpReward'] ?? 0,
      options: (map['options'] as List? ?? [])
          .map((e) => ContentOption.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class ContentOption {
  final String optionId;
  final String text;
  final bool isCorrect;

  String get optionText => text;

  ContentOption({
    required this.optionId,
    required this.text,
    required this.isCorrect,
  });

  Map<String, dynamic> toMap() {
    return {
      'optionId': optionId,
      'text': text,
      'isCorrect': isCorrect,
    };
  }

  factory ContentOption.fromMap(Map<String, dynamic> map) {
    return ContentOption(
      optionId: map['optionId'] ?? '',
      text: map['text'] ?? '',
      isCorrect: map['isCorrect'] ?? false,
    );
  }
}
