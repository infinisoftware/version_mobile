import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/dates.dart';
import '../../core/i18n.dart';
import '../../models/support.dart';
import '../../theme/app_colors.dart';
import '../shell/top_actions.dart';
import 'support_providers.dart';

class SupportScreen extends ConsumerWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translateProvider);
    final tickets = ref.watch(supportTicketsProvider);

    Future<void> reload() async {
      ref.invalidate(supportTicketsProvider);
      try {
        await ref.read(supportTicketsProvider.future);
      } catch (_) {
        // The message is already on screen
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(t('Support', 'Support', 'Soporte')), actions: const [TopActions()]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/support/new'),
        icon: const Icon(Icons.add),
        label: Text(t('New request', 'Nouvelle demande', 'Nueva solicitud'), style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: RefreshIndicator(
        color: AppColors.action,
        onRefresh: reload,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            Text(
              t('My messages to Support', 'Mes messages au Support', 'Mis mensajes a Soporte') +
                  (tickets.hasValue ? ' (${tickets.value!.length})' : ''),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              t(
                'The team answers here. You also receive an email when they reply.',
                "L'équipe répond ici. Vous recevez aussi un email à chaque réponse.",
                'El equipo responde aquí. También recibes un correo con cada respuesta.',
              ),
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 14),
            tickets.when(
              skipLoadingOnReload: true,
              skipLoadingOnRefresh: true,
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator(color: AppColors.action)),
              ),
              error: (_, _) => _Empty(
                t('Your requests could not be loaded. Pull down to try again.', "Vos demandes n'ont pas pu être chargées. Tirez vers le bas pour réessayer.", 'No se pudieron cargar tus solicitudes. Desliza hacia abajo para reintentar.'),
              ),
              data: (items) => items.isEmpty
                  ? _Empty(t('No request yet. Tap « New request » to write to the team.', 'Aucune demande pour le moment. Touchez « Nouvelle demande » pour écrire à l’équipe.', 'Todavía no hay solicitudes. Toca « Nueva solicitud » para escribir al equipo.'))
                  : Column(children: [for (final ticket in items) _TicketTile(ticket: ticket)]),
            ),
          ],
        ),
      ),
    );
  }
}

class TicketStatusPill extends ConsumerWidget {
  const TicketStatusPill({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translateProvider);
    final (label, color, icon) = switch (status) {
      'CLOSED' => (t('Closed', 'Fermé', 'Cerrado'), AppColors.textMuted, Icons.lock_outline),
      'ANSWERED' => (t('Answered', 'Répondu', 'Respondido'), AppColors.success, Icons.check_circle_outline),
      _ => (t('Open', 'En cours', 'Abierto'), const Color(0xFFFCD34D), Icons.schedule),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

class _TicketTile extends ConsumerWidget {
  const _TicketTile({required this.ticket});

  final SupportTicket ticket;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translateProvider);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.go('/support/ticket/${ticket.id}'),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(ticket.subject, style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 8),
                  TicketStatusPill(status: ticket.status),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${categoryLabel(ticket.category, t)} · ${shortDate(ticket.updatedAt, t)}',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              if ((ticket.lastMessagePreview ?? '').isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  ticket.lastMessagePreview!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSoft),
                ),
              ],
            ],
          ),
        ),
      ),
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
