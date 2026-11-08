import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../models/dispute.dart';

final supportCasesProvider = FutureProvider.autoDispose<List<SupportCase>>((ref) async {
  final response = await ref.watch(dioProvider).get<List<dynamic>>('/donations/support/cases');
  final cases = response.data!.map((item) => SupportCase.fromJson(item as Map<String, dynamic>)).toList();
  cases.sort((a, b) => b.priority.compareTo(a.priority));
  return cases;
});

/// Sum of the others' unread messages: the badge of the messages icon.
final unreadMessagesProvider = Provider.autoDispose<int>((ref) {
  final cases = ref.watch(supportCasesProvider).value ?? const <SupportCase>[];
  return cases.fold(0, (sum, item) => sum + item.unreadCount);
});

/// Opening a conversation marks it read on the server.
final disputeMessagesProvider = FutureProvider.autoDispose.family<List<DisputeMessage>, String>((ref, donationId) async {
  final response = await ref.watch(dioProvider).get<List<dynamic>>('/donations/$donationId/messages');
  return response.data!.map((item) => DisputeMessage.fromJson(item as Map<String, dynamic>)).toList();
});

class DisputeActions {
  const DisputeActions(this._ref);

  final Ref _ref;

  Future<void> send(String donationId, String message, {String? attachmentUrl}) => _ref.read(dioProvider).post<void>(
        '/donations/$donationId/messages',
        data: {'message': message.trim(), 'attachment_url': ?attachmentUrl},
      );

  /// Donor: reminds the receiver that the payment was sent.
  Future<void> remind(String donationId, String note) =>
      _ref.read(dioProvider).post<void>('/donations/$donationId/remind', data: {'note': note});

  /// Donor: brings a moderator into the conversation.
  Future<void> openDispute(String donationId, String reason) =>
      _ref.read(dioProvider).post<void>('/donations/$donationId/open-dispute', data: {'reason': reason});

  /// Receiver only, after typing the word « confirm ».
  Future<void> confirm(String donationId) =>
      _ref.read(dioProvider).post<void>('/donations/$donationId/confirm', data: {'confirm_text': 'confirm'});
}

final disputeActionsProvider = Provider(DisputeActions.new);
