import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api_client.dart';
import '../../core/config.dart';
import '../../core/dates.dart';
import '../../core/i18n.dart';
import '../../models/account.dart';
import '../../models/user.dart';
import '../../theme/app_colors.dart';
import '../../theme/gemstone.dart';
import '../auth/auth_controller.dart';
import '../dashboard/level_card.dart';
import '../forum/forum_widgets.dart';
import '../shell/language_switcher.dart';
import '../shell/top_actions.dart';
import 'account_providers.dart';
import 'contact_details_card.dart';
import 'payment_method_sheet.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translateProvider);
    final user = ref.watch(authProvider).user;

    Future<void> reload() async {
      ref.invalidate(paymentMethodsProvider);
      ref.invalidate(sponsorNameProvider);
      ref.invalidate(boardHistoryProvider);
      ref.invalidate(mySignaturesProvider);
      try {
        await ref.read(authProvider.notifier).refreshUser();
      } catch (_) {
        // The screen keeps what it already shows
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(t('Account', 'Compte', 'Cuenta')),
        actions: const [TopActions()],
      ),
      body: user == null
          ? const SizedBox.shrink()
          : RefreshIndicator(
              color: AppColors.action,
              onRefresh: reload,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _ProfileHeader(user: user),
                  _Section(
                    icon: Icons.link,
                    iconColor: AppColors.action,
                    title: t('Your invite link', "Votre lien d'invitation", 'Tu enlace de invitación'),
                    child: _InviteLink(user: user),
                  ),
                  _Section(
                    icon: Icons.person_outline,
                    iconColor: AppColors.success,
                    title: t('My contact details', 'Mes coordonnées', 'Mis datos de contacto'),
                    child: ContactDetailsCard(user: user),
                  ),
                  _Section(
                    icon: Icons.account_balance_wallet_outlined,
                    iconColor: AppColors.info,
                    title: t('Receiving Payment Coordinates', 'Coordonnées de réception des paiements', 'Datos para recibir pagos'),
                    subtitle: t('Shown to contributors when you are at the Center of a board.', 'Affichées aux contributeurs quand vous êtes au Centre d’un board.', 'Se muestran a los contribuyentes cuando estás en el Centro de un tablero.'),
                    child: const _PaymentMethods(),
                  ),
                  _Section(
                    icon: Icons.timeline,
                    iconColor: const Color(0xFFA855F7),
                    title: t('On the board', 'Sur le board', 'En el tablero'),
                    child: const _Journey(),
                  ),
                  _Section(
                    icon: Icons.draw_outlined,
                    iconColor: const Color(0xFFFCD34D),
                    title: t('My signatures', 'Mes signatures', 'Mis firmas'),
                    subtitle: t('Every acceptance of our documents is recorded as proof and cannot be changed.', 'Chaque acceptation de nos documents est enregistrée comme preuve et ne peut pas être modifiée.', 'Cada aceptación de nuestros documentos se guarda como prueba y no se puede modificar.'),
                    child: const _Signatures(),
                  ),
                  _Section(
                    icon: Icons.language,
                    iconColor: AppColors.textSoft,
                    title: t('Language', 'Langue', 'Idioma'),
                    child: const Align(alignment: Alignment.centerLeft, child: LanguageSwitcher()),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => ref.read(authProvider.notifier).signOut(),
                    icon: const Icon(Icons.logout),
                    label: Text(t('Sign out', 'Se déconnecter', 'Cerrar sesión')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.border),
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}

class _ProfileHeader extends ConsumerWidget {
  const _ProfileHeader({required this.user});

  final User user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translateProvider);
    final sponsor = ref.watch(sponsorNameProvider).value;

    String role() {
      if (user.isOwner) return t('Owner', 'Propriétaire', 'Propietario');
      if (user.isAdmin) return t('Administrator', 'Administrateur', 'Administrador');
      return t('Member', 'Membre', 'Miembro');
    }

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.avatar,
                child: Text(user.initials, style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.fullName.toUpperCase(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    if ((user.username ?? '').isNotEmpty)
                      Text('@${user.username}', style: const TextStyle(fontSize: 12, color: Color(0xFF22D3EE))),
                    Text(user.email, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Tag(role(), AppColors.action),
              _Tag(
                user.emailVerified
                    ? '✓ ${t('Email confirmed', 'Email confirmé', 'Correo confirmado')}'
                    : t('Email not confirmed', 'Email non confirmé', 'Correo sin confirmar'),
                user.emailVerified ? AppColors.success : AppColors.danger,
              ),
              _Tag(t('${user.referralCount} referral(s)', '${user.referralCount} filleul(s)', '${user.referralCount} referido(s)'), AppColors.info),
              if (user.strikesCount > 0) _Tag('⚠️ Strike ${user.strikesCount}/3', const Color(0xFFFCD34D)),
            ],
          ),
          const SizedBox(height: 12),
          _Line(t('Sponsor', 'Parrain', 'Patrocinador'), sponsor ?? '—'),
          if ((user.country ?? '').isNotEmpty) _Line(t('Country', 'Pays', 'País'), user.country!),
          if (user.memberSince != null) _Line(t('Member since', 'Membre depuis', 'Miembro desde'), shortDate(user.memberSince!, t).split(' ').first),
        ],
      ),
    );
  }
}

