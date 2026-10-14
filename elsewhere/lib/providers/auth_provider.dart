import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/utils/app_exception.dart';
import '../models/app_user.dart';
import '../repositories/auth_repository.dart';

enum AuthStatus {
  /// The first session check has not completed yet (splash screen).
  unknown,
  authenticated,
  unauthenticated,
}

/// Holds the authentication session and exposes sign-in/up/out actions. The
/// router listens to this object to redirect between public and private
/// screens.
class AuthProvider extends ChangeNotifier {
  AuthProvider(this._repository) {
    _subscription = _repository.userChanges().listen(
      _onUser,
      onError: (Object error) {
        // A failed session check must not leave the splash screen spinning
        // forever; treat it as signed out and say why.
        _user = null;
        _status = AuthStatus.unauthenticated;
        _errorMessage = friendlyError(error);
        _safeNotify();
      },
    );
  }

  final AuthRepository _repository;
  StreamSubscription<AppUser?>? _subscription;
  bool _disposed = false;

  AuthStatus _status = AuthStatus.unknown;
  AppUser? _user;
  bool _busy = false;
  String? _errorMessage;

  AuthStatus get status => _status;
  AppUser? get user => _user;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get busy => _busy;
  String? get errorMessage => _errorMessage;

  void _onUser(AppUser? user) {
    _user = user;
    _status =
        user == null ? AuthStatus.unauthenticated : AuthStatus.authenticated;
    _safeNotify();
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    _safeNotify();
  }

  Future<bool> signIn({required String email, required String password}) {
    return _run(() => _repository.signIn(email: email, password: password));
  }

  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
  }) {
    return _run(() => _repository.signUp(
          name: name,
          email: email,
          password: password,
        ));
  }

  Future<bool> sendPasswordReset(String email) {
    return _run(() => _repository.sendPasswordReset(email));
  }

  Future<bool> updateDisplayName(String name) {
    final uid = _user?.uid;
    if (uid == null) return Future.value(false);
    return _run(() => _repository.updateDisplayName(uid, name));
  }

  Future<bool> signOut() => _run(_repository.signOut);

  /// Runs [action] with busy/error bookkeeping. Returns true on success.
  /// Ignores re-entrant calls while another action is running, which prevents
  /// duplicate submissions.
  Future<bool> _run(Future<void> Function() action) async {
    if (_busy) return false;
    _busy = true;
    _errorMessage = null;
    _safeNotify();
    try {
      await action();
      return true;
    } catch (error) {
      _errorMessage = friendlyError(error);
      return false;
    } finally {
      _busy = false;
      _safeNotify();
    }
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    super.dispose();
  }
}
