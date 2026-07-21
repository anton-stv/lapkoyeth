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

List<NotificationEvent> buildStubNotificationEvents(DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  return [
    NotificationEvent(
      id: 'event-1',
      title: 'Клещи и блохи',
      petName: 'Бобик',
      date: today,
      time: const TimeOfDay(hour: 10, minute: 30),
      description: 'Обработать каплями, которые использовали ранее.',
      icon: Icons.bug_report_outlined,
      color: AppColors.accent,
      fromPreset: true,
    ),
    NotificationEvent(
      id: 'event-2',
      title: 'Плановый врач',
      petName: 'Бобик',
      date: today.add(const Duration(days: 1)),
      time: const TimeOfDay(hour: 15, minute: 0),
      description: 'Ветеринар, чек ап и анализы.',
      icon: Icons.local_hospital_outlined,
      color: AppColors.primary,
    ),
    NotificationEvent(
      id: 'event-3',
      title: 'Кормление',
      petName: 'Мурка',
      date: today.add(const Duration(days: 2)),
      time: const TimeOfDay(hour: 9, minute: 0),
      description: 'Утренний рацион и вода.',
      icon: Icons.restaurant_outlined,
      color: AppColors.secondary,
      isRecurring: true,
      repeatWeekdays: [1, 2, 3, 4, 5],
    ),
    NotificationEvent(
      id: 'event-4',
      title: 'Груминг',
      petName: 'Бобик',
      date: today.subtract(const Duration(days: 1)),
      time: const TimeOfDay(hour: 12, minute: 20),
      description: 'Стрижка когтей и уход.',
      icon: Icons.content_cut_rounded,
      color: AppColors.warning,
      isRead: false,
    ),
    NotificationEvent(
      id: 'event-5',
      title: 'Прогулка',
      petName: 'Бобик',
      date: today.subtract(const Duration(days: 3)),
      time: const TimeOfDay(hour: 18, minute: 0),
      description: 'Вечерняя прогулка.',
      icon: Icons.directions_walk_rounded,
      color: AppColors.teal,
      isRead: true,
    ),
  ];
}

bool isSameCalendarDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
