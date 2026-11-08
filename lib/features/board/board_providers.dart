import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../models/board.dart';

final boardProvider = FutureProvider.autoDispose.family<Board, int>((ref, levelId) async {
  final response = await ref.watch(dioProvider).get<Map<String, dynamic>>('/boards/$levelId');
  return Board.fromJson(response.data!);
});

final boardLineProvider = FutureProvider.autoDispose.family<List<QueueEntry>, int>((ref, levelId) async {
  final response = await ref.watch(dioProvider).get<Map<String, dynamic>>('/boards/$levelId/line');
  final entries = (response.data!['queue'] as List<dynamic>? ?? [])
      .map((item) => QueueEntry.fromJson(item as Map<String, dynamic>))
      .toList();
  entries.sort((a, b) => a.position.compareTo(b.position));
  return entries;
});

/// Members without a place in the line yet. Shown on the Bronze board only, like the website.
final boardPendingProvider = FutureProvider.autoDispose.family<List<PendingMember>, int>((ref, levelId) async {
  final response = await ref.watch(dioProvider).get<List<dynamic>>('/boards/$levelId/pending');
  return response.data!.map((item) => PendingMember.fromJson(item as Map<String, dynamic>)).toList();
});
