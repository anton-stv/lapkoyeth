import 'package:firebase_core/firebase_core.dart';

/// Public Firebase client configuration for the registered Web application.
///
/// Firebase API keys identify the project; authorization is enforced by Auth,
/// Firestore rules, App Check and Storage rules rather than by hiding this data.
abstract final class FirebaseWebOptions {
  static const current = FirebaseOptions(
    apiKey: 'AIzaSyAFAEcG9fAe2QRvk3RLcuCj-srvPKM53oM',
    appId: '1:48071134608:web:264ab970a319aabc157715',
    messagingSenderId: '48071134608',
    projectId: 'lapkoyeth',
    authDomain: 'lapkoyeth.firebaseapp.com',
    storageBucket: 'lapkoyeth.firebasestorage.app',
    measurementId: 'G-3Q6RT5CSGV',
  );
}
