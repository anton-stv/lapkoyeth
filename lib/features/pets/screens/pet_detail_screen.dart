import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/pet_model.dart';
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
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
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
                            child: Text('🐾',
                                style: TextStyle(fontSize: 80)),
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
                        child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
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
                            if (current.breed != null && current.breed!.isNotEmpty)
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
                  subtitle: current.walkTimes != null
                      ? 'Прогулки настроены'
                      : 'Не задан',
                  expandedContent: _DayRoutineContent(pet: current, ref: ref),
                ),

                // Вес
                PetSectionTile(
                  icon: Icons.monitor_weight_outlined,
                  title: 'Вес',
                  subtitle: current.weight != null
                      ? '${current.weight} кг'
                      : 'Нет данных',
                  expandedContent: current.id != null
                      ? _WeightContent(petId: current.id!, currentWeight: current.weight)
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
                            style: const TextStyle(color: AppColors.textSecondary),
                          ),
                        )
                      : null,
                ),

                // Идентификация
                PetSectionTile(
                  icon: Icons.qr_code_rounded,
                  title: 'Идентификация',
                  subtitle: [
                    if (current.tattooNumber != null) 'Клеймо: ${current.tattooNumber}',
                    if (current.chipNumber != null) 'Чип: ${current.chipNumber}',
                    if (current.tattooNumber == null && current.chipNumber == null)
                      'Клеймо и чип не указаны',
                  ].join(' · '),
                  expandedContent: _IdentificationContent(pet: current, ref: ref),
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

  Future<void> _editPhoto(BuildContext context, WidgetRef ref, PetModel p) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file != null) {
      await ref.read(petsProvider.notifier).updatePet(p.copyWith(photoPath: file.path));
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, PetModel p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить питомца?'),
        content: Text('${p.name} и все его данные будут удалены.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Отмена')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Удалить',
                style: TextStyle(color: AppColors.error)),
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
}

// ── Контент секций ──────────────────────────────────────

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

  static const _foodTypes = ['Сухой корм', 'Влажный корм', 'Натуральное', 'Смешанное'];

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
    widget.ref.read(petsProvider.notifier).updatePet(
          widget.pet.copyWith(
            foodType: _foodType,
            foodBrand: _brandCtrl.text.trim().isEmpty ? null : _brandCtrl.text.trim(),
            feedingComment: _commentCtrl.text.trim().isEmpty ? null : _commentCtrl.text.trim(),
          ),
        );
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Сохранено')));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: _foodType,
          hint: const Text('Тип питания'),
          decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
          items: _foodTypes
              .map((t) => DropdownMenuItem(value: t, child: Text(t)))
              .toList(),
          onChanged: (v) => setState(() => _foodType = v),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _brandCtrl,
          decoration: const InputDecoration(hintText: 'Марка корма'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _commentCtrl,
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
  late TextEditingController _trainCtrl;

  @override
  void initState() {
    super.initState();
    _walkCtrl = TextEditingController(text: widget.pet.walkTimes ?? '');
    _trainCtrl = TextEditingController(text: widget.pet.trainNotes ?? '');
  }

  @override
  void dispose() {
    _walkCtrl.dispose();
    _trainCtrl.dispose();
    super.dispose();
  }

  void _save() {
    widget.ref.read(petsProvider.notifier).updatePet(
          widget.pet.copyWith(
            walkTimes: _walkCtrl.text.trim().isEmpty ? null : _walkCtrl.text.trim(),
            trainNotes: _trainCtrl.text.trim().isEmpty ? null : _trainCtrl.text.trim(),
          ),
        );
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Сохранено')));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _walkCtrl,
          decoration: const InputDecoration(
              hintText: 'Время прогулок (напр. 8:00, 13:00, 19:00)'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _trainCtrl,
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

class _WeightContent extends StatelessWidget {
  final int petId;
  final double? currentWeight;
  const _WeightContent({required this.petId, this.currentWeight});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (currentWeight != null)
          Text('Текущий вес: $currentWeight кг',
              style: const TextStyle(color: AppColors.textSecondary)),
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
    widget.ref.read(petsProvider.notifier).updatePet(
          widget.pet.copyWith(
            chipNumber: _chipCtrl.text.trim().isEmpty ? null : _chipCtrl.text.trim(),
            tattooNumber: _tattooCtrl.text.trim().isEmpty ? null : _tattooCtrl.text.trim(),
          ),
        );
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Сохранено')));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _tattooCtrl,
          decoration: const InputDecoration(hintText: 'Номер клейма'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _chipCtrl,
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
      child: Text(label,
          style: const TextStyle(color: Colors.white, fontSize: 12)),
    );
  }
}
