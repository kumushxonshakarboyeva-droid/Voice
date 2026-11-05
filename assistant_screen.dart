import 'package:flutter/material.dart';

import 'app_strings.dart';
import 'android_bridge.dart';
import 'app_controller.dart';
import 'assistant_parser.dart';
import 'sound_wave.dart';
import 'reminder_editor.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  bool _listening = false;
  String? _recognized;
  String? _error;

  AppStrings get _s => AppStrings(widget.controller.settings.uiLanguage);

  Future<void> _listen() async {
    setState(() {
      _listening = true;
      _recognized = null;
      _error = null;
    });
    try {
      final text = await AndroidBridge.listenForCommand(
        widget.controller.settings.speechLocale,
      );
      if (!mounted) return;
      if (text == null || text.trim().isEmpty) {
        setState(() => _error = _s.text('no_transcript'));
        return;
      }
      setState(() => _recognized = text.trim());
      await _reviewCommand(text.trim());
    } catch (error) {
      if (mounted) setState(() => _error = 'Nutqni aniqlash ishlamadi: $error');
    } finally {
      if (mounted) setState(() => _listening = false);
    }
  }

  Future<void> _reviewCommand(String text) async {
    final draft = UzbekCommandParser.parse(text);
    final time = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay(hour: draft.dueAt.hour, minute: draft.dueAt.minute),
    );
    final day = MaterialLocalizations.of(context).formatMediumDate(draft.dueAt);
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_s.text('confirm_command')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(text),
            const SizedBox(height: 14),
            Text(
              '${draft.title.isEmpty ? _s.text('reminder') : draft.title}\n$day · $time',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(draft.explanation),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(_s.text('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(_s.text('edit')),
          ),
        ],
      ),
    );
    if (accepted != true || !mounted) return;
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            ReminderEditor(controller: widget.controller, draft: draft),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(_s.text('voice_assistant'))),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 196,
                height: 196,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primaryContainer,
                      theme.colorScheme.tertiaryContainer,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: SoundWave(
                    active: _listening,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                _listening ? _s.text('listening') : _s.text('command_help'),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Text(
                'Ovoz yozuvi saqlanmaydi. Nutqni aniqlash qurilmadagi Android xizmatidan foydalanadi; ayrim xizmatlar internet talab qilishi mumkin.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
              if (_recognized != null) ...[
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _recognized!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: TextStyle(color: theme.colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ],
              const Spacer(),
              FilledButton.icon(
                onPressed: _listening ? null : _listen,
                icon: Icon(
                  _listening ? Icons.graphic_eq_rounded : Icons.mic_rounded,
                ),
                label: Text(
                  _listening ? _s.text('listening') : _s.text('mic_start'),
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(58),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
              if (_error != null)
                TextButton(
                  onPressed: _listen,
                  child: Text(_s.text('try_again')),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
