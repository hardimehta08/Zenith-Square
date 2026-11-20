import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> expectNoOverflowAtPhoneSizes(
  WidgetTester tester,
  Widget Function() buildScreen, {
  String? screenName,
}) async {
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  tester.view.devicePixelRatio = 1;

  for (final size in [
    const Size(320, 568),
    const Size(360, 800),
    const Size(400, 840),
  ]) {
    tester.view.physicalSize = size;
    await tester.pumpWidget(buildScreen());
    await tester.pump(const Duration(milliseconds: 100));
    final exception = tester.takeException();
    expect(
      exception,
      isNull,
      reason: '${screenName ?? 'Screen'} at $size: $exception',
    );
  }
}
