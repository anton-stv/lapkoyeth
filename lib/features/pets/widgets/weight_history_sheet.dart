import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_helper.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/weight_record_model.dart';
import '../providers/pets_provider.dart';

class WeightHistorySheet extends ConsumerStatefulWidget {
  final int petId;
  const WeightHistorySheet({super.key, required this.petId});

  static Future<void> show(BuildContext context, int petId) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WeightHistorySheet(petId: petId),
    );
  }

  @override
  ConsumerState<WeightHistorySheet> createState() => _WeightHistorySheetState();
}

class _WeightHistorySheetState extends ConsumerState<WeightHistorySheet> {
  final _weightCtrl = TextEditingController();

  @override
  void dispose() {
    _weightCtrl.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final val = double.tryParse(_weightCtrl.text.replaceAll(',', '.'));
    if (val == null) return;
    await DatabaseHelper.instance.insertWeightRecord(WeightRecordModel(
      petId: widget.petId,
      weight: val,
      date: DateTime.now().toIso8601String(),
    ));
    _weightCtrl.clear();
    ref.invalidate(weightRecordsProvider(widget.petId));
  }

  @override
  Widget build(BuildContext context) {
    final records = ref.watch(weightRecordsProvider(widget.petId));

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDDD8D2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  Text('История веса',
                      style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  // Добавить новую запись
                  SizedBox(
                    width: 120,
                    child: TextField(
                      controller: _weightCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        hintText: 'кг',
                        suffixText: 'кг',
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size(56, 40)),
                    onPressed: _add,
                    child: const Text('+ '),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: records.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, s) => Center(child: Text('Ошибка: $e')),
                data: (list) => list.isEmpty
                    ? const Center(
                        child: Text('Нет записей',
                            style:
                                TextStyle(color: AppColors.textSecondary)))
                    : ListView.separated(
                        controller: controller,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        itemCount: list.length,
                        separatorBuilder: (_, i) =>
                            const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final r = list[i];
                          final date = DateTime.tryParse(r.date);
                          final dateStr = date != null
                              ? '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}'
                              : '';
                          return ListTile(
                            title: Text('${r.weight} кг',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            subtitle: Text(dateStr),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: AppColors.textSecondary),
                              onPressed: () async {
                                await DatabaseHelper.instance
                                    .deleteWeightRecord(r.id!);
                                ref.invalidate(
                                    weightRecordsProvider(widget.petId));
                              },
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
