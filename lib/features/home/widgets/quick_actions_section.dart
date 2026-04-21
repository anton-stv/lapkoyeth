import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_helper.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/pet_model.dart';
import '../../../models/weight_record_model.dart';
import '../../pets/providers/pets_provider.dart';
import 'checklist_sheet.dart';

class QuickActionsSection extends ConsumerWidget {
  const QuickActionsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Быстрые действия',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Row(
            children: [
              _ActionCard(
                icon: '⚖️',
                label: 'Записать\nвес',
                color: AppColors.teal,
                onTap: () => _handleWeight(context, ref),
              ),
              const SizedBox(width: 10),
              _ActionCard(
                icon: '📷',
                label: 'Добавить\nфото',
                color: AppColors.secondary,
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Галерея — скоро')),
                ),
              ),
              const SizedBox(width: 10),
              _ActionCard(
                icon: '✅',
                label: 'Чек-лист\nсегодня',
                color: AppColors.primary,
                onTap: () => ChecklistSheet.show(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleWeight(BuildContext context, WidgetRef ref) async {
    final pets = ref.read(petsProvider).valueOrNull ?? [];
    if (pets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сначала добавьте питомца')),
      );
      return;
    }
    if (pets.length == 1) {
      await _showWeightInput(context, ref, pets.first);
    } else {
      final selected = await showDialog<PetModel>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.background,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Выберите питомца'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: pets.map((p) => ListTile(
              title: Text(p.name),
              subtitle: p.breed != null ? Text(p.breed!) : null,
              onTap: () => Navigator.pop(ctx, p),
            )).toList(),
          ),
        ),
      );
      if (selected != null && context.mounted) {
        await _showWeightInput(context, ref, selected);
      }
    }
  }

  Future<void> _showWeightInput(BuildContext context, WidgetRef ref, PetModel pet) async {
    final controller = TextEditingController();
    final saved = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Вес — ${pet.name}'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(hintText: 'кг, например 12.5', suffixText: 'кг'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(80, 40)),
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
    if (saved != null && saved.isNotEmpty) {
      final val = double.tryParse(saved.replaceAll(',', '.'));
      if (val != null && pet.id != null) {
        await DatabaseHelper.instance.insertWeightRecord(WeightRecordModel(
          petId: pet.id!,
          weight: val,
          date: DateTime.now().toIso8601String(),
        ));
        await ref.read(petsProvider.notifier).updatePet(pet.copyWith(weight: val));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Вес ${pet.name}: $val кг сохранён')),
          );
        }
      }
    }
  }
}

class _ActionCard extends StatelessWidget {
  final String icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: color.withAlpha(40),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withAlpha(60)),
          ),
          child: Column(
            children: [
              Text(icon, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMain,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
