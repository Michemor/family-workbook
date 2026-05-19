import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TestDashboardScreen extends StatelessWidget {
  final String familyId;

  const TestDashboardScreen({super.key, required this.familyId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("3. Test Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: Center(
        child: Text(
          "✅ Endpoints Working!\n\nYou are successfully linked to:\n$familyId",
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
