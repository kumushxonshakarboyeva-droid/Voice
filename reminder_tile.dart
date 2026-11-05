import 'package:flutter/material.dart';

import 'reminder.dart';
import 'app_strings.dart';
import 'app_controller.dart';
import 'reminder_editor.dart';

class ReminderTile extends StatelessWidget {
  const ReminderTile({
    super.key,
    required this.controller,
    required this.reminder,
    this.showStatus = false,
    this.onChanged,
  });

  final AppController controller;
  final Reminder reminder;
  final bool showStatus;
  final VoidCallback? onChanged;

  AppStrings get _s => AppStrings(controller.settings.uiLanguage);

  Future<void> _edit(BuildContext context) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            ReminderEditor(controller: controller, reminder: reminder),
      ),
    );
    onChanged?.call();
  }

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_s.text('delete_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(_s.text('cancel')),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: Text(_s.text('delete')),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.deleteReminder(reminder.id);
      onChanged?.call();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_s.text('reminder_deleted'))));
      }
    }
  }

  String _recurrenceLabel() => switch (reminder.recurrence) {
    ReminderRecurrence.none => '',
    ReminderRecurrence.daily => _s.text('daily'),
    ReminderRecurrence.weekly => _s.text('weekly'),
    ReminderRecurrence.monthly => _s.text('monthly'),
  };

  String _statusLabel() => switch (reminder.status) {
    ReminderStatus.pending => _s.text('pending'),
    ReminderStatus.ringing => _s.text('ringing'),
    ReminderStatus.snoozed => _s.text('snoozed'),
    ReminderStatus.completed => _s.text('completed'),
    ReminderStatus.missed => _s.text('missed'),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = reminder.priority == 2
        ? theme.colorScheme.error
        : theme.colorScheme.primary;
    final time = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay(hour: reminder.dueAt.hour, minute: reminder.dueAt.minute),
    );
    final day = MaterialLocalizations.of(
      context,
    ).formatMediumDate(reminder.dueAt);
    return Card(
      child: InkWell(
        onTap: () => _edit(context),
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(15, 12, 8, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 68,
                margin: const EdgeInsets.only(right: 13, top: 3),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            reminder.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (reminder.priority == 2)
                          Icon(
                            Icons.priority_high_rounded,
                            size: 18,
                            color: accent,
                          ),
                        PopupMenuButton<String>(
                          tooltip: _s.text('edit'),
                          onSelected: (value) {
                            if (value == 'edit') _edit(context);
                            if (value == 'delete') _delete(context);
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Text(_s.text('edit')),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text(_s.text('delete')),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (reminder.description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          reminder.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _Meta(icon: Icons.schedule_rounded, text: time),
                        _Meta(icon: Icons.calendar_today_rounded, text: day),
                        if (_recurrenceLabel().isNotEmpty)
                          _Meta(
                            icon: Icons.repeat_rounded,
                            text: _recurrenceLabel(),
                          ),
                        if (showStatus)
                          Chip(
                            label: Text(_statusLabel()),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                          ),
                      ],
                    ),
                    if (!showStatus &&
                        reminder.status != ReminderStatus.completed &&
                        reminder.status != ReminderStatus.missed) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          if (reminder.status == ReminderStatus.ringing ||
                              reminder.status == ReminderStatus.snoozed)
                            OutlinedButton.icon(
                              onPressed: () async {
                                await controller.snoozeReminder(reminder.id);
                                onChanged?.call();
                              },
                              icon: const Icon(Icons.snooze_rounded, size: 17),
                              label: Text(_s.text('snooze')),
                            ),
                          FilledButton.tonalIcon(
                            onPressed: () async {
                              await controller.completeReminder(reminder.id);
                              onChanged?.call();
                            },
                            icon: const Icon(Icons.check_rounded, size: 17),
                            label: Text(_s.text('done')),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 4),
      Text(text, style: Theme.of(context).textTheme.labelSmall),
    ],
  );
}
