class FamilyMemberModel {
  final String memberId;
  final String uid;
  final String name;
  final String role;
  final bool isSystemAdmin; // BUG FIX: was String, Firestore stores a bool

  FamilyMemberModel({
    required this.memberId,
    required this.uid,
    required this.name,
    required this.role,
    required this.isSystemAdmin,
  });

  factory FamilyMemberModel.fromMap(Map<String, dynamic> map, String docId) {
    return FamilyMemberModel(
      memberId: docId,
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? '',
      isSystemAdmin:
          map['isSystemAdmin'] ?? false, // BUG FIX: was ?? '' (empty string)
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'memberId': memberId,
      'uid': uid,
      'name': name,
      'role': role,
      'isSystemAdmin': isSystemAdmin,
    };
  }
}
