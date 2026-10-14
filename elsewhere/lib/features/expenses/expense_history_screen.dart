import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/routes.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/ev_misc.dart';
import '../../providers/trip_workspace.dart';

class ExpenseHistoryScreen extends StatelessWidget {
  const ExpenseHistoryScreen({super.key, required this.tripId});
  final String tripId;

  @override
  Widget build(BuildContext context) {
    final workspace = context.watch<TripWorkspace>();
    final expenses = [...workspace.expenses]..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense history'),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.newExpense(tripId)),
            icon: const Icon(Icons.add),
            tooltip: 'Add expense',
          ),
        ],
      ),
      body: !workspace.expensesLoaded
          ? const Center(child: CircularProgressIndicator())
          : expenses.isEmpty
              ? const Center(child: Text('No expenses recorded yet.'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text('Total · ${EvFormat.money(workspace.totalSpent, workspace.trip!.currency)}', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    ...expenses.map((expense) => Card(
                          child: ListTile(
                            leading: const CircleAvatar(child: Icon(Icons.receipt_long_outlined)),
                            title: Text(expense.description),
                            subtitle: Text('${expense.category} · ${EvFormat.date(expense.date)}\nPaid by ${workspace.plainNameOf(expense.paidBy)}'),
                            isThreeLine: true,
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(EvFormat.money(expense.amountMinor, expense.currency), style: Theme.of(context).textTheme.titleSmall),
                                if (expense.createdBy == workspace.currentUserId)
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    tooltip: 'Delete expense',
                                    icon: const Icon(Icons.delete_outline, size: 18),
                                    onPressed: () async {
                                      final confirmed = await confirmDialog(
                                        context,
                                        title: 'Delete expense?',
                                        message: 'This removes ${expense.description} from the shared ledger.',
                                        confirmLabel: 'Delete',
                                        destructive: true,
                                      );
                                      if (!confirmed) return;
                                      try {
                                        await workspace.deleteExpense(expense.id);
                                      } catch (error) {
                                        if (context.mounted) showEvSnack(context, 'Could not delete expense: $error', isError: true);
                                      }
                                    },
                                  ),
                              ],
                            ),
                          ),
                        )),
                  ],
                ),
    );
  }
}
