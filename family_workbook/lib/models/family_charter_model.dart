/// Root document of a Family Charter.
/// Stored at `FamilyCharter/{uuid}` with a `familyId` field for querying.
class FamilyCharterModel {
  final String id; // server UUID
  final String slug; // LLM suggestion, e.g. "family_charter_v1"
  final String title; // e.g. "The Martin Family Charter"
  final String preamble; // opening paragraph
  final String closingCommitment; // sign-off sentence
  final String familyId; // used to query the correct charter per family

  const FamilyCharterModel({
    required this.id,
    required this.slug,
    required this.title,
    required this.preamble,
    required this.closingCommitment,
    required this.familyId,
  });

  factory FamilyCharterModel.fromMap(String id, Map<String, dynamic> data) {
    return FamilyCharterModel(
      id: id,
      slug: data['slug'] as String? ?? '',
      title: data['title'] as String? ?? '',
      preamble: data['preamble'] as String? ?? '',
      closingCommitment: data['closing_commitment'] as String? ?? '',
      familyId: data['familyId'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'slug': slug,
    'title': title,
    'preamble': preamble,
    'closing_commitment': closingCommitment,
    'familyId': familyId,
  };
}

/// A single clause inside a Family Charter.
/// Stored at `FamilyCharter/{uuid}/Clauses/{clause_id}`.
class CharterClause {
  final String id; // e.g. "clause_1"
  final int weekReference; // which week this clause was authored in
  final String category; // e.g. "Boundaries" / "Core Values"
  final String statement; // e.g. "We commit to speaking our needs openly..."
  final String rationale; // e.g. "Because healthy boundaries build trust..."

  const CharterClause({
    required this.id,
    required this.weekReference,
    required this.category,
    required this.statement,
    required this.rationale,
  });

  factory CharterClause.fromMap(String id, Map<String, dynamic> data) {
    return CharterClause(
      id: id,
      weekReference: data['week_reference'] as int? ?? 0,
      category: data['category'] as String? ?? '',
      statement: data['statement'] as String? ?? '',
      rationale: data['rationale'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'week_reference': weekReference,
    'category': category,
    'statement': statement,
    'rationale': rationale,
  };
}

