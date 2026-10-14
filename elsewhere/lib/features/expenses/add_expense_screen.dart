import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/router/routes.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/ev_misc.dart';
import '../../models/expense.dart';
import '../../providers/auth_provider.dart';
import '../../providers/trip_workspace.dart';
import '../../services/expense_calculator.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key, required this.tripId});
  final String tripId;
  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _form = GlobalKey<FormState>();
  final _description = TextEditingController();
  final _amount = TextEditingController();
  String? _payer;
  String _category = AppConstants.expenseCategories.first;
  final DateTime _date = DateTime.now();
  final Set<String> _participants = {};
  bool _saving = false;

  @override
  void dispose() {
    _description.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    final ws = context.read<TripWorkspace>();
    final uid = context.read<AuthProvider>().user!.uid;
    final amount = EvFormat.parseMinor(_amount.text)!;
    final participants = _participants.isEmpty
        ? ws.members.map((m) => m.userId).toList()
        : _participants.toList();
    setState(() => _saving = true);
    try {
      await ws.addExpense(Expense(
          id: '',
          description: _description.text.trim(),
          amountMinor: amount,
          currency: ws.trip!.currency,
          category: _category,
          paidBy: _payer ?? uid,
          participantIds: participants,
          shares: ExpenseCalculator.splitEqually(amount, participants),
          date: DateTime.utc(_date.year, _date.month, _date.day),
          createdBy: uid));
      if (mounted) context.go(AppRoutes.budget(widget.tripId));
    } catch (e) {
      if (mounted) {
        showEvSnack(context, 'Could not save expense: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ws = context.watch<TripWorkspace>();
    final uid = context.read<AuthProvider>().user!.uid;
    _payer ??= uid;
    if (_participants.isEmpty) {
      _participants.addAll(ws.members.map((m) => m.userId));
    }
    return Scaffold(
        appBar: AppBar(title: const Text('Add expense')),
        body: SafeArea(
            child: Form(
                key: _form,
                child: ListView(padding: const EdgeInsets.all(24), children: [
                  TextFormField(
                      controller: _description,
                      decoration: const InputDecoration(
                          labelText: 'What was it for?',
                          hintText: 'e.g. Dinner by the beach'),
                      textCapitalization: TextCapitalization.sentences,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Add a description'
                          : null),
                  const SizedBox(height: 16),
                  TextFormField(
                      controller: _amount,
                      decoration: InputDecoration(
                          labelText: 'Amount',
                          prefixText:
                              '${EvFormat.currencySymbol(ws.trip!.currency)} '),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        final a = EvFormat.parseMinor(v ?? '');
                        return a == null || a <= 0
                            ? 'Enter an amount greater than zero'
                            : null;
                      }),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                      initialValue: _category,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: AppConstants.expenseCategories
                          .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _category = v ?? _category)),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                      initialValue: _payer,
                      decoration: const InputDecoration(labelText: 'Paid by'),
                      items: ws.members
                          .map((m) => DropdownMenuItem(
                              value: m.userId,
                              child: Text(m.userId == uid
                                  ? '${m.displayName} (you)'
                                  : m.displayName)))
                          .toList(),
                      onChanged: (v) => setState(() => _payer = v)),
                  const SizedBox(height: 18),
                  Text('Split between',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  ...ws.members.map((m) => CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _participants.contains(m.userId),
                      title: Text(m.userId == uid
                          ? '${m.displayName} (you)'
                          : m.displayName),
                      onChanged: (v) => setState(() {
                            if (v == true) {
                              _participants.add(m.userId);
                            } else if (_participants.length > 1) {
                              _participants.remove(m.userId);
                            }
                          }))),
                  const SizedBox(height: 24),
                  FilledButton(
                      onPressed: _saving ? null : _save,
                      child: Text(_saving ? 'Saving…' : 'Save expense')),
                ]))));
  }
}
