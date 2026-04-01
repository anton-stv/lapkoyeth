import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../widgets/quick_actions_section.dart';
import '../widgets/reminders_section.dart';
import '../widgets/services_section.dart';
import '../widgets/stories_row.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ЛапкойЭть'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            color: AppColors.textSecondary,
            onPressed: () {},
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
