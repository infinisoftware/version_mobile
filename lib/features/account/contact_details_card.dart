import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/i18n.dart';
import '../../models/user.dart';
import '../../theme/app_colors.dart';
import 'account_providers.dart';

/// Username (it also signs in), phone and WhatsApp, editable; first and last name for admins and the owner.
/// The email is shown only: it changes through its own confirmed flow. Same rules as ContactDetailsCard.tsx.
class ContactDetailsCard extends ConsumerStatefulWidget {
  const ContactDetailsCard({super.key, required this.user});

  final User user;

  @override
  ConsumerState<ContactDetailsCard> createState() => _ContactDetailsCardState();
}

class _ContactDetailsCardState extends ConsumerState<ContactDetailsCard> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _username = TextEditingController();
  final _phone = TextEditingController();
  final _whatsapp = TextEditingController();
  String? _error;
  bool _saved = false;
  bool _saving = false;

  User get _user => widget.user;

  // Accounts made before first / last names existed only have a full name: first word = first name
  String get _baseFirst => _user.firstName ?? _user.fullName.trim().split(RegExp(r'\s+')).first;
  String get _baseLast => _user.lastName ?? _user.fullName.trim().split(RegExp(r'\s+')).skip(1).join(' ');

  @override
  void initState() {
    super.initState();
    _reset();
  }

  @override
  void didUpdateWidget(ContactDetailsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user != widget.user) _reset();
  }

  void _reset() {
    _first.text = _baseFirst;
    _last.text = _baseLast;
    _username.text = _user.username ?? '';
    _phone.text = _user.phone;
    _whatsapp.text = _user.whatsapp;
  }

  @override
  void dispose() {
    for (final c in [_first, _last, _username, _phone, _whatsapp]) {
      c.dispose();
    }
    super.dispose();
  }

  // Numbers compared by their digits: « +18005550199 » and « +1 8005550199 » are the same
  static String _digits(String value) => value.replaceAll(RegExp(r'\D'), '');

  bool get _nameChanged =>
      _user.canEditName && (_first.text.trim() != _baseFirst || _last.text.trim() != _baseLast);

  bool get _changed =>
      _nameChanged ||
      _username.text.trim() != (_user.username ?? '') ||
      _digits(_phone.text) != _digits(_user.phone) ||
      _digits(_whatsapp.text) != _digits(_user.whatsapp);

  String? _validate(Translate t) {
    if (_user.canEditName && (_first.text.trim().length < 2 || _last.text.trim().length < 2)) {
      return t('The first and last name need at least 2 characters.', 'Le nom et le prénom doivent contenir au moins 2 caractères.', 'El nombre y el apellido necesitan al menos 2 caracteres.');
    }
    final username = _username.text.trim();
    if ((username.isNotEmpty || (_user.username ?? '').isNotEmpty) && username.length < 2) {
      return t('The username needs at least 2 characters.', "Le nom d'utilisateur doit contenir au moins 2 caractères.", 'El nombre de usuario necesita al menos 2 caracteres.');
    }
    if (username.contains('@')) {
      return t('The username cannot contain « @ ».', "Le nom d'utilisateur ne peut pas contenir « @ ».", 'El nombre de usuario no puede contener « @ ».');
    }
    for (final number in [_phone.text, _whatsapp.text]) {
      if (!number.trim().startsWith('+') || _digits(number).length < 7) {
        return t(
          'Enter each number with its country code, e.g. +509 37833690.',
          "Saisissez chaque numéro avec son indicatif, par exemple +509 37833690.",
          'Escribe cada número con su código de país, por ejemplo +509 37833690.',
        );
      }
    }
    return null;
  }

  Future<void> _save(Translate t) async {
    final error = _validate(t);
    setState(() {
      _error = error;
      _saved = false;
    });
    if (error != null) return;
    setState(() => _saving = true);
    try {
      await ref.read(accountActionsProvider).updateMe({
        // An account without a username (older ones) may keep it empty
        if (_username.text.trim().isNotEmpty) 'username': _username.text.trim(),
        'phone': _phone.text.trim(),
        'whatsapp': _whatsapp.text.trim(),
        if (_nameChanged) ...{'first_name': _first.text.trim(), 'last_name': _last.text.trim()},
      });
      if (mounted) setState(() => _saved = true);
    } catch (error) {
      if (mounted) setState(() => _error = apiErrorMessage(error, t('Something went wrong. Please try again.', 'Une erreur est survenue. Réessayez.', 'Algo salió mal. Inténtalo de nuevo.')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field(TextEditingController controller, String label, {IconData? icon, TextInputType? keyboard, String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        autocorrect: false,
        onChanged: (_) => setState(() => _saved = false),
        decoration: InputDecoration(labelText: label, hintText: hint, prefixIcon: icon == null ? null : Icon(icon, size: 18)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translateProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          t('You can sign in with your email or your username.', "Vous pouvez vous connecter avec votre email ou votre nom d'utilisateur.", 'Puedes iniciar sesión con tu correo o tu nombre de usuario.'),
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        const SizedBox(height: 12),
        if (_user.canEditName) ...[
          _field(_first, t('First name', 'Prénom', 'Nombre')),
          _field(_last, t('Last name', 'Nom', 'Apellido')),
        ],
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InputDecorator(
            decoration: InputDecoration(labelText: t('Email', 'Email', 'Correo')),
            child: Text(_user.email, style: const TextStyle(color: AppColors.textSoft)),
          ),
        ),
        _field(_username, t('Username', "Nom d'utilisateur", 'Nombre de usuario'), icon: Icons.alternate_email),
        _field(
          _phone,
          t('Phone Number (Calls / SMS)', 'Numéro de Téléphone (Appels / SMS)', 'Número de teléfono (llamadas / SMS)'),
          icon: Icons.phone_outlined,
          keyboard: TextInputType.phone,
          hint: '+509 37833690',
        ),
        _field(
          _whatsapp,
          t('WhatsApp Number', 'Numéro de WhatsApp', 'Número de WhatsApp'),
          icon: Icons.chat_outlined,
          keyboard: TextInputType.phone,
          hint: '+509 37833690',
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(_error!, style: const TextStyle(fontSize: 13, color: AppColors.danger)),
          ),
        if (_saved && !_changed)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              '✓ ${t('Your contact details are saved.', 'Vos coordonnées sont enregistrées.', 'Tus datos de contacto están guardados.')}',
              style: const TextStyle(fontSize: 13, color: AppColors.success),
            ),
          ),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 8,
          children: [
            if (_changed)
              TextButton(
                onPressed: () => setState(() {
                  _reset();
                  _error = null;
                }),
                child: Text(t('Cancel', 'Annuler', 'Cancelar')),
              ),
            FilledButton(
              onPressed: _changed && !_saving ? () => _save(t) : null,
              child: _saving
                  ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(t('Save', 'Enregistrer', 'Guardar')),
            ),
          ],
        ),
      ],
    );
  }
}
