import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/game_model.dart';

/// Provides real-time Firestore streams for the games catalogue and game
/// content, with hardcoded offline fallback data so the app stays playable
/// even when Firestore is unreachable or the cache is cold.
///
/// **Schema (updated)**
///
///   Games/{uuid}                    ← root catalogue document
///   Games/{uuid}/GameContent/content ← single fixed subcollection document
///     data.questions[]  (trivia)
///     data.cards[]      (conversations)
///     data.values[]     (matching)
class GameService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Game Catalogue ─────────────────────────────────────────────────────────

  /// Streams the list of active games from the `Games` Firestore collection,
  /// sorted by [order]. Falls back to [_fallbackCatalogue] on error.
  ///
  /// Firestore's built-in offline persistence means cached data is served
  /// automatically when the device is offline. The fallback is used only when
  /// the cache is empty (e.g., first launch with no connectivity).
  Stream<List<GameModel>> watchGameCatalogue() async* {
    // Immediately yield fallback data so the UI is never blank while loading.
    yield _fallbackCatalogue;

    try {
      await for (final snap in _db
          .collection('Games')
          .where('is_active', isEqualTo: true)
          .orderBy('order')
          .snapshots()) {
        final games = snap.docs
            .map((doc) => GameModel.fromMap(doc.id, doc.data()))
            .toList();
        yield games.isEmpty ? _fallbackCatalogue : games;
      }
    } catch (_) {
      // Firestore unavailable and cache empty — fallback already yielded above.
    }
  }

  // ── Game Content — new subcollection path ──────────────────────────────────

  /// Streams trivia questions from `Games/{gameId}/GameContent/content`.
  ///
  /// The document's `data.questions` field is a list of objects:
  ///   { question: String, options: String[4], answer_index: int }
  ///
  /// Falls back to [_fallbackTriviaQuestions] on error or missing document.
  Stream<List<Map<String, dynamic>>> watchTriviaQuestions(String gameId) async* {
    yield _fallbackTriviaQuestions;

    if (gameId.isEmpty) return;

    try {
      await for (final snap in _db
          .collection('Games')
          .doc(gameId)
          .collection('GameContent')
          .doc('content')
          .snapshots()) {
        if (!snap.exists || snap.data() == null) {
          yield _fallbackTriviaQuestions;
          continue;
        }
        final raw = snap.data()!['data']?['questions'];
        if (raw is! List || raw.isEmpty) {
          yield _fallbackTriviaQuestions;
          continue;
        }
        yield raw.cast<Map<String, dynamic>>();
      }
    } catch (_) {
      // Already yielded fallback.
    }
  }

  /// Streams conversation starter cards from `Games/{gameId}/GameContent/content`.
  ///
  /// The document's `data.cards` field is a list of strings (min 4).
  ///
  /// Falls back to [_fallbackConvoCards] on error or missing document.
  Stream<List<String>> watchConversationCards(String gameId) async* {
    yield _fallbackConvoCards;

    if (gameId.isEmpty) return;

    try {
      await for (final snap in _db
          .collection('Games')
          .doc(gameId)
          .collection('GameContent')
          .doc('content')
          .snapshots()) {
        if (!snap.exists || snap.data() == null) {
          yield _fallbackConvoCards;
          continue;
        }
        final raw = snap.data()!['data']?['cards'];
        if (raw is! List || raw.isEmpty) {
          yield _fallbackConvoCards;
          continue;
        }
        yield raw.cast<String>();
      }
    } catch (_) {
      // Already yielded fallback.
    }
  }

  /// Streams matching-game value words from `Games/{gameId}/GameContent/content`.
  ///
  /// The document's `data.values` field is a list of strings (min 4).
  ///
  /// Falls back to [_fallbackMatchingValues] on error or missing document.
  Stream<List<String>> watchMatchingValues(String gameId) async* {
    yield _fallbackMatchingValues;

    if (gameId.isEmpty) return;

    try {
      await for (final snap in _db
          .collection('Games')
          .doc(gameId)
          .collection('GameContent')
          .doc('content')
          .snapshots()) {
        if (!snap.exists || snap.data() == null) {
          yield _fallbackMatchingValues;
          continue;
        }
        final raw = snap.data()!['data']?['values'];
        if (raw is! List || raw.isEmpty) {
          yield _fallbackMatchingValues;
          continue;
        }
        yield raw.cast<String>();
      }
    } catch (_) {
      // Already yielded fallback.
    }
  }

  // ── Offline / Cold-cache Fallback Data ────────────────────────────────────
  // These mirror the data that was previously hardcoded in home_screen.dart.
  // They are also the seed data written to Firestore by the seed_games.js script.

  static final List<GameModel> _fallbackCatalogue = [
    const GameModel(
      id: 'trivia',
      title: 'Family Wisdom Quiz',
      description: 'Multiple choice trivia about communication and values.',
      iconName: 'quiz',
      colorHex: '#00897B',
      type: 'trivia',
      isActive: true,
      order: 1,
      xpReward: 25,
    ),
    const GameModel(
      id: 'matching',
      title: 'Values Matching Game',
      description: 'A fun memory card matchup focusing on core values.',
      iconName: 'grid_view',
      colorHex: '#9C27B0',
      type: 'matching',
      isActive: true,
      order: 2,
      xpReward: 20,
    ),
    const GameModel(
      id: 'conversations',
      title: 'Conversation Starters',
      description: 'A deck of meaningful, fun prompts for the dinner table.',
      iconName: 'forum',
      colorHex: '#E91E8C',
      type: 'conversations',
      isActive: true,
      order: 3,
      xpReward: 15,
    ),
  ];

  static final List<Map<String, dynamic>> _fallbackTriviaQuestions = [
    {
      'question': 'Which of these is a core key to building family trust?',
      'options': [
        'Active listening & honesty',
        'Buying expensive gifts',
        'Avoiding conversation',
        'Ignoring household rules',
      ],
      'answer_index': 0,
    },
    {
      'question': 'What is the primary purpose of a Family Charter?',
      'options': [
        'To track daily chores only',
        'To define shared values and structure',
        'To assign homework punishments',
        'To list family recipes',
      ],
      'answer_index': 1,
    },
    {
      'question':
          'How should conflicts be addressed in a healthy family structure?',
      'options': [
        'Silent treatment',
        'Shouting at each other',
        'Respectful dialogue and seeking common ground',
        'Pretending nothing happened',
      ],
      'answer_index': 2,
    },
    {
      'question':
          'Which of the following is NOT one of the 8 weekly modules?',
      'options': [
        'Boundaries & Safety',
        'Roles of Children',
        'Family Identity & Structure',
        'Advanced Cooking Skills',
      ],
      'answer_index': 3,
    },
    {
      'question': 'How often should a family hold family governance meetings?',
      'options': [
        'Once a year',
        'Regularly (e.g. weekly or monthly)',
        'Only during crises',
        'Never',
      ],
      'answer_index': 1,
    },
  ];

  static const List<String> _fallbackConvoCards = [
    "What is your absolute favorite memory of our family doing something together?",
    "If our family had a theme song or motto, what would you want it to be?",
    "What is one thing you appreciate most about the person sitting next to you?",
    "If you could travel anywhere in the world with the family tomorrow, where would you go?",
    "What is a family tradition you want to make sure we keep doing forever?",
    "What is one value you think is most important for our household?",
    "If you could trade places with any other family member for one day, who would it be and why?",
    "What was the most challenging part of your week, and how did you overcome it?",
  ];

  static const List<String> _fallbackMatchingValues = [
    'Love 💖',
    'Trust 🤝',
    'Safety 🛡️',
    'Respect 🙌',
    'Fun 🎉',
    'Unity 🧩',
  ];
}
