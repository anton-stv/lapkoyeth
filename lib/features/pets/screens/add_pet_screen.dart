import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../models/pet_model.dart';
import '../providers/pets_provider.dart';

const _breeds = [
  // Собаки
  'Лабрадор-ретривер', 'Немецкая овчарка', 'Золотистый ретривер',
  'Французский бульдог', 'Бульдог', 'Пудель', 'Бигль', 'Ротвейлер',
  'Йоркширский терьер', 'Боксёр', 'Хаски', 'Мопс', 'Чихуахуа', 'Шпиц',
  'Такса', 'Далматин', 'Бордер-колли', 'Самоед', 'Маламут', 'Корги',
  'Доберман', 'Коккер-спаниель', 'Джек-рассел терьер', 'Шнауцер',
  'Мальтезе', 'Сенбернар', 'Акита', 'Сиба-ину', 'Великий датчанин',
  'Ирландский сеттер', 'Шотландская овчарка', 'Аргентинский дог',
  'Кавказская овчарка', 'Среднеазиатская овчарка', 'Московская сторожевая',
  // Кошки
  'Британская короткошёрстная', 'Шотландская вислоухая', 'Мейн-кун',
  'Персидская', 'Сфинкс', 'Сиамская', 'Бенгальская', 'Рагдолл',
  'Норвежская лесная', 'Абиссинская', 'Бурманская', 'Тайская',
  'Русская голубая', 'Турецкая ангора', 'Девон-рекс', 'Корниш-рекс',
  'Мэнкс', 'Бирманская', 'Курильский бобтейл', 'Сибирская',
  // Другие
  'Беспородный', 'Метис', 'Смешанная порода',
];

class AddPetScreen extends ConsumerStatefulWidget {
  const AddPetScreen({super.key});

  @override
  ConsumerState<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends ConsumerState<AddPetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  String? _breed;
  String? _gender;
  DateTime? _dob;
  String? _photoPath;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file != null) setState(() => _photoPath = file.path);
  }

  Future<void> _pickDob() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365)),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('ru'),
    );
    if (date != null) setState(() => _dob = date);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    final pet = PetModel(
      ownerId: user.id!,
      name: _nameCtrl.text.trim(),
      breed: _breed,
      gender: _gender,
      dateOfBirth: _dob?.toIso8601String(),
      weight: double.tryParse(_weightCtrl.text.replaceAll(',', '.')),
      photoPath: _photoPath,
    );

    await ref.read(petsProvider.notifier).addPet(pet);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Добавить питомца'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Фото
            Center(
              child: GestureDetector(
                onTap: _pickPhoto,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(30),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary.withAlpha(80), width: 2),
                    image: _photoPath != null
                        ? DecorationImage(
                            image: FileImage(File(_photoPath!)),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _photoPath == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_rounded,
                                color: AppColors.primary, size: 28),
                            SizedBox(height: 4),
                            Text('Фото',
                                style: TextStyle(
                                    fontSize: 12, color: AppColors.primary)),
                          ],
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Имя
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(hintText: 'Кличка *'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Введите кличку' : null,
            ),
            const SizedBox(height: 14),

            // Порода — поиск по списку
            _BreedField(
              selected: _breed,
              onSelected: (v) => setState(() => _breed = v),
            ),
            const SizedBox(height: 14),

            // Пол
            _SectionLabel('Пол'),
            const SizedBox(height: 8),
            Row(
              children: [
                _GenderChip(
                  label: 'Мальчик',
                  emoji: '♂️',
                  selected: _gender == 'male',
                  onTap: () => setState(() => _gender = 'male'),
                ),
                const SizedBox(width: 10),
                _GenderChip(
                  label: 'Девочка',
                  emoji: '♀️',
                  selected: _gender == 'female',
                  onTap: () => setState(() => _gender = 'female'),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Дата рождения
            _SectionLabel('Дата рождения'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDob,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE0D9D2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 10),
                    Text(
                      _dob != null
                          ? '${_dob!.day.toString().padLeft(2, '0')}.${_dob!.month.toString().padLeft(2, '0')}.${_dob!.year}'
                          : 'Выберите дату',
                      style: TextStyle(
                        color: _dob != null
                            ? AppColors.textMain
                            : AppColors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Вес
            TextFormField(
              controller: _weightCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                hintText: 'Вес',
                suffixText: 'кг',
              ),
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Поле выбора породы ────────────────────────────────────

class _BreedField extends StatefulWidget {
  final String? selected;
  final ValueChanged<String?> onSelected;
  const _BreedField({required this.selected, required this.onSelected});

  @override
  State<_BreedField> createState() => _BreedFieldState();
}

class _BreedFieldState extends State<_BreedField> {
  final _ctrl = TextEditingController();
  final _focusNode = FocusNode();
  List<String> _filtered = [];
  bool _showList = false;
  String? _localSelected;

  @override
  void initState() {
    super.initState();
    if (widget.selected != null) _ctrl.text = widget.selected!;
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        final lower = _ctrl.text.toLowerCase();
        setState(() {
          _filtered = lower.isEmpty
              ? List.of(_breeds)
              : _breeds.where((b) => b.toLowerCase().contains(lower)).toList();
          _showList = _filtered.isNotEmpty;
        });
      } else {
        final effective = _localSelected ?? widget.selected;
        if (_ctrl.text != effective) {
          _ctrl.text = effective ?? '';
        }
        setState(() => _showList = false);
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String q) {
    final lower = q.toLowerCase();
    setState(() {
      _filtered = lower.isEmpty
          ? List.of(_breeds)
          : _breeds.where((b) => b.toLowerCase().contains(lower)).toList();
      _showList = _filtered.isNotEmpty;
    });
  }

  void _select(String breed) {
    _localSelected = breed;
    _ctrl.text = breed;
    _focusNode.unfocus();
    widget.onSelected(breed);
    setState(() => _showList = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _ctrl,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: 'Порода',
            suffixIcon: widget.selected != null
                ? IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      _ctrl.clear();
                      widget.onSelected(null);
                      setState(() => _showList = false);
                    },
                  )
                : null,
          ),
          onChanged: _onChanged,
        ),
        if (_showList)
          Container(
            margin: const EdgeInsets.only(top: 2),
            constraints: const BoxConstraints(maxHeight: 220),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0D9D2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: _filtered.length,
              itemBuilder: (_, i) => InkWell(
                onTap: () => _select(_filtered[i]),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Text(_filtered[i], style: const TextStyle(fontSize: 15)),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Вспомогательные виджеты ───────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
      );
}

class _GenderChip extends StatelessWidget {
  final String label;
  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  const _GenderChip({
    required this.label,
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withAlpha(30) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : const Color(0xFFE0D9D2),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.primary : AppColors.textMain,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
