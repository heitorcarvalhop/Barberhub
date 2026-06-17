import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider;
import 'package:google_fonts/google_fonts.dart';
import 'package:barber_hub/core/theme/app_theme.dart';
import 'package:barber_hub/core/utils/app_utils.dart';
import 'package:barber_hub/features/auth/presentation/providers/auth_providers.dart';
import 'package:barber_hub/features/barber_shop/domain/entities/blocked_date_entity.dart';
import 'package:barber_hub/features/barber_shop/presentation/providers/shop_management_providers.dart';
import 'package:barber_hub/features/barber_shop/presentation/widgets/bs_widgets.dart';
import 'package:barber_hub/models/app_data_provider.dart';
import 'package:barber_hub/models/appointment_model.dart';

class BarberShopScheduleScreen extends ConsumerStatefulWidget {
  const BarberShopScheduleScreen({super.key});
  @override
  ConsumerState<BarberShopScheduleScreen> createState() => _State();
}

class _State extends ConsumerState<BarberShopScheduleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final shopId =
        authState is AuthAuthenticated ? authState.user.linkedId ?? '' : '';
    final mgmtState = ref.watch(shopManagementProvider);
    final blockedDates = mgmtState.blockedDates;

    // Filtra agendamentos reais da barbearia neste dia.
    final data = provider.Provider.of<AppDataProvider>(context);
    final allAppts = shopId.isEmpty
        ? <AppointmentModel>[]
        : data.appointmentsForShop(shopId);
    final dayAppts = allAppts
        .where((a) =>
            a.date.year == _selectedDay.year &&
            a.date.month == _selectedDay.month &&
            a.date.day == _selectedDay.day)
        .toList()
      ..sort((a, b) => a.timeSlot.compareTo(b.timeSlot));

    final isBlocked = blockedDates.any((b) => b.blocks(_selectedDay));

    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          const BsScreenHeader(eyebrow: 'gestão', title: 'Agenda'),
          const SizedBox(height: 16),

          // Tab bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TabBar(
                controller: _tab,
                indicator: BoxDecoration(
                  color: AppTheme.gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.gold),
                ),
                labelColor: AppTheme.gold,
                unselectedLabelColor: AppTheme.textSecondary,
                labelStyle:
                    GoogleFonts.jost(fontSize: 12, fontWeight: FontWeight.w600),
                unselectedLabelStyle: GoogleFonts.jost(fontSize: 12),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Agenda'),
                  Tab(text: 'Bloqueios'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
              child: TabBarView(controller: _tab, children: [
            // ── TAB 1: Agenda ───────────────────────────────────────────────
            _AgendaTab(
              selectedDay: _selectedDay,
              appointments: dayAppts,
              isBlocked: isBlocked,
              onDayChanged: (d) => setState(() => _selectedDay = d),
            ),

            // ── TAB 2: Bloqueios ────────────────────────────────────────────
            _BlocksTab(
              blockedDates: blockedDates,
              shopId: shopId,
              onAdd: () => _showBlockModal(context, ref, shopId),
              onRemove: (id) => ref
                  .read(shopManagementProvider.notifier)
                  .removeBlockedDate(id),
            ),
          ])),
        ]),
      ),
    );
  }

  void _showBlockModal(BuildContext ctx, WidgetRef ref, String shopId) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _BlockModal(ref: ref, shopId: shopId),
      ),
    );
  }
}

// ── Agenda Tab ────────────────────────────────────────────────────────────────
class _AgendaTab extends StatelessWidget {
  final DateTime selectedDay;
  final List<AppointmentModel> appointments;
  final bool isBlocked;
  final ValueChanged<DateTime> onDayChanged;
  const _AgendaTab(
      {required this.selectedDay,
      required this.appointments,
      required this.isBlocked,
      required this.onDayChanged});

