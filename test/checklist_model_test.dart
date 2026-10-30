import 'package:flutter_test/flutter_test.dart';
import 'package:lapkoyeth/models/checklist_model.dart';

void main() {
  test('checklist items can be reordered', () {
    final checklist = ChecklistModel(
      petId: 1,
      petName: 'Эмми',
      title: 'Уход',
      scheduledDate: '2026-09-08',
      items: const [
        ChecklistItemModel(title: 'Первый'),
        ChecklistItemModel(title: 'Второй'),
        ChecklistItemModel(title: 'Третий'),
      ],
    );

    final reordered = checklist.reorderItem(0, 2);
    expect(reordered.items.map((item) => item.title), [
      'Второй',
      'Третий',
      'Первый',
    ]);
  });
}
