import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static const _tabs = [
    _TabItem('/home', Icons.home_rounded, Icons.home_outlined, 'Главная'),
    _TabItem('/pets', Icons.pets_rounded, Icons.pets_outlined, 'Питомцы'),
    _TabItem('/calendar', Icons.calendar_month_rounded,
        Icons.calendar_month_outlined, 'Календарь'),
    _TabItem('/chat', Icons.chat_bubble_rounded,
        Icons.chat_bubble_outline_rounded, 'Чат'),
    _TabItem('/services', Icons.storefront_rounded,
        Icons.storefront_outlined, 'Сервисы'),
  ];

  int _currentIndex(String location) {
    for (var i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final current = _currentIndex(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(color: Color(0x12000000), blurRadius: 12, offset: Offset(0, -2)),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 60,
            child: Row(
              children: List.generate(_tabs.length, (i) {
                final tab = _tabs[i];
                final selected = i == current;
                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => context.go(tab.path),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          selected ? tab.activeIcon : tab.icon,
                          color: selected ? AppColors.primary : AppColors.textSecondary,
                          size: 24,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tab.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                            color: selected ? AppColors.primary : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem {
  final String path;
  final IconData activeIcon;
  final IconData icon;
  final String label;
  const _TabItem(this.path, this.activeIcon, this.icon, this.label);
}
