import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_helper.dart';
import '../../../models/user_model.dart';
import '../../community/community_repository.dart';

// Текущий авторизованный пользователь
final authStateProvider = AsyncNotifierProvider<AuthNotifier, UserModel?>(
  AuthNotifier.new,
);

class AuthNotifier extends AsyncNotifier<UserModel?> {
  final _auth = firebase_auth.FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  Future<UserModel?> build() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null || firebaseUser.email == null) return null;
    return _localUserForFirebaseUser(firebaseUser);
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        final credential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        return _localUserForFirebaseUser(credential.user);
      } on firebase_auth.FirebaseAuthException catch (error) {
        throw Exception(_loginErrorMessage(error.code));
      }
    });
  }

  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      late final firebase_auth.UserCredential credential;
      try {
        credential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      } on firebase_auth.FirebaseAuthException catch (error) {
        throw Exception(_registrationErrorMessage(error.code));
      }
      await credential.user?.updateDisplayName('$firstName $lastName'.trim());

      final user = await _localUserForFirebaseUser(
        credential.user,
        firstName: firstName,
        lastName: lastName,
      );
      if (credential.user != null) {
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'firstName': firstName,
          'lastName': lastName,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      return user;
    });
  }

  Future<void> logout() async {
    await _auth.signOut();
    state = const AsyncData(null);
  }

  Future<void> updateUser(UserModel updated) async {
    final current = state.valueOrNull;
    final existing = await DatabaseHelper.instance.getUserByEmail(
      updated.email,
    );
    if (existing != null && existing.id != current?.id) {
      throw Exception('Email уже зарегистрирован');
    }
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      if (updated.email != firebaseUser.email) {
        throw Exception('Смену email подключим отдельным подтверждением');
      }
      await firebaseUser.updateDisplayName(
        '${updated.firstName} ${updated.lastName}'.trim(),
      );
    }
    await DatabaseHelper.instance.updateUser(updated);
    await CommunityRepository.instance.publishUser(updated);
    state = AsyncData(updated);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) throw Exception('Не авторизован');
    final credential = firebase_auth.EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }

  Future<void> deleteAccount() async {
    final user = state.valueOrNull;
    if (user?.id == null) throw Exception('Не авторизован');
    try {
      await CommunityRepository.instance.deleteCurrentPublicData();
    } catch (_) {}
    await DatabaseHelper.instance.deleteUserAccount(user!.id!);
    final currentUid = _auth.currentUser?.uid;
    if (currentUid != null) {
      await DatabaseHelper.instance.clearViewedStories(currentUid);
      await DatabaseHelper.instance.clearNotificationEvents(currentUid);
    }
    await _auth.currentUser?.delete();
    state = const AsyncData(null);
  }

  Future<UserModel> _localUserForFirebaseUser(
    firebase_auth.User? firebaseUser, {
    String? firstName,
    String? lastName,
  }) async {
    final email = firebaseUser?.email;
    if (email == null) throw Exception('Не удалось получить email');

    final existing = await DatabaseHelper.instance.getUserByEmail(email);
    if (existing != null) {
      final restored = await _restoreCloudProfile(existing);
      await DatabaseHelper.instance.updateUser(restored);
      await DatabaseHelper.instance.syncCloudForUser(
        firebaseUser!.uid,
        restored.id!,
      );
      try {
        await CommunityRepository.instance.publishUser(restored);
      } catch (_) {}
      return restored;
    }

    final displayName = firebaseUser?.displayName?.trim();
    final parts = displayName == null || displayName.isEmpty
        ? const <String>[]
        : displayName.split(RegExp(r'\s+'));
    final cloudProfile = await _cloudProfile();
    final user = UserModel(
      firstName:
          firstName ??
          cloudProfile?['first_name'] as String? ??
          (parts.isNotEmpty ? parts.first : ''),
      lastName:
          lastName ??
          cloudProfile?['last_name'] as String? ??
          (parts.length > 1 ? parts.skip(1).join(' ') : ''),
      email: email,
      passwordHash: '',
      city: cloudProfile?['city'] as String?,
      phone: cloudProfile?['phone'] as String?,
      dateOfBirth: cloudProfile?['date_of_birth'] as String?,
      gender: cloudProfile?['gender'] as String?,
      photoPath: cloudProfile?['photo_path'] as String?,
      bio: cloudProfile?['bio'] as String?,
      profilePublic: cloudProfile?['profile_public'] as bool? ?? true,
      petsPublic: cloudProfile?['pets_public'] as bool? ?? true,
    );

    final id = await DatabaseHelper.instance.insertUser(user);
    final saved = user.copyWith(id: id);
    await DatabaseHelper.instance.syncCloudForUser(firebaseUser!.uid, id);
    try {
      await CommunityRepository.instance.publishUser(saved);
    } catch (_) {}
    return saved;
  }

  Future<Map<String, dynamic>?> _cloudProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('private_profile')
          .doc('current')
          .get();
      return snapshot.data();
    } catch (_) {
      return null;
    }
  }

  Future<UserModel> _restoreCloudProfile(UserModel local) async {
    final cloud = await _cloudProfile();
    if (cloud == null) return local;
    return local.copyWith(
      firstName: cloud['first_name'] as String?,
      lastName: cloud['last_name'] as String?,
      city: cloud['city'],
      phone: cloud['phone'],
      dateOfBirth: cloud['date_of_birth'],
      gender: cloud['gender'],
      photoPath: cloud['photo_path'],
      bio: cloud['bio'],
      profilePublic: cloud['profile_public'] as bool?,
      petsPublic: cloud['pets_public'] as bool?,
    );
  }

  String _loginErrorMessage(String code) => switch (code) {
    'invalid-credential' ||
    'wrong-password' ||
    'user-not-found' => 'Неверный email или пароль',
    'invalid-email' => 'Проверьте правильность email',
    'user-disabled' => 'Этот аккаунт заблокирован',
    'too-many-requests' => 'Слишком много попыток. Попробуйте позже',
    'network-request-failed' => 'Нет соединения с интернетом',
    _ => 'Не удалось войти. Попробуйте ещё раз',
  };

  String _registrationErrorMessage(String code) => switch (code) {
    'email-already-in-use' => 'Этот email уже зарегистрирован',
    'invalid-email' => 'Проверьте правильность email',
    'weak-password' => 'Пароль слишком простой',
    'operation-not-allowed' => 'Регистрация временно недоступна',
    'too-many-requests' => 'Слишком много попыток. Попробуйте позже',
    'network-request-failed' => 'Нет соединения с интернетом',
    _ => 'Не удалось зарегистрироваться. Попробуйте ещё раз',
  };
}
