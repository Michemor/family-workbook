import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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