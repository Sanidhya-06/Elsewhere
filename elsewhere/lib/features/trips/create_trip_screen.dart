import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/app_exception.dart';
import '../../core/utils/dates.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/ev_button.dart';
import '../../core/widgets/ev_date_field.dart';
import '../../core/widgets/ev_misc.dart';
import '../../core/widgets/ev_text_field.dart';
import '../../models/trip.dart';
import '../../providers/auth_provider.dart';
import '../../providers/trips_provider.dart';

class CreateTripScreen extends StatefulWidget {
  const CreateTripScreen({super.key});

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _destination = TextEditingController();
  final _budget = TextEditingController();
  final _cover = TextEditingController();

  DateTime? _start;
  DateTime? _end;
  String _currency = AppConstants.defaultCurrency;
  String? _dateError;
  bool _submitting = false;

  @override
  void dispose() {
    _name.dispose();
    _destination.dispose();
    _budget.dispose();
    _cover.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    FocusScope.of(context).unfocus();
    final fieldsValid = _formKey.currentState?.validate() ?? false;
    final rangeError = Validators.dateRange(_start, _end);
    setState(() => _dateError = rangeError);
    if (!fieldsValid || rangeError != null) return;

    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    final trips = context.read<TripsProvider>();

    final draft = Trip(
      id: '',
      name: _name.text.trim(),
      destination: _destination.text.trim(),
      startDate: _start!,
      endDate: _end!,
      budgetMinor: EvFormat.parseMinor(_budget.text) ?? 0,
      currency: _currency,
      createdBy: user.uid,
      memberIds: [user.uid],
      inviteCode: '',
      coverImageUrl: _cover.text.trim().isEmpty ? null : _cover.text.trim(),
    );

    setState(() => _submitting = true);
    try {
      final id = await trips.createTrip(draft: draft, creator: user);
      if (!mounted) return;
      context.pushReplacement(AppRoutes.trip(id));
    } catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      showEvSnack(context, friendlyError(error), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final today = EvDates.todayUtc();
    final first = today.subtract(const Duration(days: 30));
    final last = DateTime.utc(today.year + 5, 12, 31);

    return Scaffold(
      appBar: AppBar(title: const Text('New trip')),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(EvSpace.screenH),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Where to?', style: text.headlineMedium),
                const SizedBox(height: EvSpace.s8),
                Text(
                  'Give the trip a name and a destination. You can invite friends right after.',
                  style: text.bodyMedium,
                ),
                const SizedBox(height: EvSpace.s24),
                EvTextField(
                  controller: _destination,
                  label: 'Destination',
                  hint: 'e.g. Goa, India',
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  maxLength: AppConstants.maxNameLength,
                  validator: (v) => Validators.name(v, field: 'Destination'),
                ),
                const SizedBox(height: EvSpace.s16),
                EvTextField(
                  controller: _name,
                  label: 'Trip name',
                  hint: 'e.g. Monsoon escape',
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  maxLength: AppConstants.maxNameLength,
                  validator: (v) => Validators.name(v, field: 'Trip name'),
                ),
                const SizedBox(height: EvSpace.s16),
                EvDateField(
                  label: 'Start date',
                  value: _start,
                  firstDate: first,
                  lastDate: last,
                  onChanged: (d) => setState(() {
                    _start = d;
                    if (_end != null && _end!.isBefore(d)) _end = d;
                    _dateError = null;
                  }),
                  validator: (v) => v == null ? 'Choose a start date.' : null,
                ),
                const SizedBox(height: EvSpace.s16),
                EvDateField(
                  label: 'End date',
                  value: _end,
                  firstDate: _start ?? first,
                  lastDate: last,
                  onChanged: (d) => setState(() {
                    _end = d;
                    _dateError = null;
                  }),
                  validator: (v) => v == null ? 'Choose an end date.' : null,
                ),
                if (_dateError != null) ...[
                  const SizedBox(height: EvSpace.s8),
                  Text(_dateError!,
                      style: text.bodySmall?.copyWith(color: EvColors.error)),
                ],
                const SizedBox(height: EvSpace.s24),
                Text('Currency', style: text.titleSmall),
                const SizedBox(height: EvSpace.s8),
                Wrap(
                  spacing: EvSpace.s8,
                  runSpacing: EvSpace.s8,
                  children: [
                    for (final code in AppConstants.currencies)
                      FilterChip(
                        label: Text('${EvFormat.currencySymbol(code)} $code'),
                        selected: _currency == code,
                        onSelected: (_) => setState(() => _currency = code),
                      ),
                  ],
                ),
                const SizedBox(height: EvSpace.s16),
                EvTextField(
                  controller: _budget,
                  label: 'Budget (optional)',
                  helper: 'Total for the whole group. You can change it later.',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.next,
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: EvSpace.s16),
                    child: Align(
                      widthFactor: 1,
                      child: Text(EvFormat.currencySymbol(_currency),
                          style: text.bodyLarge),
                    ),
                  ),
                  validator: (v) =>
                      Validators.optionalAmount(v, field: 'Budget'),
                ),
                const SizedBox(height: EvSpace.s16),
                EvTextField(
                  controller: _cover,
                  label: 'Cover photo link (optional)',
                  helper: 'An https:// link to a photo. Leave blank for a placeholder.',
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.done,
                  validator: Validators.optionalHttpsUrl,
                ),
                const SizedBox(height: EvSpace.s32),
                EvButton.accent(
                  label: 'Create trip',
                  loading: _submitting,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
