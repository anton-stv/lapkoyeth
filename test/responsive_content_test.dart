import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapkoyeth/shared/widgets/responsive_content.dart';

void main() {
  testWidgets('responsive content bounds desktop child width', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1600, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ResponsiveContent(
            maxWidth: 520,
            child: SizedBox.expand(key: Key('content')),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byKey(const Key('content'))).width, 520);
  });
}
