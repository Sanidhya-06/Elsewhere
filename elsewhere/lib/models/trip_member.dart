import 'package:cloud_firestore/cloud_firestore.dart';

import 'model_utils.dart';

enum MemberRole { owner, member }

/// A member of a trip. Stored at `trips/{tripId}/members/{userId}`.
///
/// `displayName` is denormalized from the user's profile so that members can
/// see each other's names without being able to read each other's private
/// `users/{uid}` documents. `inviteCode` records which code was used to join
/// and is what the security rules verify.
class TripMember {
  const TripMember({
    required this.userId,
    required this.displayName,
    required this.role,
    this.inviteCode,
    this.joinedAt,
  });

  final String userId;
  final String displayName;
  final MemberRole role;
  final String? inviteCode;
  final DateTime? joinedAt;

  bool get isOwner => role == MemberRole.owner;

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'displayName': displayName,
        'role': role.name,
        if (inviteCode != null) 'inviteCode': inviteCode,
        if (joinedAt != null) 'joinedAt': Timestamp.fromDate(joinedAt!),
      };

  factory TripMember.fromMap(String userId, Map<String, dynamic> map) {
    final roleName = ModelUtils.readString(map['role']);
    final code = ModelUtils.readString(map['inviteCode']);
    return TripMember(
      userId: userId,
      displayName: ModelUtils.readString(map['displayName'], 'Traveller'),
      role: MemberRole.values.firstWhere(
        (r) => r.name == roleName,
        orElse: () => MemberRole.member,
      ),
      inviteCode: code.isEmpty ? null : code,
      joinedAt: ModelUtils.readInstant(map['joinedAt']),
    );
  }
}
