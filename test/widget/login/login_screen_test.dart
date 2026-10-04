import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/features/login/login_screen.dart';

import '../../helpers/localized_app.dart';

void main() {
  group('LoginScreen server URL validation', () {
    testWidgets('rejects http:// with a clear blocking error', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: localizedApp(home: const LoginScreen()),
        ),
      );
      await tester.pump();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Server URL'),
        'http://paperless.example.com',
      );
      await tester.pump();

      final formState = tester.state<FormState>(find.byType(Form));
      expect(formState.validate(), false);
      await tester.pump();

      expect(
        find.text(
          'This app requires https:// — plain http:// connections '
          'are blocked. Put your server behind a reverse proxy or '
          'Tailscale Serve for a valid HTTPS address.',
        ),
        findsOneWidget,
      );
      expect(
        find.text('http:// is blocked by this app — use https:// instead'),
        findsOneWidget,
      );
    });

    testWidgets('accepts https:// with no error', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: localizedApp(home: const LoginScreen()),
        ),
      );
      await tester.pump();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Server URL'),
        'https://paperless.example.com',
      );
      await tester.pump();

      final formState = tester.state<FormState>(find.byType(Form));
      // Other required fields (username/password) are still empty, so the
      // form as a whole is invalid — but no http:// error should appear.
      formState.validate();
      await tester.pump();

      expect(
        find.text('http:// is blocked by this app — use https:// instead'),
        findsNothing,
      );
    });
  });
}
