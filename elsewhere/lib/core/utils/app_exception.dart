import 'package:firebase_auth/firebase_auth.dart';

/// An error with a message that is safe and useful to show to the user.
class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}

class InviteInvalidException extends AppException {
  const InviteInvalidException()
      : super(
            'That invite code is not valid or is no longer active. Ask the trip owner for a new one.');
}

class DuplicateSettlementException extends AppException {
  const DuplicateSettlementException()
      : super('That payment was already recorded.');
}

/// Converts any thrown object into a message for the user, without leaking
/// raw exception text.
String friendlyError(Object error) {
  if (error is AppException) return error.message;

  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'invalid-email':
        return 'That email address does not look right.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'invalid-login-credentials':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account with this email already exists. Try signing in.';
      case 'weak-password':
        return 'Choose a stronger password (at least 8 characters).';
      case 'too-many-requests':
        return 'Too many attempts. Wait a moment and try again.';
      case 'network-request-failed':
        return 'Cannot reach the server. Check your connection and try again.';
      case 'operation-not-allowed':
        return 'Email sign-in is not enabled for this Firebase project. Enable it in the Firebase console.';
      case 'requires-recent-login':
        return 'Please sign in again to do that.';
    }
    return 'Could not complete that sign-in request. Please try again.';
  }

  if (error is FirebaseException) {
    switch (error.code) {
      case 'permission-denied':
        return 'You do not have permission to do that. You may no longer be a member of this trip.';
      case 'unavailable':
      case 'deadline-exceeded':
        return 'Cannot reach the server. Check your connection and try again.';
      case 'not-found':
        return 'We could not find that. It may have been removed.';
      case 'already-exists':
        return 'That already exists.';
      case 'unauthenticated':
        return 'Please sign in again.';
      case 'failed-precondition':
        return 'That could not be completed right now. Please try again.';
    }
    return 'Something went wrong talking to the server. Please try again.';
  }

  return 'Something went wrong. Please try again.';
}

/// True if [error] is a Firestore permission-denied error.
bool isPermissionDenied(Object error) =>
    error is FirebaseException && error.code == 'permission-denied';
