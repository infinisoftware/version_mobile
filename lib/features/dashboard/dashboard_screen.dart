import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config.dart';
import '../../core/i18n.dart';
import '../../models/level.dart';
import '../../models/user.dart';
import '../../theme/app_colors.dart';
import '../auth/auth_controller.dart';
import '../shell/top_actions.dart';
import 'dashboard_providers.dart';
import 'level_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  Timer? _refresh;
  int? _selectedLevelId;

  @override
  void initState() {
    super.initState();
    // Same pace as the level cards of the website
    _refresh = Timer.periodic(const Duration(seconds: 20), (_) => ref.invalidate(levelsProvider));
  }

  @override
  void dispose() {
    _refresh?.cancel();
    super.dispose();
  }

  Future<void> _reload() async {
    ref.invalidate(showLineRanksProvider);
    ref.invalidate(levelsProvider);
    try {
      await ref.read(levelsProvider.future);
    } catch (_) {
      // The error card is already on screen, with its « Try again » button
    }
  }

  void _showNotAvailable(Translate t) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          t(
            'Payments are coming to the mobile app. Use the website for now.',
            "Les paiements arrivent bientôt sur l'application. Utilisez le site pour l'instant.",
            'Los pagos llegarán pronto a la aplicación. Por ahora usa el sitio web.',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translateProvider);
    final user = ref.watch(authProvider).user;
    final levels = ref.watch(levelsProvider);
    final showRanks = ref.watch(showLineRanksProvider).value ?? true;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Image.asset('assets/images/logo.png', width: 32, height: 32),
            const SizedBox(width: 10),
            const Flexible(
              child: Text(
                'THE GIFT EXCHANGE',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.8),
              ),
            ),
          ],
        ),
        actions: const [TopActions()],
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: AppColors.action,
          onRefresh: _reload,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (user != null) ...[
                Text(
                  '${t('Welcome', 'Bienvenue', 'Bienvenido')}, ${user.fullName.toUpperCase()}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 14),
                _ProfileCard(user: user),
                const SizedBox(height: 16),
              ],
              levels.when(
                skipLoadingOnReload: true,
                skipLoadingOnRefresh: true,
                loading: () => const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator(color: AppColors.action)),
                ),
                error: (_, _) => _LoadError(onRetry: _reload),
                data: (items) => _Ladder(
                  levels: items,
                  user: user,
                  showRanks: showRanks,
                  selectedLevelId: _selectedLevelId,
                  onOpenBoard: (id) {
                    setState(() => _selectedLevelId = id);
                    context.go('/dashboard/board/$id');
                  },
                  onPay: () => _showNotAvailable(t),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends ConsumerWidget {
  const _ProfileCard({required this.user});

  final User user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translateProvider);
    final inviteLink = '${AppConfig.websiteUrl}/register?ref=${user.inviteCode}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.avatar,
                child: Text(user.initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.fullName.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text(
                      user.email,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            t('Your invite link', "Votre lien d'invitation", 'Tu enlace de invitación'),
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  inviteLink,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSoft),
                ),
              ),
              TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: inviteLink));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(t('Link copied', 'Lien copié', 'Enlace copiado'))),
                  );
                },
                child: Text(t('Copy', 'Copier', 'Copiar')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Ladder extends ConsumerWidget {
  const _Ladder({
    required this.levels,
    required this.user,
    required this.showRanks,
    required this.selectedLevelId,
    required this.onOpenBoard,
    required this.onPay,
  });

  final List<Level> levels;
  final User? user;
  final bool showRanks;
  final int? selectedLevelId;
  final ValueChanged<int> onOpenBoard;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translateProvider);
    final completed = levels.where((l) => l.isCompleted).length;
    final active = levels.where((l) => l.isActive).length;
    final enteredMatrix = completed + active > 0;
    final qualified = (user?.isQualified ?? false) || enteredMatrix;

    final status = completed == levels.length
        ? t('Completed', 'Terminé', 'Completado')
        : enteredMatrix
            ? t('In progress', 'En cours', 'En curso')
            : t('Not started', 'Pas commencé', 'Sin empezar');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(colors: AppColors.ladderBanner),
          ),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 12,
            runSpacing: 6,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t('Your ladder', 'Votre échelle', 'Tu escalera'),
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                  Text(status, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                ],
              ),
              Text(
                t(
                  'Ladder progress ($completed of ${levels.length} done)',
                  'Progression ($completed sur ${levels.length} terminés)',
                  'Progreso ($completed de ${levels.length} terminados)',
                ),
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        ),
        for (final level in levels) ...[
          const SizedBox(height: 14),
          LevelCard(
            level: level,
            qualified: qualified,
            showRanks: showRanks,
            selected: level.id == selectedLevelId,
            onSelect: () => onOpenBoard(level.id),
            // Already in the line: the board; otherwise joining starts with a payment
            onAction: level.isActive ? () => onOpenBoard(level.id) : onPay,
          ),
        ],
      ],
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
              'The levels could not be loaded. Check your connection and try again.',
              'Les niveaux n’ont pas pu être chargés. Vérifiez votre connexion et réessayez.',
              'No se pudieron cargar los niveles. Revisa tu conexión e inténtalo de nuevo.',
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
