import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_helper.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../models/health_record_model.dart';
import '../../../models/pet_model.dart';
import '../../../models/weight_record_model.dart';

// Список питомцев текущего пользователя
final petsProvider = AsyncNotifierProvider<PetsNotifier, List<PetModel>>(PetsNotifier.new);

class PetsNotifier extends AsyncNotifier<List<PetModel>> {
  @override
  Future<List<PetModel>> build() async {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) return [];
    return DatabaseHelper.instance.getPetsByOwner(user.id!);
  }

  Future<void> addPet(PetModel pet) async {
    final id = await DatabaseHelper.instance.insertPet(pet);
    final saved = pet.copyWith(id: id);
    state = AsyncData([...state.valueOrNull ?? [], saved]);
  }

  Future<void> updatePet(PetModel pet) async {
    await DatabaseHelper.instance.updatePet(pet);
    state = AsyncData(
      (state.valueOrNull ?? []).map((p) => p.id == pet.id ? pet : p).toList(),
    );
  }

  Future<void> deletePet(int petId) async {
    await DatabaseHelper.instance.deletePet(petId);
    state = AsyncData(
      (state.valueOrNull ?? []).where((p) => p.id != petId).toList(),
    );
  }

  Future<void> refresh() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    state = AsyncData(await DatabaseHelper.instance.getPetsByOwner(user.id!));
  }
}

// Записи веса конкретного питомца
final weightRecordsProvider =
    FutureProvider.family<List<WeightRecordModel>, int>((ref, petId) {
  return DatabaseHelper.instance.getWeightRecords(petId);
});

// Записи здоровья конкретного питомца
final healthRecordsProvider =
    FutureProvider.family<List<HealthRecordModel>, int>((ref, petId) {
  return DatabaseHelper.instance.getHealthRecords(petId);
});
