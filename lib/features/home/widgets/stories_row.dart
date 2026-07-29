import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/story_model.dart';
import 'story_viewer.dart';

class StoriesRow extends StatelessWidget {
  const StoriesRow({super.key});

  @override
  Widget build(BuildContext context) {
    if (availableStories.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('Сторисы', style: Theme.of(context).textTheme.titleLarge),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 104,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: availableStories.length,
            separatorBuilder: (_, i) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final story = availableStories[i];
              return _StoryTile(
                story: story,
                onTap: () => StoryViewer.show(
                  context,
                  stories: availableStories,
                  initialIndex: i,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StoryTile extends StatelessWidget {
  final StoryModel story;
  final VoidCallback onTap;

  const _StoryTile({required this.story, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = switch (story.type) {
      StoryType.mine => AppColors.primary,
      StoryType.promo => AppColors.accent,
      StoryType.friend => AppColors.teal,
    };
    final icon = switch (story.type) {
      StoryType.mine => Icons.add_rounded,
      StoryType.promo => Icons.auto_awesome_rounded,
      StoryType.friend => Icons.people_alt_outlined,
    };

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Container(
              width: 68,
              height: 68,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: story.isViewed ? AppColors.surface : null,
                borderRadius: BorderRadius.circular(22),
                gradient: story.isViewed
                    ? null
                    : LinearGradient(
                        colors: [color, AppColors.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: color.withAlpha(38),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              story.title,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
