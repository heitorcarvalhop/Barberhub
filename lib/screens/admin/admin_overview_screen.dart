import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/app_data_provider.dart';
import '../../models/appointment_model.dart';
import '../../core/routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_utils.dart';
import '../../widgets/app_widgets.dart';
import 'package:barber_hub/features/auth/presentation/providers/auth_providers.dart';

class AdminOverviewScreen extends ConsumerWidget {
  const AdminOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = context.watch<AppDataProvider>();
    final all = data.allAppointmentsSorted;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateBarbershopDialog(context, data),
        backgroundColor: AppTheme.gold,
        foregroundColor: AppTheme.background,
        icon: const Icon(Icons.add_business_rounded, size: 18),
        label: Text('Nova Barbearia', style: GoogleFonts.jost(fontWeight: FontWeight.w600, fontSize: 13)),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
      ),
      body: Stack(
        children: [
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppTheme.gold.withValues(alpha: .05),
                  Colors.transparent
                ]),
              ),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                // ── Header ───────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Row(children: [
                      const BarberLogo(size: 28),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text('ADMINISTRADOR',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(
                                        color: AppTheme.gold,
                                        fontSize: 9,
                                        letterSpacing: 3)),
                            Text('Barber Hub',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontSize: 16)),
                          ])),
                      IconButton(
                        icon: const Icon(Icons.logout_rounded,
                            color: AppTheme.textSecondary, size: 20),
                        onPressed: () {
                          ref.read(authNotifierProvider.notifier).logout();
                          Navigator.pushReplacementNamed(
                              context, AppRoutes.login);
                        },
                      ),
                    ]),
                  ),
                ),

                // ── Title ────────────────────────────────────────────────
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: ScreenHeader(
                        eyebrow: 'VISÃO GERAL', title: 'Dashboard'),
                  ),
                ),

                // ── Global stats ─────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionHeader(title: 'Resumo global'),
                          const SizedBox(height: 14),
                          Row(children: [
                            StatCard(
                                value: '${all.length}',
                                label: 'Total',
                                icon: Icons.calendar_month_outlined),
                            const SizedBox(width: 10),
                            StatCard(
                                value: '${data.scheduledCount}',
                                label: 'Pendentes',
                                icon: Icons.pending_outlined),
                            const SizedBox(width: 10),
                            StatCard(
                                value: '${data.completedCount}',
                                label: 'Concluídos',
                                icon: Icons.check_circle_outline),
                          ]),
                          const SizedBox(height: 10),
                          Row(children: [
                            StatCard(
                              value: 'R\$ ${data.totalRevenue}',
                              label: 'Receita total',
                              icon: Icons.attach_money_rounded,
                              valueColor: const Color(0xFF4CAF50),
                            ),
                            const SizedBox(width: 10),
                            StatCard(
                                value: '${data.barbershops.length}',
                                label: 'Barbearias',
                                icon: Icons.storefront_outlined),
                            const SizedBox(width: 10),
                            StatCard(
                                value: '${data.services.length}',
                                label: 'Serviços',
                                icon: Icons.spa_outlined),
                          ]),
                          const SizedBox(height: 10),
                          // ── Linha de avaliações ─────────────────────
                          Row(children: [
                            StatCard(
                              value: '${data.allReviews.length}',
                              label: 'Avaliações',
                              icon: Icons.star_rounded,
                              valueColor: AppTheme.gold,
                            ),
                            const SizedBox(width: 10),
                            StatCard(
                              value: data.allReviews.isEmpty
                                  ? '–'
                                  : (data.allReviews.fold(
                                              0,
                                              (s, r) =>
                                                  s + r.barbershopRating) /
                                          data.allReviews.length)
                                      .toStringAsFixed(1),
                              label: 'Nota média',
                              icon: Icons.star_half_rounded,
                              valueColor: AppTheme.gold,
                            ),
                            const SizedBox(width: 10),
                            StatCard(
                              value:
                                  '${data.allReviews.where((r) => r.barbershopRating >= 4).length}',
                              label: 'Positivas',
                              icon: Icons.thumb_up_outlined,
                              valueColor: const Color(0xFF4CAF50),
                            ),
                          ]),
                        ]),
                  ),
                ),

                // ── Por barbearia ─────────────────────────────────────────
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(24, 28, 24, 14),
                    child: SectionHeader(title: 'Por barbearia'),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 130,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      scrollDirection: Axis.horizontal,
                      itemCount: data.barbershops.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, i) {
                        final shop = data.barbershops[i];
                        final shopAppts = data.appointmentsForShop(shop.id);
                        final shopRevenue = shopAppts
                            .where(
                                (a) => a.status == AppointmentStatus.completed)
                            .fold(0.0, (s, a) => s + a.service.price);
                        final pending = shopAppts
                            .where(
                                (a) => a.status == AppointmentStatus.scheduled)
                            .length;
                        return _ShopStatCard(
                          shopIcon: shop.coverIconData,
                          name: shop.name,
                          total: shopAppts.length,
                          pending: pending,
                          revenue: shopRevenue.toInt(),
                        );
                      },
                    ),
                  ),
                ),

                // ── Distribuição de status ────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: _StatusBreakdown(appointments: all),
                  ),
                ),

                // ── Todos os agendamentos ────────────────────────────────
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(24, 24, 24, 12),
                    child: SectionHeader(title: 'Todos os agendamentos'),
                  ),
                ),

                if (all.isEmpty)
                  const SliverToBoxAdapter(
                    child: EmptyState(
                      icon: Icons.calendar_today_outlined,
                      title: 'Sem agendamentos',
                      subtitle: 'Os agendamentos realizados aparecerão aqui.',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: AppointmentCard(
                            appointment: all[i],
                            showClient: true,
                            showBarber: true,
                            showBarbershop: true,
                            // Admin: somente visualização — sem controle de agendamentos
                            onCancel: null,
                          ),
                        ),
                        childCount: all.length,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // _cancelConfirm removido — admin tem somente leitura de agendamentos.
}

