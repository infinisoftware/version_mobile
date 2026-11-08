import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/attachments.dart';
import '../../core/dates.dart';
import '../../core/i18n.dart';
import '../../models/dispute.dart';
import '../../theme/app_colors.dart';
import '../auth/auth_controller.dart';
import '../board/board_providers.dart';
import '../dashboard/dashboard_providers.dart';
import '../dashboard/level_card.dart';
import '../forum/forum_widgets.dart';
import 'messages_providers.dart';
import 'messages_screen.dart';

class ConversationScreen extends ConsumerStatefulWidget {
  const ConversationScreen({super.key, required this.donationId});

  final String donationId;

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final _text = TextEditingController();
  final _confirmWord = TextEditingController();
  PickedImage? _image;
  bool _busy = false;
  bool _confirming = false;
  String? _banner;
  Timer? _refresh;

  String get _id => widget.donationId;

  @override
  void initState() {
    super.initState();
    _refresh = Timer.periodic(const Duration(seconds: 5), (_) {
      ref.invalidate(disputeMessagesProvider(_id));
      ref.invalidate(supportCasesProvider);
    });
  }

  @override
  void dispose() {
    _refresh?.cancel();
    _text.dispose();
    _confirmWord.dispose();
    super.dispose();
  }

  void _refreshAll() {
    ref.invalidate(disputeMessagesProvider(_id));
    ref.invalidate(supportCasesProvider);
    ref.invalidate(levelsProvider);
    ref.invalidate(boardProvider);
  }

  Future<void> _run(Future<void> Function() action, String success, Translate t) async {
    setState(() => _busy = true);
    try {
      await action();
      _refreshAll();
      if (mounted) setState(() => _banner = success);
    } catch (error) {
      if (mounted) showActionError(context, apiErrorMessage(error, t('Something went wrong.', 'Une erreur est survenue.', 'Algo salió mal.')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
    final text = _text.text.trim();
    if (text.isEmpty && _image == null) return;
    final actions = ref.read(disputeActionsProvider);
    final attachment = _image?.dataUrl;
    await _run(
      () => actions.send(
        _id,
        text.isEmpty ? t('📎 Proof / screenshot attached in the messenger.', '📎 Preuve / Capture jointe dans la messagerie.', '📎 Prueba / captura adjunta en la mensajería.') : text,
        attachmentUrl: attachment,
      ),
      '',
      t,
    );
    if (!mounted) return;
    _text.clear();
    setState(() {
      _image = null;
      _banner = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translateProvider);
    final userId = ref.watch(authProvider).user?.id;
    final cases = ref.watch(supportCasesProvider).value ?? const <SupportCase>[];
    final item = cases.where((c) => c.id == _id).firstOrNull;
    final messages = ref.watch(disputeMessagesProvider(_id));
    final actions = ref.read(disputeActionsProvider);
    final isDonor = item != null && item.donorId == userId;
    final isReceiver = item != null && item.receiverId == userId;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          item == null ? t('Conversation', 'Conversation', 'Conversación') : '${item.donorName} ↔ ${item.receiverName}',
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Column(
        children: [
          if (item != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item.levelName} \$${formatAmount(item.amount)} • ${t('Donor • Receiver • Moderator', 'Donneur • Receveur • Modérateur', 'Donante • Receptor • Moderador')}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  Text(
                    'SLA : ${caseStatusLabel(item, t)}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.info),
                  ),
                  if (item.isOpen && (isDonor || isReceiver)) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (isDonor)
                          _ActionChip(
                            label: t('1. Mention paid again', '1. Re-mentionner payé', '1. Recordar que pagué'),
                            icon: Icons.notifications_active_outlined,
                            color: const Color(0xFFFCD34D),
                            onPressed: _busy
                                ? null
                                : () => _run(
                                      () => actions.remind(
                                        _id,
                                        t('Reminder sent from the messenger: I made the payment, please confirm.', "Rappel envoyé depuis la messagerie : J'ai bien effectué le paiement, merci de confirmer.", 'Recordatorio enviado desde la mensajería: hice el pago, por favor confirma.'),
                                      ),
                                      t('🔔 Reminder sent to ${item.receiverName}!', '🔔 Relance envoyée à ${item.receiverName} !', '🔔 ¡Recordatorio enviado a ${item.receiverName}!'),
                                      t,
                                    ),
                          ),
                        if (isDonor && !item.isDisputed)
                          _ActionChip(
                            label: t('2. Open a dispute', '2. Lancer un litige', '2. Abrir una disputa'),
                            icon: Icons.balance,
                            color: const Color(0xFFFDA4AF),
                            onPressed: _busy
                                ? null
                                : () => _run(
                                      () => actions.openDispute(
                                        _id,
                                        t('Dispute opened from the messenger because the receiver has not confirmed.', "Litige ouvert depuis la messagerie suite à l'absence de confirmation du receveur.", 'Disputa abierta desde la mensajería porque quien recibe no confirmó.'),
                                      ),
                                      t('⚖️ Dispute active! The Donor, the Receiver and the Moderator are connected in this conversation.', '⚖️ Litige activé ! Le Donneur, le Receveur et le Modérateur sont connectés dans cette conversation.', '⚖️ ¡Disputa activa! El Donante, el Receptor y el Moderador están conectados en esta conversación.'),
                                      t,
                                    ),
                          ),
                        // Only the receiver confirms a gift
                        if (isReceiver)
                          _ActionChip(
                            label: t('Confirm', 'Confirmer', 'Confirmar'),
                            icon: Icons.check_circle_outline,
                            color: AppColors.success,
                            onPressed: _busy ? null : () => setState(() => _confirming = !_confirming),
                          ),
                      ],
                    ),
                  ],
                  if (_confirming && isReceiver && item.isOpen) ...[
                    const SizedBox(height: 10),
                    _ConfirmBox(
                      controller: _confirmWord,
                      busy: _busy,
                      onValidate: () async {
                        await _run(
                          () => actions.confirm(_id),
                          t('✅ Payment confirmed and dispute closed!', '✅ Paiement confirmé et litige clôturé !', '✅ ¡Pago confirmado y disputa cerrada!'),
                          t,
                        );
                        if (mounted) setState(() => _confirming = false);
                      },
                    ),
                  ],
                  if (_banner != null && _banner!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(_banner!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.success)),
                  ],
                ],
              ),
            ),
          Expanded(
            child: messages.when(
              skipLoadingOnReload: true,
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.action)),
              error: (_, _) => Center(
                child: Text(
                  t('The conversation could not be loaded.', "La conversation n'a pas pu être chargée.", 'No se pudo cargar la conversación.'),
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              ),
              data: (items) => items.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          t('All messages sent here are visible to the Donor, the Receiver and the Moderator.', 'Tous les messages envoyés ici sont visibles par le Donneur, le Receveur et le Modérateur.', 'Todos los mensajes enviados aquí los ven el Donante, el Receptor y el Moderador.'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textMuted),
                        ),
                      ),
                    )
                  : ListView(
                      reverse: true,
                      padding: const EdgeInsets.all(16),
                      children: [for (final m in items.reversed) _Bubble(message: m, mine: m.senderId == userId)],
                    ),
            ),
          ),
          _Composer(
            controller: _text,
            image: _image,
            busy: _busy,
            onPick: () => _pick(t),
            onRemoveImage: () => setState(() => _image = null),
            onSend: () => _send(t),
          ),
        ],
      ),
    );
  }
}

