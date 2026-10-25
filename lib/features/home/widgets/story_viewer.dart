import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/story_model.dart';

class StoryViewer extends StatefulWidget {
  final List<StoryModel> stories;
  final int initialIndex;

  const StoryViewer({super.key, required this.stories, this.initialIndex = 0});

  static Future<List<String>?> show(
    BuildContext context, {
    required List<StoryModel> stories,
    int initialIndex = 0,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, a, b) =>
            StoryViewer(stories: stories, initialIndex: initialIndex),
      ),
    );
  }

  @override
  State<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<StoryViewer>
    with SingleTickerProviderStateMixin {
  late int _currentIndex;
  late AnimationController _progressController;
  final Set<String> _viewedStoryIds = <String>{};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _progressController =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) _next();
          });
    _markCurrentViewed();
    _progressController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentIndex < widget.stories.length - 1) {
      setState(() => _currentIndex++);
      _markCurrentViewed();
      _progressController
        ..reset()
        ..forward();
    } else {
      _close();
    }
  }

  void _previous() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      _markCurrentViewed();
      _progressController
        ..reset()
        ..forward();
    }
  }

  void _markCurrentViewed() {
    _viewedStoryIds.add(widget.stories[_currentIndex].id);
  }

  void _close() {
    Navigator.of(context).pop(_viewedStoryIds.toList());
  }

  void _pause() => _progressController.stop();
  void _resume() => _progressController.forward();

  @override
  Widget build(BuildContext context) {
    final story = widget.stories[_currentIndex];
    final color = _colorFor(story.type);
    final icon = _iconFor(story.type);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _close();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onLongPressStart: (_) => _pause(),
          onLongPressEnd: (_) => _resume(),
          child: Stack(
            children: [
              _StoryBackdrop(story: story, color: color, icon: icon),

              // Зоны нажатия: лево = назад, право = вперёд
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: _previous,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: _next,
                    ),
                  ),
                ],
              ),

              // Верхняя панель
              SafeArea(
                child: Column(
                  children: [
                    // Полоски прогресса
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      child: Row(
                        children: List.generate(widget.stories.length, (i) {
                          return Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              height: 3,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: i < _currentIndex
                                    ? const LinearProgressIndicator(
                                        value: 1,
                                        backgroundColor: Colors.white38,
                                        valueColor: AlwaysStoppedAnimation(
                                          Colors.white,
                                        ),
                                      )
                                    : i == _currentIndex
                                    ? AnimatedBuilder(
                                        animation: _progressController,
                                        builder: (ctx, child) =>
                                            LinearProgressIndicator(
                                              value: _progressController.value,
                                              backgroundColor: Colors.white38,
                                              valueColor:
                                                  const AlwaysStoppedAnimation(
                                                    Colors.white,
                                                  ),
                                            ),
                                      )
                                    : const LinearProgressIndicator(
                                        value: 0,
                                        backgroundColor: Colors.white38,
                                        valueColor: AlwaysStoppedAnimation(
                                          Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),

                    // Заголовок + закрыть
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.white24,
                            child: Icon(icon, color: Colors.white, size: 19),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              story.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: _close,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(StoryType type) {
    return switch (type) {
      StoryType.mine => Icons.add_rounded,
      StoryType.promo => Icons.auto_awesome_rounded,
      StoryType.friend => Icons.people_alt_outlined,
    };
  }

  Color _colorFor(StoryType type) {
    return switch (type) {
      StoryType.mine => AppColors.primary,
      StoryType.promo => AppColors.accent,
      StoryType.friend => AppColors.teal,
    };
  }
}

class _StoryBackdrop extends StatelessWidget {
  final StoryModel story;
  final Color color;
  final IconData icon;

  const _StoryBackdrop({
    required this.story,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final imageAsset = story.backdropImageAsset;
    final imageUrl = story.backdropImageUrl;
    final placeholder = ColoredBox(
      color: color.withAlpha(220),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 96),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Text(
                story.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );

    if (imageAsset == null && imageUrl == null) {
      return SizedBox.expand(child: placeholder);
    }

    return SizedBox.expand(
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageAsset != null)
            Image.asset(
              imageAsset,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => placeholder,
            )
          else
            Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => placeholder,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return placeholder;
              },
            ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black38, Colors.transparent, Colors.black26],
                stops: [0, 0.35, 1],
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 96, 24, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      story.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        height: 1.05,
                        fontWeight: FontWeight.w800,
                        shadows: [
                          Shadow(
                            color: Colors.black45,
                            offset: Offset(0, 1),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (story.subtitle != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        story.subtitle!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          height: 1.25,
                          fontWeight: FontWeight.w600,
                          shadows: [
                            Shadow(
                              color: Colors.black45,
                              offset: Offset(0, 1),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
