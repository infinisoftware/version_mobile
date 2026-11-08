import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/attachments.dart';
import '../../core/dates.dart';
import '../../core/i18n.dart';
import '../../models/support.dart';
import '../../theme/app_colors.dart';
import '../forum/forum_widgets.dart';
import 'support_providers.dart';
import 'support_screen.dart';

class TicketScreen extends ConsumerStatefulWidget {
  const TicketScreen({super.key, required this.ticketId});

  final String ticketId;

  @override
  ConsumerState<TicketScreen> createState() => _TicketScreenState();
}

class _TicketScreenState extends ConsumerState<TicketScreen> {
  final _reply = TextEditingController();
  PickedImage? _image;
  bool _sending = false;
  Timer? _refresh;

  String get _id => widget.ticketId;

  @override
  void initState() {
    super.initState();
    // The team's answer shows up without leaving the screen
    _refresh = Timer.periodic(const Duration(seconds: 15), (_) {
      ref.invalidate(supportMessagesProvider(_id));
      ref.invalidate(supportTicketsProvider);
    });
  }

  @override
  void dispose() {
    _refresh?.cancel();
    _reply.dispose();
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
    final text = _reply.text.trim();
    if (text.isEmpty && _image == null) return;
    setState(() => _sending = true);
    try {
      await ref.read(supportActionsProvider).reply(
            _id,
            text.isEmpty ? t('📎 Attachment sent to support.', '📎 Pièce jointe envoyée au support.', '📎 Archivo enviado a soporte.') : text,
            attachmentUrl: _image?.dataUrl,
          );
      _reply.clear();
      setState(() => _image = null);
      ref.invalidate(supportMessagesProvider(_id));
      ref.invalidate(supportTicketsProvider);
    } catch (error) {
      if (mounted) showActionError(context, apiErrorMessage(error, t('Your message could not be sent.', "Votre message n'a pas pu être envoyé.", 'No se pudo enviar tu mensaje.')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _close(Translate t) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(t('Close this request?', 'Fermer cette demande ?', '¿Cerrar esta solicitud?')),
        content: Text(t('Do it once your problem is solved.', 'À faire une fois votre problème réglé.', 'Hazlo cuando tu problema esté resuelto.')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t('Cancel', 'Annuler', 'Cancelar'))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(t('Close', 'Fermer', 'Cerrar'))),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(supportActionsProvider).close(_id);
      ref.invalidate(supportTicketsProvider);
    } catch (error) {
      if (mounted) showActionError(context, apiErrorMessage(error, t('Something went wrong.', 'Une erreur est survenue.', 'Algo salió mal.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translateProvider);
    final tickets = ref.watch(supportTicketsProvider).value;
    final ticket = tickets?.where((item) => item.id == _id).firstOrNull;
    final messages = ref.watch(supportMessagesProvider(_id));
    final closed = ticket?.isClosed ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(ticket?.subject ?? t('Request', 'Demande', 'Solicitud'), overflow: TextOverflow.ellipsis),
        actions: [
          if (ticket != null && !closed)
            TextButton(onPressed: () => _close(t), child: Text(t('Close', 'Fermer', 'Cerrar'))),
        ],
      ),
      body: Column(
        children: [
          if (ticket != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  TicketStatusPill(status: ticket.status),
                  Text(categoryLabel(ticket.category, t), style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  Text(
                    '${t('Priority:', 'Priorité :', 'Prioridad:')} ${priorityLabel(ticket.priority, t)}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
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
              data: (items) => ListView(
                padding: const EdgeInsets.all(16),
                children: [for (final message in items) _Bubble(message: message)],
              ),
            ),
          ),
          if (closed)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  t('This request is closed. Open a new one if you need help.', 'Cette demande est fermée. Ouvrez-en une nouvelle si vous avez besoin d’aide.', 'Esta solicitud está cerrada. Abre una nueva si necesitas ayuda.'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              ),
            )
          else
            _ReplyBox(
              controller: _reply,
              image: _image,
              sending: _sending,
              onPick: () => _pick(t),
              onRemoveImage: () => setState(() => _image = null),
              onSend: () => _send(t),
            ),
        ],
      ),
    );
  }
}

class _Bubble extends ConsumerWidget {
  const _Bubble({required this.message});

  final SupportMessage message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translateProvider);
    final fromSupport = message.isFromSupport;

    return Align(
      alignment: fromSupport ? Alignment.centerLeft : Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: fromSupport ? const Color(0x2610B981) : AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: fromSupport ? const Color(0x6610B981) : AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fromSupport ? '🛡️ ${message.senderName}' : message.senderName,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: fromSupport ? AppColors.success : AppColors.text),
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

class _ReplyBox extends ConsumerWidget {
  const _ReplyBox({
    required this.controller,
    required this.image,
    required this.sending,
    required this.onPick,
    required this.onRemoveImage,
    required this.onSend,
  });

  final TextEditingController controller;
  final PickedImage? image;
  final bool sending;
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
                        t('Proof attached ✓', 'Preuve jointe ✓', 'Prueba adjunta ✓'),
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
                  tooltip: t('Add a photo', 'Ajouter une photo', 'Añadir una foto'),
                  onPressed: sending ? null : onPick,
                  icon: const Icon(Icons.attach_file, color: AppColors.textMuted),
                ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    minLines: 1,
                    maxLines: 4,
                    maxLength: 4000,
                    decoration: InputDecoration(
                      hintText: t('Write to the team…', "Écrire à l'équipe…", 'Escribe al equipo…'),
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
