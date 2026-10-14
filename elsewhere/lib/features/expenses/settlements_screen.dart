import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/ev_misc.dart';
import '../../providers/trip_workspace.dart';

class SettlementsScreen extends StatelessWidget {
  const SettlementsScreen({super.key, required this.tripId});
  final String tripId;

  @override
  Widget build(BuildContext context) {
    final ws = context.watch<TripWorkspace>();
    final trip = ws.trip!;
    return Scaffold(
      appBar: AppBar(title: const Text('Settle up')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Everyone’s balance', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          ...ws.members.map((m) {
            final balance = ws.balances[m.userId] ?? 0;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(m.userId == ws.currentUserId ? '${m.displayName} (you)' : m.displayName),
              trailing: Text(
                EvFormat.money(balance, trip.currency, showPlus: true),
                style: TextStyle(
                  color: balance < 0 ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }),
          const Divider(height: 28),
          Text('Suggested payments', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (!ws.settlementsLoaded || !ws.expensesLoaded)
            const Center(child: CircularProgressIndicator())
          else if (ws.transfers.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('You’re all settled up. No payments needed.')),
            )
          else
            ...ws.transfers.map((transfer) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.swap_horiz),
                    title: Text('${ws.plainNameOf(transfer.fromUserId)} pays ${ws.plainNameOf(transfer.toUserId)}'),
                    subtitle: Text(EvFormat.money(transfer.amountMinor, trip.currency)),
                    trailing: IconButton(
                      tooltip: 'Record payment',
                      icon: const Icon(Icons.check_circle_outline),
                      onPressed: () async {
                        try {
                          await ws.recordSettlement(transfer);
                          if (context.mounted) showEvSnack(context, 'Payment recorded');
                        } catch (e) {
                          if (context.mounted) showEvSnack(context, 'Could not record payment: $e', isError: true);
                        }
                      },
                    ),
                  ),
                )),
          const SizedBox(height: 24),
          const EvSectionHeader(title: 'Recorded payments'),
          if (ws.settlements.isEmpty)
            const Text('Payments you record will appear here.')
          else
            ...ws.settlements.map((settlement) => ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: Text('${ws.plainNameOf(settlement.fromUserId)} paid ${ws.plainNameOf(settlement.toUserId)}'),
                  subtitle: Text(settlement.createdAt == null ? 'Recorded' : EvFormat.date(settlement.createdAt!)),
                  trailing: Text(EvFormat.money(settlement.amountMinor, settlement.currency)),
                )),
        ],
      ),
    );
  }
}
