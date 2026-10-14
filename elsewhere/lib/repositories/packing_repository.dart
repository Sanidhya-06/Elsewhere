import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/packing_item.dart';

/// The shared packing checklist for a trip.
abstract class PackingRepository {
  Stream<List<PackingItem>> watchItems(String tripId);

  Future<void> addItem(String tripId, {required String name, required String uid});

  Future<void> setPacked(
    String tripId,
    String itemId, {
    required bool packed,
    required String uid,
  });

  Future<void> deleteItem(String tripId, String itemId);
}

class FirestorePackingRepository implements PackingRepository {
  FirestorePackingRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String tripId) =>
      _db.collection('trips').doc(tripId).collection('packingItems');

  @override
  Stream<List<PackingItem>> watchItems(String tripId) {
    return _col(tripId).snapshots().map((snap) =>
        snap.docs.map((d) => PackingItem.fromMap(d.id, d.data())).toList());
  }

  @override
  Future<void> addItem(
    String tripId, {
    required String name,
    required String uid,
  }) async {
    await _col(tripId).add({
      'name': name.trim(),
      'packed': false,
      'addedBy': uid,
      'packedBy': '',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> setPacked(
    String tripId,
    String itemId, {
    required bool packed,
    required String uid,
  }) async {
    await _col(tripId).doc(itemId).update({
      'packed': packed,
      'packedBy': packed ? uid : '',
    });
  }

  @override
  Future<void> deleteItem(String tripId, String itemId) =>
      _col(tripId).doc(itemId).delete();
}
