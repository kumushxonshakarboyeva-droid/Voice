import 'dart:async';

import 'package:flutter/material.dart';

import 'reminder.dart';
import 'app_strings.dart';
import 'android_bridge.dart';
import 'app_controller.dart';
import 'reminder_tile.dart';
import 'assistant_screen.dart';
import 'reminder_editor.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  DateTime _now = DateTime.now();
  Timer? _clockTimer;
  final _search = TextEditingController();
  String _categoryFilter = 'all';

  AppStrings get _s => AppStrings(widget.controller.settings.uiLanguage);

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _openEditor({Reminder? reminder}) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            ReminderEditor(controller: widget.controller, reminder: reminder),
      ),
    );
  }

  Future<void> _openAssistant() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => AssistantScreen(controller: widget.controller),
      ),
    );
  }

  String _dateHeading() {
    return MaterialLocalizations.of(context).formatFullDate(_now);
  }

  String _clock() =>
      '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildToday(),
      _buildReminders(),
      _buildHistory(),
      _buildStatistics(),
      SettingsScreen(controller: widget.controller),
    ];
    final destinations = [
      NavigationDestination(
        icon: const Icon(Icons.today_outlined),
        selectedIcon: const Icon(Icons.today_rounded),
        label: _s.text('today'),
      ),
      NavigationDestination(
        icon: const Icon(Icons.notifications_none_rounded),
        selectedIcon: const Icon(Icons.notifications_rounded),
        label: _s.text('reminders'),
      ),
      NavigationDestination(
        icon: const Icon(Icons.history_rounded),
        label: _s.text('history'),
      ),
      NavigationDestination(
        icon: const Icon(Icons.insights_rounded),
        label: _s.text('statistics'),
      ),
      NavigationDestination(
        icon: const Icon(Icons.settings_outlined),
        selectedIcon: const Icon(Icons.settings_rounded),
        label: _s.text('settings'),
      ),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _s.text('app_name'),
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
        actions: [
          IconButton(
            tooltip: _s.text('voice_assistant'),
            onPressed: _openAssistant,
            icon: const Icon(Icons.mic_none_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        top: false,
        child: IndexedStack(index: _tab, children: pages),
      ),
      floatingActionButton: _tab == 0 || _tab == 1
          ? FloatingActionButton.extended(
              onPressed: _openEditor,
              icon: const Icon(Icons.add_rounded),
              label: Text(_s.text('add_reminder')),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        destinations: destinations,
        onDestinationSelected: (value) => setState(() => _tab = value),
      ),
    );
  }

  Widget _buildToday() {
    final controller = widget.controller;
    final next = controller.nextReminder;
    final todays = controller.todayReminders;
    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
        children: [
          Text(
            _dateHeading(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _clock(),
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 18),
          _VoiceStatusCard(controller: controller, onTap: _openAssistant),
          const SizedBox(height: 16),
          _NextReminderCard(reminder: next, strings: _s),
          const SizedBox(height: 20),
          _PermissionsBanner(controller: controller, strings: _s),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: Text(
                  _s.text('todays_tasks'),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                '${todays.length}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (todays.isEmpty)
            _EmptyState(
              icon: Icons.event_available_rounded,
              label: _s.text('empty_today'),
              buttonLabel: _s.text('add_reminder'),
              onPressed: _openEditor,
            )
          else
            ...todays.map(
              (reminder) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ReminderTile(
                  controller: controller,
                  reminder: reminder,
                  onChanged: controller.refresh,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReminders() {
    final all = widget.controller.activeReminders;
    final query = _search.text.trim().toLowerCase();
    final filtered = all.where((reminder) {
      final textMatch =
          query.isEmpty ||
          reminder.title.toLowerCase().contains(query) ||
          reminder.description.toLowerCase().contains(query);
      return textMatch &&
          (_categoryFilter == 'all' || reminder.category == _categoryFilter);
    }).toList();
    final categories = [
      'all',
      'general',
      'work',
      'personal',
      'health',
      'study',
    ];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
          child: TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: _s.text('search'),
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _search.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final category = categories[index];
              return ChoiceChip(
                label: Text(
                  category == 'all' ? _s.text('all') : _s.text(category),
                ),
                selected: _categoryFilter == category,
                onSelected: (_) => setState(() => _categoryFilter = category),
              );
            },
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: _EmptyState(
                    icon: Icons.notifications_none_rounded,
                    label: _s.text('empty_reminders'),
                    buttonLabel: _s.text('add_reminder'),
                    onPressed: _openEditor,
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 100),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => ReminderTile(
                    controller: widget.controller,
                    reminder: filtered[index],
                    onChanged: widget.controller.refresh,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildHistory() {
    final items =
        widget.controller.reminders
            .where(
              (item) =>
                  item.status == ReminderStatus.completed ||
                  item.status == ReminderStatus.missed,
            )
            .toList()
          ..sort((a, b) => b.dueAt.compareTo(a.dueAt));
    return items.isEmpty
        ? Center(
            child: _EmptyState(
              icon: Icons.history_rounded,
              label: _s.text('empty_history'),
              buttonLabel: _s.text('add_reminder'),
              onPressed: _openEditor,
            ),
          )
        : ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final reminder = items[index];
              return Column(
                children: [
                  ReminderTile(
                    controller: widget.controller,
                    reminder: reminder,
                    showStatus: true,
                  ),
                  if (reminder.status == ReminderStatus.missed)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().add(
                              const Duration(days: 1),
                            ),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (date == null || !mounted) return;
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(reminder.dueAt),
                          );
                          if (time == null) return;
                          await widget.controller.rescheduleMissed(
                            reminder,
                            DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            ),
                          );
                        },
                        icon: const Icon(Icons.event_repeat_rounded),
                        label: Text(_s.text('reschedule')),
                      ),
                    ),
                ],
              );
            },
          );
  }

  Widget _buildStatistics() {
    final stats = widget.controller.statistics;
    final total = widget.controller.reminders.length;
    final completed =
        stats['completed'] ??
        widget.controller.reminders
            .where((r) => r.status == ReminderStatus.completed)
            .length;
    final missed =
        stats['missed'] ??
        widget.controller.reminders
            .where((r) => r.status == ReminderStatus.missed)
            .length;
    final rate = total == 0 ? 0.0 : completed / total;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      children: [
        Text(
          _s.text('statistics'),
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.notifications_active_rounded,
                title: _s.text('tasks_total'),
                value: '$total',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.check_circle_rounded,
                title: _s.text('tasks_done'),
                value: '$completed',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _StatCard(
          icon: Icons.event_busy_rounded,
          title: _s.text('tasks_missed'),
          value: '$missed',
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _s.text('completion'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(value: rate, minHeight: 10),
                const SizedBox(height: 8),
                Text('${(rate * 100).round()}%'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _VoiceStatusCard extends StatelessWidget {
  const _VoiceStatusCard({required this.controller, required this.onTap});
  final AppController controller;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings(controller.settings.uiLanguage);
    final available = controller.hasUzbekVoice;
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.primaryContainer.withValues(alpha: .56),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.mic_rounded, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.text('voice_assistant'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      available
                          ? s.text('uzbek_available')
                          : s.text('uzbek_unavailable'),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _NextReminderCard extends StatelessWidget {
  const _NextReminderCard({required this.reminder, required this.strings});
  final Reminder? reminder;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            Color.lerp(theme.colorScheme.primary, const Color(0xFFAB7DDB), .5)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.record_voice_over_rounded,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.text('next_reminder'),
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 6),
                Text(
                  reminder?.title ?? strings.text('nothing_scheduled'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (reminder != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      MaterialLocalizations.of(context).formatTimeOfDay(
                        TimeOfDay(
                          hour: reminder!.dueAt.hour,
                          minute: reminder!.dueAt.minute,
                        ),
                      ),
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionsBanner extends StatelessWidget {
  const _PermissionsBanner({required this.controller, required this.strings});
  final AppController controller;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final capabilities = controller.capabilities;
    if (capabilities.exactAlarmGranted && capabilities.notificationGranted) {
      return const SizedBox.shrink();
    }
    return Card(
      color: Theme.of(
        context,
      ).colorScheme.errorContainer.withValues(alpha: .55),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.text('enable_reliability'),
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              !capabilities.exactAlarmGranted
                  ? strings.text('alarm_accuracy')
                  : strings.text('notifications_missing'),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                if (!capabilities.exactAlarmGranted)
                  TextButton(
                    onPressed: () async {
                      await AndroidBridge.requestExactAlarmPermission();
                      await controller.refreshCapabilities();
                    },
                    child: Text(strings.text('exact_alarm')),
                  ),
                if (!capabilities.notificationGranted)
                  TextButton(
                    onPressed: () async {
                      await AndroidBridge.requestNotificationPermission();
                      await controller.refreshCapabilities();
                    },
                    child: Text(strings.text('notifications')),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.label,
    required this.buttonLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 42, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 12),
          Text(label, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.add_rounded),
            label: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
