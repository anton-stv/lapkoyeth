import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Сервисы')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🏪', style: TextStyle(fontSize: 64)),
            SizedBox(height: 16),
            Text('Сервисы', style: TextStyle(fontSize: 18, color: AppColors.textSecondary)),
            SizedBox(height: 8),
            Text('Скоро', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
