import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_helper.dart';
import '../../../models/story_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../community/community_repository.dart';

final storiesEnabledProvider = StreamProvider<bool>((ref) {
  return FirebaseFirestore.instance
      .collection('app_config')
      .doc('features')
      .snapshots()
      .map((snapshot) => snapshot.data()?['storiesEnabled'] as bool? ?? false);
});

final storiesProvider = StreamProvider<List<StoryModel>>((ref) {
  final enabled = ref.watch(storiesEnabledProvider).valueOrNull ?? false;
  if (!enabled) return Stream.value(const []);

  return FirebaseFirestore.instance
      .collection('stories')
      .where('enabled', isEqualTo: true)
      .snapshots()
      .map((snapshot) {
        final stories = snapshot.docs.map(StoryModel.fromFirestore).toList();
        stories.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        return stories;
      });
});

// Re-read local state when the home screen is recreated after logout/account
// deletion. Keeping this provider alive used to retain the previous account's
// viewed ids and made stories look missing for a newly registered account.
final viewedStoryIdsProvider = FutureProvider.autoDispose<Set<String>>((ref) {
  ref.watch(authStateProvider);
  final ownerUid = CommunityRepository.instance.uid;
  if (ownerUid == null) return <String>{};
  return DatabaseHelper.instance.getViewedStoryIds(ownerUid);
});
