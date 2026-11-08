import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n.dart';
import '../../theme/app_colors.dart';

// Welcome and gift posts are stored in French by the backend: shown in the reader's language
// (same rules as localizeForumText in frontend/src/components/forum/ForumShared.tsx)
final _welcome = RegExp(
  r'^🎉 (.+) (?:vient de prendre sa place dans la matrice|vient de rejoindre) The Gift Exchange Global ! Bienvenue dans la communauté 🙌$',
);
final _gift = RegExp(r'^(💸|🎟️) (.+) vient de donner (\$[\d.,]+) à (.+) \((.*)\) 🙌$');

String localizeForumText(String text, Translate t) {
  final welcome = _welcome.firstMatch(text);
  if (welcome != null) {
    final name = welcome.group(1);
    return t(
      '🎉 $name just took their place in The Gift Exchange Global matrix! Welcome to the community 🙌',
      text,
      '🎉 ¡$name acaba de tomar su lugar en la matriz de The Gift Exchange Global! Bienvenido a la comunidad 🙌',
    );
  }
  final gift = _gift.firstMatch(text);
  if (gift != null) {
    String name(String n) => switch (n) {
          "l'équipe Support" => t('the Support team', n, 'el equipo de Soporte'),
          "L'équipe Support" => t('The Support team', n, 'El equipo de Soporte'),
          _ => n,
        };
    final level = gift.group(5) == 'don-ticket Bronze' ? 'Bronze don-ticket' : gift.group(5);
    final icon = gift.group(1);
    final from = name(gift.group(2)!);
    final amount = gift.group(3);
    final to = name(gift.group(4)!);
    return t(
      '$icon $from just gave $amount to $to ($level) 🙌',
      text,
      '$icon $from acaba de regalar $amount a $to ($level) 🙌',
    );
  }
  return text;
}

/// Post or comment text: line breaks kept, @mentions highlighted.
class ForumText extends ConsumerWidget {
  const ForumText(this.text, {super.key, this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translateProvider);
    final localized = localizeForumText(text, t);
    final spans = <TextSpan>[];
    localized.splitMapJoin(
      RegExp(r'@[a-zA-Z0-9_.-]+'),
      onMatch: (match) {
        spans.add(TextSpan(
          text: match[0],
          style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF22D3EE)),
        ));
        return '';
      },
      onNonMatch: (part) {
        spans.add(TextSpan(text: part));
        return '';
      },
    );
    return Text.rich(
      TextSpan(children: spans),
      style: style ?? const TextStyle(fontSize: 14, color: AppColors.textSoft, height: 1.45),
    );
  }
}

class ForumAvatar extends StatelessWidget {
  const ForumAvatar({super.key, required this.name, this.highlight = false, this.small = false});

  final String name;
  final bool highlight;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final size = small ? 28.0 : 40.0;
    final letter = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: highlight ? null : AppColors.avatar,
        gradient: highlight
            ? const LinearGradient(colors: [Color(0xFFFBBF24), Color(0xFFF43F5E)], begin: Alignment.topLeft, end: Alignment.bottomRight)
            : null,
      ),
      child: Text(
        letter,
        style: TextStyle(fontSize: small ? 11 : 14, fontWeight: FontWeight.w800, color: Colors.white),
      ),
    );
  }
}

class CommunityBadge extends ConsumerWidget {
  const CommunityBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translateProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0x26F59E0B),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x4DF59E0B)),
      ),
      child: Text(
        '🎉 ${t('Community', 'Communauté', 'Comunidad').toUpperCase()}',
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: Color(0xFFFCD34D)),
      ),
    );
  }
}

/// ❤️ 3 — red when the viewer liked it.
class LikeButton extends StatelessWidget {
  const LikeButton({super.key, required this.count, required this.liked, required this.onPressed});

  final int count;
  final bool liked;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: liked ? const Color(0xFFF43F5E) : AppColors.textMuted,
        minimumSize: const Size(44, 36),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      icon: Icon(liked ? Icons.favorite : Icons.favorite_border, size: 18),
      label: Text('$count'),
    );
  }
}

/// A message under the forum or support screens when the server refused an action.
void showActionError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
