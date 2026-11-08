// Play Store screenshots (1080x1920, 9:16) of the real screens, with fictional members only.
// Run from version_mobile/:  tool/make_store_captures.sh
// The images are written to google_play/images/captures/<language>/ (tool/make_store_captures.sh also
// removes their transparency, which the Play Console refuses).
// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:gift_exchange/core/i18n.dart';
import 'package:gift_exchange/features/account/account_providers.dart';
import 'package:gift_exchange/features/account/account_screen.dart';
import 'package:gift_exchange/features/auth/auth_controller.dart';
import 'package:gift_exchange/features/auth/login_screen.dart';
import 'package:gift_exchange/features/board/board_providers.dart';
import 'package:gift_exchange/features/board/board_screen.dart';
import 'package:gift_exchange/features/dashboard/dashboard_providers.dart';
import 'package:gift_exchange/features/dashboard/dashboard_screen.dart';
import 'package:gift_exchange/features/forum/forum_providers.dart';
import 'package:gift_exchange/features/forum/forum_screen.dart';
import 'package:gift_exchange/features/messages/conversation_screen.dart';
import 'package:gift_exchange/features/messages/messages_providers.dart';
import 'package:gift_exchange/features/support/support_providers.dart';
import 'package:gift_exchange/features/support/ticket_screen.dart';
import 'package:gift_exchange/models/account.dart';
import 'package:gift_exchange/models/board.dart';
import 'package:gift_exchange/models/dispute.dart';
import 'package:gift_exchange/models/forum.dart';
import 'package:gift_exchange/models/level.dart';
import 'package:gift_exchange/models/support.dart';
import 'package:gift_exchange/models/user.dart';
import 'package:gift_exchange/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

var lang = 'en';
String tr(String en, String fr, String es) => switch (lang) { 'fr' => fr, 'es' => es, _ => en };

String ago(Duration d) => DateTime.now().toUtc().subtract(d).toIso8601String();

final me = User.fromJson({
  'id': 'me',
  'full_name': 'Marie Laurent',
  'username': 'marie_l',
  'email': 'marie.laurent@example.com',
  'phone': '+1 3055550142',
  'whatsapp': '+1 3055550142',
  'invite_code': 'GIFT-DEMO42',
  'referral_count': 2,
  'email_verified': true,
  'country': 'United States',
  'member_since': '2026-10-20T10:00:00',
});

final levels = [
  for (final (id, name, amount, status, received, position) in [
    (1, 'Bronze', 50, 'COMPLETED', 6, null),
    (2, 'Silver', 150, 'CENTER', 3, 1),
    (3, 'Gold', 500, 'IN_LINE', 0, 4),
    (4, 'Platinum', 1000, 'UNLOCKED', 0, null),
    (5, 'Master', 3000, 'LOCKED', 0, null),
    (6, 'Titanium', 5000, 'LOCKED', 0, null),
    (7, 'Diamond', 10000, 'LOCKED', 0, null),
    (8, 'Master Diamond', 20000, 'LOCKED', 0, null),
  ])
    Level.fromJson({
      'id': id,
      'name': name,
      'amount': '$amount',
      'required_contributors': 6,
      'display_order': id,
      'user_status': status,
      'received_count': received,
      'queue_position': position,
    }),
];

final board = Board.fromJson({
  'level_id': 2,
  'level_name': 'Silver',
  'amount': '150.00',
  'confirmed_count': 3,
  'required_contributors': 6,
  'center': {'id': 'me', 'full_name': 'Marie Laurent', 'invite_code': 'x', 'member_since': '2026-10-20T10:00:00'},
  'next_in_line': {'id': 'u2', 'full_name': 'Jean Baptiste', 'invite_code': 'x', 'member_since': '2026-10-21T10:00:00'},
  'contributors': [
    {'user_id': 'u3', 'full_name': 'Sofia Ramirez', 'status': 'IN_LINE', 'donation_status': 'CONFIRMED', 'provider_used': 'ZELLE'},
    {'user_id': 'u4', 'full_name': 'David Chen', 'status': 'IN_LINE', 'donation_status': 'CONFIRMED', 'kind': 'SUPPORT_SHARE', 'provider_used': 'CASHAPP'},
    {'user_id': 'u5', 'full_name': 'Amina Diallo', 'status': 'IN_LINE', 'donation_status': 'CONFIRMED', 'provider_used': 'VIRTUAL_CURRENCY'},
    {
      'user_id': 'u6',
      'full_name': 'Lucas Martin',
      'status': 'PENDING',
      'donation_status': 'PENDING_CONFIRMATION',
      'receiver_id': 'me',
      'provider_used': 'ZELLE',
      'proof_image_url': 'data:image/png;base64,AA',
      'sent_at': ago(const Duration(hours: 2, minutes: 14)),
    },
  ],
});

