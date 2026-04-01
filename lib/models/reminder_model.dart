class ReminderModel {
  final String id;
  final String title;
  final String time;
  final String petName;
  final bool isDone;

  const ReminderModel({
    required this.id,
    required this.title,
    required this.time,
    required this.petName,
    this.isDone = false,
  });
}

// Заглушки
final stubReminders = [
  const ReminderModel(id: '1', title: 'Дать таблетку', time: '09:00', petName: 'Бобик'),
  const ReminderModel(id: '2', title: 'Плановый осмотр', time: '15:00', petName: 'Бобик'),
  const ReminderModel(id: '3', title: 'Прогулка', time: '18:00', petName: 'Бобик'),
];
