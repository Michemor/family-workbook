import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/family_service.dart';

class TestFamilySetupScreen extends StatefulWidget {
  final User user;
  final Map<String, dynamic> userData;

  const TestFamilySetupScreen({
    super.key,
    required this.user,
    required this.userData,
  });

  @override
  State<TestFamilySetupScreen> createState() => _TestFamilySetupScreenState();
}

class _TestFamilySetupScreenState extends State<TestFamilySetupScreen> {
  final _familyService = FamilyService();
  String _status = "Ready to create family";

  Future<void> _create() async {
    setState(() => _status = "Creating family via batch write...");
    try {
      await _familyService.createFamily(
        uid: widget.user.uid,
        username: widget.userData['displayName'] ?? "Test Admin",
        familyName: "The Test Family",
        familyType: "Nuclear",
        country: "Kenya",
        role: "Admin",
      );
      // Force a hot restart or trigger a state rebuild in main.dart to see the dashboard
      setState(() => _status = "✅ Success! Restart app to see Dashboard.");
    } catch (e) {
      setState(() => _status = "❌ Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("2. Test Family Setup Endpoint")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Logged in as: ${widget.user.email}"),
            const SizedBox(height: 20),
            Text(_status, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _create,
              child: const Text("TEST CREATE FAMILY"),
            ),
          ],
        ),
      ),
    );
  }
}
