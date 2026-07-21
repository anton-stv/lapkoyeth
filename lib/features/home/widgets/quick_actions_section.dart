import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_helper.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/checklists/providers/checklists_provider.dart';
import '../../../models/checklist_model.dart';
import '../../../models/pet_model.dart';
import '../../../models/weight_record_model.dart';
import '../../pets/providers/pets_provider.dart';
import '../../pets/screens/pet_detail_screen.dart';
import 'checklist_sheet.dart';

class QuickActionsSection extends ConsumerWidget {
  const QuickActionsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pets = ref.watch(petsProvider).valueOrNull ?? [];
    final firstPet = pets.isNotEmpty ? pets.first : null;
    final today = DateTime.now();
    final checklists = (ref.watch(checklistsProvider).valueOrNull ?? [])
        .where((checklist) => checklist.isPinned && checklist.occursOn(today))
        .take(ChecklistsNotifier.pinnedLimit)
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Быстрые действия',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              TextButton(
                onPressed: pets.isEmpty
                    ? () => _showNeedPet(context)
                    : () => _openQuickActionSettings(context, ref, pets),
                child: const Text('Настроить'),
              ),
            ],
          ),
          const Text(
            'Вес, фото и до 10 закрепленных чек-листов',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 12),
          if (checklists.isNotEmpty) ...[
            ...checklists.map(
              (checklist) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ChecklistPreviewCard(
                  checklist: checklist,
                  occurrenceDate: today,
                ),
              ),
            ),
          ] else if (firstPet != null) ...[
            _CreateDefaultChecklistCard(pet: firstPet),
            const SizedBox(height: 12),
          ],
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.72,
            children: [
              _ActionCard(
                icon: Icons.checklist_rounded,
                title: 'Чек-лист',
                subtitle: pets.isEmpty
                    ? 'Сначала добавьте питомца'
                    : 'Выбрать и закрепить',
                color: AppColors.secondary,
                onTap: pets.isEmpty
                    ? () => _showNeedPet(context)
                    : () => _openQuickActionSettings(context, ref, pets),
              ),
              _ActionCard(
                icon: Icons.monitor_weight_outlined,
                title: 'Записать вес',
                subtitle: firstPet == null
                    ? 'Сначала добавьте питомца'
                    : '${firstPet.name} • ${firstPet.weight ?? 'нет данных'} кг',
                color: AppColors.teal,
                onTap: () => _handleWeight(context, ref),
              ),
              _ActionCard(
                icon: Icons.photo_camera_outlined,
                title: 'Фото',
                subtitle: 'Галерея или документы',
                color: AppColors.primary,
                onTap: () => _showPhotoOptions(context),
              ),
              _ActionCard(
                icon: Icons.medical_services_outlined,
                title: 'Сервисы',
                subtitle: 'Раздел в разработке',
                color: AppColors.accent,
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Сервисы — скоро')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showNeedPet(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Сначала добавьте питомца')));
  }

  Future<void> _openQuickActionSettings(
    BuildContext context,
    WidgetRef ref,
    List<PetModel> pets,
  ) async {
    final validPets = pets.where((pet) => pet.id != null).toList();
    if (validPets.isEmpty) {
      _showNeedPet(context);
      return;
    }
    if (validPets.length == 1) {
      await _showChecklistPicker(context, ref, [validPets.first]);
      return;
    }
    final selectedPets = await _showPetPicker(context, ref, validPets);
    if (selectedPets != null && selectedPets.isNotEmpty && context.mounted) {
      await _showChecklistPicker(context, ref, selectedPets);
    }
  }

  Future<List<PetModel>?> _showPetPicker(
    BuildContext context,
    WidgetRef ref,
    List<PetModel> pets,
  ) {
    final allChecklists = ref.read(checklistsProvider).valueOrNull ?? [];
    final selectedIds = <int>{};

    return showModalBottomSheet<List<PetModel>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          return _ActionSheetFrame(
            title: 'Выберите питомца',
            subtitle: 'Можно выбрать одного или нескольких',
            leading: const SizedBox.shrink(),
            child: Column(
              children: [
                ...pets.map((pet) {
                  final petId = pet.id!;
                  final count = allChecklists
                      .where((checklist) => checklist.petId == petId)
                      .length;
                  final selected = selectedIds.contains(petId);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _PetChoiceCard(
                      pet: pet,
                      checklistCount: count,
                      selected: selected,
                      onToggle: () => setState(() {
                        if (selected) {
                          selectedIds.remove(petId);
                        } else {
                          selectedIds.add(petId);
                        }
                      }),
                      onChooseChecklists: () =>
                          Navigator.pop(ctx, <PetModel>[pet]),
                    ),
                  );
                }),
                const SizedBox(height: 6),
                ElevatedButton(
                  onPressed: selectedIds.isEmpty
                      ? null
                      : () => Navigator.pop(
                          ctx,
                          pets
                              .where((pet) => selectedIds.contains(pet.id))
                              .toList(),
                        ),
                  child: const Text('Перейти к чек-листам'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showChecklistPicker(
    BuildContext context,
    WidgetRef ref,
    List<PetModel> pets,
  ) async {
    final petIds = pets.map((pet) => pet.id).whereType<int>().toSet();
    final allChecklists = ref.read(checklistsProvider).valueOrNull ?? [];
    final visible = allChecklists
        .where((checklist) => petIds.contains(checklist.petId))
        .toList();
    final selectedIds = visible
        .where((checklist) => checklist.isPinned && checklist.id != null)
        .map((checklist) => checklist.id!)
        .toSet();
    final originallyPinnedIds = (ref.read(checklistsProvider).valueOrNull ?? [])
        .where((checklist) => checklist.isPinned && checklist.id != null)
        .map((checklist) => checklist.id!)
        .toSet();

    final savedIds = await showModalBottomSheet<Set<int>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final futurePinnedIds = {
            ...originallyPinnedIds.where(
              (id) => !visible.any((checklist) => checklist.id == id),
            ),
            ...selectedIds,
          };
          final selectedCount = futurePinnedIds.length;
          final title = pets.length == 1
              ? '${pets.first.name}: чек-листы'
              : 'Чек-листы питомцев';

          return _ActionSheetFrame(
            title: title,
            subtitle: '${pets.length} питомец · выберите чек-листы',
            leading: pets.length > 1
                ? IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  )
                : const SizedBox(width: 48),
            child: visible.isEmpty
                ? _EmptyChecklistState(
                    pet: pets.first,
                    onCreate: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PetDetailScreen(pet: pets.first),
                        ),
                      );
                    },
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...pets.map((pet) {
                        final petChecklists = visible
                            .where((checklist) => checklist.petId == pet.id)
                            .toList();
                        if (petChecklists.isEmpty) {
                          return _PetEmptyGroup(
                            pet: pet,
                            onCreate: () {
                              Navigator.pop(ctx);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PetDetailScreen(pet: pet),
                                ),
                              );
                            },
                          );
                        }
                        return _ChecklistPetGroup(
                          pet: pet,
                          checklists: petChecklists,
                          selectedIds: selectedIds,
                          selectedCount: selectedCount,
                          onSelectAll: () => setState(() {
                            final missing = petChecklists
                                .where((item) => item.id != null)
                                .where((item) => !selectedIds.contains(item.id))
                                .map((item) => item.id!)
                                .toList();
                            final allowed =
                                ChecklistsNotifier.pinnedLimit -
                                futurePinnedIds.length;
                            selectedIds.addAll(missing.take(allowed));
                            if (missing.length > allowed) {
                              _showLimitError(context);
                            }
                          }),
                          onToggle: (checklist) => setState(() {
                            final id = checklist.id;
                            if (id == null) return;
                            if (selectedIds.contains(id)) {
                              selectedIds.remove(id);
                              return;
                            }
                            if (futurePinnedIds.length >=
                                ChecklistsNotifier.pinnedLimit) {
                              _showLimitError(context);
                              return;
                            }
                            selectedIds.add(id);
                          }),
                        );
                      }),
                      const SizedBox(height: 12),
                      _PinnedSummary(count: selectedCount),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, selectedIds),
                        child: Text(
                          selectedCount == 0
                              ? 'Сохранить быстрые действия'
                              : 'Закрепить: $selectedCount',
                        ),
                      ),
                    ],
                  ),
          );
        },
      ),
    );

    if (savedIds == null) return;
    for (final checklist in visible) {
      final id = checklist.id;
      if (id == null) continue;
      final shouldPin = savedIds.contains(id);
      if (checklist.isPinned != shouldPin) {
        await ref
            .read(checklistsProvider.notifier)
            .updateChecklist(checklist.copyWith(isPinned: shouldPin));
      }
    }
  }

  void _showLimitError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Достигнут лимит: 10 быстрых действий')),
    );
  }

  Future<void> _showPhotoOptions(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Сохранить в галерею'),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Фото в галерею — скоро')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: const Text('Сохранить в документы'),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Фото в документы — скоро')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleWeight(BuildContext context, WidgetRef ref) async {
    final pets = ref.read(petsProvider).valueOrNull ?? [];
    if (pets.isEmpty) {
      _showNeedPet(context);
      return;
    }
    if (pets.length == 1) {
      await _showWeightInput(context, ref, pets.first);
    } else {
      final selected = await showDialog<PetModel>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Выберите питомца'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: pets
                .map(
                  (p) => ListTile(
                    title: Text(p.name),
                    subtitle: p.breed != null ? Text(p.breed!) : null,
                    onTap: () => Navigator.pop(ctx, p),
                  ),
                )
                .toList(),
          ),
        ),
      );
      if (selected != null && context.mounted) {
        await _showWeightInput(context, ref, selected);
      }
    }
  }

  Future<void> _showWeightInput(
    BuildContext context,
    WidgetRef ref,
    PetModel pet,
  ) async {
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
          decoration: const InputDecoration(
            hintText: 'кг, например 12.5',
            suffixText: 'кг',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
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
        await DatabaseHelper.instance.insertWeightRecord(
          WeightRecordModel(
            petId: pet.id!,
            weight: val,
            date: DateTime.now().toIso8601String(),
          ),
        );
        await ref
            .read(petsProvider.notifier)
            .updatePet(pet.copyWith(weight: val));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Вес ${pet.name}: $val кг сохранён')),
          );
        }
      }
    }
  }
}

