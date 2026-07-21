import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../features/checklists/providers/checklists_provider.dart';
import '../../../models/checklist_model.dart';
import '../../../models/pet_model.dart';
import '../../home/widgets/checklist_sheet.dart';
import '../providers/pets_provider.dart';
import '../widgets/health_section.dart';
import '../widgets/pet_section_tile.dart';
import '../widgets/weight_history_sheet.dart';

class PetDetailScreen extends ConsumerWidget {
  final PetModel pet;
  const PetDetailScreen({super.key, required this.pet});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Следим за актуальной версией питомца из провайдера
    final pets = ref.watch(petsProvider).valueOrNull ?? [];
    final current = pets.firstWhere((p) => p.id == pet.id, orElse: () => pet);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Шапка с фото ──────────────────────────────
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
                onPressed: () => _editPetData(context, ref, current),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Фото или цветной фон
                  current.photoPath != null
                      ? Image.file(File(current.photoPath!), fit: BoxFit.cover)
                      : Container(
                          color: AppColors.primary,
                          child: const Center(
                            child: Text('🐾', style: TextStyle(fontSize: 80)),
                          ),
                        ),
                  // Градиент снизу
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black54],
                        stops: [0.5, 1.0],
                      ),
                    ),
                  ),
                  // Кнопка редактирования фото
                  Positioned(
                    right: 16,
                    bottom: 60,
                    child: GestureDetector(
                      onTap: () => _editPhoto(context, ref, current),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Colors.black38,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  // Имя и чипы
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          current.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            if (current.genderLabel.isNotEmpty)
                              _Chip(current.genderLabel),
                            _Chip(current.ageString),
                            if (current.breed != null &&
                                current.breed!.isNotEmpty)
                              _Chip(current.breed!),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Секции ────────────────────────────────────
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 8),

                // Питание
                PetSectionTile(
                  icon: Icons.restaurant_rounded,
                  title: 'Питание',
                  subtitle: current.foodType != null
                      ? current.foodType!
                      : 'Режим не настроен',
                  expandedContent: _FeedingContent(pet: current, ref: ref),
                ),

                // Режим дня
                PetSectionTile(
                  icon: Icons.wb_sunny_rounded,
                  title: 'Режим дня',
                  subtitle: _nearestRoutinePreview(current),
                  expandedContent: _DayRoutineContent(pet: current, ref: ref),
                ),

                // Чек-лист
                PetSectionTile(
                  icon: Icons.checklist_rounded,
                  title: 'Чек-лист',
                  subtitle: current.id == null
                      ? 'Сначала сохраните питомца'
                      : 'Ежедневный уход и повторения',
                  expandedContent: current.id != null
                      ? _ChecklistSettingsContent(pet: current)
                      : null,
                ),

                // Вес
                PetSectionTile(
                  icon: Icons.monitor_weight_outlined,
                  title: 'Вес',
                  subtitle: current.weight != null
                      ? '${current.weight} кг'
                      : 'Нет данных',
                  expandedContent: current.id != null
                      ? _WeightContent(
                          petId: current.id!,
                          currentWeight: current.weight,
                        )
                      : null,
                ),

                // Возраст
                PetSectionTile(
                  icon: Icons.cake_rounded,
                  title: 'Возраст',
                  subtitle: current.ageString,
                  expandedContent: current.dateOfBirth != null
                      ? Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            'Дата рождения: ${_formatDate(current.dateOfBirth!)}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        )
                      : null,
                ),

                // Идентификация
                PetSectionTile(
                  icon: Icons.qr_code_rounded,
                  title: 'Идентификация',
                  subtitle: [
                    if (current.tattooNumber != null)
                      'Клеймо: ${current.tattooNumber}',
                    if (current.chipNumber != null)
                      'Чип: ${current.chipNumber}',
                    if (current.tattooNumber == null &&
                        current.chipNumber == null)
                      'Клеймо и чип не указаны',
                  ].join(' · '),
                  expandedContent: _IdentificationContent(
                    pet: current,
                    ref: ref,
                  ),
                ),

                // Документы
                PetSectionTile(
                  icon: Icons.folder_rounded,
                  title: 'Документы',
                  subtitle: 'Нет файлов',
                  expandedContent: const Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Text(
                      'Загрузка документов — скоро',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ),

                // Здоровье
                PetSectionTile(
                  icon: Icons.favorite_rounded,
                  title: 'Здоровье',
                  subtitle: 'Анамнез, прививки, препараты',
                  expandedContent: current.id != null
                      ? HealthSection(petId: current.id!)
                      : null,
                ),

                const SizedBox(height: 32),

                // Удалить питомца
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                    onPressed: () => _confirmDelete(context, ref, current),
                    child: const Text('Удалить питомца'),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editPhoto(
    BuildContext context,
    WidgetRef ref,
    PetModel p,
  ) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (file != null) {
      await ref
          .read(petsProvider.notifier)
          .updatePet(p.copyWith(photoPath: file.path));
    }
  }

  Future<void> _editPetData(
    BuildContext context,
    WidgetRef ref,
    PetModel p,
  ) async {
    final nameCtrl = TextEditingController(text: p.name);
    final breedCtrl = TextEditingController(text: p.breed ?? '');
    final weightCtrl = TextEditingController(text: p.weight?.toString() ?? '');
    String? gender = p.gender;
    DateTime? dob = p.dateOfBirth == null
        ? null
        : DateTime.tryParse(p.dateOfBirth!);

    final saved = await showDialog<PetModel>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Данные питомца'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  maxLength: 24,
                  decoration: const InputDecoration(labelText: 'Кличка'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: breedCtrl,
                  maxLength: 40,
                  decoration: const InputDecoration(labelText: 'Порода'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: gender,
                  decoration: const InputDecoration(labelText: 'Пол'),
                  items: const [
                    DropdownMenuItem(value: 'male', child: Text('Мальчик')),
                    DropdownMenuItem(value: 'female', child: Text('Девочка')),
                  ],
                  onChanged: (value) => setState(() => gender = value),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: weightCtrl,
                  maxLength: 6,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Вес',
                    suffixText: 'кг',
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: ctx,
                      initialDate:
                          dob ??
                          DateTime.now().subtract(const Duration(days: 365)),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) setState(() => dob = date);
                  },
                  icon: const Icon(Icons.cake_outlined),
                  label: Text(
                    dob == null
                        ? 'Возраст / дата рождения'
                        : _formatDate(dob!.toIso8601String()),
                  ),
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
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                Navigator.pop(
                  ctx,
                  p.copyWith(
                    name: name,
                    breed: breedCtrl.text.trim().isEmpty
                        ? null
                        : breedCtrl.text.trim(),
                    gender: gender,
                    dateOfBirth: dob?.toIso8601String(),
                    weight: double.tryParse(
                      weightCtrl.text.replaceAll(',', '.'),
                    ),
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
      await ref.read(petsProvider.notifier).updatePet(saved);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    PetModel p,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить питомца?'),
        content: Text('${p.name} и все его данные будут удалены.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Удалить',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (ok == true && p.id != null) {
      await ref.read(petsProvider.notifier).deletePet(p.id!);
      if (context.mounted) Navigator.pop(context);
    }
  }

  String _formatDate(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }

  String _nearestRoutinePreview(PetModel pet) {
    final chunks = <String>[
      if (pet.walkTimes != null && pet.walkTimes!.trim().isNotEmpty)
        'Прогулка ${pet.walkTimes!.split(',').first.trim()}',
      if (pet.playTimes != null && pet.playTimes!.trim().isNotEmpty)
        'Игры ${pet.playTimes!.split(',').first.trim()}',
      if (pet.trainNotes != null && pet.trainNotes!.trim().isNotEmpty)
        'Тренировка',
    ];
    return chunks.isEmpty ? 'Не задан' : chunks.first;
  }
}

// ── Контент секций ──────────────────────────────────────

class _ChecklistSettingsContent extends ConsumerWidget {
  final PetModel pet;
  const _ChecklistSettingsContent({required this.pet});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petId = pet.id!;
    final checklists = (ref.watch(checklistsProvider).valueOrNull ?? [])
        .where((checklist) => checklist.petId == petId)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (checklists.isEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'У этого питомца пока нет чек-листов',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () => _createChecklist(context, ref, pet),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Создать чек-лист'),
              ),
            ],
          )
        else
          ...checklists.map(
            (checklist) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => ChecklistSheet.show(context, checklist),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              checklist.title,
                              style: const TextStyle(
                                color: AppColors.textMain,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${checklist.doneCount}/${checklist.totalCount} выполнено · ${_repeatLabel(checklist)}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: checklist.isPinned,
                        onChanged: (value) async {
                          final ok = await ref
                              .read(checklistsProvider.notifier)
                              .setPinned(checklist, value);
                          if (!ok && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Достигнут лимит: 10 быстрых действий',
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _createChecklist(context, ref, pet),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Новый'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: checklists.isEmpty
                    ? null
                    : () => ChecklistSheet.show(context, checklists.first),
                icon: const Icon(Icons.tune_rounded, size: 18),
                label: const Text('Открыть'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _createChecklist(
    BuildContext context,
    WidgetRef ref,
    PetModel pet,
  ) async {
    final existing = (ref.read(checklistsProvider).valueOrNull ?? [])
        .where((checklist) => checklist.petId == pet.id)
        .length;
    if (existing >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Можно закрепить до 10 чек-листов')),
      );
      return;
    }

    final checklist = ChecklistModel(
      petId: pet.id!,
      petName: pet.name,
      title: existing == 0 ? 'Уход за день' : 'Новый чек-лист',
      description: existing == 0 ? 'Ежедневные дела по уходу' : null,
      scheduledDate: ChecklistModel.dateKey(DateTime.now()),
      repeatWeekdays: existing == 0 ? const [1, 2, 3, 4, 5, 6, 7] : const [],
      durationType: existing == 0 ? 'forever' : 'single',
      items: existing == 0
          ? const [
              ChecklistItemModel(title: 'Покормили утром'),
              ChecklistItemModel(title: 'Погуляли'),
              ChecklistItemModel(title: 'Проверили воду'),
            ]
          : const [ChecklistItemModel(title: 'Новый пункт')],
    );
    await ref.read(checklistsProvider.notifier).addChecklist(checklist);
    final created = (ref.read(checklistsProvider).valueOrNull ?? [])
        .where((item) => item.petId == pet.id)
        .last;
    if (context.mounted) {
      await ChecklistSheet.show(context, created);
    }
  }

  String _repeatLabel(ChecklistModel checklist) {
    if (checklist.repeatWeekdays.length == 7) return 'ежедневно';
    if (checklist.repeatWeekdays.isEmpty) {
      return _formatDate(checklist.scheduledDate);
    }
    const names = ['пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс'];
    return checklist.repeatWeekdays.map((day) => names[day - 1]).join(', ');
  }

  String _formatDate(String value) {
    final date = DateTime.tryParse(value);
    if (date == null) return value;
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}

class _FeedingContent extends StatefulWidget {
  final PetModel pet;
  final WidgetRef ref;
  const _FeedingContent({required this.pet, required this.ref});

  @override
  State<_FeedingContent> createState() => _FeedingContentState();
}

class _FeedingContentState extends State<_FeedingContent> {
  late TextEditingController _brandCtrl;
  late TextEditingController _commentCtrl;
  String? _foodType;

  static const _foodTypes = [
    'Сухой корм',
    'Влажный корм',
    'Натуральное',
    'Смешанное',
  ];

  @override
  void initState() {
    super.initState();
    _foodType = widget.pet.foodType;
    _brandCtrl = TextEditingController(text: widget.pet.foodBrand ?? '');
    _commentCtrl = TextEditingController(text: widget.pet.feedingComment ?? '');
  }

  @override
  void dispose() {
    _brandCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  void _save() {
    widget.ref
        .read(petsProvider.notifier)
        .updatePet(
          widget.pet.copyWith(
            foodType: _foodType,
            foodBrand: _brandCtrl.text.trim().isEmpty
                ? null
                : _brandCtrl.text.trim(),
            feedingComment: _commentCtrl.text.trim().isEmpty
                ? null
                : _commentCtrl.text.trim(),
          ),
        );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Сохранено')));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: _foodType,
          hint: const Text('Тип питания'),
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: _foodTypes
              .map((t) => DropdownMenuItem(value: t, child: Text(t)))
              .toList(),
          onChanged: (v) => setState(() => _foodType = v),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _brandCtrl,
          maxLength: 40,
          decoration: const InputDecoration(hintText: 'Марка корма'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _commentCtrl,
          maxLength: 160,
          decoration: const InputDecoration(hintText: 'Комментарий'),
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          style: ElevatedButton.styleFrom(minimumSize: const Size(120, 40)),
          onPressed: _save,
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}

class _DayRoutineContent extends StatefulWidget {
  final PetModel pet;
  final WidgetRef ref;
  const _DayRoutineContent({required this.pet, required this.ref});

  @override
  State<_DayRoutineContent> createState() => _DayRoutineContentState();
}

class _DayRoutineContentState extends State<_DayRoutineContent> {
  late TextEditingController _walkCtrl;
  late TextEditingController _playCtrl;
  late TextEditingController _trainCtrl;

  @override
  void initState() {
    super.initState();
    _walkCtrl = TextEditingController(text: widget.pet.walkTimes ?? '');
    _playCtrl = TextEditingController(text: widget.pet.playTimes ?? '');
    _trainCtrl = TextEditingController(text: widget.pet.trainNotes ?? '');
  }

  @override
  void dispose() {
    _walkCtrl.dispose();
    _playCtrl.dispose();
    _trainCtrl.dispose();
    super.dispose();
  }

  void _save() {
    widget.ref
        .read(petsProvider.notifier)
        .updatePet(
          widget.pet.copyWith(
            walkTimes: _walkCtrl.text.trim().isEmpty
                ? null
                : _walkCtrl.text.trim(),
            playTimes: _playCtrl.text.trim().isEmpty
                ? null
                : _playCtrl.text.trim(),
            trainNotes: _trainCtrl.text.trim().isEmpty
                ? null
                : _trainCtrl.text.trim(),
          ),
        );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Сохранено')));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _walkCtrl,
          maxLength: 80,
          decoration: const InputDecoration(
            hintText: 'Время прогулок (напр. 8:00, 13:00, 19:00)',
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _playCtrl,
          maxLength: 80,
          decoration: const InputDecoration(
            hintText: 'Игры (напр. 11:00 мяч, 21:00 поиск)',
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _trainCtrl,
          maxLength: 160,
          decoration: const InputDecoration(hintText: 'Тренировки / игры'),
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          style: ElevatedButton.styleFrom(minimumSize: const Size(120, 40)),
          onPressed: _save,
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}

class _WeightContent extends ConsumerWidget {
  final int petId;
  final double? currentWeight;
  const _WeightContent({required this.petId, this.currentWeight});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(weightRecordsProvider(petId)).valueOrNull ?? [];
    final latestWeight = records.isNotEmpty
        ? records.first.weight
        : currentWeight;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (latestWeight != null)
          Text(
            'Последний вес: $latestWeight кг',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.history_rounded, size: 18),
          label: const Text('История взвешиваний'),
          onPressed: () => WeightHistorySheet.show(context, petId),
        ),
      ],
    );
  }
}

class _IdentificationContent extends StatefulWidget {
  final PetModel pet;
  final WidgetRef ref;
  const _IdentificationContent({required this.pet, required this.ref});

  @override
  State<_IdentificationContent> createState() => _IdentificationContentState();
}

class _IdentificationContentState extends State<_IdentificationContent> {
  late TextEditingController _chipCtrl;
  late TextEditingController _tattooCtrl;

  @override
  void initState() {
    super.initState();
    _chipCtrl = TextEditingController(text: widget.pet.chipNumber ?? '');
    _tattooCtrl = TextEditingController(text: widget.pet.tattooNumber ?? '');
  }

  @override
  void dispose() {
    _chipCtrl.dispose();
    _tattooCtrl.dispose();
    super.dispose();
  }

  void _save() {
    widget.ref
        .read(petsProvider.notifier)
        .updatePet(
          widget.pet.copyWith(
            chipNumber: _chipCtrl.text.trim().isEmpty
                ? null
                : _chipCtrl.text.trim(),
            tattooNumber: _tattooCtrl.text.trim().isEmpty
                ? null
                : _tattooCtrl.text.trim(),
          ),
        );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Сохранено')));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _tattooCtrl,
          maxLength: 32,
          decoration: const InputDecoration(hintText: 'Номер клейма'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _chipCtrl,
          maxLength: 32,
          decoration: const InputDecoration(hintText: 'Номер чипа'),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          style: ElevatedButton.styleFrom(minimumSize: const Size(120, 40)),
          onPressed: _save,
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}
