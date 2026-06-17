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
import 'reschedule_sheet.dart';
import 'package:barber_hub/features/auth/presentation/providers/auth_providers.dart';

class AppointmentsScreen extends ConsumerStatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  ConsumerState<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends ConsumerState<AppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

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
    final authUser = authState is AuthAuthenticated ? authState.user : null;
    final data = context.watch<AppDataProvider>();
    final clientId = authUser?.id ?? '';

    final active = data.activeForClient(clientId);
    final past = data.pastForClient(clientId);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // â”€â”€ Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MEUS',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppTheme.gold,
                          fontSize: 11,
                          letterSpacing: 4,
                        ),
                  ),
                  Text(
                    'Agendamentos',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // â”€â”€ Tab bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Ativos'),
                          if (active.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            _CountBadge(active.length),
                          ],
                        ],
                      ),
                    ),
                    const Tab(text: 'Historico'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 4),

            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _AppointmentList(
                    appointments: active,
                    emptyTitle: 'Nenhum agendamento',
                    emptySubtitle:
                        'Voce nao tem horarios marcados.\nQue tal agendar agora?',
                    emptyAction: 'Ver barbearias',
                    onEmptyAction: () {
                      Navigator.pushReplacementNamed(context, AppRoutes.home);
                    },
                    onCancel: (a) => _confirmCancel(context, a, data),
                    onReschedule: (a) => _showReschedule(context, a),
                  ),
                  _AppointmentList(
                    appointments: past,
                    emptyTitle: 'Historico vazio',
                    emptySubtitle:
                        'Seus agendamentos concluidos\naparecerao aqui.',
                    onCancel: null,
                    onReschedule: null,
                    onReview: (a) => _openReview(context, a),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmCancel(
    BuildContext context,
    AppointmentModel a,
    AppDataProvider data,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: Text('Cancelar agendamento',
            style: Theme.of(context).textTheme.titleLarge),
        content: Text(
          'Cancelar "${a.service.name}" com ${a.barber.name} na ${a.barbershop.name}?',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Manter'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await data.cancelAppointment(a.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.cancel_outlined,
                            color: AppTheme.error, size: 16),
                        SizedBox(width: 10),
                        Text('Agendamento cancelado'),
                      ],
                    ),
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  void _showReschedule(BuildContext context, AppointmentModel a) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RescheduleSheet(appointment: a),
    );
  }

  Future<void> _openReview(BuildContext context, AppointmentModel a) async {
    final result = await Navigator.pushNamed(
      context,
      AppRoutes.review,
      arguments: a,
    );
    if (result == true && context.mounted) {
      AppUtils.showSnack(context, 'Avaliacao enviada! Obrigado.',
          isSuccess: true);
    }
  }
}

// â”€â”€ Count badge â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _CountBadge extends StatelessWidget {
  final int count;
  const _CountBadge(this.count);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration:
          const BoxDecoration(shape: BoxShape.circle, color: AppTheme.goldDark),
      child: Center(
        child: Text(
          '$count',
          style: GoogleFonts.jost(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary),
        ),
      ),
    );
  }
}

// â”€â”€ Appointment list â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _AppointmentList extends StatelessWidget {
  final List<AppointmentModel> appointments;
  final String emptyTitle;
  final String emptySubtitle;
  final String? emptyAction;
  final VoidCallback? onEmptyAction;
  final void Function(AppointmentModel)? onCancel;
  final void Function(AppointmentModel)? onReschedule;
  final void Function(AppointmentModel)? onReview;

  const _AppointmentList({
    required this.appointments,
    required this.emptyTitle,
    required this.emptySubtitle,
    this.emptyAction,
    this.onEmptyAction,
    required this.onCancel,
    required this.onReschedule,
    this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    if (appointments.isEmpty) {
      return EmptyState(
        icon: Icons.calendar_today_outlined,
        title: emptyTitle,
        subtitle: emptySubtitle,
        actionLabel: emptyAction,
        onAction: onEmptyAction,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      itemCount: appointments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, i) => _AppointmentCard(
        appointment: appointments[i],
        onCancel: onCancel,
        onReschedule: onReschedule,
        onReview: onReview,
      ),
    );
  }
}

