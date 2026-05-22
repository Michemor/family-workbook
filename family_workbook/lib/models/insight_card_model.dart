/// Represents a document in the `Modules/{week_id}/InsightCards/{card_id}`
/// subcollection. Insight cards are short, motivational bite-size lessons.
class InsightCardModel {
  final String id; // e.g. "insight_1_1"
  final String title; // e.g. "You set the tone at home"
  final String body; // e.g. "Children learn boundaries by watching..."

  const InsightCardModel({
    required this.id,
    required this.title,
    required this.body,
  });

  factory InsightCardModel.fromMap(String id, Map<String, dynamic> data) {
    return InsightCardModel(
      id: id,
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {'title': title, 'body': body};
}
