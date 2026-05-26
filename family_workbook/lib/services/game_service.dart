import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/game_model.dart';

class GameService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<GameModel>> watchGameCatalogue() {
    return _firestore.collection('games').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => GameModel.fromMap(doc.data(), doc.id)).toList());
  }

  Stream<List<dynamic>> watchTriviaQuestions(String gameId) {
    return _firestore
        .collection('games')
        .doc(gameId)
        .collection('questions')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Stream<List<dynamic>> watchConversationCards(String gameId) {
    return _firestore
        .collection('games')
        .doc(gameId)
        .collection('cards')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Stream<List<dynamic>> watchMatchingValues(String gameId) {
    return _firestore
        .collection('games')
        .doc(gameId)
        .collection('values')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }
}
