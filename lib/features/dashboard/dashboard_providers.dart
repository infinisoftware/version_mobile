import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../models/level.dart';

final levelsProvider = FutureProvider.autoDispose<List<Level>>((ref) async {
  final response = await ref.watch(dioProvider).get<List<dynamic>>('/levels');
  final levels = response.data!.map((item) => Level.fromJson(item as Map<String, dynamic>)).toList();
  levels.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
  return levels;
});

/// An administrator can hide the line ranks (#1, #2…) from members.
final showLineRanksProvider = FutureProvider.autoDispose<bool>((ref) async {
  final response = await ref.watch(dioProvider).get<Map<String, dynamic>>('/users/display-settings');
  return response.data!['show_line_ranks'] as bool? ?? true;
});
