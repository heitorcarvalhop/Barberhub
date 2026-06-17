import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:barber_hub/core/theme/app_theme.dart';
import 'package:barber_hub/features/auth/presentation/providers/auth_providers.dart';
import 'package:barber_hub/features/membership/domain/entities/membership_entity.dart';
import 'package:barber_hub/features/membership/presentation/providers/membership_providers.dart';
import 'package:barber_hub/features/membership/presentation/widgets/membership_widgets.dart';
import 'package:barber_hub/features/membership/presentation/models/membership_plans_args.dart';
import 'package:barber_hub/shared/widgets/app_widgets.dart';

/// Tela de seleção de planos de uma barbearia — lado do cliente.
class MembershipPlansScreen extends ConsumerStatefulWidget {
  const MembershipPlansScreen({super.key});

  @override
  ConsumerState<MembershipPlansScreen> createState() =>
      _MembershipPlansScreenState();
}

class _MembershipPlansScreenState extends ConsumerState<MembershipPlansScreen> {
  String? _selectedPlanId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as MembershipPlansArgs?;
    if (args != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(clientMembershipProvider.notifier)
            .loadPlansForShop(args.shopId);
      });
    }
  }

  Future<void> _subscribe(MembershipPlansArgs args) async {
    if (_selectedPlanId == null) return;

    final authState = ref.read(authNotifierProvider);
    if (authState is! AuthAuthenticated) return;

    final success = await ref.read(clientMembershipProvider.notifier).subscribe(
          clientId: authState.user.id,
          clientName: authState.user.name,
          shopId: args.shopId,
          planId: _selectedPlanId!,
        );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(children: [
            Icon(Icons.check_circle_outline, color: AppTheme.gold, size: 18),
            SizedBox(width: 10),
            Text('Assinatura ativada com sucesso!'),
          ]),
        ),
      );
      Navigator.pop(context);
    } else {
      final error = ref.read(clientMembershipProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Erro ao assinar plano.')),
      );
    }
  }

  Future<void> _upgrade(MembershipEntity activePlan) async {
    if (_selectedPlanId == null || _selectedPlanId == activePlan.plan.id) {
      return;
    }

    final success = await ref
        .read(clientMembershipProvider.notifier)
        .upgrade(activePlan.id, _selectedPlanId!);

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(children: [
            Icon(Icons.check_circle_outline, color: AppTheme.gold, size: 18),
            SizedBox(width: 10),
            Text('Plano atualizado com sucesso!'),
          ]),
        ),
      );
      Navigator.pop(context);
    } else {
      final error = ref.read(clientMembershipProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Erro ao atualizar plano.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as MembershipPlansArgs?;
    final membershipState = ref.watch(clientMembershipProvider);
    final authState = ref.watch(authNotifierProvider);
    final clientId = authState is AuthAuthenticated ? authState.user.id : null;

    // Plano já ativo para esta shop
    final activePlan = clientId != null && args != null
        ? membershipState.activeForShop(args.shopId)
        : null;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: AppTheme.textSecondary, size: 18),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ASSINATURA',
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(
                                  color: AppTheme.gold,
                                  fontSize: 10,
                                  letterSpacing: 4),
                        ),
                        Text(
                          args?.shopName ?? 'Planos',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(fontSize: 22),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── Subtitle ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Text(
                'Cobrança recorrente mensal. Cancele quando quiser.',
                style: GoogleFonts.jost(
                    color: AppTheme.textSecondary, fontSize: 13),
              ),
            ),

            // ── Plans ───────────────────────────────────────────────────
            Expanded(
              child: membershipState.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.gold))
                  : membershipState.availablePlans.isEmpty
                      ? Center(
                          child: Text(
                            'Nenhum plano disponível.',
                            style:
                                GoogleFonts.jost(color: AppTheme.textSecondary),
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                          children: membershipState.availablePlans
                              .where((p) => p.isActive)
                              .map((plan) => MembershipPlanCard(
                                    plan: plan,
                                    isSelected: _selectedPlanId == plan.id,
                                    isCurrentPlan:
                                        activePlan?.plan.id == plan.id,
                                    onTap: activePlan != null &&
                                            activePlan.plan.id == plan.id
                                        ? null
                                        : () => setState(
                                            () => _selectedPlanId = plan.id),
                                  ))
                              .toList(),
                        ),
            ),
          ],
        ),
      ),
      // ── CTA Button ────────────────────────────────────────────────────
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          border: Border(top: BorderSide(color: AppTheme.divider, width: 1)),
        ),
        child: PrimaryButton(
          label: _ctaLabel(activePlan),
          onPressed: _selectedPlanId == null ||
                  args == null ||
                  _selectedPlanId == activePlan?.plan.id
              ? null
              : () => activePlan != null
                  ? _upgrade(activePlan)
                  : _subscribe(args),
          isLoading: membershipState.isSubscribing,
        ),
      ),
    );
  }

  String _ctaLabel(MembershipEntity? activePlan) {
    if (_selectedPlanId == null) return 'Selecione um plano';
    if (activePlan == null) return 'Assinar plano selecionado';
    if (_selectedPlanId == activePlan.plan.id) return 'Plano atual';
    return 'Confirmar upgrade';
  }
}
