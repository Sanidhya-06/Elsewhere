import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/utils/app_exception.dart';
import '../models/activity.dart';
import '../models/expense.dart';
import '../models/packing_item.dart';
import '../models/settlement.dart';
import '../models/trip.dart';
import '../models/trip_member.dart';
import '../repositories/expense_repository.dart';
import '../repositories/itinerary_repository.dart';
import '../repositories/packing_repository.dart';
import '../repositories/trip_repository.dart';
import '../services/expense_calculator.dart';

/// Live state for one trip: the trip itself, its members, itinerary, packing
/// list, expenses and settlements. Created when the user enters a trip and
/// disposed (cancelling every listener) when they leave it.
///
/// Access is decided by the server: if the trip is missing or the security
/// rules deny a read, [accessError] is set and the UI shows an
/// "unavailable" state instead of any trip data.
class TripWorkspace extends ChangeNotifier {
  TripWorkspace({
    required this.tripId,
    required this.currentUserId,
    required TripRepository trips,
    required ItineraryRepository itinerary,
    required PackingRepository packing,
    required ExpenseRepository expenses,
  })  : _trips = trips,
        _itinerary = itinerary,
        _packing = packing,
        _expenses = expenses {
    _start();
  }

  final String tripId;
  final String currentUserId;
  final TripRepository _trips;
  final ItineraryRepository _itinerary;
  final PackingRepository _packing;
  final ExpenseRepository _expenses;

  final List<StreamSubscription<Object?>> _subscriptions = [];
  bool _disposed = false;

  Trip? _trip;
  List<TripMember> _members = const [];
  List<Activity> _activities = const [];
  List<PackingItem> _packingItems = const [];
  List<Expense> _expenseList = const [];
  List<Settlement> _settlementList = const [];

  bool _tripLoaded = false;
  bool _membersLoaded = false;
  bool _activitiesLoaded = false;
  bool _packingLoaded = false;
  bool _expensesLoaded = false;
  bool _settlementsLoaded = false;

  String? _accessError;
  final Map<String, String> _syncErrors = {};

  // Derived money state, recomputed whenever its inputs change.
  Map<String, int> _balances = const {};
  List<Transfer> _transfers = const [];
  int _spent = 0;
  Map<String, int> _spentByCategory = const {};

  // --- Public read state ---------------------------------------------------

  Trip? get trip => _trip;
  List<TripMember> get members => _members;
  List<Activity> get activities => _activities;
  List<PackingItem> get packingItems => _packingItems;
  List<Expense> get expenses => _expenseList;
  List<Settlement> get settlements => _settlementList;

  bool get activitiesLoaded => _activitiesLoaded;
  bool get packingLoaded => _packingLoaded;
  bool get expensesLoaded => _expensesLoaded;
  bool get settlementsLoaded => _settlementsLoaded;

  /// Set when the trip cannot be shown at all (missing, removed, denied).
  String? get accessError => _accessError;

  /// Non-fatal problem in a secondary list (e.g. packing could not sync).
  String? get syncError =>
      _syncErrors.isEmpty ? null : _syncErrors.values.first;

  bool get isLoading => _accessError == null && !(_tripLoaded && _membersLoaded);
  bool get isReady => _accessError == null && _trip != null && _membersLoaded;

  bool get isOwner => _members
      .any((m) => m.userId == currentUserId && m.role == MemberRole.owner);

  Map<String, int> get balances => _balances;
  List<Transfer> get transfers => _transfers;
  int get totalSpent => _spent;
  Map<String, int> get spentByCategory => _spentByCategory;

  int get myBalance => _balances[currentUserId] ?? 0;

  int get packedCount => _packingItems.where((i) => i.packed).length;

  String nameOf(String uid) {
    for (final m in _members) {
      if (m.userId == uid) return uid == currentUserId ? '${m.displayName} (you)' : m.displayName;
    }
    return 'Former member';
  }

  String plainNameOf(String uid) {
    for (final m in _members) {
      if (m.userId == uid) return m.displayName;
    }
    return 'Former member';
  }

  Activity? activityById(String id) {
    for (final a in _activities) {
      if (a.id == id) return a;
    }
    return null;
  }

  // --- Subscriptions -------------------------------------------------------

