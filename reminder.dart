enum ReminderStatus { pending, ringing, snoozed, completed, missed }

enum ReminderRecurrence { none, daily, weekly, monthly }

class Reminder {
  const Reminder({
    required this.id,
    required this.title,
    required this.description,
    required this.dueAt,
    required this.hour,
    required this.minute,
    required this.monthDay,
    required this.recurrence,
    required this.weekdays,
    required this.category,
    required this.priority,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.triggeredAt,
    this.source = 'text',
  });

  final String id;
  final String title;
  final String description;
  final DateTime dueAt;
  final int hour;
  final int minute;
  final int monthDay;
  final ReminderRecurrence recurrence;
  final List<int> weekdays;
  final String category;
  final int priority;
  final ReminderStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? triggeredAt;
  final String source;

  bool get repeats => recurrence != ReminderRecurrence.none;

  factory Reminder.fromMap(Map<Object?, Object?> map) {
    final hour = (map['hour'] as num?)?.toInt() ?? 9;
    final minute = (map['minute'] as num?)?.toInt() ?? 0;
    final dueAtMs = (map['dueAtMs'] as num?)?.toInt() ?? 0;
    final createdAtMs = (map['createdAtMs'] as num?)?.toInt() ?? dueAtMs;
    final year = (map['localYear'] as num?)?.toInt();
    final month = (map['localMonth'] as num?)?.toInt();
    final day = (map['localDay'] as num?)?.toInt();
    final dueAt = year != null && month != null && day != null
        ? DateTime(year, month, day, hour, minute)
        : DateTime.fromMillisecondsSinceEpoch(dueAtMs);
    final weekdaysValue = map['weekdays'];
    final weekdays = weekdaysValue is List
        ? weekdaysValue.map((value) => (value as num).toInt()).toList()
        : <int>[];
    final recurrenceName = map['recurrence'] as String? ?? 'none';
    final statusName = map['status'] as String? ?? 'pending';
    return Reminder(
      id: map['id'] as String,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      dueAt: dueAt,
      hour: hour,
      minute: minute,
      monthDay: (map['monthDay'] as num?)?.toInt() ?? dueAt.day,
      recurrence: ReminderRecurrence.values.firstWhere(
        (value) => value.name == recurrenceName,
        orElse: () => ReminderRecurrence.none,
      ),
      weekdays: weekdays,
      category: map['category'] as String? ?? 'general',
      priority: (map['priority'] as num?)?.toInt() ?? 1,
      status: ReminderStatus.values.firstWhere(
        (value) => value.name == statusName,
        orElse: () => ReminderStatus.pending,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs),
      updatedAt: _dateFromMillis(map['updatedAtMs']),
      triggeredAt: _dateFromMillis(map['triggeredAtMs']),
      source: map['source'] as String? ?? 'text',
    );
  }

  Map<String, Object?> toPlatformMap() => {
    'id': id,
    'title': title.trim(),
    'description': description.trim(),
    'dueAtMs': dueAt.millisecondsSinceEpoch,
    'hour': hour,
    'minute': minute,
    'localYear': dueAt.year,
    'localMonth': dueAt.month,
    'localDay': dueAt.day,
    'monthDay': monthDay,
    'recurrence': recurrence.name,
    'weekdays': weekdays,
    'category': category,
    'priority': priority,
    'status': status.name,
    'createdAtMs': createdAt.millisecondsSinceEpoch,
    'updatedAtMs': updatedAt?.millisecondsSinceEpoch,
    'triggeredAtMs': triggeredAt?.millisecondsSinceEpoch,
    'source': source,
  };

  Reminder copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueAt,
    int? hour,
    int? minute,
    int? monthDay,
    ReminderRecurrence? recurrence,
    List<int>? weekdays,
    String? category,
    int? priority,
    ReminderStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? triggeredAt,
    String? source,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueAt: dueAt ?? this.dueAt,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      monthDay: monthDay ?? this.monthDay,
      recurrence: recurrence ?? this.recurrence,
      weekdays: weekdays ?? this.weekdays,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      triggeredAt: triggeredAt ?? this.triggeredAt,
      source: source ?? this.source,
    );
  }
}

DateTime? _dateFromMillis(Object? value) {
  if (value is num && value > 0) {
    return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  }
  return null;
}
