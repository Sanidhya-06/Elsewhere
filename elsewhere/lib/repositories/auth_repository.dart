import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';

/// Authentication and profile operations.
abstract class AuthRepository {
  /// Emits the signed-in user (or null) now and whenever the session or the
  /// user's profile changes.
  Stream<AppUser?> userChanges();

  Future<void> signIn({required String email, required String password});

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  });

  Future<void> signOut();

  Future<void> sendPasswordReset(String email);

  Future<void> updateDisplayName(String uid, String name);
}

/// Firebase Authentication + Cloud Firestore implementation.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth, this._db);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _profile(String uid) =>
      _db.collection('users').doc(uid);

  static AppUser _toAppUser(User user) {
    final email = user.email ?? '';
    final name = (user.displayName ?? '').trim();
    return AppUser(
      uid: user.uid,
      displayName: name.isNotEmpty
          ? name
          : (email.isNotEmpty ? email.split('@').first : 'Traveller'),
      email: email,
    );
  }

  @override
  Stream<AppUser?> userChanges() =>
      _auth.userChanges().map((user) => user == null ? null : _toAppUser(user));

  @override
  Future<void> signIn({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(
        email: email.trim(), password: password);
  }

  @override
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(), password: password);
    final user = credential.user;
    if (user == null) return;
    final cleanName = name.trim();
    await user.updateDisplayName(cleanName);
    await _profile(user.uid).set({
      'displayName': cleanName,
      'email': email.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    // Re-emit the user so listeners see the display name that was just set.
    await user.reload();
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  @override
  Future<void> updateDisplayName(String uid, String name) async {
    final user = _auth.currentUser;
    if (user == null || user.uid != uid) {
      throw FirebaseAuthException(
          code: 'requires-recent-login', message: 'Not signed in.');
    }
    final cleanName = name.trim();
    await user.updateDisplayName(cleanName);
    await _profile(uid).set(
      {'displayName': cleanName, 'email': user.email ?? ''},
      SetOptions(merge: true),
    );
    await user.reload();
  }
}
