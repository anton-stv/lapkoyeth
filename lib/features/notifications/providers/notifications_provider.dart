import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/notification_event_model.dart';
import '../../../core/database/database_helper.dart';
import '../../auth/providers/auth_provider.dart';
import '../../community/community_repository.dart';

final notificationsProvider =
    NotifierProvider<NotificationsNotifier, List<NotificationEvent>>(
      NotificationsNotifier.new,
    );

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final events = ref.watch(notificationsProvider);
  return events.where((event) => !event.isRead).length;
});

final latestUnreadNotificationProvider = Provider<NotificationEvent?>((ref) {
  final events = [...ref.watch(notificationsProvider)]
    ..sort(compareNotificationEvents);
  for (final event in events) {
    if (!event.isRead) return event;
  }
  return null;
});

class NotificationsNotifier extends Notifier<List<NotificationEvent>> {
  @override
  List<NotificationEvent> build() {
    ref.watch(authStateProvider);
    final ownerUid = CommunityRepository.instance.uid;
    if (ownerUid == null) return const [];
    return DatabaseHelper.instance.getNotificationEvents(ownerUid);
  }

  void addOrUpdate(NotificationEvent event) {
    final ownerUid = CommunityRepository.instance.uid;
    if (ownerUid == null) return;
    final ownedEvent = event.copyWith(ownerUid: ownerUid);
    DatabaseHelper.instance.saveNotificationEvent(ownedEvent);
    final exists = state.any((item) => item.id == ownedEvent.id);
    state = exists
        ? [
            for (final item in state)
              if (item.id == ownedEvent.id) ownedEvent else item,
          ]
        : [...state, ownedEvent];
  }

  void delete(NotificationEvent event) {
    final ownerUid = CommunityRepository.instance.uid;
    if (ownerUid != null) {
      DatabaseHelper.instance.deleteNotificationEvent(ownerUid, event.id);
    }
    state = state.where((item) => item.id != event.id).toList();
  }

  void markRead(String id) {
    state = [
      for (final event in state)
        if (event.id == id) event.copyWith(isRead: true) else event,
    ];
    final updated = state.where((event) => event.id == id).firstOrNull;
    if (updated != null) DatabaseHelper.instance.saveNotificationEvent(updated);
  }

  void markReadMany(Iterable<String> ids) {
    final idsSet = ids.toSet();
    if (idsSet.isEmpty) return;
    state = [
      for (final event in state)
        if (idsSet.contains(event.id)) event.copyWith(isRead: true) else event,
    ];
    for (final event in state.where((event) => idsSet.contains(event.id))) {
      DatabaseHelper.instance.saveNotificationEvent(event);
    }
  }
}