// â”€â”€ Appointment card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  final void Function(AppointmentModel)? onCancel;
  final void Function(AppointmentModel)? onReschedule;
  final void Function(AppointmentModel)? onReview;

  const _AppointmentCard({
    required this.appointment,
    required this.onCancel,
    required this.onReschedule,
    this.onReview,
  });

  Color get _statusColor {
    switch (appointment.status) {
      case AppointmentStatus.scheduled:
        return const Color(0xFF4CAF50);
      case AppointmentStatus.completed:
        return AppTheme.gold;
      case AppointmentStatus.cancelled:
        return AppTheme.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = appointment;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.inputBorder),
      ),
      child: Column(
        children: [
          // â”€â”€ Barbershop header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.gold.withValues(alpha: 0.04),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              border: const Border(bottom: BorderSide(color: AppTheme.divider)),
            ),
            child: Row(
              children: [
                const Icon(Icons.storefront_outlined,
                    size: 13, color: AppTheme.gold),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    a.barbershop.name,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppTheme.gold,
                          fontSize: 12,
                          letterSpacing: 0.3,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                StatusBadge(
                  label: a.statusLabel.toUpperCase(),
                  color: _statusColor,
                  bgColor: _statusColor.withValues(alpha: 0.1),
                ),
              ],
            ),
          ),

          // â”€â”€ Main content â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date block
                Container(
                  width: 54,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.gold.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.gold.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${a.date.day}',
                        style: Theme.of(context)
                            .textTheme
                            .headlineLarge
                            ?.copyWith(
                                color: AppTheme.gold, fontSize: 26, height: 1),
                      ),
                      Text(
                        _monthAbbr(a.date.month),
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppTheme.gold,
                            fontSize: 10,
                            letterSpacing: 1),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 14),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Service name
                      Text(
                        a.service.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontSize: 16),
                      ),
                      const SizedBox(height: 8),

                      // Barber
                      _MetaRow(
                        icon: Icons.person_outline_rounded,
                        text: a.barber.name,
                      ),
                      const SizedBox(height: 5),

                      // Address
                      _MetaRow(
                        icon: Icons.location_on_outlined,
                        text: a.barbershop.address,
                        textColor: AppTheme.textHint,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 5),

                      // Time + price
                      Row(
                        children: [
                          const Icon(Icons.schedule_outlined,
                              size: 13, color: AppTheme.textHint),
                          const SizedBox(width: 5),
                          Text(
                            a.timeSlot,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontSize: 13),
                          ),
                          const SizedBox(width: 8),
                          Container(
                              width: 3,
                              height: 3,
                              decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.textHint)),
                          const SizedBox(width: 8),
                          Text(
                            a.service.formattedDuration,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontSize: 13),
                          ),
                          const Spacer(),
                          if (a.paidViaMembership)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.gold.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: AppTheme.gold.withOpacity(0.35)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.workspace_premium_rounded,
                                      color: AppTheme.gold, size: 11),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Assinatura',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                            fontSize: 11,
                                            color: AppTheme.gold,
                                            fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            )
                          else
                            Text(
                              a.service.formattedPrice,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                      fontSize: 14,
                                      color: AppTheme.gold,
                                      fontWeight: FontWeight.w600),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // â”€â”€ Actions â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          if (a.canCancel || a.canReschedule) ...[
            Container(height: 1, color: AppTheme.divider),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  if (a.canReschedule && onReschedule != null)
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () => onReschedule!(a),
                        icon:
                            const Icon(Icons.edit_calendar_outlined, size: 15),
                        label: const Text('Remarcar'),
                        style: TextButton.styleFrom(
                          textStyle: GoogleFonts.jost(
                              fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  if (a.canCancel && a.canReschedule)
                    Container(width: 1, height: 20, color: AppTheme.divider),
                  if (a.canCancel && onCancel != null)
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () => onCancel!(a),
                        icon: const Icon(Icons.cancel_outlined, size: 15),
                        label: const Text('Cancelar'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.error,
                          textStyle: GoogleFonts.jost(
                              fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],

          // â”€â”€ Botão Avaliar / Badge avaliado â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          if (a.canReview && onReview != null) ...[
            Container(height: 1, color: AppTheme.divider),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onReview!(a),
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(10)),
                splashColor: AppTheme.gold.withValues(alpha: 0.08),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star_outline_rounded,
                          size: 15, color: AppTheme.gold),
                      const SizedBox(width: 7),
                      Text(
                        'Avaliar atendimento',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: AppTheme.gold,
                              fontSize: 12,
                              letterSpacing: 0.3,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],

          if (a.isReviewed) ...[
            Container(height: 1, color: AppTheme.divider),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                        5,
                        (i) => Icon(
                              i < a.review!.overallRating.round()
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              size: 14,
                              color: AppTheme.gold,
                            )),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      a.review!.comment ??
                          ReviewModel.labelFor(a.review!.overallRating.round()),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 12, color: AppTheme.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.gold.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Avaliado',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.gold,
                          fontSize: 10,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _monthAbbr(int m) {
    const months = [
      '',
      'JAN',
      'FEV',
      'MAR',
      'ABR',
      'MAI',
      'JUN',
      'JUL',
      'AGO',
      'SET',
      'OUT',
      'NOV',
      'DEZ'
    ];
    return months[m];
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? textColor;
  final int maxLines;

  const _MetaRow({
    required this.icon,
    required this.text,
    this.textColor,
    this.maxLines = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13, color: AppTheme.textHint),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 13,
                  color: textColor ?? AppTheme.textSecondary,
                ),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
