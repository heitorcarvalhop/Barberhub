import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/routes/app_routes.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/membership/domain/entities/membership_entity.dart';
import '../../features/membership/domain/entities/membership_plan_entity.dart';
import '../../features/membership/presentation/providers/membership_providers.dart';
import '../../models/app_data_provider.dart';
import '../../models/appointment_booking_failure.dart';
import '../../mock/mock_data.dart';
import '../../models/barber_model.dart';
import '../../models/barbershop_model.dart';
import '../../models/service_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// BookingScreen
// Recebe via arguments: Map{'service': ServiceModel, 'barbershop': BarbershopModel}
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({super.key});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  BarberModel? _selectedBarber;
  DateTime? _selectedDate;
  String? _selectedTime;
  int _step = 0; // 0=barbeiro, 1=data/hora, 2=confirmar
  bool _useMembershipCut = false;
  DateTime get _bookingNow => DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authNotifierProvider);
      if (authState is AuthAuthenticated) {
        ref
            .read(clientMembershipProvider.notifier)
            .load(clientId: authState.user.id);
      }
    });
  }

  /// Parse seguro dos arguments. Garante que barbershop sempre vem
  /// de uma barbearia real (args ou provider).
  (ServiceModel service, BarbershopModel barbershop) _parseArgs(
      Object? args, AppDataProvider data) {
    ServiceModel? service;
    BarbershopModel? barbershop;

    if (args is Map) {
      service = args['service'] as ServiceModel?;
      barbershop = args['barbershop'] as BarbershopModel?;
    } else if (args is ServiceModel) {
      service = args;
    }

    // Fallback para provider se não vier via args
    barbershop ??= data.selectedBarbershop ?? data.barbershops.first;

    if (service == null) {
      throw StateError('BookingScreen requer um ServiceModel nos arguments.');
    }

    return (service, barbershop);
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppDataProvider>();
    final args = ModalRoute.of(context)!.settings.arguments;
    final (service, barbershop) = _parseArgs(args, data);

    // Barbeiros APENAS da barbearia em questão
    final barbers = barbershop.barbers.where((b) => b.isActive).toList();

    // Horarios já ocupados para o barbeiro/data selecionados
    final bookedSlots = (_selectedBarber != null && _selectedDate != null)
        ? data.bookedSlotsFor(_selectedBarber!.id, _selectedDate!)
        : <String>{};

    // Assinatura ativa do cliente nesta barbearia (se houver)
    final membershipState = ref.watch(clientMembershipProvider);
    final activeMembership = membershipState.activeForShop(barbershop.id);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // â”€â”€ Top bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 18, color: AppTheme.textSecondary),
                    onPressed: () {
                      if (_step > 0) {
                        setState(() => _step--);
                      } else {
                        Navigator.pop(context);
                      }
                    },
                  ),
                  const Spacer(),
                  Text(
                    'AGENDAMENTO',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppTheme.textHint,
                          fontSize: 11,
                          letterSpacing: 3,
                        ),
                  ),
                ],
              ),
            ),

            // â”€â”€ Step indicator â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: _StepIndicator(currentStep: _step),
            ),

            // â”€â”€ Service + Barbershop summary â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: _BookingSummaryBar(
                service: service,
                barbershopName: barbershop.name,
              ),
            ),

            const SizedBox(height: 4),

            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeOut,
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.05, 0),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: _buildStep(
                  service: service,
                  barbershop: barbershop,
                  barbers: barbers,
                  bookedSlots: bookedSlots,
                  data: data,
                  activeMembership: activeMembership,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep({
    required ServiceModel service,
    required BarbershopModel barbershop,
    required List<BarberModel> barbers,
    required Set<String> bookedSlots,
    required AppDataProvider data,
    required MembershipEntity? activeMembership,
  }) {
    switch (_step) {
      case 0:
        return _BarberStep(
          key: const ValueKey('step0'),
          barbers: barbers,
          selected: _selectedBarber,
          onSelect: (b) => setState(() => _selectedBarber = b),
          onNext: () => setState(() => _step = 1),
        );
      case 1:
        return _DateTimeStep(
          key: const ValueKey('step1'),
          selectedDate: _selectedDate,
          selectedTime: _selectedTime,
          bookedSlots: bookedSlots,
          referenceNow: _bookingNow,
          workingHours: barbershop.workingHours,
          isDateBlocked: (date) =>
              data.isDateBlockedForShop(barbershop.id, date) ||
              !(barbershop.workingHours[date.weekday]?.isOpen ?? true),
          onDateSelected: (d) => setState(() {
            _selectedDate = d;
            _selectedTime = null; // reset horário ao trocar data
          }),
          onTimeSelected: (t) => setState(() => _selectedTime = t),
          onNext: () => setState(() => _step = 2),
        );
      case 2:
        return _ConfirmStep(
          key: const ValueKey('step2'),
          service: service,
          barber: _selectedBarber!,
          barbershop: barbershop,
          date: _selectedDate!,
          timeSlot: _selectedTime!,
          onConfirm: () => _confirm(service, barbershop, data, activeMembership),
          isLoading: data.isLoading,
          activeMembership: activeMembership,
          useMembershipCut: _useMembershipCut,
          onToggleUseMembership: activeMembership == null
              ? null
              : (v) => setState(() => _useMembershipCut = v),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _confirm(
    ServiceModel service,
    BarbershopModel barbershop,
    AppDataProvider data,
    MembershipEntity? activeMembership,
  ) async {
    final authState = ref.read(authNotifierProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;

    if (user == null) {
      _showBookingError(AppointmentBookingFailure.notAuthenticated);
      return;
    }

    final redeemCut = _useMembershipCut && activeMembership != null;

    try {
      await data.bookAppointment(
        clientId: user.id,
        clientName: user.name,
        service: service,
        barber: _selectedBarber!,
        barbershop: barbershop,
        date: _selectedDate!,
        timeSlot: _selectedTime!,
        paidViaMembership: redeemCut,
      );
      if (redeemCut) {
        await ref
            .read(clientMembershipProvider.notifier)
            .useCut(activeMembership.id);
      }
      if (!mounted) return;
      _showSuccessDialog(barbershop.name, usedMembership: redeemCut);
    } catch (error) {
      final failure = error is AppointmentBookingException
          ? error.failure
          : AppointmentBookingFailure.unknown;
      _showBookingError(failure);
    }
  }

  void _showBookingError(AppointmentBookingFailure failure) {
    if (!mounted) return;

    final needsLogin = failure == AppointmentBookingFailure.notAuthenticated ||
        failure == AppointmentBookingFailure.unauthorized;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.error,
        content: Text(_bookingErrorMessage(failure)),
        action: needsLogin
            ? SnackBarAction(
                label: 'ENTRAR',
                textColor: AppTheme.gold,
                onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
              )
            : null,
      ),
    );
  }

  String _bookingErrorMessage(AppointmentBookingFailure failure) {
    switch (failure) {
      case AppointmentBookingFailure.notAuthenticated:
        return 'Entre na sua conta para agendar um horario.';
      case AppointmentBookingFailure.pastDate:
        return 'Escolha uma data a partir de hoje para agendar.';
      case AppointmentBookingFailure.blockedDate:
        return 'Esta data esta bloqueada pela barbearia.';
      case AppointmentBookingFailure.slotUnavailable:
        return 'Esse horario acabou de ser reservado. Escolha outro horario.';
      case AppointmentBookingFailure.unauthorized:
        return 'Sua sessao expirou. Entre novamente para continuar.';
      case AppointmentBookingFailure.network:
        return 'Nao foi possivel agendar agora. Verifique sua internet.';
      case AppointmentBookingFailure.unknown:
        return 'Nao foi possivel concluir o agendamento. Tente novamente.';
    }
  }

  void _showSuccessDialog(String barbershopName, {bool usedMembership = false}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: AppTheme.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.gold.withOpacity(0.12),
                  border: Border.all(
                      color: AppTheme.gold.withOpacity(0.3), width: 2),
                ),
                child: const Icon(Icons.check_rounded,
                    color: AppTheme.gold, size: 36),
              ),
              const SizedBox(height: 20),
              Text('Agendado!',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'Seu horario em\n$barbershopName\nfoi confirmado!',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(height: 1.6, color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
              if (usedMembership) ...[
                const SizedBox(height: 14),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.gold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: AppTheme.gold.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.workspace_premium_rounded,
                          color: AppTheme.gold, size: 14),
                      const SizedBox(width: 6),
                      Text('Corte incluso na sua assinatura',
                          style: GoogleFonts.jost(
                              color: AppTheme.gold,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      AppRoutes.home,
                      (route) => false,
                      arguments: 1,
                    );
                  },
                  child: const Text('VER AGENDAMENTOS'),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('Voltar ao inicio'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// â”€â”€ Step Indicator â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _StepIndicator extends StatelessWidget {
  final int currentStep;
  const _StepIndicator({required this.currentStep});

  static const _labels = ['Barbeiro', 'Data & Hora', 'Confirmar'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(_labels.length * 2 - 1, (i) {
        if (i.isOdd) {
          final stepIndex = i ~/ 2;
          final active = currentStep > stepIndex;
          return Expanded(
            child: Container(
              height: 1.5,
              color: active ? AppTheme.gold : AppTheme.divider,
            ),
          );
        }
        final stepIndex = i ~/ 2;
        final active = stepIndex <= currentStep;
        return Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active
                    ? AppTheme.gold.withOpacity(0.15)
                    : AppTheme.surfaceElevated,
                border: Border.all(
                  color: active ? AppTheme.gold : AppTheme.inputBorder,
                  width: active ? 1.5 : 1,
                ),
              ),
              child: Center(
                child: Text(
                  '${stepIndex + 1}',
                  style: GoogleFonts.jost(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: active ? AppTheme.gold : AppTheme.textHint,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _labels[stepIndex],
              style: GoogleFonts.jost(
                fontSize: 10,
                color: active ? AppTheme.gold : AppTheme.textHint,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        );
      }),
    );
  }
}

// â”€â”€ Booking summary bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _BookingSummaryBar extends StatelessWidget {
  final ServiceModel service;
  final String barbershopName;
  const _BookingSummaryBar(
      {required this.service, required this.barbershopName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.storefront_outlined,
                  size: 11, color: AppTheme.gold),
              const SizedBox(width: 5),
              Text(
                barbershopName,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 11,
                      color: AppTheme.gold.withOpacity(0.85),
                    ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  service.name,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontSize: 14),
                ),
              ),
              Text(
                service.formattedPrice,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: AppTheme.gold, fontSize: 15),
              ),
              const SizedBox(width: 12),
              Container(height: 14, width: 1, color: AppTheme.divider),
              const SizedBox(width: 12),
              Text(
                service.formattedDuration,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// â”€â”€ Step 0: Barber â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _BarberStep extends StatelessWidget {
  final List<BarberModel> barbers;
  final BarberModel? selected;
  final ValueChanged<BarberModel> onSelect;
  final VoidCallback onNext;

  const _BarberStep({
    super.key,
    required this.barbers,
    required this.selected,
    required this.onSelect,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 4),
          child: Text('Escolha o barbeiro',
              style: Theme.of(context).textTheme.headlineMedium),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          child: Text('Quem vai te atender hoje?',
              style: Theme.of(context).textTheme.bodyMedium),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: barbers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final barber = barbers[i];
              final isSel = selected?.id == barber.id;
              return GestureDetector(
                onTap: () => onSelect(barber),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSel
                        ? AppTheme.gold.withOpacity(0.06)
                        : AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSel ? AppTheme.gold : AppTheme.inputBorder,
                      width: isSel ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      BarberAvatar(
                          initials: barber.avatarInitials, selected: isSel),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(barber.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontSize: 15)),
                            const SizedBox(height: 3),
                            Text(barber.specialty,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontSize: 12)),
                            const SizedBox(height: 6),
                            StarRating(
                                rating: barber.rating,
                                reviewCount: barber.reviewCount),
                          ],
                        ),
                      ),
                      if (isSel)
                        const Icon(Icons.check_circle_rounded,
                            color: AppTheme.gold, size: 20),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: PrimaryButton(
            label: 'Proximo',
            onPressed: selected != null ? onNext : null,
          ),
        ),
      ],
    );
  }
}

