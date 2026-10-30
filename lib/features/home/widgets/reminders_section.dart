import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../features/notifications/providers/notifications_provider.dart';
import '../../../models/notification_event_model.dart';

class RemindersSection extends ConsumerWidget {
  const RemindersSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final upcoming =
        ref
            .watch(notificationsProvider)
            .map(
              (event) => (
                event: event,
                date: nextNotificationOccurrence(event, today),
              ),
            )
            .where((item) => item.date != null)
            .map((item) => (event: item.event, date: item.date!))
            .toList()
          ..sort((a, b) {
            final date = a.date.compareTo(b.date);
            if (date != 0) return date;
            return compareNotificationEvents(a.event, b.event);
          });
    final shown = upcoming.take(3).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Напоминания', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 2),
          const Text(
            'Три ближайших события',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 10),
          if (shown.isEmpty)
            const _EmptyReminderCard()
          else
            SizedBox(
              height: 86,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: shown.length,
                separatorBuilder: (_, i) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  return _ReminderCard(
                    reminder: shown[i].event,
                    occurrenceDate: shown[i].date,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyReminderCard extends StatelessWidget {
  const _EmptyReminderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDE6DD)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Ближайших событий нет',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: () => context.go('/calendar'),
            child: const Text('Добавить напоминание'),
          ),
        ],
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final NotificationEvent reminder;
  final DateTime occurrenceDate;
  const _ReminderCard({required this.reminder, required this.occurrenceDate});

  @override
  Widget build(BuildContext context) {
    final color = reminder.color;

    return GestureDetector(
      onTap: () => _showReminderDetails(context, reminder),
      child: Container(
        width: 202,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withAlpha(34),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(reminder.icon, size: 21, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${_formatDate(occurrenceDate)} · ${_formatTime(reminder.time)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
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
                  const SizedBox(height: 2),
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

  String _formatTime(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}';

  void _showReminderDetails(BuildContext context, NotificationEvent reminder) {
    showModalBottomSheet<void>(
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
                    color: reminder.color.withAlpha(34),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(reminder.icon, color: reminder.color),
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
                        '${reminder.petName} · ${_formatDate(occurrenceDate)} в ${_formatTime(reminder.time)}',
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
            const SizedBox(height: 16),
            if (reminder.description.isNotEmpty)
              Text(
                reminder.description,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.go(
                    Uri(
                      path: '/calendar',
                      queryParameters: {'date': _dateParam(occurrenceDate)},
                    ).toString(),
                  );
                },
                child: const Text('Открыть событие'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _dateParam(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
