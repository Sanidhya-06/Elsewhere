import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils/dates.dart';

/// Shared helpers for reading and writing Firestore values defensively.
class ModelUtils {
  ModelUtils._();

  /// A point in time (e.g. createdAt). Null while a server timestamp is still
  /// pending on a local write.
  static DateTime? readInstant(Object? value) =>
      value is Timestamp ? value.toDate() : null;

  /// A calendar day stored as a Timestamp at midnight UTC.
  static DateTime readDay(Object? value, {DateTime? fallback}) {
    if (value is Timestamp) return EvDates.fromStored(value.toDate());
    return fallback ?? EvDates.todayUtc();
  }

  static Timestamp writeDay(DateTime day) =>
      Timestamp.fromDate(EvDates.dateOnly(day));

  static int readInt(Object? value, [int fallback = 0]) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return fallback;
  }

  static String readString(Object? value, [String fallback = '']) =>
      value is String ? value : fallback;

  static List<String> readStringList(Object? value) =>
      value is List ? value.whereType<String>().toList() : const <String>[];

  static Map<String, int> readIntMap(Object? value) {
    if (value is! Map) return const <String, int>{};
    final out = <String, int>{};
    value.forEach((k, v) {
      if (k is String && v is num) out[k] = v.toInt();
    });
    return out;
  }
}
