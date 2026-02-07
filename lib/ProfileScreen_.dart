// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:minorproject/API/_Apis.dart';
import 'package:minorproject/Screens/Authentication_/LandingPage_.dart';
import 'Constants/Colors_.dart';
import 'Helper/Dialogs_.dart';
import 'Models/Chat_user.dart';

class ProfileScreen extends StatefulWidget {
  final ChatUser user;

  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _aboutController;
  String? _image;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _aboutController = TextEditingController(text: widget.user.about);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: ColorConstants.mainAppColour,
        onPressed: () async {
          Dialogs.showProgressBar(context);
          await APIs.auth.signOut();
          await GoogleSignIn().signOut();
          Navigator.pop(context); // close progress dialog
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LandingPage()),
            (route) => false,
          );
        },
        icon: const Icon(Icons.logout),
        label: const Text('Logout'),
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.only(left: 20, right: 20),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 200),
                    child: Stack(
                      children: [
                        _image != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(100),
                                child: Image.file(
                                  File(_image!),
                                  width: 170,
                                  height: 170,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(100),
                                child: CachedNetworkImage(
                                  width: 170,
                                  height: 170,
                                  fit: BoxFit.cover,
                                  imageUrl: widget.user.image,
                                  errorWidget: (context, url, error) =>
                                      const CircleAvatar(
                                          child: Icon(CupertinoIcons.home)),
                                ),
                              ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: MaterialButton(
                            color: Colors.white,
                            elevation: 1,
                            shape: const CircleBorder(),
                            onPressed: () {
                              _showBottomSheet();
                            },
                            child: Icon(
                              Icons.edit,
                              color: ColorConstants.mainAppColour,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    widget.user.email,
                    style: const TextStyle(
                        color: Colors.black45,
                        fontSize: 17,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 50),
                  TextFormField(
                    controller: _nameController,
                    validator: (val) =>
                        val != null && val.isNotEmpty ? null : 'Required Field',
                    decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.person_2_outlined),
                        label: const Text('Name'),
                        hintText: 'eg. Happy Singh',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12))),
                  ),
                  const SizedBox(height: 25),
                  TextFormField(
                    controller: _aboutController,
                    validator: (val) =>
                        val != null && val.isNotEmpty ? null : 'Required Field',
                    decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.info_outline),
                        label: const Text('About'),
                        hintText: 'Feeling Happy',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12))),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: ColorConstants.mainAppColour,
                        shape: const StadiumBorder(),
                        minimumSize: const Size(200, 45)),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        Dialogs.showProgressBar(context);
                        APIs.updateUserInfo(
                          name: _nameController.text,
                          about: _aboutController.text,
                        ).then((value) {
                          Navigator.pop(context); // close progress dialog
                          Dialogs.showSnackbar(
                              context, 'Profile Updated Successfully!');
                          // Navigate back to inbox after a short delay
                          Future.delayed(const Duration(milliseconds: 500),
                              () {
                            Navigator.pop(context);
                          });
                        });
                      }
                    },
                    icon: const Icon(Icons.edit, size: 22),
                    label: const Text(
                      'Update',
                      style: TextStyle(fontSize: 17),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showBottomSheet() {
    showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20), topRight: Radius.circular(20))),
        builder: (_) {
          return ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.only(top: 10, bottom: 20),
            children: [
              const Text('Pick Profile Picture',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
              const SizedBox(height: 50),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: const CircleBorder(),
                          fixedSize: const Size(150, 75)),
                      onPressed: () async {
                        final ImagePicker picker = ImagePicker();
                        final XFile? image = await picker.pickImage(
                            source: ImageSource.gallery, imageQuality: 80);

                        if (image != null) {
                          setState(() {
                            _image = image.path;
                          });
                          APIs.updateProfilePicture(File(_image!));
                          Navigator.pop(context);
                        }
                      },
                      child: Image.asset('Assets/Images/add_image.png')),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: const CircleBorder(),
                          fixedSize: const Size(150, 75)),
                      onPressed: () async {
                        final ImagePicker picker = ImagePicker();
                        final XFile? image = await picker.pickImage(
                            source: ImageSource.camera, imageQuality: 80);

                        if (image != null) {
                          setState(() {
                            _image = image.path;
                          });
                          APIs.updateProfilePicture(File(_image!));
                          Navigator.pop(context);
                        }
                      },
                      child: Image.asset('Assets/Images/camera.png')),
                ],
              )
            ],
          );
        });
  }
}