class _InviteLink extends ConsumerStatefulWidget {
  const _InviteLink({required this.user});

  final User user;

  @override
  ConsumerState<_InviteLink> createState() => _InviteLinkState();
}

class _InviteLinkState extends ConsumerState<_InviteLink> {
  bool _busy = false;

  Future<void> _regenerate(Translate t) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(t('Generate a new link?', 'Générer un nouveau lien ?', '¿Generar un enlace nuevo?')),
        content: Text(t('Your current link will stop working.', 'Votre lien actuel ne fonctionnera plus.', 'Tu enlace actual dejará de funcionar.')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t('Cancel', 'Annuler', 'Cancelar'))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(t('Generate', 'Générer', 'Generar'))),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _busy = true);
    try {
      await ref.read(accountActionsProvider).refreshInviteCode();
    } catch (error) {
      if (mounted) showActionError(context, apiErrorMessage(error, t('Something went wrong.', 'Une erreur est survenue.', 'Algo salió mal.')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translateProvider);
    final link = '${AppConfig.websiteUrl}/register?ref=${widget.user.inviteCode}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          t("Share this link to invite someone. You'll be their sponsor.", 'Partagez ce lien pour inviter quelqu’un. Vous serez son parrain.', 'Comparte este enlace para invitar a alguien. Serás su patrocinador.'),
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: SelectableText(link, style: const TextStyle(fontSize: 12, color: AppColors.textSoft)),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: link));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('Link copied', 'Lien copié', 'Enlace copiado'))));
              },
              icon: const Icon(Icons.copy, size: 16),
              label: Text(t('Copy', 'Copier', 'Copiar')),
            ),
            OutlinedButton.icon(
              onPressed: () => launchUrl(
                Uri.parse('https://wa.me/?text=${Uri.encodeComponent(link)}'),
                mode: LaunchMode.externalApplication,
              ),
              icon: const Icon(Icons.share, size: 16),
              label: const Text('WhatsApp'),
            ),
            TextButton(
              onPressed: _busy ? null : () => _regenerate(t),
              child: Text(t('Generate new link', 'Générer un nouveau lien', 'Generar un enlace nuevo')),
            ),
          ],
        ),
      ],
    );
  }
}

class _PaymentMethods extends ConsumerWidget {
  const _PaymentMethods();

