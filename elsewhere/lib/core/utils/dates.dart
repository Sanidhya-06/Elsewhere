/// Helpers for date-only values.
///
/// Trip days and activity days are stored in Firestore as a Timestamp at
/// midnight UTC of the calendar day. Reading them back always goes through
/// [fromStored], which takes the UTC calendar fields, so a trip day never
/// shifts to a neighbouring day in a different time zone.
class EvDates {
  EvDates._();

  /// Calendar day of [d] (using d's own year/month/day) as midnight UTC.
  static DateTime dateOnly(DateTime d) => DateTime.utc(d.year, d.month, d.day);

  /// Today's calendar day (device local date) as midnight UTC.
  static DateTime todayUtc([DateTime? now]) => dateOnly(now ?? DateTime.now());

  /// Converts a stored instant to its UTC calendar day.
  static DateTime fromStored(DateTime instant) => dateOnly(instant.toUtc());

  /// A local-midnight DateTime with the same calendar day, for date pickers.
  static DateTime toLocalDay(DateTime utcDay) =>
      DateTime(utcDay.year, utcDay.month, utcDay.day);

  /// Whole days from [a] to [b]; both must be date-only UTC values.
  static int daysBetween(DateTime a, DateTime b) => b.difference(a).inDays;

  static String key(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
