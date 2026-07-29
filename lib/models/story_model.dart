class StoryModel {
  final String id;
  final String title;
  final StoryType type;
  final bool isViewed;

  const StoryModel({
    required this.id,
    required this.title,
    required this.type,
    this.isViewed = false,
  });
}

enum StoryType { mine, promo, friend }

const availableStories = <StoryModel>[];
