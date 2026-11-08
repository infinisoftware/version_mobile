import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n.dart';
import '../../theme/app_colors.dart';

class LanguageSwitcher extends ConsumerWidget {
  const LanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(languageProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final language in supportedLanguages)
          TextButton(
            onPressed: () => ref.read(languageProvider.notifier).select(language),
            style: TextButton.styleFrom(
              minimumSize: const Size(44, 44),
              foregroundColor: language == current ? AppColors.action : AppColors.textMuted,
            ),
            child: Text(language.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
      ],
    );
  }
}
