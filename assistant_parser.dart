import 'reminder.dart';

class ReminderDraft {
  const ReminderDraft({
    required this.title,
    required this.description,
    required this.dueAt,
    required this.recurrence,
    required this.weekdays,
    required this.isCertain,
    required this.explanation,
  });

  final String title;
  final String description;
  final DateTime dueAt;
  final ReminderRecurrence recurrence;
  final List<int> weekdays;
  final bool isCertain;
  final String explanation;
}

class UzbekCommandParser {
  static const Map<String, int> _numberWords = {
    'bir': 1,
    'birinchi': 1,
    'ikki': 2,
    'uch': 3,
    'to‘rt': 4,
    "to'rt": 4,
    'tort': 4,
    'besh': 5,
    'olti': 6,
    'yetti': 7,
    'sakkiz': 8,
    'to‘qqiz': 9,
    "to'qqiz": 9,
    'toqqiz': 9,
    'o‘n': 10,
    "o'n": 10,
    'on': 10,
    'o‘n bir': 11,
    "o'n bir": 11,
    'on bir': 11,
    'o‘n ikki': 12,
    "o'n ikki": 12,
    'on ikki': 12,
    'o‘n uch': 13,
    "o'n uch": 13,
    'o‘n to‘rt': 14,
    "o'n to'rt": 14,
    'o‘n besh': 15,
    "o'n besh": 15,
    'o‘n olti': 16,
    "o'n olti": 16,
    'o‘n yetti': 17,
    "o'n yetti": 17,
    'o‘n sakkiz': 18,
    "o'n sakkiz": 18,
    'o‘n to‘qqiz': 19,
    "o'n toqqiz": 19,
    'yigirma': 20,
    'yigirma bir': 21,
    'yigirma ikki': 22,
    'yigirma uch': 23,
    'yigirma to‘rt': 24,
    'yigirma tort': 24,
  };

  static const Map<String, int> _weekdays = {
    'dushanba': DateTime.monday,
    'seshanba': DateTime.tuesday,
    'chorshanba': DateTime.wednesday,
    'payshanba': DateTime.thursday,
    'juma': DateTime.friday,
    'shanba': DateTime.saturday,
    'yakshanba': DateTime.sunday,
  };

