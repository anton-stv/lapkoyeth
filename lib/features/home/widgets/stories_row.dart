import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/story_model.dart';
import 'story_viewer.dart';

class StoriesRow extends StatelessWidget {
  const StoriesRow({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: stubStories.length,
        separatorBuilder: (_, i) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final story = stubStories[i];
          return GestureDetector(
            onTap: () => StoryViewer.show(
              context,
              stories: stubStories,
              initialIndex: i,
            ),
            child: Column(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: story.isViewed
                        ? null
                        : const LinearGradient(
                            colors: [AppColors.accent, AppColors.primary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    color: story.isViewed ? const Color(0xFFDDD8D2) : null,
                  ),
                  padding: const EdgeInsets.all(2.5),
                  child: Container(
                    decoration: BoxDecoration(
                      color: story.color.withAlpha(60),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        story.emoji,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  story.userName,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
