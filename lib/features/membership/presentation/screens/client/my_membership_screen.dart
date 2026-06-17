import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:barber_hub/core/theme/app_theme.dart';
import 'package:barber_hub/core/routes/app_routes.dart';
import 'package:barber_hub/features/auth/presentation/providers/auth_providers.dart';
import 'package:barber_hub/features/membership/domain/entities/membership_entity.dart';
import 'package:barber_hub/features/membership/domain/entities/membership_plan_entity.dart';
import 'package:barber_hub/features/membership/presentation/providers/membership_providers.dart';
import 'package:barber_hub/features/membership/presentation/providers/membership_state.dart';
import 'package:barber_hub/features/membership/presentation/models/membership_plans_args.dart';
import 'package:barber_hub/features/membership/presentation/widgets/membership_widgets.dart';

/// Tela central de assinaturas do cliente —
/// exibe assinaturas ativas e permite gestão (pausar, cancelar).
class MyMembershipScreen extends ConsumerStatefulWidget {
  const MyMembershipScreen({super.key});

  @override
  ConsumerState<MyMembershipScreen> createState() => _State();
}

class _State extends ConsumerState<MyMembershipScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final authState = ref.read(authNotifierProvider);
    if (authState is AuthAuthenticated) {
      ref
          .read(clientMembershipProvider.notifier)
          .load(clientId: authState.user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ClientMembershipState>(clientMembershipProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!)),
        );
        ref.read(clientMembershipProvider.notifier).clearMessages();
      } else if (next.successMessage != null &&
          next.successMessage != prev?.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.successMessage!)),
        );
        ref.read(clientMembershipProvider.notifier).clearMessages();
      }
    });

    final state = ref.watch(clientMembershipProvider);
    final authState = ref.watch(authNotifierProvider);
    final userName = authState is AuthAuthenticated
        ? authState.user.name.split(' ').first
        : 'você';

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ──────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.gold.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppTheme.gold.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.workspace_premium_rounded,
                                  color: AppTheme.gold, size: 11),
                              const SizedBox(width: 5),
                              Text(
                                'MEMBERSHIP',
                                style: GoogleFonts.jost(
                                    color: AppTheme.gold,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Olá, $userName!',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontSize: 26),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Gerencie suas assinaturas.',
                      style: GoogleFonts.jost(
                          color: AppTheme.textSecondary, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 28)),

            // ── Loading ──────────────────────────────────────────────────
            if (state.isLoading)
              const SliverFillRemaining(
                child: Center(
                    child:
                        CircularProgressIndicator(color: AppTheme.gold)),
              )

            // ── Empty state ──────────────────────────────────────────────
            else if (state.memberships.isEmpty)
              SliverFillRemaining(
                child: _EmptyState(
                  onExplore: () =>
                      Navigator.pushNamed(context, AppRoutes.home),
                ),
              )

            // ── Memberships ──────────────────────────────────────────────
            else ...[
              // Ativas
              SliverToBoxAdapter(
                child: _SectionLabel(
                  label: 'ATIVAS',
                  count: state.memberships
                      .where((m) => m.status == MembershipStatus.active)
                      .length,
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) {
                      final active = state.memberships
                          .where((m) => m.status == MembershipStatus.active)
                          .toList();
                      if (i >= active.length) return null;
                      return ActiveMembershipCard(
                        membership: active[i],
                        onTap: () => _showManageSheet(active[i]),
                      );
                    },
                    childCount: state.memberships
                        .where((m) => m.status == MembershipStatus.active)
                        .length,
                  ),
                ),
              ),

              // Outras (pausadas, canceladas)
              if (state.memberships
                  .any((m) => m.status != MembershipStatus.active)) ...[
                SliverToBoxAdapter(
                  child: _SectionLabel(
                    label: 'INATIVAS',
                    count: state.memberships
                        .where((m) => m.status != MembershipStatus.active)
                        .length,
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) {
                        final inactive = state.memberships
                            .where((m) =>
                                m.status != MembershipStatus.active)
                            .toList();
                        if (i >= inactive.length) return null;
                        return ActiveMembershipCard(
                          membership: inactive[i],
                          onTap: inactive[i].status ==
                                  MembershipStatus.paused
                              ? () => _showManageSheet(inactive[i])
                              : null,
                        );
                      },
                      childCount: state.memberships
                          .where(
                              (m) => m.status != MembershipStatus.active)
                          .length,
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  void _showManageSheet(MembershipEntity membership) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _ManageSheet(
        membership: membership,
        onUpgrade: () {
          Navigator.pop(context);
          Navigator.pushNamed(
            context,
            AppRoutes.membershipPlans,
            arguments: MembershipPlansArgs(
              shopId: membership.barbershopId,
              shopName: membership.barbershopName,
            ),
          );
        },
        onPause: () {
          Navigator.pop(context);
          ref
              .read(clientMembershipProvider.notifier)
              .pause(membership.id);
        },
        onResume: () {
          Navigator.pop(context);
          ref
              .read(clientMembershipProvider.notifier)
              .resume(membership.id);
        },
        onCancel: () {
          Navigator.pop(context);
          _confirmCancel(membership);
        },
      ),
    );
  }

  void _confirmCancel(MembershipEntity membership) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surfaceElevated,
        title: Text(
          'Cancelar assinatura?',
          style: GoogleFonts.jost(
              color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Você perderá os benefícios do plano ${membership.plan.name} na ${membership.barbershopName}. Esta ação não pode ser desfeita.',
          style: GoogleFonts.jost(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Manter',
                style: GoogleFonts.jost(color: AppTheme.gold)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(clientMembershipProvider.notifier)
                  .cancel(membership.id);
            },
            child: Text('Cancelar assinatura',
                style: GoogleFonts.jost(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }
}

// ── Auxiliares ────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final int count;
  const _SectionLabel({required this.label, required this.count});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
        child: Row(
          children: [
            Text(
              label,
              style: GoogleFonts.jost(
                  color: AppTheme.textHint,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3),
            ),
            const SizedBox(width: 10),
            Expanded(child: Container(height: 1, color: AppTheme.divider)),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.jost(
                    color: AppTheme.textSecondary, fontSize: 11),
              ),
            ),
          ],
        ),
      );
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onExplore;
  const _EmptyState({required this.onExplore});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.gold.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: AppTheme.gold.withValues(alpha: 0.2)),
              ),
              child: const Icon(Icons.workspace_premium_outlined,
                  color: AppTheme.gold, size: 40),
            ),
            const SizedBox(height: 24),
            Text(
              'Sem assinaturas',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontSize: 22),
            ),
            const SizedBox(height: 12),
            Text(
              'Explore as barbearias e assine um plano para cortes mensais com desconto.',
              style: GoogleFonts.jost(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: onExplore,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.gold,
                  foregroundColor: AppTheme.background,
                  shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.all(Radius.circular(4))),
                ),
                child: Text(
                  'EXPLORAR BARBEARIAS',
                  style: GoogleFonts.jost(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      letterSpacing: 1.5),
                ),
              ),
            ),
          ],
        ),
      );
}