  void _start() {
    _subscriptions.addAll([
      _trips.watchTrip(tripId).listen(
        (trip) {
          _trip = trip;
          _tripLoaded = true;
          if (trip == null) {
            _accessError = 'This trip no longer exists.';
          } else if (_accessError == _missingTripMessage) {
            _accessError = null;
          }
          _changed();
        },
        onError: (Object e) => _fatal(e),
      ),
      _trips.watchMembers(tripId).listen(
        (members) {
          _members = members;
          _membersLoaded = true;
          if (!members.any((m) => m.userId == currentUserId)) {
            _accessError = _notMemberMessage;
          } else if (_accessError == _notMemberMessage) {
            _accessError = null;
          }
          _recompute();
          _changed();
        },
        onError: (Object e) => _fatal(e),
      ),
      _itinerary.watchActivities(tripId).listen(
        (list) {
          _activities = list;
          _activitiesLoaded = true;
          _syncErrors.remove('itinerary');
          _changed();
        },
        onError: (Object e) => _soft('itinerary', e),
      ),
      _packing.watchItems(tripId).listen(
        (list) {
          _packingItems = list;
          _packingLoaded = true;
          _syncErrors.remove('packing');
          _changed();
        },
        onError: (Object e) => _soft('packing', e),
      ),
      _expenses.watchExpenses(tripId).listen(
        (list) {
          _expenseList = list;
          _expensesLoaded = true;
          _syncErrors.remove('expenses');
          _recompute();
          _changed();
        },
        onError: (Object e) => _soft('expenses', e),
      ),
      _expenses.watchSettlements(tripId).listen(
        (list) {
          _settlementList = list;
          _settlementsLoaded = true;
          _syncErrors.remove('settlements');
          _recompute();
          _changed();
        },
        onError: (Object e) => _soft('settlements', e),
      ),
    ]);
  }

  static const String _missingTripMessage = 'This trip no longer exists.';
  static const String _notMemberMessage = 'You are not a member of this trip.';

  void _fatal(Object error) {
    _tripLoaded = true;
    _membersLoaded = true;
    _accessError = isPermissionDenied(error)
        ? 'This trip is private, or you are no longer a member of it.'
        : friendlyError(error);
    _changed();
  }

  void _soft(String source, Object error) {
    // Losing access mid-session surfaces on the trip/member streams too; for
    // the secondary lists just record a readable message.
    _syncErrors[source] = friendlyError(error);
    _changed();
  }

  void _recompute() {
    final ids = _members.map((m) => m.userId);
    _balances = ExpenseCalculator.netBalances(
      memberIds: ids,
      expenses: _expenseList,
      settlements: _settlementList,
    );
    _transfers = ExpenseCalculator.suggestTransfers(_balances);
    _spent = ExpenseCalculator.totalSpent(_expenseList);
    _spentByCategory = ExpenseCalculator.spentByCategory(_expenseList);
  }

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  // --- Actions (errors propagate to the screen that called them) ----------

  Future<void> addActivity(Activity activity) =>
      _itinerary.addActivity(tripId, activity);

  Future<void> updateActivity(Activity activity) =>
      _itinerary.updateActivity(tripId, activity);

  Future<void> deleteActivity(String activityId) =>
      _itinerary.deleteActivity(tripId, activityId);

  Future<void> addPackingItem(String name) =>
      _packing.addItem(tripId, name: name, uid: currentUserId);

  Future<void> setPacked(String itemId, bool packed) =>
      _packing.setPacked(tripId, itemId, packed: packed, uid: currentUserId);

  Future<void> deletePackingItem(String itemId) =>
      _packing.deleteItem(tripId, itemId);

  Future<void> addExpense(Expense expense) =>
      _expenses.addExpense(tripId, expense);

  Future<void> deleteExpense(String expenseId) =>
      _expenses.deleteExpense(tripId, expenseId);

  /// Records that [transfer.fromUserId] paid [transfer.toUserId]. The id is
  /// derived from the current ledger state so repeated taps cannot create
  /// duplicates.
  Future<void> recordSettlement(Transfer transfer) {
    final currency = _trip?.currency ?? 'INR';
    final id = ExpenseCalculator.settlementId(
      fromUserId: transfer.fromUserId,
      toUserId: transfer.toUserId,
      amountMinor: transfer.amountMinor,
      sequence: _settlementList.length,
    );
    return _expenses.recordSettlement(
      tripId,
      Settlement(
        id: id,
        fromUserId: transfer.fromUserId,
        toUserId: transfer.toUserId,
        amountMinor: transfer.amountMinor,
        currency: currency,
        createdBy: currentUserId,
      ),
    );
  }

  Future<void> updateBudget(int budgetMinor) =>
      _trips.updateBudget(tripId, budgetMinor);

  Future<void> removeMember(String userId) =>
      _trips.removeMember(tripId, userId);

  Future<void> leave() => _trips.leaveTrip(tripId, currentUserId);

  Future<String> regenerateInviteCode() => _trips.regenerateInviteCode(
        tripId: tripId,
        oldCode: _trip?.inviteCode ?? '',
        uid: currentUserId,
      );

  @override
  void dispose() {
    _disposed = true;
    for (final s in _subscriptions) {
      s.cancel();
    }
    _subscriptions.clear();
    super.dispose();
  }
}
