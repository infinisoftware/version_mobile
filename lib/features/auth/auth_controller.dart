import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../models/user.dart';

enum AuthStatus { loading, signedOut, signedIn }

class AuthState {
  const AuthState(this.status, [this.user]);

  final AuthStatus status;
  final User? user;
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    ref.listen(sessionExpiredProvider, (_, _) => signOut());
    _restoreSession();
    return const AuthState(AuthStatus.loading);
  }

  Future<void> _restoreSession() async {
    final token = await ref.read(tokenStoreProvider).read();
    if (token == null) {
      state = const AuthState(AuthStatus.signedOut);
      return;
    }
    try {
      await refreshUser();
    } catch (_) {
      // No network at launch: back to the sign-in screen, the token stays for the next try
      if (state.status == AuthStatus.loading) state = const AuthState(AuthStatus.signedOut);
    }
  }

  Future<void> refreshUser() async {
    final response = await ref.read(dioProvider).get<Map<String, dynamic>>('/users/me');
    state = AuthState(AuthStatus.signedIn, User.fromJson(response.data!));
  }

  /// [identifier] is the email address or the username.
  Future<void> login(String identifier, String password) async {
    final response = await ref.read(dioProvider).post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': identifier.trim(), 'password': password},
    );
    final data = response.data!;
    await ref.read(tokenStoreProvider).write(data['access_token'] as String);
    state = AuthState(AuthStatus.signedIn, User.fromJson(data['user'] as Map<String, dynamic>));
  }

  Future<void> signOut() async {
    await ref.read(tokenStoreProvider).clear();
    state = const AuthState(AuthStatus.signedOut);
  }
}

final authProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);
