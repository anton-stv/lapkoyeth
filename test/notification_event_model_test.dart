import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapkoyeth/models/notification_event_model.dart';

void main() {
  NotificationEvent recurringThursday({List<DateTime> excluded = const []}) =>
      NotificationEvent(
        id: 'weekly',
        title: 'Прогулка',
        petName: 'Эмми',
        date: DateTime(2026, 8, 6),
        time: const TimeOfDay(hour: 10, minute: 0),
        description: '',
        icon: Icons.event,
        color: Colors.green,
        isRecurring: true,
        repeatWeekdays: const [DateTime.thursday],
        excludedDates: excluded,
      );

  test('regular event occurs only on configured weekday after start', () {
    final event = recurringThursday();
    expect(notificationOccursOn(event, DateTime(2026, 8, 6)), isTrue);
    expect(notificationOccursOn(event, DateTime(2026, 8, 7)), isFalse);
    expect(notificationOccursOn(event, DateTime(2026, 8, 13)), isTrue);
    expect(notificationOccursOn(event, DateTime(2026, 7, 30)), isFalse);
  });

  test('excluded occurrence is omitted', () {
    final event = recurringThursday(excluded: [DateTime(2026, 8, 13)]);
    expect(notificationOccursOn(event, DateTime(2026, 8, 13)), isFalse);
    expect(notificationOccursOn(event, DateTime(2026, 8, 20)), isTrue);
  });

  test('next occurrence can be far in the future', () {
    final event = NotificationEvent(
      id: 'future',
      title: 'Прививка',
      petName: 'Общее',
      date: DateTime(2027, 9, 8),
      time: const TimeOfDay(hour: 9, minute: 30),
      description: '',
      icon: Icons.vaccines,
      color: Colors.blue,
    );
    expect(
      nextNotificationOccurrence(event, DateTime(2026, 9, 8)),
      DateTime(2027, 9, 8),
    );
  });

  test('event survives map serialization with recurrence exceptions', () {
    final source = recurringThursday(excluded: [DateTime(2026, 8, 13)]);
    final restored = NotificationEvent.fromMap(source.toMap());
    expect(restored.petName, 'Эмми');
    expect(restored.repeatWeekdays, [DateTime.thursday]);
    expect(restored.excludedDates.single, DateTime(2026, 8, 13));
  });
}
