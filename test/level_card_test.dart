import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gift_exchange/core/i18n.dart';
import 'package:gift_exchange/features/dashboard/level_card.dart';
import 'package:gift_exchange/models/level.dart';
import 'package:gift_exchange/models/user.dart';
import 'package:gift_exchange/theme/gemstone.dart';
import 'package:shared_preferences/shared_preferences.dart';

Level level({String? status, int order = 8, int? received, int? position}) => Level.fromJson({
      'id': order,
      'name': 'Master Diamond',
      'amount': '20000.00',
      'required_contributors': 6,
      'display_order': order,
      'user_status': status,
      'received_count': received,
      'queue_position': position,
    });

Future<void> pumpCard(WidgetTester tester, Level item, {required String language, bool qualified = true}) async {
  SharedPreferences.setMockInitialValues({'tge-lang': language});
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Consumer(
              builder: (context, ref, _) {
                ref.watch(languageProvider);
                return LevelCard(
                  level: item,
                  qualified: qualified,
                  showRanks: true,
                  selected: false,
                  onSelect: () {},
                  onAction: () {},
                );
              },
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Level', () {
    test('reads the decimal amount sent as text', () {
      expect(level().amount, 20000);
    });

    test('the Center receives 5 of the 6 gifts', () {
      expect(level().centerGifts, 5);
      expect(level().centerPayout, 100000);
    });

    test('Bronze is never locked, the others follow the status', () {
      expect(level(order: 1, status: 'LOCKED').isLocked(qualified: false), isFalse);
      expect(level(order: 2, status: 'UNLOCKED').isLocked(qualified: false), isTrue);
      expect(level(order: 2, status: 'LOCKED').isLocked(qualified: true), isTrue);
      expect(level(order: 2, status: 'UNLOCKED').isLocked(qualified: true), isFalse);
    });

    test('received never goes past the cycle', () {
      expect(level(received: 9).received, 6);
    });
  });

  test('the 8 levels have their own colors', () {
    expect(gemstones.map((g) => g.id), [1, 2, 3, 4, 5, 6, 7, 8]);
    expect(gemstones.map((g) => g.accent).toSet().length, 8);
    expect(gemstoneFor(1).accent, const Color(0xFFD97706));
    expect(gemstoneFor(8).accent, const Color(0xFFF43F5E));
  });

  test('amounts use a thousands separator', () {
    expect(formatAmount(50), '50');
    expect(formatAmount(1000), '1,000');
    expect(formatAmount(100000), '100,000');
  });

  test('qualification and initials', () {
    User user(int referrals, {String name = 'Real Boss Junior'}) => User.fromJson({
          'id': '1',
          'full_name': name,
          'referral_count': referrals,
        });
    expect(user(1).isQualified, isFalse);
    expect(user(2).isQualified, isTrue);
    expect(user(0).initials, 'RB');
    expect(user(0, name: ' ').initials, '?');
  });

  group('No overflow on a 320 px phone', () {
    for (final language in supportedLanguages) {
      for (final status in [null, 'LOCKED', 'IN_LINE', 'CENTER', 'COMPLETED']) {
        testWidgets('$language / $status', (tester) async {
          tester.view.physicalSize = const Size(320, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);

          await pumpCard(tester, level(status: status, received: 3, position: 12), language: language);

          expect(tester.takeException(), isNull);
          expect(find.textContaining('Master Diamond'), findsWidgets);
        });
      }
    }
  });
}
