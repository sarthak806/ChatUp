import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// kIsWeb
import 'package:minorproject/Helper/Dialogs_.dart';
import 'package:minorproject/Screens/Authentication_/OtpVerificationScreen_.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({Key? key}) : super(key: key);

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _selectedCountryCode = '+91';
  bool _isLoading = false;

  final List<Map<String, String>> _countryCodes = [
    {'code': '+91', 'country': 'India'},
    {'code': '+1', 'country': 'USA'},
    {'code': '+44', 'country': 'UK'},
    {'code': '+61', 'country': 'Australia'},
    {'code': '+971', 'country': 'UAE'},
    {'code': '+65', 'country': 'Singapore'},
    {'code': '+60', 'country': 'Malaysia'},
    {'code': '+86', 'country': 'China'},
    {'code': '+81', 'country': 'Japan'},
    {'code': '+82', 'country': 'South Korea'},
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendOTP() async {
    final phoneNumber = _phoneController.text.trim();

    if (phoneNumber.isEmpty) {
      Dialogs.showSnackbar(context, 'Please enter phone number');
      return;
    }

    if (phoneNumber.length < 10) {
      Dialogs.showSnackbar(context, 'Please enter a valid phone number');
      return;
    }

    setState(() => _isLoading = true);

    final fullPhoneNumber = _selectedCountryCode + phoneNumber;

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: fullPhoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {},
        verificationFailed: (FirebaseAuthException e) {
          setState(() => _isLoading = false);
          Dialogs.showSnackbar(context, 'Error: ${e.message}');
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() => _isLoading = false);
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OtpVerificationScreen(
                verificationId: verificationId,
                phoneNumber: fullPhoneNumber,
              ),
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      Dialogs.showSnackbar(context, 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: mq.height * 0.05),

              const Text(
                'Phone Login',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              const Text(
                'Enter your phone number to receive an OTP',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),

              SizedBox(height: mq.height * 0.08),

              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFE5E0),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.phone_android,
                    size: 60,
                    color: Color(0xFFFF6B6B),
                  ),
                ),
              ),

              SizedBox(height: mq.height * 0.08),

              const Text('Phone Number'),

              const SizedBox(height: 10),

              Row(
                children: [
                  DropdownButton<String>(
                    value: _selectedCountryCode,
                    items: _countryCodes.map((country) {
                      return DropdownMenuItem<String>(
                        value: country['code'],
                        child: Text('${country['code']} ${country['country']}'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedCountryCode = value!);
                    },
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        hintText: '1234567890',
                        prefixIcon: Icon(Icons.phone),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: mq.height * 0.05),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendOTP,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Send OTP'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
