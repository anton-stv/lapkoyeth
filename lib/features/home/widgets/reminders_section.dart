import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/reminder_model.dart';

class RemindersSection extends StatelessWidget {
  const RemindersSection({super.key});

  @override
  Widget build(BuildContext context) {
    final shown = stubReminders.take(3).toList();
    final totalToday = stubReminders.length;
    final remaining = totalToday - shown.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Напоминания',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.go('/calendar'),
                child: const Text('Календарь'),
              ),
            ],
          ),
          const SizedBox(height: 2),
          const Text(
            'Ближайшие события на сегодня',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 118,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: shown.length + (remaining > 0 ? 1 : 0),
              separatorBuilder: (_, i) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                if (i == shown.length) {
                  return _MoreRemindersCard(count: remaining);
                }
                return _ReminderCard(reminder: shown[i]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MoreRemindersCard extends StatelessWidget {
  final int count;
  const _MoreRemindersCard({required this.count});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/calendar'),
      child: Container(
        width: 138,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.primary.withAlpha(26),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.primary.withAlpha(54)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.calendar_month_outlined,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Еще $count',
              style: const TextStyle(
                color: AppColors.textMain,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'настроить',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final ReminderModel reminder;
  const _ReminderCard({required this.reminder});

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(reminder.type);
    final icon = _iconFor(reminder.type);

    return GestureDetector(
      onTap: () => _showReminderDetails(context, reminder),
      child: Container(
        width: 214,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withAlpha(34),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, size: 23, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        reminder.time,
                        style: TextStyle(
                          fontSize: 12,
                          color: color,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(
                    reminder.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMain,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reminder.petName,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(ReminderType type) {
    return switch (type) {
      ReminderType.medicine => Icons.medication_outlined,
      ReminderType.vet => Icons.local_hospital_outlined,
      ReminderType.walk => Icons.directions_walk_rounded,
      ReminderType.food => Icons.restaurant_outlined,
      ReminderType.grooming => Icons.content_cut_rounded,
    };
  }

  Color _colorFor(ReminderType type) {
    return switch (type) {
      ReminderType.medicine => AppColors.accent,
      ReminderType.vet => AppColors.primary,
      ReminderType.walk => AppColors.teal,
      ReminderType.food => AppColors.secondary,
      ReminderType.grooming => AppColors.warning,
    };
  }

  void _showReminderDetails(BuildContext context, ReminderModel reminder) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(
          20,
          18,
          20,
          MediaQuery.of(ctx).padding.bottom + 20,
        ),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: _colorFor(reminder.type).withAlpha(34),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    _iconFor(reminder.type),
                    color: _colorFor(reminder.type),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reminder.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${reminder.petName} · сегодня в ${reminder.time}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              'Детали напоминания будут расширяться: повторение, комментарии и связь с режимом дня питомца.',
              style: TextStyle(color: AppColors.textSecondary, height: 1.35),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.go('/calendar');
                },
                child: const Text('Открыть настройки'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
