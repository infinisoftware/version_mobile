import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/attachments.dart';
import '../../core/dates.dart';
import '../../core/i18n.dart';
import '../../models/forum.dart';
import '../../theme/app_colors.dart';
import '../auth/auth_controller.dart';
import 'forum_providers.dart';
import 'forum_widgets.dart';

class ForumPostScreen extends ConsumerStatefulWidget {
  const ForumPostScreen({super.key, required this.postId});

  final String postId;

  @override
  ConsumerState<ForumPostScreen> createState() => _ForumPostScreenState();
}

class _ForumPostScreenState extends ConsumerState<ForumPostScreen> {
  final _comment = TextEditingController();
  final _focus = FocusNode();
  ForumComment? _replyTo;
  bool _sending = false;

  @override
  void dispose() {
    _comment.dispose();
    _focus.dispose();
    super.dispose();
  }

  String get _postId => widget.postId;

  Future<void> _run(Future<void> Function() action, Translate t) async {
    try {
      await action();
      ref.invalidate(forumPostProvider(_postId));
      ref.invalidate(forumPostsProvider);
    } catch (error) {
      if (mounted) showActionError(context, apiErrorMessage(error, t('Something went wrong.', 'Une erreur est survenue.', 'Algo salió mal.')));
    }
  }

  void _reply(ForumComment comment) {
    // Same as the website: the reply starts with @author
    setState(() => _replyTo = comment);
    _comment.text = '@${comment.displayName} ';
    _comment.selection = TextSelection.collapsed(offset: _comment.text.length);
    _focus.requestFocus();
  }

  Future<void> _send(Translate t) async {
    if (_comment.text.trim().isEmpty) return;
    setState(() => _sending = true);
    await _run(
      () => ref.read(forumActionsProvider).comment(_postId, _comment.text, parentCommentId: _replyTo?.id),
      t,
    );
    if (!mounted) return;
    _comment.clear();
    setState(() {
      _sending = false;
      _replyTo = null;
    });
  }

