// The app's real login and data loading against a running backend (never production).
// Run from version_mobile/ with a test account of that backend:
//   E2E_API=http://127.0.0.1:8000/api/v1 E2E_LOGIN=... E2E_PASSWORD=... flutter test test_e2e
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gift_exchange/core/api_client.dart';
import 'package:gift_exchange/features/account/account_providers.dart';
import 'package:gift_exchange/features/auth/auth_controller.dart';
import 'package:gift_exchange/features/board/board_providers.dart';
import 'package:gift_exchange/features/dashboard/dashboard_providers.dart';
import 'package:gift_exchange/features/forum/forum_providers.dart';
import 'package:gift_exchange/features/messages/messages_providers.dart';
import 'package:gift_exchange/features/support/support_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MemoryTokenStore implements TokenStore {
  String? token;

  @override
  Future<String?> read() async => token;

  @override
  Future<void> write(String value) async => token = value;

  @override
  Future<void> clear() async => token = null;
}

void main() {
  final api = Platform.environment['E2E_API'];
  final identifier = Platform.environment['E2E_LOGIN'];
  final password = Platform.environment['E2E_PASSWORD'];

  test('login, then every screen loads', () async {
    if (api == null || api.contains('giftexchangeglobal.com')) {
      markTestSkipped('E2E_API is not set to a local backend');
      return;
    }
    if (identifier == null || password == null) {
      markTestSkipped('E2E_LOGIN and E2E_PASSWORD are not set');
      return;
    }
    SharedPreferences.setMockInitialValues({});
    final store = MemoryTokenStore();
    final container = ProviderContainer(overrides: [
      apiBaseUrlProvider.overrideWithValue(api),
      tokenStoreProvider.overrideWithValue(store),
    ]);
    addTearDown(container.dispose);

    container.read(authProvider);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await container.read(authProvider.notifier).login(identifier, password);
    final user = container.read(authProvider).user!;
    expect(container.read(authProvider).status, AuthStatus.signedIn);
    expect(store.token, isNotEmpty);
    print('signed in: ${user.fullName} <${user.email}>');

    final levels = await container.read(levelsProvider.future);
    expect(levels, hasLength(8));
    await container.read(showLineRanksProvider.future);
    for (final level in levels) {
      await container.read(boardProvider(level.id).future);
      await container.read(boardLineProvider(level.id).future);
    }
    await container.read(boardPendingProvider(1).future);
    final posts = await container.read(forumPostsProvider.future);
    if (posts.isNotEmpty) await container.read(forumPostProvider(posts.first.id).future);
    await container.read(forumNotificationsProvider.future);
    final tickets = await container.read(supportTicketsProvider.future);
    if (tickets.isNotEmpty) await container.read(supportMessagesProvider(tickets.first.id).future);
    final cases = await container.read(supportCasesProvider.future);
    if (cases.isNotEmpty) await container.read(disputeMessagesProvider(cases.first.id).future);
    await container.read(paymentMethodsProvider.future);
    await container.read(sponsorNameProvider.future);
    await container.read(boardHistoryProvider.future);
    await container.read(mySignaturesProvider.future);
    print('loaded: ${levels.length} levels, ${posts.length} posts, ${tickets.length} tickets, ${cases.length} cases');

    // Restarting the app: the saved session signs in again on its own
    final restarted = ProviderContainer(overrides: [
      apiBaseUrlProvider.overrideWithValue(api),
      tokenStoreProvider.overrideWithValue(store),
    ]);
    addTearDown(restarted.dispose);
    restarted.read(authProvider);
    for (var i = 0; i < 50 && restarted.read(authProvider).status == AuthStatus.loading; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    expect(restarted.read(authProvider).status, AuthStatus.signedIn);
  });
}
