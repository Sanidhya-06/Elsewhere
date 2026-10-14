import 'package:flutter/material.dart';

import '../utils/dates.dart';
import '../utils/formatters.dart';
import 'ev_text_field.dart';

/// A read-only field that opens the date picker. Values are date-only UTC
/// (see [EvDates]).
class EvDateField extends StatefulWidget {
  const EvDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.firstDate,
    required this.lastDate,
    this.validator,
    this.enabled = true,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final DateTime firstDate;
  final DateTime lastDate;
  final String? Function(DateTime? value)? validator;
  final bool enabled;

  @override
  State<EvDateField> createState() => _EvDateFieldState();
}

class _EvDateFieldState extends State<EvDateField> {
  late final TextEditingController _controller =
      TextEditingController(text: _format(widget.value));

  static String _format(DateTime? d) => d == null ? '' : EvFormat.date(d);

  @override
  void didUpdateWidget(EvDateField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.text = _format(widget.value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    var initial = widget.value ?? EvDates.todayUtc();
    if (initial.isBefore(widget.firstDate)) initial = widget.firstDate;
    if (initial.isAfter(widget.lastDate)) initial = widget.lastDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: EvDates.toLocalDay(initial),
      firstDate: EvDates.toLocalDay(widget.firstDate),
      lastDate: EvDates.toLocalDay(widget.lastDate),
    );
    if (picked != null) widget.onChanged(EvDates.dateOnly(picked));
  }

  @override
  Widget build(BuildContext context) {
    return EvTextField(
      controller: _controller,
      label: widget.label,
      readOnly: true,
      enabled: widget.enabled,
      onTap: _pick,
      suffixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
      validator: widget.validator == null
          ? null
          : (_) => widget.validator!(widget.value),
    );
  }
}
