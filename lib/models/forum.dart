class ForumComment {
  const ForumComment({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorUsername,
    required this.content,
    required this.likesCount,
    required this.likedByMe,
    required this.createdAt,
    this.parentCommentId,
  });

  factory ForumComment.fromJson(Map<String, dynamic> json) => ForumComment(
        id: json['id'] as String,
        authorId: json['author_id'] as String,
        authorName: json['author_name'] as String? ?? '',
        authorUsername: json['author_username'] as String? ?? '',
        content: json['content'] as String? ?? '',
        likesCount: json['likes_count'] as int? ?? 0,
        likedByMe: json['liked_by_me'] as bool? ?? false,
        createdAt: json['created_at'] as String,
        parentCommentId: json['parent_comment_id'] as String?,
      );

  final String id;
  final String authorId;
  final String authorName;
  final String authorUsername;
  final String content;
  final int likesCount;
  final bool likedByMe;
  final String createdAt;
  final String? parentCommentId;

  /// The public name: the username, or the full name when there is none.
  String get displayName => authorUsername.isNotEmpty ? authorUsername : authorName;
}

class ForumPost {
  const ForumPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorUsername,
    required this.levelBadge,
    required this.content,
    required this.likesCount,
    required this.likedByMe,
    required this.commentsCount,
    required this.comments,
    required this.createdAt,
    this.imageUrl,
  });

  factory ForumPost.fromJson(Map<String, dynamic> json) => ForumPost(
        id: json['id'] as String,
        authorId: json['author_id'] as String,
        authorName: json['author_name'] as String? ?? '',
        authorUsername: json['author_username'] as String? ?? '',
        levelBadge: json['level_badge'] as String? ?? '',
        content: json['content'] as String? ?? '',
        likesCount: json['likes_count'] as int? ?? 0,
        likedByMe: json['liked_by_me'] as bool? ?? false,
        commentsCount: json['comments_count'] as int? ?? 0,
        comments: (json['comments'] as List<dynamic>? ?? [])
            .map((item) => ForumComment.fromJson(item as Map<String, dynamic>))
            .toList(),
        createdAt: json['created_at'] as String,
        imageUrl: json['image_url'] as String?,
      );

  final String id;
  final String authorId;
  final String authorName;
  final String authorUsername;
  final String levelBadge;
  final String content;
  final int likesCount;
  final bool likedByMe;
  final int commentsCount;
  final List<ForumComment> comments;
  final String createdAt;
  final String? imageUrl;

  String get displayName => authorUsername.isNotEmpty ? authorUsername : authorName;

  /// Welcome and gift posts published by the platform (badge « Communauté »).
  bool get isCommunity => levelBadge.toLowerCase().startsWith('communaut');
}

class ForumNotification {
  const ForumNotification({
    required this.id,
    required this.actorName,
    required this.type,
    required this.postId,
    required this.preview,
    required this.isRead,
    required this.createdAt,
    this.actorUsername,
  });

  factory ForumNotification.fromJson(Map<String, dynamic> json) => ForumNotification(
        id: json['id'] as String,
        actorName: json['actor_name'] as String? ?? '',
        actorUsername: json['actor_username'] as String?,
        type: json['notif_type'] as String? ?? '',
        postId: json['post_id'] as String,
        preview: json['preview_text'] as String? ?? '',
        isRead: json['is_read'] as bool? ?? true,
        createdAt: json['created_at'] as String,
      );

  final String id;
  final String actorName;
  final String? actorUsername;

  /// MENTION_POST, MENTION_COMMENT, LIKE_POST, LIKE_COMMENT, COMMENT_POST, REPLY_COMMENT or NEW_POST
  final String type;
  final String postId;
  final String preview;
  final bool isRead;
  final String createdAt;

  String get actor => (actorUsername ?? '').isNotEmpty ? actorUsername! : actorName;
}

class ForumNotifications {
  const ForumNotifications(this.unreadCount, this.items);

  factory ForumNotifications.fromJson(Map<String, dynamic> json) => ForumNotifications(
        json['unread_count'] as int? ?? 0,
        (json['items'] as List<dynamic>? ?? [])
            .map((item) => ForumNotification.fromJson(item as Map<String, dynamic>))
            .toList(),
      );

  final int unreadCount;
  final List<ForumNotification> items;
}
