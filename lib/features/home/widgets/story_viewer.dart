import 'package:flutter/material.dart';

import '../../../models/story_model.dart';

class StoryViewer extends StatefulWidget {
  final List<StoryModel> stories;
  final int initialIndex;

  const StoryViewer({
    super.key,
    required this.stories,
    this.initialIndex = 0,
  });

  static Future<void> show(
    BuildContext context, {
    required List<StoryModel> stories,
    int initialIndex = 0,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, a, b) => StoryViewer(
          stories: stories,
          initialIndex: initialIndex,
        ),
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

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) _next();
      });
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
      _progressController
        ..reset()
        ..forward();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _previous() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      _progressController
        ..reset()
        ..forward();
    }
  }

  void _pause() => _progressController.stop();
  void _resume() => _progressController.forward();

  @override
  Widget build(BuildContext context) {
    final story = widget.stories[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onLongPressStart: (_) => _pause(),
        onLongPressEnd: (_) => _resume(),
        child: Stack(
          children: [
            // Фон — плейсхолдер
            Container(
              width: double.infinity,
              height: double.infinity,
              color: story.color.withAlpha(220),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(story.emoji, style: const TextStyle(fontSize: 96)),
                    const SizedBox(height: 16),
                    Text(
                      story.userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                                      valueColor: AlwaysStoppedAnimation(Colors.white),
                                    )
                                  : i == _currentIndex
                                      ? AnimatedBuilder(
                                          animation: _progressController,
                                          builder: (ctx, child) => LinearProgressIndicator(
                                            value: _progressController.value,
                                            backgroundColor: Colors.white38,
                                            valueColor:
                                                const AlwaysStoppedAnimation(Colors.white),
                                          ),
                                        )
                                      : const LinearProgressIndicator(
                                          value: 0,
                                          backgroundColor: Colors.white38,
                                          valueColor: AlwaysStoppedAnimation(Colors.white),
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
                          child: Text(story.emoji),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          story.userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
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
    );
  }
}