class _ActionSheetFrame extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget leading;
  final Widget child;

  const _ActionSheetFrame({
    required this.title,
    required this.subtitle,
    required this.leading,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDDD8D2),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                SizedBox(width: 48, child: leading),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
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
                IconButton.filledTonal(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(child: SingleChildScrollView(child: child)),
          ],
        ),
      ),
    );
  }
}

class _PetChoiceCard extends StatelessWidget {
  final PetModel pet;
  final int checklistCount;
  final bool selected;
  final VoidCallback onToggle;
  final VoidCallback onChooseChecklists;

  const _PetChoiceCard({
    required this.pet,
    required this.checklistCount,
    required this.selected,
    required this.onToggle,
    required this.onChooseChecklists,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected ? AppColors.primary : const Color(0xFFE8E2DB),
          width: selected ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            leading: _CheckBox(selected: selected, onTap: onToggle),
            title: Text(
              pet.name,
              style: const TextStyle(
                color: AppColors.textMain,
                fontWeight: FontWeight.w800,
              ),
            ),
            subtitle: Text(
              '$checklistCount чек-листов',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            trailing: _PetAvatar(pet: pet),
            onTap: onToggle,
          ),
          InkWell(
            onTap: onChooseChecklists,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFFF2EDE7),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
              child: const Row(
                children: [
                  Text(
                    'Выбрать чек-листы',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Spacer(),
                  Icon(Icons.chevron_right_rounded, color: AppColors.primary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistPetGroup extends StatelessWidget {
  final PetModel pet;
  final List<ChecklistModel> checklists;
  final Set<int> selectedIds;
  final int selectedCount;
  final VoidCallback onSelectAll;
  final ValueChanged<ChecklistModel> onToggle;

  const _ChecklistPetGroup({
    required this.pet,
    required this.checklists,
    required this.selectedIds,
    required this.selectedCount,
    required this.onSelectAll,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        children: [
          Row(
            children: [
              _PetAvatar(pet: pet, size: 34),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  pet.name,
                  style: const TextStyle(
                    color: AppColors.textMain,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton(onPressed: onSelectAll, child: const Text('Все')),
            ],
          ),
          const SizedBox(height: 6),
          ...checklists.map(
            (checklist) => _ChecklistChoiceTile(
              checklist: checklist,
              selected: selectedIds.contains(checklist.id),
              onTap: () => onToggle(checklist),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistChoiceTile extends StatelessWidget {
  final ChecklistModel checklist;
  final bool selected;
  final VoidCallback onTap;

  const _ChecklistChoiceTile({
    required this.checklist,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFFAF6) : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.accent : const Color(0xFFE8E2DB),
          ),
        ),
        child: Row(
          children: [
            _CheckBox(
              selected: selected,
              onTap: onTap,
              active: AppColors.accent,
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                value: checklist.progress,
                backgroundColor: const Color(0xFFF1E8DD),
                valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    checklist.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textMain,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${checklist.doneCount}/${checklist.totalCount} выполнено',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (checklist.isPinned)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withAlpha(24),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Закреплен',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PinnedSummary extends StatelessWidget {
  final int count;

  const _PinnedSummary({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(20),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.push_pin_outlined,
            size: 18,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$count из ${ChecklistsNotifier.pinnedLimit} быстрых действий',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const Icon(Icons.check_circle_outline, color: AppColors.primary),
        ],
      ),
    );
  }
}

class _EmptyChecklistState extends StatelessWidget {
  final PetModel pet;
  final VoidCallback onCreate;

  const _EmptyChecklistState({required this.pet, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        const Icon(
          Icons.checklist_rtl_rounded,
          size: 52,
          color: AppColors.textSecondary,
        ),
        const SizedBox(height: 12),
        const Text(
          'У этого питомца пока нет чек-листов',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textMain,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 14),
        ElevatedButton.icon(
          onPressed: onCreate,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Создать чек-лист'),
        ),
      ],
    );
  }
}

class _PetEmptyGroup extends StatelessWidget {
  final PetModel pet;
  final VoidCallback onCreate;

  const _PetEmptyGroup({required this.pet, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              pet.name,
              style: const TextStyle(
                color: AppColors.textMain,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'У этого питомца пока нет чек-листов',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Создать чек-лист'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PetAvatar extends StatelessWidget {
  final PetModel pet;
  final double size;

  const _PetAvatar({required this.pet, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AppColors.primary.withAlpha(28),
      child: Text(
        pet.name.isEmpty ? '?' : pet.name.characters.first.toUpperCase(),
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _CheckBox extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final Color active;

  const _CheckBox({
    required this.selected,
    required this.onTap,
    this.active = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: selected ? active : Colors.transparent,
          border: Border.all(
            color: selected ? active : const Color(0xFFE3DDD6),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(9),
        ),
        child: selected
            ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
            : null,
      ),
    );
  }
}

class _CreateDefaultChecklistCard extends ConsumerWidget {
  final PetModel pet;

  const _CreateDefaultChecklistCard({required this.pet});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _ActionCard(
      icon: Icons.checklist_rounded,
      title: 'Уход за день',
      subtitle: '${pet.name} · создать чек-лист',
      color: AppColors.primary,
      onTap: () async {
        if (pet.id == null) return;
        final checklist = await ref
            .read(checklistsProvider.notifier)
            .ensureDefaultChecklist(petId: pet.id!, petName: pet.name);
        if (context.mounted) {
          await ChecklistSheet.show(
            context,
            checklist,
            occurrenceDate: DateTime.now(),
          );
        }
      },
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(9),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
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
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textMain,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      height: 1.2,
                    ),
                    maxLines: 2,
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
}
