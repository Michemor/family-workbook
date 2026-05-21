import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../models/user_model.dart';
import '../models/family_model.dart';
import '../models/family_member_model.dart';
import '../services/family_service.dart';
import 'home_screen.dart';

class FamilySetupScreen extends StatefulWidget {
  final bool isJoining;
  final UserModel user;

  const FamilySetupScreen({
    super.key,
    required this.isJoining,
    required this.user,
  });

  @override
  State<FamilySetupScreen> createState() => _FamilySetupScreenState();
}

class _FamilySetupScreenState extends State<FamilySetupScreen> {
  final _familyService = FamilyService();

  // Wizard state
  int _currentStep = 2; // Starts at 2 of 3 (Step 1 is registration/signup)
  bool _isLoading = false;

  // Step 2 Create Family State
  final _familyNameController = TextEditingController();
  final _countryController = TextEditingController();
  final _familyTypeController = TextEditingController(text: 'Nuclear Family');
  int _selectedAvatarIndex = 0;

  // Step 2 Join Family State
  String? _selectedFamilyId;
  String? _selectedFamilyName;
  List<FamilyModel> _availableFamilies = [];

  // Step 3 Invite Members State
  int _activeInviteTab = 0; // 0: Phone, 1: Email, 2: Link
  final _inviteInputController = TextEditingController();
  List<Map<String, String>> _invitedMembers = []; // mock invites list

  // Step 3 Join Meet Family State
  List<FamilyMemberModel> _existingMembersList = [];

  final List<String> _familyTypes = [
    'Nuclear Family',
    'Extended Family',
    'Single Parent',
    'Blended Family',
    'Adoptive Family',
    'Other',
  ];

  final List<String> _avatarColors = [
    '0xFF3B67B5', // Ocean Blue
    '0xFFA395D1', // Lavender
    '0xFFCFB8E8', // Lilac Pink
    '0xFF142459', // Deep Navy
  ];

  @override
  void initState() {
    super.initState();
    _familyNameController.text = '${widget.user.username}\'s Family';
    _countryController.text = 'United States';
    
    // Add default invited members like the mockup
    _invitedMembers = [
      {'name': 'Sandra Rivera', 'status': 'Joined', 'role': 'Parent'},
      {'name': 'Marcus Rivera', 'status': 'Invited', 'role': 'Sibling'},
    ];

    if (widget.isJoining) {
      _loadFamilies();
    }
  }

  @override
  void dispose() {
    _familyNameController.dispose();
    _countryController.dispose();
    _familyTypeController.dispose();
    _inviteInputController.dispose();
    super.dispose();
  }

