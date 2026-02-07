import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  Message({
    required this.toId,
    required this.msg,
    required this.read,
    required this.type,
    required this.fromId,
    required this.sent,
    this.id = '',
    List<String>? deletedFor,
    this.isTimeCapsule = false,
    this.unlockTime = '',
    this.status = 'unlocked',
    this.originalMsg = '',
  }) : deletedFor = deletedFor ?? [];

  late final String toId;
  late final String msg;
  late final String read;
  late final String fromId;
  late final String sent;
  late final Type type;
  late final String id;
  late final List<String> deletedFor;
  late final bool isTimeCapsule;
  late final String unlockTime;
  late final String status; // 'locked' or 'unlocked'
  late final String originalMsg;

  Message.fromJson(Map<String, dynamic> json, {String id = ''}) {
    toId = json['toId'].toString();
    msg = json['msg'].toString();
    read = json['read'].toString();
    type = json['type'].toString() == Type.image.name ? Type.image : Type.text;
    fromId = json['fromId'].toString();
    sent = json['sent'].toString();
    this.id = id;
    final df = json['deletedFor'];
    if (df is List) {
      deletedFor = df.map((e) => e.toString()).toList();
    } else {
      deletedFor = [];
    }
    isTimeCapsule = json['isTimeCapsule'] ?? false;
    unlockTime = json['unlockTime']?.toString() ?? '';
    status = json['status']?.toString() ?? 'unlocked';
    originalMsg = json['originalMsg']?.toString() ?? '';
  }

  factory Message.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    return Message.fromJson(doc.data(), id: doc.id);
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['toId'] = toId;
    data['msg'] = msg;
    data['read'] = read;
    data['type'] = type.name;
    data['fromId'] = fromId;
    data['sent'] = sent;
    data['deletedFor'] = deletedFor;
    data['isTimeCapsule'] = isTimeCapsule;
    data['unlockTime'] = unlockTime;
    data['status'] = status;
    data['originalMsg'] = originalMsg;
    return data;
  }
}

enum Type { text, image }