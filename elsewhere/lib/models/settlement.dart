import 'package:cloud_firestore/cloud_firestore.dart';

import 'model_utils.dart';

/// A recorded payment between two members. Stored at
/// `trips/{tripId}/settlements/{settlementId}`.
///
/// Elsewhere does not move money. A settlement is a record that one member
/// paid another outside the app, which brings their balances closer to zero.
class Settlement {
  const Settlement({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.amountMinor,
    required this.currency,
    this.status = statusSettled,
    required this.createdBy,
    this.createdAt,
  });

  static const String statusSettled = 'settled';

  /// The member who paid.
  final String fromUserId;

  /// The member who received the payment.
  final String toUserId;
  final int amountMinor;
  final String currency;
  final String status;
  final String createdBy;
  final DateTime? createdAt;

  final String id;

  Map<String, dynamic> toMap() => {
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'amountMinor': amountMinor,
        'currency': currency,
        'status': status,
        'createdBy': createdBy,
        if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      };

  factory Settlement.fromMap(String id, Map<String, dynamic> map) =>
      Settlement(
        id: id,
        fromUserId: ModelUtils.readString(map['fromUserId']),
        toUserId: ModelUtils.readString(map['toUserId']),
        amountMinor: ModelUtils.readInt(map['amountMinor']),
        currency: ModelUtils.readString(map['currency'], 'INR'),
        status: ModelUtils.readString(map['status'], statusSettled),
        createdBy: ModelUtils.readString(map['createdBy']),
        createdAt: ModelUtils.readInstant(map['createdAt']),
      );
}
