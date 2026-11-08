import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n.dart';
import '../../models/board.dart';
import '../../theme/app_colors.dart';
import '../../theme/gemstone.dart';
import '../auth/auth_controller.dart';
import '../dashboard/dashboard_providers.dart';
import '../dashboard/level_card.dart';
import '../shell/top_actions.dart';
import 'board_providers.dart';

const _amber = Color(0xFFFBBF24);
const _amberSoft = Color(0xFFFCD34D);
const _rose = Color(0xFFFDA4AF);
const _subCard = Color(0xE60F172A);

class BoardScreen extends ConsumerStatefulWidget {
  const BoardScreen({super.key, required this.levelId});

  final int levelId;

  @override
  ConsumerState<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends ConsumerState<BoardScreen> {
  Timer? _refresh;

  int get _levelId => widget.levelId;

  @override
  void initState() {
    super.initState();
    // Same pace as the website: new gifts, confirmations and the 24h countdowns show up on their own
    _refresh = Timer.periodic(const Duration(seconds: 10), (_) => _invalidate());
  }

  @override
  void dispose() {
    _refresh?.cancel();
    super.dispose();
  }

  void _invalidate() {
    ref.invalidate(boardProvider(_levelId));
    ref.invalidate(boardLineProvider(_levelId));
    if (_levelId == 1) ref.invalidate(boardPendingProvider(_levelId));
  }

  Future<void> _reload() async {
    _invalidate();
    try {
      await ref.read(boardProvider(_levelId).future);
    } catch (_) {
      // The error card is already on screen, with its « Try again » button
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translateProvider);
    final board = ref.watch(boardProvider(_levelId));
    final title = board.value?.levelName ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(title.isEmpty ? t('Board', 'Board', 'Tablero') : t('$title Board', 'Board $title', 'Tablero $title')),
        actions: const [TopActions()],
      ),
      body: RefreshIndicator(
        color: AppColors.action,
        onRefresh: _reload,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            board.when(
              skipLoadingOnReload: true,
              skipLoadingOnRefresh: true,
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator(color: AppColors.action)),
              ),
              error: (_, _) => _LoadError(onRetry: _reload),
              data: (data) => _BoardCard(board: data),
            ),
          ],
        ),
      ),
    );
  }
}

class _BoardCard extends ConsumerWidget {
  const _BoardCard({required this.board});

