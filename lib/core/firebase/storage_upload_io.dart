import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

Future<TaskSnapshot> uploadLocalFile(Reference reference, String path) async {
  final file = File(path);
  if (!await file.exists()) {
    throw StateError('Selected media file is no longer available');
  }
  return reference.putFile(file);
}
