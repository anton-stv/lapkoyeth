import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../models/health_record_model.dart';
import '../../models/pet_model.dart';
import '../../models/user_model.dart';
import '../../models/weight_record_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._();
  DatabaseHelper._();

  static const _usersBox = 'users';
  static const _petsBox = 'pets';
  static const _metaBox = 'meta';
  static const _weightBox = 'weight_records';
  static const _healthBox = 'health_records';

  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<Map>(_usersBox);
    await Hive.openBox<Map>(_petsBox);
    await Hive.openBox<Map>(_weightBox);
    await Hive.openBox<Map>(_healthBox);
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
  Box<Map> get _weights => Hive.box<Map>(_weightBox);
  Box<Map> get _health => Hive.box<Map>(_healthBox);

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

  Future<PetModel?> getPetById(int id) async {
    final val = _pets.get(id);
    if (val == null) return null;
    return PetModel.fromMap(Map<String, dynamic>.from(val));
  }

  Future<void> updatePet(PetModel pet) async {
    if (pet.id == null) return;
    await _pets.put(pet.id, pet.toMap());
  }

  Future<void> deletePet(int id) async {
    await _pets.delete(id);
    // Удаляем связанные записи
    final weightKeys = _weights.keys
        .where((k) => (_weights.get(k)?['pet_id']) == id)
        .toList();
    await _weights.deleteAll(weightKeys);
    final healthKeys = _health.keys
        .where((k) => (_health.get(k)?['pet_id']) == id)
        .toList();
    await _health.deleteAll(healthKeys);
  }

  // ── Weight records ─────────────────────────────────────

  Future<int> insertWeightRecord(WeightRecordModel record) async {
    final meta = Hive.box(_metaBox);
    final nextId = (meta.get('nextWeightId') as int? ?? 1);
    await meta.put('nextWeightId', nextId + 1);
    final data = record.toMap()..['id'] = nextId;
    await _weights.put(nextId, data);
    return nextId;
  }

  Future<List<WeightRecordModel>> getWeightRecords(int petId) async {
    final records = _weights.values
        .map((v) => WeightRecordModel.fromMap(Map<String, dynamic>.from(v)))
        .where((r) => r.petId == petId)
        .toList();
    records.sort((a, b) => b.date.compareTo(a.date));
    return records;
  }

  Future<void> deleteWeightRecord(int id) async {
    await _weights.delete(id);
  }

  // ── Health records ─────────────────────────────────────

  Future<int> insertHealthRecord(HealthRecordModel record) async {
    final meta = Hive.box(_metaBox);
    final nextId = (meta.get('nextHealthId') as int? ?? 1);
    await meta.put('nextHealthId', nextId + 1);
    final data = record.toMap()..['id'] = nextId;
    await _health.put(nextId, data);
    return nextId;
  }

  Future<List<HealthRecordModel>> getHealthRecords(int petId,
      {HealthRecordType? type}) async {
    final records = _health.values
        .map((v) => HealthRecordModel.fromMap(Map<String, dynamic>.from(v)))
        .where((r) => r.petId == petId)
        .where((r) => type == null || r.type == type)
        .toList();
    records.sort((a, b) => b.date.compareTo(a.date));
    return records;
  }

  Future<void> deleteHealthRecord(int id) async {
    await _health.delete(id);
  }
}
