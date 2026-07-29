import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/notification_event_model.dart';
import '../providers/notifications_provider.dart';

enum _EventsTab { upcoming, past }

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  late DateTime _selectedDate;
  _EventsTab _tab = _EventsTab.upcoming;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    final events = ref.watch(notificationsProvider);
    final selectedEvents =
        events
            .where((event) => notificationOccursOn(event, _selectedDate))
            .toList()
          ..sort(compareNotificationEvents);
    final shownEvents = _visibleEvents(events);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Уведомления'),
        actions: [
          IconButton(
            tooltip: 'Настройки уведомлений',
            onPressed: _showNotificationSettings,
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEventSheet(initialDate: _selectedDate),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Событие'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          _CalendarCard(
            selectedDate: _selectedDate,
            events: events,
            onSelected: (date) => setState(() => _selectedDate = date),
          ),
          const SizedBox(height: 14),
          _SelectedDayActions(
            dateLabel: _formatFullDate(_selectedDate),
            count: selectedEvents.length,
            onAdd: () => _openEventSheet(initialDate: _selectedDate),
            onDelete: selectedEvents.isEmpty
                ? null
                : () => _deleteEvent(selectedEvents.first),
            onEdit: selectedEvents.isEmpty
                ? null
                : () => _openEventSheet(
                    event: selectedEvents.first,
                    initialDate: selectedEvents.first.date,
                  ),
          ),
          const SizedBox(height: 14),
          _CalendarIntegrationCard(onTap: _showCalendarIntegration),
          const SizedBox(height: 16),
          _Tabs(
            value: _tab,
            onChanged: (value) => setState(() => _tab = value),
          ),
          const SizedBox(height: 12),
          if (shownEvents.isEmpty)
            _EmptyEvents(tab: _tab)
          else
            ...shownEvents.map(
              (event) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _EventTile(
                  event: event,
                  isPast: _isPastEvent(event),
                  onTap: () {
                    ref.read(notificationsProvider.notifier).markRead(event.id);
                    _openEventDetails(event);
                  },
                  onEdit: () =>
                      _openEventSheet(event: event, initialDate: event.date),
                  onDelete: () => _deleteEvent(event),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<NotificationEvent> _visibleEvents(List<NotificationEvent> source) {
    final events = source.where((event) {
      final isPast = _isPastEvent(event);
      return _tab == _EventsTab.past ? isPast : !isPast;
    }).toList()..sort(compareNotificationEvents);
    if (_tab == _EventsTab.past) {
      return events.reversed.toList();
    }
    return events;
  }

  DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  bool _isPastEvent(NotificationEvent event) {
    final today = _today();
    if (!event.isRecurring) return event.date.isBefore(today);
    final until = event.repeatUntil;
    if (until == null) return false;
    return DateTime(until.year, until.month, until.day).isBefore(today);
  }

  Future<void> _openEventSheet({
    NotificationEvent? event,
    required DateTime initialDate,
  }) async {
    final originalDate = event?.date ?? initialDate;
    final result = await showModalBottomSheet<NotificationEvent>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) =>
          _EventEditorSheet(event: event, initialDate: initialDate),
    );

    if (result == null) return;
    ref.read(notificationsProvider.notifier).addOrUpdate(result);
    setState(() {
      if (!isSameCalendarDay(result.date, originalDate)) {
        _selectedDate = result.date;
      }
    });
  }

  void _deleteEvent(NotificationEvent event) {
    ref.read(notificationsProvider.notifier).delete(event);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Событие «${event.title}» удалено')));
  }

  void _openEventDetails(NotificationEvent event) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EventDetailsSheet(
        event: event,
        onEdit: () {
          Navigator.pop(ctx);
          _openEventSheet(event: event, initialDate: event.date);
        },
        onDelete: () {
          Navigator.pop(ctx);
          _deleteEvent(event);
        },
      ),
    );
  }

  void _showCalendarIntegration() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _InfoSheet(
        title: 'Интеграция календарей',
        icon: Icons.sync_rounded,
        text:
            'Здесь будет подключение календаря телефона, Google, Яндекс, Mail и других. Если пользователь получает пуш от основного календаря, пуш приложения можно будет сделать опциональным.',
      ),
    );
  }

  void _showNotificationSettings() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _NotificationSettingsSheet(),
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

