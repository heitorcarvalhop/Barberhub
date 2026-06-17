import 'package:barber_hub/core/services/supabase_service.dart';
import 'package:barber_hub/models/appointment_model.dart';

class SupabaseReviewDatasource {
  bool get isConfigured => SupabaseService.client != null;

  Future<List<ReviewModel>> loadReviews() async {
    final client = SupabaseService.client;
    if (client == null) return const [];

    final response =
        await client.from('reviews').select().order('created_at', ascending: false);

    return _rows(response).map(_reviewFromRow).toList();
  }

  Future<ReviewModel> createReview({
    required AppointmentModel appointment,
    required int barbershopRating,
    required int barberRating,
    String? comment,
  }) async {
    final client = SupabaseService.client;
    if (client == null) {
      throw StateError('Supabase não configurado para avaliações.');
    }

    final row = await client
        .from('reviews')
        .insert({
          'appointment_id': appointment.id,
          'client_id': appointment.clientId,
          'client_name': appointment.clientName,
          'barbershop_id': appointment.barbershop.id,
          'barbershop_name': appointment.barbershop.name,
          'barber_id': appointment.barber.id,
          'barber_name': appointment.barber.name,
          'service_name': appointment.service.name,
          'barbershop_rating': barbershopRating,
          'barber_rating': barberRating,
          'comment': (comment == null || comment.trim().isEmpty) ? null : comment.trim(),
        })
        .select()
        .single();

    return _reviewFromRow(Map<String, dynamic>.from(row));
  }

  ReviewModel _reviewFromRow(Map<String, dynamic> row) {
    return ReviewModel(
      id: _string(row['id']),
      appointmentId: _string(row['appointment_id']),
      clientId: _string(row['client_id']),
      clientName: _string(row['client_name'], fallback: 'Cliente'),
      barbershopId: _string(row['barbershop_id']),
      barbershopName: _string(row['barbershop_name'], fallback: 'Barbearia'),
      barberId: _string(row['barber_id']),
      barberName: _string(row['barber_name'], fallback: 'Barbeiro'),
      serviceName: _string(row['service_name'], fallback: 'Serviço'),
      barbershopRating: _int(row['barbershop_rating'], fallback: 5),
      barberRating: _int(row['barber_rating'], fallback: 5),
      comment: _nullableString(row['comment']),
      createdAt: DateTime.tryParse(_string(row['created_at'])) ?? DateTime.now(),
    );
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

  String _string(Object? value, {String fallback = ''}) {
    if (value == null) return fallback;
    final text = value.toString();
    return text.isEmpty ? fallback : text;
  }

  String? _nullableString(Object? value) {
    final text = _string(value);
    return text.isEmpty ? null : text;
  }

  int _int(Object? value, {int fallback = 0}) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
