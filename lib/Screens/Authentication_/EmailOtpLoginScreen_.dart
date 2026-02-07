import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../API/_Apis.dart';
import '../HomeScreen_.dart';

class EmailOtpLoginScreen extends StatefulWidget {
  const EmailOtpLoginScreen({super.key});

  @override
  State<EmailOtpLoginScreen> createState() => _EmailOtpLoginScreenState();
}

class _EmailOtpLoginScreenState extends State<EmailOtpLoginScreen> {
  final _emailCtrl = TextEditingController();
  bool _sending = false;
  bool _checkingLink = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    _checkIncomingEmailLink();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkIncomingEmailLink() async {
    final auth = FirebaseAuth.instance;
    final link = Uri.base.toString();
    if (!auth.isSignInWithEmailLink(link)) return;

    setState(() => _checkingLink = true);
    final prefs = await SharedPreferences.getInstance();
    final storedEmail = prefs.getString('pendingEmailForLink');

    if (storedEmail == null) {
      setState(() {
        _status = 'Open the link on the same device where you requested it.';
        _checkingLink = false;
      });
      return;
    }

    try {
      final credential = await auth.signInWithEmailLink(
        email: storedEmail,
        emailLink: link,
      );

      await APIs.getSelfinfo();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MyHomePage()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _status = 'Sign-in failed: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _status = 'Unexpected error: $e';
      });
    } finally {
      setState(() => _checkingLink = false);
    }
  }

  Future<void> _sendEmailLink() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _status = 'Please enter a valid email.');
      return;
    }

    final auth = FirebaseAuth.instance;
    setState(() {
      _sending = true;
      _status = null;
    });

    const continueUrl = 'https://chatrealnotfake.firebaseapp.com/email-signin';

    final settings = ActionCodeSettings(
      url: continueUrl,
      handleCodeInApp: true,
      androidPackageName: 'com.example.minorproject', // ignored on web; replace later for Android
      androidInstallApp: true,
      androidMinimumVersion: '21',
      iOSBundleId: 'com.example.minorproject', // ignored on web; replace later for iOS
    );

    try {
      await auth.sendSignInLinkToEmail(email: email, actionCodeSettings: settings);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pendingEmailForLink', email);
      setState(() {
        _status = 'Email sent. Open the link on this device to finish sign-in.';
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _status = e.message ?? 'Failed to send email.';
      });
    } catch (e) {
      setState(() {
        _status = 'Unexpected error: $e';
      });
    } finally {
      setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'Email Sign-In',
          style: TextStyle(color: Colors.black87),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            const Text(
              'Sign in with a one-time link sent to your email.',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email address',
                hintText: 'name@example.com',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _sending ? null : _sendEmailLink,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE07856),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _sending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Send Sign-In Link',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            if (_status != null)
              Text(
                _status!,
                style: const TextStyle(color: Colors.black87),
              ),
            if (_checkingLink) ...[
              const SizedBox(height: 20),
              const Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 10),
                  Text('Finishing sign-in...'),
                ],
              )
            ],
          ],
        ),
      ),
    );
  }
}