// ── Shop stat card ─────────────────────────────────────────────────────────────
class _ShopStatCard extends StatelessWidget {
  final IconData shopIcon; final String name;
  final int total, pending, revenue;
  const _ShopStatCard({
    required this.shopIcon,
    required this.name,
    required this.total,
    required this.pending,
    required this.revenue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(shopIcon, size: 20, color: AppTheme.gold),
            const SizedBox(width: 8),
            Expanded(
              child: Text(name,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontSize: 13),
                  overflow: TextOverflow.ellipsis),
            ),
          ]),
          const Spacer(),
          Row(children: [
            _MiniStat(
                value: '$total',
                label: 'agend.',
                icon: Icons.calendar_today_outlined),
            const SizedBox(width: 12),
            _MiniStat(
                value: '$pending',
                label: 'pend.',
                icon: Icons.pending_outlined),
          ]),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
              border:
                  Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.3)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.attach_money_rounded,
                  size: 12, color: Color(0xFF4CAF50)),
              Text('R\$ $revenue',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 12,
                      color: const Color(0xFF4CAF50),
                      fontWeight: FontWeight.w600)),
            ]),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String value, label;
  final IconData icon;
  const _MiniStat(
      {required this.value, required this.label, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 11, color: AppTheme.textHint),
      const SizedBox(width: 4),
      Text('$value $label',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(fontSize: 11, color: AppTheme.textSecondary)),
    ]);
  }
}

// ── Status breakdown ──────────────────────────────────────────────────────────
class _StatusBreakdown extends StatelessWidget {
  final List<AppointmentModel> appointments;
  const _StatusBreakdown({required this.appointments});
  @override
  Widget build(BuildContext context) {
    if (appointments.isEmpty) return const SizedBox.shrink();
    final total = appointments.length;
    final byStatus = <AppointmentStatus, int>{};
    for (final a in appointments) {
      byStatus[a.status] = (byStatus[a.status] ?? 0) + 1;
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.inputBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('DISTRIBUIÇÃO',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppTheme.textHint, fontSize: 10, letterSpacing: 2)),
        const SizedBox(height: 14),
        ...AppointmentStatus.values.map((s) {
          final count = byStatus[s] ?? 0;
          final pct = total > 0 ? count / total : 0.0;
          final (color, _) = AppUtils.statusColors(s);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              Container(
                  width: 8,
                  height: 8,
                  decoration:
                      BoxDecoration(shape: BoxShape.circle, color: color)),
              const SizedBox(width: 10),
              SizedBox(
                width: 80,
                child: Text(
                  s == AppointmentStatus.scheduled
                      ? 'Agendados'
                      : s == AppointmentStatus.completed
                          ? 'Concluídos'
                          : 'Cancelados',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontSize: 12),
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: AppTheme.inputBorder,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(color.withValues(alpha: .7)),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text('$count',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 12,
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600)),
            ]),
          );
        }),
      ]),
    );
  }

}

void _showCreateBarbershopDialog(BuildContext context, AppDataProvider data) {
  final nameCtrl = TextEditingController();
  final addrCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (sheetContext) => StatefulBuilder(
      builder: (sheetContext, setState) {
        var saving = false;

        Future<void> submit() async {
          if (nameCtrl.text.trim().isEmpty) return;
          setState(() => saving = true);
          try {
            await data.addBarbershop(
              name: nameCtrl.text.trim(),
              address: addrCtrl.text.trim(),
              phone: phoneCtrl.text.trim(),
            );
            if (sheetContext.mounted) {
              Navigator.pop(sheetContext);
              AppUtils.showSnack(context, 'Barbearia criada com sucesso!');
            }
          } catch (e) {
            setState(() => saving = false);
            if (sheetContext.mounted) {
              AppUtils.showSnack(sheetContext, 'Erro ao criar barbearia.', isError: true);
            }
          }
        }

        return Padding(
          padding: EdgeInsets.only(left: 24, right: 24, top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 32),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 36, height: 4,
                decoration: BoxDecoration(color: AppTheme.divider, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text('Nova Barbearia', style: GoogleFonts.jost(color: AppTheme.textPrimary,
                fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            _AdminTextField(ctrl: nameCtrl, label: 'Nome da barbearia', icon: Icons.storefront_rounded),
            const SizedBox(height: 12),
            _AdminTextField(ctrl: addrCtrl, label: 'Endereço', icon: Icons.location_on_rounded),
            const SizedBox(height: 12),
            _AdminTextField(ctrl: phoneCtrl, label: 'Telefone', icon: Icons.phone_rounded),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: saving ? null : submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.gold,
                  foregroundColor: AppTheme.background,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
                ),
                child: saving
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.background))
                    : Text('CRIAR BARBEARIA', style: GoogleFonts.jost(fontWeight: FontWeight.w700, letterSpacing: 1.5)),
              ),
            ),
          ]),
        );
      },
    ),
  );
}

class _AdminTextField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  const _AdminTextField({required this.ctrl, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) => TextField(
    controller: ctrl,
    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
      prefixIcon: Icon(icon, color: AppTheme.gold, size: 18),
      filled: true,
      fillColor: AppTheme.surfaceElevated,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.inputBorder)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.inputBorder)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.gold)),
    ),
  );
}
