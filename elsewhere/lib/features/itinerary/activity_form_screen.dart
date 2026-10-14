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
import '../../core/widgets/state_views.dart';
import '../../models/activity.dart';
import '../../models/trip.dart';
import '../../providers/trip_workspace.dart';

/// Add or edit an activity. [activityId] is null when adding.
class ActivityFormScreen extends StatelessWidget {
  const ActivityFormScreen({super.key, this.activityId});

  final String? activityId;

  @override
  Widget build(BuildContext context) {
    final ws = context.watch<TripWorkspace>();
    final trip = ws.trip;
    if (trip == null) return const SizedBox.shrink();

    final id = activityId;
    if (id == null) {
      return _ActivityForm(trip: trip, initial: null);
    }

    // Editing: wait for the itinerary, then handle a missing activity.
    if (!ws.activitiesLoaded) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit activity')),
        body: const EvLoading(),
      );
    }
    final existing = ws.activityById(id);
    if (existing == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit activity')),
        body: EvErrorState(
          title: 'Activity not found',
          message: 'It may have been deleted by someone else on the trip.',
          retryLabel: 'Back to itinerary',
          onRetry: () => context.go(AppRoutes.itinerary(trip.id)),
        ),
      );
    }
    return _ActivityForm(trip: trip, initial: existing);
  }
}

class _ActivityForm extends StatefulWidget {
  const _ActivityForm({required this.trip, required this.initial});

  final Trip trip;
  final Activity? initial;

  @override
  State<_ActivityForm> createState() => _ActivityFormState();
}

class _ActivityFormState extends State<_ActivityForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _location;
  late final TextEditingController _cost;
  late final TextEditingController _notes;
  late final TextEditingController _timeText;

  late DateTime _date;
  String? _time; // "HH:mm"
  bool _saving = false;
  bool _deleting = false;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final a = widget.initial;
    _title = TextEditingController(text: a?.title ?? '');
    _location = TextEditingController(text: a?.location ?? '');
    _cost = TextEditingController(
        text: (a != null && a.costMinor > 0)
            ? EvFormat.minorToInput(a.costMinor)
            : '');
    _notes = TextEditingController(text: a?.notes ?? '');
    _time = a?.time;
    _timeText = TextEditingController(
        text: _time == null ? '' : EvFormat.time(_time!));

    var date = a?.date ?? EvDates.todayUtc();
    if (date.isBefore(widget.trip.startDate)) date = widget.trip.startDate;
    if (date.isAfter(widget.trip.endDate)) date = widget.trip.endDate;
    _date = date;
  }

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    _cost.dispose();
    _notes.dispose();
    _timeText.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    var initial = const TimeOfDay(hour: 9, minute: 0);
    final t = _time;
    if (t != null) {
      final parts = t.split(':');
      final h = int.tryParse(parts.first);
      final m = int.tryParse(parts.last);
      if (h != null && m != null) initial = TimeOfDay(hour: h, minute: m);
    }
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    setState(() {
      _time =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      _timeText.text = EvFormat.time(_time!);
    });
  }

  void _clearTime() {
    setState(() {
      _time = null;
      _timeText.clear();
    });
  }

  Future<void> _save() async {
    if (_saving || _deleting) return;
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ws = context.read<TripWorkspace>();

    final activity = Activity(
      id: widget.initial?.id ?? '',
      title: _title.text.trim(),
      location: _location.text.trim(),
      date: _date,
      time: _time,
      costMinor: EvFormat.parseMinor(_cost.text) ?? 0,
      notes: _notes.text.trim(),
      createdBy: widget.initial?.createdBy ?? ws.currentUserId,
      createdAt: widget.initial?.createdAt,
    );

    setState(() => _saving = true);
    try {
      if (_isEdit) {
        await ws.updateActivity(activity);
      } else {
        await ws.addActivity(activity);
      }
      if (!mounted) return;
      _close();
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      showEvSnack(context, friendlyError(error), isError: true);
    }
  }

  Future<void> _delete() async {
    final initial = widget.initial;
    if (initial == null || _saving || _deleting) return;
    final ok = await confirmDialog(
      context,
      title: 'Delete this activity?',
      message: '"${initial.title}" will be removed for everyone on the trip.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok || !mounted) return;
    final ws = context.read<TripWorkspace>();
    setState(() => _deleting = true);
    try {
      await ws.deleteActivity(initial.id);
      if (!mounted) return;
      _close();
    } catch (error) {
      if (!mounted) return;
      setState(() => _deleting = false);
      showEvSnack(context, friendlyError(error), isError: true);
    }
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.itinerary(widget.trip.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit activity' : 'New activity'),
        leading: IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close),
          onPressed: (_saving || _deleting) ? null : _close,
        ),
        actions: [
          if (_isEdit)
            IconButton(
              tooltip: 'Delete activity',
              icon: const Icon(Icons.delete_outline),
              onPressed: (_saving || _deleting) ? null : _delete,
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(EvSpace.screenH),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EvTextField(
                  controller: _title,
                  label: 'What are you doing?',
                  hint: 'e.g. Sunset at the fort',
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  maxLength: 120,
                  validator: (v) => Validators.name(v, field: 'Activity'),
                ),
                const SizedBox(height: EvSpace.s16),
                EvTextField(
                  controller: _location,
                  label: 'Location (optional)',
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  maxLength: 120,
                  prefixIcon: const Icon(Icons.place_outlined),
                ),
                const SizedBox(height: EvSpace.s16),
                EvDateField(
                  label: 'Day',
                  value: _date,
                  firstDate: trip.startDate,
                  lastDate: trip.endDate,
                  onChanged: (d) => setState(() => _date = d),
                  validator: (d) {
                    if (d == null) return 'Choose a day.';
                    if (d.isBefore(trip.startDate) || d.isAfter(trip.endDate)) {
                      return 'Pick a day within the trip dates.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: EvSpace.s16),
                EvTextField(
                  controller: _timeText,
                  label: 'Time (optional)',
                  readOnly: true,
                  onTap: _pickTime,
                  prefixIcon: const Icon(Icons.schedule_outlined),
                  suffixIcon: _time == null
                      ? null
                      : IconButton(
                          tooltip: 'Clear time',
                          icon: const Icon(Icons.clear),
                          onPressed: _clearTime,
                        ),
                ),
                const SizedBox(height: EvSpace.s16),
                EvTextField(
                  controller: _cost,
                  label: 'Estimated cost (optional)',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.next,
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: EvSpace.s16),
                    child: Align(
                      widthFactor: 1,
                      child: Text(EvFormat.currencySymbol(trip.currency),
                          style: Theme.of(context).textTheme.bodyLarge),
                    ),
                  ),
                  validator: (v) =>
                      Validators.optionalAmount(v, field: 'Cost'),
                ),
                const SizedBox(height: EvSpace.s16),
                EvTextField(
                  controller: _notes,
                  label: 'Notes (optional)',
                  maxLines: 4,
                  maxLength: AppConstants.maxNoteLength,
                  textCapitalization: TextCapitalization.sentences,
                  validator: Validators.note,
                ),
                const SizedBox(height: EvSpace.s24),
                EvButton.primary(
                  label: _isEdit ? 'Save changes' : 'Add to itinerary',
                  loading: _saving,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
