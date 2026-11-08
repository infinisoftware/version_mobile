import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/attachments.dart';
import '../../core/dates.dart';
import '../../core/i18n.dart';
import '../../models/forum.dart';
import '../../theme/app_colors.dart';
import '../shell/top_actions.dart';
import 'forum_providers.dart';
import 'forum_widgets.dart';

class ForumScreen extends ConsumerStatefulWidget {
  const ForumScreen({super.key});

  @override
  ConsumerState<ForumScreen> createState() => _ForumScreenState();
}

class _ForumScreenState extends ConsumerState<ForumScreen> {
  Timer? _refresh;

  @override
  void initState() {
    super.initState();
    _refresh = Timer.periodic(const Duration(seconds: 30), (_) {
      ref.invalidate(forumPostsProvider);
      ref.invalidate(forumNotificationsProvider);
    });
  }

  @override
  void dispose() {
    _refresh?.cancel();
    super.dispose();
  }

  Future<void> _reload() async {
    ref.invalidate(forumNotificationsProvider);
    ref.invalidate(forumPostsProvider);
    try {
      await ref.read(forumPostsProvider.future);
    } catch (_) {
      // The error card is already on screen
    }
  }

  Future<void> _toggleLike(ForumPost post, Translate t) async {
    try {
      await ref.read(forumActionsProvider).toggleLikePost(post.id);
      ref.invalidate(forumPostsProvider);
    } catch (error) {
      if (mounted) showActionError(context, apiErrorMessage(error, t('Something went wrong.', 'Une erreur est survenue.', 'Algo salió mal.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translateProvider);
    final posts = ref.watch(forumPostsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t('Community', 'Communauté', 'Comunidad')),
        actions: const [TopActions()],
      ),
      body: RefreshIndicator(
        color: AppColors.action,
        onRefresh: _reload,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Composer(onPosted: _reload),
            const SizedBox(height: 16),
            posts.when(
              skipLoadingOnReload: true,
              skipLoadingOnRefresh: true,
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator(color: AppColors.action)),
              ),
              error: (_, _) => _Message(
                t('The posts could not be loaded. Pull down to try again.', "Les publications n'ont pas pu être chargées. Tirez vers le bas pour réessayer.", 'No se pudieron cargar las publicaciones. Desliza hacia abajo para reintentar.'),
              ),
              data: (items) => items.isEmpty
                  ? _Message(t('No posts yet. Be the first!', 'Aucune publication pour le moment. Soyez le premier !', 'Todavía no hay publicaciones. ¡Sé el primero!'))
                  : Column(
                      children: [
                        for (final post in items)
                          _PostCard(
                            post: post,
                            onOpen: () => context.go('/forum/post/${post.id}'),
                            onLike: () => _toggleLike(post, t),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Composer extends ConsumerStatefulWidget {
  const _Composer({required this.onPosted});

  final Future<void> Function() onPosted;

  @override
  ConsumerState<_Composer> createState() => _ComposerState();
}

class _ComposerState extends ConsumerState<_Composer> {
  final _text = TextEditingController();
  PickedImage? _image;
  bool _sending = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _pick(Translate t) async {
    try {
      final image = await pickImage();
      if (image != null) setState(() => _image = image);
    } on AttachmentTooLarge {
      if (mounted) showActionError(context, t('The file is too large (8 MB maximum).', 'Le fichier est trop lourd (8 Mo maximum).', 'El archivo es demasiado grande (8 MB máximo).'));
    }
  }

  Future<void> _send(Translate t) async {
    if (_text.text.trim().isEmpty) return;
    setState(() => _sending = true);
    try {
      await ref.read(forumActionsProvider).createPost(_text.text, imageUrl: _image?.dataUrl);
      _text.clear();
      setState(() => _image = null);
      await widget.onPosted();
    } catch (error) {
      if (mounted) showActionError(context, apiErrorMessage(error, t('The post could not be published.', "La publication n'a pas pu être envoyée.", 'No se pudo publicar.')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translateProvider);

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _text,
            minLines: 2,
            maxLines: 6,
            maxLength: 4000,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: t("What's new?", 'Quoi de neuf ?', '¿Qué hay de nuevo?'),
              counterText: '',
            ),
          ),
          if (_image != null) ...[
            const SizedBox(height: 10),
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(_image!.bytes, height: 160, width: double.infinity, fit: BoxFit.cover),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: IconButton.filledTonal(
                    tooltip: t('Remove', 'Retirer', 'Quitar'),
                    onPressed: () => setState(() => _image = null),
                    icon: const Icon(Icons.close),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              IconButton(
                tooltip: t('Add a photo', 'Ajouter une photo', 'Añadir una foto'),
                onPressed: _sending ? null : () => _pick(t),
                icon: const Icon(Icons.image_outlined, color: AppColors.textMuted),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _sending || _text.text.trim().isEmpty ? null : () => _send(t),
                child: _sending
                    ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(t('Post', 'Publier', 'Publicar'), style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PostCard extends ConsumerWidget {
  const _PostCard({required this.post, required this.onOpen, required this.onLike});

  final ForumPost post;
  final VoidCallback onOpen;
  final VoidCallback onLike;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translateProvider);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onOpen,
        child: _Card(
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
                        Text(timeAgo(post.createdAt, t), style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
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
                AttachmentImage(url: post.imageUrl!),
              ],
              const SizedBox(height: 4),
              Row(
                children: [
                  LikeButton(count: post.likesCount, liked: post.likedByMe, onPressed: onLike),
                  TextButton.icon(
                    onPressed: onOpen,
                    style: TextButton.styleFrom(foregroundColor: AppColors.textMuted, minimumSize: const Size(44, 36)),
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    label: Text('${post.commentsCount}'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ForumNotificationsBell extends ConsumerWidget {
  const ForumNotificationsBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translateProvider);
    final unread = ref.watch(forumNotificationsProvider).value?.unreadCount ?? 0;

    return IconButton(
      tooltip: t('Notifications', 'Notifications', 'Notificaciones'),
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.card,
        builder: (_) => const _NotificationsSheet(),
      ),
      icon: Badge(
        isLabelVisible: unread > 0,
        label: Text(unread > 99 ? '99+' : '$unread'),
        backgroundColor: const Color(0xFFF43F5E),
        child: const Icon(Icons.notifications_outlined),
      ),
    );
  }
}

class _NotificationsSheet extends ConsumerWidget {
  const _NotificationsSheet();

  String _describe(ForumNotification n, Translate t) {
    final who = n.actor;
    return switch (n.type) {
      'MENTION_POST' || 'MENTION_COMMENT' => t('$who mentioned you', '$who vous a mentionné', '$who te mencionó'),
      'LIKE_POST' => t('$who liked your post', '$who a aimé votre publication', 'A $who le gustó tu publicación'),
      'LIKE_COMMENT' => t('$who liked your comment', '$who a aimé votre commentaire', 'A $who le gustó tu comentario'),
      'COMMENT_POST' => t('$who commented on your post', '$who a commenté votre publication', '$who comentó tu publicación'),
      'REPLY_COMMENT' => t('$who replied to your comment', '$who a répondu à votre commentaire', '$who respondió a tu comentario'),
      _ => t('$who posted in the community', '$who a publié dans la communauté', '$who publicó en la comunidad'),
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translateProvider);
    final notifications = ref.watch(forumNotificationsProvider);
    final items = notifications.value?.items ?? const <ForumNotification>[];

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
              // Wraps: « Tout marquer comme lu » does not fit beside the title on a 320 px phone
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    t('Notifications', 'Notifications', 'Notificaciones'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  TextButton(
                    onPressed: () async {
                      await ref.read(forumActionsProvider).markAllNotificationsRead();
                      ref.invalidate(forumNotificationsProvider);
                    },
                    child: Text(t('Mark all as read', 'Tout marquer comme lu', 'Marcar todo como leído')),
                  ),
                ],
              ),
            ),
            if (notifications.isLoading && items.isEmpty)
              const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator(color: AppColors.action)))
            else if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  t('No notifications yet.', 'Aucune notification pour le moment.', 'Todavía no hay notificaciones.'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.border),
                  itemBuilder: (context, index) {
                    final n = items[index];
                    return ListTile(
                      leading: ForumAvatar(name: n.actor, small: true),
                      title: Text(
                        _describe(n, t),
                        style: TextStyle(fontSize: 13, fontWeight: n.isRead ? FontWeight.w500 : FontWeight.w800),
                      ),
                      subtitle: Text(
                        '${localizeForumText(n.preview, t)}\n${timeAgo(n.createdAt, t)}',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                      trailing: n.isRead ? null : const Icon(Icons.circle, size: 8, color: Color(0xFFF43F5E)),
                      onTap: () {
                        Navigator.of(context).pop();
                        context.go('/forum/post/${n.postId}');
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)),
    );
  }
}
