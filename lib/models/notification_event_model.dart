import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class NotificationEvent {
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
  final bool fromPreset;

  const NotificationEvent({
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
    this.fromPreset = false,
  });

  NotificationEvent copyWith({
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
    bool clearRepeatUntil = false,
    bool? fromPreset,
  }) {
    return NotificationEvent(
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
      fromPreset: fromPreset ?? this.fromPreset,
    );
  }
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
