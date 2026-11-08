import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gift_exchange/core/dates.dart';
import 'package:gift_exchange/core/i18n.dart';
import 'package:gift_exchange/features/auth/auth_controller.dart';
import 'package:gift_exchange/features/forum/forum_post_screen.dart';
import 'package:gift_exchange/features/forum/forum_providers.dart';
import 'package:gift_exchange/features/forum/forum_screen.dart';
import 'package:gift_exchange/features/forum/forum_widgets.dart';
import 'package:gift_exchange/features/messages/messages_providers.dart';
import 'package:gift_exchange/features/support/new_ticket_screen.dart';
import 'package:gift_exchange/features/support/support_providers.dart';
import 'package:gift_exchange/features/support/support_screen.dart';
import 'package:gift_exchange/features/support/ticket_screen.dart';
import 'package:gift_exchange/models/forum.dart';
import 'package:gift_exchange/models/support.dart';
import 'package:gift_exchange/models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

const longName = 'averyveryverylongusername_with_no_spaces_at_all';

Map<String, dynamic> comment(String id, {String? parent, String author = 'lolo'}) => {
      'id': id,
      'post_id': 'p1',
      'parent_comment_id': parent,
      'author_id': 'u-$author',
      'author_name': author,
      'author_username': author,
      'content': 'Comment $id @rosalie',
      'likes_count': 1,
      'liked_by_me': id == 'c1',
      'created_at': '2026-11-06T10:00:00',
    };

final post = ForumPost.fromJson({
  'id': 'p1',
  'author_id': 'me',
  'author_name': longName,
  'author_username': longName,
  'level_badge': 'Communauté',
  'content': "🎉 RealBoss vient de prendre sa place dans la matrice The Gift Exchange Global ! Bienvenue dans la communauté 🙌",
  'likes_count': 12,
  'liked_by_me': true,
  'comments_count': 4,
  'comments': [comment('c1'), comment('c2', parent: 'c1'), comment('c3', parent: 'c2', author: longName), comment('c4')],
  'created_at': '2026-11-06T09:00:00',
});

final ticket = SupportTicket.fromJson({
  'id': 't1',
  'user_id': 'me',
  'user_name': 'Me',
  'user_email': 'me@example.com',
  'category': 'MOYENS_PAIEMENT',
  'subject': 'My crypto wallet address is refused when I add it to my profile',
  'priority': 'URGENTE',
  'status': 'ANSWERED',
  'created_at': '2026-11-05T09:00:00',
  'updated_at': '2026-11-06T09:00:00',
  'messages_count': 2,
  'last_message_preview': 'We checked your address, the network was wrong.',
});

final messages = [
  SupportMessage.fromJson({'id': 'm1', 'ticket_id': 't1', 'sender_id': 'me', 'sender_name': longName, 'sender_role': 'MEMBER', 'message': 'Hello, it does not work.', 'created_at': '2026-11-05T09:00:00'}),
  SupportMessage.fromJson({'id': 'm2', 'ticket_id': 't1', 'sender_id': 'mod', 'sender_name': 'Support team', 'sender_role': 'SUPPORT_ADMIN', 'message': 'We checked your address, the network was wrong.', 'created_at': '2026-11-06T09:00:00'}),
];

class _SignedIn extends AuthController {
  @override
  AuthState build() => AuthState(AuthStatus.signedIn, User.fromJson({'id': 'me', 'full_name': longName}));
}

Future<void> pump(WidgetTester tester, Widget screen, String language) async {
  tester.view.physicalSize = const Size(320, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({'tge-lang': language});
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authProvider.overrideWith(_SignedIn.new),
        forumPostsProvider.overrideWith((ref) async => [post, post]),
        forumPostProvider.overrideWith((ref, id) async => post),
        forumNotificationsProvider.overrideWith(
          (ref) async => ForumNotifications.fromJson({
            'unread_count': 120,
            'items': [
              {'id': 'n1', 'actor_name': longName, 'notif_type': 'REPLY_COMMENT', 'post_id': 'p1', 'preview_text': 'Hi', 'is_read': false, 'created_at': '2026-11-06T09:00:00'},
            ],
          }),
        ),
        supportTicketsProvider.overrideWith((ref) async => [ticket]),
        supportCasesProvider.overrideWith((ref) async => []),
        supportMessagesProvider.overrideWith((ref, id) async => messages),
      ],
      child: MaterialApp(home: screen),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('replies are grouped under their top-level comment, even a reply to a reply', () {
    final threads = groupThreads(post.comments);
    expect(threads.map((t) => t.$1.id), ['c1', 'c4']);
    expect(threads.first.$2.map((c) => c.id), ['c2', 'c3']);
    expect(threads.last.$2, isEmpty);
  });

  test('community posts stored in French are shown in the reader language', () {
    String en(String a, String b, String c) => a;
    String es(String a, String b, String c) => c;
    expect(localizeForumText(post.content, en), startsWith('🎉 RealBoss just took their place'));
    expect(localizeForumText(post.content, es), startsWith('🎉 ¡RealBoss acaba de tomar su lugar'));
    const gift = "💸 lolo vient de donner \$50 à l'équipe Support (Bronze) 🙌";
    expect(localizeForumText(gift, en), "💸 lolo just gave \$50 to the Support team (Bronze) 🙌");
    expect(localizeForumText('Hello', en), 'Hello');
    expect(post.isCommunity, isTrue);
  });

  test('API dates without a timezone are read as UTC', () {
    expect(parseApiDate('2026-11-06T09:00:00').toUtc().hour, 9);
    expect(parseApiDate('2026-11-06T09:00:00Z').toUtc().hour, 9);
    expect(parseApiDate('2026-11-06T09:00:00+02:00').toUtc().hour, 7);
  });

  for (final language in supportedLanguages) {
    group('$language at 320 px, no overflow', () {
      testWidgets('forum feed', (tester) async {
        await pump(tester, const ForumScreen(), language);
        expect(tester.takeException(), isNull);
        expect(find.text('99+'), findsOneWidget);
        await tester.tap(find.byTooltip(language == 'es' ? 'Notificaciones' : 'Notifications'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });

      testWidgets('forum post with threads', (tester) async {
        await pump(tester, const ForumPostScreen(postId: 'p1'), language);
        expect(tester.takeException(), isNull);
        expect(find.textContaining('Comment c3'), findsOneWidget);
        expect(find.byTooltip(language == 'en' ? 'Delete' : language == 'fr' ? 'Supprimer' : 'Eliminar'), findsOneWidget);
      });

      testWidgets('support list, new request and conversation', (tester) async {
        await pump(tester, const SupportScreen(), language);
        expect(tester.takeException(), isNull);
        expect(find.textContaining('crypto wallet'), findsOneWidget);

        await pump(tester, const NewTicketScreen(), language);
        expect(tester.takeException(), isNull);

        await pump(tester, const TicketScreen(ticketId: 't1'), language);
        expect(tester.takeException(), isNull);
        expect(find.textContaining('network was wrong'), findsWidgets);
        await tester.pumpWidget(const SizedBox());
      });
    });
  }
}
