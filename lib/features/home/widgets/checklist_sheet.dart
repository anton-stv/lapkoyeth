import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class ChecklistSheet extends StatefulWidget {
  const ChecklistSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ChecklistSheet(),
    );
  }

  @override
  State<ChecklistSheet> createState() => _ChecklistSheetState();
}

class _ChecklistSheetState extends State<ChecklistSheet> {
  final _items = [
    _CheckItem('Покормили утром', false),
    _CheckItem('Покормили вечером', false),
    _CheckItem('Погуляли', false),
    _CheckItem('Дали лекарства', false),
    _CheckItem('Взвешивание', false),
    _CheckItem('Вычесали шерсть', false),
  ];

  @override
  Widget build(BuildContext context) {
    final done = _items.where((i) => i.checked).length;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
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
          const SizedBox(height: 20),
          Row(
            children: [
              Text('Чек-лист на сегодня',
                  style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              Text(
                '$done / ${_items.length}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _items.isEmpty ? 0 : done / _items.length,
              backgroundColor: const Color(0xFFE8E2DB),
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 16),
          ..._items.map((item) => _CheckTile(
                item: item,
                onToggle: () => setState(() => item.checked = !item.checked),
              )),
        ],
      ),
    );
  }
}

class _CheckItem {
  final String title;
  bool checked;
  _CheckItem(this.title, this.checked);
}

class _CheckTile extends StatelessWidget {
  final _CheckItem item;
  final VoidCallback onToggle;
  const _CheckTile({required this.item, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: item.checked ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: item.checked ? AppColors.primary : const Color(0xFFCCC5BC),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: item.checked
                  ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 14),
            Text(
              item.title,
              style: TextStyle(
                fontSize: 16,
                color: item.checked ? AppColors.textSecondary : AppColors.textMain,
                decoration: item.checked ? TextDecoration.lineThrough : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
