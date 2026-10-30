import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'core/database/database_helper.dart';
import 'core/firebase/firebase_messaging_service.dart';
import 'core/firebase/firebase_web_options.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: kIsWeb ? FirebaseWebOptions.current : null,
  );
  await DatabaseHelper.instance.init();
  if (!kIsWeb) {
    FirebaseMessagingService.registerBackgroundHandler();
    await FirebaseMessagingService.instance.init();
  }
  runApp(const ProviderScope(child: LapkoyethApp()));
}

class LapkoyethApp extends ConsumerWidget {
  const LapkoyethApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'ЛапкойЭть',
      theme: AppTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('ru'), Locale('en')],
    );
  }
}
