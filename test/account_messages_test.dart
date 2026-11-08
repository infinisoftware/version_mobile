import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gift_exchange/core/crypto.dart';
import 'package:gift_exchange/core/i18n.dart';
import 'package:gift_exchange/features/account/account_providers.dart';
import 'package:gift_exchange/features/account/account_screen.dart';
import 'package:gift_exchange/features/account/payment_method_sheet.dart';
import 'package:gift_exchange/features/auth/auth_controller.dart';
import 'package:gift_exchange/features/forum/forum_providers.dart';
import 'package:gift_exchange/features/messages/conversation_screen.dart';
import 'package:gift_exchange/features/messages/messages_providers.dart';
import 'package:gift_exchange/features/messages/messages_screen.dart';
import 'package:gift_exchange/models/account.dart';
import 'package:gift_exchange/models/dispute.dart';
import 'package:gift_exchange/models/forum.dart';
import 'package:gift_exchange/models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

const longName = 'Averyveryverylongfirstname Withaverylonglastname';

User member({bool admin = false}) => User.fromJson({
      'id': 'me',
      'full_name': longName,
      'username': 'averyveryverylongusername_no_spaces',
      'email': 'averyveryverylongemailaddress@giftexchangeglobal.com',
      'phone': '+509 37833690',
      'whatsapp': '+509 37833690',
      'invite_code': 'GIFT-ABC123',
      'referral_count': 2,
      'is_admin': admin,
      'is_owner': admin,
      'email_verified': true,
      'strikes_count': 1,
      'country': 'Haiti',
      'member_since': '2026-10-20T10:00:00',
    });

SupportCase supportCase(String id, {required String status, String donor = 'me', String receiver = 'other', int unread = 0}) =>
    SupportCase.fromJson({
      'id': id,
      'cycle_id': 'c',
      'level_id': 8,
      'level_name': 'Master Diamond',
      'donor_id': donor,
      'donor_name': longName,
      'receiver_id': receiver,
      'receiver_name': 'Rosalie Receiver Longname',
      'amount': '20000.00',
      'provider_used': 'VIRTUAL_CURRENCY',
      'status': status,
      'sent_at': '2026-11-06T09:00:00',
      'my_role': donor == 'me' ? 'DONOR' : 'RECEIVER',
      'messages_count': 3,
      'unread_count': unread,
      'remaining_seconds': 3600 * 5 + 60 * 7,
      'kind': 'SUPPORT_SHARE',
    });

final cases = [
  supportCase('d1', status: 'PENDING_CONFIRMATION', unread: 2),
  supportCase('d2', status: 'CONFIRMED'),
  supportCase('d3', status: 'DISPUTED', donor: 'other', receiver: 'me', unread: 5),
];

final messages = [
  DisputeMessage.fromJson({'id': 'm0', 'donation_id': 'd1', 'sender_name': 'System', 'sender_role': 'SYSTEM', 'message': 'Dispute opened.', 'created_at': '2026-11-06T09:00:00'}),
  DisputeMessage.fromJson({'id': 'm1', 'donation_id': 'd1', 'sender_id': 'me', 'sender_name': longName, 'sender_role': 'DONOR', 'message': 'I paid yesterday.', 'created_at': '2026-11-06T09:01:00'}),
  DisputeMessage.fromJson({'id': 'm2', 'donation_id': 'd1', 'sender_id': 'mod', 'sender_name': 'Moderator', 'sender_role': 'MODERATOR', 'message': 'Checking.', 'created_at': '2026-11-06T09:02:00'}),
];

class _SignedIn extends AuthController {
  _SignedIn(this.user);

  final User user;

  @override
  AuthState build() => AuthState(AuthStatus.signedIn, user);
}

