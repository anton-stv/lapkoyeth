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

final stubStories = [
  const StoryModel(id: '1', title: 'Мои', type: StoryType.mine),
  const StoryModel(id: '2', title: 'Советы', type: StoryType.promo),
  const StoryModel(id: '3', title: 'Друзья', type: StoryType.friend),
  const StoryModel(
    id: '4',
    title: 'Уход',
    type: StoryType.promo,
    isViewed: true,
  ),
  const StoryModel(
    id: '5',
    title: 'Прогулки',
    type: StoryType.friend,
    isViewed: true,
  ),
  const StoryModel(id: '6', title: 'Акции', type: StoryType.promo),
];