class _ConfirmBox extends ConsumerStatefulWidget {
  const _ConfirmBox({required this.controller, required this.busy, required this.onValidate});

  final TextEditingController controller;
  final bool busy;
  final VoidCallback onValidate;

  @override
  ConsumerState<_ConfirmBox> createState() => _ConfirmBoxState();
}

class _ConfirmBoxState extends ConsumerState<_ConfirmBox> {
  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translateProvider);
    final valid = widget.controller.text.trim().toLowerCase() == 'confirm';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x8010B981)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: '${t('Type', 'Tapez', 'Escribe')} '),
                const TextSpan(text: 'confirm', style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w800, color: AppColors.action)),
                TextSpan(text: ' ${t('to validate receipt:', 'pour valider la réception :', 'para validar la recepción:')}'),
              ],
            ),
            style: const TextStyle(fontSize: 12, color: AppColors.textSoft),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  autocorrect: false,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(hintText: 'confirm', isDense: true),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: valid && !widget.busy ? widget.onValidate : null,
                child: Text(t('Validate', 'Valider', 'Validar')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.label, required this.icon, required this.color, required this.onPressed});

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        backgroundColor: color.withValues(alpha: 0.12),
        side: BorderSide(color: color.withValues(alpha: 0.5)),
        minimumSize: const Size(44, 40),
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }
}

class _Bubble extends ConsumerWidget {
  const _Bubble({required this.message, required this.mine});

  final DisputeMessage message;
  final bool mine;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translateProvider);
    if (message.senderRole == 'SYSTEM') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(message.message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
      );
    }

    final (role, color) = switch (message.senderRole) {
      'MODERATOR' => (t('Moderator', 'Modérateur', 'Moderador'), AppColors.success),
      'DONOR' => (t('Donor', 'Donneur', 'Donante'), const Color(0xFF7DD3FC)),
      _ => (t('Receiver', 'Receveur', 'Receptor'), const Color(0xFFFCD34D)),
    };

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: mine ? const Color(0xFF334155) : AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(message.senderName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                  Text(role, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color)),
                ],
              ),
              const SizedBox(height: 4),
              Text(message.message, style: const TextStyle(fontSize: 14, color: AppColors.textSoft, height: 1.4)),
              if (message.attachmentUrl != null) ...[
                const SizedBox(height: 8),
                AttachmentImage(url: message.attachmentUrl!, maxHeight: 240),
              ],
              const SizedBox(height: 4),
              Text(shortDate(message.createdAt, t), style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Composer extends ConsumerWidget {
  const _Composer({
    required this.controller,
    required this.image,
    required this.busy,
    required this.onPick,
    required this.onRemoveImage,
    required this.onSend,
  });

  final TextEditingController controller;
  final PickedImage? image;
  final bool busy;
  final VoidCallback onPick;
  final VoidCallback onRemoveImage;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translateProvider);

    return Container(
      decoration: const BoxDecoration(color: AppColors.card, border: Border(top: BorderSide(color: AppColors.border))),
      padding: const EdgeInsets.fromLTRB(4, 8, 8, 8),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (image != null)
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 6),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(image!.bytes, width: 48, height: 48, fit: BoxFit.cover),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        t('📎 Image attached to the message', '📎 Image jointe au message', '📎 Imagen adjunta al mensaje'),
                        style: const TextStyle(fontSize: 12, color: AppColors.success),
                      ),
                    ),
                    TextButton(onPressed: onRemoveImage, child: Text(t('Remove', 'Retirer', 'Quitar'))),
                  ],
                ),
              ),
            Row(
              children: [
                IconButton(
                  tooltip: t('Attach a screenshot', 'Joindre une capture', 'Adjuntar una captura'),
                  onPressed: busy ? null : onPick,
                  icon: const Icon(Icons.attach_file, color: AppColors.textMuted),
                ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: t('Write in the room…', 'Écrire dans le salon…', 'Escribe en la sala…'),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton.filled(
                  tooltip: t('Send', 'Envoyer', 'Enviar'),
                  onPressed: busy ? null : onSend,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
