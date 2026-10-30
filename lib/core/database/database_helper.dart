import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../models/health_record_model.dart';
import '../../models/checklist_model.dart';
import '../../models/notification_event_model.dart';
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
  static const _checklistsBox = 'checklists';
  static const _notificationsBox = 'notification_events';

  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<Map>(_usersBox);
    await Hive.openBox<Map>(_petsBox);
    await Hive.openBox<Map>(_weightBox);
    await Hive.openBox<Map>(_healthBox);
    await Hive.openBox<Map>(_checklistsBox);
    await Hive.openBox<Map>(_notificationsBox);
    await Hive.openBox(_metaBox);
    await _cleanupLegacySeedData();
  }

  Future<void> _cleanupLegacySeedData() async {
    final meta = Hive.box(_metaBox);
    if (meta.get('legacySeedCleaned') == true) return;
    for (final key in _users.keys.toList()) {
      final raw = _users.get(key);
      if (raw == null) continue;
      final user = UserModel.fromMap(Map<String, dynamic>.from(raw));
      if (user.email == 'admin@test.ru' &&
          user.firstName == 'Тест' &&
          user.lastName == 'Юзер') {
        await deleteUserAccount(user.id!);
      }
    }
    await meta.put('seeded', false);
    await meta.put('legacySeedCleaned', true);
  }

  Box<Map> get _users => Hive.box<Map>(_usersBox);
  Box<Map> get _pets => Hive.box<Map>(_petsBox);
  Box<Map> get _weights => Hive.box<Map>(_weightBox);
  Box<Map> get _health => Hive.box<Map>(_healthBox);
  Box<Map> get _checklists => Hive.box<Map>(_checklistsBox);
  Box<Map> get _notifications => Hive.box<Map>(_notificationsBox);

  // ── Users ──────────────────────────────────────────────

  Future<int> insertUser(UserModel user) async {
    final meta = Hive.box(_metaBox);
    final nextId = (meta.get('nextUserId') as int? ?? 1);
    await meta.put('nextUserId', nextId + 1);
    final data = user.toMap()..['id'] = nextId;
    await _users.put(nextId, data);
    await _writeCloud('private_profile', 'current', _privateProfileMap(data));
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
    await _writeCloud(
      'private_profile',
      'current',
      _privateProfileMap(user.toMap()),
    );
  }

  Future<void> deleteUserAccount(int userId) async {
    final petIds = _pets.values
        .map((v) => PetModel.fromMap(Map<String, dynamic>.from(v)))
        .where((p) => p.ownerId == userId && p.id != null)
        .map((p) => p.id!)
        .toList();
    for (final petId in petIds) {
      await deletePet(petId);
    }
    await _users.delete(userId);
  }

  // ── Pets ───────────────────────────────────────────────

  Future<int> insertPet(PetModel pet) async {
    final meta = Hive.box(_metaBox);
    final nextId = (meta.get('nextPetId') as int? ?? 1);
    await meta.put('nextPetId', nextId + 1);
    final data = pet.toMap()..['id'] = nextId;
    await _pets.put(nextId, data);
    await _writeCloud('private_pets', '$nextId', data);
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
    await _writeCloud('private_pets', '${pet.id}', pet.toMap());
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
    final checklistKeys = _checklists.keys
        .where((k) => (_checklists.get(k)?['pet_id']) == id)
        .toList();
    await _checklists.deleteAll(checklistKeys);
    await _deleteCloud('private_pets', '$id');
    for (final key in weightKeys) {
      await _deleteCloud('private_weights', '$key');
    }
    for (final key in healthKeys) {
      await _deleteCloud('private_health', '$key');
    }
    for (final key in checklistKeys) {
      await _deleteCloud('private_checklists', '$key');
    }
  }

  // ── Checklists ────────────────────────────────────────

  Future<int> insertChecklist(ChecklistModel checklist) async {
    final meta = Hive.box(_metaBox);
    final nextId = (meta.get('nextChecklistId') as int? ?? 1);
    await meta.put('nextChecklistId', nextId + 1);
    final data = checklist.toMap()..['id'] = nextId;
    await _checklists.put(nextId, data);
    await _writeCloud('private_checklists', '$nextId', data);
    return nextId;
  }

  Future<List<ChecklistModel>> getChecklistsForPet(int petId) async {
    final checklists = _checklists.values
        .map((v) => ChecklistModel.fromMap(Map<String, dynamic>.from(v)))
        .where((c) => c.petId == petId)
        .toList();
    checklists.sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
    return checklists;
  }

  Future<List<ChecklistModel>> getChecklistsForPets(List<int> petIds) async {
    final allowed = petIds.toSet();
    final checklists = _checklists.values
        .map((v) => ChecklistModel.fromMap(Map<String, dynamic>.from(v)))
        .where((c) => allowed.contains(c.petId))
        .toList();
    checklists.sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
    return checklists;
  }

  Future<void> updateChecklist(ChecklistModel checklist) async {
    if (checklist.id == null) return;
    await _checklists.put(checklist.id, checklist.toMap());
    await _writeCloud(
      'private_checklists',
      '${checklist.id}',
      checklist.toMap(),
    );
  }

  Future<void> deleteChecklist(int id) async {
    await _checklists.delete(id);
    await _deleteCloud('private_checklists', '$id');
  }

  // ── Notification events ────────────────────────────────

  List<NotificationEvent> getNotificationEvents(String ownerUid) =>
      _notifications.values
          .map(
            (value) =>
                NotificationEvent.fromMap(Map<String, dynamic>.from(value)),
          )
          .where((event) => event.ownerUid == ownerUid)
          .toList();

  Future<void> saveNotificationEvent(NotificationEvent event) async {
    final ownerUid = event.ownerUid;
    if (ownerUid == null) return;
    await _notifications.put('$ownerUid::${event.id}', event.toMap());
    await _writeCloud('private_notifications', event.id, event.toMap());
  }

  Future<void> deleteNotificationEvent(String ownerUid, String id) async {
    await _notifications.delete('$ownerUid::$id');
    await _deleteCloud('private_notifications', id);
  }

  Future<void> clearNotificationEvents(String ownerUid) async {
    final keys = _notifications.keys
        .where((key) => key.toString().startsWith('$ownerUid::'))
        .toList();
    await _notifications.deleteAll(keys);
  }

  // ── Weight records ─────────────────────────────────────

  Future<int> insertWeightRecord(WeightRecordModel record) async {
    final meta = Hive.box(_metaBox);
    final nextId = (meta.get('nextWeightId') as int? ?? 1);
    await meta.put('nextWeightId', nextId + 1);
    final data = record.toMap()..['id'] = nextId;
    await _weights.put(nextId, data);
    await _writeCloud('private_weights', '$nextId', data);
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
    await _deleteCloud('private_weights', '$id');
  }

  // ── Health records ─────────────────────────────────────

  Future<int> insertHealthRecord(HealthRecordModel record) async {
    final meta = Hive.box(_metaBox);
    final nextId = (meta.get('nextHealthId') as int? ?? 1);
    await meta.put('nextHealthId', nextId + 1);
    final data = record.toMap()..['id'] = nextId;
    await _health.put(nextId, data);
    await _writeCloud('private_health', '$nextId', data);
    return nextId;
  }

  Future<List<HealthRecordModel>> getHealthRecords(
    int petId, {
    HealthRecordType? type,
  }) async {
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
    await _deleteCloud('private_health', '$id');
  }

  // ── Stories ────────────────────────────────────────────

  Future<Set<String>> getViewedStoryIds(String ownerUid) async {
    final raw = Hive.box(_metaBox).get('viewedStoryIds_$ownerUid');
    if (raw is! List) return <String>{};
    return raw.whereType<String>().toSet();
  }

  Future<void> markStoriesViewed(
    String ownerUid,
    Iterable<String> storyIds,
  ) async {
    final next = await getViewedStoryIds(ownerUid);
    next.addAll(storyIds.where((id) => id.isNotEmpty));
    await Hive.box(_metaBox).put('viewedStoryIds_$ownerUid', next.toList());
    await _writeCloud('private_state', 'stories', {
      'viewed_story_ids': next.toList(),
    });
  }

  Future<void> clearViewedStories(String ownerUid) =>
      Hive.box(_metaBox).delete('viewedStoryIds_$ownerUid');

  /// Merges the signed-in user's private Firestore data into the local Hive
  /// cache and uploads records that only exist on this device.
  Future<void> syncCloudForUser(String uid, int localUserId) async {
    if (Firebase.apps.isEmpty ||
        FirebaseAuth.instance.currentUser?.uid != uid) {
      return;
    }

    await _syncBox(
      uid: uid,
      collection: 'private_pets',
      box: _pets,
      localEntries: _pets.toMap().entries.where((entry) {
        final map = Map<String, dynamic>.from(entry.value);
        return map['owner_id'] == localUserId;
      }),
      normalize: (map, id) => map
        ..['id'] = int.parse(id)
        ..['owner_id'] = localUserId,
      nextIdKey: 'nextPetId',
    );

    final petIds = (await getPetsByOwner(
      localUserId,
    )).where((pet) => pet.id != null).map((pet) => pet.id!).toSet();
    await _syncBox(
      uid: uid,
      collection: 'private_weights',
      box: _weights,
      localEntries: _weights.toMap().entries.where(
        (entry) => petIds.contains(entry.value['pet_id']),
      ),
      nextIdKey: 'nextWeightId',
    );
    await _syncBox(
      uid: uid,
      collection: 'private_health',
      box: _health,
      localEntries: _health.toMap().entries.where(
        (entry) => petIds.contains(entry.value['pet_id']),
      ),
      nextIdKey: 'nextHealthId',
    );
    await _syncBox(
      uid: uid,
      collection: 'private_checklists',
      box: _checklists,
      localEntries: _checklists.toMap().entries.where(
        (entry) => petIds.contains(entry.value['pet_id']),
      ),
      nextIdKey: 'nextChecklistId',
    );
    await _syncBox(
      uid: uid,
      collection: 'private_notifications',
      box: _notifications,
      localEntries: _notifications.toMap().entries.where(
        (entry) => entry.value['owner_uid'] == uid,
      ),
      normalize: (map, id) => map..['owner_uid'] = uid,
      remoteKey: (id) => '$uid::$id',
    );

    final stories = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('private_state')
        .doc('stories')
        .get();
    final storyIds = stories.data()?['viewed_story_ids'];
    if (storyIds is List) {
      await Hive.box(
        _metaBox,
      ).put('viewedStoryIds_$uid', storyIds.whereType<String>().toList());
    }
  }

  Future<void> _syncBox({
    required String uid,
    required String collection,
    required Box<Map> box,
    required Iterable<MapEntry<dynamic, Map>> localEntries,
    Map<String, dynamic> Function(Map<String, dynamic>, String)? normalize,
    Object Function(String)? remoteKey,
    String? nextIdKey,
  }) async {
    try {
      final reference = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection(collection);
      final snapshot = await reference.get();
      final remoteIds = snapshot.docs.map((doc) => doc.id).toSet();

      for (final doc in snapshot.docs) {
        final map = Map<String, dynamic>.from(doc.data());
        final normalized = normalize?.call(map, doc.id) ?? map;
        final key = remoteKey?.call(doc.id) ?? int.tryParse(doc.id) ?? doc.id;
        await box.put(key, normalized);
      }

      for (final entry in localEntries) {
        final id = entry.key.toString().split('::').last;
        if (remoteIds.contains(id)) continue;
        await reference
            .doc(id)
            .set(
              Map<String, dynamic>.from(entry.value),
              SetOptions(merge: true),
            );
      }

      if (nextIdKey != null) {
        final numericIds = <int>[
          ...box.keys.map((key) => int.tryParse('$key')).whereType<int>(),
          ...snapshot.docs.map((doc) => int.tryParse(doc.id)).whereType<int>(),
        ];
        if (numericIds.isNotEmpty) {
          final next = numericIds.reduce((a, b) => a > b ? a : b) + 1;
          final meta = Hive.box(_metaBox);
          final current = meta.get(nextIdKey) as int? ?? 1;
          if (next > current) await meta.put(nextIdKey, next);
        }
      }
    } catch (_) {
      // Hive remains the offline source when Firebase is unreachable.
    }
  }

  Future<void> _writeCloud(
    String collection,
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      if (Firebase.apps.isEmpty) return;
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection(collection)
          .doc(id)
          .set(data, SetOptions(merge: true));
    } catch (_) {
      // Local writes remain available offline and sync on the next login.
    }
  }

  Future<void> _deleteCloud(String collection, String id) async {
    try {
      if (Firebase.apps.isEmpty) return;
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection(collection)
          .doc(id)
          .delete();
    } catch (_) {}
  }

  Map<String, dynamic> _privateProfileMap(Map<String, dynamic> source) {
    final result = Map<String, dynamic>.from(source);
    result.remove('password_hash');
    result.remove('id');
    return result;
  }
}
