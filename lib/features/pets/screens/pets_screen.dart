import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class PetsScreen extends StatelessWidget {
  const PetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Питомцы')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🐾', style: TextStyle(fontSize: 64)),
            SizedBox(height: 16),
            Text('Профили питомцев', style: TextStyle(fontSize: 18, color: AppColors.textSecondary)),
            SizedBox(height: 8),
            Text('Скоро', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
        onPressed: () {},
      ),
    );
  }
}
