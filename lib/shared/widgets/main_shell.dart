import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import 'responsive_content.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static const _tabs = [
    _TabItem('/home', Icons.home_rounded, Icons.home_outlined, 'Главная'),
    _TabItem('/pets', Icons.pets_rounded, Icons.pets_outlined, 'Питомцы'),
    _TabItem(
      '/calendar',
      Icons.calendar_month_rounded,
      Icons.calendar_month_outlined,
      'Календарь',
    ),
    _TabItem(
      '/chat',
      Icons.people_alt_rounded,
      Icons.people_alt_outlined,
      'Петобщество',
    ),
    _TabItem(
      '/profile',
      Icons.person_rounded,
      Icons.person_outline_rounded,
      'Профиль',
    ),
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail = constraints.maxWidth >= AppBreakpoints.tablet;
        final extended = constraints.maxWidth >= AppBreakpoints.desktop;
        final content = ColoredBox(
          color: AppColors.background,
          child: ResponsiveContent(child: child),
        );

        if (useRail) {
          return Scaffold(
            body: Row(
              children: [
                SafeArea(
                  right: false,
                  child: NavigationRail(
                    extended: extended,
                    selectedIndex: current,
                    onDestinationSelected: (index) =>
                        context.go(_tabs[index].path),
                    labelType: extended
                        ? NavigationRailLabelType.none
                        : NavigationRailLabelType.all,
                    leading: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: extended
                          ? const Text(
                              'ЛапкойЭть',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            )
                          : const Icon(Icons.pets, color: AppColors.primary),
                    ),
                    destinations: [
                      for (final tab in _tabs)
                        NavigationRailDestination(
                          icon: Icon(tab.icon),
                          selectedIcon: Icon(tab.activeIcon),
                          label: Text(tab.label),
                        ),
                    ],
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: content),
              ],
            ),
          );
        }

        return Scaffold(
          body: content,
          bottomNavigationBar: _MobileNavigation(tabs: _tabs, current: current),
        );
      },
    );
  }
}

class _MobileNavigation extends StatelessWidget {
  const _MobileNavigation({required this.tabs, required this.current});

  final List<_TabItem> tabs;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(tabs.length, (i) {
              final tab = tabs[i];
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
                        color: selected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        size: 24,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tab.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: selected
                              ? AppColors.primary
                              : AppColors.textSecondary,
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
