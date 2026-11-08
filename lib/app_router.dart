import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/auth/auth_controller.dart';
import 'features/auth/login_screen.dart';
import 'features/board/board_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/forum/forum_post_screen.dart';
import 'features/forum/forum_screen.dart';
import 'features/account/account_screen.dart';
import 'features/messages/conversation_screen.dart';
import 'features/messages/messages_screen.dart';
import 'features/shell/app_shell.dart';
import 'features/support/new_ticket_screen.dart';
import 'features/support/support_screen.dart';
import 'features/support/ticket_screen.dart';
import 'theme/app_colors.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authChanges = ValueNotifier(0);
  ref.listen(authProvider, (_, _) => authChanges.value++);
  ref.onDispose(authChanges.dispose);

  return GoRouter(
    initialLocation: '/dashboard',
    refreshListenable: authChanges,
    redirect: (context, state) {
      final status = ref.read(authProvider).status;
      final location = state.matchedLocation;
      if (status == AuthStatus.loading) return location == '/splash' ? null : '/splash';
      if (status == AuthStatus.signedOut) return location == '/login' ? null : '/login';
      return location == '/login' || location == '/splash' ? '/dashboard' : null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const Scaffold(
          body: Center(child: CircularProgressIndicator(color: AppColors.action)),
        ),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      // Opened from the top-bar icon of every tab: full screen, above the tab bar
      GoRoute(path: '/messages', builder: (context, state) => const MessagesScreen()),
      GoRoute(
        path: '/messages/:donationId',
        builder: (context, state) => ConversationScreen(donationId: state.pathParameters['donationId']!),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardScreen(),
                routes: [
                  GoRoute(
                    path: 'board/:levelId',
                    builder: (context, state) =>
                        BoardScreen(levelId: int.parse(state.pathParameters['levelId']!)),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/forum',
                builder: (context, state) => const ForumScreen(),
                routes: [
                  GoRoute(
                    path: 'post/:postId',
                    builder: (context, state) => ForumPostScreen(postId: state.pathParameters['postId']!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/support',
                builder: (context, state) => const SupportScreen(),
                routes: [
                  GoRoute(path: 'new', builder: (context, state) => const NewTicketScreen()),
                  GoRoute(
                    path: 'ticket/:ticketId',
                    builder: (context, state) => TicketScreen(ticketId: state.pathParameters['ticketId']!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/account', builder: (context, state) => const AccountScreen())],
          ),
        ],
      ),
    ],
  );
});
