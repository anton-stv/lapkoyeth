import 'package:flutter/material.dart';

import 'platform_image_provider_stub.dart'
    if (dart.library.io) 'platform_image_provider_io.dart'
    if (dart.library.html) 'platform_image_provider_web.dart'
    as platform;

class PlatformImage extends StatelessWidget {
  const PlatformImage({
    super.key,
    required this.source,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.errorBuilder,
  });

  final String source;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  @override
  Widget build(BuildContext context) {
    return Image(
      image: platform.imageProviderFor(source),
      width: width,
      height: height,
      fit: fit,
      errorBuilder:
          errorBuilder ??
          (_, _, _) => Container(
            width: width,
            height: height,
            color: const Color(0xFFF0E8E2),
            alignment: Alignment.center,
            child: const Icon(Icons.broken_image_outlined),
          ),
    );
  }
}
