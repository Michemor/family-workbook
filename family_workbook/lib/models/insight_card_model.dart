class InsightCardModel {
  final String id;
  final String title;
  final String body;

  InsightCardModel({
    required this.id,
    required this.title,
    required this.body,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
    };
  }

  factory InsightCardModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    return InsightCardModel(
      id: docId ?? map['id'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
    );
  }
}
