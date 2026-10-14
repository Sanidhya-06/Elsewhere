import 'package:cloud_firestore/cloud_firestore.dart';

import 'model_utils.dart';

/// An itinerary activity. Stored at `trips/{tripId}/itinerary/{activityId}`.
class Activity {
  const Activity({
    required this.id,
    required this.title,
    required this.date,
    this.location = '',
    this.time,
    this.costMinor = 0,
    this.notes = '',
    required this.createdBy,
    this.createdAt,
  });

  final String id;
  final String title;
  final String location;

  /// Date-only UTC value.
  final DateTime date;

  /// Optional start time as "HH:mm" (24-hour).
  final String? time;

  /// Estimated cost in minor currency units (0 if none).
  final int costMinor;
  final String notes;
  final String createdBy;
  final DateTime? createdAt;

  /// Sort key within a day: timed activities in order, untimed ones last.
  String get sortKey => '${time ?? '99:99'}|${title.toLowerCase()}';

  Map<String, dynamic> toMap() => {
        ...toUpdateMap(),
        'createdBy': createdBy,
        if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      };

  /// The user-editable fields only; used for updates so that `createdBy` and
  /// `createdAt` are never rewritten.
  Map<String, dynamic> toUpdateMap() => {
        'title': title,
        'location': location,
        'date': ModelUtils.writeDay(date),
        'time': time ?? '',
        'costMinor': costMinor,
        'notes': notes,
      };

  factory Activity.fromMap(String id, Map<String, dynamic> map) {
    final time = ModelUtils.readString(map['time']);
    return Activity(
      id: id,
      title: ModelUtils.readString(map['title']),
      location: ModelUtils.readString(map['location']),
      date: ModelUtils.readDay(map['date']),
      time: time.isEmpty ? null : time,
      costMinor: ModelUtils.readInt(map['costMinor']),
      notes: ModelUtils.readString(map['notes']),
      createdBy: ModelUtils.readString(map['createdBy']),
      createdAt: ModelUtils.readInstant(map['createdAt']),
    );
  }
}
