import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n.dart';
import '../../models/level.dart';
import '../../theme/app_colors.dart';
import '../../theme/gemstone.dart';

String formatAmount(num amount) {
  final digits = amount.round().toString();
  return digits.replaceAllMapped(RegExp(r'\B(?=(\d{3})+$)'), (_) => ',');
}

class LevelCard extends ConsumerWidget {
  const LevelCard({
    super.key,
    required this.level,
    required this.qualified,
    required this.showRanks,
    required this.selected,
    required this.onSelect,
    required this.onAction,
  });

  final Level level;
  final bool qualified;
  final bool showRanks;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translateProvider);
    final gem = gemstoneFor(level.displayOrder);
    final locked = level.isLocked(qualified: qualified);
    final slots = level.requiredContributors;
    final gifts = level.centerGifts;

    return GestureDetector(
      onTap: onSelect,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? gem.accent.withValues(alpha: 0.6) : AppColors.border),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gem.cardGradient,
          ),
          boxShadow: selected ? [BoxShadow(color: gem.accent.withValues(alpha: 0.28), blurRadius: 28)] : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(height: 6, decoration: BoxDecoration(gradient: LinearGradient(colors: gem.header))),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: gem.accent.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: gem.accent.withValues(alpha: 0.3)),
                            ),
                            child: Icon(gem.icon, size: 20, color: gem.badgeText),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${t('Level', 'Niveau', 'Nivel')} ${level.displayOrder}'.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.5,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              Text(
                                level.name,
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: gem.tileText),
                              ),
                            ],
                          ),
                        ],
                      ),
                      _StatusBadge(level: level, gem: gem, locked: locked, t: t),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.end,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t('Contribution', 'Contribution', 'Contribución'),
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                          Text(
                            '\$${formatAmount(level.amount)}',
                            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _progressLabel(t, slots, gifts),
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                          Text(
                            '\$${formatAmount(level.centerPayout)}',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: gem.badgeText),
                          ),
                          if (level.isCenter) ...[
                            const SizedBox(height: 4),
                            SizedBox(
                              width: 96,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: level.received / slots,
                                  minHeight: 6,
                                  backgroundColor: AppColors.background,
                                  color: AppColors.action,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const Divider(color: AppColors.border, height: 24),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.group_outlined, size: 14, color: gem.badgeText),
                          const SizedBox(width: 6),
                          Text(
                            t('$slots gifts per cycle', '$slots dons par cycle', '$slots regalos por ciclo'),
                            style: const TextStyle(fontSize: 12, color: AppColors.textSoft),
                          ),
                        ],
                      ),
                      Text(
                        '🤝 ${t('$gifts to the Center · 1 to Support', '$gifts au Centre · 1 au Support', '$gifts al Centro · 1 a Soporte')}',
                        style: const TextStyle(fontSize: 11, color: AppColors.info),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _ActionButton(label: _buttonLabel(t, locked), gem: gem, locked: locked, onPressed: onAction),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _progressLabel(Translate t, int slots, int gifts) {
    final received = level.received;
    if (level.isCenter) {
      return t(
        '$received / $slots gifts confirmed · for you',
        '$received / $slots dons confirmés · pour vous',
        '$received / $slots regalos confirmados · para ti',
      );
    }
    if (level.isInLine && level.queuePosition != null) {
      final rank = level.queuePosition;
      return showRanks
          ? t(
              '#$rank in line · a full cycle gives the Center',
              '#$rank dans la file · un cycle complet donne au Centre',
              '#$rank en la fila · un ciclo completo da al Centro',
            )
          : t(
              'In line · a full cycle gives the Center',
              'Dans la file · un cycle complet donne au Centre',
              'En la fila · un ciclo completo da al Centro',
            );
    }
    if (level.isCompleted) {
      return t('Done · $gifts gifts received', 'Terminé · $gifts dons reçus', 'Terminado · $gifts regalos recibidos');
    }
    return t(
      'A full cycle gives the Center ($gifts gifts)',
      'Un cycle complet donne au Centre ($gifts dons)',
      'Un ciclo completo da al Centro ($gifts regalos)',
    );
  }

  String _buttonLabel(Translate t, bool locked) {
    final name = level.name;
    if (locked) return t('Locked', 'Verrouillé', 'Bloqueado');
    if (level.isActive) return t('View $name Board', 'Voir le board $name', 'Ver el tablero $name');
    if (level.isCompleted) return t('Re-Join $name', 'Rejoindre $name à nouveau', 'Unirse de nuevo a $name');
    return t('Join $name', 'Rejoindre $name', 'Unirse a $name');
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.level, required this.gem, required this.locked, required this.t});

  final Level level;
  final Gemstone gem;
  final bool locked;
  final Translate t;

  @override
  Widget build(BuildContext context) {
    if (level.isCenter) {
      return _pill(
        '★ ${t('Center', 'Centre', 'Centro')}',
        background: AppColors.action,
        foreground: const Color(0xFF020617),
      );
    }
    if (level.isCompleted) {
      return _pill(
        t('Done', 'Terminé', 'Terminado'),
        background: const Color(0x3310B981),
        foreground: AppColors.success,
        border: const Color(0x6610B981),
        icon: Icons.check_circle_outline,
      );
    }
    if (locked) {
      return _pill(
        t('Locked', 'Verrouillé', 'Bloqueado'),
        background: AppColors.card,
        foreground: AppColors.textMuted,
        border: AppColors.border,
        icon: Icons.lock_outline,
      );
    }
    final label = level.isInLine
        ? t('Active in Line', 'Actif dans la file', 'Activo en la fila')
        : t('Open', 'Ouvert', 'Abierto');
    return _pill(
      label,
      background: gem.accent.withValues(alpha: 0.15),
      foreground: gem.badgeText,
      border: gem.accent.withValues(alpha: 0.4),
    );
  }

  Widget _pill(String label, {required Color background, required Color foreground, Color? border, IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: border == null ? null : Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 12, color: foreground), const SizedBox(width: 4)],
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: foreground)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.gem, required this.locked, required this.onPressed});

  final String label;
  final Gemstone gem;
  final bool locked;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final foreground = locked ? AppColors.textDisabled : gem.buttonText;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: locked ? AppColors.card : null,
        gradient: locked ? null : LinearGradient(colors: gem.button),
        border: locked ? Border.all(color: AppColors.border) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: locked ? null : onPressed,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: foreground),
                    ),
                  ),
                  if (!locked) ...[const SizedBox(width: 6), Icon(Icons.arrow_forward, size: 14, color: foreground)],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
