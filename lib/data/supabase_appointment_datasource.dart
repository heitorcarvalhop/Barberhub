import 'package:barber_hub/core/services/supabase_service.dart';
import 'package:barber_hub/models/appointment_model.dart';
import 'package:barber_hub/models/barber_model.dart';
import 'package:barber_hub/models/service_model.dart';

class SupabaseAppointmentDatasource {
  bool get isConfigured => SupabaseService.client != null;

  Future<List<AppointmentModel>> loadAppointments(
    List<BarbershopModel> shops,
  ) async {
    final client = SupabaseService.client;
    if (client == null) return const [];

    final response = await client
        .from('appointments')
        .select()
        .order('date', ascending: false)
        .order('time_slot');

    final rows = _rows(response);
    return rows
        .map((row) => _appointmentFromRow(row, shops))
        .whereType<AppointmentModel>()
        .toList();
  }

  Future<AppointmentModel> createAppointment({
    required String clientId,
    required String clientName,
    required ServiceModel service,
    required BarberModel barber,
    required BarbershopModel barbershop,
    required DateTime date,
    required String timeSlot,
    bool paidViaMembership = false,
  }) async {
    final client = SupabaseService.client;
    if (client == null) {
      throw StateError('Supabase nao configurado para agendamentos.');
    }

    final row = await client
        .from('appointments')
        .insert({
          'client_id': clientId,
          'client_name': clientName,
          'service_id': service.id,
          'barber_id': barber.id,
          'barbershop_id': barbershop.id,
          'date': _dateOnly(date),
          'time_slot': timeSlot,
          'status': AppointmentStatus.scheduled.name,
          'paid_via_membership': paidViaMembership,
        })
        .select()
        .single();

    return _appointmentFromRow(
      Map<String, dynamic>.from(row),
      [barbershop],
    )!;
  }

  Future<void> updateStatus(String id, AppointmentStatus status) async {
    final client = SupabaseService.client;
    if (client == null) return;

    await client
        .from('appointments')
        .update({'status': status.name}).eq('id', id);
  }

  Future<AppointmentModel> rescheduleAppointment({
    required AppointmentModel old,
    required DateTime newDate,
    required String newTimeSlot,
    required BarberModel newBarber,
  }) async {
    await updateStatus(old.id, AppointmentStatus.cancelled);
    return createAppointment(
      clientId: old.clientId,
      clientName: old.clientName,
      service: old.service,
      barber: newBarber,
      barbershop: old.barbershop,
      date: newDate,
      timeSlot: newTimeSlot,
      paidViaMembership: old.paidViaMembership,
    );
  }

  AppointmentModel? _appointmentFromRow(
    Map<String, dynamic> row,
    List<BarbershopModel> shops,
  ) {
    final shopId = _string(row['barbershop_id']);
    final serviceId = _string(row['service_id']);
    final barberId = _string(row['barber_id']);

    final shop = shops.where((item) => item.id == shopId).firstOrNull;
    if (shop == null) return null;

    final service =
        shop.services.where((item) => item.id == serviceId).firstOrNull;
    final barber =
        shop.barbers.where((item) => item.id == barberId).firstOrNull;
    final date = DateTime.tryParse(_string(row['date']));

    if (service == null || barber == null || date == null) return null;

    return AppointmentModel(
      id: _string(row['id']),
      clientId: _string(row['client_id']),
      clientName: _string(row['client_name'], fallback: 'Cliente'),
      service: service,
      barber: barber,
      barbershop: shop,
      date: date,
      timeSlot: _string(row['time_slot']),
      status: _status(row['status']),
      paidViaMembership: _bool(row['paid_via_membership']),
    );
  }

  bool _bool(Object? value) {
    if (value is bool) return value;
    return value?.toString().toLowerCase() == 'true';
  }

  List<Map<String, dynamic>> _rows(Object? value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
    }
    return const [];
  }

  AppointmentStatus _status(Object? value) {
    final name = _string(value, fallback: AppointmentStatus.scheduled.name);
    return AppointmentStatus.values.firstWhere(
      (item) => item.name == name,
      orElse: () => AppointmentStatus.scheduled,
    );
  }

  String _dateOnly(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _string(Object? value, {String fallback = ''}) {
    if (value == null) return fallback;
    final text = value.toString();
    return text.isEmpty ? fallback : text;
  }
}