// â”€â”€ Step 1: Data & Hora â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _DateTimeStep extends StatelessWidget {
  final DateTime? selectedDate;
  final String? selectedTime;
  final Set<String> bookedSlots;
  final DateTime referenceNow;
  final Map<int, WorkingHoursEntity> workingHours;
  final bool Function(DateTime) isDateBlocked;
  final ValueChanged<DateTime> onDateSelected;
  final ValueChanged<String> onTimeSelected;
  final VoidCallback onNext;

  const _DateTimeStep({
    super.key,
    required this.selectedDate,
    required this.selectedTime,
    required this.bookedSlots,
    required this.referenceNow,
    required this.workingHours,
    required this.isDateBlocked,
    required this.onDateSelected,
    required this.onTimeSelected,
    required this.onNext,
  });

  List<String> get _slotsForDay {
    final date = selectedDate;
    if (date == null) return MockData.timeSlots;
    final hours = workingHours[date.weekday];
    if (hours == null) return MockData.timeSlots;
    return hours.availableSlots(MockData.timeSlots);
  }

  bool get _hasUnavailableSlots {
    if (selectedDate == null) return false;
    return bookedSlots.isNotEmpty || _slotsForDay.any(_isPastSlot);
  }

  bool _isPastSlot(String slot) {
    if (selectedDate == null) return false;

    final parts = slot.split(':');
    if (parts.length != 2) return false;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return false;

    final now = referenceNow;
    final slotDateTime = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      hour,
      minute,
    );

    return !slotDateTime.isAfter(now);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 4),
          child: Text('Data e horario',
              style: Theme.of(context).textTheme.headlineMedium),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          child: Text('Quando voce quer ser atendido?',
              style: Theme.of(context).textTheme.bodyMedium),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date picker
                GestureDetector(
                  onTap: () async {
                    final today = DateTime(
                      referenceNow.year,
                      referenceNow.month,
                      referenceNow.day,
                    );
                    final selectedDay = selectedDate == null
                        ? null
                        : DateTime(
                            selectedDate!.year,
                            selectedDate!.month,
                            selectedDate!.day,
                          );
                    final initialDate =
                        selectedDay != null && !selectedDay.isBefore(today)
                            ? selectedDay
                            : today;
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: initialDate,
                      firstDate: today,
                      lastDate: today.add(const Duration(days: 60)),
                      selectableDayPredicate: (day) => !isDateBlocked(day),
                      builder: (ctx, child) => Theme(
                        data: Theme.of(ctx).copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: AppTheme.gold,
                            onPrimary: AppTheme.background,
                            surface: AppTheme.surfaceElevated,
                            onSurface: AppTheme.textPrimary,
                          ),
                          dialogTheme: const DialogThemeData(
                              backgroundColor: AppTheme.surface),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) onDateSelected(picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selectedDate != null
                            ? AppTheme.gold
                            : AppTheme.inputBorder,
                        width: selectedDate != null ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            color: selectedDate != null
                                ? AppTheme.gold
                                : AppTheme.textHint,
                            size: 20),
                        const SizedBox(width: 14),
                        Text(
                          selectedDate != null
                              ? _fmt(selectedDate!)
                              : 'Selecionar data',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: selectedDate != null
                                        ? AppTheme.textPrimary
                                        : AppTheme.textHint,
                                    fontSize: 15,
                                  ),
                        ),
                        const Spacer(),
                        const Icon(Icons.chevron_right_rounded,
                            color: AppTheme.textHint, size: 20),
                      ],
                    ),
                  ),
                ),

                if (selectedDate != null) ...[
                  const SizedBox(height: 24),
                  const SectionHeader(title: 'Horarios disponiveis'),
                  const SizedBox(height: 6),
                  if (_hasUnavailableSlots)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline,
                              size: 12, color: AppTheme.textHint),
                          const SizedBox(width: 5),
                          Text(
                            'Horarios ocupados ou ja passados ficam indisponiveis.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                    fontSize: 11, color: AppTheme.textHint),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  if (_slotsForDay.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Esta barbearia está fechada neste dia.',
                        style: GoogleFonts.jost(
                            color: AppTheme.textHint, fontSize: 13),
                      ),
                    ),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _slotsForDay.map((slot) {
                      final isSel = selectedTime == slot;
                      final isBooked = bookedSlots.contains(slot);
                      final isPast = _isPastSlot(slot);
                      final isUnavailable = isBooked || isPast;
                      return GestureDetector(
                        onTap:
                            isUnavailable ? null : () => onTimeSelected(slot),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isUnavailable
                                ? AppTheme.surface
                                : isSel
                                    ? AppTheme.gold.withOpacity(0.12)
                                    : AppTheme.surfaceElevated,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isUnavailable
                                  ? AppTheme.divider
                                  : isSel
                                      ? AppTheme.gold
                                      : AppTheme.inputBorder,
                              width: isSel ? 1.5 : 1,
                            ),
                          ),
                          child: Text(
                            slot,
                            style: GoogleFonts.jost(
                              fontSize: 14,
                              fontWeight:
                                  isSel ? FontWeight.w600 : FontWeight.w400,
                              color: isUnavailable
                                  ? AppTheme.textHint
                                  : isSel
                                      ? AppTheme.gold
                                      : AppTheme.textSecondary,
                              decoration: isUnavailable
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: PrimaryButton(
            label: 'Proximo',
            onPressed:
                (selectedDate != null && selectedTime != null) ? onNext : null,
          ),
        ),
      ],
    );
  }

  String _fmt(DateTime d) {
    const months = [
      '',
      'jan',
      'fev',
      'mar',
      'abr',
      'mai',
      'jun',
      'jul',
      'ago',
      'set',
      'out',
      'nov',
      'dez'
    ];
    const weekdays = [
      '',
      'segunda',
      'terca',
      'quarta',
      'quinta',
      'sexta',
      'sabado',
      'domingo'
    ];
    return '${weekdays[d.weekday]}, ${d.day} de ${months[d.month]} de ${d.year}';
  }
}

