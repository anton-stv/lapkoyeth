import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';

import '../../../core/database/database_helper.dart';
import '../../../models/user_model.dart';

// Текущий авторизованный пользователь
final authStateProvider =
    AsyncNotifierProvider<AuthNotifier, UserModel?>(AuthNotifier.new);

class AuthNotifier extends AsyncNotifier<UserModel?> {
  @override
  Future<UserModel?> build() async => null;

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = await DatabaseHelper.instance.getUserByEmail(email);
      if (user == null) throw Exception('Пользователь не найден');

      final hash = _hashPassword(password);
      if (user.passwordHash != hash) throw Exception('Неверный пароль');

      return user;
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
      final existing = await DatabaseHelper.instance.getUserByEmail(email);
      if (existing != null) throw Exception('Email уже зарегистрирован');

      final user = UserModel(
        firstName: firstName,
        lastName: lastName,
        email: email,
        passwordHash: _hashPassword(password),
      );

      final id = await DatabaseHelper.instance.insertUser(user);
      return user.copyWith(id: id);
    });
  }

  Future<void> logout() async {
    state = const AsyncData(null);
  }

  String _hashPassword(String password) =>
      sha256.convert(utf8.encode(password)).toString();
}
