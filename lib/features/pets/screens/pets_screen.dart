import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/pet_model.dart';
import '../providers/pets_provider.dart';
import 'add_pet_screen.dart';
import 'pet_detail_screen.dart';

class PetsScreen extends ConsumerWidget {
  const PetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petsState = ref.watch(petsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Питомцы'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            color: AppColors.primary,
            onPressed: () => _openAddPet(context),
          ),
        ],
      ),
      body: petsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Ошибка: $e')),
        data: (pets) => pets.isEmpty
            ? _ZeroState(onAdd: () => _openAddPet(context))
            : _PetsList(pets: pets),
      ),
    );
  }

  void _openAddPet(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddPetScreen()),
    );
  }
}

// ── Нулевое состояние ────────────────────────────────────

class _ZeroState extends StatelessWidget {
  final VoidCallback onAdd;
  const _ZeroState({required this.onAdd});

  static const _sections = [
    ('Питание', 'Режим не настроен', Icons.restaurant_rounded),
    ('Режим дня', 'Не задан', Icons.wb_sunny_rounded),
    ('Что кушает', 'Не указано', Icons.set_meal_rounded),
    ('Возраст', 'Не указан', Icons.cake_rounded),
    ('Вес', 'Нет данных', Icons.monitor_weight_outlined),
    ('Идентификация', 'Клеймо: не указано · Чип: не указан', Icons.qr_code_rounded),
    ('Документы', 'Нет файлов', Icons.folder_rounded),
    ('Здоровье', 'Анамнез, прививки, препараты', Icons.favorite_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Пустая карточка
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                height: 140,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Icon(Icons.pets_rounded,
                      size: 64, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 16),
              Text('Имя питомца',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textSecondary,
                      )),
              const SizedBox(height: 4),
              const Text('Возраст · Вес',
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Добавить питомца'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Незаполненные секции
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: _sections.indexed.map((entry) {
              final (i, s) = entry;
              return Column(
                children: [
                  ListTile(
                    leading: Icon(s.$3,
                        color: AppColors.primary.withAlpha(120), size: 22),
                    title: Text(s.$1,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w500)),
                    subtitle: Text(s.$2,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary)),
                    trailing: const Icon(Icons.chevron_right_rounded,
                        color: AppColors.textSecondary),
                    onTap: onAdd,
                  ),
                  if (i < _sections.length - 1)
                    const Divider(height: 1, indent: 56),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ── Список питомцев ──────────────────────────────────────

class _PetsList extends ConsumerWidget {
  final List<PetModel> pets;
  const _PetsList({required this.pets});

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, PetModel p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить питомца?'),
        content: Text('${p.name} и все его данные будут удалены.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Удалить', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok == true && p.id != null) {
      await ref.read(petsProvider.notifier).deletePet(p.id!);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: pets.length,
      separatorBuilder: (_, i) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _SwipeToDelete(
        onDelete: () => _confirmDelete(context, ref, pets[i]),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => PetDetailScreen(pet: pets[i]))),
        child: _PetCard(pet: pets[i]),
      ),
    );
  }
}

// ── Свайп для удаления ───────────────────────────────────

class _SwipeToDelete extends StatefulWidget {
  final Widget child;
  final VoidCallback onDelete;
  final VoidCallback onTap;
  const _SwipeToDelete({required this.child, required this.onDelete, required this.onTap});

  @override
  State<_SwipeToDelete> createState() => _SwipeToDeleteState();
}

class _SwipeToDeleteState extends State<_SwipeToDelete>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  double _dragOffset = 0;
  static const _revealWidth = 88.0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _anim = _ctrl.drive(Tween<double>(begin: 0, end: -_revealWidth)
        .chain(CurveTween(curve: Curves.easeOutCubic)));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _open()  => _ctrl.forward();
  void _close() => _ctrl.reverse();

  void _onDragUpdate(DragUpdateDetails d) {
    _dragOffset = (_dragOffset + d.delta.dx).clamp(-_revealWidth, 0);
    _ctrl.value = -_dragOffset / _revealWidth;
  }

  void _onDragEnd(DragEndDetails d) {
    final velocity = d.primaryVelocity ?? 0;
    if (velocity < -300 || _dragOffset < -_revealWidth / 2) {
      _dragOffset = -_revealWidth;
      _open();
    } else {
      _dragOffset = 0;
      _close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) {
        final offset = _anim.value;
        // Reveal opacity tied to slide amount
        final reveal = (-offset / _revealWidth).clamp(0.0, 1.0);

        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Красная зона справа
              Positioned.fill(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Opacity(
                    opacity: reveal,
                    child: GestureDetector(
                      onTap: () {
                        _close();
                        _dragOffset = 0;
                        widget.onDelete();
                      },
                      child: Container(
                        width: _revealWidth,
                        color: AppColors.error,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.delete_rounded,
                                color: Colors.white,
                                size: 22 + 4 * reveal),
                            const SizedBox(height: 4),
                            const Text('Удалить',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Карточка
              GestureDetector(
                onHorizontalDragUpdate: _onDragUpdate,
                onHorizontalDragEnd: _onDragEnd,
                onTap: () {
                  if (_ctrl.value > 0) {
                    _close();
                    _dragOffset = 0;
                  } else {
                    widget.onTap();
                  }
                },
                child: Transform.translate(
                  offset: Offset(offset, 0),
                  child: child,
                ),
              ),
            ],
          ),
        );
      },
      child: widget.child,
    );
  }
}

class _PetCard extends StatelessWidget {
  final PetModel pet;
  const _PetCard({required this.pet});

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Фото
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(20)),
              child: pet.photoPath != null
                  ? Image.file(
                      File(pet.photoPath!),
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 100,
                      height: 100,
                      color: AppColors.primary.withAlpha(30),
                      child: const Center(
                        child: Text('🐾',
                            style: TextStyle(fontSize: 36)),
                      ),
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pet.name,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (pet.breed != null) pet.breed!,
                      if (pet.genderLabel.isNotEmpty) pet.genderLabel,
                    ].join(' · '),
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Text(pet.ageString,
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.chevron_right_rounded,
                  color: AppColors.textSecondary),
            ),
          ],
        ),
    );
  }
}
