import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../models/forum.dart';

final forumPostsProvider = FutureProvider.autoDispose<List<ForumPost>>((ref) async {
  final response = await ref.watch(dioProvider).get<List<dynamic>>('/forum/posts');
  return response.data!.map((item) => ForumPost.fromJson(item as Map<String, dynamic>)).toList();
});

final forumPostProvider = FutureProvider.autoDispose.family<ForumPost, String>((ref, postId) async {
  final response = await ref.watch(dioProvider).get<Map<String, dynamic>>('/forum/posts/$postId');
  return ForumPost.fromJson(response.data!);
});

final forumNotificationsProvider = FutureProvider.autoDispose<ForumNotifications>((ref) async {
  final response = await ref.watch(dioProvider).get<Map<String, dynamic>>('/forum/notifications');
  return ForumNotifications.fromJson(response.data!);
});

/// Every forum action the screens send to the API.
class ForumActions {
  const ForumActions(this._ref);

  final Ref _ref;

  Future<void> createPost(String content, {String? imageUrl}) => _ref.read(dioProvider).post<void>(
        '/forum/posts',
        data: {'content': content.trim(), 'level_badge': 'Général', 'image_url': ?imageUrl},
      );

  Future<void> deletePost(String postId) => _ref.read(dioProvider).delete<void>('/forum/posts/$postId');

  Future<void> toggleLikePost(String postId) => _ref.read(dioProvider).post<void>('/forum/posts/$postId/like');

  Future<void> toggleLikeComment(String commentId) =>
      _ref.read(dioProvider).post<void>('/forum/comments/$commentId/like');

  Future<void> comment(String postId, String content, {String? parentCommentId}) =>
      _ref.read(dioProvider).post<void>(
        '/forum/posts/$postId/comments',
        data: {'content': content.trim(), 'parent_comment_id': ?parentCommentId},
      );

  Future<void> markAllNotificationsRead() => _ref.read(dioProvider).post<void>('/forum/notifications/read-all');
}

final forumActionsProvider = Provider(ForumActions.new);
