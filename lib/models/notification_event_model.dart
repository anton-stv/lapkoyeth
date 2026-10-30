import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class NotificationEvent {
  final String? ownerUid;
  final String id;
  final String title;
  final String petName;
  final DateTime date;
  final TimeOfDay time;
  final String description;
  final IconData icon;
  final Color color;
  final bool isRead;
  final bool isRecurring;
  final List<int> repeatWeekdays;
  final DateTime? repeatUntil;
  final List<DateTime> excludedDates;
  final bool fromPreset;

  const NotificationEvent({
    this.ownerUid,
    required this.id,
    required this.title,
    required this.petName,
    required this.date,
    required this.time,
    required this.description,
    required this.icon,
    required this.color,
    this.isRead = false,
    this.isRecurring = false,
    this.repeatWeekdays = const [],
    this.repeatUntil,
    this.excludedDates = const [],
    this.fromPreset = false,
  });

  NotificationEvent copyWith({
    String? ownerUid,
    String? id,
    String? title,
    String? petName,
    DateTime? date,
    TimeOfDay? time,
    String? description,
    IconData? icon,
    Color? color,
    bool? isRead,
    bool? isRecurring,
    List<int>? repeatWeekdays,
    DateTime? repeatUntil,
    List<DateTime>? excludedDates,
    bool clearRepeatUntil = false,
    bool? fromPreset,
  }) {
    return NotificationEvent(
      ownerUid: ownerUid ?? this.ownerUid,
      id: id ?? this.id,
      title: title ?? this.title,
      petName: petName ?? this.petName,
      date: date ?? this.date,
      time: time ?? this.time,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isRead: isRead ?? this.isRead,
      isRecurring: isRecurring ?? this.isRecurring,
      repeatWeekdays: repeatWeekdays ?? this.repeatWeekdays,
      repeatUntil: clearRepeatUntil ? null : repeatUntil ?? this.repeatUntil,
      excludedDates: excludedDates ?? this.excludedDates,
      fromPreset: fromPreset ?? this.fromPreset,
    );
  }

  Map<String, dynamic> toMap() => {
    'owner_uid': ownerUid,
    'id': id,
    'title': title,
    'pet_name': petName,
    'date': date.toIso8601String(),
    'time_hour': time.hour,
    'time_minute': time.minute,
    'description': description,
    'icon': icon.codePoint,
    'color': color.toARGB32(),
    'is_read': isRead,
    'is_recurring': isRecurring,
    'repeat_weekdays': repeatWeekdays,
    'repeat_until': repeatUntil?.toIso8601String(),
    'excluded_dates': excludedDates
        .map((date) => date.toIso8601String())
        .toList(),
    'from_preset': fromPreset,
  };

  factory NotificationEvent.fromMap(Map<String, dynamic> map) =>
      NotificationEvent(
        ownerUid: map['owner_uid'] as String?,
        id: map['id'] as String,
        title: map['title'] as String? ?? '',
        petName: map['pet_name'] as String? ?? 'Общее',
        date: DateTime.parse(map['date'] as String),
        time: TimeOfDay(
          hour: (map['time_hour'] as num?)?.toInt() ?? 0,
          minute: (map['time_minute'] as num?)?.toInt() ?? 0,
        ),
        description: map['description'] as String? ?? '',
        icon: _iconFromCodePoint((map['icon'] as num?)?.toInt()),
        color: Color(
          (map['color'] as num?)?.toInt() ?? AppColors.primary.toARGB32(),
        ),
        isRead: map['is_read'] as bool? ?? false,
        isRecurring: map['is_recurring'] as bool? ?? false,
        repeatWeekdays: (map['repeat_weekdays'] as List? ?? const [])
            .map((value) => (value as num).toInt())
            .toList(),
        repeatUntil: map['repeat_until'] == null
            ? null
            : DateTime.tryParse(map['repeat_until'] as String),
        excludedDates: (map['excluded_dates'] as List? ?? const [])
            .map((value) => DateTime.tryParse(value.toString()))
            .whereType<DateTime>()
            .toList(),
        fromPreset: map['from_preset'] as bool? ?? false,
      );
}

IconData _iconFromCodePoint(int? codePoint) {
  const supported = [
    Icons.event_note_outlined,
    Icons.vaccines_outlined,
    Icons.bug_report_outlined,
    Icons.restaurant_outlined,
    Icons.local_hospital_outlined,
    Icons.medication_liquid_outlined,
    Icons.directions_walk_rounded,
  ];
  return supported.where((icon) => icon.codePoint == codePoint).firstOrNull ??
      Icons.event_note_outlined;
}

class NotificationPreset {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const NotificationPreset({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

final notificationPresets = <NotificationPreset>[
  const NotificationPreset(
    title: 'Прививка',
    description: 'Проверьте дату последней прививки в профиле питомца.',
    icon: Icons.vaccines_outlined,
    color: AppColors.primary,
  ),
  const NotificationPreset(
    title: 'Клещи и блохи',
    description: 'Ранее использовали капли. Повторите обработку по графику.',
    icon: Icons.bug_report_outlined,
    color: AppColors.accent,
  ),
  const NotificationPreset(
    title: 'Глисты',
    description: 'Напоминание об обработке от глистов по данным профиля.',
    icon: Icons.medication_liquid_outlined,
    color: AppColors.warning,
  ),
  const NotificationPreset(
    title: 'Кормление',
    description: 'Плановое кормление с учетом режима питомца.',
    icon: Icons.restaurant_outlined,
    color: AppColors.secondary,
  ),
  const NotificationPreset(
    title: 'Прогулка',
    description: 'Запланированная прогулка и активность.',
    icon: Icons.directions_walk_rounded,
    color: AppColors.teal,
  ),
];

bool isSameCalendarDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

bool notificationOccursOn(NotificationEvent event, DateTime date) {
  final day = DateTime(date.year, date.month, date.day);
  final start = DateTime(event.date.year, event.date.month, event.date.day);
  if (event.excludedDates.any((excluded) => isSameCalendarDay(excluded, day))) {
    return false;
  }
  if (!event.isRecurring) return isSameCalendarDay(start, day);
  if (day.isBefore(start)) return false;
  final until = event.repeatUntil;
  if (until != null) {
    final end = DateTime(until.year, until.month, until.day);
    if (day.isAfter(end)) return false;
  }
  final weekdays = event.repeatWeekdays.isEmpty
      ? const [1, 2, 3, 4, 5, 6, 7]
      : event.repeatWeekdays;
  return weekdays.contains(day.weekday);
}

int compareNotificationEvents(NotificationEvent a, NotificationEvent b) {
  final dateCompare = a.date.compareTo(b.date);
  if (dateCompare != 0) return dateCompare;
  final aMinutes = a.time.hour * 60 + a.time.minute;
  final bMinutes = b.time.hour * 60 + b.time.minute;
  return aMinutes.compareTo(bMinutes);
}

DateTime? nextNotificationOccurrence(NotificationEvent event, DateTime from) {
  final start = DateTime(from.year, from.month, from.day);
  if (!event.isRecurring) {
    final date = DateTime(event.date.year, event.date.month, event.date.day);
    return date.isBefore(start) ? null : date;
  }
  final last = event.repeatUntil == null
      ? start.add(const Duration(days: 365 * 20))
      : DateTime(
          event.repeatUntil!.year,
          event.repeatUntil!.month,
          event.repeatUntil!.day,
        );
  for (
    var day = start;
    !day.isAfter(last);
    day = day.add(const Duration(days: 1))
  ) {
    if (notificationOccursOn(event, day)) return day;
  }
  return null;
}
