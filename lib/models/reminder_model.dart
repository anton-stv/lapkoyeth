class ReminderModel {
  final String id;
  final String title;
  final String time;
  final String petName;
  final ReminderType type;
  final bool isDone;

  const ReminderModel({
    required this.id,
    required this.title,
    required this.time,
    required this.petName,
    required this.type,
    this.isDone = false,
  });
}

enum ReminderType { medicine, vet, walk, food, grooming }

final stubReminders = [
  const ReminderModel(
    id: '1',
    title: 'Дать таблетку',
    time: '09:00',
    petName: 'Бобик',
    type: ReminderType.medicine,
  ),
  const ReminderModel(
    id: '2',
    title: 'Плановый осмотр',
    time: '15:00',
    petName: 'Бобик',
    type: ReminderType.vet,
  ),
  const ReminderModel(
    id: '3',
    title: 'Прогулка',
    time: '18:00',
    petName: 'Бобик',
    type: ReminderType.walk,
  ),
  const ReminderModel(
    id: '4',
    title: 'Покормить',
    time: '20:00',
    petName: 'Мурка',
    type: ReminderType.food,
  ),
];
