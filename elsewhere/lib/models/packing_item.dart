import 'package:cloud_firestore/cloud_firestore.dart';

import 'model_utils.dart';

/// A shared packing checklist item. Stored at
/// `trips/{tripId}/packingItems/{itemId}`.
class PackingItem {
  const PackingItem({
    required this.id,
    required this.name,
    this.packed = false,
    required this.addedBy,
    this.packedBy = '',
    this.createdAt,
  });

  final String id;
  final String name;
  final bool packed;
  final String addedBy;

  /// Who last ticked the item; empty when unpacked.
  final String packedBy;
  final DateTime? createdAt;

  Map<String, dynamic> toMap() => {
        'name': name,
        'packed': packed,
        'addedBy': addedBy,
        'packedBy': packedBy,
        if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      };

  factory PackingItem.fromMap(String id, Map<String, dynamic> map) =>
      PackingItem(
        id: id,
        name: ModelUtils.readString(map['name']),
        packed: map['packed'] == true,
        addedBy: ModelUtils.readString(map['addedBy']),
        packedBy: ModelUtils.readString(map['packedBy']),
        createdAt: ModelUtils.readInstant(map['createdAt']),
      );
}
