import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gift_exchange/core/i18n.dart';
import 'package:gift_exchange/features/auth/login_screen.dart';
import 'package:gift_exchange/features/shell/language_switcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final language in supportedLanguages) {
    testWidgets('$language: languages at the top, sign-up button visible, no overflow at 320 px', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({'tge-lang': language});

      await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: LoginScreen())));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      final switcher = tester.getRect(find.byType(LanguageSwitcher));
      expect(switcher.top, lessThan(60));
      expect(find.descendant(of: find.byType(AppBar), matching: find.byType(LanguageSwitcher)), findsOneWidget);

      final signUp = find.byType(OutlinedButton);
      await tester.scrollUntilVisible(signUp, 100, scrollable: find.byType(Scrollable).last);
      expect(signUp, findsOneWidget);
      expect(
        find.descendant(of: signUp, matching: find.textContaining(RegExp('Sign up|inscrire|Registrarse'))),
        findsOneWidget,
      );
    });
  }
}
