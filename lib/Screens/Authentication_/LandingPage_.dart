import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:minorproject/API/_Apis.dart';
import 'package:minorproject/Helper/Dialogs_.dart';
import 'package:minorproject/Screens/HomeScreen_.dart';
import 'package:minorproject/Screens/Authentication_/ProfileSetupScreen_.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({Key? key}) : super(key: key);

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  bool _isSignInHovered = false;
  bool _isGetStartedHovered = false;
  bool _isLearnMoreHovered = false;

  // Google Authentication
  Future<UserCredential?> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      
      if (googleUser == null) {
        Dialogs.showSnackbar(context, 'Sign in cancelled');
        return null;
      }
      
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await APIs.auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      Dialogs.showSnackbar(context, 'Auth Error: ${e.message}');
      return null;
    } catch (e) {
      print('Sign In Error: $e');
      Dialogs.showSnackbar(context, 'Error: $e');
      return null;
    }
  }

  // Handle Google login
  void _handleGoogleBtnClick() {
    Dialogs.showProgressBar(context);
    _signInWithGoogle().then((user) async {
      Navigator.pop(context);
      if (user != null) {
        try {
          if ((await APIs.userExist())) {
            await APIs.getSelfinfo();
            // User exists, check if profile is completed
            final profileCompleted = await APIs.isProfileCompleted();
            if (profileCompleted) {
              // Profile completed, go to home
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (_) => const MyHomePage()));
            } else {
              // Profile not completed, go to setup
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileSetupScreen()));
            }
          } else {
            // New user, create user then go to setup
            await APIs.createUser().then((value) {
              APIs.getSelfinfo();
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const ProfileSetupScreen()));
            });
          }
        } catch (e) {
          print('Error during user check: $e');
          Dialogs.showSnackbar(context, 'Error: $e');
        }
      }
    }).catchError((e) {
      Navigator.pop(context);
      print('Sign In Error: $e');
      Dialogs.showSnackbar(context, 'Error: $e');
    });
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Decorative background elements
          Positioned(
            top: 60,
            left: 80,
            child: _buildDecorativeBox(120, const Color(0xFFFFE5E0)),
          ),
          Positioned(
            top: 120,
            right: 60,
            child: _buildDecorativeBox(100, const Color(0xFFFFD4CC)),
          ),
          Positioned(
            bottom: 200,
            left: 100,
            child: _buildDecorativeBox(80, const Color(0xFFFFE5E0)),
          ),
          Positioned(
            top: mq.height * 0.35,
            right: 80,
            child: _buildDecorativeBox(90, const Color(0xFFFFCCC2)),
          ),
          Positioned(
            bottom: 100,
            right: 120,
            child: _buildDecorativeBox(110, const Color(0xFFFFD4CC)),
          ),
          Positioned(
            top: mq.height * 0.5,
            left: 50,
            child: _buildDecorativeBox(70, const Color(0xFFFFE5E0)),
          ),

          // Main Content
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Header with Logo and Navigation
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Logo
                        Row(
                          children: [
                            Container(
                              width: 35,
                              height: 35,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE07856),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.chat_bubble,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'ChatUp',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        // Navigation buttons
                        Row(
                          children: [
                            _buildNavButton('Features', false),
                            const SizedBox(width: 20),
                            _buildNavButton('About', false),
                            const SizedBox(width: 20),
                            _buildSignInButton(),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Hero Section
                  SizedBox(height: mq.height * 0.08),

                  // Security Badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE8E0),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          color: Color(0xFFE07856),
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Secure & Private Messaging',
                          style: TextStyle(
                            color: Color(0xFFE07856),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Main Heading
                  const Text(
                    'Connect with',
                    style: TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      height: 1.2,
                    ),
                  ),
                  const Text(
                    'confidence',
                    style: TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE07856),
                      height: 1.2,
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Subtitle
                  const SizedBox(
                    width: 650,
                    child: Text(
                      'Designed with security in mind, using the latest encryption technology to protect your messages from prying eyes.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.black54,
                        height: 1.6,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // CTA Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Get Started Button
                      MouseRegion(
                        onEnter: (_) =>
                            setState(() => _isGetStartedHovered = true),
                        onExit: (_) =>
                            setState(() => _isGetStartedHovered = false),
                        child: GestureDetector(
                          onTap: _handleGoogleBtnClick,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 35, vertical: 18),
                            decoration: BoxDecoration(
                              color: _isGetStartedHovered
                                  ? const Color(0xFFD06845)
                                  : const Color(0xFFE07856),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: _isGetStartedHovered
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFFE07856)
                                            .withOpacity(0.4),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Get Started Free',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 20),

                      // Learn More Button
                      MouseRegion(
                        onEnter: (_) =>
                            setState(() => _isLearnMoreHovered = true),
                        onExit: (_) =>
                            setState(() => _isLearnMoreHovered = false),
                        child: GestureDetector(
                          onTap: () {
                            // Add learn more functionality here
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 35, vertical: 18),
                            decoration: BoxDecoration(
                              color: _isLearnMoreHovered
                                  ? const Color(0xFFF5F5F5)
                                  : Colors.white,
                              border: Border.all(
                                color: _isLearnMoreHovered
                                    ? const Color(0xFFE07856)
                                    : Colors.black12,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Learn More',
                              style: TextStyle(
                                color: _isLearnMoreHovered
                                    ? const Color(0xFFE07856)
                                    : Colors.black87,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: mq.height * 0.12),

                  // Stats Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStatCard('10M+', 'Active Users'),
                      const SizedBox(width: 100),
                      _buildStatCard('99.9%', 'Uptime'),
                      const SizedBox(width: 100),
                      _buildStatCard('256-bit', 'Encryption'),
                    ],
                  ),

                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton(String text, bool isActive) {
    return TextButton(
      onPressed: () {},
      child: Text(
        text,
        style: TextStyle(
          color: isActive ? Colors.black87 : Colors.black54,
          fontSize: 16,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildSignInButton() {
    return MouseRegion(
      onEnter: (_) => setState(() => _isSignInHovered = true),
      onExit: (_) => setState(() => _isSignInHovered = false),
      child: GestureDetector(
        onTap: _handleGoogleBtnClick,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
          decoration: BoxDecoration(
            color: _isSignInHovered
                ? const Color(0xFFE07856)
                : Colors.transparent,
            border: Border.all(
              color: const Color(0xFFE07856),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Sign In',
            style: TextStyle(
              color: _isSignInHovered ? Colors.white : const Color(0xFFE07856),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String number, String label) {
    return Column(
      children: [
        Text(
          number,
          style: const TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildDecorativeBox(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}
