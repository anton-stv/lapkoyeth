import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
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
      appBar: AppBar(
        title: const Text('ЛапкойЭть'),
        leading: IconButton(
          icon: const Icon(Icons.notifications_outlined),
          color: AppColors.textSecondary,
          onPressed: () {},
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            color: AppColors.textSecondary,
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: ListView(
        children: const [
          SizedBox(height: 8),
          StoriesRow(),
          SizedBox(height: 24),
          RemindersSection(),
          SizedBox(height: 24),
          QuickActionsSection(),
          SizedBox(height: 24),
          ServicesSection(),
          SizedBox(height: 24),
        ],
      ),
    );
  }
}
