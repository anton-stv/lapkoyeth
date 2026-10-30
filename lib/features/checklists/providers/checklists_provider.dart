import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_helper.dart';
import '../../../models/checklist_model.dart';
import '../../pets/providers/pets_provider.dart';

final checklistsProvider =
    AsyncNotifierProvider<ChecklistsNotifier, List<ChecklistModel>>(
      ChecklistsNotifier.new,
    );

class ChecklistsNotifier extends AsyncNotifier<List<ChecklistModel>> {
  static const pinnedLimit = 10;

  @override
  Future<List<ChecklistModel>> build() async {
    final pets = await ref.watch(petsProvider.future);
    final petIds = pets.map((pet) => pet.id).whereType<int>().toList();
    if (petIds.isEmpty) return [];
    return DatabaseHelper.instance.getChecklistsForPets(petIds);
  }

  Future<ChecklistModel> ensureDefaultChecklist({
    required int petId,
    required String petName,
  }) async {
    final existing = (state.valueOrNull ?? [])
        .where((checklist) => checklist.petId == petId)
        .toList();
    if (existing.isNotEmpty) return existing.first;

    final checklist = ChecklistModel(
      petId: petId,
      petName: petName,
      title: 'Уход за день',
      description: 'Ежедневные дела по уходу',
      scheduledDate: ChecklistModel.dateKey(DateTime.now()),
      repeatWeekdays: const [1, 2, 3, 4, 5, 6, 7],
      durationType: 'forever',
      items: const [
        ChecklistItemModel(title: 'Покормили утром'),
        ChecklistItemModel(title: 'Погуляли'),
        ChecklistItemModel(title: 'Проверили воду'),
        ChecklistItemModel(title: 'Дали лекарства'),
        ChecklistItemModel(title: 'Покормили вечером'),
      ],
    );
    final id = await DatabaseHelper.instance.insertChecklist(checklist);
    final saved = checklist.copyWith(id: id);
    state = AsyncData([...state.valueOrNull ?? [], saved]);
    return saved;
  }

  Future<void> addChecklist(ChecklistModel checklist) async {
    final id = await DatabaseHelper.instance.insertChecklist(checklist);
    state = AsyncData([...state.valueOrNull ?? [], checklist.copyWith(id: id)]);
  }

  Future<void> updateChecklist(ChecklistModel checklist) async {
    await DatabaseHelper.instance.updateChecklist(checklist);
    state = AsyncData(
      (state.valueOrNull ?? [])
          .map((item) => item.id == checklist.id ? checklist : item)
          .toList(),
    );
  }

  Future<bool> setPinned(ChecklistModel checklist, bool isPinned) async {
    if (isPinned &&
        !(checklist.isPinned) &&
        pinnedChecklists().length >= pinnedLimit) {
      return false;
    }
    await updateChecklist(checklist.copyWith(isPinned: isPinned));
    return true;
  }

  Future<void> updateFutureChecklist(ChecklistModel checklist) async {
    await updateChecklist(checklist.copyWith(isException: false));
  }

  Future<bool> createExceptionForDate({
    required ChecklistModel source,
    required ChecklistModel edited,
    required DateTime date,
  }) async {
    if (source.id == null) return false;
    final dateKey = ChecklistModel.dateKey(date);
    final excluded = {...source.excludedDates, dateKey}.toList()..sort();
    await updateChecklist(source.copyWith(excludedDates: excluded));
    await addChecklist(
      ChecklistModel(
        petId: source.petId,
        petName: source.petName,
        title: edited.title,
        description: edited.description,
        scheduledDate: dateKey,
        deadlineDate: edited.deadlineDate,
        repeatWeekdays: const [],
        durationType: 'single',
        endDate: null,
        repeatCount: null,
        isPinned: edited.isPinned,
        isException: true,
        items: edited.items,
      ),
    );
    return true;
  }

  List<ChecklistModel> pinnedChecklists() =>
      (state.valueOrNull ?? []).where((item) => item.isPinned).toList();

  Future<void> deleteChecklist(int id) async {
    await DatabaseHelper.instance.deleteChecklist(id);
    state = AsyncData(
      (state.valueOrNull ?? []).where((item) => item.id != id).toList(),
    );
  }
}
