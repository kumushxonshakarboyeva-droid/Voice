import 'package:flutter/foundation.dart';

import 'app_settings.dart';
import 'reminder.dart';
import 'android_bridge.dart';

class AppController extends ChangeNotifier {
  List<Reminder> reminders = [];
  AppSettings settings = const AppSettings();
  DeviceCapabilities capabilities = const DeviceCapabilities();
  List<VoiceInfo> voices = [];
  Map<String, int> statistics = const {};
  String? errorMessage;
  bool initialized = false;
  bool loading = false;

  bool get hasUzbekVoice =>
      voices.any((voice) => voice.language.toLowerCase() == 'uz');

  List<Reminder> get activeReminders =>
      reminders
          .where(
            (reminder) =>
                reminder.status == ReminderStatus.pending ||
                reminder.status == ReminderStatus.ringing ||
                reminder.status == ReminderStatus.snoozed,
          )
          .toList()
        ..sort((a, b) => a.dueAt.compareTo(b.dueAt));

  List<Reminder> get todayReminders {
    final now = DateTime.now();
    return activeReminders.where((reminder) {
      final due = reminder.dueAt;
      return due.year == now.year &&
          due.month == now.month &&
          due.day == now.day;
    }).toList();
  }

  Reminder? get nextReminder {
    final upcoming =
        activeReminders
            .where(
              (reminder) =>
                  reminder.status != ReminderStatus.completed &&
                  reminder.dueAt.isAfter(DateTime.now()),
            )
            .toList()
          ..sort((a, b) => a.dueAt.compareTo(b.dueAt));
    return upcoming.isEmpty ? null : upcoming.first;
  }

  Future<void> initialize() async {
    try {
      capabilities = await AndroidBridge.initialize(reschedule: true);
      settings = await AndroidBridge.loadSettings();
      await refresh();
      await refreshVoices();
      initialized = true;
    } catch (error) {
      errorMessage = 'Ilova ma’lumotlarini yuklab bo‘lmadi: $error';
    }
    notifyListeners();
  }

  Future<void> refresh() async {
    loading = true;
    notifyListeners();
    try {
      reminders = await AndroidBridge.loadReminders();
      statistics = await AndroidBridge.loadStatistics();
      capabilities = await AndroidBridge.initialize();
      errorMessage = null;
    } catch (error) {
      errorMessage = 'Ma’lumotlarni yangilab bo‘lmadi: $error';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> refreshVoices() async {
    try {
      voices = await AndroidBridge.loadVoices();
    } catch (error) {
      errorMessage = 'Ovozlar ro‘yxatini tekshirib bo‘lmadi: $error';
    }
    notifyListeners();
  }

  Future<void> saveReminder(Reminder reminder) async {
    await AndroidBridge.saveReminder(reminder);
    await refresh();
  }

  Future<void> deleteReminder(String id) async {
    await AndroidBridge.deleteReminder(id);
    await refresh();
  }

  Future<void> completeReminder(String id) async {
    await AndroidBridge.completeReminder(id);
    await refresh();
  }

  Future<void> snoozeReminder(String id) async {
    await AndroidBridge.snoozeReminder(id, settings.snoozeMinutes);
    await refresh();
  }

  Future<void> rescheduleMissed(Reminder reminder, DateTime newTime) async {
    await AndroidBridge.rescheduleMissed(
      reminder.id,
      newTime.millisecondsSinceEpoch,
    );
    await refresh();
  }

  Future<void> updateSettings(AppSettings value) async {
    await AndroidBridge.saveSettings(value);
    settings = value;
    notifyListeners();
    await refreshVoices();
  }

  Future<void> refreshCapabilities() async {
    capabilities = await AndroidBridge.initialize();
    notifyListeners();
  }
}
