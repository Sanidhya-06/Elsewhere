import 'package:flutter_test/flutter_test.dart';
import 'package:elsewhere/models/expense.dart';
import 'package:elsewhere/models/settlement.dart';
import 'package:elsewhere/services/expense_calculator.dart';

void main() {
  group('ExpenseCalculator', () {
    test('splits evenly and distributes remainder deterministically', () {
      expect(ExpenseCalculator.splitEqually(100, ['b', 'a', 'c']),
          {'a': 34, 'b': 33, 'c': 33});
    });
    test('rejects empty participant list', () {
      expect(
          () => ExpenseCalculator.splitEqually(100, []), throwsArgumentError);
    });
    test('rejects negative amounts', () {
      expect(
          () => ExpenseCalculator.splitEqually(-1, ['a']), throwsArgumentError);
    });
    test('deduplicates participants and supports zero-value shares', () {
      expect(
          ExpenseCalculator.splitEqually(2, ['b', 'a', 'a']), {'a': 1, 'b': 1});
      expect(ExpenseCalculator.splitEqually(0, ['a', 'b']), {'a': 0, 'b': 0});
    });
    test('calculates zero-sum net balances', () {
      final expense = Expense(
          id: 'e1',
          description: 'Dinner',
          amountMinor: 900,
          currency: 'INR',
          category: 'Food',
          paidBy: 'a',
          participantIds: ['a', 'b', 'c'],
          shares: {'a': 300, 'b': 300, 'c': 300},
          date: DateTime.utc(2026, 1, 1),
          createdBy: 'a');
      final balances = ExpenseCalculator.netBalances(
          memberIds: ['a', 'b', 'c'],
          expenses: [expense],
          settlements: const []);
      expect(balances, {'a': 600, 'b': -300, 'c': -300});
      expect(ExpenseCalculator.isBalanced(balances), isTrue);
    });
    test('settlement reduces the outstanding balances', () {
      const settlement = Settlement(
          id: 's1',
          fromUserId: 'b',
          toUserId: 'a',
          amountMinor: 300,
          currency: 'INR',
          createdBy: 'b');
      final balances = ExpenseCalculator.netBalances(
          memberIds: ['a', 'b'], expenses: const [], settlements: [settlement]);
      expect(balances, {'a': -300, 'b': 300});
    });
    test('invalid stored shares fall back to an equal split', () {
      final expense = Expense(
          id: 'e2',
          description: 'Taxi',
          amountMinor: 101,
          currency: 'INR',
          category: 'Travel',
          paidBy: 'a',
          participantIds: ['a', 'b'],
          shares: {'a': 1},
          date: DateTime.utc(2026, 1, 1),
          createdBy: 'a');
      expect(ExpenseCalculator.sharesFor(expense), {'a': 51, 'b': 50});
      expect(
          ExpenseCalculator.isBalanced(ExpenseCalculator.netBalances(
              memberIds: ['a', 'b'],
              expenses: [expense],
              settlements: const [])),
          isTrue);
    });
    test('suggested transfers settle every balance', () {
      final transfers =
          ExpenseCalculator.suggestTransfers({'a': 700, 'b': -500, 'c': -200});
      expect(transfers, hasLength(2));
      expect(transfers.fold<int>(0, (sum, t) => sum + t.amountMinor), 700);
      expect(ExpenseCalculator.suggestTransfers({'a': 0, 'b': 0}), isEmpty);
    });
    test('aggregates spending and creates deterministic settlement ids', () {
      final expenses = [
        Expense(
            id: 'e1',
            description: 'Meal',
            amountMinor: 450,
            currency: 'INR',
            category: 'Food',
            paidBy: 'a',
            participantIds: ['a'],
            shares: {'a': 450},
            date: DateTime.utc(2026, 1, 1),
            createdBy: 'a'),
        Expense(
            id: 'e2',
            description: 'Coffee',
            amountMinor: 150,
            currency: 'INR',
            category: 'Food',
            paidBy: 'b',
            participantIds: ['b'],
            shares: {'b': 150},
            date: DateTime.utc(2026, 1, 1),
            createdBy: 'b'),
      ];
      expect(ExpenseCalculator.totalSpent(expenses), 600);
      expect(ExpenseCalculator.spentByCategory(expenses), {'Food': 600});
      expect(
          ExpenseCalculator.settlementId(
              fromUserId: 'b', toUserId: 'a', amountMinor: 300, sequence: 2),
          's_b_a_300_2');
    });
  });
}
