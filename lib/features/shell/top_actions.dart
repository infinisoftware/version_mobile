import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n.dart';
import '../forum/forum_providers.dart';
import '../forum/forum_screen.dart';
import '../messages/messages_providers.dart';

/// The two icons of the website's top bar: the payments & disputes messenger and the forum bell.
class TopActions extends ConsumerStatefulWidget {
  const TopActions({super.key});

  @override
  ConsumerState<TopActions> createState() => _TopActionsState();
}

class _TopActionsState extends ConsumerState<TopActions> {
  Timer? _refresh;

  @override
  void initState() {
    super.initState();
    // The badges move without leaving the screen
    _refresh = Timer.periodic(const Duration(seconds: 30), (_) {
      ref.invalidate(supportCasesProvider);
      ref.invalidate(forumNotificationsProvider);
    });
  }

  @override
  void dispose() {
    _refresh?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translateProvider);
    final unread = ref.watch(unreadMessagesProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: t('Payments & disputes', 'Paiements & litiges', 'Pagos y disputas'),
          onPressed: () => context.push('/messages'),
          icon: Badge(
            isLabelVisible: unread > 0,
            label: Text(unread > 99 ? '99+' : '$unread'),
            backgroundColor: const Color(0xFFF43F5E),
            child: const Icon(Icons.chat_bubble_outline),
          ),
        ),
        const ForumNotificationsBell(),
        const SizedBox(width: 4),
      ],
    );
  }
}
