import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/ev_misc.dart';
import '../../providers/trip_workspace.dart';

class PackingScreen extends StatefulWidget {
  const PackingScreen({super.key, required this.tripId});
  final String tripId;

  @override
  State<PackingScreen> createState() => _PackingScreenState();
}

class _PackingScreenState extends State<PackingScreen> {
  final _item = TextEditingController();
  bool _adding = false;

  @override
  void dispose() {
    _item.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final name = _item.text.trim();
    if (name.isEmpty || _adding) return;
    setState(() => _adding = true);
    try {
      await context.read<TripWorkspace>().addPackingItem(name);
      _item.clear();
    } catch (error) {
      if (mounted) showEvSnack(context, 'Could not add item: $error', isError: true);
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final workspace = context.watch<TripWorkspace>();
    final items = [...workspace.packingItems]
      ..sort((a, b) {
        if (a.packed != b.packed) return a.packed ? 1 : -1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Packing list'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.trip(widget.tripId)),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(EvSpace.screenH),
          children: [
            Text('${workspace.packedCount} of ${workspace.packingItems.length} packed', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: workspace.packingItems.isEmpty ? 0 : workspace.packedCount / workspace.packingItems.length,
              minHeight: 7,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _item,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _add(),
                    decoration: const InputDecoration(labelText: 'Add something to pack', hintText: 'e.g. sunscreen'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(onPressed: _adding ? null : _add, icon: const Icon(Icons.add), tooltip: 'Add item'),
              ],
            ),
            const SizedBox(height: 16),
            if (!workspace.packingLoaded)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
            else if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: Text('Your checklist is empty. Add the first item above.')),
              )
            else
              ...items.map((item) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: CheckboxListTile(
                      value: item.packed,
                      title: Text(item.name, style: TextStyle(decoration: item.packed ? TextDecoration.lineThrough : null)),
                      onChanged: (value) async {
                        if (value == null) return;
                        try {
                          await workspace.setPacked(item.id, value);
                        } catch (error) {
                          if (context.mounted) showEvSnack(context, 'Could not update item: $error', isError: true);
                        }
                      },
                      secondary: IconButton(
                        tooltip: 'Delete item',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          try {
                            await workspace.deletePackingItem(item.id);
                          } catch (error) {
                            if (context.mounted) showEvSnack(context, 'Could not delete item: $error', isError: true);
                          }
                        },
                      ),
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}
