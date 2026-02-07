import 'dart:io';
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:minorproject/Models/Chat_user.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:minorproject/Models/Message.dart';
import 'package:image_picker/image_picker.dart';

class APIs {
  // Getter method (To get user details)
  static User get user => auth.currentUser!;

  // Authentication
  static FirebaseAuth auth = FirebaseAuth.instance;

  // Accessing cloud firestore database
  static FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Accessing cloud firebase Storage
  static FirebaseStorage storage = FirebaseStorage.instance;

  // For checking if user exist or not?
  static Future<bool> userExist() async {
    return (await firestore.collection('users').doc(user.uid).get()).exists;
  }

  // For storing self user info
  static late ChatUser me;

// For getting current user info
  static Future<void> getSelfinfo() async {
    await firestore
        .collection('users')
        .doc(user.uid)
        .get()
        .then((user) async =>
    {
      if (user.exists)
        {me = ChatUser.fromJson(user.data()!)}
      else
        {await createUser().then((value) => getSelfinfo())}
    });
  }

// For creating a new user
  static Future<void> createUser() async {
    final time = DateTime
        .now()
        .millisecondsSinceEpoch
        .toString();
    final chatUser = ChatUser(
        id: user.uid,
        name: user.displayName.toString(),
        email: user.email.toString(),
        about: "Hey, I'm using ChatUp",
        image: user.photoURL.toString(),
        createdAt: time,
        isOnline: false,
        lastActive: time,
        pushToken: '',
        username: null,
        profileCompleted: false);

    return await firestore
        .collection('users')
        .doc(user.uid)
        .set(chatUser.toJson());
  }

  // Check if user has completed their profile setup
  static Future<bool> isProfileCompleted() async {
    try {
      final doc = await firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data();
        return data?['profileCompleted'] == true;
      }
      return false;
    } catch (e) {
      print('Error checking profile completion: $e');
      return false;
    }
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllusers() {
    return firestore
        .collection('users')
        .where('id', isNotEqualTo: user.uid)
        .snapshots();
  }

// Update profile picture
  static Future<void> updateProfilePicture(File file) async {
    // Getting image file extension
    final ext = file.path
        .split('.')
        .last;
    // Storage file reference with path
    final ref = storage.ref().child('profile_pictures/${user.uid}.$ext');
    // Uploading image
    await ref
        .putFile(file, SettableMetadata(contentType: 'image/$ext'))
        .then((p0) {});
    // Updating image in firestore storage
    me.image = await ref.getDownloadURL();
    await firestore
        .collection('users')
        .doc(user.uid)
        .update({'image': me.image});
  }

  // Update user info (name and about)
  static Future<void> updateUserInfo({required String name, required String about}) async {
    await firestore.collection('users').doc(user.uid).update({
      'name': name,
      'about': about,
    });
    // Update local me object
    me.name = name;
    me.about = about;
  }

// ********** User messages related APIs **********

  static String getConversationID(String id) =>
      user.uid.hashCode <= id.hashCode
          ? '${user.uid}_$id'
          : '${id}_${user.uid}';

  //For getting all messages of a specific conversation from FSDB
  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllMessages(
      ChatUser user) {
    return firestore
        .collection('chats/${getConversationID(user.id)}/messages/')
        .orderBy('sent')
        .snapshots();
  }

  // Fetch only the latest message in a conversation (for inbox preview)
  static Stream<QuerySnapshot<Map<String, dynamic>>> getLastMessage(
      ChatUser user) {
    return firestore
        .collection('chats/${getConversationID(user.id)}/messages/')
        .orderBy('sent', descending: true)
        .limit(1)
        .snapshots();
  }

  // Mark a message as read when the current user views it
  static Future<void> markMessageAsRead(Message message) async {
    if (message.read.isNotEmpty || message.fromId == user.uid) return;

    final otherId = message.fromId;
    final docRef = firestore
        .collection('chats/${getConversationID(otherId)}/messages/')
        .doc(message.id);

    await docRef.update({
      'read': DateTime.now().millisecondsSinceEpoch.toString(),
    });
  }

  // For sending message
  static Future<void> sendMessage(ChatUser chatUser, String msg) async {
    final time = DateTime
        .now()
        .millisecondsSinceEpoch
        .toString();
    
    final Message message = Message(
      toId: chatUser.id,
      msg: msg,
      read: '',
      type: Type.text,
      fromId: user.uid,
      sent: time,
    );
    final ref =
    firestore.collection('chats/${getConversationID(chatUser.id)}/messages/');
    await ref.doc().set(message.toJson());
  }

