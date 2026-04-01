import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class ServicesSection extends StatelessWidget {
  const ServicesSection({super.key});

  static const _services = [
    _Service('🩺', 'Ветеринар', AppColors.teal),
    _Service('🏠', 'Зооняня', AppColors.secondary),
    _Service('🐕', 'Кинолог', AppColors.primary),
    _Service('✂️', 'Груминг', AppColors.accent),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Сервисы', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: _services
                .map((s) => _ServiceItem(service: s))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _Service {
  final String emoji;
  final String label;
  final Color color;
  const _Service(this.emoji, this.label, this.color);
}

class _ServiceItem extends StatelessWidget {
  final _Service service;
  const _ServiceItem({required this.service});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${service.label} — скоро')),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: service.color.withAlpha(40),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: service.color.withAlpha(70)),
            ),
            child: Center(
              child: Text(service.emoji,
                  style: const TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            service.label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}
