import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();

  // Connect to Local Emulators
  const String host = '127.0.0.1'; // Use 10.0.2.2 if testing on Android Studio Emulator
  try {
    FirebaseAuth.instance.useAuthEmulator(host, 9099);
    FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
    print("Connected to Firebase Emulators");
  } catch (e) {
    print("Emulator connection error (might already be running): $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auth Flow Test',
      theme: ThemeData(primarySwatch: Colors.blue),
      
      home: Scaffold(
        appBar: AppBar(title: const Text('Firebase Auth Emulator Test')),
        body: const Center(child: Text('Firebase Auth Emulator Connected')),
      ),
    );
  }
}