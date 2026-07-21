import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../features/checklists/providers/checklists_provider.dart';
import '../../../models/checklist_model.dart';

class ChecklistSheet extends ConsumerWidget {
  final ChecklistModel checklist;
  final DateTime? occurrenceDate;

  const ChecklistSheet({
    super.key,
    required this.checklist,
    this.occurrenceDate,
  });

  static Future<void> show(
    BuildContext context,
    ChecklistModel checklist, {
    DateTime? occurrenceDate,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          ChecklistSheet(checklist: checklist, occurrenceDate: occurrenceDate),
    );
  }

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
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 20,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDD8D2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _SheetHeader(checklist: current),
              const SizedBox(height: 16),
              _ProgressBar(checklist: current),
              if (current.description != null &&
                  current.description!.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  current.description!,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              ...List.generate(
                current.items.length,
                (index) => _CheckTile(
                  item: current.items[index],
                  onToggle: () => ref
                      .read(checklistsProvider.notifier)
                      .updateChecklist(current.toggleItem(index)),
                  onDelete: () => ref
                      .read(checklistsProvider.notifier)
                      .updateChecklist(current.removeItem(index)),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: current.items.length >= 40
                          ? null
                          : () => _showAddItemDialog(context, ref, current),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Пункт'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showEditDialog(context, ref, current),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Редактировать'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
                label: const Text('Закрыть'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAddItemDialog(
    BuildContext context,
    WidgetRef ref,
    ChecklistModel checklist,
  ) async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Пункт чек-листа'),
        content: TextField(
          controller: controller,
          maxLength: 50,
          decoration: const InputDecoration(
            hintText: 'Например, вычесать шерсть',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
    if (value != null && value.isNotEmpty) {
      await ref
          .read(checklistsProvider.notifier)
          .updateChecklist(checklist.addItem(value));
    }
  }

  Future<void> _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    ChecklistModel checklist,
  ) async {
    final titleCtrl = TextEditingController(text: checklist.title);
    final descCtrl = TextEditingController(text: checklist.description ?? '');
    var scheduledDate =
        DateTime.tryParse(checklist.scheduledDate) ?? DateTime.now();
    var repeatWeekdays = checklist.repeatWeekdays.toSet();
    var durationType = checklist.durationType;
    var endDate = checklist.endDate == null
        ? scheduledDate.add(const Duration(days: 30))
        : DateTime.tryParse(checklist.endDate!) ?? scheduledDate;
    final repeatCountCtrl = TextEditingController(
      text: checklist.repeatCount?.toString() ?? '',
    );
    var isPinned = checklist.isPinned;
    var editOnlyThisDate = false;
    final editDate = occurrenceDate ?? scheduledDate;
    final isRecurring = checklist.repeatWeekdays.isNotEmpty;
    final saved = await showDialog<ChecklistModel>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Редактирование'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleCtrl,
                  maxLength: 20,
                  decoration: const InputDecoration(labelText: 'Название'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descCtrl,
                  maxLength: 120,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Краткое описание',
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: ctx,
                      initialDate: scheduledDate,
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 1),
                      ),
                      lastDate: DateTime.now().add(
                        const Duration(days: 365 * 3),
                      ),
                    );
                    if (date != null) setState(() => scheduledDate = date);
                  },
                  icon: const Icon(Icons.event_outlined),
                  label: Text(
                    'Дата: ${_formatDate(ChecklistModel.dateKey(scheduledDate))}',
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Регулярность',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: List.generate(7, (index) {
                    const names = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
                    final day = index + 1;
                    final selected = repeatWeekdays.contains(day);
                    return FilterChip(
                      label: Text(names[index]),
                      selected: selected,
                      onSelected: (value) => setState(() {
                        repeatWeekdays = {...repeatWeekdays};
                        if (value) {
                          repeatWeekdays.add(day);
                        } else {
                          repeatWeekdays.remove(day);
                        }
                      }),
                    );
                  }),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: durationType,
                  decoration: const InputDecoration(labelText: 'Длительность'),
                  items: const [
                    DropdownMenuItem(
                      value: 'forever',
                      child: Text('Бессрочно'),
                    ),
                    DropdownMenuItem(
                      value: 'single',
                      child: Text('Только выбранная дата'),
                    ),
                    DropdownMenuItem(
                      value: 'until_date',
                      child: Text('До даты'),
                    ),
                    DropdownMenuItem(
                      value: 'repeat_count',
                      child: Text('Количество повторений'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => durationType = value);
                  },
                ),
                if (durationType == 'until_date') ...[
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: ctx,
                        initialDate: endDate.isBefore(scheduledDate)
                            ? scheduledDate
                            : endDate,
                        firstDate: scheduledDate,
                        lastDate: DateTime.now().add(
                          const Duration(days: 365 * 3),
                        ),
                      );
                      if (date != null) setState(() => endDate = date);
                    },
                    icon: const Icon(Icons.event_repeat_outlined),
                    label: Text(
                      'Завершить: ${_formatDate(ChecklistModel.dateKey(endDate))}',
                    ),
                  ),
                ],
                if (durationType == 'repeat_count') ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: repeatCountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Количество повторений',
                      hintText: 'Например, 12',
                    ),
                  ),
                ],
                if (isRecurring) ...[
                  const SizedBox(height: 10),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: editOnlyThisDate,
                    title: Text(
                      'Только ${_formatDate(ChecklistModel.dateKey(editDate))}',
                    ),
                    subtitle: const Text(
                      'Создать исключение из регулярного чек-листа',
                    ),
                    onChanged: (value) =>
                        setState(() => editOnlyThisDate = value ?? false),
                  ),
                ],
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: isPinned,
                  title: const Text('Показывать на главной'),
                  onChanged: (value) => setState(() => isPinned = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                final title = titleCtrl.text.trim();
                if (title.isEmpty) return;
                final repeatCount = int.tryParse(repeatCountCtrl.text);
                Navigator.pop(
                  ctx,
                  checklist
                      .copyWith(
                        title: title,
                        scheduledDate: ChecklistModel.dateKey(scheduledDate),
                        repeatWeekdays:
                            durationType == 'single'
                                  ? const []
                                  : repeatWeekdays.toList()
                              ..sort(),
                        durationType: durationType,
                        endDate: durationType == 'until_date'
                            ? ChecklistModel.dateKey(endDate)
                            : null,
                        repeatCount: durationType == 'repeat_count'
                            ? (repeatCount == null || repeatCount < 1
                                  ? 1
                                  : repeatCount)
                            : null,
                        isPinned: isPinned,
                      )
                      .withNullableFields(
                        description: descCtrl.text.trim().isEmpty
                            ? null
                            : descCtrl.text.trim(),
                        endDate: durationType == 'until_date'
                            ? ChecklistModel.dateKey(endDate)
                            : null,
                        repeatCount: durationType == 'repeat_count'
                            ? (repeatCount == null || repeatCount < 1
                                  ? 1
                                  : repeatCount)
                            : null,
                      ),
                );
              },
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
    if (saved != null) {
      final notifier = ref.read(checklistsProvider.notifier);
      if (editOnlyThisDate) {
        await notifier.createExceptionForDate(
          source: checklist,
          edited: saved,
          date: editDate,
        );
      } else {
        await notifier.updateFutureChecklist(saved);
      }
    }
  }

  String _formatDate(String value) {
    final date = DateTime.tryParse(value);
    if (date == null) return value;
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}