// â”€â”€ Step 2: Confirmar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _ConfirmStep extends StatelessWidget {
  final ServiceModel service;
  final BarberModel barber;
  final BarbershopModel barbershop;
  final DateTime date;
  final String timeSlot;
  final VoidCallback onConfirm;
  final bool isLoading;
  final MembershipEntity? activeMembership;
  final bool useMembershipCut;
  final ValueChanged<bool>? onToggleUseMembership;

  const _ConfirmStep({
    super.key,
    required this.service,
    required this.barber,
    required this.barbershop,
    required this.date,
    required this.timeSlot,
    required this.onConfirm,
    required this.isLoading,
    this.activeMembership,
    this.useMembershipCut = false,
    this.onToggleUseMembership,
  });

  @override
  Widget build(BuildContext context) {
    final membership = activeMembership;
    final canRedeemCut = membership != null && membership.hasCutsAvailable;
    final isVip = membership?.plan.priorityBooking ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 4),
          child: Row(
            children: [
              Expanded(
                child: Text('Confirmar',
                    style: Theme.of(context).textTheme.headlineMedium),
              ),
              if (isVip)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: membership!.plan.tier.accentColor
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: membership.plan.tier.accentColor
                            .withValues(alpha: 0.4)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.star_rounded,
                        color: membership.plan.tier.accentColor, size: 13),
                    const SizedBox(width: 4),
                    Text('Prioridade VIP',
                        style: GoogleFonts.jost(
                            color: membership.plan.tier.accentColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ]),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Text('Revise os detalhes do agendamento.',
              style: Theme.of(context).textTheme.bodyMedium),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                _ConfirmRow(
                  icon: Icons.storefront_outlined,
                  label: 'Barbearia',
                  value: barbershop.name,
                  subValue: barbershop.address,
                ),
                const SizedBox(height: 12),
                _ConfirmRow(
                  icon: Icons.content_cut_rounded,
                  label: 'Servico',
                  value: service.name,
                  subValue: useMembershipCut
                      ? 'Incluso na assinatura'
                      : service.formattedPrice,
                ),
                const SizedBox(height: 12),
                if (canRedeemCut) ...[
                  _MembershipCutBanner(
                    membership: membership,
                    value: useMembershipCut,
                    onChanged: onToggleUseMembership,
                  ),
                  const SizedBox(height: 12),
                ],
                _ConfirmRow(
                  icon: Icons.person_outline_rounded,
                  label: 'Barbeiro',
                  value: barber.name,
                  subValue: barber.specialty,
                ),
                const SizedBox(height: 12),
                _ConfirmRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Data',
                  value: _fmtDate(date),
                  subValue: null,
                ),
                const SizedBox(height: 12),
                _ConfirmRow(
                  icon: Icons.schedule_outlined,
                  label: 'Horario',
                  value: timeSlot,
                  subValue: service.formattedDuration,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.gold.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.gold.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          color: AppTheme.gold, size: 16),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Chegue 5 minutos antes do horario marcado.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontSize: 12, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: PrimaryButton(
            label: 'Confirmar agendamento',
            onPressed: onConfirm,
            isLoading: isLoading,
          ),
        ),
      ],
    );
  }

  String _fmtDate(DateTime d) {
    const months = [
      '',
      'jan',
      'fev',
      'mar',
      'abr',
      'mai',
      'jun',
      'jul',
      'ago',
      'set',
      'out',
      'nov',
      'dez'
    ];
    return '${d.day} de ${months[d.month]} de ${d.year}';
  }
}

// ── Banner: usar corte da assinatura ────────────────────────────────────────
class _MembershipCutBanner extends StatelessWidget {
  final MembershipEntity membership;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _MembershipCutBanner({
    required this.membership,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final color = membership.plan.tier.accentColor;
    return GestureDetector(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: value ? color.withValues(alpha: 0.1) : AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: value ? color : AppTheme.inputBorder,
            width: value ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.workspace_premium_rounded, color: color, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Usar corte da assinatura ${membership.plan.name}',
                    style: GoogleFonts.jost(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    membership.cutsRemainingLabel,
                    style: GoogleFonts.jost(color: color, fontSize: 11),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: color,
              inactiveTrackColor: AppTheme.inputBorder,
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfirmRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? subValue;

  const _ConfirmRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.subValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.inputBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.gold, size: 18),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontSize: 11, letterSpacing: 0.5),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontSize: 15),
                ),
                if (subValue != null)
                  Text(
                    subValue!,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontSize: 12, color: AppTheme.gold),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
