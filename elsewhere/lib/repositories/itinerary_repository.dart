import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/activity.dart';

/// Itinerary activities for a trip.
abstract class ItineraryRepository {
  Stream<List<Activity>> watchActivities(String tripId);

  Future<void> addActivity(String tripId, Activity activity);

  Future<void> updateActivity(String tripId, Activity activity);

  Future<void> deleteActivity(String tripId, String activityId);
}

class FirestoreItineraryRepository implements ItineraryRepository {
  FirestoreItineraryRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String tripId) =>
      _db.collection('trips').doc(tripId).collection('itinerary');

  @override
  Stream<List<Activity>> watchActivities(String tripId) {
    return _col(tripId).orderBy('date').snapshots().map((snap) =>
        snap.docs.map((d) => Activity.fromMap(d.id, d.data())).toList());
  }

  @override
  Future<void> addActivity(String tripId, Activity activity) async {
    await _col(tripId).add({
      ...activity.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> updateActivity(String tripId, Activity activity) async {
    await _col(tripId).doc(activity.id).update({
      ...activity.toUpdateMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deleteActivity(String tripId, String activityId) =>
      _col(tripId).doc(activityId).delete();
}