class ChecklistPreviewCard extends ConsumerWidget {
  final ChecklistModel checklist;
  final DateTime? occurrenceDate;

  const ChecklistPreviewCard({
    super.key,
    required this.checklist,
    this.occurrenceDate,
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

    return GestureDetector(
      onTap: () =>
          ChecklistSheet.show(context, current, occurrenceDate: occurrenceDate),
      child: Container(
        padding: const EdgeInsets.all(16),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SheetHeader(checklist: current, compact: true),
            const SizedBox(height: 12),
            _ProgressBar(checklist: current, compact: true),
            const SizedBox(height: 12),
            ...current.previewItems.map((item) => _PreviewLine(item: item)),
            if (current.remainingCount > 0) ...[
              const SizedBox(height: 5),
              Text(
                '+ еще ${current.remainingCount}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  final ChecklistModel checklist;
  final bool compact;

  const _SheetHeader({required this.checklist, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: compact ? 44 : 42,
          height: compact ? 44 : 42,
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(38),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.checklist_rounded, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                checklist.title,
                style: compact
                    ? const TextStyle(
                        color: AppColors.textMain,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      )
                    : Theme.of(context).textTheme.titleLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                '${checklist.petName} · ${_repeatLabel(checklist)}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (compact)
          Text(
            '${(checklist.progress * 100).round()}%',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          )
        else
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
            color: AppColors.textSecondary,
          ),
      ],
    );
  }

  String _repeatLabel(ChecklistModel checklist) {
    if (checklist.repeatWeekdays.length == 7) return 'ежедневно';
    if (checklist.repeatWeekdays.isEmpty) {
      return _formatDate(checklist.scheduledDate);
    }
    const names = ['пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс'];
    return checklist.repeatWeekdays.map((d) => names[d - 1]).join(', ');
  }

  String _formatDate(String value) {
    final date = DateTime.tryParse(value);
    if (date == null) return value;
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}

class _ProgressBar extends StatelessWidget {
  final ChecklistModel checklist;
  final bool compact;

  const _ProgressBar({required this.checklist, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (!compact) ...[
          Row(
            children: [
              const Text(
                'Прогресс',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${checklist.doneCount} / ${checklist.totalCount}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: checklist.progress,
            backgroundColor: const Color(0xFFE8E2DB),
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            minHeight: compact ? 7 : 8,
          ),
        ),
      ],
    );
  }
}

class _PreviewLine extends StatelessWidget {
  final ChecklistItemModel item;

  const _PreviewLine({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            item.isDone ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 16,
            color: item.isDone ? AppColors.primary : const Color(0xFFCFC7BE),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item.title,
              style: TextStyle(
                color: item.isDone
                    ? AppColors.textSecondary
                    : AppColors.textMain,
                fontSize: 13,
                decoration: item.isDone ? TextDecoration.lineThrough : null,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckTile extends StatelessWidget {
  final ChecklistItemModel item;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _CheckTile({
    required this.item,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: item.isDone ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: item.isDone
                      ? AppColors.primary
                      : const Color(0xFFCCC5BC),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: item.isDone
                  ? const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                item.title,
                style: TextStyle(
                  fontSize: 16,
                  color: item.isDone
                      ? AppColors.textSecondary
                      : AppColors.textMain,
                  decoration: item.isDone ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded),
              color: AppColors.textSecondary,
              tooltip: 'Удалить',
            ),
          ],
        ),
      ),
    );
  }
}
