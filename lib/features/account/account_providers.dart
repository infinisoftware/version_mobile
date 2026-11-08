import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../models/account.dart';
import '../auth/auth_controller.dart';

final paymentMethodsProvider = FutureProvider.autoDispose<List<PaymentMethod>>((ref) async {
  final response = await ref.watch(dioProvider).get<List<dynamic>>('/users/me/payment-methods');
  return response.data!.map((item) => PaymentMethod.fromJson(item as Map<String, dynamic>)).toList();
});

/// The sponsor's name is only on the public profile.
final sponsorNameProvider = FutureProvider.autoDispose<String?>((ref) async {
  final userId = ref.watch(authProvider.select((state) => state.user?.id));
  if (userId == null) return null;
  final response = await ref.watch(dioProvider).get<Map<String, dynamic>>('/users/$userId/profile');
  final data = response.data!;
  final user = data['user'] as Map<String, dynamic>? ?? data;
  return user['sponsor_name'] as String? ?? (data['sponsor'] as Map<String, dynamic>?)?['full_name'] as String?;
});

final boardHistoryProvider = FutureProvider.autoDispose<List<BoardHistoryItem>>((ref) async {
  final userId = ref.watch(authProvider.select((state) => state.user?.id));
  if (userId == null) return const [];
  final response = await ref.watch(dioProvider).get<List<dynamic>>('/users/$userId/board-history');
  return response.data!.map((item) => BoardHistoryItem.fromJson(item as Map<String, dynamic>)).toList();
});

final mySignaturesProvider = FutureProvider.autoDispose<List<LegalAcceptance>>((ref) async {
  final response = await ref.watch(dioProvider).get<List<dynamic>>('/legal/my-acceptances');
  return response.data!.map((item) => LegalAcceptance.fromJson(item as Map<String, dynamic>)).toList();
});

class AccountActions {
  const AccountActions(this._ref);

  final Ref _ref;

  Future<void> updateMe(Map<String, String> changes) async {
    await _ref.read(dioProvider).put<void>('/users/me', data: changes);
    await _ref.read(authProvider.notifier).refreshUser();
  }

  Future<void> addPaymentMethod(String providerType, Map<String, String> details) =>
      _ref.read(dioProvider).post<void>(
        '/users/me/payment-methods',
        data: {'provider_type': providerType, 'details': details, 'is_active': true},
      );

  Future<void> deletePaymentMethod(String id) => _ref.read(dioProvider).delete<void>('/users/me/payment-methods/$id');

  /// The old invite link stops working.
  Future<void> refreshInviteCode() async {
    await _ref.read(dioProvider).post<void>('/users/me/invite-code/refresh');
    await _ref.read(authProvider.notifier).refreshUser();
  }
}

final accountActionsProvider = Provider(AccountActions.new);
