import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/ev_card.dart';
import '../../core/widgets/ev_misc.dart';
import '../../providers/trip_workspace.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key, required this.tripId});
  final String tripId;

  Future<void> _editBudget(BuildContext context, TripWorkspace ws) async {
    final controller = TextEditingController(
        text: ws.trip?.hasBudget == true
            ? EvFormat.minorToInput(ws.trip!.budgetMinor)
            : '');
    final formKey = GlobalKey<FormState>();
    final value = await showDialog<int?>(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text('Trip budget'),
              content: Form(
                  key: formKey,
                  child: TextFormField(
                      controller: controller,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                          labelText: 'Total budget', prefixText: '₹ '),
                      validator: (v) => EvFormat.parseMinor(v ?? '') == null
                          ? 'Enter a valid amount'
                          : null)),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel')),
                FilledButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        Navigator.pop(
                            ctx, EvFormat.parseMinor(controller.text));
                      }
                    },
                    child: const Text('Save'))
              ],
            ));
    controller.dispose();
    if (value == null) return;
    try {
      await ws.updateBudget(value);
    } catch (e) {
      if (context.mounted) {
        showEvSnack(context, 'Could not update budget: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ws = context.watch<TripWorkspace>();
    final trip = ws.trip!;
    final remaining = trip.budgetMinor - ws.totalSpent;
    final ratio = trip.budgetMinor <= 0
        ? 0.0
        : (ws.totalSpent / trip.budgetMinor).clamp(0.0, 1.0);
    final categories = ws.spentByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Scaffold(
      appBar: AppBar(title: const Text('Budget')),
      body: ListView(padding: const EdgeInsets.all(EvSpace.screenH), children: [
        EvCard(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('TRIP BUDGET'),
            IconButton(
                onPressed: () => _editBudget(context, ws),
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit budget')
          ]),
          Text(
              trip.hasBudget
                  ? EvFormat.money(trip.budgetMinor, trip.currency)
                  : 'Not set',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 18),
          const Text('Spent so far'),
          Text(EvFormat.money(ws.totalSpent, trip.currency),
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              borderRadius: BorderRadius.circular(8)),
          const SizedBox(height: 10),
          Text(trip.hasBudget
              ? '${EvFormat.money(remaining, trip.currency, showPlus: true)} ${remaining >= 0 ? 'left' : 'over budget'}'
              : 'Set a budget to track how much is left.')
        ])),
        const SizedBox(height: 24),
        const EvSectionHeader(title: 'Spending by category'),
        if (!ws.expensesLoaded)
          const Center(child: CircularProgressIndicator())
        else if (categories.isEmpty)
          const Text('No expenses yet. Add your first shared expense.')
        else
          ...categories.map((entry) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(entry.key),
              subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: LinearProgressIndicator(
                      value:
                          ws.totalSpent == 0 ? 0 : entry.value / ws.totalSpent,
                      minHeight: 5)),
              trailing: Text(EvFormat.money(entry.value, trip.currency)))),
        const SizedBox(height: 12),
        FilledButton.icon(
            onPressed: () => context.push(AppRoutes.newExpense(tripId)),
            icon: const Icon(Icons.add),
            label: const Text('Add expense')),
        TextButton.icon(
            onPressed: () => context.push(AppRoutes.expenses(tripId)),
            icon: const Icon(Icons.receipt_long_outlined),
            label: const Text('View expense history')),
        TextButton.icon(
            onPressed: () => context.push(AppRoutes.settlements(tripId)),
            icon: const Icon(Icons.swap_horiz),
            label: const Text('View settlements')),
      ]),
    );
  }
}