  @override
  Widget build(BuildContext context) => CustomScrollView(slivers: [
        // Date picker compact
        SliverToBoxAdapter(
            child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: GestureDetector(
            onTap: () async {
              final p = await showDatePicker(
                context: context,
                initialDate: selectedDay,
                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                lastDate: DateTime.now().add(const Duration(days: 60)),
                builder: (ctx, child) => Theme(
                  data: Theme.of(ctx).copyWith(
                      colorScheme: const ColorScheme.dark(
                          primary: AppTheme.gold,
                          onPrimary: AppTheme.background,
                          surface: AppTheme.surfaceElevated,
                          onSurface: AppTheme.textPrimary)),
                  child: child!,
                ),
              );
              if (p != null) onDayChanged(p);
            },
            child: BsCard(
              highlight: true,
              child: Row(children: [
                const Icon(Icons.calendar_today_rounded,
                    color: AppTheme.gold, size: 20),
                const SizedBox(width: 12),
                Text(AppUtils.formatDateLong(selectedDay),
                    style: GoogleFonts.jost(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
                const Spacer(),
                const Icon(Icons.keyboard_arrow_down_rounded,
                    color: AppTheme.textHint, size: 20),
              ]),
            ),
          ),
        )),

        if (isBlocked)
          SliverToBoxAdapter(
              child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.error.withValues(alpha: 0.4)),
              ),
              child: Row(children: [
                const Icon(Icons.block_rounded,
                    color: AppTheme.error, size: 20),
                const SizedBox(width: 10),
                Text('Esta data está bloqueada para agendamentos.',
                    style:
                        GoogleFonts.jost(color: AppTheme.error, fontSize: 13)),
              ]),
            ),
          )),

        const SliverToBoxAdapter(child: SizedBox(height: 14)),

        if (appointments.isEmpty)
          const SliverFillRemaining(
              child: BsEmptyState(
            icon: Icons.event_busy_outlined,
            message: 'Nenhum agendamento neste dia.',
          ))
        else ...[
          SliverToBoxAdapter(
              child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: BsSectionHeader(
                title:
                    '${appointments.length} agendamento${appointments.length != 1 ? 's' : ''}'),
          )),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 32),
            sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
              (_, i) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _AppointmentCard(appt: appointments[i]),
              ),
              childCount: appointments.length,
            )),
          ),
        ],
      ]);
}

// ── Appointment Card ──────────────────────────────────────────────────────────
class _AppointmentCard extends StatelessWidget {
  final AppointmentModel appt;
  const _AppointmentCard({required this.appt});

  Future<void> _setStatus(BuildContext context, AppointmentStatus status) =>
      provider.Provider.of<AppDataProvider>(context, listen: false)
          .updateAppointmentStatus(appt.id, status);

  @override
  Widget build(BuildContext context) {
    final statusColor = appt.status == AppointmentStatus.scheduled
        ? const Color(0xFF2ECC71)
        : appt.status == AppointmentStatus.completed
            ? AppTheme.gold
            : AppTheme.error;

    return BsCard(
      child: Column(children: [
        Row(children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.gold.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
              child: Text(appt.timeSlot,
                  style: GoogleFonts.jost(
                      color: AppTheme.gold,
                      fontSize: 12,
                      fontWeight: FontWeight.w700))),
        ),
        const SizedBox(width: 14),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(appt.clientName,
              style: GoogleFonts.jost(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 3),
          Text('${appt.service.name} · ${appt.barber.name}',
              style: GoogleFonts.jost(
                  color: AppTheme.textSecondary, fontSize: 12)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('R\$ ${appt.service.price.toStringAsFixed(0)}',
              style: GoogleFonts.jost(
                  color: AppTheme.gold,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: statusColor.withValues(alpha: 0.4)),
            ),
            child: Text(
                appt.status == AppointmentStatus.scheduled
                    ? 'Agendado'
                    : appt.status == AppointmentStatus.completed
                        ? 'Concluído'
                        : 'Cancelado',
                style: GoogleFonts.jost(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600)),
          ),
        ]),
      ]),
        if (appt.status == AppointmentStatus.scheduled) ...[
          const SizedBox(height: 10),
          Container(height: 1, color: AppTheme.divider),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(
              child: TextButton.icon(
                onPressed: () => _setStatus(context, AppointmentStatus.completed),
                icon: const Icon(Icons.check_circle_outline_rounded, size: 15),
                label: const Text('Concluir'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.gold,
                  textStyle:
                      GoogleFonts.jost(fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            ),
            Container(width: 1, height: 20, color: AppTheme.divider),
            Expanded(
              child: TextButton.icon(
                onPressed: () => _setStatus(context, AppointmentStatus.cancelled),
                icon: const Icon(Icons.cancel_outlined, size: 15),
                label: const Text('Cancelar'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.error,
                  textStyle:
                      GoogleFonts.jost(fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ]),
        ],
      ]),
    );
  }
}

// ── Blocks Tab ────────────────────────────────────────────────────────────────
class _BlocksTab extends StatelessWidget {
  final List<BlockedDateEntity> blockedDates;
  final String shopId;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;
  const _BlocksTab(
      {required this.blockedDates,
      required this.shopId,
      required this.onAdd,
      required this.onRemove});

