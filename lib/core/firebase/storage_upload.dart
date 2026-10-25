import 'package:firebase_storage/firebase_storage.dart';

import 'storage_upload_stub.dart'
    if (dart.library.io) 'storage_upload_io.dart'
    if (dart.library.html) 'storage_upload_web.dart'
    as platform;

Future<TaskSnapshot> uploadLocalFile(Reference reference, String path) =>
    platform.uploadLocalFile(reference, path);
