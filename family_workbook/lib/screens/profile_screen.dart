import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/family_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/family_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _familyService = FamilyService();
  final _formKey = GlobalKey<FormState>();
  final _personalityController = TextEditingController();
  
  UserModel? _user;
  FamilyModel? _family;
  bool _isLoading = true;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _loadUserData();
    if (_user?.familyId != null) {
      await _loadFamilyData(_user!.familyId!);
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserData() async {
    final user = await _authService.getCurrentUser();
    if (user != null) {
      setState(() {
        _user = user;
        _personalityController.text = user.personalityType ?? '';
      });
    }
  }

  Future<void> _loadFamilyData(String familyId) async {
    final family = await _familyService.getFamilyById(familyId);
    if (family != null) {
      setState(() {
        _family = family;
      });
    }
  }

  @override
  void dispose() {
    _personalityController.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      await _authService.updateProfile(
        personalityType: _personalityController.text,
      );
      await _loadUserData(); // Reload user data to reflect changes
      setState(() {
        _isLoading = false;
        _isEditing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
              ? const Center(child: Text('User not found.'))
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildProfileHeader(),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            // Personality Type
                            _buildPersonalitySection(),

                            const SizedBox(height: 16),

                            // Family Details
                            _buildFamilyDetails(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF9D4EDD),
            const Color(0xFF7209B7),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: _user?.profilePictureUrl != null
                ? NetworkImage(_user!.profilePictureUrl!)
                : null,
            child: _user?.profilePictureUrl == null
                ? const Icon(Icons.person, size: 50)
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            _user?.username ?? 'Username',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            _user?.email ?? 'email@example.com',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalitySection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Personality Type',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: Icon(_isEditing ? Icons.save : Icons.edit),
                    onPressed: _isEditing ? _saveProfile : _toggleEdit,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _isEditing
                  ? TextFormField(
                      controller: _personalityController,
                      decoration: const InputDecoration(
                        labelText: 'Enter your personality type',
                        hintText: 'e.g., INFJ, ENTP, etc.',
                      ),
                      validator: (value) {
                        // This field is optional, so no validation needed
                        return null;
                      },
                    )
                  : Text(
                      _user?.personalityType?.isEmpty ?? true
                          ? 'No personality type set.'
                          : _user!.personalityType!,
                      style: const TextStyle(fontSize: 16),
                    ),
              if (_isLoading) const Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFamilyDetails() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _family == null
            ? const Text('Not part of a family yet.')
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Family Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow('Family Name:', _family?.familyName ?? 'N/A'),
                  _buildDetailRow('Family Type:', _family?.familyType ?? 'N/A'),
                  _buildDetailRow('Country:', _family?.country ?? 'N/A'),
                  _buildDetailRow(
                      'Members:', _family?.members.length.toString() ?? '0'),
                ],
              ),
      ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
