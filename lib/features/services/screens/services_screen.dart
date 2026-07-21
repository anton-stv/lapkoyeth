import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  final _mapQueryCtrl = TextEditingController(text: 'ветклиника рядом');

  @override
  void dispose() {
    _mapQueryCtrl.dispose();
    super.dispose();
  }

  Future<void> _openYandexMaps() async {
    final query = Uri.encodeComponent(_mapQueryCtrl.text.trim());
    if (query.isEmpty) return;
    final appUri = Uri.parse('yandexmaps://maps.yandex.ru/?text=$query');
    final webUri = Uri.parse('https://yandex.ru/maps/?text=$query');
    if (await canLaunchUrl(appUri)) {
      await launchUrl(appUri, mode: LaunchMode.externalApplication);
      return;
    }
    await launchUrl(webUri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Сервисы')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SoonCard(
            icon: Icons.storefront_rounded,
            title: 'Маркет и услуги',
            subtitle: 'Груминг, ветклиники, корма и специалисты',
            color: AppColors.primary,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.teal.withAlpha(38),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.map_outlined,
                        color: AppColors.teal,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Поиск на Яндекс Картах',
                            style: TextStyle(
                              color: AppColors.textMain,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Встроенная карта позже, сейчас открываем запрос',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _mapQueryCtrl,
                  maxLength: 80,
                  decoration: const InputDecoration(
                    hintText: 'Что найти',
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _openYandexMaps,
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: const Text('Открыть в Яндекс Картах'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const _SoonCard(
            icon: Icons.medical_services_outlined,
            title: 'Запись к врачу',
            subtitle: 'Скоро',
            color: AppColors.accent,
          ),
          const SizedBox(height: 12),
          const _SoonCard(
            icon: Icons.content_cut_rounded,
            title: 'Груминг',
            subtitle: 'Скоро',
            color: AppColors.warning,
          ),
        ],
      ),
    );
  }
}

class _SoonCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _SoonCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withAlpha(38),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textMain,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withAlpha(28),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Скоро',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
