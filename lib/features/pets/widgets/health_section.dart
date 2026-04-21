import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_helper.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/health_record_model.dart';
import '../providers/pets_provider.dart';

class HealthSection extends ConsumerWidget {
  final int petId;
  const HealthSection({super.key, required this.petId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(healthRecordsProvider(petId));

    return records.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: CircularProgressIndicator(),
      ),
      error: (e, s) => Text('Ошибка: $e'),
      data: (list) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HealthGroup(
            petId: petId,
            type: HealthRecordType.anamnesis,
            label: 'Анамнез',
            icon: Icons.history_edu_rounded,
            records: list.where((r) => r.type == HealthRecordType.anamnesis).toList(),
            ref: ref,
          ),
          _HealthGroup(
            petId: petId,
            type: HealthRecordType.visit,
            label: 'Приёмы врача',
            icon: Icons.local_hospital_rounded,
            records: list.where((r) => r.type == HealthRecordType.visit).toList(),
            ref: ref,
          ),
          _HealthGroup(
            petId: petId,
            type: HealthRecordType.vaccination,
            label: 'Прививки',
            icon: Icons.vaccines_rounded,
            records: list.where((r) => r.type == HealthRecordType.vaccination).toList(),
            ref: ref,
          ),
          _HealthGroup(
            petId: petId,
            type: HealthRecordType.medication,
            label: 'Препараты',
            icon: Icons.medication_rounded,
            records: list.where((r) => r.type == HealthRecordType.medication).toList(),
            ref: ref,
          ),
        ],
      ),
    );
  }
}

class _HealthGroup extends StatelessWidget {
  final int petId;
  final HealthRecordType type;
  final String label;
  final IconData icon;
  final List<HealthRecordModel> records;
  final WidgetRef ref;

  const _HealthGroup({
    required this.petId,
    required this.type,
    required this.label,
    required this.icon,
    required this.records,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textMain)),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _showAddDialog(context),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Добавить', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ],
        ),
        if (records.isEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 22, bottom: 8),
            child: Text('Нет записей',
                style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary.withAlpha(160))),
          )
        else
          ...records.map((r) => _RecordTile(
                record: r,
                onDelete: () async {
                  await DatabaseHelper.instance.deleteHealthRecord(r.id!);
                  ref.invalidate(healthRecordsProvider(petId));
                },
              )),
        const SizedBox(height: 8),
      ],
    );
  }

  Future<void> _showAddDialog(BuildContext context) async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Добавить: $label'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(hintText: 'Название *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(hintText: 'Описание'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(80, 40)),
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty) return;
              await DatabaseHelper.instance.insertHealthRecord(HealthRecordModel(
                petId: petId,
                type: type,
                title: titleCtrl.text.trim(),
                date: DateTime.now().toIso8601String(),
                description: descCtrl.text.trim().isEmpty
                    ? null
                    : descCtrl.text.trim(),
              ));
              ref.invalidate(healthRecordsProvider(petId));
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }
}

class _RecordTile extends StatelessWidget {
  final HealthRecordModel record;
  final VoidCallback onDelete;
  const _RecordTile({required this.record, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(record.date);
    final dateStr = date != null
        ? '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}'
        : '';
    return Padding(
      padding: const EdgeInsets.only(left: 22, bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record.title,
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.textMain)),
                if (record.description != null)
                  Text(record.description!,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                Text(dateStr,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                size: 18, color: AppColors.textSecondary),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
