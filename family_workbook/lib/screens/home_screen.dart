import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/family_service.dart';
import '../services/game_service.dart';
import '../services/module_service.dart';
import '../services/charter_service.dart';
import '../services/response_service.dart';
import '../models/user_model.dart';
import '../models/family_model.dart';
import '../models/family_member_model.dart';
import '../models/game_model.dart';
import '../models/module_model.dart';
import '../models/insight_card_model.dart';
import '../models/module_content_model.dart';
import '../models/family_charter_model.dart';
import '../models/user_response_model.dart';
import '../utils/icon_mapper.dart';
import 'home/shared/xp_badge.dart';
import 'home/shared/page_indicator.dart';
import 'home/shared/empty_state.dart';
import 'home/shared/stat_card.dart';
import 'welcome_screen.dart';
import 'family_setup_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  final _familyService = FamilyService();
  final _gameService = GameService();
  final _moduleService = ModuleService();
  final _charterService = CharterService();
  final _responseService = ResponseService();
  UserModel? _currentUser;
  FamilyModel? _currentFamily;
  bool _isLoadingData = true;
  int _selectedIndex = 0;

  // Navigation subpage parameters
  String? _activeSubPage;
  Map<String, dynamic>? _subPageParams;

  // Visa Payment controllers and variables
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  bool _isAnnualSelected = true;
  String _cardNumText = '•••• •••• •••• ••••';
  String _cardExpiryText = 'MM/YY';
  String _cardCvvText = 'CVV';

  // Lesson inputs controllers
  final _lessonInput1Controller = TextEditingController();
  final _lessonInput2Controller = TextEditingController();

  // Trivia state
  int _triviaIndex = 0;
  int _triviaScore = 0;
  int? _selectedTriviaOption;
  bool _triviaAnswered = false;

  // Matching game state
  List<String> _matchingCards = [];
  List<bool> _matchingFlipped = [];
  List<bool> _matchingMatched = [];
  int? _firstFlippedIndex;
  bool _matchingIgnoreTaps = false;
  int _matchingMoves = 0;

  // Conversation Starter state
  int _convoIndex = 0;

  // ── Game backend streams ───────────────────────────────────────────────────
  /// Live game catalogue fetched from Firestore `Games` collection.
  List<GameModel> _gameCatalogue = [];
  bool _gamesLoading = true;

  /// Live game content — populated from Firestore, with offline fallback.
  List<Map<String, dynamic>> _triviaQuestions = [];
  List<String> _convoCards = [];
  List<String> _matchingValuePool = [];

  // ── Module backend streams ─────────────────────────────────────────────────
  List<ModuleModel> _modules = [];
  bool _modulesLoading = true;

  // Active lesson — populated when the user navigates into a lesson subpage.
  List<InsightCardModel> _activeInsightCards = [];
  List<ModuleContentModel> _activeModuleContent = [];
  /// Responses keyed by contentId for O(1) lookup in the lesson view.
  Map<String, UserResponseModel> _activeResponses = {};
  bool _lessonContentLoading = false;

  // ── Lesson PageView controller ─────────────────────────────────────────────
  final PageController _lessonPageController = PageController();
  int _lessonPageIndex = 0;
  bool _assessmentAnswered = false;

  // ── Charter backend streams ────────────────────────────────────────────────
  FamilyCharterModel? _familyCharter;
  List<CharterClause> _charterClauses = [];
  bool _charterLoading = true;

  // ── Family members stream ────────────────────────────────────────────────
  List<FamilyMemberModel> _familyMembers = [];
  StreamSubscription<List<FamilyMemberModel>>? _familyMembersSub;

  // Stream subscriptions (cancelled in dispose)
  StreamSubscription<List<GameModel>>? _catalogueSub;
  StreamSubscription<List<Map<String, dynamic>>>? _triviaSub;
  StreamSubscription<List<String>>? _convoSub;
  StreamSubscription<List<String>>? _matchingSub;
  StreamSubscription<List<ModuleModel>>? _modulesSub;
  StreamSubscription<FamilyCharterModel?>? _charterSub;
  StreamSubscription<List<CharterClause>>? _clausesSub;
  // Lesson-scoped subscriptions — cancelled on exit
  StreamSubscription<List<InsightCardModel>>? _insightCardsSub;
  StreamSubscription<List<ModuleContentModel>>? _moduleContentSub;
  StreamSubscription<Map<String, UserResponseModel>>? _responsesSub;

  final List<String> weekTopics = [
    'Definition of Family',
    'Purpose of Family',
    'Types of Families',
    'Family Leadership Principles',
    'Roles of Father',
    'Roles of Mother',
    'Roles of Children',
    'Family Responsibility Framework',
    'Household Governance Concepts',
  ];

  // Hardcoded lists removed — game content now streams from Firestore via
  // GameService. Fallback data lives in GameService._fallback* constants.
  // _triviaQuestions, _convoCards, _matchingValuePool are declared above.

  final Map<int, Map<String, dynamic>> lessonData = {
    1: {
      'title': 'Family Identity & Structure',
      'subtitle':
          'Define your family identity and establish clear leadership roles.',
      'readText':
          'Every great institution has a clear identity and purpose. A family is no different. In this module, you will define your family name, identify your core family values, and establish clear roles and responsibilities for parents and children. Establishing structural clarity provides security for children and alignment for parents.',
      'question1':
          'What is your Family\'s Core Identity or Name? (e.g. The Brave Browns)',
      'question2': 'What is your family\'s shared motto or tagline?',
    },
    2: {
      'title': 'Love & Communication',
      'subtitle':
          'Foster deep connection and practice active emotional listening.',
      'readText':
          'Healthy communication is the glue that keeps a family together. Learning to speak each other\'s love languages and practicing active listening prevents misunderstandings and makes every family member feel valued. In this module, you will discover your family members\' love languages and practice the "Active Listening" protocol.',
      'question1': 'List the main communication barrier in your home today:',
      'question2': 'Write down one active listening goal for this week:',
    },
    3: {
      'title': 'Safety & Boundaries',
      'subtitle':
          'Create a safe emotional and physical environment with rules.',
      'readText':
          'Rules without relationship lead to rebellion. In this module, you will establish emotional and physical safety rules. You will define household boundaries that protect your children while teaching them respect for others\' boundaries.',
      'question1': 'What is one major household rule you want to establish?',
      'question2':
          'How will your family handle digital screen time boundaries?',
    },
    4: {
      'title': 'Traditions & Rituals',
      'subtitle': 'Build lasting memories and shared family events.',
      'readText':
          'Traditions give families a sense of belonging and identity. In this module, you will outline yearly, monthly, and weekly rituals (like family dinners, game nights, or holiday traditions) that create lifetime memories.',
      'question1': 'Write down a new weekly ritual you want to start:',
      'question2': 'Describe your favorite annual family holiday tradition:',
    },
    5: {
      'title': 'Father\'s Leadership & Vows',
      'subtitle': 'Define paternal responsibilities and vision.',
      'readText':
          'Fathers play a critical role in providing, protecting, and guiding the family. In this module, you will draft the father\'s leadership guidelines and vows to support the spouse and children.',
      'question1': 'What is the father\'s commitment to emotional presence?',
      'question2':
          'How will the father support the mother\'s goals and dreams?',
    },
    6: {
      'title': 'Mother\'s Role & Vows',
      'subtitle': 'Define maternal support, nurturing, and guidance.',
      'readText':
          'Mothers provide essential nurturing, wisdom, and leadership. In this module, you will draft the mother\'s guidance covenants and vows to foster love and character development.',
      'question1': 'What is the mother\'s promise for nurturing character?',
      'question2':
          'How will the mother encourage open communication and trust?',
    },
    7: {
      'title': 'Children\'s Code & Vows',
      'subtitle': 'Instill honor, respect, and responsibility in children.',
      'readText':
          'Children grow best when they learn to take responsibility, honor authority, and contribute to the household. In this module, you will create a code of honor for the kids.',
      'question1': 'What chores or responsibilities will the children own?',
      'question2':
          'How will the children show honor and respect in communication?',
    },
    8: {
      'title': 'Family Constitution',
      'subtitle': 'Ratify your final rules, governance, and charter.',
      'readText':
          'The final step is to combine all your vows and agreements into a single Family Constitution. This document governs decisions and serves as a legacy charter for future generations.',
      'question1': 'How will our family resolve constitution disputes?',
      'question2': 'Where will the Family Charter be displayed in our home?',
    },
  };

  @override
  void initState() {
    super.initState();
    _lessonPageController.addListener(() {
      if (mounted) {
        setState(() {
          _lessonPageIndex = _lessonPageController.page?.round() ?? 0;
        });
      }
    });
    _loadData();
    _startGameStreams();
    _startModuleStreams();
    _startCharterStreams();

    // Card input listeners to dynamically draw on the preview card
    _cardNumberController.addListener(() {
      setState(() {
        _cardNumText = _cardNumberController.text.isEmpty
            ? '•••• •••• •••• ••••'
            : _cardNumberController.text;
      });
    });

    _expiryController.addListener(() {
      setState(() {
        _cardExpiryText = _expiryController.text.isEmpty
            ? 'MM/YY'
            : _expiryController.text;
      });
    });

    _cvvController.addListener(() {
      setState(() {
        _cardCvvText = _cvvController.text.isEmpty
            ? 'CVV'
            : _cvvController.text;
      });
    });
  }

  @override
  void dispose() {
    // Cancel all stream subscriptions
    _catalogueSub?.cancel();
    _triviaSub?.cancel();
    _convoSub?.cancel();
    _matchingSub?.cancel();
    _modulesSub?.cancel();
    _charterSub?.cancel();
    _clausesSub?.cancel();
    _familyMembersSub?.cancel();
    _insightCardsSub?.cancel();
    _moduleContentSub?.cancel();
    _responsesSub?.cancel();
    _lessonPageController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _lessonInput1Controller.dispose();
    _lessonInput2Controller.dispose();
    super.dispose();
  }

  /// Subscribes to the Firestore game catalogue stream.
  /// Content streams (trivia/conversations/matching) are started lazily when
  /// the user selects a specific game, so we can pass the correct [gameId].
  void _startGameStreams() {
    _catalogueSub = _gameService.watchGameCatalogue().listen((games) {
      if (mounted) {
        setState(() {
          _gameCatalogue = games;
          _gamesLoading = false;
        });
      }
    });
  }

  /// Starts content streams for a specific game by its Firestore [gameId].
  void _startGameContentStreams(String gameId, String gameType) {
    _triviaSub?.cancel();
    _convoSub?.cancel();
    _matchingSub?.cancel();

    switch (gameType) {
      case 'trivia':
        _triviaSub = _gameService.watchTriviaQuestions(gameId).listen((q) {
          if (mounted) setState(() => _triviaQuestions = q);
        });
        break;
      case 'conversations':
        _convoSub = _gameService.watchConversationCards(gameId).listen((c) {
          if (mounted) setState(() => _convoCards = c);
        });
        break;
      case 'matching':
        _matchingSub = _gameService.watchMatchingValues(gameId).listen((v) {
          if (mounted) setState(() => _matchingValuePool = v);
        });
        break;
    }
  }

  /// Subscribes to live modules from Firestore.
  void _startModuleStreams() {
    _modulesSub = _moduleService.watchModules().listen((modules) {
      if (mounted) {
        setState(() {
          _modules = modules;
          _modulesLoading = false;
        });
      }
    });
  }

  void _startFamilyMembersStream() {
    final familyId = _currentFamily?.familyId ?? '';
    if (familyId.isNotEmpty) {
      _familyMembersSub?.cancel();
      _familyMembersSub = _familyService.streamFamilyMembers(familyId).listen((members) {
        if (mounted) setState(() => _familyMembers = members);
      });
    }
  }

  /// Subscribes to the family charter and its clauses.
  /// Called after family data is loaded so [_currentFamily] is available.
  void _startCharterStreams() {
    final familyId = _currentFamily?.familyId ?? '';
    _charterSub = _charterService.watchFamilyCharter(familyId).listen((charter) {
      if (!mounted) return;
      setState(() {
        _familyCharter = charter;
        _charterLoading = false;
      });
      // When the charter doc changes, re-subscribe to its clauses.
      _clausesSub?.cancel();
      if (charter != null) {
        _clausesSub = _charterService.watchClauses(charter.id).listen((clauses) {
          if (mounted) setState(() => _charterClauses = clauses);
        });
      } else {
        if (mounted) setState(() => _charterClauses = []);
      }
    });
  }

  Future<void> _loadData() async {
    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        setState(() {
          _currentUser = user;
        });
        if (user.familyId == null || user.familyId!.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => FamilySetupScreen(
                  isJoining: false,
                  user: user,
                ),
              ),
            );
          });
        } else {
          if (user.familyId != null && user.familyId!.isNotEmpty) {
            final family = await _familyService.getFamilyById(user.familyId!);
            if (family != null) {
              setState(() {
                _currentFamily = family;
              });
              // Now that family is loaded, start charter streams.
              _startCharterStreams();
              _startFamilyMembersStream();
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading home dashboard data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
      }
    }
  }

  Future<void> _updateCurrentWeek(int newWeek) async {
    final uid = _currentUser?.uid;
    if (uid != null) {
      final completion =
          (newWeek - 1) * 12.5; // (8 weeks, 12.5% per week completed)

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'currentWeek': newWeek,
        'completionPercentage': completion.toInt(),
      });

      final familyId = _currentUser?.familyId;
      if (familyId != null && familyId.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('families')
            .doc(familyId)
            .update({
              'overallCompletionPercentage': completion,
              'charterReadinessScore': completion,
            });
      }

      await _loadData();
    }
  }


  void _navigateToSubPage(
    String subPage, [
    Map<String, dynamic>? params,
  ]) {
    if (subPage == 'lesson') {
      _loadLessonContent(params);
    } else if (subPage == 'game_matching') {
      final game = params?['game'] as GameModel?;
      if (game != null) _startGameContentStreams(game.id, game.type);
      _initMatchingGame();
    } else if (subPage == 'game_trivia') {
      final game = params?['game'] as GameModel?;
      if (game != null) _startGameContentStreams(game.id, game.type);
      _resetTrivia();
    } else if (subPage == 'game_conversations') {
      final game = params?['game'] as GameModel?;
      if (game != null) _startGameContentStreams(game.id, game.type);
    }

    setState(() {
      _activeSubPage = subPage;
      _subPageParams = params;
    });
  }

  /// Starts the three lesson-scoped streams for [InsightCards], [ModuleContent],
  /// and [UserResponses]. Old subscriptions are cancelled first.
  void _loadLessonContent(Map<String, dynamic>? params) {
    final moduleId = params?['moduleId'] as String? ?? '';
    final uid = _currentUser?.uid ?? '';

    _insightCardsSub?.cancel();
    _moduleContentSub?.cancel();
    _responsesSub?.cancel();

    if (moduleId.isEmpty) return;

    setState(() => _lessonContentLoading = true);

    _insightCardsSub =
        _moduleService.watchInsightCards(moduleId).listen((cards) {
      if (mounted) setState(() => _activeInsightCards = cards);
    });

    bool contentFirstEmit = true;
    _moduleContentSub =
        _moduleService.watchModuleContent(moduleId).listen((items) {
      if (mounted) {
        setState(() {
          _activeModuleContent = items;
          // The service yields [] immediately as a placeholder before Firestore
          // responds. Only clear the loading flag once real data has arrived
          // (non-empty list OR after the first placeholder emit has passed).
          if (items.isNotEmpty || !contentFirstEmit) {
            _lessonContentLoading = false;
          }
          contentFirstEmit = false;
        });
      }
    });

    if (uid.isNotEmpty) {
      _responsesSub =
          _responseService.watchModuleResponses(uid, moduleId).listen((map) {
        if (mounted) setState(() => _activeResponses = map);
      });
    }
  }

  void _goBack() {
    // Cancel lesson-scoped streams when leaving a lesson
    _insightCardsSub?.cancel();
    _moduleContentSub?.cancel();
    _responsesSub?.cancel();
    if (_lessonPageController.hasClients) {
      _lessonPageController.jumpToPage(0);
    }
    setState(() {
      _activeSubPage = null;
      _subPageParams = null;
      _activeInsightCards = [];
      _activeModuleContent = [];
      _activeResponses = {};
      _lessonContentLoading = false;
      _lessonPageIndex = 0;
      _assessmentAnswered = false;
    });
  }

  // Games states logic helper methods
  void _resetTrivia() {
    setState(() {
      _triviaIndex = 0;
      _triviaScore = 0;
      _selectedTriviaOption = null;
      _triviaAnswered = false;
    });
  }

  void _initMatchingGame() {
    List<String> pool = [];
    pool.addAll(_matchingValuePool);
    pool.addAll(_matchingValuePool);
    pool.shuffle();

    setState(() {
      _matchingCards = pool;
      _matchingFlipped = List.generate(12, (_) => false);
      _matchingMatched = List.generate(12, (_) => false);
      _firstFlippedIndex = null;
      _matchingIgnoreTaps = false;
      _matchingMoves = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBeige,
      body: _isLoadingData
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryColor,
                ),
              ),
            )
          : _activeSubPage != null
          ? _buildSubPage()
          : (_selectedIndex == 0 ? _buildHomeTab() : _buildOtherTabs()),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
              _activeSubPage = null; // reset subpage when changing tabs
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppTheme.oceanBlue,
          unselectedItemColor: Colors.grey.shade400,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 10,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_rounded),
              label: 'Modules',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.stars_rounded),
              label: 'Charter',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.sports_esports_rounded),
              label: 'Games',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.payment_rounded),
              label: 'Payment',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
    final currentWeek = _currentUser?.currentWeek ?? 1;
    final familyName = _currentFamily?.familyName ?? 'My Family';
    final progressVal =
        (_currentFamily?.overallCompletionPercentage ?? 0.0) / 100.0;

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTheme.oceanBlue.withValues(alpha: 0.1),
                    child: const Icon(
                      Icons.family_restroom_rounded,
                      color: AppTheme.oceanBlue,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, $familyName!',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      Text(
                        _currentUser?.role != null
                            ? '${_currentUser!.role!.toUpperCase()} Profile'
                            : 'Family Member Profile',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Progress Summary Dashboard Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryOmbre,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: AppTheme.modernShadow,
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Overall Completion',
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          '${(progressVal * 100).toInt()}%',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Week $currentWeek of 8',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progressVal,
                        minHeight: 8,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Active Module Card — populated from live Firestore modules.
            Builder(builder: (context) {
              // Find the module for the current week from the live stream.
              final activeModule = _modules.cast<ModuleModel?>().firstWhere(
                (m) => m!.week == currentWeek,
                orElse: () => null,
              );
              final moduleTitle = activeModule?.title ??
                  lessonData[currentWeek]?['title'] ??
                  'Week $currentWeek Module';
              final moduleDesc = activeModule?.description ??
                  lessonData[currentWeek]?['subtitle'] ??
                  'Continue your family transformation journey.';
              final moduleTags = activeModule?.tags ?? [];
              final moduleId = activeModule?.id ?? '';
              final totalWeeks = _modules.isEmpty ? 8 : _modules.length;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: const Text(
                      'Active Module',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: AppTheme.modernShadow,
                      ),
                      padding: const EdgeInsets.all(20),
                      child: _modulesLoading
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppTheme.oceanBlue
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.menu_book_rounded,
                                        color: AppTheme.oceanBlue,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Week $currentWeek of $totalWeeks',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textLight,
                                            ),
                                          ),
                                          Text(
                                            moduleTitle,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.textDark,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            moduleDesc,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textLight,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (moduleTags.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Topics Covered',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: moduleTags.take(4).map((tag) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                            color: AppTheme.primaryColor,
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          tag,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.primaryColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                                const SizedBox(height: 16),
                                Builder(builder: (context) {
                                  final isPaidHome = _currentUser?.isPaid == true;
                                  final isModuleActive = activeModule?.active ?? false;
                                  return SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        if (!isModuleActive) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('This module is not yet available.'),
                                              backgroundColor: AppTheme.oceanBlue,
                                            ),
                                          );
                                        } else if (!isPaidHome) {
                                          _showPaymentAlert(context);
                                        } else {
                                          _navigateToSubPage('lesson', {
                                            'week': currentWeek,
                                            'moduleId': moduleId,
                                            'module': activeModule,
                                          });
                                        }
                                      },
                                      icon: Icon(
                                        !isModuleActive
                                            ? Icons.lock_clock_rounded
                                            : isPaidHome
                                                ? Icons.play_arrow_rounded
                                                : Icons.lock_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      label: Text(
                                        !isModuleActive
                                            ? 'Module Coming Soon'
                                            : isPaidHome
                                                ? 'Continue Week $currentWeek →'
                                                : 'Please Pay to Access',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: (!isModuleActive || !isPaidHome)
                                            ? Colors.grey.shade400
                                            : AppTheme.primaryColor,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                    ),
                  ),
                ],
              );
            }),
            const SizedBox(height: 20),

            // Program Roadmap — populated from live Firestore modules.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white,
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _modules.isEmpty
                          ? '8-Week Program Roadmap'
                          : '${_modules.length}-Week Program Roadmap',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const Text(
                      'Your family transformation journey',
                      style: TextStyle(fontSize: 12, color: AppTheme.textLight),
                    ),
                    const SizedBox(height: 12),
                    if (_modulesLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      )
                    else if (_modules.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'No modules available yet. Check back soon!',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _modules.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 4),
                        itemBuilder: (context, index) {
                          final m = _modules[index];
                          final isCompleted = m.week < currentWeek;
                          final isCurrentWeek = m.week == currentWeek;
                          final isPaid = _currentUser?.isPaid == true;
                          final isModuleActive = m.active;
                          
                          Color dotColor = Colors.grey.shade300;
                          if (isCompleted) dotColor = AppTheme.successGreen;
                          if (isCurrentWeek) dotColor = AppTheme.primaryColor;
                          // When not paid or not active, use grey for all dots
                          if (!isPaid || !isModuleActive) dotColor = Colors.grey.shade300;

                          return GestureDetector(
                            onTap: () {
                              if (!isModuleActive) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('This module is not yet available.'),
                                    backgroundColor: AppTheme.oceanBlue,
                                  ),
                                );
                              } else if (!isPaid) {
                                _showPaymentAlert(context);
                              } else if (m.week > currentWeek) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Complete your current week first to unlock this lesson.'),
                                    backgroundColor: AppTheme.oceanBlue,
                                  ),
                                );
                              } else {
                                _navigateToSubPage('lesson', {
                                  'moduleId': m.id,
                                  'week': m.week,
                                  'module': m,
                                });
                              }
                            },
                            child: Container(
                              color: Colors.transparent, // Ensures tap targets the whole row
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isCompleted
                                          ? AppTheme.successGreen
                                          : Colors.transparent,
                                      border: Border.all(
                                        color: dotColor,
                                        width: 2,
                                      ),
                                    ),
                                    child: isCompleted
                                        ? const Icon(
                                            Icons.check,
                                            size: 13,
                                            color: Colors.white,
                                          )
                                        : isCurrentWeek && isModuleActive
                                            ? Container(
                                                decoration: const BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: AppTheme.primaryColor,
                                                ),
                                                margin: const EdgeInsets.all(4),
                                              )
                                            : (!isPaid || !isModuleActive
                                                ? const Icon(
                                                    Icons.lock_rounded,
                                                    size: 14,
                                                    color: Colors.grey,
                                                  )
                                                : null),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Week ${m.week}: ${m.title}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: isPaid && isModuleActive && (isCurrentWeek || isCompleted)
                                                ? AppTheme.textDark
                                                : Colors.grey.shade400,
                                            fontWeight: isCurrentWeek && isModuleActive && isPaid
                                                ? FontWeight.w600
                                                : FontWeight.w500,
                                          ),
                                        ),
                                        if (m.description.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 2),
                                            child: Text(
                                              m.description,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade500,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (isCompleted)
                                    const Text(
                                      'Done',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.successGreen,
                                      ),
                                    )
                                  else if (isCurrentWeek && isModuleActive)
                                    const Text(
                                      'Current',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryColor,
                                      ),
                                    )
                                  else if (!isPaid || !isModuleActive)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: Colors.grey.shade300),
                                      ),
                                      child: const Text(
                                        'Locked',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildOtherTabs() {
    switch (_selectedIndex) {
      case 1:
        return _buildModulesTab();
      case 2:
        return _buildCharterTab();
      case 3:
        return _buildGamesTab();
      case 4:
        return _buildPaymentTab();
      case 5:
        return _buildProfileTab();
      default:
        return const Center(child: Text('Page not found'));
    }
  }

  Widget _buildModulesTab() {
    final currentWeek = _currentUser?.currentWeek ?? 1;
    final totalCompleted = (_currentUser?.currentWeek ?? 1) - 1;
    final progressVal = totalCompleted / 8.0;
    final isPaid = _currentUser?.isPaid == true;

    // Use live Firestore modules when available; show loading indicator while
    // streaming. If Firestore has no data yet the list is empty.
    final displayModules = _modules;
    final moduleCount = displayModules.isEmpty ? 8 : displayModules.length;

    return Scaffold(
      backgroundColor: AppTheme.lightBeige,
      appBar: AppBar(
        title: const Text('Workbook Modules'),
        backgroundColor: AppTheme.oceanBlue,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress Banner
              Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.secondaryOmbre,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppTheme.modernShadow,
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$moduleCount-Week Program',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          isPaid
                              ? '$totalCompleted/$moduleCount Completed'
                              : 'Content Locked',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your family transformation journey',
                      style: TextStyle(fontSize: 13, color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                      value: isPaid ? progressVal : 0.0,
                        minHeight: 8,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              // Non-premium upgrade banner
              if (!isPaid) ...[
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => setState(() => _selectedIndex = 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.workspace_premium_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Upgrade to Premium to access all lessons',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: Colors.white70,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              const Text(
                'Weekly Lessons',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 12),
              if (_modulesLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryColor,
                      ),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayModules.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final module = displayModules[index];
                    final isModuleActive = module.active;
                    // For premium users, weeks unlock progressively.
                    // For free users, every week is visible but paywall-gated.
                    final isWeekReached = module.week <= currentWeek;
                    final isCurrentWeek = module.week == currentWeek;
                    // A lesson is fully accessible only when paid AND
                    // the user has reached that week in the programme AND it is active.
                    final isAccessible = isPaid && isWeekReached && isModuleActive;

                    return GestureDetector(
                      onTap: () {
                        if (!isModuleActive) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'This module is not yet available.'),
                              backgroundColor: AppTheme.oceanBlue,
                            ),
                          );
                        } else if (!isPaid) {
                          // Show payment alert dialog
                          _showPaymentAlert(context);
                        } else if (!isWeekReached) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Complete your current week first to unlock this lesson.'),
                              backgroundColor: AppTheme.oceanBlue,
                            ),
                          );
                        } else {
                          _navigateToSubPage('lesson', {
                            'moduleId': module.id,
                            'week': module.week,
                            'module': module,
                          });
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isModuleActive ? Colors.white : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isCurrentWeek && isPaid && isModuleActive
                                ? AppTheme.oceanBlue
                                : Colors.grey.shade200,
                            width: isCurrentWeek && isPaid && isModuleActive ? 2 : 1,
                          ),
                          boxShadow: isModuleActive ? AppTheme.modernShadow : null,
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // ── Leading icon ───────────────────────────────
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: isAccessible
                                    ? (isCurrentWeek
                                          ? AppTheme.oceanBlue
                                                .withValues(alpha: 0.1)
                                          : AppTheme.lightBeige)
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isAccessible
                                    ? Icons.menu_book_rounded
                                    : Icons.lock_outline_rounded,
                                color: isAccessible
                                    ? (isCurrentWeek
                                          ? AppTheme.oceanBlue
                                          : AppTheme.textLight)
                                    : Colors.grey.shade400,
                              ),
                            ),
                            const SizedBox(width: 16),

                            // ── Text content ───────────────────────────────
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Week ${module.week}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isModuleActive ? AppTheme.textLight : Colors.grey.shade400,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    module.title,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isModuleActive ? AppTheme.textDark : Colors.grey.shade500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    // Always show the real description so
                                    // users know what they're buying into.
                                    module.description,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isModuleActive ? AppTheme.textLight
                                          .withValues(alpha: 0.85) : Colors.grey.shade400,
                                    ),
                                  ),
                                  if (module.tags.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 6,
                                      children: module.tags
                                          .take(3)
                                          .map(
                                            (tag) => Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: isModuleActive ? AppTheme.oceanBlue
                                                    .withValues(alpha: 0.08) : Colors.grey.shade200,
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                tag,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: isModuleActive ? AppTheme.oceanBlue : Colors.grey.shade500,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (!isModuleActive)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: const Text(
                                  'Soon',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                              )
                            else if (!isPaid)
                              // Payment required badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.lock_rounded,
                                      size: 11,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(width: 3),
                                    Text(
                                      'Locked',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Icon(
                                    isWeekReached
                                        ? Icons.arrow_forward_ios_rounded
                                        : Icons.lock_outline_rounded,
                                    size: 16,
                                    color: AppTheme.textLight,
                                  ),
                                  if (module.totalModuleXp > 0)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        '${module.totalModuleXp} XP',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.amber.shade700,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// Shows an alert dialog when an unpaid user taps locked content.
  void _showPaymentAlert(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_rounded,
                color: AppTheme.primaryColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Payment Required',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
          ],
        ),
        content: const Padding(
          padding: EdgeInsets.only(top: 8, bottom: 20),
          child: Text(
            'Please complete payment to access this content. Unlock all 8 weekly lessons, worksheets, and your family charter.',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textLight,
              height: 1.5,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _selectedIndex = 4); // Go to Payment tab
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text(
              'Pay Now',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharterTab() {
    final readinessVal = (_currentFamily?.charterReadinessScore ?? 0.0) / 100.0;
    final charterTitle =
        _familyCharter?.title ?? 'Family Charter';
    final charterPreamble =
        _familyCharter?.preamble ?? 'Your comprehensive family framework document';

    // Show live Firestore clauses when available, otherwise empty.
    final displayClauses = _charterClauses;
    final currentWeek = _currentUser?.currentWeek ?? 1;

    return Scaffold(
      backgroundColor: AppTheme.lightBeige,
      appBar: AppBar(
        title: const Text('Family Charter'),
        backgroundColor: AppTheme.oceanBlue,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Wavy Ombre Charter Card
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: AppTheme.wavesOmbre,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppTheme.modernShadow,
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(
                      Icons.stars_rounded,
                      color: Colors.white,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      charterTitle,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      charterPreamble,
                      style: const TextStyle(
                          fontSize: 13, color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Progress Section Card
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFDDD6FE)),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Charter In Progress',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5B21B6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Complete all 8 weeks to generate your full Family Charter PDF',
                      style: TextStyle(fontSize: 12, color: Color(0xFF7C3AED)),
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: readinessVal,
                        minHeight: 8,
                        backgroundColor: const Color(0xFFEDE9FE),
                        valueColor: const AlwaysStoppedAnimation(
                          Color(0xFF7C3AED),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${(readinessVal * 8).toInt()}/8 Sections Unlocked',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF7C3AED),
                          ),
                        ),
                        Text(
                          '${(readinessVal * 100).toInt()}% Ready',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF7C3AED),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Text(
                    'Charter Clauses',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  if (displayClauses.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE9FE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${displayClauses.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7C3AED),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              if (_charterLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF7C3AED),
                      ),
                    ),
                  ),
                )
              else if (displayClauses.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.article_outlined,
                          size: 48,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No clauses yet.\nComplete weekly modules to build your charter.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayClauses.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final clause = displayClauses[index];
                    final isUnlocked = clause.weekReference < currentWeek;

                    return Container(
                      decoration: BoxDecoration(
                        color:
                            isUnlocked ? Colors.white : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey.shade200,
                        ),
                        boxShadow:
                            isUnlocked ? AppTheme.modernShadow : null,
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isUnlocked
                                  ? const Color(0xFFEDE9FE)
                                  : Colors.grey.shade200,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isUnlocked
                                  ? Icons.verified_user_rounded
                                  : Icons.lock_outline,
                              color: isUnlocked
                                  ? const Color(0xFF7C3AED)
                                  : Colors.grey.shade400,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isUnlocked
                                            ? const Color(0xFFEDE9FE)
                                            : Colors.grey.shade200,
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        clause.category,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: isUnlocked
                                              ? const Color(0xFF7C3AED)
                                              : Colors.grey.shade500,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Week ${clause.weekReference}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  isUnlocked
                                      ? clause.statement
                                      : 'Unlock by completing Week ${clause.weekReference}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isUnlocked
                                        ? AppTheme.textDark
                                        : Colors.grey.shade500,
                                    fontStyle: isUnlocked
                                        ? FontStyle.normal
                                        : FontStyle.italic,
                                  ),
                                ),
                                if (isUnlocked &&
                                    clause.rationale.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    clause.rationale,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textLight,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              // Closing commitment (shown only when charter exists and has clauses)
              if (_familyCharter != null &&
                  _familyCharter!.closingCommitment.isNotEmpty &&
                  displayClauses.isNotEmpty) ...[
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFDDD6FE)),
                  ),
                  child: Text(
                    _familyCharter!.closingCommitment,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF5B21B6),
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGamesTab() {
    return Scaffold(
      backgroundColor: AppTheme.lightBeige,
      appBar: AppBar(
        title: const Text('Interactive Games'),
        backgroundColor: AppTheme.oceanBlue,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Premium game badge
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: AppTheme.secondaryOmbre,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppTheme.modernShadow,
                ),
                padding: const EdgeInsets.all(20),
                child: const Row(
                  children: [
                    Icon(
                      Icons.sports_esports_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Family Play Time',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Strengthen connections and values together.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Select a Game',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 12),

              // ── Dynamic game list from Firestore ─────────────────────────
              // Add a new document to the `games` Firestore collection to
              // show a new game card here — no code change needed.
              if (_gamesLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryColor,
                      ),
                    ),
                  ),
                )
              else if (_gameCatalogue.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.sports_esports_outlined,
                          size: 48,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No games available right now.\nCheck back soon!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...List.generate(_gameCatalogue.length, (index) {
                  final game = _gameCatalogue[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index < _gameCatalogue.length - 1 ? 12 : 0,
                    ),
                    child: _buildGameMenuCard(
                      title: game.title,
                      desc: game.description,
                      icon: iconFromString(game.iconName),
                      color: game.color,
                      xpReward: game.xpReward,
                      onTap: () => _navigateToSubPage(
                        'game_${game.type}',
                        {'game': game},
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildGameMenuCard({
    required String title,
    required String desc,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    int xpReward = 0,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: AppTheme.modernShadow,
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textLight,
                    ),
                  ),
                  if (xpReward > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: 12,
                            color: Colors.amber.shade600,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '$xpReward XP',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.play_arrow_rounded, color: AppTheme.textLight),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentTab() {
    final isPaid = _currentUser?.isPaid == true;

    return Scaffold(
      backgroundColor: AppTheme.lightBeige,
      appBar: AppBar(
        title: const Text('Upgrade Subscription'),
        backgroundColor: AppTheme.oceanBlue,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Start Your Journey',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Join thousands of families growing with intention.',
                style: TextStyle(fontSize: 14, color: AppTheme.textLight),
                textAlign: TextAlign.center,
              ),
              const Text(
                'Start free. Cancel anytime.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textLight,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Annual vs Monthly Custom Toggle Switch
              Container(
                width: 240,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isAnnualSelected = false;
                          });
                        },
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: !_isAnnualSelected
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: !_isAnnualSelected
                                ? AppTheme.modernShadow
                                : null,
                          ),
                          child: Text(
                            'Monthly',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: !_isAnnualSelected
                                  ? AppTheme.textDark
                                  : AppTheme.textLight,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isAnnualSelected = true;
                          });
                        },
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _isAnnualSelected
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: _isAnnualSelected
                                ? AppTheme.modernShadow
                                : null,
                          ),
                          child: Text(
                            'Annual — Save 40%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _isAnnualSelected
                                  ? AppTheme.textDark
                                  : AppTheme.textLight,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Pricing Choices
              Row(
                children: [
                  // Annual pricing option
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isAnnualSelected = true;
                        });
                      },
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _isAnnualSelected
                                    ? const Color(0xFF7C3AED)
                                    : Colors.grey.shade200,
                                width: _isAnnualSelected ? 2.5 : 1,
                              ),
                              boxShadow: _isAnnualSelected
                                  ? AppTheme.modernShadow
                                  : null,
                            ),
                            child: const Column(
                              children: [
                                SizedBox(height: 8),
                                Text(
                                  'ANNUAL',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '\$49.99',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  '\$0.96 / week',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            top: -10,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7C3AED),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Most Popular',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Monthly pricing option
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isAnnualSelected = false;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: !_isAnnualSelected
                                ? const Color(0xFF3B67B5)
                                : Colors.grey.shade200,
                            width: !_isAnnualSelected ? 2.5 : 1,
                          ),
                          boxShadow: !_isAnnualSelected
                              ? AppTheme.modernShadow
                              : null,
                        ),
                        child: const Column(
                          children: [
                            SizedBox(height: 8),
                            Text(
                              'MONTHLY',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '\$7.99',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textDark,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'per month',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              if (isPaid) ...[
                // Premium unlocked view
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.successGreen.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: AppTheme.successGreen,
                        size: 48,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Your Premium Subscription is Active!',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'All features, matching games, modules, and PDF downloads are fully unlocked.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textLight,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Apple Pay Black Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () => _simulateMockCheckout('Apple Pay'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(
                      Icons.apple,
                      color: Colors.white,
                      size: 24,
                    ),
                    label: const Text(
                      'Pay with Apple Pay',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                const Text(
                  '— or —',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 16),

                // Premium Live Credit Card Preview mockup!
                Container(
                  width: double.infinity,
                  height: 190,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _isAnnualSelected
                          ? [
                              AppTheme.oceanBlue,
                              AppTheme.skyBlue,
                              AppTheme.softLavender,
                              AppTheme.lilacPink,
                            ]
                          : [
                              AppTheme.deepNavy,
                              AppTheme.oceanBlue,
                              AppTheme.skyBlue,
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppTheme.modernShadow,
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Icon(
                            Icons.credit_card_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                          Text(
                            _isAnnualSelected ? 'ANNUAL PASS' : 'MONTHLY PASS',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white70,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        _cardNumText,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'CARD HOLDER',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.white60,
                                ),
                              ),
                              Text(
                                _currentUser?.username.toUpperCase() ??
                                    'FAMILY MEMBER',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'EXPIRES',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: Colors.white60,
                                    ),
                                  ),
                                  Text(
                                    _cardExpiryText,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'CVV',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: Colors.white60,
                                    ),
                                  ),
                                  Text(
                                    _cardCvvText,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Visa Checkout Input fields
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: AppTheme.modernShadow,
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Card Number field
                      TextField(
                        controller: _cardNumberController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Card number',
                          prefixIcon: const Icon(
                            Icons.credit_card,
                            color: Colors.grey,
                          ),
                          suffixIcon: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12.0,
                              vertical: 8.0,
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'VISA',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          // Expiry
                          Expanded(
                            child: TextField(
                              controller: _expiryController,
                              keyboardType: TextInputType.datetime,
                              decoration: InputDecoration(
                                hintText: 'MM / YY',
                                prefixIcon: const Icon(
                                  Icons.calendar_today,
                                  color: Colors.grey,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // CVV
                          Expanded(
                            child: TextField(
                              controller: _cvvController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'CVV',
                                prefixIcon: const Icon(
                                  Icons.lock,
                                  color: Colors.grey,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Start Trial/Pay Button (gradient themed)
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppTheme.wavesOmbre,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: AppTheme.modernShadow,
                    ),
                    child: ElevatedButton(
                      onPressed: () => _simulateMockCheckout('Visa Card'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        _isAnnualSelected
                            ? 'Start 7-Day Free Trial'
                            : 'Pay & Upgrade Now',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                // Footer text
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.security, size: 14, color: Colors.grey),
                    SizedBox(width: 6),
                    Text(
                      'Secure',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    SizedBox(width: 16),
                    Icon(Icons.loop, size: 14, color: Colors.grey),
                    SizedBox(width: 6),
                    Text(
                      'Cancel anytime',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    SizedBox(width: 16),
                    Icon(Icons.timer, size: 14, color: Colors.grey),
                    SizedBox(width: 6),
                    Text(
                      '7-day trial',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _isAnnualSelected
                      ? '\$49.99/year after trial. Cancel anytime in Settings'
                      : '\$7.99/month subscription fee. Cancel anytime.',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _simulateMockCheckout(String provider) async {
    // If credit card inputs are visible, validate that they entered details
    if (provider == 'Visa Card') {
      if (_cardNumberController.text.length < 8 ||
          _expiryController.text.isEmpty ||
          _cvvController.text.length < 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter valid credit card details.'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
        return;
      }
    }

    setState(() {
      _isLoadingData = true;
    });

    try {
      await _authService.updatePaymentStatus(true);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Subscription Activated via $provider! Welcome to Premium.',
            ),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failure: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
      }
    }
  }

  Widget _buildProfileTab() {
    final isPaid = _currentUser?.isPaid == true;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.oceanBlue, width: 3),
                boxShadow: AppTheme.modernShadow,
                color: AppTheme.lightBeige,
              ),
              child: ClipOval(
                child: _currentUser?.profilePictureUrl != null &&
                        _currentUser!.profilePictureUrl!.isNotEmpty
                    ? (_currentUser!.profilePictureUrl!.startsWith('waves_avatar_')
                        ? Container(
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: const AssetImage('assets/images/waves_bg.png'),
                                fit: BoxFit.cover,
                                alignment: _currentUser!.profilePictureUrl == 'waves_avatar_0'
                                    ? Alignment.topLeft
                                    : _currentUser!.profilePictureUrl == 'waves_avatar_1'
                                        ? Alignment.topRight
                                        : _currentUser!.profilePictureUrl == 'waves_avatar_2'
                                            ? Alignment.bottomLeft
                                            : Alignment.bottomRight,
                              ),
                            ),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _currentUser!.profilePictureUrl == 'waves_avatar_0'
                                      ? Icons.face_rounded
                                      : _currentUser!.profilePictureUrl == 'waves_avatar_1'
                                          ? Icons.face_3_rounded
                                          : _currentUser!.profilePictureUrl == 'waves_avatar_2'
                                              ? Icons.face_6_rounded
                                              : Icons.family_restroom_rounded,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            ),
                          )
                        : Image.network(
                            _currentUser!.profilePictureUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 50, color: AppTheme.deepNavy),
                          ))
                    : const Icon(Icons.person, size: 50, color: AppTheme.deepNavy),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _currentUser?.username ?? 'Family Member',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _currentUser?.email ?? '',
              style: const TextStyle(fontSize: 14, color: AppTheme.textLight),
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    icon: Icons.star_rounded,
                    title: 'Total XP',
                    value: '${_currentUser?.gamePoints ?? 0}',
                    color: Colors.amber.shade600,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    icon: Icons.track_changes_rounded,
                    title: 'Progress',
                    value: '${_currentUser?.completionPercentage ?? 0}%',
                    color: AppTheme.oceanBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    icon: Icons.workspace_premium_rounded,
                    title: 'Status',
                    value: isPaid ? 'Premium' : 'Trial',
                    color: isPaid ? AppTheme.successGreen : Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Family Members',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_familyMembers.isEmpty)
              const Center(child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ))
            else
              SizedBox(
                height: 110,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _familyMembers.length,
                  itemBuilder: (context, index) {
                    final member = _familyMembers[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 20.0),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: AppTheme.oceanBlue.withValues(alpha: 0.1),
                            child: Text(
                              member.name.isNotEmpty ? member.name.substring(0, 1).toUpperCase() : '?',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.oceanBlue,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            member.name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textDark,
                            ),
                          ),
                          Text(
                            member.role.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textLight,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            if (!isPaid) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedIndex = 4; // Redirect to Payment Tab
                    });
                  },
                  icon: const Icon(Icons.payment, color: Colors.white),
                  label: const Text(
                    'Upgrade to Premium (Pay)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await _authService.signOut();
                  if (mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const WelcomeScreen(),
                      ),
                      (route) => false,
                    );
                  }
                },
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text(
                  'Sign Out',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorRed,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }


  // SUBPAGES RENDER (WITH BACK BUTTON)
  Widget _buildSubPage() {
    Widget child;
    String title = '';
    PreferredSizeWidget? appBarBottom;

    switch (_activeSubPage) {
      case 'lesson':
        final int week = _subPageParams?['week'] ?? 1;
        final ModuleModel? module = _subPageParams?['module'] as ModuleModel?;
        title = module != null ? module.title : 'Week $week Lesson';
        child = _buildLessonView(week, module: module);
        // Step indicator shown only for lesson
        appBarBottom = PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: PageIndicator(3, _lessonPageIndex),
          ),
        );
        break;
      case 'game_trivia':
        final GameModel? tGame = _subPageParams?['game'] as GameModel?;
        title = tGame?.title ?? 'Family Wisdom Quiz';
        child = _buildTriviaGameView();
        break;
      case 'game_conversations':
        final GameModel? cGame = _subPageParams?['game'] as GameModel?;
        title = cGame?.title ?? 'Conversation Starters';
        child = _buildConversationsGameView();
        break;
      case 'game_matching':
        final GameModel? mGame = _subPageParams?['game'] as GameModel?;
        title = mGame?.title ?? 'Values Matching Game';
        child = _buildMatchingGameView();
        break;
      default:
        title = 'Detail';
        child = const Center(child: Text('Unknown subpage'));
    }

    return Scaffold(
      backgroundColor: AppTheme.lightBeige,
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppTheme.oceanBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: _goBack,
        ),
        elevation: 0,
        bottom: appBarBottom,
      ),
      body: child,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // LESSON DETAIL VIEW — 3-step PageView
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildLessonView(int week, {ModuleModel? module}) {
    final reflections = _activeModuleContent.where((i) => i.type == 'reflection').toList();
    final assessments = _activeModuleContent.where((i) => i.type == 'assessment').toList();
    final activities  = _activeModuleContent.where((i) => i.type == 'activity').toList();

    if (_lessonContentLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
        ),
      );
    }

    return PageView(
      controller: _lessonPageController,
      physics: const ClampingScrollPhysics(),
      children: [
        _buildInsightsPage(week, module, reflections),
        _buildAssessmentPage(assessments),
        _buildActivitiesPage(activities, week),
      ],
    );
  }

  // ─── PAGE 1: Insights & Reflections ──────────────────────────────────────
  Widget _buildInsightsPage(
    int week,
    ModuleModel? module,
    List<ModuleContentModel> reflections,
  ) {
    final uid      = _currentUser?.uid ?? '';
    final familyId = _currentUser?.familyId;
    final subtitle = module?.description ??
        lessonData[week]?['subtitle'] ??
        'Workbook guidelines and reflection details.';
    final totalXp  = _activeModuleContent.fold<int>(0, (acc, i) => acc + i.xpReward);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── XP Banner ───────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.deepNavy, AppTheme.oceanBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.modernShadow,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 22),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Max Week XP',
                        style: TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w500)),
                    Text('$totalXp Points',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Week $week of 8',
                      style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Module Description ───────────────────────────────────────────────
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 15,
              fontStyle: FontStyle.italic,
              height: 1.6,
              color: AppTheme.textDark,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 24),

          // ── Insight Cards ────────────────────────────────────────────────────
          if (_activeInsightCards.isNotEmpty) ...[
            const Text('This Week\'s Insights',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            const SizedBox(height: 12),
            if (_activeInsightCards.length >= 2)
              Row(children: [
                Expanded(child: _buildInsightCard(_activeInsightCards[0])),
                const SizedBox(width: 12),
                Expanded(child: _buildInsightCard(_activeInsightCards[1])),
              ])
            else
              _buildInsightCard(_activeInsightCards[0]),
            const SizedBox(height: 24),
          ],

          // ── Reflection Prompts ───────────────────────────────────────────────
          if (reflections.isNotEmpty) ...[
            const Text('Reflections',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            const SizedBox(height: 12),
            ...reflections.map((item) {
              final existing = _activeResponses[item.id];
              final ctrl     = TextEditingController(text: existing?.textResponse ?? '');
              final isDone   = existing?.isCompleted ?? false;
              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDone ? AppTheme.oceanBlue.withValues(alpha: 0.3) : Colors.grey.shade200),
                    boxShadow: AppTheme.modernShadow,
                  ),
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(item.question,
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w600,
                                    color: AppTheme.textDark, height: 1.4)),
                          ),
                          const SizedBox(width: 8),
                          XpBadge('${item.xpReward} XP • Reflective Focus',
                              const Color(0xFFDCEAFF), AppTheme.oceanBlue),
                        ],
                      ),
                      if (item.description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(item.description,
                            style: const TextStyle(fontSize: 12, color: AppTheme.textLight, height: 1.4)),
                      ],
                      const SizedBox(height: 12),
                      TextField(
                        controller: ctrl,
                        maxLines: 3,
                        style: const TextStyle(fontSize: 14, height: 1.5),
                        decoration: InputDecoration(
                          hintText: 'Write your reflection here...',
                          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                          filled: true,
                          fillColor: const Color(0xFFF7FAFF),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.oceanBlue, width: 1.5)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          if (isDone) ...[
                            const Icon(Icons.check_circle_rounded,
                                color: AppTheme.successGreen, size: 16),
                            const SizedBox(width: 4),
                            Text('+${item.xpReward} XP earned',
                                style: const TextStyle(fontSize: 12, color: AppTheme.successGreen,
                                    fontWeight: FontWeight.w600)),
                          ],
                          const Spacer(),
                          SizedBox(
                            height: 38,
                            child: ElevatedButton(
                              onPressed: uid.isEmpty ? null : () async {
                                final text = ctrl.text.trim();
                                if (text.isEmpty) return;
                                final isFirst = !isDone;
                                final resp = UserResponseModel(
                                  contentId: item.id,
                                  moduleId: _subPageParams?['moduleId'] as String? ?? '',
                                  type: item.type,
                                  textResponse: text,
                                  xpEarned: isFirst ? item.xpReward : (existing?.xpEarned ?? 0),
                                );
                                await _responseService.saveResponse(uid: uid, response: resp);
                                if (isFirst) {
                                  await _responseService.recordXp(uid: uid, familyId: familyId, xp: item.xpReward);
                                }
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text(isFirst
                                        ? 'Saved! +${item.xpReward} XP earned 🌟'
                                        : 'Response updated.'),
                                    backgroundColor: AppTheme.successGreen,
                                  ));
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.oceanBlue,
                                padding: const EdgeInsets.symmetric(horizontal: 18),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: Text(isDone ? 'Update' : 'Save',
                                  style: const TextStyle(color: Colors.white, fontSize: 13)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],

          // ── Empty state ────────────────────────────────────────────────────
          if (_activeInsightCards.isEmpty && reflections.isEmpty)
            EmptyContentState(),

          const SizedBox(height: 16),

          // ── Next Page CTA ────────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => _lessonPageController.nextPage(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOut,
              ),
              icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
              label: const Text('Next: Assessment',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.oceanBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ─── Insight Card Widget ────────────────────────────────────────────────────
  Widget _buildInsightCard(InsightCardModel card) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.deepNavy, AppTheme.oceanBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.modernShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(card.title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
              maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Text(card.body,
              style: const TextStyle(fontSize: 11, color: Colors.white70, height: 1.4),
              maxLines: 5, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  // ─── PAGE 2: Assessment ────────────────────────────────────────────────────
  Widget _buildAssessmentPage(List<ModuleContentModel> assessments) {
    final uid      = _currentUser?.uid ?? '';
    final familyId = _currentUser?.familyId;

    if (assessments.isEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          EmptyContentState(),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton.icon(
              onPressed: () => _lessonPageController.nextPage(
                  duration: const Duration(milliseconds: 350), curve: Curves.easeInOut),
              icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
              label: const Text('Next: Activities',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.oceanBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            ),
          ),
        ]),
      );
    }

    Map<String, String> selectedOptions = {};
    bool allAlreadyDone = true;
    for (var item in assessments) {
      final existing = _activeResponses[item.id];
      if (existing?.selectedOptionId != null) {
        selectedOptions[item.id] = existing!.selectedOptionId!;
      } else {
        allAlreadyDone = false;
      }
    }

    bool submitted = allAlreadyDone || _assessmentAnswered;

    return StatefulBuilder(
      builder: (context, localSetState) {
        String feedbackMsg = '';
        if (submitted) {
          int correctCount = 0;
          for (var item in assessments) {
            final sel = selectedOptions[item.id];
            final existing = _activeResponses[item.id];
            if (existing != null && existing.isCorrect == true) {
               correctCount++;
            } else if (sel != null) {
               final chosenOpt = item.options.firstWhere((o) => o.optionId == sel, orElse: () => item.options.first);
               if (chosenOpt.isCorrect) correctCount++;
            }
          }
          if (correctCount == assessments.length) {
            feedbackMsg = 'Excellent! You got everything right! 🌟';
          } else {
            feedbackMsg = 'Good effort! Review the insights and try again next time. 💪';
          }
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('Comprehension Check',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                  ),
                  XpBadge('${assessments.fold<int>(0, (total, i) => total + i.xpReward)} XP',
                      const Color(0xFFF3E8FF), const Color(0xFF7B3FA8)),
                ],
              ),
              const SizedBox(height: 20),

              ...assessments.map((item) {
                final selectedId = selectedOptions[item.id];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: AppTheme.modernShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.question,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                                  color: AppTheme.textDark, height: 1.5)),
                          const SizedBox(height: 20),
                          ...item.options.map((opt) {
                            final isSelected = selectedId == opt.optionId;
                            Color bg     = Colors.white;
                            Color border = Colors.grey.shade300;
                            Color text   = AppTheme.textDark;

                            if (submitted) {
                              if (opt.isCorrect) {
                                bg = const Color(0xFFE8F5E9);
                                border = const Color(0xFF66BB6A);
                                text = const Color(0xFF1B5E20);
                              } else if (isSelected && !opt.isCorrect) {
                                bg = const Color(0xFFFFEBEE);
                                border = const Color(0xFFEF5350);
                                text = const Color(0xFFB71C1C);
                              }
                            } else if (isSelected) {
                              bg = const Color(0xFFDCEAFF);
                              border = AppTheme.oceanBlue;
                              text = AppTheme.deepNavy;
                            }

                            return GestureDetector(
                              onTap: submitted ? null : () => localSetState(() => selectedOptions[item.id] = opt.optionId),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOut,
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                                decoration: BoxDecoration(
                                  color: bg,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: border, width: 1.5),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(child: Text(opt.optionText,
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: text))),
                                    if (submitted && opt.isCorrect)
                                      const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 18)
                                    else if (submitted && isSelected && !opt.isCorrect)
                                      const Icon(Icons.cancel_rounded, color: Color(0xFFC62828), size: 18),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              }),

              if (!submitted)
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    onPressed: (uid.isEmpty || selectedOptions.length < assessments.length) ? null : () async {
                      List<UserResponseModel> responsesToSave = [];
                      List<bool> isFirstList = [];
                      
                      for (var item in assessments) {
                        final existing = _activeResponses[item.id];
                        final isFirst = existing?.selectedOptionId == null;
                        final selId = selectedOptions[item.id]!;
                        final chosenOpt = item.options.firstWhere((o) => o.optionId == selId);
                        
                        final resp = UserResponseModel(
                          contentId: item.id,
                          moduleId: _subPageParams?['moduleId'] as String? ?? '',
                          type: item.type,
                          selectedOptionId: selId,
                          isCorrect: chosenOpt.isCorrect,
                          xpEarned: isFirst ? item.xpReward : (existing?.xpEarned ?? 0),
                        );
                        
                        responsesToSave.add(resp);
                        isFirstList.add(isFirst);
                      }
                      
                      await _responseService.saveResponsesBatch(
                        uid: uid,
                        responses: responsesToSave,
                        isFirstSubmissions: isFirstList,
                        familyId: familyId,
                      );
                      
                      setState(() => _assessmentAnswered = true);
                      localSetState(() => submitted = true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7B3FA8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    child: const Text('Submit Answers',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),

              if (submitted && feedbackMsg.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFCE93D8)),
                  ),
                  child: Text(feedbackMsg,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                          color: Color(0xFF6A0080))),
                ),
                const SizedBox(height: 20),
              ],

              if (submitted)
                AnimatedOpacity(
                  opacity: 1.0,
                  duration: const Duration(milliseconds: 500),
                  child: SizedBox(
                    width: double.infinity, height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () => _lessonPageController.nextPage(
                          duration: const Duration(milliseconds: 350), curve: Curves.easeInOut),
                      icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                      label: const Text('Next: Activities',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.oceanBlue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    ),
                  ),
                ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  // ─── PAGE 3: Activities ────────────────────────────────────────────────────
  Widget _buildActivitiesPage(List<ModuleContentModel> activities, int week) {
    final uid        = _currentUser?.uid ?? '';
    final familyId   = _currentUser?.familyId;
    final controllers = {
      for (final a in activities)
        a.id: TextEditingController(text: _activeResponses[a.id]?.textResponse ?? '')
    };

    if (activities.isEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          EmptyContentState(),
          const SizedBox(height: 24),
          _buildCompleteWeekButton(week, [], {}, uid, familyId),
        ]),
      );
    }

    return StatefulBuilder(
      builder: (context, localSetState) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Charter Building',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
              const SizedBox(height: 4),
              const Text('Complete each activity to build your family charter.',
                  style: TextStyle(fontSize: 13, color: AppTheme.textLight, height: 1.4)),
              const SizedBox(height: 24),

              ...activities.map((item) {
                final existing = _activeResponses[item.id];
                final isDone   = existing?.isCompleted ?? false;
                final ctrl     = controllers[item.id]!;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: isDone ? const Color(0xFF66BB6A) : Colors.grey.shade200,
                          width: isDone ? 1.5 : 1.0),
                      boxShadow: AppTheme.modernShadow,
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          XpBadge('${item.xpReward} XP • Charter Milestone',
                              const Color(0xFFFFF8E1), const Color(0xFFE65100)),
                          const Spacer(),
                          if (isDone)
                            Row(children: [
                              const Icon(Icons.check_circle_rounded,
                                  color: Color(0xFF2E7D32), size: 16),
                              const SizedBox(width: 4),
                              Text('+${item.xpReward} XP',
                                  style: const TextStyle(fontSize: 12,
                                      fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                            ]),
                        ]),
                        const SizedBox(height: 14),
                        Text(item.question,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                                color: AppTheme.textDark, height: 1.5)),
                        if (item.description.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(item.description,
                              style: const TextStyle(fontSize: 13, color: AppTheme.textLight, height: 1.5)),
                        ],
                        const SizedBox(height: 16),
                        TextField(
                          controller: ctrl,
                          maxLines: 4,
                          enabled: !isDone,
                          style: const TextStyle(fontSize: 14, height: 1.6),
                          decoration: InputDecoration(
                            hintText: 'As a family, we commit to...',
                            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                            filled: true,
                            fillColor: isDone ? const Color(0xFFF1F8E9) : const Color(0xFFFFFBF2),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: isDone ? const Color(0xFFA5D6A7) : Colors.amber.shade200)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: isDone ? const Color(0xFFA5D6A7) : Colors.amber.shade200)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.amber.shade700, width: 1.5)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (!isDone)
                          SizedBox(
                            width: double.infinity, height: 44,
                            child: ElevatedButton(
                              onPressed: uid.isEmpty ? null : () async {
                                final text = ctrl.text.trim();
                                if (text.isEmpty) return;
                                final resp = UserResponseModel(
                                  contentId: item.id,
                                  moduleId: _subPageParams?['moduleId'] as String? ?? '',
                                  type: item.type,
                                  textResponse: text,
                                  xpEarned: item.xpReward,
                                );
                                await _responseService.saveResponse(uid: uid, response: resp);
                                await _responseService.recordXp(uid: uid, familyId: familyId, xp: item.xpReward);
                                localSetState(() {});
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber.shade700,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                              child: const Text('Save Activity',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 8),
              _buildCompleteWeekButton(week, activities, controllers, uid, familyId),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompleteWeekButton(
    int week,
    List<ModuleContentModel> activities,
    Map<String, TextEditingController> controllers,
    String uid,
    String? familyId,
  ) {
    final currentWeek       = _currentUser?.currentWeek ?? 1;
    final alreadyCompleted  = currentWeek > week;

    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        gradient: alreadyCompleted
            ? const LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF388E3C)])
            : const LinearGradient(colors: [AppTheme.deepNavy, AppTheme.oceanBlue]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.modernShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: (uid.isEmpty || alreadyCompleted) ? null : () async {
            for (final act in activities) {
              if (_activeResponses[act.id]?.isCompleted != true) {
                final text = controllers[act.id]?.text.trim() ?? '';
                if (text.isNotEmpty) {
                  final resp = UserResponseModel(
                    contentId: act.id,
                    moduleId: _subPageParams?['moduleId'] as String? ?? '',
                    type: act.type,
                    textResponse: text,
                    xpEarned: act.xpReward,
                  );
                  await _responseService.saveResponse(uid: uid, response: resp);
                  await _responseService.recordXp(uid: uid, familyId: familyId, xp: act.xpReward);
                }
              }
            }
            final nextWeek = (week < 8) ? week + 1 : week;
            await _updateCurrentWeek(nextWeek);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Week complete! Great work, family! 🎉'),
                backgroundColor: Color(0xFF2E7D32),
              ));
              _goBack();
            }
          },
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  alreadyCompleted ? Icons.check_circle_rounded : Icons.auto_awesome_rounded,
                  color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Text(
                  alreadyCompleted ? 'Week Already Completed ✓' : 'Save and Complete Week ✨',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Empty State Widget ────────────────────────────────────────────────────

  // ─── XP Badge Widget ────────────────────────────────────────────────────────

  // ─── Page Step Indicator ────────────────────────────────────────────────────

  // ── Individual ModuleContent Item Renderer ────────────────────────────────
  // ignore: unused_element
  Widget _buildModuleContentItem(ModuleContentModel item) {
    final existingResponse = _activeResponses[item.id];
    final uid = _currentUser?.uid ?? '';
    final familyId = _currentUser?.familyId;

    switch (item.type) {
      case 'reflection':
        return _buildReflectionItem(item, existingResponse, uid, familyId);
      case 'assessment':
        return _buildAssessmentItem(item, existingResponse, uid, familyId);
      case 'activity':
        return _buildActivityItem(item, existingResponse, uid, familyId);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildReflectionItem(
    ModuleContentModel item,
    UserResponseModel? existing,
    String uid,
    String? familyId,
  ) {
    final controller = TextEditingController(
      text: existing?.textResponse ?? '',
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: AppTheme.modernShadow,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.oceanBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Reflection',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.oceanBlue,
                    ),
                  ),
                ),
                const Spacer(),
                if (existing?.isCompleted ?? false)
                  Row(
                    children: [
                      Icon(
                        Icons.star_rounded,
                        size: 12,
                        color: Colors.amber.shade600,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '+${item.xpReward} XP',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade700,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              item.question,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
            if (item.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                item.description,
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textLight),
              ),
            ],
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Write your reflection here...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: uid.isEmpty
                    ? null
                    : () async {
                        final text = controller.text.trim();
                        if (text.isEmpty) return;
                        final isFirstSubmit =
                            !(existing?.isCompleted ?? false);
                        final response = UserResponseModel(
                          contentId: item.id,
                          moduleId: _subPageParams?['moduleId'] as String? ?? '',
                          type: item.type,
                          textResponse: text,
                          xpEarned:
                              isFirstSubmit ? item.xpReward : (existing?.xpEarned ?? 0),
                        );
                        await _responseService.saveResponse(
                          uid: uid,
                          response: response,
                        );
                        if (isFirstSubmit) {
                          await _responseService.recordXp(
                            uid: uid,
                            familyId: familyId,
                            xp: item.xpReward,
                          );
                        }
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isFirstSubmit
                                    ? 'Saved! +${item.xpReward} XP earned 🌟'
                                    : 'Response updated.',
                              ),
                              backgroundColor: AppTheme.successGreen,
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.oceanBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  (existing?.isCompleted ?? false) ? 'Update' : 'Save Reflection',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssessmentItem(
    ModuleContentModel item,
    UserResponseModel? existing,
    String uid,
    String? familyId,
  ) {
    final alreadyAnswered = existing?.selectedOptionId != null;
    return StatefulBuilder(
      builder: (context, localSetState) {
        String? selected =
            alreadyAnswered ? existing!.selectedOptionId : null;
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: AppTheme.modernShadow,
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color:
                            Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Assessment',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple.shade700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (alreadyAnswered)
                      Row(
                        children: [
                          Icon(
                            existing!.isCorrect == true
                                ? Icons.check_circle_rounded
                                : Icons.cancel_rounded,
                            size: 14,
                            color: existing.isCorrect == true
                                ? Colors.green
                                : Colors.red,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${item.xpReward} XP',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade700,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  item.question,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                ...item.options.map((opt) {
                  final isSelected = selected == opt.optionId;
                  Color bgColor = Colors.white;
                  Color borderColor = Colors.grey.shade300;
                  if (alreadyAnswered || selected != null) {
                    if (opt.isCorrect) {
                      bgColor = Colors.green.shade50;
                      borderColor = Colors.green.shade400;
                    } else if (isSelected && !opt.isCorrect) {
                      bgColor = Colors.red.shade50;
                      borderColor = Colors.red.shade400;
                    }
                  } else if (isSelected) {
                    bgColor = AppTheme.oceanBlue.withValues(alpha: 0.08);
                    borderColor = AppTheme.oceanBlue;
                  }
                  return GestureDetector(
                    onTap: (alreadyAnswered || selected != null)
                        ? null
                        : () async {
                            localSetState(() => selected = opt.optionId);
                            final isFirstSubmit =
                                !(existing?.isCompleted ?? false);
                            final response = UserResponseModel(
                              contentId: item.id,
                              moduleId:
                                  _subPageParams?['moduleId'] as String? ?? '',
                              type: item.type,
                              selectedOptionId: opt.optionId,
                              isCorrect: opt.isCorrect,
                              xpEarned: isFirstSubmit
                                  ? item.xpReward
                                  : (existing?.xpEarned ?? 0),
                            );
                            await _responseService.saveResponse(
                                uid: uid, response: response);
                            if (isFirstSubmit) {
                              await _responseService.recordXp(
                                uid: uid,
                                familyId: familyId,
                                xp: item.xpReward,
                              );
                            }
                          },
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor, width: 1.5),
                      ),
                      child: Text(
                        opt.optionText,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActivityItem(
    ModuleContentModel item,
    UserResponseModel? existing,
    String uid,
    String? familyId,
  ) {
    final isDone = existing?.isCompleted ?? false;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        decoration: BoxDecoration(
          gradient: isDone
              ? LinearGradient(
                  colors: [
                    Colors.green.shade50,
                    Colors.green.shade100,
                  ],
                )
              : LinearGradient(
                  colors: [
                    Colors.amber.shade50,
                    Colors.orange.shade50,
                  ],
                ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDone ? Colors.green.shade300 : Colors.amber.shade300,
          ),
          boxShadow: AppTheme.modernShadow,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDone
                        ? Colors.green.shade100
                        : Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Activity',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isDone
                          ? Colors.green.shade700
                          : Colors.amber.shade800,
                    ),
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Icon(
                      Icons.star_rounded,
                      size: 12,
                      color: Colors.amber.shade600,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${item.xpReward} XP',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              item.question,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDone
                    ? Colors.green.shade800
                    : AppTheme.textDark,
              ),
            ),
            if (item.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                item.description,
                style: TextStyle(
                  fontSize: 12,
                  color: isDone
                      ? Colors.green.shade600
                      : AppTheme.textLight,
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isDone || uid.isEmpty
                    ? null
                    : () async {
                        final response = UserResponseModel(
                          contentId: item.id,
                          moduleId:
                              _subPageParams?['moduleId'] as String? ?? '',
                          type: item.type,
                          textResponse: 'completed',
                          xpEarned: item.xpReward,
                        );
                        await _responseService.saveResponse(
                            uid: uid, response: response);
                        await _responseService.recordXp(
                          uid: uid,
                          familyId: familyId,
                          xp: item.xpReward,
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Activity completed! +${item.xpReward} XP 🎉'),
                              backgroundColor: AppTheme.successGreen,
                            ),
                          );
                        }
                      },
                icon: Icon(
                  isDone
                      ? Icons.check_circle_rounded
                      : Icons.done_all_rounded,
                  color: Colors.white,
                ),
                label: Text(
                  isDone ? 'Completed ✓' : 'Mark as Complete',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isDone ? Colors.green.shade400 : Colors.amber.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // TRIVIA WISDOM GAME VIEW
  Widget _buildTriviaGameView() {
    if (_triviaIndex >= _triviaQuestions.length) {
      // Show Completion Screen
      String feedText = '';
      if (_triviaScore == 5) {
        feedText = 'Exceptional! Your family communication is exemplary! 🏆';
      } else if (_triviaScore >= 3) {
        feedText = 'Great job! Keep discussing and learning together. 🌟';
      } else {
        feedText =
            'A good start! Review the weekly modules together to learn more. 📚';
      }

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.emoji_events_rounded,
                color: Colors.amber,
                size: 80,
              ),
              const SizedBox(height: 20),
              const Text(
                'Quiz Finished!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your Score: $_triviaScore / ${_triviaQuestions.length}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.oceanBlue,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                feedText,
                style: const TextStyle(fontSize: 14, color: AppTheme.textLight),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _resetTrivia,
                icon: const Icon(Icons.replay_rounded, color: Colors.white),
                label: const Text(
                  'Play Again',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final qData = _triviaQuestions[_triviaIndex];
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${_triviaIndex + 1} of ${_triviaQuestions.length}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textLight,
                ),
              ),
              Text(
                'Score: $_triviaScore',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.oceanBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (_triviaIndex + 1) / _triviaQuestions.length,
              minHeight: 6,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation(AppTheme.oceanBlue),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            qData['question'],
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.separated(
              itemCount: (qData['options'] as List).length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, idx) {
                final optionText = qData['options'][idx];
                Color btnColor = Colors.white;
                Color txtColor = AppTheme.textDark;
                BorderSide border = BorderSide(color: Colors.grey.shade200);

                if (_triviaAnswered) {
                  if (idx == qData['answerIndex']) {
                    btnColor = Colors.green.shade50;
                    txtColor = Colors.green.shade700;
                    border = BorderSide(color: Colors.green.shade400, width: 2);
                  } else if (_selectedTriviaOption == idx) {
                    btnColor = Colors.red.shade50;
                    txtColor = Colors.red.shade700;
                    border = BorderSide(color: Colors.red.shade400, width: 2);
                  }
                }

                return GestureDetector(
                  onTap: _triviaAnswered
                      ? null
                      : () {
                          setState(() {
                            _selectedTriviaOption = idx;
                            _triviaAnswered = true;
                            if (idx == qData['answerIndex']) {
                              _triviaScore++;
                            }
                          });
                        },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      color: btnColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.fromBorderSide(border),
                      boxShadow: AppTheme.modernShadow,
                    ),
                    child: Text(
                      optionText,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: txtColor,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_triviaAnswered)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _triviaIndex++;
                    _triviaAnswered = false;
                    _selectedTriviaOption = null;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                ),
                child: const Text(
                  'Next Question →',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // CONVERSATION STARTERS VIEW
  Widget _buildConversationsGameView() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF8A2387),
                    Color(0xFFE94057),
                    Color(0xFFF27121),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.pink.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.format_quote_rounded,
                    color: Colors.white70,
                    size: 52,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _convoCards[_convoIndex],
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  Text(
                    'Card ${_convoIndex + 1} of ${_convoCards.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      if (_convoIndex > 0) {
                        _convoIndex--;
                      } else {
                        _convoIndex = _convoCards.length - 1;
                      }
                    });
                  },
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Previous'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.oceanBlue),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      if (_convoIndex < _convoCards.length - 1) {
                        _convoIndex++;
                      } else {
                        _convoIndex = 0;
                      }
                    });
                  },
                  icon: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Next Card',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _convoIndex = (List.from(
                  _convoCards,
                )..shuffle()).indexOf(_convoCards[_convoIndex]);
                if (_convoIndex == -1 || _convoIndex >= _convoCards.length) {
                  _convoIndex = 0;
                }
              });
            },
            icon: const Icon(Icons.shuffle_rounded),
            label: const Text('Shuffle Prompts'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // MEMORY MATCHING GAME VIEW
  Widget _buildMatchingGameView() {
    final matchedAll = _matchingMatched.every((element) => element);

    if (matchedAll && _matchingCards.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star_rounded, color: Colors.amber, size: 84),
              const SizedBox(height: 16),
              const Text(
                'Congratulations!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'You matched all core values in $_matchingMoves moves!',
                style: const TextStyle(fontSize: 16, color: AppTheme.textLight),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _initMatchingGame,
                icon: const Icon(Icons.replay_rounded, color: Colors.white),
                label: const Text(
                  'Play Again',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Moves: $_matchingMoves',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              IconButton(
                onPressed: _initMatchingGame,
                icon: const Icon(
                  Icons.replay_rounded,
                  color: AppTheme.oceanBlue,
                ),
                tooltip: 'Restart Game',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              itemCount: _matchingCards.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (context, idx) {
                final isFlipped =
                    _matchingFlipped[idx] || _matchingMatched[idx];
                final value = _matchingCards[idx];

                return GestureDetector(
                  onTap: () {
                    if (isFlipped || _matchingIgnoreTaps) return;

                    setState(() {
                      _matchingFlipped[idx] = true;
                    });

                    if (_firstFlippedIndex == null) {
                      _firstFlippedIndex = idx;
                    } else {
                      final firstIdx = _firstFlippedIndex!;
                      _matchingMoves++;

                      if (_matchingCards[firstIdx] == _matchingCards[idx]) {
                        // Match!
                        setState(() {
                          _matchingMatched[firstIdx] = true;
                          _matchingMatched[idx] = true;
                          _firstFlippedIndex = null;
                        });
                      } else {
                        // Not a match, flip back after 1 second delay
                        setState(() {
                          _matchingIgnoreTaps = true;
                        });
                        Future.delayed(const Duration(milliseconds: 900), () {
                          if (mounted) {
                            setState(() {
                              _matchingFlipped[firstIdx] = false;
                              _matchingFlipped[idx] = false;
                              _firstFlippedIndex = null;
                              _matchingIgnoreTaps = false;
                            });
                          }
                        });
                      }
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isFlipped ? Colors.white : AppTheme.oceanBlue,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isFlipped ? AppTheme.oceanBlue : Colors.white,
                        width: 2,
                      ),
                      boxShadow: AppTheme.modernShadow,
                    ),
                    child: isFlipped
                        ? Text(
                            value,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                            textAlign: TextAlign.center,
                          )
                        : const Icon(
                            Icons.question_mark_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}