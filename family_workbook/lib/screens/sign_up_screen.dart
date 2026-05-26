import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/password_validator.dart';
import '../utils/country_data.dart';
import '../services/auth_service.dart';
import 'sign_in_screen.dart';
import 'family_setup_screen.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/country_data.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  Map<String, bool> _passwordRequirements = {};

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isJoining = false;
  CountryData _selectedPhoneCountry = CountryData.fromCode('US');
  String? _selectedPersonalityType;

  final List<String> _personalityTypes = [
    'ISTJ', 'ISFJ', 'INFJ', 'INTJ',
    'ISTP', 'ISFP', 'INFP', 'INTP',
    'ESTP', 'ESFP', 'ENFP', 'ENTP',
    'ESTJ', 'ESFJ', 'ENFJ', 'ENTJ',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() {
      final password = _passwordController.text;
      setState(() {
        _passwordRequirements = PasswordValidator.getRequirements(password);
      });
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handleSignUp() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Passwords do not match'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
        return;
      }
      if (_selectedPersonalityType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select your personality type.')),
        );
        return;
      }

      setState(() => _isLoading = true);
      try {
        // Step 1: Create user auth account and firestore document
        final user = await _authService.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          username: _usernameController.text.trim(),
          phoneNumber: '${_selectedPhoneCountry.dialCode}${_phoneController.text}',
          personalityType: _selectedPersonalityType,
        );

        if (user != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created successfully! Let\'s set up your family.'),
              backgroundColor: AppTheme.successGreen,
            ),
          );
          // Navigate to FamilySetupScreen
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => FamilySetupScreen(
                isJoining: _isJoining,
                user: user,
              ),
            ),
            (route) => false,
          );
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Registration failed. Please try again.'),
                backgroundColor: AppTheme.errorRed,
              ),
            );
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
  }

  void _updatePasswordRequirements(String password) {
    setState(() {
      _passwordRequirements = PasswordValidator.getRequirements(password);
    });
  }

  void _showCountryCodePicker() {
    final searchController = TextEditingController();
    List<CountryData> filtered = CountryData.all;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.white,
            title: const Text(
              'Select Country Code',
              style: TextStyle(color: AppTheme.deepNavy, fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: 340,
              height: 420,
              child: Column(
                children: [
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search country...',
                      prefixIcon: const Icon(Icons.search, color: AppTheme.oceanBlue),
                      filled: true,
                      fillColor: AppTheme.lightBeige,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    ),
                    onChanged: (query) {
                      setDialogState(() {
                        filtered = CountryData.all
                            .where((c) =>
                                c.name.toLowerCase().contains(query.toLowerCase()) ||
                                c.dialCode.contains(query))
                            .toList();
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final country = filtered[i];
                        final isSelected = country.code == _selectedPhoneCountry.code;
                        return ListTile(
                          dense: true,
                          leading: Text(country.flag, style: const TextStyle(fontSize: 22)),
                          title: Text(
                            country.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? AppTheme.oceanBlue : AppTheme.textDark,
                            ),
                          ),
                          trailing: Text(
                            country.dialCode,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? AppTheme.oceanBlue : AppTheme.textLight,
                            ),
                          ),
                          tileColor: isSelected ? AppTheme.lightBeige : null,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          onTap: () {
                            setState(() {
                              _selectedPhoneCountry = country;
                            });
                            Navigator.of(context).pop();
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryOmbre,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child: Column(
              children: [
                // Header Section
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppTheme.primaryColor,
                              AppTheme.primaryColor.withValues(alpha: 0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.home_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Create Account',
                        style: Theme.of(context)
                            .textTheme
                            .displayLarge!
                            .copyWith(fontSize: 26),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Start your family transformation journey',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                // Form Section
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(28.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Full Name Field
                          _buildFormLabel('Full Name'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _usernameController,
                            decoration: InputDecoration(
                              prefixIcon: Icon(
                                Icons.person_outline,
                                color: AppTheme.primaryColor,
                              ),
                              hintText: 'John Smith',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your full name';
                              }
                              if (value.length < 2) {
                                return 'Name must be at least 2 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // Email Field
                          _buildFormLabel('Email'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              prefixIcon: Icon(
                                Icons.email_outlined,
                                color: AppTheme.primaryColor,
                              ),
                              hintText: 'your@email.com',
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!RegExp(
                                      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
                                  .hasMatch(value)) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // Password Field
                          _buildFormLabel('Password'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _passwordController,
                            onChanged: _updatePasswordRequirements,
                            decoration: InputDecoration(
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                color: AppTheme.primaryColor,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: AppTheme.primaryColor,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            obscureText: _obscurePassword,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a password';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          // Password Requirements
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.lightBeige,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Password Requirements:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildRequirementItem(
                                  'At least 6 characters',
                                  _passwordRequirements['length'] ?? false,
                                ),
                                _buildRequirementItem(
                                  'Uppercase letter (A-Z)',
                                  _passwordRequirements['uppercase'] ?? false,
                                ),
                                _buildRequirementItem(
                                  'Lowercase letter (a-z)',
                                  _passwordRequirements['lowercase'] ?? false,
                                ),
                                _buildRequirementItem(
                                  'Number (0-9)',
                                  _passwordRequirements['number'] ?? false,
                                ),
                                _buildRequirementItem(
                                  'Symbol (!@#\$%^&*)',
                                  _passwordRequirements['symbol'] ?? false,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Confirm Password Field
                          _buildFormLabel('Confirm Password'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _confirmPasswordController,
                            decoration: InputDecoration(
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                color: AppTheme.primaryColor,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: AppTheme.primaryColor,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword;
                                  });
                                },
                              ),
                            ),
                            obscureText: _obscureConfirmPassword,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your password';
                              }
                              if (value != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // Phone Number Field
                          _buildFormLabel('Phone Number (Optional)'),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              // Country code picker button
                              GestureDetector(
                                onTap: () => _showCountryCodePicker(),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: AppTheme.lightBeige,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppTheme.softTan.withValues(alpha: 0.5)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(_selectedPhoneCountry.flag, style: const TextStyle(fontSize: 20)),
                                      const SizedBox(width: 4),
                                      Text(
                                        _selectedPhoneCountry.dialCode,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textDark,
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppTheme.textLight),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  decoration: const InputDecoration(
                                    hintText: '7XX XXX XXX',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Family Path Option Section
                          Text(
                            'Choose Family Option',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isJoining = false;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                                    decoration: BoxDecoration(
                                      gradient: !_isJoining ? AppTheme.primaryOmbre : null,
                                      color: _isJoining ? Colors.white : null,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: !_isJoining 
                                            ? AppTheme.deepNavy 
                                            : AppTheme.softTan.withValues(alpha: 0.4),
                                        width: 2,
                                      ),
                                      boxShadow: !_isJoining ? AppTheme.modernShadow : null,
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.add_home_rounded,
                                          color: !_isJoining ? Colors.white : AppTheme.textLight,
                                          size: 32,
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          'Start Family',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: !_isJoining ? Colors.white : AppTheme.textDark,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Create a new account for your home',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: !_isJoining 
                                                ? Colors.white.withValues(alpha: 0.9) 
                                                : AppTheme.textLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isJoining = true;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                                    decoration: BoxDecoration(
                                      gradient: _isJoining ? AppTheme.primaryOmbre : null,
                                      color: !_isJoining ? Colors.white : null,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: _isJoining 
                                            ? AppTheme.deepNavy 
                                            : AppTheme.softTan.withValues(alpha: 0.4),
                                        width: 2,
                                      ),
                                      boxShadow: _isJoining ? AppTheme.modernShadow : null,
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.group_add_rounded,
                                          color: _isJoining ? Colors.white : AppTheme.textLight,
                                          size: 32,
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          'Join Family',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: _isJoining ? Colors.white : AppTheme.textDark,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Connect to an existing family space',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: _isJoining 
                                                ? Colors.white.withValues(alpha: 0.9) 
                                                : AppTheme.textLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          // Create Account Button
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
                              onPressed: _isLoading ? null : _handleSignUp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                              ),
                              child: _isLoading
                                  ? const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 10),
                                        Text('Creating Account...'),
                                      ],
                                    )
                                  : const Text(
                                      'Create Account',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Sign In Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Already have an account? ',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const SignInScreen(),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Sign In',
                                  style: TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppTheme.textDark,
      ),
    );
  }

  Widget _buildRequirementItem(String text, bool isValid) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: isValid ? AppTheme.successGreen : AppTheme.textLight,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: isValid ? AppTheme.successGreen : AppTheme.textLight,
                fontWeight: isValid ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalityTestSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Personality Type',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Please take the personality test and select your type below. This is a required step.',
          style: TextStyle(fontSize: 14, color: AppTheme.textLight),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final url = Uri.parse('https://personality.co/personality-test?gclid=CjwKCAjwn4vQBhBsEiwAq3hhN1aeXIzeAPdhygjVHyd26JPJFMTx_7jZNitu0k_zp1dnvHFRaf3pKxoCSp4QAvD_BwE&utm_source=google&utm_medium=cpc&utm_campaign=23296896410&utm_content=187856916654&utm_term=personality%20test&matchtype=e&device=c&gad_source=1&gad_campaignid=23296896410&gbraid=0AAAABCDT4dxvFttUTTi0xilc8jhWRG01l&gclid=CjwKCAjwn4vQBhBsEiwAq3hhN1aeXIzeAPdhygjVHyd26JPJFMTx_7jZNitu0k_zp1dnvHFRaf3pKxoCSp4QAvD_BwE');
            if (await canLaunchUrl(url)) {
              await launchUrl(url, mode: LaunchMode.externalApplication);
            }
          },
          child: const Text(
            'Take the Personality Test Here',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.primaryColor,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedPersonalityType,
          hint: const Text('Select Your Personality Type'),
          isExpanded: true,
          onChanged: (String? newValue) {
            setState(() {
              _selectedPersonalityType = newValue;
            });
          },
          items: _personalityTypes.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          validator: (value) => value == null ? 'Please select a personality type' : null,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFamilyOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Family Options
        Text(
          'Choose Family Option',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isJoining = false;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                  decoration: BoxDecoration(
                    gradient: !_isJoining ? AppTheme.primaryOmbre : null,
                    color: _isJoining ? Colors.white : null,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: !_isJoining 
                          ? AppTheme.deepNavy 
                          : AppTheme.softTan.withValues(alpha: 0.4),
                      width: 2,
                    ),
                    boxShadow: !_isJoining ? AppTheme.modernShadow : null,
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.add_home_rounded,
                        color: !_isJoining ? Colors.white : AppTheme.textLight,
                        size: 32,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Start Family',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: !_isJoining ? Colors.white : AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Create a new account for your home',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: !_isJoining 
                              ? Colors.white.withValues(alpha: 0.9) 
                              : AppTheme.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isJoining = true;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                  decoration: BoxDecoration(
                    gradient: _isJoining ? AppTheme.primaryOmbre : null,
                    color: !_isJoining ? Colors.white : null,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isJoining 
                          ? AppTheme.deepNavy 
                          : AppTheme.softTan.withValues(alpha: 0.4),
                      width: 2,
                    ),
                    boxShadow: _isJoining ? AppTheme.modernShadow : null,
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.group_add_rounded,
                        color: _isJoining ? Colors.white : AppTheme.textLight,
                        size: 32,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Join Family',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: _isJoining ? Colors.white : AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Connect to an existing family space',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: _isJoining 
                              ? Colors.white.withValues(alpha: 0.9) 
                              : AppTheme.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}
