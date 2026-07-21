import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/pets/providers/pets_provider.dart';
import '../../../models/user_model.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late TextEditingController _firstNameCtrl;
  late TextEditingController _lastNameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _bioCtrl;
  String? _gender;
  bool _saving = false;
  bool _edited = false;
  bool _helpExpanded = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authStateProvider).valueOrNull;
    _firstNameCtrl = TextEditingController(text: user?.firstName ?? '');
    _lastNameCtrl = TextEditingController(text: user?.lastName ?? '');
    _emailCtrl = TextEditingController(text: user?.email ?? '');
    _phoneCtrl = TextEditingController(text: user?.phone ?? '');
    _cityCtrl = TextEditingController(text: user?.city ?? '');
    _bioCtrl = TextEditingController(text: user?.bio ?? '');
    _gender = user?.gender;
    for (final c in [
      _firstNameCtrl,
      _lastNameCtrl,
      _emailCtrl,
      _phoneCtrl,
      _cityCtrl,
      _bioCtrl,
    ]) {
      c.addListener(() => setState(() => _edited = true));
    }
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showSnack('Введите корректную почту', isError: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(authStateProvider.notifier)
          .updateUser(
            user.copyWith(
              firstName: _firstNameCtrl.text.trim(),
              lastName: _lastNameCtrl.text.trim(),
              email: email,
              phone: _emptyToNull(_phoneCtrl.text),
              city: _emptyToNull(_cityCtrl.text),
              bio: _emptyToNull(_bioCtrl.text),
              gender: _gender,
            ),
          );
      if (mounted) {
        setState(() => _edited = false);
        _showSnack('Профиль обновлён');
      }
    } catch (e) {
      if (mounted) {
        _showSnack('$e'.replaceFirst('Exception: ', ''), isError: true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String _profileId(int? id) => 'LP-${(id ?? 0).toString().padLeft(6, '0')}';

  void _showSnack(String text, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: isError ? AppColors.error : null,
      ),
    );
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 88,
    );
    if (file == null) return;

    final size = await File(file.path).length();
    if (size > 50 * 1024 * 1024) {
      _showSnack('Фото должно быть не больше 50 МБ', isError: true);
      return;
    }

    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    await ref
        .read(authStateProvider.notifier)
        .updateUser(user.copyWith(photoPath: file.path));
  }

  void _openPhoto(String path) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black,
      builder: (ctx) => GestureDetector(
        onTap: () => Navigator.pop(ctx),
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.file(File(path), fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  void _showChangePassword() {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscureOld = true;
    bool obscureNew = true;
    bool changing = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: _SheetFrame(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SheetHandle(),
                const SizedBox(height: 20),
                const Text(
                  'Смена пароля',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 20),
                _pwField(
                  oldCtrl,
                  'Текущий пароль',
                  obscureOld,
                  () => setS(() => obscureOld = !obscureOld),
                ),
                const SizedBox(height: 12),
                _pwField(
                  newCtrl,
                  'Новый пароль',
                  obscureNew,
                  () => setS(() => obscureNew = !obscureNew),
                ),
                const SizedBox(height: 12),
                _pwField(
                  confirmCtrl,
                  'Повторите новый пароль',
                  obscureNew,
                  () => setS(() => obscureNew = !obscureNew),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: changing
                        ? null
                        : () async {
                            if (newCtrl.text != confirmCtrl.text) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                  content: Text('Пароли не совпадают'),
                                ),
                              );
                              return;
                            }
                            setS(() => changing = true);
                            try {
                              await ref
                                  .read(authStateProvider.notifier)
                                  .changePassword(
                                    currentPassword: oldCtrl.text,
                                    newPassword: newCtrl.text,
                                  );
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (mounted) _showSnack('Пароль изменён');
                            } catch (e) {
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '$e'.replaceFirst('Exception: ', ''),
                                    ),
                                  ),
                                );
                              }
                            } finally {
                              if (ctx.mounted) setS(() => changing = false);
                            }
                          },
                    child: changing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Изменить пароль'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pwField(
    TextEditingController c,
    String hint,
    bool obscure,
    VoidCallback toggle,
  ) => TextField(
    controller: c,
    obscureText: obscure,
    decoration: InputDecoration(
      hintText: hint,
      suffixIcon: IconButton(
        icon: Icon(
          obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          size: 20,
          color: AppColors.textSecondary,
        ),
        onPressed: toggle,
      ),
    ),
  );

  Future<void> _confirmDeleteAccount() async {
    final wantsDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить аккаунт?'),
        content: const Text(
          'Если ваше решение связано с функциональностью приложения, напишите нам: help@lapkoyeth.app. Действие нельзя отменить. Ваш аккаунт будет удален и все данные стерты.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (wantsDelete != true) return;

    final typed = await _askDeleteWord();
    if (typed != true) return;

    await ref.read(authStateProvider.notifier).deleteAccount();
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Аккаунт удален'),
        content: const Text(
          'Нам очень жаль, но ваш аккаунт удален. Однако можете зарегистрироваться снова.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/login');
            },
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/register');
            },
            child: const Text('Регистрация'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _askDeleteWord() {
    final ctrl = TextEditingController();
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Подтверждение'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Введите слово “удалить” и нажмите OK'),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'удалить'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(ctx, ctrl.text.trim().toLowerCase() == 'удалить'),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final pets = ref.watch(petsProvider).valueOrNull ?? [];
    if (user == null) return const SizedBox.shrink();

    final initials = [
      if (user.firstName.isNotEmpty) user.firstName[0],
      if (user.lastName.isNotEmpty) user.lastName[0],
    ].join().toUpperCase();
    final photoExists =
        user.photoPath != null && File(user.photoPath!).existsSync();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 236,
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
              if (_edited)
                TextButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Сохранить',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF7FA890), AppColors.primary],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 38),
                      GestureDetector(
                        onTap: photoExists
                            ? () => _openPhoto(user.photoPath!)
                            : _pickPhoto,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            CircleAvatar(
                              radius: 44,
                              backgroundColor: Colors.white.withAlpha(35),
                              backgroundImage: photoExists
                                  ? FileImage(File(user.photoPath!))
                                  : null,
                              child: photoExists
                                  ? null
                                  : initials.isEmpty
                                  ? const Icon(
                                      Icons.person_rounded,
                                      color: Colors.white,
                                      size: 42,
                                    )
                                  : Text(
                                      initials,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                            Positioned(
                              right: -2,
                              bottom: -2,
                              child: IconButton.filled(
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppColors.primary,
                                  minimumSize: const Size(34, 34),
                                ),
                                onPressed: _pickPhoto,
                                icon: const Icon(
                                  Icons.photo_camera_outlined,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${user.firstName} ${user.lastName}'.trim(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_profileId(user.id)} · ${user.email}',
                        style: TextStyle(
                          color: Colors.white.withAlpha(185),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Личные данные'),
                  const SizedBox(height: 8),
                  _SectionCard(
                    children: [
                      _StaticInfoRow(
                        icon: Icons.tag_rounded,
                        label: 'ID профиля',
                        value: _profileId(user.id),
                      ),
                      const _Divider(),
                      _InfoRow(
                        icon: Icons.person_outline_rounded,
                        label: 'Имя',
                        controller: _firstNameCtrl,
                      ),
                      const _Divider(),
                      _InfoRow(
                        icon: Icons.badge_outlined,
                        label: 'Фамилия',
                        controller: _lastNameCtrl,
                      ),
                      const _Divider(),
                      _InfoRow(
                        icon: Icons.mail_outline_rounded,
                        label: 'Почта',
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const _Divider(),
                      _InfoRow(
                        icon: Icons.phone_outlined,
                        label: 'Телефон',
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                      ),
                      const _Divider(),
                      _InfoRow(
                        icon: Icons.location_city_outlined,
                        label: 'Город',
                        controller: _cityCtrl,
                      ),
                      const _Divider(),
                      _InfoRow(
                        icon: Icons.notes_outlined,
                        label: 'О себе',
                        controller: _bioCtrl,
                        maxLines: 3,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _sectionTitle('Пол'),
                  const SizedBox(height: 8),
                  _SectionCard(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            _GenderOption(
                              label: 'Мужской',
                              icon: Icons.male_rounded,
                              selected: _gender == 'male',
                              onTap: () => setState(() {
                                _gender = 'male';
                                _edited = true;
                              }),
                            ),
                            const SizedBox(width: 10),
                            _GenderOption(
                              label: 'Женский',
                              icon: Icons.female_rounded,
                              selected: _gender == 'female',
                              onTap: () => setState(() {
                                _gender = 'female';
                                _edited = true;
                              }),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _sectionTitle('Статистика'),
                  const SizedBox(height: 8),
                  _SectionCard(
                    children: [
                      _StaticInfoRow(
                        icon: Icons.pets_outlined,
                        label: 'Животных',
                        value: '${pets.length}',
                      ),
                      const _Divider(),
                      _StaticInfoRow(
                        icon: Icons.fact_check_outlined,
                        label: 'Заполненность профиля',
                        value: '${_profileCompleteness(user)}%',
                      ),
                      const _Divider(),
                      const _StaticInfoRow(
                        icon: Icons.visibility_outlined,
                        label: 'Просмотры и подписчики',
                        value: 'В разработке',
                        muted: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _sectionTitle('Безопасность'),
                  const SizedBox(height: 8),
                  _SectionCard(
                    children: [
                      _ActionTile(
                        icon: Icons.lock_outline_rounded,
                        title: 'Сменить пароль',
                        onTap: _showChangePassword,
                      ),
                      const _Divider(),
                      _ActionTile(
                        icon: Icons.delete_outline_rounded,
                        title: 'Удалить аккаунт',
                        danger: true,
                        onTap: _confirmDeleteAccount,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _sectionTitle('Оплата'),
                  const SizedBox(height: 8),
                  const _SectionCard(
                    children: [
                      _StaticInfoRow(
                        icon: Icons.credit_card_outlined,
                        label: 'Способы оплаты',
                        value: 'В разработке',
                        muted: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _sectionTitle('Помощь'),
                  const SizedBox(height: 8),
                  _SectionCard(
                    children: [
                      _ActionTile(
                        icon: Icons.help_outline_rounded,
                        title: 'Поддержка',
                        trailing: Icon(
                          _helpExpanded
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                          color: AppColors.textSecondary,
                        ),
                        onTap: () =>
                            setState(() => _helpExpanded = !_helpExpanded),
                      ),
                      if (_helpExpanded) const _HelpContent(),
                    ],
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text('Выйти из аккаунта'),
                      onPressed: () =>
                          ref.read(authStateProvider.notifier).logout(),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _profileCompleteness(UserModel user) {
    final values = [
      user.firstName,
      user.lastName,
      user.email,
      user.phone,
      user.city,
      user.gender,
      user.photoPath,
      user.bio,
    ];
    final filled = values.where((v) => v != null && v.trim().isNotEmpty).length;
    return (filled / values.length * 100).round();
  }

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(left: 4),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      ),
    ),
  );
}

class _SheetFrame extends StatelessWidget {
  final Widget child;
  const _SheetFrame({required this.child});

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color: AppColors.background,
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
    child: child,
  );
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: const Color(0xFFDDD8D2),
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withAlpha(8),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(children: children),
  );
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, indent: 56, endIndent: 0);
}

class _StaticInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool muted;

  const _StaticInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(
      children: [
        _RowIcon(icon: icon),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  color: muted ? AppColors.textSecondary : AppColors.textMain,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final int maxLines;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.controller,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: Row(
      crossAxisAlignment: maxLines > 1
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Padding(
          padding: EdgeInsets.only(top: maxLines > 1 ? 12 : 0),
          child: _RowIcon(icon: icon),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              TextField(
                controller: controller,
                keyboardType: keyboardType,
                maxLines: maxLines,
                style: const TextStyle(fontSize: 15),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 4),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final bool danger;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailing,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.error : AppColors.primary;
    return ListTile(
      leading: _RowIcon(icon: icon, color: color),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          color: danger ? color : AppColors.textMain,
        ),
      ),
      trailing:
          trailing ??
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textSecondary,
          ),
      onTap: onTap,
    );
  }
}

class _RowIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _RowIcon({required this.icon, this.color = AppColors.primary});

  @override
  Widget build(BuildContext context) => Container(
    width: 34,
    height: 34,
    decoration: BoxDecoration(
      color: color.withAlpha(25),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Icon(icon, color: color, size: 18),
  );
}

class _GenderOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _GenderOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : const Color(0xFFE0D9D2),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? Colors.white : AppColors.textMain,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                color: selected ? Colors.white : AppColors.textMain,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _HelpContent extends StatelessWidget {
  const _HelpContent();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Divider(),
        SizedBox(height: 14),
        Text(
          'help@lapkoyeth.app',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 8),
        Text(
          'Рады приветствовать вас в нашем приложении. Это бесплатное приложение, позволяющее вам находиться в гармонии со своими любимцами. Можете задать вопрос или оставить обратную связь. Мы обязательно ответим на ваш запрос так быстро, как сможем. С заботой и вас и ваших питомцах!',
          style: TextStyle(
            fontSize: 14,
            height: 1.35,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    ),
  );
}