  @override
  Widget build(BuildContext context) => CustomScrollView(slivers: [
        SliverToBoxAdapter(
            child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
                'Datas bloqueadas não aparecerão como disponíveis para clientes.',
                style: GoogleFonts.jost(
                    color: AppTheme.textSecondary, fontSize: 12, height: 1.5)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Adicionar bloqueio'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.gold,
                  side: const BorderSide(color: AppTheme.gold),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10))),
                ),
              ),
            ),
          ]),
        )),
        if (blockedDates.isEmpty)
          const SliverFillRemaining(
              child: BsEmptyState(
            icon: Icons.event_available_outlined,
            message:
                'Nenhum bloqueio configurado.\nTodas as datas estão disponíveis.',
          ))
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
              (_, i) {
                final b = blockedDates[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: BsCard(
                    child: Row(children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppTheme.error.withValues(alpha: 0.3)),
                        ),
                        child: Center(
                            child: Icon(b.type.iconData,
                                color: AppTheme.error, size: 20)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(b.displayLabel,
                                style: GoogleFonts.jost(
                                    color: AppTheme.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600)),
                            if (b.reason.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(b.reason,
                                  style: GoogleFonts.jost(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ],
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.error.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: AppTheme.error.withValues(alpha: 0.3)),
                              ),
                              child: Text(b.type.label,
                                  style: GoogleFonts.jost(
                                      color: AppTheme.error,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ])),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded,
                            color: AppTheme.error, size: 20),
                        onPressed: () => onRemove(b.id),
                      ),
                    ]),
                  ),
                );
              },
              childCount: blockedDates.length,
            )),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ]);
}

// ── Block Modal ───────────────────────────────────────────────────────────────
class _BlockModal extends ConsumerStatefulWidget {
  final WidgetRef ref;
  final String shopId;
  const _BlockModal({required this.ref, required this.shopId});

  @override
  ConsumerState<_BlockModal> createState() => _BlockModalState();
}

class _BlockModalState extends ConsumerState<_BlockModal> {
  BlockType _type = BlockType.specificDate;
  DateTime? _date;
  final _reasonCtrl = TextEditingController();

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_type == BlockType.specificDate && _date == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Selecione uma data.')));
      return;
    }
    if (_reasonCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Informe um motivo.')));
      return;
    }
    await ref.read(shopManagementProvider.notifier).addBlockedDate(
          BlockedDateEntity(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            shopId: widget.shopId,
            type: _type,
            date: _date,
            reason: _reasonCtrl.text.trim(),
          ),
        );
    await provider.Provider.of<AppDataProvider>(context, listen: false)
        .refreshBlockedDates();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(shopManagementProvider).isSaving;
    return BsModalSheet(
      title: 'Novo bloqueio',
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Tipo
        ...BlockType.values.map((t) => GestureDetector(
              onTap: () => setState(() {
                _type = t;
                if (t != BlockType.specificDate) _date = null;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: _type == t
                      ? AppTheme.gold.withValues(alpha: 0.08)
                      : AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: _type == t ? AppTheme.gold : AppTheme.inputBorder,
                      width: _type == t ? 1.5 : 1),
                ),
                child: Row(children: [
                  Icon(t.iconData,
                      color:
                          _type == t ? AppTheme.gold : AppTheme.textSecondary,
                      size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text(t.label,
                          style: GoogleFonts.jost(
                              color: _type == t
                                  ? AppTheme.gold
                                  : AppTheme.textPrimary,
                              fontSize: 14,
                              fontWeight: _type == t
                                  ? FontWeight.w600
                                  : FontWeight.w400))),
                  if (_type == t)
                    const Icon(Icons.check_circle_rounded,
                        color: AppTheme.gold, size: 18),
                ]),
              ),
            )),

        // Date picker (só para specificDate)
        if (_type == BlockType.specificDate) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              final p = await showDatePicker(
                context: context,
                initialDate:
                    _date ?? DateTime.now().add(const Duration(days: 1)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                builder: (ctx, child) => Theme(
                  data: Theme.of(ctx).copyWith(
                      colorScheme: const ColorScheme.dark(
                          primary: AppTheme.gold,
                          onPrimary: AppTheme.background,
                          surface: AppTheme.surfaceElevated,
                          onSurface: AppTheme.textPrimary)),
                  child: child!,
                ),
              );
              if (p != null) setState(() => _date = p);
            },
            child: BsCard(
              highlight: _date != null,
              child: Row(children: [
                Icon(Icons.calendar_today_rounded,
                    color: _date != null ? AppTheme.gold : AppTheme.textHint,
                    size: 20),
                const SizedBox(width: 12),
                Text(
                    _date != null
                        ? AppUtils.formatDateLong(_date!)
                        : 'Selecionar data',
                    style: GoogleFonts.jost(
                        color: _date != null
                            ? AppTheme.textPrimary
                            : AppTheme.textHint,
                        fontSize: 14)),
              ]),
            ),
          ),
        ],
        const SizedBox(height: 14),
        BsTextField(
            label: 'Motivo',
            hint: 'Ex: Feriado, Manutenção...',
            controller: _reasonCtrl),
        const SizedBox(height: 24),
        BsSaveButton(
            label: 'Adicionar bloqueio', onPressed: _save, isLoading: isSaving),
        const SizedBox(height: 8),
      ]),
    );
  }
}
