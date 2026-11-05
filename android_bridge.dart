import 'package:flutter/services.dart';

import 'app_settings.dart';
import 'reminder.dart';

class AndroidBridge {
  AndroidBridge._();

  static const MethodChannel _channel = MethodChannel(
    'com.voicelife.reminder/native',
  );

  static Future<DeviceCapabilities> initialize({
    bool reschedule = false,
  }) async {
    final result = await _channel.invokeMapMethod<Object?, Object?>(
      'initialize',
      {'reschedule': reschedule},
    );
    return DeviceCapabilities.fromMap(result);
  }

  static Future<List<Reminder>> loadReminders() async {
    final result =
        await _channel.invokeListMethod<Object?>('listReminders') ?? [];
    return result
        .whereType<Map<Object?, Object?>>()
        .map(Reminder.fromMap)
        .toList();
  }

  static Future<void> saveReminder(Reminder reminder) =>
      _channel.invokeMethod<void>('saveReminder', reminder.toPlatformMap());

  static Future<void> deleteReminder(String id) =>
      _channel.invokeMethod<void>('deleteReminder', {'id': id});

  static Future<void> completeReminder(String id) =>
      _channel.invokeMethod<void>('completeReminder', {'id': id});

  static Future<void> snoozeReminder(String id, int minutes) => _channel
      .invokeMethod<void>('snoozeReminder', {'id': id, 'minutes': minutes});

  static Future<void> rescheduleMissed(String id, int dueAtMs) => _channel
      .invokeMethod<void>('rescheduleMissed', {'id': id, 'dueAtMs': dueAtMs});

  static Future<AppSettings> loadSettings() async {
    final result = await _channel.invokeMapMethod<Object?, Object?>(
      'getSettings',
    );
    return AppSettings.fromMap(result);
  }

  static Future<void> saveSettings(AppSettings settings) =>
      _channel.invokeMethod<void>('saveSettings', settings.toPlatformMap());

  static Future<List<VoiceInfo>> loadVoices() async {
    final result = await _channel.invokeListMethod<Object?>('getVoices') ?? [];
    return result
        .whereType<Map<Object?, Object?>>()
        .map(VoiceInfo.fromMap)
        .toList();
  }

  static Future<Map<String, Object?>> getAlarmStatus() async =>
      await _channel.invokeMapMethod<String, Object?>('getAlarmStatus') ?? {};

  static Future<void> requestNotificationPermission() =>
      _channel.invokeMethod<void>('requestNotificationPermission');

  static Future<void> requestExactAlarmPermission() =>
      _channel.invokeMethod<void>('requestExactAlarmPermission');

  static Future<void> openBatterySettings() =>
      _channel.invokeMethod<void>('openBatterySettings');

  static Future<void> openTtsSettings() =>
      _channel.invokeMethod<void>('openTtsSettings');

  static Future<void> previewSpeech(String text) =>
      _channel.invokeMethod<void>('previewSpeech', {'text': text});

  static Future<String?> listenForCommand(String localeTag) =>
      _channel.invokeMethod<String>('listenForCommand', {'locale': localeTag});

  static Future<Map<String, int>> loadStatistics() async {
    final result =
        await _channel.invokeMapMethod<Object?, Object?>('getStatistics') ?? {};
    return result.map(
      (key, value) => MapEntry(key.toString(), (value as num).toInt()),
    );
  }

  static Future<bool> exportBackup() async =>
      await _channel.invokeMethod<bool>('exportBackup') ?? false;

  static Future<bool> importBackup() async =>
      await _channel.invokeMethod<bool>('importBackup') ?? false;
}
