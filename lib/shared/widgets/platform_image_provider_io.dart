import 'dart:io';

import 'package:flutter/widgets.dart';

ImageProvider<Object> imageProviderFor(String source) {
  final uri = Uri.tryParse(source);
  if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
    return NetworkImage(source);
  }
  return FileImage(File(source));
}
