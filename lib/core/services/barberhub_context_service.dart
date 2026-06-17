import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// Busca dados reais do Supabase e formata um bloco de contexto para o Ollama.
/// Cada seção falha de forma independente — um erro não cancela as demais.
class BarberhubContextService {
  static Future<({String context, String? error})> build() async {
    final client = SupabaseService.client;
    if (client == null) {
      return (context: '', error: 'Supabase não está configurado.');
    }

    final now = DateTime.now();
    final today = _isoDate(now);
    final buffer = StringBuffer();
    String? firstError;

    buffer
      ..writeln('=== DADOS REAIS DO BARBER HUB ===')
      ..writeln('Data/hora: ${_fmtDate(today)} às ${_fmtTime(now)}')
      ..writeln();

    // Cada bloco tem seu próprio try/catch para não cancelar os demais
    try {
      await _appendUser(client, buffer, today);
    } catch (e) {
      firstError ??= 'Usuário: $e';
    }

    try {
      await _appendShops(client, buffer);
    } catch (e) {
      firstError ??= 'Barbearias: $e';
    }

    final result = buffer.toString().trim();

    // Considera vazio se só tem o cabeçalho (nenhum dado real foi carregado)
    final hasData = result.split('\n').length > 3;
    return (
      context: hasData ? result : '',
      error: hasData ? null : (firstError ?? 'Nenhum dado retornado pelo banco.'),
    );
  }

  // ── Usuário e agendamentos ───────────────────────────────────────────────────

  static Future<void> _appendUser(
    SupabaseClient client,
    StringBuffer buf,
    String today,
  ) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;

    final profile = await client
        .from('profiles')
        .select('name')
        .eq('id', userId)
        .maybeSingle();

    if (profile != null) {
      buf
        ..writeln('CLIENTE LOGADO: ${profile['name']}')
        ..writeln();
    }

    await _appendAppointments(client, buf, userId, today);
  }

  static Future<void> _appendAppointments(
    SupabaseClient client,
    StringBuffer buf,
    String userId,
    String today,
  ) async {
    final upcoming = await client
        .from('appointments')
        .select()
        .eq('client_id', userId)
        .eq('status', 'scheduled')
        .gte('date', today)
        .order('date')
        .order('time_slot')
        .limit(5);

    if (upcoming.isEmpty) {
      buf
        ..writeln('AGENDAMENTOS FUTUROS: Nenhum agendamento marcado.')
        ..writeln();
      return;
    }

    buf.writeln('AGENDAMENTOS FUTUROS:');

    final enriched = await Future.wait(upcoming.map((a) async {
      final results = await Future.wait([
        _name(client, 'services', a['service_id'] as String?),
        _name(client, 'barbers', a['barber_id'] as String?),
        _name(client, 'barbershops', a['barbershop_id'] as String?),
      ]);
      return (appt: a, service: results[0], barber: results[1], shop: results[2]);
    }));

    for (final e in enriched) {
      final a = e.appt;
      final date = _fmtDate(a['date'] as String? ?? '');
      final time = a['time_slot'] as String? ?? '';
      final status = _statusLabel(a['status'] as String? ?? '');
      buf.writeln(
          '• ${e.service} em ${e.shop} com ${e.barber} — $date às $time [$status]');
    }
    buf.writeln();

    final past = await client
        .from('appointments')
        .select()
        .eq('client_id', userId)
        .eq('status', 'completed')
        .order('date', ascending: false)
        .limit(3);

    if (past.isNotEmpty) {
      buf.writeln('ÚLTIMOS ATENDIMENTOS:');
      final pastEnriched = await Future.wait(past.map((a) async {
        final results = await Future.wait([
          _name(client, 'services', a['service_id'] as String?),
          _name(client, 'barbershops', a['barbershop_id'] as String?),
        ]);
        return (appt: a, service: results[0], shop: results[1]);
      }));
      for (final e in pastEnriched) {
        final date = _fmtDate(e.appt['date'] as String? ?? '');
        buf.writeln('• ${e.service} em ${e.shop} — $date');
      }
      buf.writeln();
    }
  }

  // ── Barbearias, serviços, barbeiros e produtos ──────────────────────────────

  static Future<void> _appendShops(
    SupabaseClient client,
    StringBuffer buf,
  ) async {
    final shops = await client
        .from('barbershops')
        .select()
        .order('rating', ascending: false)
        .limit(10);

    if (shops.isEmpty) return;

    buf.writeln('BARBEARIAS NO APP:');

    for (int i = 0; i < shops.length; i++) {
      final s = shops[i];
      final shopId = s['id'] as String;
      final rating = (s['rating'] as num?)?.toStringAsFixed(1) ?? '—';
      final reviews = s['review_count'] ?? 0;
      final open = s['is_open'] == true ? 'Aberta agora' : 'Fechada';
      buf.writeln(
          '${i + 1}. ${s['name']} — ${s['address']} — ★$rating ($reviews avaliações) — $open');

      final [svcs, barbers, products] = await Future.wait([
        client
            .from('services')
            .select('name, price, duration_minutes')
            .eq('barbershop_id', shopId)
            .eq('is_active', true),
        client
            .from('barbers')
            .select('name, specialty, rating, review_count')
            .eq('barbershop_id', shopId)
            .eq('is_active', true),
        client
            .from('products')
            .select('name, price, category, brand')
            .eq('barbershop_id', shopId)
            .eq('is_available', true),
      ]);

      if ((svcs as List).isNotEmpty) {
        final list = svcs.map((sv) {
          final price = (sv['price'] as num).toStringAsFixed(0);
          return '${sv['name']} (R\$$price, ${sv['duration_minutes']}min)';
        }).join(', ');
        buf.writeln('   Serviços: $list');
      }

      if ((barbers as List).isNotEmpty) {
        final list = barbers.map((b) {
          final r = (b['rating'] as num?)?.toStringAsFixed(1) ?? '—';
          final rc = b['review_count'] ?? 0;
          return '${b['name']} — ${b['specialty']} (★$r, $rc aval.)';
        }).join('; ');
        buf.writeln('   Barbeiros: $list');
      }

      if ((products as List).isNotEmpty) {
        final list = products.map((p) {
          final price = (p['price'] as num).toStringAsFixed(0);
          final cat = _categoryLabel(p['category'] as String? ?? '');
          final brand = p['brand'] as String? ?? '';
          return '${p['name']}${brand.isNotEmpty ? ' ($brand)' : ''} — $cat — R\$$price';
        }).join('; ');
        buf.writeln('   Produtos: $list');
      }
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  static Future<String> _name(
    SupabaseClient client,
    String table,
    String? id,
  ) async {
    if (id == null) return '—';
    try {
      final row = await client
          .from(table)
          .select('name')
          .eq('id', id)
          .maybeSingle();
      return row?['name'] as String? ?? '—';
    } catch (_) {
      return '—';
    }
  }

  static String _isoDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _fmtDate(String iso) {
    final p = iso.split('-');
    return p.length == 3 ? '${p[2]}/${p[1]}/${p[0]}' : iso;
  }

  static String _fmtTime(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  static String _categoryLabel(String s) => switch (s) {
        'pomade' => 'Pomada',
        'shampoo' => 'Shampoo',
        'beard' => 'Barba',
        'skincare' => 'Skincare',
        'tool' => 'Ferramenta',
        'kit' => 'Kit',
        _ => s,
      };

  static String _statusLabel(String s) => switch (s) {
        'scheduled' => 'Agendado',
        'completed' => 'Concluído',
        'cancelled' => 'Cancelado',
        _ => s,
      };
}
