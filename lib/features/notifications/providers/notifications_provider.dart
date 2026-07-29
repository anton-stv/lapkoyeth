import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/notification_event_model.dart';

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
  List<NotificationEvent> build() => const [];

  void addOrUpdate(NotificationEvent event) {
    final exists = state.any((item) => item.id == event.id);
    state = exists
        ? [
            for (final item in state)
              if (item.id == event.id) event else item,
          ]
        : [...state, event];
  }

  void delete(NotificationEvent event) {
    state = state.where((item) => item.id != event.id).toList();
  }

  void markRead(String id) {
    state = [
      for (final event in state)
        if (event.id == id) event.copyWith(isRead: true) else event,
    ];
  }

  void markReadMany(Iterable<String> ids) {
    final idsSet = ids.toSet();
    if (idsSet.isEmpty) return;
    state = [
      for (final event in state)
        if (idsSet.contains(event.id)) event.copyWith(isRead: true) else event,
    ];
  }
}
