import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/attachments.dart';
import '../../core/i18n.dart';
import '../../theme/app_colors.dart';
import '../forum/forum_widgets.dart';
import 'support_providers.dart';

class NewTicketScreen extends ConsumerStatefulWidget {
  const NewTicketScreen({super.key});

  @override
  ConsumerState<NewTicketScreen> createState() => _NewTicketScreenState();
}

class _NewTicketScreenState extends ConsumerState<NewTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subject = TextEditingController();
  final _message = TextEditingController();
  String _category = supportCategories.first;
  String _priority = supportPriorities.first;
  PickedImage? _image;
  bool _sending = false;

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
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
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);
    try {
      final id = await ref.read(supportActionsProvider).createTicket(
            category: _category,
            priority: _priority,
            subject: _subject.text,
            message: _message.text,
            attachmentUrl: _image?.dataUrl,
          );
      ref.invalidate(supportTicketsProvider);
      if (mounted) context.go('/support/ticket/$id');
    } catch (error) {
      if (mounted) showActionError(context, apiErrorMessage(error, t('Your request could not be sent.', "Votre demande n'a pas pu être envoyée.", 'No se pudo enviar tu solicitud.')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translateProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t('New request', 'Nouvelle demande', 'Nueva solicitud'))),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              initialValue: _category,
              isExpanded: true,
              dropdownColor: AppColors.card,
              decoration: InputDecoration(labelText: t('Request category', 'Catégorie de votre demande', 'Categoría de la solicitud')),
              items: [
                for (final value in supportCategories)
                  DropdownMenuItem(value: value, child: Text(categoryLabel(value, t), overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (value) => setState(() => _category = value ?? _category),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _priority,
              isExpanded: true,
              dropdownColor: AppColors.card,
              decoration: InputDecoration(labelText: t('Priority', 'Priorité', 'Prioridad')),
              items: [
                for (final value in supportPriorities) DropdownMenuItem(value: value, child: Text(priorityLabel(value, t))),
              ],
              onChanged: (value) => setState(() => _priority = value ?? _priority),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _subject,
              maxLength: 200,
              decoration: InputDecoration(labelText: t('Subject', 'Sujet', 'Asunto')),
              validator: (value) => (value ?? '').trim().length < 3
                  ? t('At least 3 characters.', 'Au moins 3 caractères.', 'Al menos 3 caracteres.')
                  : null,
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _message,
              minLines: 5,
              maxLines: 10,
              maxLength: 4000,
              decoration: InputDecoration(
                labelText: t('Your message', 'Votre message', 'Tu mensaje'),
                alignLabelWithHint: true,
              ),
              validator: (value) => (value ?? '').trim().length < 5
                  ? t('At least 5 characters.', 'Au moins 5 caractères.', 'Al menos 5 caracteres.')
                  : null,
            ),
            const SizedBox(height: 6),
            if (_image != null)
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
              )
            else
              OutlinedButton.icon(
                onPressed: _sending ? null : () => _pick(t),
                icon: const Icon(Icons.image_outlined),
                label: Text(t('Add a screenshot (optional)', 'Ajouter une capture (facultatif)', 'Añadir una captura (opcional)')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSoft,
                  side: const BorderSide(color: AppColors.border),
                  minimumSize: const Size.fromHeight(44),
                ),
              ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _sending ? null : () => _send(t),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _sending
                  ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(t('Send to Support', 'Envoyer au Support', 'Enviar a Soporte'), style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}
