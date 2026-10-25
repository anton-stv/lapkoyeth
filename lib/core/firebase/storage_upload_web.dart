import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

Future<TaskSnapshot> uploadLocalFile(Reference reference, String path) async {
  final bytes = await XFile(path).readAsBytes();
  return reference.putData(bytes);
}
