import 'package:flutter/material.dart';

import 'app_settings.dart';
import 'app_strings.dart';
import 'android_bridge.dart';
import 'app_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _working = false;

  AppStrings get _s => AppStrings(widget.controller.settings.uiLanguage);

  Future<void> _save(AppSettings value) async {
    try {
      await widget.controller.updateSettings(value);
    } catch (error) {
      if (mounted) _message('Sozlama saqlanmadi: $error');
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _backup({required bool restore}) async {
    if (restore) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(_s.text('restore')),
          content: Text(_s.text('restore_confirm')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(_s.text('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(_s.text('restore')),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    setState(() => _working = true);
    try {
      final completed = restore
          ? await AndroidBridge.importBackup()
          : await AndroidBridge.exportBackup();
      if (!mounted) return;
      await widget.controller.refresh();
      _message(
        completed
            ? _s.text(restore ? 'backup_restored' : 'backup_saved')
            : _s.text('backup_failed'),
      );
    } catch (error) {
      if (mounted) _message('${_s.text('backup_failed')}: $error');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  String _voicePreviewText() => switch (widget
      .controller
      .settings
      .speechLocale) {
    'ru-RU' => 'Проверка голосового напоминания. Всё готово.',
    'en-US' => 'This is a spoken reminder voice preview.',
    _ =>
      'Assalomu alaykum. Bugun soat sakkizda ingliz tilini o‘rganishni unutmang.',
  };

  String _languageName(String tag) => switch (tag) {
    'uz-UZ' => 'O‘zbekcha (Latin)',
    'ru-RU' => 'Русский',
    'en-US' => 'English',
    _ => tag,
  };

  @override
  Widget build(BuildContext context) {
    final settings = widget.controller.settings;
    final theme = Theme.of(context);
    final voices =
        widget.controller.voices
            .where(
              (voice) => voice.localeTag.toLowerCase().startsWith(
                settings.speechLocale.split('-').first.toLowerCase(),
              ),
            )
            .toList()
          ..sort((a, b) {
            if (a.isDefault != b.isDefault) return a.isDefault ? -1 : 1;
            return b.quality.compareTo(a.quality);
          });
    final selectedVoiceExists = voices.any(
      (voice) => voice.name == settings.voiceName,
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        Text(
          _s.text('settings'),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),
        _SectionLabel(title: _s.text('voice_settings')),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  value: settings.uiLanguage,
                  decoration: InputDecoration(
                    labelText: _s.text('app_language'),
                    prefixIcon: const Icon(Icons.translate_rounded),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'uz', child: Text('O‘zbekcha')),
                    DropdownMenuItem(value: 'ru', child: Text('Русский')),
                    DropdownMenuItem(value: 'en', child: Text('English')),
                  ],
                  onChanged: (value) {
                    if (value != null)
                      _save(settings.copyWith(uiLanguage: value));
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: settings.speechLocale,
                  decoration: InputDecoration(
                    labelText: _s.text('speech_language'),
                    prefixIcon: const Icon(Icons.record_voice_over_rounded),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'uz-UZ',
                      child: Text('O‘zbekcha (Latin)'),
                    ),
                    DropdownMenuItem(value: 'ru-RU', child: Text('Русский')),
                    DropdownMenuItem(value: 'en-US', child: Text('English')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      _save(
                        settings.copyWith(speechLocale: value, voiceName: ''),
                      );
                    }
                  },
                ),
                const SizedBox(height: 14),
                if (voices.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer.withValues(
                        alpha: .6,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: theme.colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(_s.text('voice_unavailable'))),
                      ],
                    ),
                  )
                else
                  DropdownButtonFormField<String>(
                    value: selectedVoiceExists ? settings.voiceName : '',
                    decoration: InputDecoration(
                      labelText: _s.text('voice'),
                      prefixIcon: const Icon(Icons.graphic_eq_rounded),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: '',
                        child: Text(
                          '${_s.text('select_voice')} · ${_s.text('system')}',
                        ),
                      ),
                      ...voices.map((voice) {
                        final network = voice.requiresNetwork
                            ? ' · ${_s.text('network_note')}'
                            : '';
                        return DropdownMenuItem(
                          value: voice.name,
                          child: Text(
                            '${voice.name} · ${voice.localeTag}$network',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }),
                    ],
                    onChanged: (value) =>
                        _save(settings.copyWith(voiceName: value ?? '')),
                  ),
                const SizedBox(height: 10),
                Text(_s.text('speaker_note'), style: theme.textTheme.bodySmall),
                const SizedBox(height: 6),
                Text(
                  _s.text('uzbek_voice_help'),
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 6),
                Text(_s.text('network_note'), style: theme.textTheme.bodySmall),
                if (voices.isEmpty) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: AndroidBridge.openTtsSettings,
                    icon: const Icon(Icons.settings_voice_rounded),
                    label: Text(_s.text('open_tts')),
                  ),
                ],
                const SizedBox(height: 8),
                FilledButton.tonalIcon(
                  onPressed: voices.isEmpty
                      ? null
                      : () async {
                          try {
                            await AndroidBridge.previewSpeech(
                              _voicePreviewText(),
                            );
                          } catch (error) {
                            _message('TTS sinovi bajarilmadi: $error');
                          }
                        },
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(_s.text('voice_preview')),
                ),
                const SizedBox(height: 10),
                _SliderSetting(
                  label: _s.text('speed'),
                  value: settings.speechRate,
                  min: .5,
                  max: 1.5,
                  onChangeEnd: (value) =>
                      _save(settings.copyWith(speechRate: value)),
                  display: '${settings.speechRate.toStringAsFixed(2)}×',
                ),
                _SliderSetting(
                  label: _s.text('pitch'),
                  value: settings.speechPitch,
                  min: .5,
                  max: 2,
                  onChangeEnd: (value) =>
                      _save(settings.copyWith(speechPitch: value)),
                  display: settings.speechPitch.toStringAsFixed(2),
                ),
                _SliderSetting(
                  label: _s.text('volume'),
                  value: settings.speechVolume,
                  min: 0,
                  max: 1,
                  onChangeEnd: (value) =>
                      _save(settings.copyWith(speechVolume: value)),
                  display: '${(settings.speechVolume * 100).round()}%',
                ),
                const SizedBox(height: 8),
                _ChoiceSetting<int>(
                  label: _s.text('repeat_count'),
                  value: settings.repeatCount,
                  choices: const [1, 2, 3],
                  labelFor: (value) => '$value',
                  onChanged: (value) =>
                      _save(settings.copyWith(repeatCount: value)),
                ),
                _ChoiceSetting<int>(
                  label: _s.text('snooze_minutes'),
                  value: settings.snoozeMinutes,
                  choices: const [5, 10, 15, 30],
                  labelFor: (value) => '$value',
                  onChanged: (value) =>
                      _save(settings.copyWith(snoozeMinutes: value)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        _SectionLabel(title: _s.text('theme')),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'system', label: Text(_s.text('system'))),
                ButtonSegment(value: 'light', label: Text(_s.text('light'))),
                ButtonSegment(value: 'dark', label: Text(_s.text('dark'))),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (value) =>
                  _save(settings.copyWith(themeMode: value.first)),
            ),
          ),
        ),
        const SizedBox(height: 18),
        _SectionLabel(title: _s.text('alarm_status')),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.volume_up_rounded),
                title: Text(_s.text('speak_only')),
                subtitle: Text(_s.text('speak_only_help')),
                trailing: const Icon(Icons.lock_outline_rounded),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.alarm_on_rounded),
                title: Text(_s.text('exact_alarm')),
                subtitle: Text(
                  widget.controller.capabilities.exactAlarmGranted
                      ? _s.text('permission_saved')
                      : _s.text('alarm_accuracy'),
                ),
                trailing: const Icon(Icons.open_in_new_rounded),
                onTap: () async {
                  await AndroidBridge.requestExactAlarmPermission();
                  await widget.controller.refreshCapabilities();
                },
              ),
              ListTile(
                leading: const Icon(Icons.notifications_active_rounded),
                title: Text(_s.text('notifications')),
                subtitle: Text(
                  widget.controller.capabilities.notificationGranted
                      ? _s.text('permission_saved')
                      : _s.text('notifications_missing'),
                ),
                trailing: const Icon(Icons.open_in_new_rounded),
                onTap: () async {
                  await AndroidBridge.requestNotificationPermission();
                  await widget.controller.refreshCapabilities();
                },
              ),
              ListTile(
                leading: const Icon(Icons.battery_saver_rounded),
                title: Text(_s.text('open_battery')),
                subtitle: Text(_s.text('battery_help')),
                onTap: AndroidBridge.openBatterySettings,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _SectionLabel(title: _s.text('privacy')),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '${_s.text('privacy_help')}\n\n${_s.text('offline_note')}',
            ),
          ),
        ),
        const SizedBox(height: 18),
        _SectionLabel(title: _s.text('backup_section')),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.backup_rounded),
                title: Text(_s.text('backup')),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: _working ? null : () => _backup(restore: false),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.settings_backup_restore_rounded),
                title: Text(_s.text('restore')),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: _working ? null : () => _backup(restore: true),
              ),
              if (_working)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: LinearProgressIndicator(),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            'VOICE LIFE · Android · 1.0.0',
            style: theme.textTheme.labelSmall,
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
    ),
  );
}

