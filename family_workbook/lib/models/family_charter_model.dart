class FamilyCharterModel {
  final String id;
  final String title;
  final String preamble;
  final String closingCommitment;

  FamilyCharterModel({
    required this.id,
    required this.title,
    required this.preamble,
    required this.closingCommitment,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'preamble': preamble,
      'closingCommitment': closingCommitment,
    };
  }

  factory FamilyCharterModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    return FamilyCharterModel(
      id: docId ?? map['id'] ?? '',
      title: map['title'] ?? 'Family Charter',
      preamble: map['preamble'] ?? 'Our family principles and guidelines.',
      closingCommitment: map['closingCommitment'] ?? '',
    );
  }
}

class CharterClause {
  final String id;
  final String category;
  final String statement;
  final String rationale;
  final int weekReference;

  CharterClause({
    required this.id,
    required this.category,
    required this.statement,
    this.rationale = '',
    required this.weekReference,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'statement': statement,
      'rationale': rationale,
      'weekReference': weekReference,
    };
  }

  factory CharterClause.fromMap(Map<String, dynamic> map, [String? docId]) {
    return CharterClause(
      id: docId ?? map['id'] ?? '',
      category: map['category'] ?? 'General',
      statement: map['statement'] ?? '',
      rationale: map['rationale'] ?? '',
      weekReference: map['weekReference'] ?? 1,
    );
  }
}
