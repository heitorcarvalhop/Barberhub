import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:barber_hub/core/theme/app_theme.dart';
import 'package:barber_hub/features/auth/presentation/providers/auth_providers.dart';
import 'package:barber_hub/features/membership/domain/entities/membership_entity.dart';
import 'package:barber_hub/features/membership/domain/entities/membership_plan_entity.dart';
import 'package:barber_hub/features/membership/presentation/providers/membership_providers.dart';
import 'package:barber_hub/features/membership/presentation/providers/membership_state.dart';
import 'package:barber_hub/features/membership/presentation/widgets/membership_widgets.dart';
import 'package:barber_hub/features/barber_shop/presentation/widgets/bs_widgets.dart';

/// Painel de gestão de assinaturas para o proprietário da barbearia.
class MembershipManagementScreen extends ConsumerStatefulWidget {
  const MembershipManagementScreen({super.key});

  @override
  ConsumerState<MembershipManagementScreen> createState() => _State();
}

class _State extends ConsumerState<MembershipManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  void _load() {
    final authState = ref.read(authNotifierProvider);
    if (authState is AuthAuthenticated) {
      final shopId = authState.user.linkedId;
      if (shopId != null) {
        ref.read(shopMembershipProvider.notifier).load(shopId);
      }
    }
  }

  void _confirmDeletePlan(MembershipPlanEntity plan) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: Text('Excluir plano',
            style: GoogleFonts.jost(
                color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
        content: Text(
          'Tem certeza que deseja excluir o plano "${plan.name}"? Esta ação não pode ser desfeita.',
          style: GoogleFonts.jost(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: GoogleFonts.jost(color: AppTheme.gold)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final ok = await ref
                  .read(shopMembershipProvider.notifier)
                  .deletePlan(plan.id);
              if (!mounted) return;
              if (ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Plano excluído.')),
                );
              } else {
                final error = ref.read(shopMembershipProvider).error;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(error ?? 'Erro ao excluir plano.')),
                );
              }
            },
            child: Text('Excluir', style: GoogleFonts.jost(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }

  void _openPlanForm({MembershipPlanEntity? existing}) {
    final authState = ref.read(authNotifierProvider);
    final shopId =
        authState is AuthAuthenticated ? authState.user.linkedId : null;
    if (shopId == null) return;

    final usedTiers = ref
        .read(shopMembershipProvider)
        .plans
        .where((p) => p.id != existing?.id)
        .map((p) => p.tier)
        .toSet();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _PlanFormSheet(
        shopId: shopId,
        existing: existing,
        usedTiers: usedTiers,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ShopMembershipState>(shopMembershipProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!)),
        );
      }
    });

    final state = ref.watch(shopMembershipProvider);
    final authState = ref.watch(authNotifierProvider);
    final shopId =
        authState is AuthAuthenticated ? authState.user.linkedId : null;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: AppTheme.textSecondary, size: 18),
                      ),
                      const SizedBox(width: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.gold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: AppTheme.gold.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.workspace_premium_rounded,
                                color: AppTheme.gold, size: 11),
                            const SizedBox(width: 5),
                            Text(
                              'MEMBERSHIPS',
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Assinaturas',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(fontSize: 28),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _openPlanForm(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.gold,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add_rounded,
                                  color: AppTheme.background, size: 18),
                              const SizedBox(width: 6),
                              Text('Novo plano',
                                  style: GoogleFonts.jost(
                                      color: AppTheme.background,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Stats Row ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  MembershipStatCard(
                    label: 'Assinantes',
                    value: '${state.activeSubscriberCount}',
                    icon: Icons.people_outline_rounded,
                    valueColor: AppTheme.gold,
                  ),
                  const SizedBox(width: 10),
                  MembershipStatCard(
                    label: 'Receita mensal',
                    value: 'R\$ ${state.monthlyRevenue.toStringAsFixed(0)}',
                    icon: Icons.attach_money_rounded,
                    valueColor: Colors.green,
                  ),
                  const SizedBox(width: 10),
                  MembershipStatCard(
                    label: 'Planos ativos',
                    value: '${state.plans.where((p) => p.isActive).length}',
                    icon: Icons.layers_outlined,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Tab Bar ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.inputBorder),
                ),
                child: TabBar(
                  controller: _tab,
                  indicator: BoxDecoration(
                    color: AppTheme.gold,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelStyle: GoogleFonts.jost(
                      fontSize: 12, fontWeight: FontWeight.w600),
                  unselectedLabelStyle: GoogleFonts.jost(
                      fontSize: 12, fontWeight: FontWeight.w400),
                  labelColor: AppTheme.background,
                  unselectedLabelColor: AppTheme.textSecondary,
                  tabs: const [
                    Tab(text: 'Assinantes'),
                    Tab(text: 'Planos'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Tab Content ──────────────────────────────────────────────
            Expanded(
              child: state.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.gold))
                  : TabBarView(
                      controller: _tab,
                      children: [
                        _SubscribersTab(
                          subscribers: state.subscribers,
                          onRegisterCut: shopId == null
                              ? null
                              : (id) => ref
                                  .read(shopMembershipProvider.notifier)
                                  .registerCutUsage(id),
                        ),
                        _PlansTab(
                          plans: state.plans,
                          isSaving: state.isSaving,
                          onToggle: shopId == null
                              ? null
                              : (planId) => ref
                                  .read(shopMembershipProvider.notifier)
                                  .togglePlan(shopId, planId),
                          onEdit: (plan) => _openPlanForm(existing: plan),
                          onDelete: (plan) => _confirmDeletePlan(plan),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tab: Assinantes ───────────────────────────────────────────────────────────

class _SubscribersTab extends StatelessWidget {
  final List<MembershipEntity> subscribers;
  final void Function(String membershipId)? onRegisterCut;

  const _SubscribersTab({
    required this.subscribers,
    this.onRegisterCut,
  });

  @override
  Widget build(BuildContext context) {
    final active = subscribers
        .where((s) => s.status == MembershipStatus.active)
        .toList()
      ..sort((a, b) => b.plan.tier.sortOrder.compareTo(a.plan.tier.sortOrder));

    if (active.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.people_outline_rounded,
                color: AppTheme.textHint, size: 48),
            const SizedBox(height: 12),
            Text(
              'Nenhum assinante ainda.',
              style: GoogleFonts.jost(color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      itemCount: active.length,
      separatorBuilder: (_, __) =>
          Container(height: 1, color: AppTheme.divider),
      itemBuilder: (_, i) => _SubscriberTile(
        membership: active[i],
        onRegisterCut:
            onRegisterCut == null ? null : () => onRegisterCut!(active[i].id),
      ),
    );
  }
}

class _SubscriberTile extends StatelessWidget {
  final MembershipEntity membership;
  final VoidCallback? onRegisterCut;

  const _SubscriberTile({
    required this.membership,
    this.onRegisterCut,
  });

  @override
  Widget build(BuildContext context) {
    final plan = membership.plan;
    final color = plan.tier.accentColor;
    final initials = membership.clientName
        .split(' ')
        .take(2)
        .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
        .join();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Center(
              child: Text(
                initials,
                style: GoogleFonts.jost(
                    color: color, fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  membership.clientName,
                  style: GoogleFonts.jost(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14),
                ),
                Row(
                  children: [
                    Icon(plan.tier.icon, color: color, size: 11),
                    const SizedBox(width: 4),
                    Text(
                      'Plano ${plan.name}',
                      style: GoogleFonts.jost(color: color, fontSize: 11),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${membership.cutsUsedThisMonth} corte${membership.cutsUsedThisMonth != 1 ? 's' : ''} este mês',
                      style: GoogleFonts.jost(
                          color: AppTheme.textHint, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Registrar corte
          if (membership.hasCutsAvailable && onRegisterCut != null)
            GestureDetector(
              onTap: onRegisterCut,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.content_cut_rounded, color: color, size: 13),
                    const SizedBox(width: 4),
                    Text(
                      '+Corte',
                      style: GoogleFonts.jost(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Tab: Planos ───────────────────────────────────────────────────────────────

class _PlansTab extends StatelessWidget {
  final List<MembershipPlanEntity> plans;
  final bool isSaving;
  final void Function(String planId)? onToggle;
  final void Function(MembershipPlanEntity plan)? onEdit;
  final void Function(MembershipPlanEntity plan)? onDelete;

  const _PlansTab({
    required this.plans,
    required this.isSaving,
    this.onToggle,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (plans.isEmpty) {
      return Center(
        child: Text(
          'Nenhum plano configurado. Toque em "Novo plano" para criar o primeiro.',
          textAlign: TextAlign.center,
          style: GoogleFonts.jost(color: AppTheme.textSecondary),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      itemCount: plans.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => BsCard(
        highlight: plans[i].isActive,
        child: Row(
          children: [
            Icon(plans[i].tier.icon,
                color: plans[i].tier.accentColor, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onEdit == null ? null : () => onEdit!(plans[i]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plans[i].name,
                      style: GoogleFonts.jost(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15),
                    ),
                    Text(
                      '${plans[i].formattedPrice}/mês · ${plans[i].cutsLabel}'
                      '${plans[i].productDiscountPercent > 0 ? ' · -${plans[i].productDiscountPercent}% produtos' : ''}',
                      style: GoogleFonts.jost(
                          color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            if (onDelete != null)
              GestureDetector(
                onTap: () => onDelete!(plans[i]),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.delete_outline_rounded,
                      color: AppTheme.error, size: 18),
                ),
              ),
            const SizedBox(width: 6),
            Switch(
              value: plans[i].isActive,
              onChanged: isSaving || onToggle == null
                  ? null
                  : (_) => onToggle!(plans[i].id),
              activeThumbColor: plans[i].tier.accentColor,
              inactiveTrackColor: AppTheme.inputBorder,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Plan Form Sheet (criar/editar) ─────────────────────────────────────────────

class _PlanFormSheet extends ConsumerStatefulWidget {
  final String shopId;
  final MembershipPlanEntity? existing;
  final Set<MembershipTier> usedTiers;
  const _PlanFormSheet({
    required this.shopId,
    this.existing,
    this.usedTiers = const {},
  });

  @override
  ConsumerState<_PlanFormSheet> createState() => _PlanFormSheetState();
}

class _PlanFormSheetState extends ConsumerState<_PlanFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late MembershipTier _tier;
  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _cuts;
  late final TextEditingController _discount;
  late final TextEditingController _benefits;
  late bool _includesBeard;
  late bool _priorityBooking;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _tier = p?.tier ??
        MembershipTier.values.firstWhere(
          (t) => !widget.usedTiers.contains(t),
          orElse: () => MembershipTier.basic,
        );
    _name = TextEditingController(text: p?.name ?? '');
    _price = TextEditingController(
        text: p == null ? '' : p.priceMonthly.toStringAsFixed(2));
    _cuts = TextEditingController(
        text: p?.cutsPerMonth == null ? '' : '${p!.cutsPerMonth}');
    _discount = TextEditingController(
        text: p == null ? '0' : '${p.productDiscountPercent}');
    _benefits = TextEditingController(text: p?.benefits.join('\n') ?? '');
    _includesBeard = p?.includesBeard ?? false;
    _priorityBooking = p?.priorityBooking ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _cuts.dispose();
    _discount.dispose();
    _benefits.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final benefits = _benefits.text
        .split('\n')
        .map((b) => b.trim())
        .where((b) => b.isNotEmpty)
        .toList();
    final cutsText = _cuts.text.trim();
    final price = double.tryParse(_price.text.replaceAll(',', '.'));

    if (price == null) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preço inválido.')),
      );
      return;
    }

    final plan = MembershipPlanEntity(
      id: widget.existing?.id ?? '',
      barbershopId: widget.shopId,
      tier: _tier,
      name: _name.text.trim(),
      priceMonthly: price,
      benefits: benefits,
      cutsPerMonth: cutsText.isEmpty ? null : int.tryParse(cutsText),
      includesBeard: _includesBeard,
      priorityBooking: _priorityBooking,
      productDiscountPercent: int.tryParse(_discount.text.trim()) ?? 0,
      isActive: widget.existing?.isActive ?? true,
    );

    final notifier = ref.read(shopMembershipProvider.notifier);
    bool ok;
    try {
      ok = _isEdit
          ? await notifier.savePlan(plan)
          : await notifier.createPlan(plan);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar plano: $e')),
      );
      return;
    }

    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() => _saving = false);
      final error = ref.read(shopMembershipProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Erro ao salvar plano.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          left: 24, right: 24, top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.inputBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                _isEdit ? 'Editar plano' : 'Novo plano',
                style: GoogleFonts.jost(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),
              Text('Tier',
                  style: GoogleFonts.jost(
                      color: AppTheme.textSecondary, fontSize: 12)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: MembershipTier.values.map((t) {
                  final sel = _tier == t;
                  final disabled = widget.usedTiers.contains(t);
                  return GestureDetector(
                    onTap: disabled ? null : () => setState(() => _tier = t),
                    child: Opacity(
                      opacity: disabled ? 0.4 : 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel
                              ? t.accentColor.withValues(alpha: 0.15)
                              : AppTheme.surfaceElevated,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color:
                                  sel ? t.accentColor : AppTheme.inputBorder,
                              width: sel ? 1.5 : 1),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(t.icon,
                              size: 14,
                              color: sel ? t.accentColor : AppTheme.textHint),
                          const SizedBox(width: 6),
                          Text(
                              disabled
                                  ? '${t.label} (já existe)'
                                  : t.label,
                              style: GoogleFonts.jost(
                                  color: sel
                                      ? t.accentColor
                                      : AppTheme.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              _field(_name, 'Nome do plano', 'ex: Premium'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: _field(_price, 'Preço mensal (R\$)', '89.90',
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      formatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))
                      ],
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Obrigatório';
                        final n = double.tryParse(v.replaceAll(',', '.'));
                        if (n == null || n <= 0) return 'Inválido';
                        return null;
                      }),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _field(_cuts, 'Cortes/mês', 'vazio = ilimitado',
                      keyboardType: TextInputType.number,
                      formatters: [FilteringTextInputFormatter.digitsOnly]),
                ),
              ]),
              const SizedBox(height: 12),
              _field(_discount, 'Desconto em produtos (%)', '0 a 100',
                  keyboardType: TextInputType.number,
                  formatters: [FilteringTextInputFormatter.digitsOnly]),
              const SizedBox(height: 12),
              _field(_benefits, 'Benefícios (um por linha)',
                  'Cortes ilimitados\nBarba incluída\n...',
                  maxLines: 4),
              const SizedBox(height: 14),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Inclui barba',
                    style: GoogleFonts.jost(
                        color: AppTheme.textPrimary, fontSize: 13)),
                value: _includesBeard,
                activeThumbColor: AppTheme.gold,
                onChanged: (v) => setState(() => _includesBeard = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Prioridade no agendamento',
                    style: GoogleFonts.jost(
                        color: AppTheme.textPrimary, fontSize: 13)),
                value: _priorityBooking,
                activeThumbColor: AppTheme.gold,
                onChanged: (v) => setState(() => _priorityBooking = v),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.gold,
                    foregroundColor: AppTheme.background,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppTheme.background))
                      : Text(_isEdit ? 'Salvar alterações' : 'Criar plano',
                          style: GoogleFonts.jost(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    String hint, {
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      inputFormatters: formatters,
      maxLines: maxLines,
      validator: validator ??
          (maxLines == 1
              ? (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null
              : null),
      style: GoogleFonts.jost(color: AppTheme.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle:
            GoogleFonts.jost(color: AppTheme.textSecondary, fontSize: 12),
        hintStyle: GoogleFonts.jost(color: AppTheme.textHint, fontSize: 12),
        filled: true,
        fillColor: AppTheme.surfaceElevated,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppTheme.inputBorder)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppTheme.inputBorder)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppTheme.gold)),
      ),
    );
  }
}
