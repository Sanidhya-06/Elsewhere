import 'package:flutter_test/flutter_test.dart';
import 'package:elsewhere/models/app_user.dart';
import 'package:elsewhere/models/expense.dart';
import 'package:elsewhere/models/packing_item.dart';
import 'package:elsewhere/models/settlement.dart';
import 'package:elsewhere/models/trip.dart';
import 'package:elsewhere/models/trip_member.dart';
import 'package:elsewhere/core/utils/formatters.dart';

void main() {
  test('trip computes inclusive duration', () {
    final trip = Trip(
        id: 't',
        name: 'Goa',
        destination: 'Goa',
        startDate: DateTime.utc(2026, 1, 1),
        endDate: DateTime.utc(2026, 1, 3),
        budgetMinor: 0,
        currency: 'INR',
        createdBy: 'u',
        memberIds: ['u'],
        inviteCode: 'ABCD2345');
    expect(trip.dayCount, 3);
    expect(trip.hasBudget, isFalse);
  });
  test('money parser stores amounts in minor units', () {
    expect(EvFormat.parseMinor('1,250.50'), 125050);
    expect(EvFormat.parseMinor('12.345'), isNull);
  });

  test('trip round-trips date-only values and optional fields', () {
    final trip = Trip(
      id: 't1',
      name: 'Coast',
      destination: 'Goa',
      startDate: DateTime.utc(2026, 3, 1),
      endDate: DateTime.utc(2026, 3, 4),
      budgetMinor: 125000,
      currency: 'INR',
      createdBy: 'u1',
      memberIds: ['u1', 'u2'],
      inviteCode: 'ABCD2345',
      coverImageUrl: 'https://example.com/coast.jpg',
      createdAt: DateTime.utc(2026, 1, 1),
    );
    final restored = Trip.fromMap('t1', trip.toMap());

    expect(restored.startDate, trip.startDate);
    expect(restored.endDate, trip.endDate);
    expect(restored.budgetMinor, trip.budgetMinor);
    expect(restored.memberIds, trip.memberIds);
    expect(restored.coverImageUrl, trip.coverImageUrl);
    expect(restored.createdAt!.isAtSameMomentAs(trip.createdAt!), isTrue);
  });

  test('expense, member, settlement, and packing item round-trip', () {
    final date = DateTime.utc(2026, 4, 2);
    final expense = Expense(
      id: 'e1',
      description: 'Lunch',
      amountMinor: 900,
      currency: 'INR',
      category: 'Food',
      paidBy: 'u1',
      participantIds: ['u1', 'u2'],
      shares: {'u1': 450, 'u2': 450},
      date: date,
      createdBy: 'u1',
    );
    final restoredExpense = Expense.fromMap('e1', expense.toMap());
    expect(restoredExpense.amountMinor, 900);
    expect(restoredExpense.shares, {'u1': 450, 'u2': 450});
    expect(restoredExpense.date, date);

    final member = TripMember(
      userId: 'u1',
      displayName: 'Sam',
      role: MemberRole.owner,
      inviteCode: 'ABCD2345',
      joinedAt: date,
    );
    expect(TripMember.fromMap('u1', member.toMap()).isOwner, isTrue);
    expect(
        TripMember.fromMap('u2', {'role': 'unknown'}).role, MemberRole.member);

    const settlement = Settlement(
      id: 's1',
      fromUserId: 'u2',
      toUserId: 'u1',
      amountMinor: 450,
      currency: 'INR',
      createdBy: 'u2',
    );
    expect(Settlement.fromMap('s1', settlement.toMap()).amountMinor, 450);

    const item = PackingItem(
        id: 'p1', name: 'Adapter', addedBy: 'u1', packed: true, packedBy: 'u2');
    final restoredItem = PackingItem.fromMap('p1', item.toMap());
    expect(restoredItem.packed, isTrue);
    expect(restoredItem.packedBy, 'u2');
  });

  test('app user first name handles whitespace and empty names', () {
    expect(
        const AppUser(
                uid: 'u1', displayName: '  Sam Lee ', email: 'sam@example.com')
            .firstName,
        'Sam');
    expect(
        const AppUser(uid: 'u1', displayName: ' ', email: 'sam@example.com')
            .firstName,
        'there');
  });
}
