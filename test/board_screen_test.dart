import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gift_exchange/core/i18n.dart';
import 'package:gift_exchange/features/auth/auth_controller.dart';
import 'package:gift_exchange/features/board/board_providers.dart';
import 'package:gift_exchange/features/board/board_screen.dart';
import 'package:gift_exchange/features/dashboard/dashboard_providers.dart';
import 'package:gift_exchange/features/forum/forum_providers.dart';
import 'package:gift_exchange/features/messages/messages_providers.dart';
import 'package:gift_exchange/models/forum.dart';
import 'package:gift_exchange/models/board.dart';
import 'package:gift_exchange/models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Same shape as GET /boards/{level_id} (backend/app/schemas/board_schema.py).
Map<String, dynamic> boardJson({required int levelId, String name = 'Bronze'}) => {
      'level_id': levelId,
      'level_name': name,
      'amount': '50.00',
      'cycle_id': 'c1',
      'cycle_number': 3,
      'confirmed_count': 2,
      'required_contributors': 6,
      'center': {
        'id': 'center',
        'full_name': 'Rosalie Longname Example',
        'invite_code': 'GIFT-1',
        'strikes_count': 1,
        'has_active_dispute': false,
        'member_since': '2026-10-20T10:00:00',
      },
      'next_in_line': {'id': 'next', 'full_name': 'Ngunza Asha', 'invite_code': 'GIFT-2', 'member_since': '2026-10-21T10:00:00'},
      'contributors': [
        {'user_id': 'a', 'full_name': 'Chery Fritz', 'status': 'IN_LINE', 'donation_status': 'CONFIRMED', 'provider_used': 'ZELLE'},
        {
          'user_id': 'b',
          'full_name': 'Ngunza Asha',
          'status': 'PENDING',
          'donation_status': 'PENDING_CONFIRMATION',
          'kind': 'SUPPORT_SHARE',
          'receiver_id': 'owner',
          'provider_used': 'VIRTUAL_CURRENCY',
          'transaction_ref': 'TX-0001-VERY-LONG-REFERENCE',
          'proof_image_url': 'data:image/png;base64,AAAA',
          'sent_at': DateTime.now().toUtc().subtract(const Duration(hours: 2)).toIso8601String(),
        },
        {'user_id': 'c', 'full_name': 'Lolo', 'status': 'PENDING', 'donation_status': 'DISPUTED'},
        {'user_id': 'owner', 'full_name': 'RealBoss', 'status': 'PENDING', 'donation_status': 'CONFIRMED', 'kind': 'SUPPORT_FUNDING'},
      ],
    };

final line = [
  QueueEntry.fromJson({'id': 'q1', 'user_id': 'center', 'full_name': 'Rosalie Longname Example', 'queue_position': 1, 'status': 'CENTER', 'joined_at': '2026-10-20T10:00:00', 'received_count': 2}),
  QueueEntry.fromJson({'id': 'q2', 'user_id': 'next', 'full_name': 'Ngunza Asha', 'queue_position': 2, 'status': 'WAITING', 'joined_at': '2026-10-21T10:00:00'}),
  QueueEntry.fromJson({'id': 'q3', 'user_id': 'a', 'full_name': 'Chery Fritz', 'queue_position': 120, 'status': 'IN_LINE', 'joined_at': '2026-10-22T10:00:00'}),
];

final pending = [
  PendingMember.fromJson({'user_id': 'p1', 'full_name': 'New Member', 'stage': 'NEEDS_REFERRALS', 'referral_count': 1}),
  PendingMember.fromJson({'user_id': 'p2', 'full_name': 'Ready One', 'stage': 'AWAITING_PAYMENT'}),
  PendingMember.fromJson({'user_id': 'p3', 'full_name': 'Paid One', 'stage': 'AWAITING_CONFIRMATION'}),
];

class _SignedIn extends AuthController {
  @override
  AuthState build() => AuthState(
        AuthStatus.signedIn,
        User.fromJson({'id': 'center', 'full_name': 'Rosalie Longname Example', 'referral_count': 2}),
      );
}

Future<void> pumpBoard(WidgetTester tester, {required int levelId, required String language}) async {
  SharedPreferences.setMockInitialValues({'tge-lang': language});
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authProvider.overrideWith(_SignedIn.new),
        showLineRanksProvider.overrideWith((ref) async => true),
        supportCasesProvider.overrideWith((ref) async => []),
        forumNotificationsProvider.overrideWith((ref) async => const ForumNotifications(0, [])),
        boardProvider.overrideWith((ref, id) async => Board.fromJson(boardJson(levelId: id))),
        boardLineProvider.overrideWith((ref, id) async => line),
        boardPendingProvider.overrideWith((ref, id) async => pending),
      ],
      child: MaterialApp(home: BoardScreen(levelId: levelId)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('reads the board sent by the API', () {
    final board = Board.fromJson(boardJson(levelId: 1));
    expect(board.amount, 50);
    expect(board.center!.name, 'Rosalie Longname Example');
    expect(board.nextInLine!.name, 'Ngunza Asha');
    expect(board.contributors, hasLength(4));
    expect(board.contributors[1].isPending, isTrue);
    expect(board.contributors[1].hasProof, isTrue);
    expect(board.contributors[3].isFromSupport, isTrue);
    expect(board.emptySlots, 2);
    expect(board.centerHasDispute, isTrue, reason: 'a disputed gift pauses the Center');
  });

  for (final language in supportedLanguages) {
    for (final levelId in [1, 8]) {
      testWidgets('$language / level $levelId: people, line and pending shown, no overflow at 320 px', (tester) async {
        tester.view.physicalSize = const Size(320, 4000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await pumpBoard(tester, levelId: levelId, language: language);

        expect(tester.takeException(), isNull);
        expect(find.text('CHERY FRITZ'), findsWidgets);
        expect(find.text('NGUNZA ASHA'), findsWidgets);
        expect(find.text('ROSALIE LONGNAME EXAMPLE'), findsWidgets);
        expect(find.text('#120'), findsOneWidget);
        // The Pending list is shown on the Bronze board only, like the website
        expect(find.text('NEW MEMBER'), levelId == 1 ? findsOneWidget : findsNothing);

        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}
