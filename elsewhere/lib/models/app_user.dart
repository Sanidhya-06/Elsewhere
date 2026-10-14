import 'package:cloud_firestore/cloud_firestore.dart';

import 'model_utils.dart';

/// The signed-in person. Stored at `users/{uid}`.
class AppUser {
  const AppUser({
    required this.uid,
    required this.displayName,
    required this.email,
    this.createdAt,
  });

  final String uid;
  final String displayName;
  final String email;
  final DateTime? createdAt;

  String get firstName {
    final trimmed = displayName.trim();
    return trimmed.isEmpty ? 'there' : trimmed.split(RegExp(r'\s+')).first;
  }

  AppUser copyWith({String? displayName}) => AppUser(
        uid: uid,
        displayName: displayName ?? this.displayName,
        email: email,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'displayName': displayName,
        'email': email,
        if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      };

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) => AppUser(
        uid: uid,
        displayName: ModelUtils.readString(map['displayName']),
        email: ModelUtils.readString(map['email']),
        createdAt: ModelUtils.readInstant(map['createdAt']),
      );
}
