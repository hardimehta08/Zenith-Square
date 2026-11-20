import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/community/add_tenant_screen.dart';
import 'package:frontend/features/core/verify_otp_screen.dart';
import 'package:frontend/main.dart';

import 'support/overflow_test_helpers.dart';

void main() {
  testWidgets('all registered screens fit common phone viewports', (
    tester,
  ) async {
    for (final route in MyApp.routes.keys) {
      await expectNoOverflowAtPhoneSizes(
        tester,
        () => MyApp(initialRoute: route),
        screenName: route,
      );
    }
  });

  testWidgets('standalone screens fit common phone viewports', (tester) async {
    await expectNoOverflowAtPhoneSizes(
      tester,
      () => const MaterialApp(home: AddTenantScreen()),
      screenName: 'AddTenantScreen',
    );
    await expectNoOverflowAtPhoneSizes(
      tester,
      () => const MaterialApp(
        home: VerifyOtpScreen(email: 'resident@example.com'),
      ),
      screenName: 'VerifyOtpScreen',
    );
  });
}
