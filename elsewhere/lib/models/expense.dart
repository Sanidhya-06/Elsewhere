import 'package:cloud_firestore/cloud_firestore.dart';

import 'model_utils.dart';

/// A shared expense. Stored at `trips/{tripId}/expenses/{expenseId}`.
///
/// `shares` holds each participant's share in minor units, computed once when
/// the expense is created (equal split, deterministic remainder). Storing it
/// means balances never change retroactively if the splitting algorithm does.
class Expense {
  const Expense({
    required this.id,
    required this.description,
    required this.amountMinor,
    required this.currency,
    required this.category,
    required this.paidBy,
    required this.participantIds,
    required this.shares,
    required this.date,
    required this.createdBy,
    this.createdAt,
  });

  final String id;
  final String description;

  /// Total in minor currency units (paise, cents, pence).
  final int amountMinor;
  final String currency;
  final String category;
  final String paidBy;
  final List<String> participantIds;
  final Map<String, int> shares;

  /// Date-only UTC value.
  final DateTime date;
  final String createdBy;
  final DateTime? createdAt;

  Map<String, dynamic> toMap() => {
        'description': description,
        'amountMinor': amountMinor,
        'currency': currency,
        'category': category,
        'paidBy': paidBy,
        'participantIds': participantIds,
        'shares': shares,
        'date': ModelUtils.writeDay(date),
        'createdBy': createdBy,
        if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      };

  factory Expense.fromMap(String id, Map<String, dynamic> map) => Expense(
        id: id,
        description: ModelUtils.readString(map['description']),
        amountMinor: ModelUtils.readInt(map['amountMinor']),
        currency: ModelUtils.readString(map['currency'], 'INR'),
        category: ModelUtils.readString(map['category'], 'Other'),
        paidBy: ModelUtils.readString(map['paidBy']),
        participantIds: ModelUtils.readStringList(map['participantIds']),
        shares: ModelUtils.readIntMap(map['shares']),
        date: ModelUtils.readDay(map['date']),
        createdBy: ModelUtils.readString(map['createdBy']),
        createdAt: ModelUtils.readInstant(map['createdAt']),
      );
}
