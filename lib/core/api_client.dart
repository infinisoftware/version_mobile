import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'config.dart';
import 'i18n.dart';

const _tokenKey = 'gifting_matrix_token';

class TokenStore {
  const TokenStore(this._storage);

  final FlutterSecureStorage _storage;

  Future<String?> read() => _storage.read(key: _tokenKey);
  Future<void> write(String token) => _storage.write(key: _tokenKey, value: token);
  Future<void> clear() => _storage.delete(key: _tokenKey);
}

final tokenStoreProvider = Provider((ref) => const TokenStore(FlutterSecureStorage()));

/// Called when the server answers 401: the session is over (expired, blocked account).
final sessionExpiredProvider = NotifierProvider<SessionExpired, int>(SessionExpired.new);

class SessionExpired extends Notifier<int> {
  @override
  int build() => 0;

  void signal() => state++;
}

final apiBaseUrlProvider = Provider((ref) => AppConfig.apiBaseUrl);

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ref.watch(apiBaseUrlProvider),
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await ref.read(tokenStoreProvider).read();
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        // The backend answers errors and system messages in this language
        options.headers['Accept-Language'] = ref.read(languageProvider);
        handler.next(options);
      },
      onError: (error, handler) {
        final isLogin = error.requestOptions.path.endsWith('/auth/login');
        if (error.response?.statusCode == 401 && !isLogin) {
          ref.read(sessionExpiredProvider.notifier).signal();
        }
        handler.next(error);
      },
    ),
  );

  return dio;
});

/// The server's message when it sent one, otherwise [fallback].
String apiErrorMessage(Object error, String fallback) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['detail'] is String) return data['detail'] as String;
  }
  return fallback;
}
