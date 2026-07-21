import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../features/checklists/providers/checklists_provider.dart';
import '../../../models/checklist_model.dart';
import '../../home/widgets/checklist_sheet.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final checklists = ref.watch(checklistsProvider).valueOrNull ?? [];
    final dayChecklists = checklists
        .where((checklist) => checklist.occursOn(_selectedDate))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Календарь')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _WeekStrip(
            selectedDate: _selectedDate,
            onSelected: (date) => setState(() => _selectedDate = date),
          ),
          const SizedBox(height: 18),
          Text(
            _formatFullDate(_selectedDate),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          if (dayChecklists.isEmpty)
            const _EmptyDay()
          else
            ...dayChecklists.map(
              (checklist) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ChecklistCalendarTile(
                  checklist: checklist,
                  selectedDate: _selectedDate,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatFullDate(DateTime date) {
    const months = [
      'января',
      'февраля',
      'марта',
      'апреля',
      'мая',
      'июня',
      'июля',
      'августа',
      'сентября',
      'октября',
      'ноября',
      'декабря',
    ];
    return '${date.day} ${months[date.month - 1]}';
  }
}

class _WeekStrip extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelected;

  const _WeekStrip({required this.selectedDate, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final start = today.subtract(Duration(days: today.weekday - 1));
    final days = List.generate(14, (index) => start.add(Duration(days: index)));
    const names = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final day = days[index];
          final selected = _sameDay(day, selectedDate);
          return GestureDetector(
            onTap: () => onSelected(day),
            child: Container(
              width: 56,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected ? AppColors.primary : const Color(0xFFE8E2DB),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    names[day.weekday - 1],
                    style: TextStyle(
                      color: selected ? Colors.white : AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    day.day.toString(),
                    style: TextStyle(
                      color: selected ? Colors.white : AppColors.textMain,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _ChecklistCalendarTile extends ConsumerWidget {
  final ChecklistModel checklist;
  final DateTime selectedDate;

  const _ChecklistCalendarTile({
    required this.checklist,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current =
        ref
            .watch(checklistsProvider)
            .valueOrNull
            ?.where((item) => item.id == checklist.id)
            .firstOrNull ??
        checklist;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withAlpha(35),
          child: const Icon(Icons.checklist_rounded, color: AppColors.primary),
        ),
        title: Text(
          current.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          '${current.petName} · ${current.doneCount}/${current.totalCount}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: SizedBox(
          width: 54,
          child: LinearProgressIndicator(
            value: current.progress,
            backgroundColor: const Color(0xFFE8E2DB),
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            minHeight: 7,
          ),
        ),
        onTap: () =>
            ChecklistSheet.show(context, current, occurrenceDate: selectedDate),
      ),
    );
  }
}

class NotificationsCenterScreen extends StatelessWidget {
  const NotificationsCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Уведомления')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Непрочитанные',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            const _NotificationTile(
              icon: Icons.event_available_outlined,
              title: 'Сегодня чек-листы и напоминания',
              subtitle: 'Проверьте календарь питомцев',
              color: AppColors.primary,
            ),
            const SizedBox(height: 10),
            const _NotificationTile(
              icon: Icons.person_outline_rounded,
              title: 'Заполните профиль',
              subtitle: 'Так приложение сможет точнее помогать',
              color: AppColors.warning,
            ),
            const SizedBox(height: 10),
            const _NotificationTile(
              icon: Icons.auto_awesome_outlined,
              title: 'Новые сторисы скоро',
              subtitle: 'Раздел находится в разработке',
              color: AppColors.accent,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyDay extends StatelessWidget {
  const _EmptyDay();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Text(
        'На эту дату чек-листов нет',
        style: TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _NotificationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withAlpha(38),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textMain,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
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
    );
  }
}
