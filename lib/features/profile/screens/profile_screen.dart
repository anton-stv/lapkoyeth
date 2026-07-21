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

  Future<bool> _save() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return false;
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showSnack('Введите корректную почту', isError: true);
      return false;
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
        _showSnack('Профиль обновлён');
      }
      return true;
    } catch (e) {
      if (mounted) {
        _showSnack('$e'.replaceFirst('Exception: ', ''), isError: true);
      }
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String _profileId(int? id) => 'LP-${(id ?? 0).toString().padLeft(6, '0')}';

  String _displayName(UserModel user) {
    final name = '${user.firstName} ${user.lastName}'.trim();
    return name.isEmpty ? 'Профиль питомца' : name;
  }

  String _initials(UserModel user) {
    final value = [
      if (user.firstName.isNotEmpty) user.firstName[0],
      if (user.lastName.isNotEmpty) user.lastName[0],
    ].join().toUpperCase();
    return value;
  }

  void _resetEditors(UserModel user) {
    _firstNameCtrl.text = user.firstName;
    _lastNameCtrl.text = user.lastName;
    _emailCtrl.text = user.email;
    _phoneCtrl.text = user.phone ?? '';
    _cityCtrl.text = user.city ?? '';
    _bioCtrl.text = user.bio ?? '';
    _gender = user.gender;
  }

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

  void _showEditProfile(UserModel user) {
    _resetEditors(user);

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
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SheetHandle(),
                  const SizedBox(height: 20),
                  const Text(
                    'Редактировать профиль',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 18),
                  _EditField(controller: _firstNameCtrl, label: 'Имя'),
                  const SizedBox(height: 12),
                  _EditField(controller: _lastNameCtrl, label: 'Фамилия'),
                  const SizedBox(height: 12),
                  _EditField(
                    controller: _emailCtrl,
                    label: 'Почта',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  _EditField(
                    controller: _phoneCtrl,
                    label: 'Телефон',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  _EditField(controller: _cityCtrl, label: 'Город'),
                  const SizedBox(height: 12),
                  _EditField(
                    controller: _bioCtrl,
                    label: 'О себе',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _GenderOption(
                        label: 'Мужской',
                        icon: Icons.male_rounded,
                        selected: _gender == 'male',
                        onTap: () => setS(() {
                          setState(() {
                            _gender = 'male';
                          });
                        }),
                      ),
                      const SizedBox(width: 10),
                      _GenderOption(
                        label: 'Женский',
                        icon: Icons.female_rounded,
                        selected: _gender == 'female',
                        onTap: () => setS(() {
                          setState(() {
                            _gender = 'female';
                          });
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _saving
                              ? null
                              : () {
                                  setState(() => _resetEditors(user));
                                  Navigator.pop(ctx);
                                },
                          child: const Text('Выйти без изменений'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saving
                              ? null
                              : () async {
                                  final saved = await _save();
                                  if (saved && ctx.mounted) {
                                    Navigator.pop(ctx);
                                  }
                                },
                          child: _saving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Сохранить'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

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

    final photoExists =
        user.photoPath != null && File(user.photoPath!).existsSync();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Профиль',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.textMain,
                    minimumSize: const Size(44, 44),
                  ),
                  onPressed: () => _showEditProfile(user),
                  icon: const Icon(Icons.settings_outlined, size: 22),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _ProfileSummaryCard(
              name: _displayName(user),
              profileId: _profileId(user.id),
              email: user.email,
              bio: user.bio,
              initials: _initials(user),
              photoPath: photoExists ? user.photoPath : null,
              onPhotoTap: photoExists
                  ? () => _openPhoto(user.photoPath!)
                  : _pickPhoto,
              onPhotoEdit: _pickPhoto,
              onEdit: () => _showEditProfile(user),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _StatPill(
                  icon: Icons.pets_outlined,
                  label: 'Животных',
                  value: '${pets.length}',
                ),
                const SizedBox(width: 10),
                _StatPill(
                  icon: Icons.login_rounded,
                  label: 'Заходы',
                  value: '1',
                ),
                const SizedBox(width: 10),
                _StatPill(
                  icon: Icons.fact_check_outlined,
                  label: 'Анкета',
                  value: '${_profileCompleteness(user)}%',
                ),
              ],
            ),
            const SizedBox(height: 20),
            _SectionCard(
              children: [
                _ActionTile(
                  icon: Icons.person_outline_rounded,
                  title: 'Личная информация',
                  subtitle: '${_profileId(user.id)} · ${user.email}',
                  onTap: () => _showEditProfile(user),
                ),
                const _Divider(),
                _ActionTile(
                  icon: Icons.lock_outline_rounded,
                  title: 'Безопасность',
                  subtitle: 'Сменить пароль',
                  onTap: _showChangePassword,
                ),
                const _Divider(),
                _ActionTile(
                  icon: Icons.notifications_none_rounded,
                  title: 'Уведомления',
                  subtitle: 'В разработке',
                  muted: true,
                  onTap: () => _showSnack('Уведомления пока в разработке'),
                ),
                const _Divider(),
                _ActionTile(
                  icon: Icons.credit_card_outlined,
                  title: 'Способы оплаты',
                  subtitle: 'В разработке',
                  muted: true,
                  onTap: () => _showSnack('Способы оплаты пока в разработке'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _sectionTitle('Достижения'),
            const SizedBox(height: 10),
            const Row(
              children: [
                _AchievementBadge(
                  icon: Icons.favorite_rounded,
                  title: 'Забота',
                  subtitle: 'Профиль создан',
                ),
                SizedBox(width: 10),
                _AchievementBadge(
                  icon: Icons.auto_awesome_rounded,
                  title: 'Гармония',
                  subtitle: 'Впереди',
                  muted: true,
                ),
              ],
            ),
            const SizedBox(height: 20),
            _SectionCard(
              children: [
                _ActionTile(
                  icon: Icons.help_outline_rounded,
                  title: 'Помощь',
                  trailing: Icon(
                    _helpExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: AppColors.textSecondary,
                  ),
                  onTap: () => setState(() => _helpExpanded = !_helpExpanded),
                ),
                if (_helpExpanded) const _HelpContent(),
                const _Divider(),
                _ActionTile(
                  icon: Icons.logout_rounded,
                  title: 'Выйти из аккаунта',
                  subtitle: 'Сбросить текущую сессию',
                  danger: true,
                  onTap: () => ref.read(authStateProvider.notifier).logout(),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.center,
              child: TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                onPressed: _confirmDeleteAccount,
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('Удалить аккаунт'),
              ),
            ),
          ],
        ),
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

class _ProfileSummaryCard extends StatelessWidget {
  final String name;
  final String profileId;
  final String email;
  final String? bio;
  final String initials;
  final String? photoPath;
  final VoidCallback onPhotoTap;
  final VoidCallback onPhotoEdit;
  final VoidCallback onEdit;

  const _ProfileSummaryCard({
    required this.name,
    required this.profileId,
    required this.email,
    required this.initials,
    required this.onPhotoTap,
    required this.onPhotoEdit,
    required this.onEdit,
    this.bio,
    this.photoPath,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoPath != null;
    final description = bio?.trim().isNotEmpty == true
        ? bio!.trim()
        : 'Расскажите немного о себе и своих питомцах';

    return _SectionCard(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: onPhotoTap,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 42,
                      backgroundColor: AppColors.primary.withAlpha(30),
                      backgroundImage: hasPhoto
                          ? FileImage(File(photoPath!))
                          : null,
                      child: hasPhoto
                          ? null
                          : initials.isEmpty
                          ? const Icon(
                              Icons.add_a_photo_outlined,
                              color: AppColors.primary,
                              size: 30,
                            )
                          : Text(
                              initials,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                    Positioned(
                      right: -4,
                      bottom: -4,
                      child: IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(32, 32),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: onPhotoEdit,
                        icon: const Icon(Icons.photo_camera_outlined, size: 17),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 20,
                              height: 1.1,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textMain,
                            ),
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: onEdit,
                          icon: const Icon(Icons.edit_outlined, size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profileId,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textMain,
                        fontSize: 13,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      height: 78,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textMain,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    ),
  );
}

class _AchievementBadge extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool muted;

  const _AchievementBadge({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      height: 84,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: muted
              ? const Color(0xFFE5DED7)
              : AppColors.secondary.withAlpha(130),
        ),
      ),
      child: Row(
        children: [
          _RowIcon(
            icon: icon,
            color: muted ? AppColors.textSecondary : AppColors.accent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: muted ? AppColors.textSecondary : AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
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

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool danger;
  final bool muted;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailing,
    this.danger = false,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger
        ? AppColors.error
        : muted
        ? AppColors.textSecondary
        : AppColors.primary;
    return ListTile(
      leading: _RowIcon(icon: icon, color: color),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: danger || muted ? color : AppColors.textMain,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
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

class _EditField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final int maxLines;

  const _EditField({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    keyboardType: keyboardType,
    maxLines: maxLines,
    decoration: InputDecoration(labelText: label),
  );
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