  Future<void> _delete(Translate t) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(t('Delete this post?', 'Supprimer cette publication ?', '¿Eliminar esta publicación?')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t('Cancel', 'Annuler', 'Cancelar'))),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(t('Delete', 'Supprimer', 'Eliminar')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(forumActionsProvider).deletePost(_postId);
      ref.invalidate(forumPostsProvider);
      if (mounted) context.go('/forum');
    } catch (error) {
      if (mounted) showActionError(context, apiErrorMessage(error, t('Something went wrong.', 'Une erreur est survenue.', 'Algo salió mal.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translateProvider);
    final post = ref.watch(forumPostProvider(_postId));
    final userId = ref.watch(authProvider).user?.id;
    final isMine = post.value != null && post.value!.authorId == userId;

    return Scaffold(
      appBar: AppBar(
        title: Text(t('Post', 'Publication', 'Publicación')),
        actions: [
          if (isMine)
            IconButton(
              tooltip: t('Delete', 'Supprimer', 'Eliminar'),
              onPressed: () => _delete(t),
              icon: const Icon(Icons.delete_outline, color: AppColors.danger),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: post.when(
              skipLoadingOnReload: true,
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.action)),
              error: (_, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    t('This post could not be loaded. It may have been deleted.', "Cette publication n'a pas pu être chargée. Elle a peut-être été supprimée.", 'No se pudo cargar esta publicación. Quizás fue eliminada.'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                ),
              ),
              data: (data) => RefreshIndicator(
                color: AppColors.action,
                onRefresh: () async => ref.invalidate(forumPostProvider(_postId)),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _PostBody(post: data, onLike: () => _run(() => ref.read(forumActionsProvider).toggleLikePost(data.id), t)),
                    const SizedBox(height: 16),
                    Text(
                      t('Comments (${data.comments.length})', 'Commentaires (${data.comments.length})', 'Comentarios (${data.comments.length})'),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    ...threads(data.comments).expand(
                      (thread) => [
                        _CommentTile(
                          comment: thread.$1,
                          onLike: () => _run(() => ref.read(forumActionsProvider).toggleLikeComment(thread.$1.id), t),
                          onReply: () => _reply(thread.$1),
                        ),
                        for (final reply in thread.$2)
                          Padding(
                            padding: const EdgeInsets.only(left: 28),
                            child: _CommentTile(
                              comment: reply,
                              onLike: () => _run(() => ref.read(forumActionsProvider).toggleLikeComment(reply.id), t),
                              onReply: () => _reply(reply),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (post.hasValue) _CommentBox(controller: _comment, focus: _focus, sending: _sending, onSend: () => _send(t), replyTo: _replyTo, onCancelReply: () {
            _comment.clear();
            setState(() => _replyTo = null);
          }),
        ],
      ),
    );
  }

  /// Top-level comments, each with every reply below it (a reply to a reply goes under the same
  /// top-level comment), like ForumPostPage.tsx.
  List<(ForumComment, List<ForumComment>)> threads(List<ForumComment> comments) => groupThreads(comments);
}

List<(ForumComment, List<ForumComment>)> groupThreads(List<ForumComment> comments) {
  final byId = {for (final c in comments) c.id: c};
  String rootOf(ForumComment comment) {
    var current = comment;
    final seen = <String>{};
    while (current.parentCommentId != null && byId.containsKey(current.parentCommentId) && seen.add(current.id)) {
      current = byId[current.parentCommentId]!;
    }
    return current.id;
  }

  final replies = <String, List<ForumComment>>{};
  for (final c in comments) {
    if (c.parentCommentId == null) continue;
    replies.putIfAbsent(rootOf(c), () => []).add(c);
  }
  return [
    for (final c in comments)
      if (c.parentCommentId == null) (c, replies[c.id] ?? const <ForumComment>[]),
  ];
}

class _PostBody extends ConsumerWidget {
  const _PostBody({required this.post, required this.onLike});

  final ForumPost post;
  final VoidCallback onLike;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translateProvider);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ForumAvatar(name: post.displayName, highlight: post.isCommunity),
              const SizedBox(width: 10),
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(post.displayName, style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text(shortDate(post.createdAt, t), style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    if (post.isCommunity) const CommunityBadge(),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ForumText(post.content),
          if (post.imageUrl != null) ...[
            const SizedBox(height: 10),
            AttachmentImage(url: post.imageUrl!, maxHeight: 420),
          ],
          LikeButton(count: post.likesCount, liked: post.likedByMe, onPressed: onLike),
        ],
      ),
    );
  }
}

class _CommentTile extends ConsumerWidget {
  const _CommentTile({required this.comment, required this.onLike, required this.onReply});

  final ForumComment comment;
  final VoidCallback onLike;
  final VoidCallback onReply;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translateProvider);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 2),
      decoration: BoxDecoration(
        color: const Color(0xE60F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ForumAvatar(name: comment.displayName, small: true),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  comment.displayName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                ),
              ),
              Text(timeAgo(comment.createdAt, t), style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 6),
          ForumText(comment.content, style: const TextStyle(fontSize: 13, color: AppColors.textSoft, height: 1.4)),
          Row(
            children: [
              LikeButton(count: comment.likesCount, liked: comment.likedByMe, onPressed: onLike),
              TextButton(
                onPressed: onReply,
                style: TextButton.styleFrom(foregroundColor: AppColors.textMuted, minimumSize: const Size(44, 36)),
                child: Text(t('Reply', 'Répondre', 'Responder')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CommentBox extends ConsumerWidget {
  const _CommentBox({
    required this.controller,
    required this.focus,
    required this.sending,
    required this.onSend,
    required this.replyTo,
    required this.onCancelReply,
  });

  final TextEditingController controller;
  final FocusNode focus;
  final bool sending;
  final VoidCallback onSend;
  final ForumComment? replyTo;
  final VoidCallback onCancelReply;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translateProvider);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (replyTo != null)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      t('Replying to ${replyTo!.displayName}', 'Réponse à ${replyTo!.displayName}', 'Respondiendo a ${replyTo!.displayName}'),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ),
                  IconButton(
                    tooltip: t('Cancel', 'Annuler', 'Cancelar'),
                    onPressed: onCancelReply,
                    icon: const Icon(Icons.close, size: 18),
                  ),
                ],
              ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focus,
                    minLines: 1,
                    maxLines: 4,
                    maxLength: 2500,
                    decoration: InputDecoration(
                      hintText: t('Write a comment…', 'Écrire un commentaire…', 'Escribe un comentario…'),
                      counterText: '',
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton.filled(
                  tooltip: t('Send', 'Envoyer', 'Enviar'),
                  onPressed: sending ? null : onSend,
                  icon: sending
                      ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
