import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n.dart';
import '../../models/dispute.dart';
import '../../theme/app_colors.dart';
import '../../theme/gemstone.dart';
import '../dashboard/level_card.dart';
import 'messages_providers.dart';

/// Short state of a gift's 24h: « 23h 55m », « 24h SLA expired », « Confirmed »…
String caseStatusLabel(SupportCase item, Translate t) {
  if (item.status == 'CONFIRMED') return t('Confirmed', 'Confirmé', 'Confirmado');
  if (item.status == 'REJECTED') return t('Rejected', 'Rejeté', 'Rechazado');
  if (item.isDisputed) return t('Dispute', 'Litige', 'Disputa');
  final seconds = item.remainingSeconds ?? 0;
  if (seconds <= 0 || item.isSlaExpired) return t('24h SLA expired', 'SLA 24h expiré', 'Plazo de 24 h vencido');
  final minutes = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
  return '⏱️ ${seconds ~/ 3600}h ${minutes}m';
}

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  Timer? _refresh;

  @override
  void initState() {
    super.initState();
    _refresh = Timer.periodic(const Duration(seconds: 10), (_) => ref.invalidate(supportCasesProvider));
  }

  @override
  void dispose() {
    _refresh?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translateProvider);
    final cases = ref.watch(supportCasesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t('Payments & disputes', 'Paiements & litiges', 'Pagos y disputas'))),
      body: RefreshIndicator(
        color: AppColors.action,
        onRefresh: () async => ref.invalidate(supportCasesProvider),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              t(
                'Remind your receiver or talk 3-way with a Moderator in case of a dispute.',
                'Relancez votre receveur ou discutez à trois avec un Modérateur en cas de litige.',
                'Recuérdale a quien recibe o habla con un Moderador en caso de disputa.',
              ),
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 14),
            cases.when(
              skipLoadingOnReload: true,
              skipLoadingOnRefresh: true,
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator(color: AppColors.action)),
              ),
              error: (_, _) => _Empty(
                t('The conversations could not be loaded. Pull down to try again.', "Les conversations n'ont pas pu être chargées. Tirez vers le bas pour réessayer.", 'No se pudieron cargar las conversaciones. Desliza hacia abajo para reintentar.'),
              ),
              data: (items) => items.isEmpty
                  ? _Empty(
                      t(
                        'No active conversation. Your pending or disputed payments will show up here automatically.',
                        'Aucune conversation active. Vos paiements en attente ou en litige apparaîtront automatiquement ici.',
                        'No hay conversaciones activas. Tus pagos pendientes o en disputa aparecerán aquí automáticamente.',
                      ),
                    )
                  : Column(children: [for (final item in items) _CaseTile(item: item)]),
            ),
          ],
        ),
      ),
    );
  }
}

class _CaseTile extends ConsumerWidget {
  const _CaseTile({required this.item});

  final SupportCase item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translateProvider);
    final gem = gemstoneFor(item.levelId);
    final statusColor = switch (item.status) {
      'DISPUTED' => const Color(0xFFFDA4AF),
      'PENDING_CONFIRMATION' => const Color(0xFFFCD34D),
      'CONFIRMED' => AppColors.success,
      _ => AppColors.textMuted,
    };
    final supportGift = item.kind == 'SUPPORT_SHARE' || item.kind == 'SUPPORT_FUNDING';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push('/messages/${item.id}'),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: item.isDisputed ? const Color(0x80F43F5E) : AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _Pill('${supportGift ? '🤝 ' : ''}${item.levelName} • \$${formatAmount(item.amount)}', gem.badgeText, gem.accent),
                  _Pill(caseStatusLabel(item, t), statusColor, statusColor),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${item.donorName} → ${item.receiverName}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          '${t('Via', 'Via', 'Vía')} ${item.providerUsed} • ${item.messagesCount} ${t('message(s)', 'message(s)', 'mensaje(s)')}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  if (item.unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFFF43F5E), borderRadius: BorderRadius.circular(999)),
                      child: Text('${item.unreadCount}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
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

class _Pill extends StatelessWidget {
  const _Pill(this.label, this.foreground, this.accent);

  final String label;
  final Color foreground;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: foreground)),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)),
    );
  }
}