  Future<void> _loadFamilies() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final list = await _familyService.getAllFamilies();
      setState(() {
        _availableFamilies = list;
        if (list.isNotEmpty) {
          _selectedFamilyId = list.first.familyId;
          _selectedFamilyName = list.first.familyName;
          _loadExistingMembers(list.first.familyId);
        }
      });
    } catch (e) {
      debugPrint('Error loading families: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadExistingMembers(String familyId) async {
    try {
      // Get initial list from stream
      _familyService.streamFamilyMembers(familyId).listen((members) {
        if (mounted) {
          setState(() {
            _existingMembersList = members;
          });
        }
      });
      // We don't necessarily need to keep it open unless needed, but it helps populate the view.
    } catch (e) {
      debugPrint('Error loading family members: $e');
    }
  }

  void _sendInvite() {
    final text = _inviteInputController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _invitedMembers.insert(0, {
        'name': text,
        'status': 'Invited',
        'role': 'Member',
      });
      _inviteInputController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invitation sent successfully!'),
        backgroundColor: AppTheme.successGreen,
      ),
    );
  }

  void _handleStep2Submit() async {
    if (widget.isJoining) {
      if (_selectedFamilyId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a family to join'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
        return;
      }
      // Load members of this family to meet them in Step 3
      await _loadExistingMembers(_selectedFamilyId!);
      setState(() {
        _currentStep = 3;
      });
    } else {
      if (_familyNameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please name your family'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
        return;
      }
      // Move to Step 3
      setState(() {
        _currentStep = 3;
      });
    }
  }

  void _handleStep3Submit() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.isJoining) {
        // Complete join family
        await _familyService.joinFamily(
          uid: widget.user.uid,
          username: widget.user.username,
          familyId: _selectedFamilyId!,
          role: widget.user.role ?? 'Member',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully joined the $_selectedFamilyName Family!'),
              backgroundColor: AppTheme.successGreen,
            ),
          );
          _navigateToDashboard();
        }
      } else {
        // Create new family
        await _familyService.createFamily(
          uid: widget.user.uid,
          username: widget.user.username,
          familyName: _familyNameController.text.trim(),
          country: _countryController.text.trim(),
          familyType: _familyTypeController.text.trim(),
          role: widget.user.role ?? 'Parent',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Family set up successfully!'),
              backgroundColor: AppTheme.successGreen,
            ),
          );
          _navigateToDashboard();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToDashboard() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.deepNavy),
          onPressed: () {
            if (_currentStep == 3) {
              setState(() {
                _currentStep = 2;
              });
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(
          widget.isJoining ? 'Join Family' : 'Family Setup',
          style: const TextStyle(
            color: AppTheme.deepNavy,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Custom Stepper / Progress Bar like the mockup
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  children: [
                    Text(
                      '$_currentStep of 3',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textLight.withValues(alpha: 0.8),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppTheme.lightBeige,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: _currentStep / 3,
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              gradient: AppTheme.wavesOmbre,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Dynamic wizard body
              if (_currentStep == 2) ...[
                _buildStep2(theme, size)
              ] else if (_currentStep == 3) ...[
                _buildStep3(theme, size)
              ],
            ],
          ),
        ),
      ),
    );
  }

  // STEP 2 UI
  Widget _buildStep2(ThemeData theme, Size size) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Text
          Text(
            widget.isJoining ? 'Select your family.' : 'Name your family.',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppTheme.deepNavy,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.isJoining
                ? 'Choose the family account you would like to join. Ensure you have the family name right.'
                : 'This name will appear on your Family Charter. Choose something meaningful.',
            style: const TextStyle(
              fontSize: 15,
              color: AppTheme.textLight,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),

          if (widget.isJoining) ...[
            // Join fields
            const Text(
              'SELECT A FAMILY',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.deepNavy,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _availableFamilies.isEmpty
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.lightBeige,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.skyBlue.withValues(alpha: 0.3)),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.info_outline, color: AppTheme.oceanBlue),
                            SizedBox(height: 8),
                            Text(
                              'No active families found in the database. Please go back and create a new family instead.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppTheme.deepNavy, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.skyBlue, width: 1.5),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedFamilyId,
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.oceanBlue),
                            items: _availableFamilies.map((fam) {
                              return DropdownMenuItem<String>(
                                value: fam.familyId,
                                child: Text(
                                  fam.familyName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.deepNavy,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedFamilyId = val;
                                _selectedFamilyName = _availableFamilies
                                    .firstWhere((element) => element.familyId == val)
                                    .familyName;
                              });
                            },
                          ),
                        ),
                      ),
          ] else ...[
            // Create fields
            const Text(
              'FAMILY NAME',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.deepNavy,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _familyNameController,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: AppTheme.deepNavy),
              decoration: const InputDecoration(
                hintText: 'e.g. The Rivera Family',
                prefixIcon: Icon(Icons.family_restroom_rounded, color: AppTheme.oceanBlue),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Examples: The Rivera Family · Our Growing Family · The Johnson-Lee Household',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textLight.withValues(alpha: 0.8),
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 20),
            
            // Family details: type and country
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'FAMILY TYPE',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.deepNavy),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.skyBlue, width: 1.5),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _familyTypeController.text,
                            isExpanded: true,
                            items: _familyTypes.map((type) {
                              return DropdownMenuItem<String>(
                                value: type,
                                child: Text(type, style: const TextStyle(fontSize: 13, color: AppTheme.deepNavy)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _familyTypeController.text = val;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'COUNTRY',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.deepNavy),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _countryController,
                        style: const TextStyle(fontSize: 14, color: AppTheme.deepNavy),
                        decoration: const InputDecoration(
                          hintText: 'United States',
                          contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 28),

          // Avatar Picker Mockup
          Text(
            widget.isJoining ? 'CHOOSE YOUR AVATAR' : 'CHOOSE A FAMILY AVATAR',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.deepNavy,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(4, (index) {
              final isSelected = _selectedAvatarIndex == index;
              final colHex = _avatarColors[index];
              final color = Color(int.parse(colHex));

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedAvatarIndex = index;
                  });
                },
                child: Container(
                  width: (size.width - 56 - 48) / 4,
                  height: (size.width - 56 - 48) / 4,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? color : Colors.transparent,
                      width: 3.5,
                    ),
                    boxShadow: isSelected ? AppTheme.modernShadow : null,
                  ),
                  child: Center(
                    child: Icon(
                      widget.isJoining ? Icons.person : Icons.home_filled,
                      color: color,
                      size: 28,
                    ),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 48),

          // Primary Actions
          Container(
            width: double.infinity,
            height: 54,
            decoration: BoxDecoration(
              gradient: AppTheme.wavesOmbre,
              borderRadius: BorderRadius.circular(14),
              boxShadow: AppTheme.modernShadow,
            ),
            child: ElevatedButton(
              onPressed: _handleStep2Submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.isJoining ? 'Confirm & Continue' : 'This Is Our Family',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Center(
            child: TextButton(
              onPressed: _navigateToDashboard,
              child: Text(
                widget.isJoining ? 'Back to login' : 'I\'ll set this up later',
                style: const TextStyle(
                  color: AppTheme.textLight,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // STEP 3 UI
  Widget _buildStep3(ThemeData theme, Size size) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Text
          Text(
            widget.isJoining ? 'Meet the Family!' : 'Who\'s joining you?',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppTheme.deepNavy,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.isJoining
                ? 'Here are the members already participating in the $_selectedFamilyName Family:'
                : 'Invite family members to participate. They can join anytime — even during Week 3.',
            style: const TextStyle(
              fontSize: 15,
              color: AppTheme.textLight,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),

          if (!widget.isJoining) ...[
            // Invite Tabs
            Row(
              children: [
                _buildInviteTabItem(0, 'Phone'),
                _buildInviteTabItem(1, 'Email'),
                _buildInviteTabItem(2, 'Link'),
              ],
            ),
            const SizedBox(height: 16),

            // Tab contents
            if (_activeInviteTab == 2) ...[
              // Link invite
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.lightBeige,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.skyBlue, width: 1),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'https://familyworkbook.app/join/f_28s9j',
                        style: TextStyle(
                          color: AppTheme.deepNavy,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, color: AppTheme.oceanBlue),
                      onPressed: () {
                        Clipboard.setData(
                          const ClipboardData(text: 'https://familyworkbook.app/join/f_28s9j')
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Join link copied!')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Phone/Email invite input
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _inviteInputController,
                      keyboardType: _activeInviteTab == 0
                          ? TextInputType.phone
                          : TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: _activeInviteTab == 0
                            ? '+1 (555) 000-0000'
                            : 'name@email.com',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: AppTheme.wavesOmbre,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton(
                      onPressed: _sendInvite,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                      ),
                      child: const Text('Send'),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 28),

            // Invited Members Header
            const Text(
              'INVITED MEMBERS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.deepNavy,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),

            // Invited members list
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _invitedMembers.length,
              itemBuilder: (context, index) {
                final invite = _invitedMembers[index];
                final isJoined = invite['status'] == 'Joined';
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.lightBeige.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: isJoined
                            ? AppTheme.successGreen.withValues(alpha: 0.15)
                            : AppTheme.oceanBlue.withValues(alpha: 0.15),
                        child: Text(
                          invite['name']!.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            color: isJoined ? AppTheme.successGreen : AppTheme.oceanBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              invite['name']!,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.deepNavy,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              invite['role']!,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isJoined
                              ? AppTheme.successGreen.withValues(alpha: 0.12)
                              : AppTheme.skyBlue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          invite['status']!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isJoined ? AppTheme.successGreen : AppTheme.oceanBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ] else ...[
            // Meet existing members
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _existingMembersList.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.lightBeige,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'You will be the first joining member in this family!',
                            style: TextStyle(color: AppTheme.deepNavy, fontWeight: FontWeight.bold),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _existingMembersList.length,
                        itemBuilder: (context, index) {
                          final member = _existingMembersList[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.lightBeige,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppTheme.oceanBlue,
                                  child: Text(
                                    member.name.isEmpty ? '?' : member.name.substring(0, 1).toUpperCase(),
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        member.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.deepNavy,
                                        ),
                                      ),
                                      Text(
                                        member.role,
                                        style: const TextStyle(color: AppTheme.textLight, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.successGreen.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Active',
                                    style: TextStyle(color: AppTheme.successGreen, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ],

          const SizedBox(height: 48),

          // Primary action button
          Container(
            width: double.infinity,
            height: 54,
            decoration: BoxDecoration(
              gradient: AppTheme.wavesOmbre,
              borderRadius: BorderRadius.circular(14),
              boxShadow: AppTheme.modernShadow,
            ),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleStep3Submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.isJoining ? 'Join Dashboard' : 'Start My Journey',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 16),

          Center(
            child: TextButton(
              onPressed: _navigateToDashboard,
              child: Text(
                widget.isJoining ? 'Skip overview' : 'Skip for now',
                style: const TextStyle(
                  color: AppTheme.textLight,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          
          if (!widget.isJoining) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Invite more members from your dashboard at any time.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textLight.withValues(alpha: 0.8),
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildInviteTabItem(int index, String label) {
    final isActive = _activeInviteTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _activeInviteTab = index;
            _inviteInputController.clear();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? AppTheme.oceanBlue : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? AppTheme.deepNavy : AppTheme.textLight,
            ),
          ),
        ),
      ),
    );
  }
}
