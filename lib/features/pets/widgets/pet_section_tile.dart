import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class PetSectionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? expandedContent;
  final IconData? icon;

  const PetSectionTile({
    super.key,
    required this.title,
    required this.subtitle,
    this.expandedContent,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      decoration: const BoxDecoration(color: AppColors.surface),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          leading: icon != null
              ? Icon(icon, color: AppColors.primary, size: 22)
              : null,
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textMain,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          iconColor: AppColors.textSecondary,
          collapsedIconColor: AppColors.textSecondary,
          children: [
            ?expandedContent,
          ],
        ),
      ),
    );
  }
}
