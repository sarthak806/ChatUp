import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:minorproject/API/_Apis.dart';
import 'package:minorproject/Screens/Authentication_/LandingPage_.dart';
import 'package:minorproject/Screens/Authentication_/ProfileSetupScreen_.dart';
import 'package:minorproject/Screens/HomeScreen_.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  StreamSubscription<User?>? _authSub;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _setSystemUi();
    _authSub = APIs.auth.authStateChanges().listen((user) async {
      if (_navigated) return;
      _navigated = true;

      if (user != null) {
        // User is logged in, check if profile is completed
        final userExists = await APIs.userExist();
        if (userExists) {
          final profileCompleted = await APIs.isProfileCompleted();
          if (profileCompleted) {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const MyHomePage()));
          } else {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const ProfileSetupScreen()));
          }
        } else {
          // User doesn't exist in database, go to landing page
          await APIs.auth.signOut();
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const LandingPage()));
        }
      } else {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const LandingPage()));
      }
    });
  }

  void _setSystemUi() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.white, statusBarColor: Colors.white));
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //initializing media query (for getting device screen size)
    var mq = MediaQuery.of(context).size;

    return Scaffold(
        //body
        body: SingleChildScrollView(
      child: Center(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 450),
              child: const Image(
                image: AssetImage('Assets/Images/AppIcon.png'),
              ),
            ),
            Container(
                margin: const EdgeInsets.only(top: 10),
                child: const Image(
                    image: AssetImage('Assets/Images/Logo_Text.png'))),
            Container(
                width: 300,
                margin: const EdgeInsets.only(top: 420),
                child: const Image(
                    image: AssetImage('Assets/Images/Base_Text.png'))),
            Container(
                width: 110,
                margin: const EdgeInsets.only(top: 10),
                child: const Image(
                    image: AssetImage('Assets/Images/Base_Icons.png'))),
          ],
        ),
      ),
    ));
  }
}
