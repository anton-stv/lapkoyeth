import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../core/firebase/storage_upload.dart';
import '../../models/pet_model.dart';
import '../../models/user_model.dart';

class CommunityRepository {
  CommunityRepository._();
  static final instance = CommunityRepository._();

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _storage = FirebaseStorage.instance;

  String? get uid => _auth.currentUser?.uid;

  static List<String> buildSearchTokens(String firstName, String lastName) {
    final parts = [firstName, lastName]
        .map((value) => value.trim().toLowerCase())
        .where((value) => value.isNotEmpty)
        .toList();
    final values = <String>{...parts};
    if (parts.isNotEmpty) {
      values
        ..add(parts.join(' '))
        ..add(parts.reversed.join(' '));
    }

    final tokens = <String>{};
    for (final value in values) {
      for (var i = 1; i <= value.length; i++) {
        tokens.add(value.substring(0, i));
      }
    }
    return tokens.toList()..sort();
  }

  Future<String?> _upload(String? path, String destination) async {
    if (path == null || path.isEmpty || path.startsWith('http')) return path;
    final task = await uploadLocalFile(_storage.ref(destination), path);
    return task.ref.getDownloadURL();
  }

  Future<void> publishUser(UserModel user) async {
    final currentUid = uid;
    if (currentUid == null) return;
    String? photoUrl;
    try {
      photoUrl = await _upload(user.photoPath, 'users/$currentUid/avatar.jpg');
    } catch (_) {
      // The profile remains usable when Storage is unavailable.
    }
    final fullName = '${user.firstName} ${user.lastName}'.trim();
    final tokens = buildSearchTokens(user.firstName, user.lastName);
    await _firestore.collection('users').doc(currentUid).set({
      'firstName': user.firstName,
      'lastName': user.lastName,
      'displayName': fullName,
      'publicId': 'LP-${currentUid.substring(0, 8).toUpperCase()}',
      'bio': user.bio,
      'photoUrl': ?photoUrl,
      'searchTokens': tokens,
      'profilePublic': user.profilePublic,
      'petsPublic': user.petsPublic,
      // The community profile is public-facing; authentication contact data
      // must never be part of it.
      'email': FieldValue.delete(),
      'phone': FieldValue.delete(),
      'city': FieldValue.delete(),
      'gender': FieldValue.delete(),
      'dateOfBirth': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> publishPets(List<PetModel> pets) async {
    final currentUid = uid;
    if (currentUid == null) return;
    final collection = _firestore
        .collection('users')
        .doc(currentUid)
        .collection('pets');
    for (final pet in pets.where((pet) => pet.id != null)) {
      String? photoUrl;
      final photoUrls = <String>[];
      try {
        photoUrl = await _upload(
          pet.photoPath,
          'users/$currentUid/pets/${pet.id}/cover.jpg',
        );
        final galleryPaths = pet.photoPaths
            .where((path) => path != pet.photoPath)
            .toList();
        for (var index = 0; index < galleryPaths.length; index++) {
          final url = await _upload(
            galleryPaths[index],
            'users/$currentUid/pets/${pet.id}/gallery/$index.jpg',
          );
          if (url != null) photoUrls.add(url);
        }
      } catch (_) {}
      await collection.doc('${pet.id}').set({
        'name': pet.name,
        'breed': pet.breed,
        'gender': pet.gender,
        'dateOfBirth': pet.dateOfBirth,
        'about': pet.about,
        'photoUrl': ?photoUrl,
        'photoUrls': photoUrls,
        'isPublic': pet.isPublic,
        'createdOrder': pet.id,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  Future<void> deletePet(int petId) async {
    final currentUid = uid;
    if (currentUid == null) return;
    await _firestore
        .collection('users')
        .doc(currentUid)
        .collection('pets')
        .doc('$petId')
        .delete();
    try {
      await _storage.ref('users/$currentUid/pets/$petId/cover.jpg').delete();
    } catch (_) {}
  }

  Future<void> deleteCurrentPublicData() async {
    final currentUid = uid;
    if (currentUid == null) return;
    final userRef = _firestore.collection('users').doc(currentUid);
    final pets = await userRef.collection('pets').get();
    final requests = await _firestore
        .collection('friend_requests')
        .where('participants', arrayContains: currentUid)
        .get();
    final batch = _firestore.batch();
    for (final pet in pets.docs) {
      batch.delete(pet.reference);
    }
    for (final request in requests.docs) {
      batch.delete(request.reference);
    }
    batch.delete(userRef);
    await batch.commit();
    try {
      await _storage.ref('users/$currentUid').listAll().then((result) async {
        for (final item in result.items) {
          await item.delete();
        }
        for (final prefix in result.prefixes) {
          final nested = await prefix.listAll();
          for (final item in nested.items) {
            await item.delete();
          }
        }
      });
    } catch (_) {}
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> requests() {
    final currentUid = uid!;
    return _firestore
        .collection('friend_requests')
        .where('participants', arrayContains: currentUid)
        .snapshots();
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> search(
    String query,
  ) async {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return [];
    final publicId = query.trim().toUpperCase();
    final byId = await _firestore
        .collection('users')
        .where('publicId', isEqualTo: publicId)
        .where('profilePublic', isEqualTo: true)
        .limit(20)
        .get();
    final visibleById = byId.docs.where((doc) => doc.id != uid).toList();
    if (visibleById.isNotEmpty) return visibleById;

    final byName = await _firestore
        .collection('users')
        .where('searchTokens', arrayContains: normalized)
        .where('profilePublic', isEqualTo: true)
        .limit(20)
        .get();
    return byName.docs.where((doc) => doc.id != uid).toList();
  }

  Future<void> sendRequest(String toUid) async {
    final fromUid = uid!;
    final id = [fromUid, toUid]..sort();
    await _firestore.collection('friend_requests').doc(id.join('_')).set({
      'fromUid': fromUid,
      'toUid': toUid,
      'participants': [fromUid, toUid],
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setRequestStatus(String id, String status) => _firestore
      .collection('friend_requests')
      .doc(id)
      .update({'status': status, 'updatedAt': FieldValue.serverTimestamp()});

  Future<void> deleteConnection(String id) =>
      _firestore.collection('friend_requests').doc(id).delete();

  Future<DocumentSnapshot<Map<String, dynamic>>> user(String userId) async {
    final reference = _firestore.collection('users').doc(userId);
    try {
      return await reference.get(const GetOptions(source: Source.server));
    } catch (_) {
      return reference.get();
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> publicPets(String userId) =>
      _firestore
          .collection('users')
          .doc(userId)
          .collection('pets')
          .where('isPublic', isEqualTo: true)
          .snapshots();
}
