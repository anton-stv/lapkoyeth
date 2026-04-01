import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../models/pet_model.dart';
import '../../models/user_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._();
  DatabaseHelper._();

  static const _usersBox = 'users';
  static const _petsBox = 'pets';
  static const _metaBox = 'meta';

  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<Map>(_usersBox);
    await Hive.openBox<Map>(_petsBox);
    await Hive.openBox(_metaBox);
    await _seedIfNeeded();
  }

  Future<void> _seedIfNeeded() async {
    final meta = Hive.box(_metaBox);
    if (meta.get('seeded') == true) return;

    final hash = sha256.convert(utf8.encode('admin')).toString();
    await insertUser(UserModel(
      firstName: 'Тест',
      lastName: 'Юзер',
      email: 'admin@test.ru',
      passwordHash: hash,
      city: 'Москва',
    ));
    await meta.put('seeded', true);
  }

  Box<Map> get _users => Hive.box<Map>(_usersBox);
  Box<Map> get _pets => Hive.box<Map>(_petsBox);

  // ── Users ──────────────────────────────────────────────

  Future<int> insertUser(UserModel user) async {
    final meta = Hive.box(_metaBox);
    final nextId = (meta.get('nextUserId') as int? ?? 1);
    await meta.put('nextUserId', nextId + 1);
    final data = user.toMap()..['id'] = nextId;
    await _users.put(nextId, data);
    return nextId;
  }

  Future<UserModel?> getUserByEmail(String email) async {
    for (final val in _users.values) {
      final map = Map<String, dynamic>.from(val);
      if (map['email'] == email) return UserModel.fromMap(map);
    }
    return null;
  }

  Future<UserModel?> getUserById(int id) async {
    final val = _users.get(id);
    if (val == null) return null;
    return UserModel.fromMap(Map<String, dynamic>.from(val));
  }

  Future<void> updateUser(UserModel user) async {
    if (user.id == null) return;
    await _users.put(user.id, user.toMap());
  }

  // ── Pets ───────────────────────────────────────────────

  Future<int> insertPet(PetModel pet) async {
    final meta = Hive.box(_metaBox);
    final nextId = (meta.get('nextPetId') as int? ?? 1);
    await meta.put('nextPetId', nextId + 1);
    final data = pet.toMap()..['id'] = nextId;
    await _pets.put(nextId, data);
    return nextId;
  }

  Future<List<PetModel>> getPetsByOwner(int ownerId) async {
    return _pets.values
        .map((v) => PetModel.fromMap(Map<String, dynamic>.from(v)))
        .where((p) => p.ownerId == ownerId)
        .toList();
  }

  Future<void> updatePet(PetModel pet) async {
    if (pet.id == null) return;
    await _pets.put(pet.id, pet.toMap());
  }

  Future<void> deletePet(int id) async {
    await _pets.delete(id);
  }
}
