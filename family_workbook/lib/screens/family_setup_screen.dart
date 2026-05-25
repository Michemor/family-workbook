import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../models/user_model.dart';
import '../models/family_model.dart';
import '../models/family_member_model.dart';
import '../services/family_service.dart';
import '../services/auth_service.dart';
import '../utils/country_data.dart';
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

  // Dynamic flow state (allows switching in screen if no families exist)
  late bool _isJoining;

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
  CountryData _selectedInvitePhoneCountry = CountryData.fromCode('US');
  CountryData _selectedCountry = CountryData.fromCode('US');

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

  String? _uploadedPhotoUrl;

  /// Opens a searchable country name picker dialog and updates [_selectedCountry]
  void _showCountryPickerDialog() {
    final searchCtrl = TextEditingController();
    List<CountryData> filtered = CountryData.all;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          title: const Text('Select Country',
              style: TextStyle(color: AppTheme.deepNavy, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 340,
            height: 420,
            child: Column(children: [
              TextField(
                controller: searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search country...',
                  prefixIcon: const Icon(Icons.search, color: AppTheme.oceanBlue),
                  filled: true,
                  fillColor: AppTheme.lightBeige,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                ),
                onChanged: (q) => setS(() {
                  filtered = CountryData.all
                      .where((c) => c.name.toLowerCase().contains(q.toLowerCase()))
                      .toList();
                }),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final c = filtered[i];
                    final sel = c.code == _selectedCountry.code;
                    return ListTile(
                      dense: true,
                      leading: Text(c.flag, style: const TextStyle(fontSize: 22)),
                      title: Text(c.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                            color: sel ? AppTheme.oceanBlue : AppTheme.textDark,
                          )),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      tileColor: sel ? AppTheme.lightBeige : null,
                      onTap: () {
                        setState(() {
                          _selectedCountry = c;
                          _countryController.text = c.name;
                        });
                        Navigator.of(ctx).pop();
                      },
                    );
                  },
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  /// Opens a searchable country code picker for the phone invite tab
  void _showPhoneCountryCodePicker() {
    final searchCtrl = TextEditingController();
    List<CountryData> filtered = CountryData.all;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          title: const Text('Select Country Code',
              style: TextStyle(color: AppTheme.deepNavy, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 340,
            height: 420,
            child: Column(children: [
              TextField(
                controller: searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search...',
                  prefixIcon: const Icon(Icons.search, color: AppTheme.oceanBlue),
                  filled: true,
                  fillColor: AppTheme.lightBeige,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                onChanged: (q) => setS(() {
                  filtered = CountryData.all
                      .where((c) =>
                          c.name.toLowerCase().contains(q.toLowerCase()) ||
                          c.dialCode.contains(q))
                      .toList();
                }),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final c = filtered[i];
                    final sel = c.code == _selectedInvitePhoneCountry.code;
                    return ListTile(
                      dense: true,
                      leading: Text(c.flag, style: const TextStyle(fontSize: 22)),
                      title: Text(c.name,
                          style: TextStyle(
                            fontSize: 13,
                            color: sel ? AppTheme.oceanBlue : AppTheme.textDark,
                            fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                          )),
                      trailing: Text(c.dialCode,
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: sel ? AppTheme.oceanBlue : AppTheme.textLight)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      tileColor: sel ? AppTheme.lightBeige : null,
                      onTap: () {
                        setState(() => _selectedInvitePhoneCountry = c);
                        Navigator.of(ctx).pop();
                      },
                    );
                  },
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  void _simulatePhotoUpload() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.add_a_photo_rounded, color: AppTheme.oceanBlue),
            SizedBox(width: 10),
            Text('Upload Profile Photo', style: TextStyle(color: AppTheme.deepNavy, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select a sample photo or enter a custom web image URL to simulate an upload:',
              style: TextStyle(color: AppTheme.textLight, fontSize: 13),
            ),
            const SizedBox(height: 16),
            const Text('SAMPLE PHOTOS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.deepNavy, letterSpacing: 0.8)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSamplePhotoOption('https://images.unsplash.com/photo-1511895426328-dc8714191300?w=150'),
                _buildSamplePhotoOption('https://images.unsplash.com/photo-1543269865-cbf427effbad?w=150'),
                _buildSamplePhotoOption('https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=150'),
              ],
            ),
            const SizedBox(height: 20),
            const Text('CUSTOM IMAGE URL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.deepNavy, letterSpacing: 0.8)),
            const SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                filled: true,
                fillColor: AppTheme.lightBeige,
                hintText: 'https://example.com/photo.jpg',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              onSubmitted: (url) {
                if (url.trim().isNotEmpty) {
                  setState(() {
                    _uploadedPhotoUrl = url.trim();
                    _selectedAvatarIndex = 4;
                  });
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textLight)),
          ),
        ],
      ),
    );
  }

  Widget _buildSamplePhotoOption(String url) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _uploadedPhotoUrl = url;
          _selectedAvatarIndex = 4;
        });
        Navigator.of(context).pop();
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.skyBlue, width: 1.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(url, fit: BoxFit.cover),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _isJoining = widget.isJoining;
    _familyNameController.text = '${widget.user.username}\'s Family';
    _countryController.text = 'United States';
    
    // Add default invited members
    _invitedMembers = [
      {'name': 'Sandra Rivera', 'status': 'Joined', 'role': 'Parent'},
      {'name': 'Marcus Rivera', 'status': 'Invited', 'role': 'Sibling'},
    ];

    if (_isJoining) {
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
      _familyService.streamFamilyMembers(familyId).listen((members) {
        if (mounted) {
          setState(() {
            _existingMembersList = members;
          });
        }
      });
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
    if (_isJoining) {
      if (_selectedFamilyId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a family to join'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
        return;
      }
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
      final authService = AuthService();
      final avatarVal = _selectedAvatarIndex == 4
          ? _uploadedPhotoUrl ?? ''
          : 'waves_avatar_$_selectedAvatarIndex';

      if (_isJoining) {
        await _familyService.joinFamily(
          uid: widget.user.uid,
          username: widget.user.username,
          familyId: _selectedFamilyId!,
          role: widget.user.role ?? 'Member',
        );

        if (avatarVal.isNotEmpty) {
          await authService.updateProfile(profilePictureUrl: avatarVal);
        }

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
        await _familyService.createFamily(
          uid: widget.user.uid,
          username: widget.user.username,
          familyName: _familyNameController.text.trim(),
          country: _countryController.text.trim(),
          familyType: _familyTypeController.text.trim(),
          role: widget.user.role ?? 'Parent',
        );

        if (avatarVal.isNotEmpty) {
          await authService.updateProfile(profilePictureUrl: avatarVal);
        }

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
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.deepNavy),
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
          _isJoining ? 'Join Family' : 'Family Setup',
          style: const TextStyle(
            color: AppTheme.deepNavy,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Custom Stepper / Progress Bar matching the mockup with blue ombre gradient
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                child: Column(
                  children: [
                    Text(
                      '$_currentStep of 3',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textLight,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppTheme.lightBeige,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: _currentStep / 3,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryOmbre,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
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
            _isJoining ? 'Select your family.' : 'Name your family.',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppTheme.deepNavy,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isJoining
                ? 'Choose the family account you would like to join. Ensure you select the correct family.'
                : 'This name will appear on your Family Charter. Choose something meaningful.',
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textLight,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),

          if (_isJoining) ...[
            // Join fields
            const Text(
              'SELECT A FAMILY',
              style: TextStyle(
                fontSize: 11,
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
                      child: CircularProgressIndicator(color: AppTheme.oceanBlue),
                    ),
                  )
                : _availableFamilies.isEmpty
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppTheme.lightBeige,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.skyBlue.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.info_outline_rounded, color: AppTheme.oceanBlue, size: 28),
                            const SizedBox(height: 10),
                            const Text(
                              'No active families found in the database.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppTheme.deepNavy, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryOmbre,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _isJoining = false;
                                  });
                                },
                                icon: const Icon(Icons.add_home_rounded, size: 18, color: Colors.white),
                                label: const Text('Start a New Family', style: TextStyle(color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.lightBeige,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.skyBlue, width: 1.5),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedFamilyId,
                            isExpanded: true,
                            dropdownColor: AppTheme.lightBeige,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.oceanBlue),
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
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppTheme.deepNavy,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _familyNameController,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: AppTheme.deepNavy),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppTheme.lightBeige,
                hintText: 'e.g. The Rivera Family',
                prefixIcon: const Icon(Icons.family_restroom_rounded, color: AppTheme.oceanBlue),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppTheme.oceanBlue, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Examples: The Rivera Family · Our Growing Family · The Johnson-Lee Household',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textLight,
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
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.lightBeige,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _familyTypeController.text,
                            isExpanded: true,
                            dropdownColor: AppTheme.lightBeige,
                            items: _familyTypes.map((type) {
                              return DropdownMenuItem<String>(
                                value: type,
                                child: Text(type, style: const TextStyle(fontSize: 14, color: AppTheme.deepNavy)),
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
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _showCountryPickerDialog,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.lightBeige,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Text(_selectedCountry.flag,
                                  style: const TextStyle(fontSize: 18)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _selectedCountry.name,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textDark,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(Icons.keyboard_arrow_down_rounded,
                                  color: AppTheme.oceanBlue, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              ],
            ),
          ],

          const SizedBox(height: 28),

          // Avatar Picker Mockup with Avatar Photos and Blue Ombre accents
          Text(
            _isJoining ? 'CHOOSE YOUR AVATAR' : 'CHOOSE A FAMILY AVATAR',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppTheme.deepNavy,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Wave-styled avatar options
              ...List.generate(4, (index) {
                final isSelected = _selectedAvatarIndex == index;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedAvatarIndex = index;
                    });
                  },
                  child: Container(
                    width: (size.width - 56 - 48) / 5, // scaled to fit 5 options nicely
                    height: (size.width - 56 - 48) / 5,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? AppTheme.oceanBlue : Colors.transparent,
                        width: 3.0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppTheme.oceanBlue.withValues(alpha: 0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              )
                            ],
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child: Container(
                            width: double.infinity,
                            height: double.infinity,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: const AssetImage('assets/images/waves_bg.png'),
                                fit: BoxFit.cover,
                                alignment: index == 0
                                    ? Alignment.topLeft
                                    : index == 1
                                        ? Alignment.topRight
                                        : index == 2
                                            ? Alignment.bottomLeft
                                            : Alignment.bottomRight,
                              ),
                            ),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  index == 0
                                      ? Icons.face_rounded
                                      : index == 1
                                          ? Icons.face_3_rounded
                                          : index == 2
                                              ? Icons.face_6_rounded
                                              : Icons.family_restroom_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (isSelected)
                          Positioned(
                            top: 2,
                            right: 2,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: AppTheme.oceanBlue,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
              
              // Upload Photo slot
              GestureDetector(
                onTap: _simulatePhotoUpload,
                child: Container(
                  width: (size.width - 56 - 48) / 5,
                  height: (size.width - 56 - 48) / 5,
                  decoration: BoxDecoration(
                    color: AppTheme.lightBeige,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _selectedAvatarIndex == 4 ? AppTheme.oceanBlue : Colors.transparent,
                      width: 3.0,
                    ),
                    boxShadow: _selectedAvatarIndex == 4
                        ? [
                            BoxShadow(
                              color: AppTheme.oceanBlue.withValues(alpha: 0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            )
                          ],
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: _uploadedPhotoUrl != null
                            ? Image.network(
                                _uploadedPhotoUrl!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              )
                            : Container(
                                color: AppTheme.lightBeige,
                                child: const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_a_photo_rounded, color: AppTheme.oceanBlue, size: 20),
                                      SizedBox(height: 2),
                                      Text(
                                        'Upload',
                                        style: TextStyle(
                                          fontSize: 8,
                                          color: AppTheme.oceanBlue,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                      ),
                      if (_selectedAvatarIndex == 4)
                        Positioned(
                          top: 2,
                          right: 2,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: AppTheme.oceanBlue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 40),

          // Primary Actions using Blue Ombre Gradient
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.deepNavy, AppTheme.oceanBlue],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: AppTheme.modernShadow,
            ),
            child: ElevatedButton(
              onPressed: _handleStep2Submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isJoining ? 'Confirm & Continue' : 'This Is Our Family',
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
              child: const Text(
                'I\'ll set this up later',
                style: TextStyle(
                  color: AppTheme.textLight,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  decoration: TextDecoration.underline,
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
            _isJoining ? 'Meet the Family!' : 'Who\'s joining you?',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppTheme.deepNavy,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isJoining
                ? 'Here are the members already participating in the $_selectedFamilyName Family:'
                : 'Invite family members to participate. They can join anytime — even during Week 3.',
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textLight,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),

          if (!_isJoining) ...[
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
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.skyBlue.withValues(alpha: 0.3), width: 1.5),
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
                      icon: const Icon(Icons.copy_rounded, color: AppTheme.oceanBlue),
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
                  // Country code picker (only for phone tab)
                  if (_activeInviteTab == 0) ...[
                    GestureDetector(
                      onTap: _showPhoneCountryCodePicker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppTheme.lightBeige,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.skyBlue.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_selectedInvitePhoneCountry.flag,
                                style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 4),
                            Text(
                              _selectedInvitePhoneCountry.dialCode,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textDark,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(Icons.keyboard_arrow_down_rounded,
                                size: 14, color: AppTheme.textLight),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: TextFormField(
                      controller: _inviteInputController,
                      keyboardType: _activeInviteTab == 0
                          ? TextInputType.phone
                          : TextInputType.emailAddress,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppTheme.lightBeige,
                        hintText: _activeInviteTab == 0
                            ? '7XX XXX XXX'
                            : 'name@email.com',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.deepNavy, AppTheme.oceanBlue],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ElevatedButton(
                      onPressed: _sendInvite,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
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
                fontSize: 11,
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
                    color: AppTheme.lightBeige,
                    borderRadius: BorderRadius.circular(14),
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
                ? const Center(child: CircularProgressIndicator(color: AppTheme.oceanBlue))
                : _existingMembersList.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.lightBeige,
                          borderRadius: BorderRadius.circular(14),
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
                              borderRadius: BorderRadius.circular(14),
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

          const SizedBox(height: 40),

          // Primary action button using Blue Ombre Gradient
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.deepNavy, AppTheme.oceanBlue],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: AppTheme.modernShadow,
            ),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleStep3Submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isJoining ? 'Join Dashboard' : 'Start My Journey',
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
                _isJoining ? 'Skip overview' : 'Skip for now',
                style: const TextStyle(
                  color: AppTheme.textLight,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
          
          if (!_isJoining) ...[
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Invite more members from your dashboard at any time.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textLight,
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
                width: 2.5,
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
