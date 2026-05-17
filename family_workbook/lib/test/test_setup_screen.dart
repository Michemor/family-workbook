import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/family_service.dart';

class TestSetupScreen extends StatefulWidget {
  const TestSetupScreen({Key? key}) : super(key: key);

  @override
  State<TestSetupScreen> createState() => _TestSetupScreenState();
}

class _TestSetupScreenState extends State<TestSetupScreen> {
  final _authService = AuthService();
  final _familyService = FamilyService();

  // Controllers for our inputs
  final _emailController = TextEditingController(text: "test@family.com");
  final _passwordController = TextEditingController(text: "password123");
  final _nameController = TextEditingController(text: "Martin");
  final _familyNameController = TextEditingController(text: "The Martins");
  final _familyTypeController = TextEditingController(text: "Nuclear");
  final _countryController = TextEditingController(text: "Kenya");
  
  bool _isLoading = false;
  String _statusMessage = "Ready to test.";

  Future<void> _runTest() async {
    setState(() {
      _isLoading = true;
      _statusMessage = "1. Registering User...";
    });

    try {
      // Step 1: Auth
      var user = await _authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        username: _nameController.text.trim(),
      );

      if (user != null) {
        setState(() => _statusMessage = "2. User created! Building Family...");

        // Step 2: Family Setup
        String familyId = await _familyService.createFamily(
          uid: user.uid,
          username: user.username,
          familyName: _familyNameController.text.trim(),
          familyType: _familyTypeController.text.trim(),
          country: _countryController.text.trim(),
          role: "Father", // Default test role
        );

        setState(() => _statusMessage = "✅ Success! Family ID: $familyId");
      }
    } catch (e) {
      setState(() => _statusMessage = "❌ Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Firebase Emulator Test")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: "Email")),
            TextField(controller: _passwordController, decoration: const InputDecoration(labelText: "Password")),
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Your Name")),
            const Divider(height: 40),
            TextField(controller: _familyNameController, decoration: const InputDecoration(labelText: "Family Name")),
            TextField(controller: _familyTypeController, decoration: const InputDecoration(labelText: "Family Type")),
            TextField(controller: _countryController, decoration: const InputDecoration(labelText: "Country")),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _runTest,
              child: _isLoading ? const CircularProgressIndicator() : const Text("Run Setup Flow"),
            ),
            const SizedBox(height: 20),
            Text(_statusMessage, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}