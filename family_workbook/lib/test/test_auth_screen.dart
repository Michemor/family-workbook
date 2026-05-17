import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class TestAuthScreen extends StatefulWidget {
  const TestAuthScreen({Key? key}) : super(key: key);

  @override
  State<TestAuthScreen> createState() => _TestAuthScreenState();
}

class _TestAuthScreenState extends State<TestAuthScreen> {
  final _authService = AuthService();
  String _status = "Ready";

  Future<void> _signUp() async {
    setState(() => _status = "Signing up...");
    try {
      await _authService.signUp(
        email: "testuser@example.com",
        password: "password123",
        username: "Test User",
      );
      setState(() => _status = "Sign Up Success!");
    } catch (e) {
      setState(() => _status = "Error: $e");
    }
  }

  Future<void> _signIn() async {
    setState(() => _status = "Signing in...");
    try {
      await _authService.signIn(
        email: "testuser@example.com",
        password: "password123",
      );
      setState(() => _status = "Sign In Success!");
    } catch (e) {
      setState(() => _status = "Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("1. Test Auth Endpoint")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_status, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _signUp, child: const Text("TEST SIGN UP")),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: _signIn, child: const Text("TEST SIGN IN")),
          ],
        ),
      ),
    );
  }
}