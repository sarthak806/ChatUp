import 'package:flutter/material.dart';
import 'package:minorproject/Screens/Splash_.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

late Size mq;

void main() async {
/* Returns an instance of the WidgetsBinding, creating and initializing it if necessary.
If one is created, it will be a WidgetsFlutterBinding. If one was previously initialized,
then it will at least implement WidgetsBinding. */
  WidgetsFlutterBinding.ensureInitialized();
  /* Firebase initialization */
  await _initializeFirebase();
  // Sign out all users on app start
  await FirebaseAuth.instance.signOut();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}

/* Initialize firebase connection by main thread */
Future<void> _initializeFirebase() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}
