import 'package:flutter/material.dart';
import 'package:minorproject/API/_Apis.dart';
import 'package:minorproject/Helper/Dialogs_.dart';
import 'package:minorproject/Screens/HomeScreen_.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({Key? key}) : super(key: key);

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _aboutController = TextEditingController();
  bool _isNotRobot = false;
  bool _isLoading = false;
  bool _isCheckingUsername = false;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  Future<bool> _isUsernameUnique(String username) async {
    if (username.trim().isEmpty) return false;
    
    try {
      final querySnapshot = await APIs.firestore
          .collection('users')
          .where('username', isEqualTo: username.trim())
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isEmpty) return true;

      final existingDoc = querySnapshot.docs.first;
      if (existingDoc.id == APIs.user.uid) return true;

      return false;
    } catch (e) {
      print('Error checking username: $e');
      return false;
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_isNotRobot) {
      Dialogs.showSnackbar(context, 'Please confirm you are not a robot');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final username = _usernameController.text.trim();
      
      // Double-check username uniqueness before saving
      final isUnique = await _isUsernameUnique(username);
      if (!isUnique) {
        Dialogs.showSnackbar(context, 'Username is already taken');
        setState(() => _isLoading = false);
        return;
      }

      // Update user profile
      await APIs.firestore.collection('users').doc(APIs.user.uid).update({
        'name': _nameController.text.trim(),
        'username': username,
        'about': _aboutController.text.trim(),
        'profileCompleted': true,
      });

      await APIs.getSelfinfo();

      setState(() => _isLoading = false);

      // Navigate to home screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MyHomePage()),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error saving profile: $e');
      Dialogs.showSnackbar(context, 'Error saving profile: $e');
    }
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
            bottom: 100,
            right: 120,
            child: _buildDecorativeBox(110, const Color(0xFFFFD4CC)),
          ),

          // Main Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(40),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header
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

                        const SizedBox(height: 50),

                        // Title
                        const Text(
                          'Complete Your Profile',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),

                        const SizedBox(height: 12),

                        const Text(
                          'Please provide the following information to set up your profile',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Full Name Field
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Full Name *',
                            labelStyle: const TextStyle(color: Colors.black54),
                            prefixIcon: const Icon(Icons.person_outline,
                                color: Color(0xFFE07856)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.black12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.black12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: Color(0xFFE07856), width: 2),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.red),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Colors.red, width: 2),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Full name is required';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        // Username Field
                        TextFormField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            labelText: 'Username *',
                            labelStyle: const TextStyle(color: Colors.black54),
                            prefixIcon: const Icon(Icons.alternate_email,
                                color: Color(0xFFE07856)),
                            suffixIcon: _isCheckingUsername
                                ? const Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.black12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.black12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: Color(0xFFE07856), width: 2),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.red),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Colors.red, width: 2),
                            ),
                            helperText: 'Username must be unique',
                            helperStyle:
                                const TextStyle(fontSize: 12, color: Colors.black45),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Username is required';
                            }
                            if (value.trim().length < 3) {
                              return 'Username must be at least 3 characters';
                            }
                            if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value.trim())) {
                              return 'Username can only contain letters, numbers, and underscores';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            if (value.trim().length >= 3) {
                              // Debounce username check
                              Future.delayed(const Duration(milliseconds: 500), () async {
                                if (_usernameController.text == value) {
                                  setState(() => _isCheckingUsername = true);
                                  await _isUsernameUnique(value.trim());
                                  setState(() => _isCheckingUsername = false);
                                }
                              });
                            }
                          },
                        ),

                        const SizedBox(height: 20),

                        // About Field
                        TextFormField(
                          controller: _aboutController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'About *',
                            labelStyle: const TextStyle(color: Colors.black54),
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(bottom: 60),
                              child: Icon(Icons.info_outline,
                                  color: Color(0xFFE07856)),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.black12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.black12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: Color(0xFFE07856), width: 2),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.red),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Colors.red, width: 2),
                            ),
                            helperText: 'Tell us a bit about yourself',
                            helperStyle:
                                const TextStyle(fontSize: 12, color: Colors.black45),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'About is required';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 30),

                        // I'm not a robot checkbox
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _isNotRobot
                                  ? const Color(0xFFE07856)
                                  : Colors.black12,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          child: CheckboxListTile(
                            title: const Text(
                              'I am not a robot',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                            value: _isNotRobot,
                            onChanged: (value) {
                              setState(() => _isNotRobot = value ?? false);
                            },
                            activeColor: const Color(0xFFE07856),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Submit Button
                        SizedBox(
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE07856),
                              disabledBackgroundColor: Colors.grey,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Complete Setup',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
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
