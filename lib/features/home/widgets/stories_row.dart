import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_helper.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/story_model.dart';
import '../../community/community_repository.dart';
import '../providers/stories_provider.dart';
import 'story_viewer.dart';

class StoriesRow extends ConsumerWidget {
  const StoriesRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storiesState = ref.watch(storiesProvider);

    return storiesState.when(
      data: (stories) {
        if (stories.isEmpty) return const SizedBox.shrink();
        final viewedIds =
            ref.watch(viewedStoryIdsProvider).valueOrNull ?? <String>{};
        final visibleStories =
            stories
                .map(
                  (story) =>
                      story.copyWith(isViewed: viewedIds.contains(story.id)),
                )
                .toList()
              ..sort((a, b) {
                if (a.isViewed != b.isViewed) return a.isViewed ? 1 : -1;
                return a.sortOrder.compareTo(b.sortOrder);
              });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Сторисы',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 104,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: visibleStories.length,
                separatorBuilder: (_, i) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  final story = visibleStories[i];
                  return _StoryTile(
                    story: story,
                    onTap: () async {
                      final viewedStoryIds = await StoryViewer.show(
                        context,
                        stories: visibleStories,
                        initialIndex: i,
                      );
                      if (viewedStoryIds == null || viewedStoryIds.isEmpty) {
                        return;
                      }
                      final ownerUid = CommunityRepository.instance.uid;
                      if (ownerUid == null) return;
                      await DatabaseHelper.instance.markStoriesViewed(
                        ownerUid,
                        viewedStoryIds,
                      );
                      ref.invalidate(viewedStoryIdsProvider);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
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
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: story.isViewed
                      ? AppColors.textSecondary.withAlpha(80)
                      : AppColors.primary,
                  width: story.isViewed ? 1 : 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(19),
                child: _StoryPreview(
                  imageUrl: story.tileImageUrl,
                  imageAsset: story.tileImageAsset,
                  color: color,
                  icon: icon,
                  isViewed: story.isViewed,
                ),
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

class _StoryPreview extends StatelessWidget {
  final String? imageUrl;
  final String? imageAsset;
  final Color color;
  final IconData icon;
  final bool isViewed;

  const _StoryPreview({
    required this.imageUrl,
    required this.imageAsset,
    required this.color,
    required this.icon,
    required this.isViewed,
  });

  @override
  Widget build(BuildContext context) {
    final fallback = ColoredBox(
      color: color.withAlpha(isViewed ? 24 : 38),
      child: Center(
        child: Icon(
          icon,
          color: isViewed ? AppColors.textSecondary : color,
          size: 28,
        ),
      ),
    );

    final asset = imageAsset;
    final url = imageUrl;
    if (asset == null && url == null) return fallback;

    final image = asset != null
        ? Image.asset(
            asset,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => fallback,
          )
        : Image.network(
            url!,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => fallback,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return fallback;
            },
          );

    if (!isViewed) return image;

    return ColorFiltered(
      colorFilter: const ColorFilter.matrix(<double>[
        0.2126,
        0.7152,
        0.0722,
        0,
        0,
        0.2126,
        0.7152,
        0.0722,
        0,
        0,
        0.2126,
        0.7152,
        0.0722,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
      ]),
      child: Opacity(opacity: 0.72, child: image),
    );
  }
}
