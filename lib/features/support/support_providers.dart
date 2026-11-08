import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/i18n.dart';
import '../../models/support.dart';

final supportTicketsProvider = FutureProvider.autoDispose<List<SupportTicket>>((ref) async {
  final response = await ref.watch(dioProvider).get<List<dynamic>>('/support/tickets');
  return response.data!.map((item) => SupportTicket.fromJson(item as Map<String, dynamic>)).toList();
});

final supportMessagesProvider = FutureProvider.autoDispose.family<List<SupportMessage>, String>((ref, ticketId) async {
  final response = await ref.watch(dioProvider).get<List<dynamic>>('/support/tickets/$ticketId/messages');
  return response.data!.map((item) => SupportMessage.fromJson(item as Map<String, dynamic>)).toList();
});

class SupportActions {
  const SupportActions(this._ref);

  final Ref _ref;

  Future<String> createTicket({
    required String category,
    required String priority,
    required String subject,
    required String message,
    String? attachmentUrl,
  }) async {
    final response = await _ref.read(dioProvider).post<Map<String, dynamic>>(
      '/support/tickets',
      data: {
        'category': category,
        'priority': priority,
        'subject': subject.trim(),
        'message': message.trim(),
        'attachment_url': ?attachmentUrl,
      },
    );
    return response.data!['id'] as String;
  }

  Future<void> reply(String ticketId, String message, {String? attachmentUrl}) => _ref.read(dioProvider).post<void>(
        '/support/tickets/$ticketId/messages',
        data: {'message': message.trim(), 'attachment_url': ?attachmentUrl},
      );

  Future<void> close(String ticketId) => _ref.read(dioProvider).post<void>('/support/tickets/$ticketId/close');
}

final supportActionsProvider = Provider(SupportActions.new);

/// Categories of the website (frontend/src/pages/SupportPage.tsx).
const supportCategories = [
  'QUESTION_GENERALE',
  'PAIEMENT_CONFIRMATION',
  'COMPTE_PROFIL',
  'MOYENS_PAIEMENT',
  'PARRAINAGE_NIVEAUX',
  'PROBLEME_TECHNIQUE',
];

String categoryLabel(String value, Translate t) => switch (value) {
      'QUESTION_GENERALE' => t('General question', 'Question générale', 'Pregunta general'),
      'PAIEMENT_CONFIRMATION' => t('Payment / Gift confirmation', 'Paiement / Confirmation de don', 'Pago / Confirmación de regalo'),
      'COMPTE_PROFIL' => t('My account & profile', 'Mon compte & profil', 'Mi cuenta y perfil'),
      'MOYENS_PAIEMENT' => t('Payment methods (Zelle, CashApp, Crypto...)', 'Moyens de paiement (Zelle, CashApp, Crypto...)', 'Medios de pago (Zelle, CashApp, Cripto...)'),
      'PARRAINAGE_NIVEAUX' => t('Referrals & level unlocking', 'Parrainage & déblocage des niveaux', 'Referidos y desbloqueo de niveles'),
      'PROBLEME_TECHNIQUE' => t('Technical problem', 'Problème technique', 'Problema técnico'),
      _ => value,
    };

const supportPriorities = ['NORMALE', 'HAUTE', 'URGENTE'];

String priorityLabel(String value, Translate t) => switch (value) {
      'NORMALE' => t('Normal', 'Normale', 'Normal'),
      'HAUTE' => t('High', 'Haute', 'Alta'),
      'URGENTE' => t('Urgent', 'Urgente', 'Urgente'),
      _ => value,
    };