class NotificationsCenterScreen extends ConsumerWidget {
  const NotificationsCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = [...ref.watch(notificationsProvider)]
      ..sort(compareNotificationEvents);
    final shownEvents = events.take(6).toList();
    final unread = events.where((event) => !event.isRead).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Центр уведомлений')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _UnreadSummary(unread: unread),
          const SizedBox(height: 14),
          ...shownEvents.map(
            (event) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _EventTile(
                event: event,
                isPast: _isPastEvent(event),
                onTap: () {
                  ref.read(notificationsProvider.notifier).markRead(event.id);
                  context.go('/calendar');
                },
                onEdit: () => context.go('/calendar'),
                onDelete: () {
                  ref.read(notificationsProvider.notifier).delete(event);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Событие «${event.title}» удалено'),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.go('/calendar'),
              icon: const Icon(Icons.calendar_month_rounded),
              label: const Text('Открыть календарь'),
            ),
          ),
        ],
      ),
    );
  }

  DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  bool _isPastEvent(NotificationEvent event) {
    final today = _today();
    if (!event.isRecurring) return event.date.isBefore(today);
    final until = event.repeatUntil;
    if (until == null) return false;
    return DateTime(until.year, until.month, until.day).isBefore(today);
  }
}

class _CalendarCard extends StatelessWidget {
  final DateTime selectedDate;
  final List<NotificationEvent> events;
  final ValueChanged<DateTime> onSelected;

