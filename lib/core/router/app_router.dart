import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/chat/screens/chat_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/pets/screens/pets_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/services/screens/services_screen.dart';
import '../../shared/widgets/main_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = RouterRefreshNotifier(ref);

  return GoRouter(
    initialLocation: '/home',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isLoggedIn = authState.valueOrNull != null;
      final isAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsCenterScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/pets',
            builder: (context, state) => const PetsScreen(),
          ),
          GoRoute(
            path: '/calendar',
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/chat',
            builder: (context, state) => const ChatScreen(),
          ),
          GoRoute(
            path: '/services',
            builder: (context, state) => const ServicesScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
});

class RouterRefreshNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterRefreshNotifier(this._ref) {
    _ref.listen(authStateProvider, (prev, next) => notifyListeners());
  }
}
