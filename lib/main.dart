import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitora/core/theme/app_theme.dart';
import 'package:fitora/routes/app_routes.dart';
import 'package:fitora/screens/splash/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
    debugPrint('Firebase initialized successfully!');
    _testFirebaseConnection();
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  runApp(const FitoraApp());
}

Future<void> _testFirebaseConnection() async {
  try {
    final docRef = await FirebaseFirestore.instance.collection('test').add({
      'name': 'Fitora Test User',
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'Firebase connected',
    });
    debugPrint('Firebase test successful! Document written with ID: ${docRef.id}');
  } catch (e) {
    debugPrint('Firebase test failed: $e');
  }
}

class FitoraApp extends StatelessWidget {
  const FitoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fitora',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.generateRoute,
      home: const SplashScreen(),
    );
  }
}