  // For sending time capsule message
  static Future<void> sendTimeCapsuleMessage(
      ChatUser chatUser, String msg, String unlockTime) async {
    final time = DateTime.now().millisecondsSinceEpoch.toString();
    
    // Create placeholder message to show before unlock
    const String placeholderMsg = 'Time Capsule Message';
    
    final Message message = Message(
      toId: chatUser.id,
      msg: placeholderMsg,
      read: '',
      type: Type.text,
      fromId: user.uid,
      sent: time,
      isTimeCapsule: true,
      unlockTime: unlockTime,
      status: 'locked',
      originalMsg: msg, // Store the actual message
    );
    
    final ref =
        firestore.collection('chats/${getConversationID(chatUser.id)}/messages/');
    await ref.doc().set(message.toJson());
  }

  // Check and unlock time capsule messages
  static Future<void> checkAndUnlockMessages(String conversationId) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // Query for locked time capsule messages where unlock time has passed
      final querySnapshot = await firestore
          .collection('chats/$conversationId/messages/')
          .where('isTimeCapsule', isEqualTo: true)
          .where('status', isEqualTo: 'locked')
          .get();
      
      for (var doc in querySnapshot.docs) {
        final message = Message.fromDoc(doc);
        
        if (message.unlockTime.isNotEmpty) {
          final unlockTime = int.parse(message.unlockTime);
          
          if (now >= unlockTime) {
            // Unlock the message by updating status and replacing placeholder with original
            await doc.reference.update({
              'status': 'unlocked',
              'msg': message.originalMsg,
            });
          }
        }
      }
    } catch (e) {
      print('Error checking time capsule messages: $e');
    }
  }

  // Delete message for me (hide only for current user)
  static Future<void> deleteMessageForMe(Message message) async {
    final otherId = message.fromId == user.uid ? message.toId : message.fromId;
    final docRef = firestore
        .collection('chats/${getConversationID(otherId)}/messages/')
        .doc(message.id);
    await docRef.update({'deletedFor': FieldValue.arrayUnion([user.uid])});
  }

  // Delete message for everyone (remove the document)
  static Future<void> deleteMessageForEveryone(Message message) async {
    if (message.fromId != user.uid) {
      throw FirebaseException(
          plugin: 'firebase_storage',
          code: 'not-allowed',
          message: 'Only sender can delete message for everyone');
    }
    final otherId = message.toId; // current user is sender
    final docRef = firestore
        .collection('chats/${getConversationID(otherId)}/messages/')
        .doc(message.id);
    await docRef.delete();
  }

  // For sending image message
  static Future<void> sendImageMessage(ChatUser chatUser, File imageFile) async {
    final time = DateTime
        .now()
        .millisecondsSinceEpoch
        .toString();
    
    // Getting image file extension
    final ext = imageFile.path.split('.').last;
    
    // Storage file reference with path
    final ref = storage.ref().child(
        'chat_images/${getConversationID(chatUser.id)}/${user.uid}_$time.$ext');
    
    // Uploading image
    await ref
        .putFile(imageFile, SettableMetadata(contentType: 'image/$ext'))
        .then((p0) async {
      // Get the download URL
      final imageUrl = await ref.getDownloadURL();
      
      // Create and send message with image URL
      final Message message = Message(
        toId: chatUser.id,
        msg: imageUrl,
        read: '',
        type: Type.image,
        fromId: user.uid,
        sent: time,
      );
      
      final messageRef = firestore
          .collection('chats/${getConversationID(chatUser.id)}/messages/');
      await messageRef.doc().set(message.toJson());
    });
  }

  // For sending image message from XFile (works on web and mobile)
  static Future<void> sendImageMessageXFile(ChatUser chatUser, XFile imageFile) async {
    try {
      final time = DateTime.now().millisecondsSinceEpoch.toString();

      print('=== Starting image upload for ${imageFile.name} ===');

      // Derive extension from the file NAME (path is a blob URL on web)
      final name = imageFile.name;
      String ext = name.contains('.') ? name.split('.').last.toLowerCase() : 'png';
      if (ext == 'jpg') ext = 'jpeg';
      final contentType = 'image/$ext';
      print('[UPLOAD] Resolved extension: $ext, contentType: $contentType');

      // Storage file reference with safe path
      final ref = storage
          .ref()
          .child('chat_images/${getConversationID(chatUser.id)}/${user.uid}_$time.$ext');

      print('[UPLOAD] Storage reference: ${ref.fullPath}');

      // Read file bytes from XFile
      print('[UPLOAD] Reading file bytes...');
      final fileBytes = await imageFile.readAsBytes();
      print('[UPLOAD] File size: ${fileBytes.lengthInBytes} bytes');

      // Uploading image bytes with proper task management
      print('[UPLOAD] Creating upload task...');
      final metadata = SettableMetadata(contentType: contentType);
      
      late TaskSnapshot taskSnapshot;
      int retries = 0;
      const maxRetries = 3;
      
      while (retries < maxRetries) {
        try {
          print('[UPLOAD] Attempt ${retries + 1} of $maxRetries');
          
          // Create upload task
          final uploadTask = ref.putData(fileBytes, metadata);
          print('[UPLOAD] Upload task created, waiting for completion...');
          
          // Listen to upload progress
          uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
            print('[UPLOAD PROGRESS] ${snapshot.bytesTransferred}/${snapshot.totalBytes} bytes');
          });
          
          // Wait for upload with timeout
          taskSnapshot = await uploadTask.timeout(
            const Duration(minutes: 3),
            onTimeout: () {
              print('[UPLOAD] Timeout! Attempting to cancel upload...');
              try {
                uploadTask.cancel();
              } catch (e) {
                print('[UPLOAD] Could not cancel task: $e');
              }
              throw TimeoutException('Image upload took too long (3 minutes)');
            },
          );
          
          print('[UPLOAD] Upload task completed. State: ${taskSnapshot.state}');
          
          if (taskSnapshot.state == TaskState.success) {
            print('[UPLOAD] Upload successful!');
            break; // Success, exit retry loop
          } else {
            print('[UPLOAD] Upload state is not success: ${taskSnapshot.state}');
            retries++;
            if (retries < maxRetries) {
              print('[UPLOAD] Retrying... (waiting 2 seconds)');
              await Future.delayed(const Duration(seconds: 2));
            } else {
              throw Exception('Upload failed with state: ${taskSnapshot.state}');
            }
          }
        } on TimeoutException {
          print('[UPLOAD] Timeout on attempt ${retries + 1}');
          retries++;
          if (retries < maxRetries) {
            print('[UPLOAD] Retrying after timeout...');
            await Future.delayed(const Duration(seconds: 2));
          } else {
            print('[UPLOAD] Max retries reached after timeout');
            rethrow;
          }
        } on FirebaseException catch (e) {
          print('[UPLOAD] Firebase error on attempt ${retries + 1}: ${e.code} - ${e.message}');
          retries++;
          if (retries < maxRetries) {
            print('[UPLOAD] Retrying after Firebase error...');
            await Future.delayed(const Duration(seconds: 2));
          } else {
            print('[UPLOAD] Max retries reached after Firebase error');
            rethrow;
          }
        } catch (e) {
          print('[UPLOAD] Error on attempt ${retries + 1}: $e (${e.runtimeType})');
          retries++;
          if (retries < maxRetries) {
            print('[UPLOAD] Retrying...');
            await Future.delayed(const Duration(seconds: 2));
          } else {
            print('[UPLOAD] Max retries reached');
            rethrow;
          }
        }
      }

      print('[UPLOAD] Getting download URL...');
      final imageUrl = await ref.getDownloadURL().timeout(
        const Duration(minutes: 1),
        onTimeout: () => throw TimeoutException('Failed to get download URL'),
      );
      print('[UPLOAD] Download URL obtained: $imageUrl');

      // Create and send message with image URL
      print('[FIRESTORE] Creating message object...');
      final Message message = Message(
          toId: chatUser.id,
          msg: imageUrl,
          read: '',
          type: Type.image,
          fromId: user.uid,
          sent: time);

      print('[FIRESTORE] Saving message to Firestore...');
      final messageRef = firestore
          .collection('chats/${getConversationID(chatUser.id)}/messages/');
      
      await messageRef.doc().set(message.toJson()).timeout(
        const Duration(minutes: 1),
        onTimeout: () => throw TimeoutException('Failed to save message to Firestore'),
      );
      
      print('[FIRESTORE] Message saved successfully!');
      print('=== Image message sent successfully! ===');
    } on TimeoutException catch (e) {
      print('[ERROR] Timeout: $e');
      rethrow;
    } on FirebaseException catch (e) {
      print('[ERROR] Firebase error: code=${e.code}, message=${e.message}');
      rethrow;
    } catch (e) {
      print('[ERROR] Unexpected error in sendImageMessageXFile: $e');
      print('[ERROR] Error type: ${e.runtimeType}');
      rethrow;
    }
  }
}
