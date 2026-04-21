import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../features/auth/providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late TextEditingController _firstNameCtrl;
  late TextEditingController _lastNameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _cityCtrl;
  String? _gender;
  bool _saving = false;
  bool _edited = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authStateProvider).valueOrNull;
    _firstNameCtrl = TextEditingController(text: user?.firstName ?? '');
    _lastNameCtrl  = TextEditingController(text: user?.lastName  ?? '');
    _phoneCtrl     = TextEditingController(text: user?.phone     ?? '');
    _cityCtrl      = TextEditingController(text: user?.city      ?? '');
    _gender = user?.gender;
    for (final c in [_firstNameCtrl, _lastNameCtrl, _phoneCtrl, _cityCtrl]) {
      c.addListener(() => setState(() => _edited = true));
    }
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    setState(() => _saving = true);
    try {
      await ref.read(authStateProvider.notifier).updateUser(user.copyWith(
        firstName: _firstNameCtrl.text.trim(),
        lastName:  _lastNameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        city:  _cityCtrl.text.trim().isEmpty  ? null : _cityCtrl.text.trim(),
        gender: _gender,
      ));
      if (mounted) {
        setState(() => _edited = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Профиль обновлён')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showChangePassword() {
    final oldCtrl     = TextEditingController();
    final newCtrl     = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscureOld  = true;
    bool obscureNew  = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDDD8D2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Смена пароля',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 20),
                _pwField(oldCtrl, 'Текущий пароль', obscureOld,
                    () => setS(() => obscureOld = !obscureOld)),
                const SizedBox(height: 12),
                _pwField(newCtrl, 'Новый пароль', obscureNew,
                    () => setS(() => obscureNew = !obscureNew)),
                const SizedBox(height: 12),
                _pwField(confirmCtrl, 'Повторите новый пароль', obscureNew,
                    () => setS(() => obscureNew = !obscureNew)),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (newCtrl.text != confirmCtrl.text) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Пароли не совпадают')),
                        );
                        return;
                      }
                      try {
                        await ref.read(authStateProvider.notifier).changePassword(
                          currentPassword: oldCtrl.text,
                          newPassword: newCtrl.text,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Пароль изменён')),
                          );
                        }
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text('$e')),
                          );
                        }
                      }
                    },
                    child: const Text('Изменить пароль'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pwField(TextEditingController c, String hint, bool obscure, VoidCallback toggle) =>
      TextField(
        controller: c,
        obscureText: obscure,
        decoration: InputDecoration(
          hintText: hint,
          suffixIcon: IconButton(
            icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                size: 20, color: AppColors.textSecondary),
            onPressed: toggle,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) return const SizedBox.shrink();

    final initials = [
      if (user.firstName.isNotEmpty) user.firstName[0],
      if (user.lastName.isNotEmpty)  user.lastName[0],
    ].join().toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Шапка ─────────────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (_edited)
                TextButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Сохранить',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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
                      const SizedBox(height: 40),
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(30),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white54, width: 2),
                        ),
                        child: Center(
                          child: initials.isEmpty
                              ? const Icon(Icons.person_rounded, color: Colors.white, size: 40)
                              : Text(initials,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                  )),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${user.firstName} ${user.lastName}'.trim(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(user.email,
                          style: TextStyle(
                            color: Colors.white.withAlpha(180),
                            fontSize: 13,
                          )),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Содержимое ────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),

                  // Личные данные
                  _sectionTitle('Личные данные'),
                  const SizedBox(height: 8),
                  _SectionCard(children: [
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
                  ]),
                  const SizedBox(height: 20),

                  // Пол
                  _sectionTitle('Пол'),
                  const SizedBox(height: 8),
                  _SectionCard(children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          _GenderOption(
                            label: '♂  Мужской',
                            selected: _gender == 'male',
                            onTap: () => setState(() {
                              _gender = 'male';
                              _edited = true;
                            }),
                          ),
                          const SizedBox(width: 10),
                          _GenderOption(
                            label: '♀  Женский',
                            selected: _gender == 'female',
                            onTap: () => setState(() {
                              _gender = 'female';
                              _edited = true;
                            }),
                          ),
                        ],
                      ),
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // Безопасность
                  _sectionTitle('Безопасность'),
                  const SizedBox(height: 8),
                  _SectionCard(children: [
                    ListTile(
                      leading: Container(
                        width: 34, height: 34,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(30),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.lock_outline_rounded,
                            color: AppColors.primary, size: 18),
                      ),
                      title: const Text('Сменить пароль',
                          style: TextStyle(fontSize: 15)),
                      trailing: const Icon(Icons.chevron_right_rounded,
                          color: AppColors.textSecondary),
                      onTap: _showChangePassword,
                    ),
                  ]),
                  const SizedBox(height: 32),

                  // Выход
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
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

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            )),
      );
}

// ── Вспомогательные виджеты ──────────────────────────────

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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.controller,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
                TextField(
                  controller: controller,
                  keyboardType: keyboardType,
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
}

class _GenderOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _GenderOption({required this.label, required this.selected, required this.onTap});

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
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                color: selected ? Colors.white : AppColors.textMain,
              ),
            ),
          ),
        ),
      );
}
