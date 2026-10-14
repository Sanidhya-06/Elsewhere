import '../models/expense.dart';
import '../models/settlement.dart';

/// A suggested payment that would reduce outstanding balances.
class Transfer {
  const Transfer({
    required this.fromUserId,
    required this.toUserId,
    required this.amountMinor,
  });

  final String fromUserId;
  final String toUserId;
  final int amountMinor;

  @override
  bool operator ==(Object other) =>
      other is Transfer &&
      other.fromUserId == fromUserId &&
      other.toUserId == toUserId &&
      other.amountMinor == amountMinor;

  @override
  int get hashCode => Object.hash(fromUserId, toUserId, amountMinor);

  @override
  String toString() => 'Transfer($fromUserId -> $toUserId: $amountMinor)';
}

/// Pure expense and settlement arithmetic. No Flutter or Firebase calls, so it
/// is fully unit-testable. All amounts are integer minor units, which avoids
/// floating-point rounding entirely.
class ExpenseCalculator {
  ExpenseCalculator._();

  /// Splits [totalMinor] equally between [participantIds].
  ///
  /// Every share is `total ~/ n`; the remainder is handed out one minor unit at
  /// a time to participants in ascending id order. The result is deterministic
  /// and its values always sum to exactly [totalMinor].
  static Map<String, int> splitEqually(
    int totalMinor,
    Iterable<String> participantIds,
  ) {
    final ids = participantIds.toSet().toList()..sort();
    if (ids.isEmpty) {
      throw ArgumentError('An expense needs at least one participant.');
    }
    if (totalMinor < 0) {
      throw ArgumentError('An expense amount cannot be negative.');
    }
    final base = totalMinor ~/ ids.length;
    final remainder = totalMinor % ids.length;
    return {
      for (var i = 0; i < ids.length; i++) ids[i]: base + (i < remainder ? 1 : 0),
    };
  }

  /// The shares to use for [expense]: the stored shares when they are
  /// consistent, otherwise a fresh equal split of its participants.
  static Map<String, int> sharesFor(Expense expense) {
    final stored = expense.shares;
    final sum = stored.values.fold<int>(0, (a, b) => a + b);
    if (stored.isNotEmpty && sum == expense.amountMinor) return stored;
    if (expense.participantIds.isEmpty) return {};
    return splitEqually(expense.amountMinor, expense.participantIds);
  }

  /// Net balance per member, in minor units.
  ///
  /// Positive means the member is owed money; negative means they owe money.
  /// Recorded settlements are included: a payer's balance rises toward zero and
  /// the recipient's falls toward zero. Because every expense and settlement is
  /// zero-sum, the balances always add up to exactly zero.
  static Map<String, int> netBalances({
    required Iterable<String> memberIds,
    required Iterable<Expense> expenses,
    required Iterable<Settlement> settlements,
  }) {
    final balances = <String, int>{for (final id in memberIds) id: 0};

    void add(String id, int delta) =>
        balances.update(id, (v) => v + delta, ifAbsent: () => delta);

    for (final expense in expenses) {
      final shares = sharesFor(expense);
      if (shares.isEmpty) continue;
      add(expense.paidBy, expense.amountMinor);
      shares.forEach((id, share) => add(id, -share));
    }
    for (final s in settlements) {
      add(s.fromUserId, s.amountMinor);
      add(s.toUserId, -s.amountMinor);
    }
    return balances;
  }

  /// True if [balances] sum to zero (the invariant for a consistent ledger).
  static bool isBalanced(Map<String, int> balances) =>
      balances.values.fold<int>(0, (a, b) => a + b) == 0;

  /// Greedy settle-up suggestion: the largest debtor pays the largest creditor
  /// until everyone is square. Ties are broken by member id, so the result is
  /// deterministic.
  static List<Transfer> suggestTransfers(Map<String, int> balances) {
    int byAmountThenId(MapEntry<String, int> a, MapEntry<String, int> b) {
      final cmp = b.value.abs().compareTo(a.value.abs());
      return cmp != 0 ? cmp : a.key.compareTo(b.key);
    }

    final creditors = balances.entries.where((e) => e.value > 0).toList()
      ..sort(byAmountThenId);
    final debtors = balances.entries.where((e) => e.value < 0).toList()
      ..sort(byAmountThenId);

    final credit = [for (final c in creditors) [c.key, c.value]];
    final debt = [for (final d in debtors) [d.key, -d.value]];

    final transfers = <Transfer>[];
    var i = 0;
    var j = 0;
    while (i < debt.length && j < credit.length) {
      final owed = debt[i][1] as int;
      final due = credit[j][1] as int;
      final amount = owed < due ? owed : due;
      if (amount > 0) {
        transfers.add(Transfer(
          fromUserId: debt[i][0] as String,
          toUserId: credit[j][0] as String,
          amountMinor: amount,
        ));
      }
      debt[i][1] = owed - amount;
      credit[j][1] = due - amount;
      if ((debt[i][1] as int) == 0) i++;
      if ((credit[j][1] as int) == 0) j++;
    }
    return transfers;
  }

  /// Total spent across [expenses].
  static int totalSpent(Iterable<Expense> expenses) =>
      expenses.fold<int>(0, (sum, e) => sum + e.amountMinor);

  /// Spend per category.
  static Map<String, int> spentByCategory(Iterable<Expense> expenses) {
    final out = <String, int>{};
    for (final e in expenses) {
      out.update(e.category, (v) => v + e.amountMinor,
          ifAbsent: () => e.amountMinor);
    }
    return out;
  }

  /// Deterministic settlement document id.
  ///
  /// Two attempts to record the same payment from the same ledger state map to
  /// the same document id, so the second attempt is rejected as a duplicate
  /// instead of creating a second record. [sequence] is the number of
  /// settlements already recorded for the trip.
  static String settlementId({
    required String fromUserId,
    required String toUserId,
    required int amountMinor,
    required int sequence,
  }) =>
      's_${fromUserId}_${toUserId}_${amountMinor}_$sequence';
}