class _ManageSheet extends StatelessWidget {
  final MembershipEntity membership;
  final VoidCallback onUpgrade;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onCancel;

  const _ManageSheet({
    required this.membership,
    required this.onUpgrade,
    required this.onPause,
    required this.onResume,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = membership.status == MembershipStatus.active;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Plano ${membership.plan.name}',
            style: GoogleFonts.jost(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700),
          ),
          Text(
            membership.barbershopName,
            style: GoogleFonts.jost(
                color: AppTheme.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 20),
          if (isActive && membership.plan.tier != MembershipTier.vip)
            _SheetAction(
              icon: Icons.upgrade_rounded,
              label: 'Fazer upgrade',
              subtitle: 'Mudar para um plano superior',
              color: const Color(0xFFB87FE8),
              onTap: onUpgrade,
            ),
        if (isActive)
            _SheetAction(
              icon: Icons.pause_circle_outline_rounded,
              label: 'Pausar assinatura',
              subtitle: 'Suspende a cobrança temporariamente',
              color: AppTheme.gold,
              onTap: onPause,
            )
          else
            _SheetAction(
              icon: Icons.play_circle_outline_rounded,
              label: 'Reativar assinatura',
              subtitle: 'Retoma as cobranças e benefícios',
              color: Colors.green,
              onTap: onResume,
            ),
          const SizedBox(height: 8),
          _SheetAction(
            icon: Icons.cancel_outlined,
            label: 'Cancelar assinatura',
            subtitle: 'Encerra o plano permanentemente',
            color: AppTheme.error,
            onTap: onCancel,
          ),
        ],
      ),
    );
  }
}

class _SheetAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _SheetAction({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.inputBorder),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.jost(
                          color: color,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  Text(subtitle,
                      style: GoogleFonts.jost(
                          color: AppTheme.textHint, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      );
}
