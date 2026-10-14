import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/utils/app_exception.dart';
import '../models/app_user.dart';
import '../models/trip.dart';
import '../repositories/trip_repository.dart';

/// The signed-in user's trips (home screen) plus create/join actions.
class TripsProvider extends ChangeNotifier {
  TripsProvider(this._repository);

  final TripRepository _repository;
  StreamSubscription<List<Trip>>? _subscription;
  bool _disposed = false;

  String? _uid;
  List<Trip> _trips = const [];
  bool _loading = false;
  String? _error;

  List<Trip> get trips => _trips;
  bool get loading => _loading;
  String? get error => _error;

  /// Trips that have not ended yet, soonest first.
  List<Trip> upcoming([DateTime? now]) => (_trips.where((t) => !t.hasEnded(now)).toList()
    ..sort((a, b) => a.startDate.compareTo(b.startDate)));

  /// Trips that have ended, most recent first.
  List<Trip> past([DateTime? now]) => (_trips.where((t) => t.hasEnded(now)).toList()
    ..sort((a, b) => b.startDate.compareTo(a.startDate)));

  /// Starts (or stops) listening for the given user. Safe to call on every
  /// rebuild; it only does work when the user actually changes.
  void bindUser(String? uid) {
    if (uid == _uid) return;
    _uid = uid;
    _subscription?.cancel();
    _subscription = null;
    _trips = const [];
    _error = null;
    _loading = uid != null;
    if (uid != null) _listen(uid);
    // bindUser can run during a widget build, so notify after it.
    scheduleMicrotask(_safeNotify);
  }

  void _listen(String uid) {
    _subscription = _repository.watchTrips(uid).listen(
      (trips) {
        _trips = trips;
        _loading = false;
        _error = null;
        _safeNotify();
      },
      onError: (Object error) {
        _loading = false;
        _error = friendlyError(error);
        _safeNotify();
      },
    );
  }

  /// Re-subscribes after an error.
  void retry() {
    final uid = _uid;
    if (uid == null) return;
    _subscription?.cancel();
    _loading = true;
    _error = null;
    _safeNotify();
    _listen(uid);
  }

  Future<String> createTrip({required Trip draft, required AppUser creator}) =>
      _repository.createTrip(draft: draft, creator: creator);

  Future<String> joinTrip({required String code, required AppUser user}) =>
      _repository.joinTrip(code: code, user: user);

  /// Pushes a new display name to every trip membership. Returns true if all
  /// updates succeeded.
  Future<bool> syncDisplayName(String uid, String name) async {
    try {
      await _repository.updateMemberDisplayName(uid, name);
      return true;
    } catch (_) {
      return false;
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
