import 'service_model.dart';
import 'barber_model.dart';
import 'barbershop_model.dart';
import 'review_model.dart';

export 'barbershop_model.dart';
export 'review_model.dart';

enum AppointmentStatus { scheduled, completed, cancelled }

class AppointmentModel {
  final String id;
  final String clientId;
  final String clientName;
  final ServiceModel service;
  final BarberModel barber;
  final BarbershopModel barbershop;
  final DateTime date;
  final String timeSlot;
  AppointmentStatus status;

  /// Avaliação do cliente para este agendamento.
  /// null = ainda não avaliado.
  ReviewModel? review;

  /// Se este agendamento foi resgatado como corte incluso na assinatura
  /// (não cobrado separadamente).
  final bool paidViaMembership;

  AppointmentModel({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.service,
    required this.barber,
    required this.barbershop,
    required this.date,
    required this.timeSlot,
    this.status = AppointmentStatus.scheduled,
    this.review,
    this.paidViaMembership = false,
  }) {
    assert(
      barbershop.services.any((s) => s.id == service.id),
      'O serviço "${service.name}" não pertence à barbearia "${barbershop.name}".',
    );
    assert(
      barbershop.barbers.any((b) => b.id == barber.id),
      'O barbeiro "${barber.name}" não pertence à barbearia "${barbershop.name}".',
    );
  }

  // ── Status ─────────────────────────────────────────────────────────────────
  String get statusLabel {
    switch (status) {
      case AppointmentStatus.scheduled:  return 'Agendado';
      case AppointmentStatus.completed:  return 'Concluído';
      case AppointmentStatus.cancelled:  return 'Cancelado';
    }
  }

  bool get canCancel     => status == AppointmentStatus.scheduled;
  bool get canReschedule => status == AppointmentStatus.scheduled;
  bool get canComplete   => status == AppointmentStatus.scheduled;

  bool get isUpcoming =>
      status == AppointmentStatus.scheduled && date.isAfter(DateTime.now());

  /// O cliente pode avaliar somente agendamentos concluídos e ainda não avaliados.
  bool get canReview =>
      status == AppointmentStatus.completed && review == null;

  bool get isReviewed =>
      status == AppointmentStatus.completed && review != null;

  // ── Date formatters ────────────────────────────────────────────────────────
  String get formattedDate {
    const months = [
      '', 'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
      'jul', 'ago', 'set', 'out', 'nov', 'dez'
    ];
    return '${date.day} de ${months[date.month]}';
  }

  String get formattedDateFull {
    const months = [
      '', 'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
      'jul', 'ago', 'set', 'out', 'nov', 'dez'
    ];
    return '${date.day} de ${months[date.month]} de ${date.year}';
  }

  String get monthAbbr {
    const months = [
      '', 'JAN', 'FEV', 'MAR', 'ABR', 'MAI', 'JUN',
      'JUL', 'AGO', 'SET', 'OUT', 'NOV', 'DEZ'
    ];
    return months[date.month];
  }
}