  Future<void> _delete(BuildContext context, WidgetRef ref, PaymentMethod method, Translate t) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(t('Delete this method?', 'Supprimer ce moyen de paiement ?', '¿Eliminar este medio de pago?')),
        content: Text(providerLabel(method.providerType, t)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t('Cancel', 'Annuler', 'Cancelar'))),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(t('Delete', 'Supprimer', 'Eliminar')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(accountActionsProvider).deletePaymentMethod(method.id);
      ref.invalidate(paymentMethodsProvider);
    } catch (error) {
      if (context.mounted) showActionError(context, apiErrorMessage(error, t('Something went wrong.', 'Une erreur est survenue.', 'Algo salió mal.')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translateProvider);
    final methods = ref.watch(paymentMethodsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        methods.when(
          loading: () => const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator(color: AppColors.action))),
          error: (_, _) => Text(t('Could not load your methods.', 'Impossible de charger vos moyens de paiement.', 'No se pudieron cargar tus medios de pago.'), style: const TextStyle(color: AppColors.textMuted)),
          data: (items) => items.isEmpty
              ? Text(
                  t('No payment methods added yet. Add Zelle, Cash App, Crypto or a bank account so members can pay you.', 'Aucun moyen de paiement pour le moment. Ajoutez Zelle, Cash App, Crypto ou un compte bancaire pour que les membres puissent vous payer.', 'Todavía no hay medios de pago. Añade Zelle, Cash App, Cripto o una cuenta bancaria para que los miembros puedan pagarte.'),
                  style: const TextStyle(fontSize: 13, color: AppColors.textSoft),
                )
              : Column(
                  children: [
                    for (final m in items)
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.fromLTRB(12, 4, 4, 10),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(providerLabel(m.providerType, t), style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.action)),
                                ),
                                IconButton(
                                  tooltip: t('Delete method', 'Supprimer', 'Eliminar'),
                                  onPressed: () => _delete(context, ref, m, t),
                                  icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                            // Label above the value: « Adresse du portefeuille » and an address don't fit side by side at 320 px
                            for (final e in m.details.entries)
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(paymentFieldLabel(e.key, t), style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                        Text(e.value, style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: t('Copy', 'Copier', 'Copiar'),
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () => Clipboard.setData(ClipboardData(text: e.value)),
                                    icon: const Icon(Icons.copy, size: 14, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: () => showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            backgroundColor: AppColors.card,
            builder: (_) => const PaymentMethodSheet(),
          ),
          icon: const Icon(Icons.add),
          label: Text(t('Add Method', 'Ajouter', 'Añadir')),
        ),
      ],
    );
  }
}

class _Journey extends ConsumerWidget {
  const _Journey();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translateProvider);
    final history = ref.watch(boardHistoryProvider).value ?? const <BoardHistoryItem>[];

    if (history.isEmpty) {
      return Text(
        t('Not on any board yet.', "Pas encore sur un board.", 'Todavía no estás en ningún tablero.'),
        style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
      );
    }
    return Column(
      children: [
        for (final item in history)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(width: 4, height: 36, decoration: BoxDecoration(color: gemstoneFor(item.levelId).accent, borderRadius: BorderRadius.circular(4))),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${item.levelName} · \$${formatAmount(item.amount)}', style: const TextStyle(fontWeight: FontWeight.w800)),
                      Text(
                        t('Received ${item.receivedCount} / ${item.requiredContributors}', 'Reçu ${item.receivedCount} / ${item.requiredContributors}', 'Recibido ${item.receivedCount} / ${item.requiredContributors}'),
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                _Tag(
                  item.isDone
                      ? '✓ ${t('Done', 'Terminé', 'Terminado')}'
                      : item.status == 'CENTER'
                          ? t('Center', 'Centre', 'Centro')
                          : t('In line', 'Dans la file', 'En la fila'),
                  item.isDone ? AppColors.success : AppColors.action,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Signatures extends ConsumerWidget {
  const _Signatures();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translateProvider);
    final signatures = ref.watch(mySignaturesProvider).value ?? const <LegalAcceptance>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 4,
          children: [
            TextButton(
              onPressed: () => launchUrl(Uri.parse('${AppConfig.websiteUrl}/terms'), mode: LaunchMode.externalApplication),
              child: Text(t('Terms of Use', "Conditions d'utilisation", 'Condiciones de uso')),
            ),
            TextButton(
              onPressed: () => launchUrl(Uri.parse('${AppConfig.websiteUrl}/privacy'), mode: LaunchMode.externalApplication),
              child: Text(t('Privacy Policy', 'Politique de confidentialité', 'Política de privacidad')),
            ),
          ],
        ),
        if (signatures.isEmpty)
          Text(t('No signature yet.', 'Aucune signature pour le moment.', 'Todavía no hay firmas.'), style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
        for (final s in signatures)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '✍️ ${s.documentType == 'TERMS' ? t('Terms of Use', "Conditions d'utilisation", 'Condiciones de uso') : t('Privacy Policy', 'Politique de confidentialité', 'Política de privacidad')} v${s.documentVersion}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                ),
                Text(
                  '${shortDate(s.acceptedAt, t)} • ${s.context == 'REGISTRATION' ? t('At sign-up', "À l'inscription", 'Al registrarse') : t('Document update', 'Mise à jour du document', 'Actualización del documento')} • ${t('IP address:', 'Adresse IP :', 'Dirección IP:')} ${s.ipAddress ?? '—'}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.icon, required this.iconColor, required this.title, required this.child, this.subtitle});

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800))),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label, this.color);

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: '$label : ', style: const TextStyle(color: AppColors.textMuted)),
            TextSpan(text: value, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        style: const TextStyle(fontSize: 13),
      ),
    );
  }
}