final line = [
  for (final (i, name, received) in [(1, 'Marie Laurent', 3), (2, 'Jean Baptiste', 0), (3, 'Sofia Ramirez', 0), (4, 'David Chen', 0), (5, 'Amina Diallo', 0)])
    QueueEntry.fromJson({
      'id': 'q$i',
      'user_id': 'u$i',
      'full_name': name,
      'queue_position': i,
      'status': i == 1 ? 'CENTER' : 'IN_LINE',
      'joined_at': '2026-10-20T10:00:00',
      'received_count': received,
    }),
];

List<ForumPost> get posts => [
  ForumPost.fromJson({
    'id': 'p1',
    'author_id': 'u3',
    'author_name': 'Sofia Ramirez',
    'author_username': 'sofia_r',
    'level_badge': 'Général',
    'content': tr('Just confirmed my 3rd gift on Silver. Thank you @marie_l for the quick confirmation, the 24h timer really keeps everyone honest!', "Mon 3e don sur Silver vient d'être confirmé. Merci @marie_l pour la confirmation rapide, le délai de 24 h garde tout le monde honnête !", 'Acaban de confirmar mi 3.er regalo en Silver. ¡Gracias @marie_l por confirmar tan rápido, el plazo de 24 h mantiene a todos honestos!'),
    'likes_count': 14,
    'liked_by_me': true,
    'comments_count': 5,
    'comments': [],
    'created_at': ago(const Duration(minutes: 42)),
  }),
  ForumPost.fromJson({
    'id': 'p2',
    'author_id': 'sys',
    'author_name': 'The Gift Exchange',
    'author_username': 'TheGiftExchange',
    'level_badge': 'Communauté',
    'content': '🎉 Amina Diallo vient de prendre sa place dans la matrice The Gift Exchange Global ! Bienvenue dans la communauté 🙌',
    'likes_count': 22,
    'liked_by_me': false,
    'comments_count': 8,
    'comments': [],
    'created_at': ago(const Duration(hours: 3)),
  }),
  ForumPost.fromJson({
    'id': 'p3',
    'author_id': 'u2',
    'author_name': 'Jean Baptiste',
    'author_username': 'jean_b',
    'level_badge': 'Général',
    'content': tr('Tip for newcomers: add your receiving methods in Account before you reach the Center, so your donors can pay you right away.', 'Conseil aux nouveaux : ajoutez vos moyens de réception dans Compte avant d’arriver au Centre, pour que vos donateurs puissent vous payer tout de suite.', 'Consejo para los nuevos: añade tus medios de cobro en Cuenta antes de llegar al Centro, así tus donantes pueden pagarte enseguida.'),
    'likes_count': 9,
    'liked_by_me': false,
    'comments_count': 2,
    'comments': [],
    'created_at': ago(const Duration(days: 1)),
  }),
];

final cases = [
  SupportCase.fromJson({
    'id': 'd1',
    'level_id': 2,
    'level_name': 'Silver',
    'donor_id': 'u6',
    'donor_name': 'Lucas Martin',
    'receiver_id': 'me',
    'receiver_name': 'Marie Laurent',
    'amount': '150',
    'provider_used': 'ZELLE',
    'status': 'PENDING_CONFIRMATION',
    'sent_at': ago(const Duration(hours: 2, minutes: 14)),
    'messages_count': 3,
    'unread_count': 1,
    'remaining_seconds': 21 * 3600 + 46 * 60,
  }),
];

List<DisputeMessage> get disputeMessages => [
  DisputeMessage.fromJson({'id': 'm1', 'sender_id': 'u6', 'sender_name': 'Lucas Martin', 'sender_role': 'DONOR', 'message': tr('Hi Marie, I sent the \$150 by Zelle a few minutes ago. Reference ZL-58213.', "Bonjour Marie, je t'ai envoyé les 150 \$ par Zelle il y a quelques minutes. Référence ZL-58213.", 'Hola Marie, te envié los 150 \$ por Zelle hace unos minutos. Referencia ZL-58213.'), 'created_at': ago(const Duration(hours: 2))}),
  DisputeMessage.fromJson({'id': 'm2', 'sender_id': 'me', 'sender_name': 'Marie Laurent', 'sender_role': 'RECEIVER', 'message': tr('Thanks Lucas! I am checking my account and will confirm right after.', 'Merci Lucas ! Je vérifie mon compte et je confirme juste après.', '¡Gracias Lucas! Reviso mi cuenta y confirmo enseguida.'), 'created_at': ago(const Duration(hours: 1, minutes: 50))}),
];

SupportTicket get ticket => SupportTicket.fromJson({
  'id': 't1',
  'category': 'MOYENS_PAIEMENT',
  'subject': tr('Which network for my USDT wallet?', 'Quel réseau pour mon portefeuille USDT ?', '¿Qué red para mi billetera USDT?'),
  'priority': 'NORMALE',
  'status': 'ANSWERED',
  'created_at': ago(const Duration(hours: 5)),
  'updated_at': ago(const Duration(hours: 4)),
  'messages_count': 2,
});

