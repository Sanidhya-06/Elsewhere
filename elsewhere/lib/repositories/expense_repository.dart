import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils/app_exception.dart';
import '../models/expense.dart';
import '../models/settlement.dart';

/// Shared expenses and recorded settlements for a trip.
abstract class ExpenseRepository {
  Stream<List<Expense>> watchExpenses(String tripId);

  Stream<List<Settlement>> watchSettlements(String tripId);

  Future<void> addExpense(String tripId, Expense expense);

  Future<void> deleteExpense(String tripId, String expenseId);

  /// Records a settlement under the deterministic id [settlement.id]. Throws
  /// [DuplicateSettlementException] if a record with that id already exists.
  Future<void> recordSettlement(String tripId, Settlement settlement);
}

class FirestoreExpenseRepository implements ExpenseRepository {
  FirestoreExpenseRepository(this._db);

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _trip(String tripId) =>
      _db.collection('trips').doc(tripId);

  CollectionReference<Map<String, dynamic>> _expenses(String tripId) =>
      _trip(tripId).collection('expenses');

  CollectionReference<Map<String, dynamic>> _settlements(String tripId) =>
      _trip(tripId).collection('settlements');

  @override
  Stream<List<Expense>> watchExpenses(String tripId) {
    return _expenses(tripId).snapshots().map((snap) =>
        snap.docs.map((d) => Expense.fromMap(d.id, d.data())).toList());
  }

  @override
  Stream<List<Settlement>> watchSettlements(String tripId) {
    return _settlements(tripId).snapshots().map((snap) =>
        snap.docs.map((d) => Settlement.fromMap(d.id, d.data())).toList());
  }

  @override
  Future<void> addExpense(String tripId, Expense expense) async {
    await _expenses(tripId).add({
      ...expense.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deleteExpense(String tripId, String expenseId) =>
      _expenses(tripId).doc(expenseId).delete();

  @override
  Future<void> recordSettlement(String tripId, Settlement settlement) {
    final ref = _settlements(tripId).doc(settlement.id);
    return _db.runTransaction((tx) async {
      final existing = await tx.get(ref);
      if (existing.exists) throw const DuplicateSettlementException();
      tx.set(ref, {
        ...settlement.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