  const _CalendarCard({
    required this.selectedDate,
    required this.events,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final monthStart = DateTime(selectedDate.year, selectedDate.month);
    final monthDays = DateUtils.getDaysInMonth(
      selectedDate.year,
      selectedDate.month,
    );
    final lead = monthStart.weekday - 1;
    final cells = List<DateTime?>.generate(lead + monthDays, (index) {
      if (index < lead) return null;
      return DateTime(selectedDate.year, selectedDate.month, index - lead + 1);
    });

    return Container(
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
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Предыдущий месяц',
                onPressed: () => onSelected(
                  DateTime(selectedDate.year, selectedDate.month - 1, 1),
                ),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Text(
                  _monthLabel(selectedDate),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                tooltip: 'Следующий месяц',
                onPressed: () => onSelected(
                  DateTime(selectedDate.year, selectedDate.month + 1, 1),
                ),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              _WeekdayLabel('Пн'),
              _WeekdayLabel('Вт'),
              _WeekdayLabel('Ср'),
              _WeekdayLabel('Чт'),
              _WeekdayLabel('Пт'),
              _WeekdayLabel('Сб'),
              _WeekdayLabel('Вс'),
            ],
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
            ),
            itemCount: cells.length,
            itemBuilder: (context, index) {
              final date = cells[index];
              if (date == null) return const SizedBox.shrink();
              final selected = isSameCalendarDay(date, selectedDate);
              final hasEvents = events.any(
                (event) => notificationOccursOn(event, date),
              );
              return _DayCell(
                date: date,
                selected: selected,
                hasEvents: hasEvents,
                onTap: () => onSelected(date),
              );
            },
          ),
        ],
      ),
    );
  }

  String _monthLabel(DateTime date) {
    const months = [
      'Январь',
      'Февраль',
      'Март',
      'Апрель',
      'Май',
      'Июнь',
      'Июль',
      'Август',
      'Сентябрь',
      'Октябрь',
      'Ноябрь',
      'Декабрь',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

class _WeekdayLabel extends StatelessWidget {
  final String text;
  const _WeekdayLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final DateTime date;
  final bool selected;
  final bool hasEvents;
  final VoidCallback onTap;

  const _DayCell({
    required this.date,
    required this.selected,
    required this.hasEvents,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : const Color(0xFFE8E2DB),
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              date.day.toString(),
              style: TextStyle(
                color: selected ? Colors.white : AppColors.textMain,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (hasEvents)
              Positioned(
                bottom: 6,
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: selected ? Colors.white : AppColors.accent,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SelectedDayActions extends StatelessWidget {
  final String dateLabel;
  final int count;
  final VoidCallback onAdd;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const _SelectedDayActions({
    required this.dateLabel,
    required this.count,
    required this.onAdd,
    required this.onDelete,
    required this.onEdit,
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dateLabel, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  count == 0 ? 'Событий нет' : 'Событий: $count',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Добавить',
            onPressed: onAdd,
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
          IconButton(
            tooltip: 'Изменить',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_calendar_outlined),
          ),
          IconButton(
            tooltip: 'Удалить',
            onPressed: onDelete,
            color: AppColors.error,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
    );
  }
}

class _CalendarIntegrationCard extends StatelessWidget {
  final VoidCallback onTap;
  const _CalendarIntegrationCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.primary.withAlpha(28),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.primary.withAlpha(58)),
        ),
        child: const Row(
          children: [
            Icon(Icons.sync_rounded, color: AppColors.primary),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Интеграция с календарями телефона, Google, Яндекс и Mail',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  final _EventsTab value;
  final ValueChanged<_EventsTab> onChanged;

  const _Tabs({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _TabButton(
            label: 'Будущие',
            selected: value == _EventsTab.upcoming,
            onTap: () => onChanged(_EventsTab.upcoming),
          ),
          _TabButton(
            label: 'Прошедшие',
            selected: value == _EventsTab.past,
            onTap: () => onChanged(_EventsTab.past),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  final NotificationEvent event;
  final bool isPast;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EventTile({
    required this.event,
    required this.isPast,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(event.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: !event.isRead && isPast
                ? AppColors.accent.withAlpha(120)
                : const Color(0xFFEDE6DD),
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: event.color.withAlpha(34),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(event.icon, color: event.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            event.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textMain,
                            ),
                          ),
                        ),
                        if (!event.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_dateLabel(event.date)} · ${_timeLabel(event.time)} · ${event.petName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    if (event.description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        event.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Изменить')),
                  PopupMenuItem(value: 'delete', child: Text('Удалить')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _dateLabel(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}';

  String _timeLabel(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}

class _EventEditorSheet extends StatefulWidget {
  final NotificationEvent? event;
  final DateTime initialDate;

  const _EventEditorSheet({required this.event, required this.initialDate});

  @override
  State<_EventEditorSheet> createState() => _EventEditorSheetState();
}

class _EventEditorSheetState extends State<_EventEditorSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late DateTime _date;
  late TimeOfDay _time;
  late IconData _icon;
  late Color _color;
  bool _isRecurring = false;
  List<int> _repeatWeekdays = [];
  DateTime? _repeatUntil;

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    _titleController = TextEditingController(text: event?.title ?? '');
    _descriptionController = TextEditingController(
      text: event?.description ?? '',
    );
    _date = event?.date ?? widget.initialDate;
    _time = event?.time ?? TimeOfDay.now();
    _icon = event?.icon ?? Icons.event_note_outlined;
    _color = event?.color ?? AppColors.primary;
    _isRecurring = event?.isRecurring ?? false;
    _repeatWeekdays = [...event?.repeatWeekdays ?? const []];
    _repeatUntil = event?.repeatUntil;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            16,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ListView(
        shrinkWrap: true,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD8D0C8),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.event == null ? 'Новое событие' : 'Изменить событие',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 14),
          _PresetDropdown(onSelected: _applyPreset),
          const SizedBox(height: 12),
          TextField(
            controller: _titleController,
            maxLength: 20,
            decoration: const InputDecoration(labelText: 'Название события'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _descriptionController,
            maxLength: 300,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Описание',
              hintText: 'Можно вставлять ссылки',
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _PickerButton(
                  icon: Icons.calendar_today_outlined,
                  label: _formatDate(_date),
                  onTap: _pickDate,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PickerButton(
                  icon: Icons.schedule_rounded,
                  label: _formatTime(_time),
                  onTap: _pickTime,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _ColorIconChooser(
            color: _color,
            icon: _icon,
            onColor: (value) => setState(() => _color = value),
            onIcon: (value) => setState(() => _icon = value),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            value: _isRecurring,
            onChanged: (value) => setState(() {
              _isRecurring = value;
              if (value && _repeatWeekdays.isEmpty) {
                _repeatWeekdays = const [1, 2, 3, 4, 5, 6, 7];
              }
            }),
            title: const Text('Регулярное событие'),
            subtitle: const Text('Дни повторения и дата завершения'),
            contentPadding: EdgeInsets.zero,
          ),
          if (_isRecurring) ...[
            _WeekdayChips(
              selected: _repeatWeekdays,
              onChanged: (value) => setState(() => _repeatWeekdays = value),
            ),
            const SizedBox(height: 10),
            _PickerButton(
              icon: Icons.event_repeat_rounded,
              label: _repeatUntil == null
                  ? 'Бессрочно'
                  : 'До ${_formatDate(_repeatUntil!)}',
              onTap: _pickRepeatUntil,
            ),
          ],
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: _save,
            child: const Text('Сохранить событие'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Выйти без сохранения'),
          ),
        ],
      ),
    );
  }

  void _applyPreset(NotificationPreset preset) {
    setState(() {
      _titleController.text = preset.title.characters.take(20).toString();
      _descriptionController.text = preset.description;
      _icon = preset.icon;
      _color = preset.color;
    });
  }

  Future<void> _pickDate() async {
    final result = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (result != null) setState(() => _date = result);
  }

  Future<void> _pickTime() async {
    final result = await showTimePicker(context: context, initialTime: _time);
    if (result != null) setState(() => _time = result);
  }

  Future<void> _pickRepeatUntil() async {
    final result = await showDatePicker(
      context: context,
      initialDate: _repeatUntil ?? _date.add(const Duration(days: 30)),
      firstDate: _date,
      lastDate: DateTime(2035),
    );
    setState(() => _repeatUntil = result);
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Введите название события')));
      return;
    }
    final event = (widget.event ?? _blankEvent()).copyWith(
      title: title,
      description: _descriptionController.text.trim(),
      date: _date,
      time: _time,
      icon: _icon,
      color: _color,
      isRecurring: _isRecurring,
      repeatWeekdays: _isRecurring ? _repeatWeekdays : [],
      repeatUntil: _repeatUntil,
      clearRepeatUntil: !_isRecurring || _repeatUntil == null,
    );
    Navigator.pop(context, event);
  }

  NotificationEvent _blankEvent() => NotificationEvent(
    id: 'event-${DateTime.now().microsecondsSinceEpoch}',
    title: '',
    petName: 'Питомец',
    date: _date,
    time: _time,
    description: '',
    icon: _icon,
    color: _color,
  );

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';

  String _formatTime(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}

class _PresetDropdown extends StatelessWidget {
  final ValueChanged<NotificationPreset> onSelected;
  const _PresetDropdown({required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<NotificationPreset>(
      decoration: const InputDecoration(
        labelText: 'Настроить по данным профиля',
      ),
      items: [
        for (final preset in notificationPresets)
          DropdownMenuItem(value: preset, child: Text(preset.title)),
      ],
      onChanged: (value) {
        if (value != null) onSelected(value);
      },
    );
  }
}

class _PickerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PickerButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label, overflow: TextOverflow.ellipsis),
    );
  }
}

class _ColorIconChooser extends StatelessWidget {
  final Color color;
  final IconData icon;
  final ValueChanged<Color> onColor;
  final ValueChanged<IconData> onIcon;

  const _ColorIconChooser({
    required this.color,
    required this.icon,
    required this.onColor,
    required this.onIcon,
  });

  @override
  Widget build(BuildContext context) {
    const colors = [
      AppColors.primary,
      AppColors.accent,
      AppColors.warning,
      AppColors.teal,
      AppColors.error,
    ];
    const icons = [
      Icons.event_note_outlined,
      Icons.vaccines_outlined,
      Icons.bug_report_outlined,
      Icons.restaurant_outlined,
      Icons.local_hospital_outlined,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Цвет и значок',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (final item in colors)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => onColor(item),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: item,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                        color: color == item
                            ? AppColors.textMain
                            : Colors.white,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in icons)
              OutlinedButton(
                onPressed: () => onIcon(item),
                style: OutlinedButton.styleFrom(
                  backgroundColor: icon == item
                      ? AppColors.primary.withAlpha(30)
                      : null,
                ),
                child: Icon(
                  item,
                  color: icon == item ? AppColors.primary : AppColors.textMain,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _WeekdayChips extends StatelessWidget {
  final List<int> selected;
  final ValueChanged<List<int>> onChanged;

  const _WeekdayChips({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const labels = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    return Wrap(
      spacing: 8,
      children: [
        for (var i = 0; i < labels.length; i++)
          FilterChip(
            label: Text(labels[i]),
            selected: selected.contains(i + 1),
            onSelected: (value) {
              final next = [...selected];
              value ? next.add(i + 1) : next.remove(i + 1);
              next.sort();
              onChanged(next);
            },
          ),
      ],
    );
  }
}

class _EventDetailsSheet extends StatelessWidget {
  final NotificationEvent event;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EventDetailsSheet({
    required this.event,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        18,
        20,
        MediaQuery.of(context).padding.bottom + 20,
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
              CircleAvatar(
                backgroundColor: event.color.withAlpha(34),
                child: Icon(event.icon, color: event.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  event.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${event.petName} · ${event.date.day}.${event.date.month}.${event.date.year} · ${event.time.format(context)}',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Text(event.description, style: const TextStyle(height: 1.35)),
          if (event.isRecurring) ...[
            const SizedBox(height: 12),
            const Text(
              'Повторяется по выбранным дням',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Удалить'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Изменить'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NotificationSettingsSheet extends StatefulWidget {
  const _NotificationSettingsSheet();

  @override
  State<_NotificationSettingsSheet> createState() =>
      _NotificationSettingsSheetState();
}

class _NotificationSettingsSheetState
    extends State<_NotificationSettingsSheet> {
  bool pushAllowed = true;
  bool appPush = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        18,
        20,
        MediaQuery.of(context).padding.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.notifications_active_outlined),
            title: const Text('Пуш уведомления'),
            subtitle: const Text('Разрешение будет запрашиваться у системы'),
            trailing: Switch(
              value: pushAllowed,
              onChanged: (value) => setState(() => pushAllowed = value),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.mobile_friendly_rounded),
            title: const Text('Пуши от приложения'),
            subtitle: const Text(
              'Можно выключить, если подключен внешний календарь',
            ),
            trailing: Switch(
              value: appPush,
              onChanged: pushAllowed
                  ? (value) => setState(() => appPush = value)
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Фоновая доставка поверх других приложений потребует настройки Firebase/APNs и разрешений Android/iOS.',
            style: TextStyle(color: AppColors.textSecondary, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _InfoSheet extends StatelessWidget {
  final String title;
  final IconData icon;
  final String text;

  const _InfoSheet({
    required this.title,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        18,
        20,
        MediaQuery.of(context).padding.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withAlpha(34),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _UnreadSummary extends StatelessWidget {
  final int unread;
  const _UnreadSummary({required this.unread});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(35),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.notifications_none_rounded,
            color: AppColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              unread > 0
                  ? 'Непрочитанных уведомлений: $unread'
                  : 'Все уведомления прочитаны',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyEvents extends StatelessWidget {
  final _EventsTab tab;
  const _EmptyEvents({required this.tab});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        tab == _EventsTab.past
            ? 'Прошедших уведомлений пока нет'
            : 'Ближайших событий пока нет',
        style: const TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}
