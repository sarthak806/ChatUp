// import 'dart:html';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:minorproject/API/_Apis.dart';
import 'package:minorproject/Models/Chat_user.dart';
import 'package:minorproject/ProfileScreen_.dart';
import 'package:minorproject/Widgets/Chat_user_card.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

FirebaseAuth auth = FirebaseAuth.instance;

Future _signOut() async {
  await FirebaseAuth.instance.signOut();
}

// Storage Information
// For storing all users
List<ChatUser> list = [];

// For storing searched users
final List<ChatUser> _searchList = [];

// For storing search status
bool _isSearching = false;

class _MyHomePageState extends State<MyHomePage> {
  bool _isFabHovered = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    APIs.getSelfinfo();
  }

  @override
  Widget build(BuildContext context) {
    const gradientBg = LinearGradient(
      colors: [Colors.white, Color(0xFFFFF7F3)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: WillPopScope(
        onWillPop: () {
          if (_isSearching) {
            setState(() {
              _isSearching = !_isSearching;
            });
            return Future.value(false);
          } else {
            return Future.value(true);
          }
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          body: Container(
            decoration: const BoxDecoration(gradient: gradientBg),
            child: SafeArea(
              child: Stack(
                children: [
                  // Page content
                  SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 18,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              RichText(
                                text: const TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'i',
                                      style: TextStyle(
                                        fontSize: 42,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFFE07856),
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'nbox',
                                      style: TextStyle(
                                        fontSize: 42,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF3A3A3A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              _SettingsButton(onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => ProfileScreen(
                                              user: APIs.me,
                                            )));
                              }),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Search bar
                          Container(
                            height: 54,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F4F4),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: TextField(
                              onTap: () {
                                setState(() {
                                  _isSearching = true;
                                });
                              },
                              onChanged: (val) {
                                _searchList.clear();
                                for (var i in list) {
                                  if (i.name
                                          .toLowerCase()
                                          .contains(val.toLowerCase()) ||
                                      i.email
                                          .toLowerCase()
                                          .contains(val.toLowerCase())) {
                                    _searchList.add(i);
                                    setState(() {
                                      _searchList;
                                    });
                                  }
                                }
                              },
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                icon: Icon(Icons.search, color: Colors.black38),
                                hintText: 'Search conversations...',
                                hintStyle: TextStyle(
                                  color: Colors.black38,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 28),

                          StreamBuilder(
                            stream: APIs.getAllusers(),
                            builder: (context, snapshot) {
                              switch (snapshot.connectionState) {
                                case ConnectionState.waiting:
                                case ConnectionState.none:
                                  return const Center(
                                      child: Padding(
                                    padding: EdgeInsets.only(top: 60.0),
                                    child: CircularProgressIndicator(),
                                  ));

                                case ConnectionState.active:
                                case ConnectionState.done:
                                  final data = snapshot.data?.docs;

                                  list = data
                                          ?.map((e) =>
                                              ChatUser.fromJson(e.data()))
                                          .toList() ??
                                      [];

                                  if (list.isNotEmpty) {
                                    return ListView.builder(
                                        physics: const BouncingScrollPhysics(),
                                        shrinkWrap: true,
                                        itemCount: _isSearching
                                            ? _searchList.length
                                            : list.length,
                                        itemBuilder: (context, index) {
                                          return ChatUserCard(
                                              user: _isSearching
                                                  ? _searchList[index]
                                                  : list[index]);
                                        });
                                  } else {
                                    return const Padding(
                                      padding: EdgeInsets.only(top: 40.0),
                                      child: Center(
                                          child: Text('No Connection found')),
                                    );
                                  }
                              }
                            },
                          ),

                          const SizedBox(height: 40),

                          // Pull down to refresh text
                          const Center(
                            child: Text(
                              'Pull down to refresh',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black26,
                              ),
                            ),
                          ),

                          const SizedBox(height: 40),
                        ],
                      ),
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
}

class _SettingsButton extends StatefulWidget {
  const _SettingsButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_SettingsButton> createState() => _SettingsButtonState();
}

class _SettingsButtonState extends State<_SettingsButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color:
                    const Color(0xFFE07856).withOpacity(_hover ? 0.30 : 0.18),
                blurRadius: _hover ? 20 : 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: AnimatedRotation(
            turns:
                _hover ? 0.125 : 0, // 45 degrees rotation (1/8 of a full turn)
            duration: const Duration(milliseconds: 200),
            child: const Icon(
              Icons.settings,
              color: Color(0xFFE07856),
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}