  final Board board;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translateProvider);
    final gem = gemstoneFor(board.levelId);
    final slots = board.requiredContributors;
    final center = board.center;
    final line = ref.watch(boardLineProvider(board.levelId)).value ?? const <QueueEntry>[];
    final showRanks = ref.watch(showLineRanksProvider).value ?? true;
    final userId = ref.watch(authProvider).user?.id;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(height: 6, decoration: BoxDecoration(gradient: LinearGradient(colors: gem.header))),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(board: board, gem: gem, t: t),
                if (board.centerHasDispute) ...[
                  const SizedBox(height: 14),
                  _Notice(
                    icon: Icons.hourglass_top,
                    color: _amber,
                    title: t(
                      '${center?.name} is sorting out a payment with a donor',
                      '${center?.name} règle un paiement avec un donateur',
                      '${center?.name} está resolviendo un pago con un donante',
                    ),
                    body: t(
                      'A moderator is checking it. Payments to this member are paused for a short while — please wait a little before sending your gift.',
                      'Un modérateur vérifie ce paiement. Les paiements vers ce membre sont en pause un court instant — merci de patienter un peu avant d’envoyer votre don.',
                      'Un moderador lo está revisando. Los pagos a este miembro están en pausa un momento: espera un poco antes de enviar tu regalo.',
                    ),
                  ),
                ],
                if (board.centerDisputeResolved) ...[
                  const SizedBox(height: 14),
                  _Notice(
                    icon: Icons.check_circle_outline,
                    color: AppColors.success,
                    title: t(
                      'Settled — payments are open again',
                      'Réglé — les paiements sont de nouveau ouverts',
                      'Resuelto: los pagos están abiertos de nuevo',
                    ),
                    body: t(
                      'A moderator has settled the payment check involving ${center?.name}. You can send your gift normally.',
                      'Un modérateur a réglé la vérification de paiement concernant ${center?.name}. Vous pouvez envoyer votre don normalement.',
                      'Un moderador resolvió la revisión del pago de ${center?.name}. Puedes enviar tu regalo normalmente.',
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                _Progress(board: board, gem: gem, t: t),
                const SizedBox(height: 18),
                Center(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: board.levelName, style: TextStyle(color: gem.tileText)),
                        TextSpan(text: ' — \$${formatAmount(board.amount)}'),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Pill(
                      t('Needs $slots contributors', '$slots contributeurs requis', 'Se necesitan $slots contribuyentes'),
                      foreground: AppColors.textSoft,
                      background: AppColors.background,
                      border: AppColors.border,
                    ),
                    _Pill(
                      t('${board.confirmedCount} in', '${board.confirmedCount} reçus', '${board.confirmedCount} recibidos'),
                      foreground: gem.badgeText,
                      background: gem.accent.withValues(alpha: 0.15),
                      border: gem.accent.withValues(alpha: 0.4),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _SectionTitle(t('CONTRIBUTORS', 'CONTRIBUTEURS', 'CONTRIBUYENTES')),
                for (final contributor in board.contributors)
                  _ContributorRow(contributor: contributor, userId: userId, centerId: center?.id, t: t),
                if (board.emptySlots > 0) _EmptySlots(count: board.emptySlots, gem: gem),
                const SizedBox(height: 16),
                _SectionTitle(t('NEXT IN LINE', 'PROCHAIN DANS LA FILE', 'SIGUIENTE EN LA FILA')),
                _Row(
                  children: [
                    if (board.nextInLine != null) ...[
                      _Avatar(name: board.nextInLine!.name),
                      const SizedBox(width: 10),
                      Expanded(child: _Name(board.nextInLine!.name)),
                    ] else
                      Expanded(
                        child: Text(
                          t(
                            'Waiting for next member in line',
                            'En attente du prochain membre dans la file',
                            'Esperando al siguiente miembro de la fila',
                          ),
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                _SectionTitle(t('RECEIVING NOW', 'REÇOIT MAINTENANT', 'RECIBE AHORA')),
                _ReceivingNow(board: board, t: t),
                const Divider(color: AppColors.border, height: 32),
                _LineSection(board: board, line: line, showRanks: showRanks, gem: gem, t: t),
                if (board.levelId == 1) ...[
                  const Divider(color: AppColors.border, height: 32),
                  _PendingSection(levelId: board.levelId, levelName: board.levelName, t: t),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.board, required this.gem, required this.t});

  final Board board;
  final Gemstone gem;
  final Translate t;

  @override
  Widget build(BuildContext context) {
    final center = board.center;

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.start,
      spacing: 12,
      runSpacing: 10,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 6,
          children: [
            _Pill(
              '${t('Level', 'Niveau', 'Nivel')} ${board.levelId}',
              foreground: gem.badgeText,
              background: gem.accent.withValues(alpha: 0.15),
              border: gem.accent.withValues(alpha: 0.4),
            ),
            Text(
              t('${board.levelName} Board', 'Board ${board.levelName}', 'Tablero ${board.levelName}'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: gem.tileText),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              t('Receiving now', 'Reçoit maintenant', 'Recibe ahora'),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _amber),
            ),
            Text(
              center?.name.toUpperCase() ?? t('Waiting...', 'En attente...', 'Esperando...'),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
            if (center != null && center.strikesCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: _Pill(
                  '⚠️ Strike ${center.strikesCount}/3',
                  foreground: _amberSoft,
                  background: const Color(0x33F59E0B),
                  border: const Color(0x80F59E0B),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.board, required this.gem, required this.t});

  final Board board;
  final Gemstone gem;
  final Translate t;

  @override
  Widget build(BuildContext context) {
    final slots = board.requiredContributors;
    final ratio = (board.confirmedCount / slots).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _subCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  t('Contributors this cycle', 'Contributeurs ce cycle', 'Contribuyentes de este ciclo'),
                  style: const TextStyle(fontSize: 12, color: AppColors.textSoft),
                ),
              ),
              Text(
                '${board.confirmedCount} ${t('of', 'sur', 'de')} $slots',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) => Container(
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFF020617),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              alignment: Alignment.centerLeft,
              child: Container(
                width: constraints.maxWidth * (ratio == 0 ? 0 : ratio.clamp(0.08, 1.0)),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(colors: gem.header),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContributorRow extends StatelessWidget {
  const _ContributorRow({required this.contributor, required this.userId, required this.centerId, required this.t});

  final Contributor contributor;
  final String? userId;
  final String? centerId;
  final Translate t;

  @override
  Widget build(BuildContext context) {
    final c = contributor;
    final name = c.isFromSupport ? '🤝 ${t('Support team', 'Équipe Support', 'Equipo de Soporte')}' : c.name;
    final provider = [
      if (c.providerUsed != null) c.providerUsed!,
      if (c.transactionRef != null) '${t('Ref', 'Réf', 'Ref')}: ${c.transactionRef}',
    ].join(' • ');

    String? kindLabel;
    if (c.kind == 'SUPPORT_SHARE') {
      kindLabel = '🤝 ${t('Paid to the Support team (2nd gift)', "Payé à l'équipe Support (2ᵉ don)", 'Pagado al equipo de Soporte (2.º regalo)')}';
    } else if (c.kind == 'SUPPORT_FUNDING' || c.kind == 'TICKET') {
      kindLabel = t(
        'Gift from the Support cash — no place in line',
        'Don de la caisse Support — sans place dans la file',
        'Regalo de la caja de Soporte: sin lugar en la fila',
      );
    } else if (c.kind == 'SUPPORT_SLOT') {
      kindLabel = '🤝 ${t('2nd gift passed by the Support team', "2ᵉ don passé par l'équipe Support", '2.º regalo pasado por el equipo de Soporte')}';
    }

    // The Center confirms only the gifts paid to them: the 2nd one is confirmed by the Support team
    final viewerIsCenter = userId != null && userId == centerId;

    return _Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Avatar(name: c.isFromSupport ? 'S' : c.name),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Name(name),
              if (kindLabel != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(kindLabel, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.info)),
                ),
              if (provider.isNotEmpty)
                Text(provider, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (c.isConfirmed)
                    _Pill(
                      t('Confirmed', 'Confirmé', 'Confirmado'),
                      foreground: AppColors.success,
                      background: const Color(0x3310B981),
                      border: const Color(0x6610B981),
                    )
                  else if (c.isPending) ...[
                    _Countdown(sentAt: c.sentAt, t: t),
                    _Pill(
                      t('Pending', 'En attente', 'Pendiente'),
                      foreground: _amberSoft,
                      background: const Color(0x33F59E0B),
                      border: const Color(0x66F59E0B),
                    ),
                    if (viewerIsCenter && c.receiverId != userId)
                      _Pill(
                        t('Confirmed by the Support team', "Confirmé par l'équipe Support", 'Lo confirma el equipo de Soporte'),
                        foreground: AppColors.textSoft,
                        background: const Color(0x99334155),
                        border: const Color(0xFF475569),
                      ),
                  ] else
                    _Pill(
                      t('Disputed', 'En litige', 'En disputa'),
                      foreground: _rose,
                      background: const Color(0x33F43F5E),
                      border: const Color(0x66F43F5E),
                    ),
                  if (c.hasProof)
                    _Pill(
                      t('Proof', 'Preuve', 'Prueba'),
                      foreground: AppColors.info,
                      background: const Color(0x2606B6D4),
                      border: const Color(0x6606B6D4),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 24h before an unconfirmed gift automatically becomes a dispute.
class _Countdown extends StatefulWidget {
  const _Countdown({required this.sentAt, required this.t});

  final DateTime? sentAt;
  final Translate t;

  @override
  State<_Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<_Countdown> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 30), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  String _label() {
    final sentAt = widget.sentAt;
    if (sentAt == null) return '24h 00m';
    final left = sentAt.add(const Duration(hours: 24)).difference(DateTime.now().toUtc());
    if (left.isNegative) return widget.t('Expired (auto-escalation)', 'Expiré (auto-escalade)', 'Vencido (escalado automático)');
    final minutes = (left.inMinutes % 60).toString().padLeft(2, '0');
    return '${left.inHours}h ${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    return _Pill(
      '⏱️ ${_label()}',
      foreground: AppColors.info,
      background: const Color(0x2606B6D4),
      border: const Color(0x6606B6D4),
      icon: Icons.schedule,
    );
  }
}

class _EmptySlots extends ConsumerWidget {
  const _EmptySlots({required this.count, required this.gem});

  final int count;
  final Gemstone gem;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translateProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: [
          for (var i = 0; i < count; i++)
            InkWell(
              customBorder: const CircleBorder(),
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    t(
                      'Payments are coming to the mobile app. Use the website for now.',
                      "Les paiements arrivent bientôt sur l'application. Utilisez le site pour l'instant.",
                      'Los pagos llegarán pronto a la aplicación. Por ahora usa el sitio web.',
                    ),
                  ),
                ),
              ),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xB30F172A),
                  border: Border.all(color: const Color(0xFF475569)),
                ),
                child: const Icon(Icons.add, size: 18, color: AppColors.textMuted),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReceivingNow extends StatelessWidget {
  const _ReceivingNow({required this.board, required this.t});

  final Board board;
  final Translate t;

  @override
  Widget build(BuildContext context) {
    final center = board.center;
    if (center == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Text(
          t('No active Center on this board yet.', 'Aucun Centre actif sur ce board pour le moment.', 'Todavía no hay un Centro activo en este tablero.'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0x2610B981)),
            child: _Avatar(name: center.name, size: 72, color: AppColors.receiving),
          ),
          const SizedBox(height: 10),
          Text(
            center.name.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5),
          ),
          if (board.centerHasDispute || center.strikesCount > 0) ...[
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                if (board.centerHasDispute)
                  _Pill(
                    '⏳ ${t('Payment being checked — please wait a little', 'Paiement en vérification — patientez un peu', 'Pago en revisión: espera un poco')}',
                    foreground: _amberSoft,
                    background: const Color(0x26F59E0B),
                    border: const Color(0x66F59E0B),
                  ),
                if (center.strikesCount > 0)
                  _Pill(
                    '⚠️ ${t('Warning badge', "Badge d'avertissement", 'Insignia de advertencia')} : Strike ${center.strikesCount}/3',
                    foreground: _amberSoft,
                    background: const Color(0x33F59E0B),
                    border: const Color(0x80F59E0B),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _LineSection extends StatelessWidget {
  const _LineSection({required this.board, required this.line, required this.showRanks, required this.gem, required this.t});

  final Board board;
  final List<QueueEntry> line;
  final bool showRanks;
  final Gemstone gem;
  final Translate t;

  @override
  Widget build(BuildContext context) {
    final slots = board.requiredContributors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          t('${board.levelName} line', 'File ${board.levelName}', 'Fila ${board.levelName}'),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          t(
            'Everyone still collecting, in order. The center receives first. Once all their payments are marked paid, the next person in line receives.',
            'Tous ceux qui attendent de recevoir, dans l’ordre. Le Centre reçoit en premier. Une fois tous ses paiements confirmés, la personne suivante reçoit.',
            'Todos los que esperan recibir, en orden. El Centro recibe primero. Cuando todos sus pagos están confirmados, recibe la siguiente persona.',
          ),
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.4),
        ),
        const SizedBox(height: 10),
        if (line.isEmpty && board.center == null)
          Text(
            t('Nobody in line yet.', "Personne dans la file pour l'instant.", 'Todavía no hay nadie en la fila.'),
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        for (final entry in line)
          _Row(
            children: [
              if (showRanks)
                SizedBox(
                  width: 34,
                  child: Text(
                    '#${entry.position}',
                    style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: AppColors.textMuted),
                  ),
                ),
              _Avatar(name: entry.name),
              const SizedBox(width: 10),
              // « X / 6 » under the name: on a 320 px phone the row has no room for it beside the badge
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Name(entry.name),
                    Text(
                      '${entry.receivedCount} / $slots',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              entry.isCenter
                  ? _Pill(
                      t('Center', 'Centre', 'Centro'),
                      foreground: _amberSoft,
                      background: const Color(0x33F59E0B),
                      border: const Color(0x66F59E0B),
                    )
                  : _Pill(
                      t('Waiting', 'En attente', 'Esperando'),
                      foreground: gem.badgeText,
                      background: gem.accent.withValues(alpha: 0.15),
                      border: gem.accent.withValues(alpha: 0.4),
                    ),
            ],
          ),
      ],
    );
  }
}

class _PendingSection extends ConsumerWidget {
  const _PendingSection({required this.levelId, required this.levelName, required this.t});

  final int levelId;
  final String levelName;
  final Translate t;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(boardPendingProvider(levelId)).value ?? const <PendingMember>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(t('Pending', 'En attente', 'Pendientes'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(
          t(
            "Not in the $levelName line yet. A place needs 2 people signed up with their invite link (email confirmed), a payment, then the receiver's confirmation.",
            "Pas encore dans la file $levelName. Une place demande 2 inscrits avec son lien d'invitation (email confirmé), un paiement, puis la confirmation du receveur.",
            'Todavía no están en la fila $levelName. Un lugar requiere 2 personas registradas con su enlace (correo confirmado), un pago y la confirmación de quien recibe.',
          ),
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.4),
        ),
        const SizedBox(height: 10),
        if (members.isEmpty)
          _Row(
            children: [
              Expanded(
                child: Text(
                  t('No pending members right now.', 'Aucun membre en attente pour le moment.', 'No hay miembros pendientes por ahora.'),
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ),
            ],
          ),
        for (final member in members)
          _Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Avatar(name: member.name),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Name(member.name),
                    const SizedBox(height: 6),
                    _stagePill(member),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _stagePill(PendingMember member) {
    switch (member.stage) {
      case 'AWAITING_PAYMENT':
        return _Pill(
          t('Ready to pay', 'Prêt à payer', 'Listo para pagar'),
          foreground: AppColors.info,
          background: const Color(0x2606B6D4),
          border: const Color(0x6606B6D4),
        );
      case 'AWAITING_CONFIRMATION':
        return _Pill(
          t('Paid — awaiting confirmation', 'Payé — en attente de confirmation', 'Pagado: esperando confirmación'),
          foreground: _amberSoft,
          background: const Color(0x33F59E0B),
          border: const Color(0x66F59E0B),
        );
      default:
        final count = member.referralCount.clamp(0, 2);
        return _Pill(
          t('$count / 2 confirmed sign-ups', '$count / 2 inscrits confirmés', '$count / 2 registros confirmados'),
          foreground: AppColors.textSoft,
          background: const Color(0x99334155),
          border: const Color(0xFF475569),
        );
    }
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        '• $text',
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: AppColors.textMuted),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.children, this.crossAxisAlignment = CrossAxisAlignment.center});

  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _subCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(crossAxisAlignment: crossAxisAlignment, children: children),
    );
  }
}

class _Name extends StatelessWidget {
  const _Name(this.name);

  final String name;

  @override
  Widget build(BuildContext context) {
    return Text(
      name.toUpperCase(),
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, this.size = 32, this.color = AppColors.avatar});

  final String name;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).take(2);
    final initials = parts.isEmpty ? '?' : parts.map((p) => p[0]).join().toUpperCase();

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: color,
      child: Text(
        initials,
        style: TextStyle(fontSize: size * 0.36, fontWeight: FontWeight.w800, color: Colors.white),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.label, {required this.foreground, required this.background, required this.border, this.icon});

  final String label;
  final Color foreground;
  final Color background;
  final Color border;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 12, color: foreground), const SizedBox(width: 4)],
          Flexible(
            child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: foreground)),
          ),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.color, required this.title, required this.body});

  final IconData icon;
  final Color color;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
                const SizedBox(height: 2),
                Text(body, style: const TextStyle(fontSize: 12, color: AppColors.textSoft)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadError extends ConsumerWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translateProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 32),
          const SizedBox(height: 10),
          Text(
            t(
              'The board could not be loaded. Check your connection and try again.',
              "Le board n'a pas pu être chargé. Vérifiez votre connexion et réessayez.",
              'No se pudo cargar el tablero. Revisa tu conexión e inténtalo de nuevo.',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: Text(t('Try again', 'Réessayer', 'Reintentar'))),
        ],
      ),
    );
  }
}
