import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils/app_exception.dart';
import '../core/utils/invite_code.dart';
import '../models/app_user.dart';
import '../models/trip.dart';
import '../models/trip_member.dart';

/// Trips, membership and invitations.
abstract class TripRepository {
  /// Trips the user belongs to.
  Stream<List<Trip>> watchTrips(String uid);

  /// Emits null if the trip document does not exist.
  Stream<Trip?> watchTrip(String tripId);

  Stream<List<TripMember>> watchMembers(String tripId);

  /// Creates the trip, the owner's membership and its invite code in one
  /// atomic batch. Returns the new trip id.
  Future<String> createTrip({required Trip draft, required AppUser creator});

  /// Joins a trip using an invite code. Returns the trip id. Throws
  /// [InviteInvalidException] if the code is unknown or deactivated.
  Future<String> joinTrip({required String code, required AppUser user});

  Future<void> updateBudget(String tripId, int budgetMinor);

  /// Owner removes another member.
  Future<void> removeMember(String tripId, String userId);

  /// A non-owner member leaves the trip.
  Future<void> leaveTrip(String tripId, String userId);

  /// Replaces the trip's invite code. Returns the new code.
  Future<String> regenerateInviteCode({
    required String tripId,
    required String oldCode,
    required String uid,
  });

  /// Updates the denormalized display name on every membership of [uid].
  Future<void> updateMemberDisplayName(String uid, String name);
}

class FirestoreTripRepository implements TripRepository {
  FirestoreTripRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _trips =>
      _db.collection('trips');
  CollectionReference<Map<String, dynamic>> get _invites =>
      _db.collection('invites');

  CollectionReference<Map<String, dynamic>> _members(String tripId) =>
      _trips.doc(tripId).collection('members');

  @override
  Stream<List<Trip>> watchTrips(String uid) {
    return _trips.where('memberIds', arrayContains: uid).snapshots().map(
        (snap) => snap.docs.map((d) => Trip.fromMap(d.id, d.data())).toList());
  }

  @override
  Stream<Trip?> watchTrip(String tripId) {
    return _trips.doc(tripId).snapshots().map((snap) {
      final data = snap.data();
      return snap.exists && data != null ? Trip.fromMap(snap.id, data) : null;
    });
  }

  @override
  Stream<List<TripMember>> watchMembers(String tripId) {
    return _members(tripId).snapshots().map((snap) {
      final members =
          snap.docs.map((d) => TripMember.fromMap(d.id, d.data())).toList();
      members.sort((a, b) {
        if (a.isOwner != b.isOwner) return a.isOwner ? -1 : 1;
        return a.displayName
            .toLowerCase()
            .compareTo(b.displayName.toLowerCase());
      });
      return members;
    });
  }

  @override
  Future<String> createTrip({
    required Trip draft,
    required AppUser creator,
  }) async {
    final ref = _trips.doc();
    final code = InviteCodes.generate();
    final batch = _db.batch();

    batch.set(ref, {
      ...draft.toMap(),
      'createdBy': creator.uid,
      'memberIds': [creator.uid],
      'inviteCode': code,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(_members(ref.id).doc(creator.uid), {
      'userId': creator.uid,
      'displayName': creator.displayName,
      'role': MemberRole.owner.name,
      'joinedAt': FieldValue.serverTimestamp(),
    });
    batch.set(_invites.doc(code), {
      'tripId': ref.id,
      'createdBy': creator.uid,
      'active': true,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    return ref.id;
  }

  @override
  Future<String> joinTrip({required String code, required AppUser user}) async {
    final inviteSnap = await _invites.doc(code).get();
    final invite = inviteSnap.data();
    if (!inviteSnap.exists || invite == null || invite['active'] != true) {
      throw const InviteInvalidException();
    }
    final tripId = invite['tripId'];
    if (tripId is! String || tripId.isEmpty) {
      throw const InviteInvalidException();
    }

    // Already a member? Reading the membership document succeeds only for
    // members; non-members get permission-denied, which means "not yet".
    try {
      final existing = await _members(tripId).doc(user.uid).get();
      if (existing.exists) return tripId;
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') rethrow;
    }

    final batch = _db.batch();
    batch.set(_members(tripId).doc(user.uid), {
      'userId': user.uid,
      'displayName': user.displayName,
      'role': MemberRole.member.name,
      'inviteCode': code,
      'joinedAt': FieldValue.serverTimestamp(),
    });
    batch.update(_trips.doc(tripId), {
      'memberIds': FieldValue.arrayUnion([user.uid]),
    });
    await batch.commit();
    return tripId;
  }

  @override
  Future<void> updateBudget(String tripId, int budgetMinor) =>
      _trips.doc(tripId).update({'budgetMinor': budgetMinor});

  @override
  Future<void> removeMember(String tripId, String userId) async {
    final batch = _db.batch();
    batch.delete(_members(tripId).doc(userId));
    batch.update(_trips.doc(tripId), {
      'memberIds': FieldValue.arrayRemove([userId]),
    });
    await batch.commit();
  }

  @override
  Future<void> leaveTrip(String tripId, String userId) =>
      removeMember(tripId, userId);

  @override
  Future<String> regenerateInviteCode({
    required String tripId,
    required String oldCode,
    required String uid,
  }) async {
    final code = InviteCodes.generate();
    final batch = _db.batch();
    batch.set(_invites.doc(code), {
      'tripId': tripId,
      'createdBy': uid,
      'active': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
    if (oldCode.isNotEmpty) {
      batch.update(_invites.doc(oldCode), {'active': false});
    }
    batch.update(_trips.doc(tripId), {'inviteCode': code});
    await batch.commit();
    return code;
  }

  @override
  Future<void> updateMemberDisplayName(String uid, String name) async {
    final trips = await _trips.where('memberIds', arrayContains: uid).get();
    if (trips.docs.isEmpty) return;
    final batch = _db.batch();
    for (final trip in trips.docs) {
      batch.update(_members(trip.id).doc(uid), {'displayName': name.trim()});
    }
    await batch.commit();
  }
}
