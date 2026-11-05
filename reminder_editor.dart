import 'package:flutter/material.dart';

import 'reminder.dart';
import 'app_strings.dart';
import 'app_controller.dart';
import 'assistant_parser.dart';

class ReminderEditor extends StatefulWidget {
  const ReminderEditor({
    super.key,
    required this.controller,
    this.reminder,
    this.draft,
  });

  final AppController controller;
  final Reminder? reminder;
  final ReminderDraft? draft;

  @override
  State<ReminderEditor> createState() => _ReminderEditorState();
}

class _ReminderEditorState extends State<ReminderEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late DateTime _date;
  late TimeOfDay _time;
  late ReminderRecurrence _recurrence;
  late List<int> _weekdays;
  late String _category;
  late int _priority;
  bool _saving = false;

  AppStrings get _s => AppStrings(widget.controller.settings.uiLanguage);

  @override
  void initState() {
    super.initState();
    final existing = widget.reminder;
    final draft = widget.draft;
    final initialDate = existing?.dueAt ?? draft?.dueAt ?? _nextHour();
    _title = TextEditingController(text: existing?.title ?? draft?.title ?? '');
    _description = TextEditingController(
      text: existing?.description ?? draft?.description ?? '',
    );
    _date = DateTime(initialDate.year, initialDate.month, initialDate.day);
    _time = TimeOfDay(hour: initialDate.hour, minute: initialDate.minute);
    _recurrence =
        existing?.recurrence ?? draft?.recurrence ?? ReminderRecurrence.none;
    _weekdays = List.of(existing?.weekdays ?? draft?.weekdays ?? const []);
    _category = existing?.category ?? 'general';
    _priority = existing?.priority ?? 1;
  }

  DateTime _nextHour() {
    final now = DateTime.now();
    final next = DateTime(now.year, now.month, now.day, now.hour + 1);
    return next;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final earliestDefault = DateTime.now().subtract(const Duration(days: 365));
    final reminderDate = DateTime(_date.year, _date.month, _date.day);
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: reminderDate.isBefore(earliestDefault)
          ? reminderDate
          : earliestDefault,
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (selected != null) setState(() => _date = selected);
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(context: context, initialTime: _time);
    if (selected != null) setState(() => _time = selected);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_recurrence == ReminderRecurrence.weekly && _weekdays.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_s.text('choose_day'))));
      return;
    }
    final now = DateTime.now();
    final old = widget.reminder;
    var dueAt = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _time.hour,
      _time.minute,
    );
    if (_recurrence == ReminderRecurrence.daily) {
      final today = DateTime(now.year, now.month, now.day);
      if (dueAt.isBefore(today)) {
        dueAt = DateTime(
          today.year,
          today.month,
          today.day,
          _time.hour,
          _time.minute,
        );
      }
      if (!dueAt.isAfter(now)) dueAt = dueAt.add(const Duration(days: 1));
    } else if (_recurrence == ReminderRecurrence.weekly) {
      final today = DateTime(now.year, now.month, now.day);
      final start = DateTime(_date.year, _date.month, _date.day).isBefore(today)
          ? today
          : _date;
      for (var offset = 0; offset < 14; offset++) {
        final candidateDate = start.add(Duration(days: offset));
        final candidate = DateTime(
          candidateDate.year,
          candidateDate.month,
          candidateDate.day,
          _time.hour,
          _time.minute,
        );
        if (_weekdays.contains(candidate.weekday) && candidate.isAfter(now)) {
          dueAt = candidate;
          break;
        }
      }
    } else if (_recurrence == ReminderRecurrence.monthly) {
      final selectedMonth = DateTime(_date.year, _date.month, 1);
      final currentMonth = DateTime(now.year, now.month, 1);
      final startMonth = selectedMonth.isBefore(currentMonth)
          ? currentMonth
          : selectedMonth;
      for (var offset = 0; offset < 120; offset++) {
        final month = DateTime(startMonth.year, startMonth.month + offset, 1);
        final monthDay = _date.day
            .clamp(1, DateTime(month.year, month.month + 1, 0).day)
            .toInt();
        final candidate = DateTime(
          month.year,
          month.month,
          monthDay,
          _time.hour,
          _time.minute,
        );
        if (candidate.isAfter(now)) {
          dueAt = candidate;
          break;
        }
      }
    } else if (!dueAt.isAfter(now)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_s.text('past_time'))));
      return;
    }
    setState(() => _saving = true);
    final keepMonthlyAnchor =
        old != null &&
        old.recurrence == ReminderRecurrence.monthly &&
        _recurrence == ReminderRecurrence.monthly &&
        old.dueAt.year == _date.year &&
        old.dueAt.month == _date.month &&
        old.dueAt.day == _date.day;
    final reminder = Reminder(
      id: old?.id ?? now.microsecondsSinceEpoch.toString(),
      title: _title.text.trim(),
      description: _description.text.trim(),
      dueAt: dueAt,
      hour: _time.hour,
      minute: _time.minute,
      monthDay: keepMonthlyAnchor ? (old?.monthDay ?? _date.day) : _date.day,
      recurrence: _recurrence,
      weekdays: _recurrence == ReminderRecurrence.weekly
          ? (List<int>.of(_weekdays)..sort())
          : const [],
      category: _category,
      priority: _priority,
      status: ReminderStatus.pending,
      createdAt: old?.createdAt ?? now,
      updatedAt: now,
      triggeredAt: null,
      source: old?.source ?? (widget.draft == null ? 'text' : 'voice'),
    );
    try {
      await widget.controller.saveReminder(reminder);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_s.text('reminder_saved'))));
      Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saqlash amalga oshmadi: $error')),
        );
        setState(() => _saving = false);
      }
    }
  }

  String _dateLabel() {
    return MaterialLocalizations.of(context).formatMediumDate(_date);
  }

  String _recurrenceName(ReminderRecurrence value) => switch (value) {
    ReminderRecurrence.none => _s.text('no_repeat'),
    ReminderRecurrence.daily => _s.text('daily'),
    ReminderRecurrence.weekly => _s.text('weekly'),
    ReminderRecurrence.monthly => _s.text('monthly'),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final language = widget.controller.settings.uiLanguage;
    final dayNames = switch (language) {
      'en' => const ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
      'ru' => const ['П', 'В', 'С', 'Ч', 'П', 'С', 'В'],
      _ => const ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh', 'Ya'],
    };
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.reminder == null ? _s.text('add_reminder') : _s.text('edit'),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              if (widget.draft != null && !widget.draft!.isCertain)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${_s.text('parse_uncertain')} ${widget.draft!.explanation}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              TextFormField(
                controller: _title,
                autofocus: widget.reminder == null,
                maxLength: 120,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: _s.text('title'),
                  prefixIcon: const Icon(Icons.edit_note_rounded),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? _s.text('no_title')
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _description,
                maxLines: 3,
                maxLength: 500,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: _s.text('description'),
                  prefixIcon: const Icon(Icons.notes_rounded),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _PickerTile(
                      icon: Icons.calendar_month_rounded,
                      label: _s.text('date'),
                      value: _dateLabel(),
                      onTap: _pickDate,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PickerTile(
                      icon: Icons.schedule_rounded,
                      label: _s.text('time'),
                      value: _time.format(context),
                      onTap: _pickTime,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text(_s.text('repeat'), style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              DropdownButtonFormField<ReminderRecurrence>(
                value: _recurrence,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.repeat_rounded),
                ),
                items: ReminderRecurrence.values
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(_recurrenceName(value)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _recurrence = value);
                },
              ),
              if (_recurrence == ReminderRecurrence.weekly) ...[
                const SizedBox(height: 14),
                Text(_s.text('weekdays'), style: theme.textTheme.titleSmall),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: List.generate(7, (index) {
                    final weekday = index + 1;
                    final selected = _weekdays.contains(weekday);
                    return FilterChip(
                      label: Text(dayNames[index]),
                      selected: selected,
                      onSelected: (value) => setState(() {
                        if (value) {
                          _weekdays.add(weekday);
                        } else {
                          _weekdays.remove(weekday);
                        }
                      }),
                    );
                  }),
                ),
              ],
              const SizedBox(height: 22),
              Text(_s.text('category'), style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.folder_open_rounded),
                ),
                items: ['general', 'work', 'personal', 'health', 'study']
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(_s.text(value)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _category = value);
                },
              ),
              const SizedBox(height: 22),
              Text(_s.text('priority'), style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              SegmentedButton<int>(
                segments: [
                  ButtonSegment(value: 0, label: Text(_s.text('low'))),
                  ButtonSegment(value: 1, label: Text(_s.text('normal'))),
                  ButtonSegment(value: 2, label: Text(_s.text('high'))),
                ],
                selected: {_priority},
                onSelectionChanged: (values) =>
                    setState(() => _priority = values.first),
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(_s.text('save')),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(
        context,
      ).colorScheme.primaryContainer.withValues(alpha: .45),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 12),
              Text(label, style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 3),
              Text(value, maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}
