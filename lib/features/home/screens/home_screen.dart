import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/notifications/providers/notifications_provider.dart';
import '../../../models/user_model.dart';
import '../widgets/quick_actions_section.dart';
import '../widgets/reminders_section.dart';
import '../widgets/services_section.dart';
import '../widgets/stories_row.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListView(
        padding: const EdgeInsets.only(top: 14, bottom: 28),
        children: [
          const _HomeHeader(),
          const SizedBox(height: 18),
          const StoriesRow(),
          const SizedBox(height: 24),
          const RemindersSection(),
          const SizedBox(height: 24),
          const QuickActionsSection(),
          const SizedBox(height: 24),
          const ServicesSection(),
        ],
      ),
    );
  }
}

class _HomeHeader extends ConsumerWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    final profileIncomplete = user != null && _profileCompleteness(user) < 100;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(35),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.pets_rounded,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ЛапкойЭть',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Сегодня все под рукой',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            _BadgeIconButton(
              icon: Icons.notifications_none_rounded,
              badgeText: unreadCount == 0
                  ? null
                  : unreadCount > 99
                  ? '99+'
                  : unreadCount.toString(),
              onTap: () => context.push('/notifications'),
            ),
            const SizedBox(width: 10),
            _BadgeIconButton(
              icon: Icons.person_outline_rounded,
              badgeText: profileIncomplete ? '!' : null,
              badgeColor: AppColors.warning,
              onTap: () => context.go('/profile'),
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
}

class _BadgeIconButton extends StatelessWidget {
  final IconData icon;
  final String? badgeText;
  final Color badgeColor;
  final VoidCallback onTap;

  const _BadgeIconButton({
    required this.icon,
    required this.onTap,
    this.badgeText,
    this.badgeColor = AppColors.error,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(icon, color: AppColors.textMain),
            ),
            if (badgeText != null)
              Positioned(
                top: -3,
                right: -3,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.background, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    badgeText!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
