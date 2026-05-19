import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/family_service.dart';
import '../models/user_model.dart';
import '../models/family_model.dart';
import 'welcome_screen.dart';
import 'sign_in_screen.dart';
import 'family_setup_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  final _familyService = FamilyService();
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

  final List<Map<String, dynamic>> _triviaQuestions = [
    {
      'question': 'Which of these is a core key to building family trust?',
      'options': [
        'Active listening & honesty',
        'Buying expensive gifts',
        'Avoiding conversation',
        'Ignoring household rules',
      ],
      'answerIndex': 0,
    },
    {
      'question': 'What is the primary purpose of a Family Charter?',
      'options': [
        'To track daily chores only',
        'To define shared values and structure',
        'To assign homework punishments',
        'To list family recipes',
      ],
      'answerIndex': 1,
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
      'answerIndex': 2,
    },
    {
      'question': 'Which of the following is NOT one of the 8 weekly modules?',
      'options': [
        'Boundaries & Safety',
        'Roles of Children',
        'Family Identity & Structure',
        'Advanced Cooking Skills',
      ],
      'answerIndex': 3,
    },
    {
      'question': 'How often should a family hold family governance meetings?',
      'options': [
        'Once a year',
        'Regularly (e.g. weekly or monthly)',
        'Only during crises',
        'Never',
      ],
      'answerIndex': 1,
    },
  ];

  final List<String> _convoCards = [
    "What is your absolute favorite memory of our family doing something together?",
    "If our family had a theme song or motto, what would you want it to be?",
    "What is one thing you appreciate most about the person sitting next to you?",
    "If you could travel anywhere in the world with the family tomorrow, where would you go?",
    "What is a family tradition you want to make sure we keep doing forever?",
    "What is one value you think is most important for our household?",
    "If you could trade places with any other family member for one day, who would it be and why?",
    "What was the most challenging part of your week, and how did you overcome it?",
  ];

  final List<String> _matchingValuePool = [
    'Love 💖',
    'Trust 🤝',
    'Safety 🛡️',
    'Respect 🙌',
    'Fun 🎉',
    'Unity 🧩',
  ];

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
    _loadData();

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
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _lessonInput1Controller.dispose();
    _lessonInput2Controller.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        setState(() {
          _currentUser = user;
        });
        if (SignInScreen.selectedFamilyOption == 'join') {
          SignInScreen.selectedFamilyOption = 'start'; // reset one-time flag
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => FamilySetupScreen(
                  isJoining: true,
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

  Future<void> _saveLessonAnswers(int week, String ans1, String ans2) async {
    final uid = _currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('lessonAnswers')
          .doc('week_$week')
          .set({
            'week': week,
            'answer1': ans1,
            'answer2': ans2,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      final currentWeek = _currentUser?.currentWeek ?? 1;
      if (week == currentWeek) {
        await _updateCurrentWeek(currentWeek + 1);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Answers saved and progress updated!'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    }
  }

  Future<void> _loadLessonAnswers(int week) async {
    final uid = _currentUser?.uid;
    if (uid != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('lessonAnswers')
            .doc('week_$week')
            .get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          _lessonInput1Controller.text = data['answer1'] ?? '';
          _lessonInput2Controller.text = data['answer2'] ?? '';
        } else {
          _lessonInput1Controller.clear();
          _lessonInput2Controller.clear();
        }
      } catch (e) {
        _lessonInput1Controller.clear();
        _lessonInput2Controller.clear();
      }
    }
  }

  void _navigateToSubPage(
    String subPage, [
    Map<String, dynamic>? params,
  ]) async {
    if (subPage == 'lesson') {
      final int w = params?['week'] ?? 1;
      await _loadLessonAnswers(w);
    } else if (subPage == 'game_matching') {
      _initMatchingGame();
    } else if (subPage == 'game_trivia') {
      _resetTrivia();
    }

    setState(() {
      _activeSubPage = subPage;
      _subPageParams = params;
    });
  }

  void _goBack() {
    setState(() {
      _activeSubPage = null;
      _subPageParams = null;
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
                        'Welcome, ${familyName}!',
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

            // Active Module Card
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.oceanBlue.withValues(alpha: 0.1),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Week $currentWeek of 8',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textLight,
                                ),
                              ),
                              const Text(
                                'Family Identity & Structure',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Define your family identity and establish clear leadership roles',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
                      children: weekTopics.take(3).map((topic) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppTheme.primaryColor,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            topic,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          _navigateToSubPage('lesson', {'week': currentWeek});
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          'Continue Week $currentWeek →',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Program summary roadmap
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
                    const Text(
                      '8-Week Program Roadmap',
                      style: TextStyle(
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
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 4,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final weeks = [
                          'Week 1: Family Identity & Structure',
                          'Week 2: Love & Communication',
                          'Week 3: Boundaries & Safety',
                          'Week 4: Core Values & Traditions',
                        ];
                        final isActive = index == (currentWeek - 1);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isActive
                                        ? AppTheme.primaryColor
                                        : Colors.grey.shade300,
                                    width: 2,
                                  ),
                                ),
                                child: isActive
                                    ? Container(
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppTheme.primaryColor,
                                        ),
                                        margin: const EdgeInsets.all(4),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  weeks[index],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isActive
                                        ? AppTheme.textDark
                                        : AppTheme.textLight,
                                    fontWeight: isActive
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
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

    final List<Map<String, String>> weeksInfo = [
      {
        'week': 'Week 1',
        'title': 'Family Identity & Structure',
        'desc':
            'Define your family identity and establish clear leadership roles',
      },
      {
        'week': 'Week 2',
        'title': 'Love & Communication',
        'desc': 'Build healthy communication patterns and emotional connection',
      },
      {
        'week': 'Week 3',
        'title': 'Boundaries & Safety',
        'desc': 'Create emotional and physical safety through clear boundaries',
      },
      {
        'week': 'Week 4',
        'title': 'Core Values & Traditions',
        'desc': 'Identify core values and build lasting family traditions',
      },
      {
        'week': 'Week 5',
        'title': 'Roles of Father',
        'desc': 'Understand and embrace the father\'s unique contribution',
      },
      {
        'week': 'Week 6',
        'title': 'Roles of Mother',
        'desc': 'Understand and embrace the mother\'s unique contribution',
      },
      {
        'week': 'Week 7',
        'title': 'Roles of Children',
        'desc': 'Foster responsibility, obedience, and character in children',
      },
      {
        'week': 'Week 8',
        'title': 'Family Governance',
        'desc': 'Implement family meetings, financial stewardships, and rules',
      },
    ];

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
                        const Text(
                          '8-Week Program',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '$totalCompleted/8 Completed',
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
                        value: progressVal,
                        minHeight: 8,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
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
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: weeksInfo.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = weeksInfo[index];
                  final isUnlocked = index < currentWeek;
                  final isActive = index == (currentWeek - 1);

                  return GestureDetector(
                    onTap: isUnlocked
                        ? () {
                            _navigateToSubPage('lesson', {'week': index + 1});
                          }
                        : null,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isUnlocked ? Colors.white : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isActive
                              ? AppTheme.oceanBlue
                              : Colors.grey.shade200,
                          width: isActive ? 2 : 1,
                        ),
                        boxShadow: isUnlocked ? AppTheme.modernShadow : null,
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isUnlocked
                                  ? (isActive
                                        ? AppTheme.oceanBlue.withValues(
                                            alpha: 0.1,
                                          )
                                        : AppTheme.lightBeige)
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isUnlocked
                                  ? Icons.menu_book_rounded
                                  : Icons.lock_outline,
                              color: isUnlocked
                                  ? (isActive
                                        ? AppTheme.oceanBlue
                                        : AppTheme.textLight)
                                  : Colors.grey.shade400,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${item['week']} of 8',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isUnlocked
                                        ? AppTheme.textLight
                                        : Colors.grey.shade500,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item['title']!,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isUnlocked
                                        ? AppTheme.textDark
                                        : Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isUnlocked
                                      ? item['desc']!
                                      : 'Complete previous weeks to unlock',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isUnlocked
                                        ? AppTheme.textLight.withValues(
                                            alpha: 0.8,
                                          )
                                        : Colors.grey.shade400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isUnlocked)
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                              color: AppTheme.textLight,
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

  Widget _buildCharterTab() {
    final readinessVal = (_currentFamily?.charterReadinessScore ?? 0.0) / 100.0;

    final List<Map<String, String>> charterSections = [
      {
        'title': 'Family Vision Statement',
        'desc': 'Defining the family\'s long-term visual destination.',
      },
      {
        'title': 'Family Mission & Values',
        'desc': 'Core commitments and fundamental pillars.',
      },
      {
        'title': 'Family Safety Agreement',
        'desc': 'Establishing physical, mental and emotional protection.',
      },
      {
        'title': 'Traditions & Celebrations',
        'desc': 'Key milestones, events, and family bonding habits.',
      },
      {
        'title': 'Father\'s Leadership Intent',
        'desc': 'Pledges of leadership and active involvement.',
      },
      {
        'title': 'Mother\'s Nurturing Vows',
        'desc': 'Vows of support, parenting alignment, and love.',
      },
      {
        'title': 'Children\'s Code of Honor',
        'desc': 'Respect, chores, and behavioral standards.',
      },
      {
        'title': 'Family Constitution',
        'desc': 'Rules of governance and household agreements.',
      },
    ];

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
                    const Text(
                      'Family Charter',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Your comprehensive family framework document',
                      style: TextStyle(fontSize: 13, color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Progress Section Card (themed with periwinkle/blue waves style)
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
              const Text(
                'Charter Sections',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 12),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: charterSections.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final section = charterSections[index];
                  final isUnlocked =
                      index < ((_currentUser?.currentWeek ?? 1) - 1);

                  return Container(
                    decoration: BoxDecoration(
                      color: isUnlocked ? Colors.white : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isUnlocked
                            ? Colors.grey.shade200
                            : Colors.grey.shade200,
                      ),
                      boxShadow: isUnlocked ? AppTheme.modernShadow : null,
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
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
                              Text(
                                section['title']!,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: isUnlocked
                                      ? AppTheme.textDark
                                      : Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isUnlocked
                                    ? section['desc']!
                                    : 'Unlock this section by completing Week ${index + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isUnlocked
                                      ? AppTheme.textLight
                                      : Colors.grey.shade400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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

              // Game 1: Matching Game
              _buildGameMenuCard(
                title: 'Values Matching Game',
                desc: 'A fun memory card matchup focusing on core values.',
                icon: Icons.grid_view_rounded,
                color: Colors.purple.shade400,
                onTap: () => _navigateToSubPage('game_matching'),
              ),
              const SizedBox(height: 12),

              // Game 2: Trivia
              _buildGameMenuCard(
                title: 'Family Wisdom Quiz',
                desc: 'Multiple choice trivia about communication and values.',
                icon: Icons.quiz_rounded,
                color: Colors.teal.shade400,
                onTap: () => _navigateToSubPage('game_trivia'),
              ),
              const SizedBox(height: 12),

              // Game 3: Dinner Conversation cards
              _buildGameMenuCard(
                title: 'Conversation Starters',
                desc: 'A deck of meaningful, fun prompts for the dinner table.',
                icon: Icons.forum_rounded,
                color: Colors.pink.shade400,
                onTap: () => _navigateToSubPage('game_conversations'),
              ),
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
    final isPremium = _currentUser?.subscriptionStatus == 'premium';

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

              if (isPremium) ...[
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
      await _authService.updateSubscription('premium');
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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 50,
              backgroundColor: AppTheme.primaryColor,
              backgroundImage:
                  _currentUser?.profilePictureUrl != null &&
                      _currentUser!.profilePictureUrl!.isNotEmpty
                  ? NetworkImage(_currentUser!.profilePictureUrl!)
                  : null,
              child:
                  _currentUser?.profilePictureUrl == null ||
                      _currentUser!.profilePictureUrl!.isEmpty
                  ? const Icon(Icons.person, size: 50, color: Colors.white)
                  : null,
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
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildProfileDetailRow(
                    Icons.family_restroom,
                    'Family',
                    _currentFamily?.familyName ?? 'No Family connected',
                  ),
                  const Divider(height: 24),
                  _buildProfileDetailRow(
                    Icons.calendar_today,
                    'Program Progression',
                    'Week ${_currentUser?.currentWeek ?? 1} of 8',
                  ),
                  const Divider(height: 24),
                  _buildProfileDetailRow(
                    Icons.workspace_premium,
                    'Subscription',
                    _currentUser?.subscriptionStatus?.toUpperCase() ?? 'TRIAL',
                  ),
                ],
              ),
            ),
            if (_currentUser?.subscriptionStatus == 'trial') ...[
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
            const Spacer(),
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

  Widget _buildProfileDetailRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryColor),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontSize: 14, color: AppTheme.textLight),
        ),
      ],
    );
  }

  // SUBPAGES RENDER (WITH BACK BUTTON)
  Widget _buildSubPage() {
    Widget child;
    String title = '';

    switch (_activeSubPage) {
      case 'lesson':
        final int week = _subPageParams?['week'] ?? 1;
        title = 'Week $week Lesson';
        child = _buildLessonView(week);
        break;
      case 'game_trivia':
        title = 'Family Wisdom Quiz';
        child = _buildTriviaGameView();
        break;
      case 'game_conversations':
        title = 'Conversation Starters';
        child = _buildConversationsGameView();
        break;
      case 'game_matching':
        title = 'Values Matching Game';
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
      ),
      body: child,
    );
  }

  // LESSON DETAIL VIEW WORKBOOK
  Widget _buildLessonView(int week) {
    final data =
        lessonData[week] ??
        {
          'title': 'Weekly Lesson',
          'subtitle': 'Workbook guidelines and reflection details.',
          'readText': 'Workbook guidelines details.',
          'question1': 'Question 1:',
          'question2': 'Question 2:',
        };

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Week subtitle & description
            Text(
              data['subtitle']!,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.oceanBlue,
              ),
            ),
            const SizedBox(height: 12),
            Container(
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
                  const Text(
                    'Study Reflection Guideline',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data['readText']!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textLight,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Interactive Worksheet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 12),

            // Question 1
            Text(
              data['question1']!,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _lessonInput1Controller,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Type your reflection here...',
                fillColor: Colors.white,
                filled: true,
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
            const SizedBox(height: 20),

            // Question 2
            Text(
              data['question2']!,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _lessonInput2Controller,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Type your reflection here...',
                fillColor: Colors.white,
                filled: true,
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
            const SizedBox(height: 24),

            // Save Progress Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  _saveLessonAnswers(
                    week,
                    _lessonInput1Controller.text,
                    _lessonInput2Controller.text,
                  );
                },
                icon: const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                ),
                label: const Text(
                  'Save & Complete Week',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 30),
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