class _SliderSetting extends StatefulWidget {
  const _SliderSetting({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChangeEnd,
    required this.display,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChangeEnd;
  final String display;

  @override
  State<_SliderSetting> createState() => _SliderSettingState();
}

class _SliderSettingState extends State<_SliderSetting> {
  late double _value = widget.value;

  @override
  void didUpdateWidget(covariant _SliderSetting oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) _value = widget.value;
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: [
          Expanded(child: Text(widget.label)),
          Text(widget.display),
        ],
      ),
      Slider(
        value: _value.clamp(widget.min, widget.max),
        min: widget.min,
        max: widget.max,
        onChanged: (value) => setState(() => _value = value),
        onChangeEnd: widget.onChangeEnd,
      ),
    ],
  );
}

class _ChoiceSetting<T extends Object> extends StatelessWidget {
  const _ChoiceSetting({
    required this.label,
    required this.value,
    required this.choices,
    required this.labelFor,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> choices;
  final String Function(T value) labelFor;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(label)),
      Wrap(
        spacing: 8,
        children: choices
            .map(
              (choice) => ChoiceChip(
                label: Text(labelFor(choice)),
                selected: choice == value,
                onSelected: (_) => onChanged(choice),
              ),
            )
            .toList(),
      ),
      const SizedBox(height: 12),
    ],
  );
}
