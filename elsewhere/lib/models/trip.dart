import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils/dates.dart';
import 'model_utils.dart';

/// A trip. Stored at `trips/{tripId}`.
///
/// `memberIds` is a deliberate denormalization of the `members` subcollection:
/// it lets a user list their trips with one `array-contains` query. The
/// subcollection remains the source of truth for roles and display names.
class Trip {
  const Trip({
    required this.id,
    required this.name,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.budgetMinor,
    required this.currency,
    required this.createdBy,
    required this.memberIds,
    required this.inviteCode,
    this.coverImageUrl,
    this.createdAt,
  });

  final String id;
  final String name;
  final String destination;

  /// Date-only UTC values (see [EvDates]).
  final DateTime startDate;
  final DateTime endDate;

  /// Budget in minor currency units. Zero means "no budget set".
  final int budgetMinor;
  final String currency;
  final String createdBy;
  final List<String> memberIds;
  final String inviteCode;
  final String? coverImageUrl;
  final DateTime? createdAt;

  int get dayCount => EvDates.daysBetween(startDate, endDate) + 1;

  List<DateTime> get days =>
      List.generate(dayCount, (i) => startDate.add(Duration(days: i)));

  bool get hasBudget => budgetMinor > 0;

  bool hasEnded([DateTime? now]) => endDate.isBefore(EvDates.todayUtc(now));

  bool isOngoing([DateTime? now]) {
    final today = EvDates.todayUtc(now);
    return !startDate.isAfter(today) && !endDate.isBefore(today);
  }

  Trip copyWith({int? budgetMinor, String? inviteCode, List<String>? memberIds}) =>
      Trip(
        id: id,
        name: name,
        destination: destination,
        startDate: startDate,
        endDate: endDate,
        budgetMinor: budgetMinor ?? this.budgetMinor,
        currency: currency,
        createdBy: createdBy,
        memberIds: memberIds ?? this.memberIds,
        inviteCode: inviteCode ?? this.inviteCode,
        coverImageUrl: coverImageUrl,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'destination': destination,
        'startDate': ModelUtils.writeDay(startDate),
        'endDate': ModelUtils.writeDay(endDate),
        'budgetMinor': budgetMinor,
        'currency': currency,
        'createdBy': createdBy,
        'memberIds': memberIds,
        'inviteCode': inviteCode,
        if (coverImageUrl != null && coverImageUrl!.isNotEmpty)
          'coverImageUrl': coverImageUrl,
        if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      };

  factory Trip.fromMap(String id, Map<String, dynamic> map) {
    final start = ModelUtils.readDay(map['startDate']);
    final end = ModelUtils.readDay(map['endDate'], fallback: start);
    final cover = ModelUtils.readString(map['coverImageUrl']);
    return Trip(
      id: id,
      name: ModelUtils.readString(map['name']),
      destination: ModelUtils.readString(map['destination']),
      startDate: start,
      endDate: end.isBefore(start) ? start : end,
      budgetMinor: ModelUtils.readInt(map['budgetMinor']),
      currency: ModelUtils.readString(map['currency'], 'INR'),
      createdBy: ModelUtils.readString(map['createdBy']),
      memberIds: ModelUtils.readStringList(map['memberIds']),
      inviteCode: ModelUtils.readString(map['inviteCode']),
      coverImageUrl: cover.isEmpty ? null : cover,
      createdAt: ModelUtils.readInstant(map['createdAt']),
    );
  }
}
