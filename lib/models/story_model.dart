import 'package:cloud_firestore/cloud_firestore.dart';

class StoryModel {
  static const welcomeStoryId = 'welcome';
  static const welcomeImageAsset = 'assets/images/stories/welcome_story.webp';
  static const welcomePreviewAsset =
      'assets/images/stories/welcome_preview.webp';
  static const welcomeTitle = 'Привет! Это ЛапкоЕсть';
  static const welcomeSubtitle = 'Поможем заботиться о питомце каждый день';

  final String id;
  final String title;
  final String? subtitle;
  final StoryType type;
  final String? imageUrl;
  final String? previewImageUrl;
  final String? imageAsset;
  final String? previewImageAsset;
  final int sortOrder;
  final bool isViewed;

  const StoryModel({
    required this.id,
    required this.title,
    this.subtitle,
    required this.type,
    this.imageUrl,
    this.previewImageUrl,
    this.imageAsset,
    this.previewImageAsset,
    this.sortOrder = 0,
    this.isViewed = false,
  });

  factory StoryModel.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final isWelcome = doc.id == welcomeStoryId;
    return StoryModel(
      id: doc.id,
      title: _stringOrNull(data['title']) ?? (isWelcome ? welcomeTitle : ''),
      subtitle:
          _stringOrNull(data['subtitle']) ??
          (isWelcome ? welcomeSubtitle : null),
      type: StoryTypeX.fromName(data['type'] as String?),
      imageUrl: _stringOrNull(data['imageUrl']),
      previewImageUrl:
          _stringOrNull(data['previewImageUrl']) ??
          _stringOrNull(data['previewUrl']),
      imageAsset: isWelcome
          ? welcomeImageAsset
          : _stringOrNull(data['imageAsset']),
      previewImageAsset: isWelcome
          ? welcomePreviewAsset
          : _stringOrNull(data['previewImageAsset']),
      sortOrder: (data['sortOrder'] as num?)?.toInt() ?? 0,
      isViewed: data['isViewed'] as bool? ?? false,
    );
  }

  StoryModel copyWith({bool? isViewed}) {
    return StoryModel(
      id: id,
      title: title,
      subtitle: subtitle,
      type: type,
      imageUrl: imageUrl,
      previewImageUrl: previewImageUrl,
      imageAsset: imageAsset,
      previewImageAsset: previewImageAsset,
      sortOrder: sortOrder,
      isViewed: isViewed ?? this.isViewed,
    );
  }

  String? get tileImageUrl => previewImageUrl ?? imageUrl;
  String? get tileImageAsset => previewImageAsset ?? imageAsset;
  String? get backdropImageUrl => imageUrl ?? previewImageUrl;
  String? get backdropImageAsset => imageAsset ?? previewImageAsset;

  static String? _stringOrNull(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

enum StoryType { mine, promo, friend }

extension StoryTypeX on StoryType {
  String get name => switch (this) {
    StoryType.mine => 'mine',
    StoryType.promo => 'promo',
    StoryType.friend => 'friend',
  };

  static StoryType fromName(String? value) => switch (value) {
    'mine' => StoryType.mine,
    'friend' => StoryType.friend,
    _ => StoryType.promo,
  };
}