  static ReminderDraft parse(String raw, {DateTime? now}) {
    final current = now ?? DateTime.now();
    var normalized = raw.toLowerCase().trim().replaceAll(RegExp("['’`ʻ]"), '‘');
    int? hour;
    var minute = 0;
    var timeMatched = false;

    final numericTime = RegExp(
      r'\bsoat\s*(\d{1,2})(?::([0-5]\d))?(?:\s*(?:da|ta))?',
    ).firstMatch(normalized);
    if (numericTime != null) {
      hour = int.tryParse(numericTime.group(1)!);
      minute = int.tryParse(numericTime.group(2) ?? '0') ?? 0;
      timeMatched = hour != null && hour >= 0 && hour <= 23;
      normalized = normalized.replaceRange(
        numericTime.start,
        numericTime.end,
        ' ',
      );
    } else {
      final spokenTime = RegExp(
        r"""\bsoat\s+((?:(?:o‘n|o'n|on|yigirma)\s+)?(?:bir|ikki|uch|to‘rt|to'rt|tort|besh|olti|yetti|sakkiz|to‘qqiz|to'qqiz|toqqiz|o‘n|o'n|on|yigirma)(?:\s+(?:bir|ikki|uch|to‘rt|to'rt|tort|besh|olti|yetti|sakkiz|to‘qqiz|to'qqiz|toqqiz))?)(?:da|ta)?\b""",
      ).firstMatch(normalized);
      if (spokenTime != null) {
        final words = spokenTime.group(1)!.trim();
        hour = _numberWords[words];
        timeMatched = hour != null && hour >= 0 && hour <= 23;
        normalized = normalized.replaceRange(
          spokenTime.start,
          spokenTime.end,
          ' ',
        );
      }
    }

    var recurrence = ReminderRecurrence.none;
    if (normalized.contains('har kuni')) {
      recurrence = ReminderRecurrence.daily;
      normalized = normalized.replaceAll('har kuni', ' ');
    } else if (normalized.contains('har oy')) {
      recurrence = ReminderRecurrence.monthly;
      normalized = normalized.replaceAll('har oy', ' ');
    } else if (normalized.contains('har hafta') ||
        _weekdays.keys.any(
          (day) => RegExp('\\bhar\\s+$day\\b').hasMatch(normalized),
        )) {
      recurrence = ReminderRecurrence.weekly;
    }

    final selectedDays =
        _weekdays.entries
            .where((entry) => RegExp('\\b${entry.key}\\b').hasMatch(normalized))
            .map((entry) => entry.value)
            .toSet()
            .toList()
          ..sort();
    if (recurrence == ReminderRecurrence.weekly && selectedDays.isEmpty) {
      selectedDays.add(current.weekday);
    }
    for (final weekday in _weekdays.keys) {
      normalized = normalized.replaceAll(RegExp('\\b$weekday\\b'), ' ');
    }

    var targetDate = DateTime(current.year, current.month, current.day);
    if (normalized.contains('ertaga')) {
      targetDate = targetDate.add(const Duration(days: 1));
      normalized = normalized.replaceAll('ertaga', ' ');
    } else if (normalized.contains('bugun')) {
      normalized = normalized.replaceAll('bugun', ' ');
    } else if (selectedDays.isNotEmpty) {
      final offset = List<int>.generate(7, (index) => index).firstWhere(
        (daysAhead) =>
            selectedDays.contains(((current.weekday - 1 + daysAhead) % 7) + 1),
      );
      targetDate = targetDate.add(Duration(days: offset));
    }

    hour ??= 9;
    var dueAt = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      hour,
      minute,
    );
    if (dueAt.isBefore(current)) {
      if (recurrence == ReminderRecurrence.daily) {
        dueAt = dueAt.add(const Duration(days: 1));
      } else if (recurrence == ReminderRecurrence.weekly ||
          selectedDays.isNotEmpty) {
        dueAt = dueAt.add(const Duration(days: 7));
      } else if (recurrence == ReminderRecurrence.monthly) {
        final nextMonth = DateTime(dueAt.year, dueAt.month + 1, 1);
        final lastDay = DateTime(nextMonth.year, nextMonth.month + 1, 0).day;
        dueAt = DateTime(
          nextMonth.year,
          nextMonth.month,
          dueAt.day.clamp(1, lastDay).toInt(),
          hour,
          minute,
        );
      } else if (!raw.toLowerCase().contains('bugun')) {
        dueAt = dueAt.add(const Duration(days: 1));
      }
    }

    normalized = normalized
        .replaceAll(RegExp(r'\bhar\s+hafta\b'), ' ')
        .replaceAll(RegExp(r'\bhar\s+'), ' ')
        .replaceAll(RegExp(r'\bhar\s+kuni\b'), ' ')
        .replaceAll(
          RegExp(r"""\b(?:iltimos\s+)?eslat(?:ib\s+qo‘y|ib\s+qo'y)?\b"""),
          ' ',
        )
        .replaceAll(RegExp(r'\beslatma\b'), ' ')
        .replaceAll(RegExp(r'\bqo‘y\b'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'^[\s,.;:]+|[\s,.;:]+$'), '')
        .trim();

    final title = normalized.isEmpty
        ? raw.trim()
        : normalized[0].toUpperCase() + normalized.substring(1);
    final certain = timeMatched && title.isNotEmpty;
    return ReminderDraft(
      title: title,
      description: '',
      dueAt: dueAt,
      recurrence: recurrence,
      weekdays: recurrence == ReminderRecurrence.weekly ? selectedDays : [],
      isCertain: certain,
      explanation: !timeMatched
          ? 'Vaqt aniq topilmadi. Saqlashdan oldin vaqtni tekshiring.'
          : title.isEmpty
          ? 'Vazifa matni topilmadi. Sarlavhani kiriting.'
          : 'Topilgan vazifani va vaqtni tasdiqlang.',
    );
  }
}