List<SupportMessage> get ticketMessages => [
  SupportMessage.fromJson({'id': 's1', 'sender_id': 'me', 'sender_name': 'Marie Laurent', 'sender_role': 'MEMBER', 'message': tr('Hello, my wallet is on Tron. Which network should I choose when I add it?', 'Bonjour, mon portefeuille est sur Tron. Quel réseau dois-je choisir en l’ajoutant ?', 'Hola, mi billetera está en Tron. ¿Qué red debo elegir al añadirla?'), 'created_at': ago(const Duration(hours: 5))}),
  SupportMessage.fromJson({'id': 's2', 'sender_name': tr('Support team', 'Équipe Support', 'Equipo de Soporte'), 'sender_role': 'SUPPORT_ADMIN', 'message': tr('Hi Marie, choose USDT then TRC20 (Tron). The app checks the address format before saving it.', "Bonjour Marie, choisissez USDT puis TRC20 (Tron). L'application vérifie le format de l'adresse avant de l'enregistrer.", 'Hola Marie, elige USDT y luego TRC20 (Tron). La aplicación revisa el formato de la dirección antes de guardarla.'), 'created_at': ago(const Duration(hours: 4))}),
];

class _SignedIn extends AuthController {
  @override
  AuthState build() => AuthState(AuthStatus.signedIn, me);
}

List<Override> get overrides => [
  authProvider.overrideWith(_SignedIn.new),
  levelsProvider.overrideWith((ref) async => levels),
  showLineRanksProvider.overrideWith((ref) async => true),
  boardProvider.overrideWith((ref, id) async => board),
  boardLineProvider.overrideWith((ref, id) async => line),
  boardPendingProvider.overrideWith((ref, id) async => const <PendingMember>[]),
  forumPostsProvider.overrideWith((ref) async => posts),
  forumNotificationsProvider.overrideWith((ref) async => const ForumNotifications(3, [])),
  supportCasesProvider.overrideWith((ref) async => cases),
  disputeMessagesProvider.overrideWith((ref, id) async => disputeMessages),
  supportTicketsProvider.overrideWith((ref) async => [ticket]),
  supportMessagesProvider.overrideWith((ref, id) async => ticketMessages),
  paymentMethodsProvider.overrideWith(
    (ref) async => [
      PaymentMethod.fromJson({'id': 'pm1', 'provider_type': 'ZELLE', 'details': {'email_or_phone': 'marie.laurent@example.com', 'recipient_name': 'Marie Laurent'}}),
      PaymentMethod.fromJson({'id': 'pm2', 'provider_type': 'VIRTUAL_CURRENCY', 'details': {'currency': 'USDT', 'network': 'TRC20', 'wallet_address': 'TDemoWalletAddress0000000000000000'}}),
    ],
  ),
  sponsorNameProvider.overrideWith((ref) async => 'Jean Baptiste'),
  boardHistoryProvider.overrideWith((ref) async => const <BoardHistoryItem>[]),
  mySignaturesProvider.overrideWith((ref) async => const <LegalAcceptance>[]),
];

Future<void> loadFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final path in paths) {
    loader.addFont(File(path).readAsBytes().then((bytes) => ByteData.view(bytes.buffer)));
  }
  await loader.load();
}

void main() {
  setUpAll(() async {
    await loadFont('PlusJakartaSans', [for (final w in [400, 500, 600, 700, 800]) 'assets/fonts/PlusJakartaSans-$w.ttf']);
    final flutterRoot = Platform.environment['FLUTTER_ROOT'] ?? '/Users/kikipllc/development/flutter';
    await loadFont('MaterialIcons', ['$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf']);
    // On a phone the system draws emoji and « ᵉ »; here they come from these fonts
    await loadFont('NotoSans', ['test_store/fonts/NotoSans.ttf']);
    await loadFont('NotoSansSymbols2', ['test_store/fonts/NotoSansSymbols2.ttf']);
    await loadFont('NotoColorEmoji', ['test_store/fonts/NotoColorEmoji.ttf']);
  });

  ThemeData theme() {
    final base = buildAppTheme();
    const fallback = ['NotoSans', 'NotoSansSymbols2', 'NotoColorEmoji'];
    return base.copyWith(
      textTheme: base.textTheme.apply(fontFamilyFallback: fallback),
      primaryTextTheme: base.primaryTextTheme.apply(fontFamilyFallback: fallback),
    );
  }

  final screens = <String, Widget>{
    '01_connexion': const LoginScreen(),
    '02_tableau_de_bord': const DashboardScreen(),
    '03_board': const BoardScreen(levelId: 2),
    '04_messagerie': const ConversationScreen(donationId: 'd1'),
    '05_forum': const ForumScreen(),
    '06_support': const TicketScreen(ticketId: 't1'),
    '07_compte': const AccountScreen(),
  };

  for (final language in supportedLanguages) {
    for (final entry in screens.entries) {
      testWidgets('$language ${entry.key}', (tester) async {
        tester.view.physicalSize = const Size(1080, 1920);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        SharedPreferences.setMockInitialValues({'tge-lang': language});
        lang = language;

        await tester.pumpWidget(
          ProviderScope(
            overrides: overrides,
            child: MaterialApp(debugShowCheckedModeBanner: false, theme: theme(), home: entry.value),
          ),
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('../google_play/images/captures/$language/${entry.key}.png'),
        );
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}
