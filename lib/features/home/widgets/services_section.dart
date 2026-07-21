import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class ServicesSection extends StatelessWidget {
  const ServicesSection({super.key});

  static const _services = [
    _Service(Icons.local_hospital_outlined, 'Ветеринар', AppColors.teal),
    _Service(Icons.home_work_outlined, 'Зооняня', AppColors.secondary),
    _Service(Icons.school_outlined, 'Кинолог', AppColors.primary),
    _Service(Icons.content_cut_rounded, 'Груминг', AppColors.accent),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Сервисы', style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              TextButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Все сервисы — скоро')),
                ),
                child: const Text('Все'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 94,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _services.length,
              separatorBuilder: (_, i) => const SizedBox(width: 12),
              itemBuilder: (context, i) => _ServiceItem(service: _services[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _Service {
  final IconData icon;
  final String label;
  final Color color;
  const _Service(this.icon, this.label, this.color);
}

class _ServiceItem extends StatelessWidget {
  final _Service service;
  const _ServiceItem({required this.service});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${service.label} — скоро'))),
      child: Container(
        width: 92,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: service.color.withAlpha(38),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(service.icon, color: service.color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              service.label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