Future<void> pump(WidgetTester tester, Widget screen, String language, {bool admin = false}) async {
  tester.view.physicalSize = const Size(320, 3600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({'tge-lang': language});
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authProvider.overrideWith(() => _SignedIn(member(admin: admin))),
        supportCasesProvider.overrideWith((ref) async => cases),
        disputeMessagesProvider.overrideWith((ref, id) async => messages),
        forumNotificationsProvider.overrideWith((ref) async => const ForumNotifications(3, [])),
        paymentMethodsProvider.overrideWith(
          (ref) async => [
            PaymentMethod.fromJson({'id': 'p1', 'provider_type': 'VIRTUAL_CURRENCY', 'details': {'currency': 'USDT', 'network': 'TRC20', 'wallet_address': 'TXyzVeryLongWalletAddressThatGoesOnAndOn1234'}}),
            PaymentMethod.fromJson({'id': 'p2', 'provider_type': 'BANK', 'details': {'bank_name': 'Banque Nationale de Crédit', 'account_number': '1234567890123', 'routing_number': 'BNCHHTPP', 'account_holder': longName}}),
          ],
        ),
        sponsorNameProvider.overrideWith((ref) async => 'RealBoss'),
        boardHistoryProvider.overrideWith(
          (ref) async => [
            BoardHistoryItem.fromJson({'cycle_id': 'c1', 'level_id': 8, 'level_name': 'Master Diamond', 'amount': '20000', 'role': 'CENTER', 'status': 'CENTER', 'received_count': 3, 'date': '2026-11-01T00:00:00'}),
            BoardHistoryItem.fromJson({'cycle_id': 'c2', 'level_id': 1, 'level_name': 'Bronze', 'amount': '50', 'role': 'CENTER', 'status': 'COMPLETED', 'received_count': 6, 'date': '2026-10-01T00:00:00'}),
          ],
        ),
        mySignaturesProvider.overrideWith(
          (ref) async => [
            LegalAcceptance.fromJson({'id': 's1', 'document_type': 'TERMS', 'document_version': '1.2', 'accepted_at': '2026-10-30T10:00:00', 'context': 'UPDATE', 'signer_name': longName, 'signer_email': 'x@y.z', 'ip_address': '2a02:8429:1234:5678:90ab:cdef:1234:5678'}),
          ],
        ),
      ],
      child: MaterialApp(home: screen),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('crypto address check, same rules as the website', () {
    String en(String a, String b, String c) => a;
    expect(cryptoAddressError('TRC20', 'T${'a' * 33}', en), isNull);
    expect(cryptoAddressError('TRC20', '0x1234', en), contains('TRC20'));
    expect(cryptoAddressError('ERC20', '0x${'a' * 40}', en), isNull);
    expect(cryptoAddressError('BITCOIN', 'bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh', en), isNull);
    expect(cryptoAddressError('SOLANA', '', en), 'Enter your wallet address.');
    expect(networksByCurrency['ETH'], ['ERC20']);
  });

  test('the messages badge adds up the unread messages of every conversation', () async {
    final container = ProviderContainer(overrides: [supportCasesProvider.overrideWith((ref) async => cases)]);
    addTearDown(container.dispose);
    await container.read(supportCasesProvider.future);
    expect(container.read(unreadMessagesProvider), 7);
    // Disputes first, then gifts waiting for confirmation
    final sorted = [...cases]..sort((a, b) => b.priority.compareTo(a.priority));
    expect(sorted.map((c) => c.id), ['d3', 'd1', 'd2']);
  });

  for (final language in supportedLanguages) {
    group('$language at 320 px, no overflow', () {
      testWidgets('account (member and admin)', (tester) async {
        await pump(tester, const AccountScreen(), language);
        expect(tester.takeException(), isNull);
        expect(find.text('7'), findsOneWidget, reason: 'unread messages badge');
        expect(find.text('3'), findsWidgets, reason: 'forum notifications badge');
        expect(find.textContaining('GIFT-ABC123'), findsOneWidget);
        expect(find.textContaining('RealBoss', findRichText: true), findsOneWidget);

        await pump(tester, const AccountScreen(), language, admin: true);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });

      testWidgets('add a payment method', (tester) async {
        tester.view.physicalSize = const Size(320, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        SharedPreferences.setMockInitialValues({'tge-lang': language});
        await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: Scaffold(body: PaymentMethodSheet()))));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });

      testWidgets('messenger list and conversation', (tester) async {
        await pump(tester, const MessagesScreen(), language);
        expect(tester.takeException(), isNull);

        // Donor: remind and open a dispute; no confirm
        await pump(tester, const ConversationScreen(donationId: 'd1'), language);
        expect(tester.takeException(), isNull);
        expect(find.textContaining('1. '), findsOneWidget);
        expect(find.textContaining('2. '), findsOneWidget);
        expect(find.text('I paid yesterday.'), findsOneWidget);

        // Receiver of a disputed gift: only « Confirm », which asks for the word
        await pump(tester, const ConversationScreen(donationId: 'd3'), language);
        expect(find.textContaining('1. '), findsNothing);
        await tester.tap(find.text(language == 'en' ? 'Confirm' : language == 'fr' ? 'Confirmer' : 'Confirmar'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('confirm'), findsWidgets);
        await tester.pumpWidget(const SizedBox());
      });
    });
  }
}
