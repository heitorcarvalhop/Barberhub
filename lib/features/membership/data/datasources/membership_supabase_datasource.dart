import 'package:barber_hub/core/services/supabase_service.dart';
import 'package:barber_hub/features/membership/domain/entities/membership_entity.dart';
import 'package:barber_hub/features/membership/domain/entities/membership_plan_entity.dart';

/// Datasource Supabase de assinaturas — substitui [MembershipMockDatasource]
/// mantendo a mesma API pública (mesmos nomes/assinaturas de método).
class MembershipSupabaseDatasource {
  bool get isConfigured => SupabaseService.client != null;

  Future<List<MembershipPlanEntity>> getPlansForShop(String shopId) async {
    final client = SupabaseService.client;
    if (client == null) return const [];

    final rows = await client
        .from('membership_plans')
        .select()
        .eq('barbershop_id', shopId)
        .order('price_monthly');

    return _rows(rows).map(_plan).toList();
  }

  Future<MembershipPlanEntity> createPlan(MembershipPlanEntity plan) async {
    final client = SupabaseService.client;
    if (client == null) {
      throw StateError('Supabase não configurado.');
    }

    final row = await client
        .from('membership_plans')
        .insert({
          'barbershop_id': plan.barbershopId,
          'tier': plan.tier.name,
          'name': plan.name,
          'price_monthly': plan.priceMonthly,
          'cuts_per_month': plan.cutsPerMonth,
          'includes_beard': plan.includesBeard,
          'priority_booking': plan.priorityBooking,
          'product_discount_percent': plan.productDiscountPercent,
          'benefits': plan.benefits,
          'is_active': plan.isActive,
        })
        .select()
        .single();

    return _plan(Map<String, dynamic>.from(row as Map));
  }

  Future<void> updatePlan(MembershipPlanEntity plan) async {
    final client = SupabaseService.client;
    if (client == null) return;

    final rows = await client
        .from('membership_plans')
        .update({
          'tier': plan.tier.name,
          'name': plan.name,
          'price_monthly': plan.priceMonthly,
          'cuts_per_month': plan.cutsPerMonth,
          'includes_beard': plan.includesBeard,
          'priority_booking': plan.priorityBooking,
          'product_discount_percent': plan.productDiscountPercent,
          'benefits': plan.benefits,
          'is_active': plan.isActive,
        })
        .eq('id', plan.id)
        .select('id');

    if (rows.isEmpty) {
      throw StateError(
        'Nenhum plano foi atualizado. Verifique o linked_id do perfil e a policy da tabela membership_plans.',
      );
    }
  }

  Future<void> deletePlan(String planId) async {
    final client = SupabaseService.client;
    if (client == null) return;

    final rows = await client
        .from('membership_plans')
        .delete()
        .eq('id', planId)
        .select('id');

    if (rows.isEmpty) {
      throw StateError(
        'Nenhum plano foi excluído. Verifique o linked_id do perfil e a policy da tabela membership_plans.',
      );
    }
  }

  Future<List<MembershipEntity>> getClientMemberships(String clientId) async {
    final client = SupabaseService.client;
    if (client == null) return const [];

    final rows = await client
        .from('memberships')
        .select('*, membership_plans(*), barbershops(name)')
        .eq('client_id', clientId)
        .order('created_at', ascending: false);

    return _rows(rows).map(_membership).toList();
  }

  Future<List<MembershipEntity>> getShopMemberships(String shopId) async {
    final client = SupabaseService.client;
    if (client == null) return const [];

    final rows = await client
        .from('memberships')
        .select('*, membership_plans(*), barbershops(name)')
        .eq('barbershop_id', shopId)
        .order('created_at', ascending: false);

    return _rows(rows).map(_membership).toList();
  }

  Future<MembershipEntity> subscribe({
    required String clientId,
    required String clientName,
    required String shopId,
    required String planId,
  }) async {
    final client = SupabaseService.client;
    if (client == null) {
      throw StateError('Supabase não configurado.');
    }

    final planRow = await client
        .from('membership_plans')
        .select()
        .eq('id', planId)
        .single();
    final plan = _plan(Map<String, dynamic>.from(planRow as Map));

    final now = DateTime.now();
    final nextBilling = DateTime(now.year, now.month + 1, now.day);

    final row = await client
        .from('memberships')
        .insert({
          'client_id': clientId,
          'client_name': clientName,
          'barbershop_id': shopId,
          'plan_id': planId,
          'status': 'active',
          'start_date': now.toUtc().toIso8601String(),
          'next_billing_date': nextBilling.toUtc().toIso8601String(),
          'cuts_used_this_month': 0,
          'renewal_count': 0,
        })
        .select('*, barbershops(name)')
        .single();

    return _membership(Map<String, dynamic>.from(row as Map), planOverride: plan);
  }

  Future<MembershipEntity> upgradeMembership({
    required String membershipId,
    required String newPlanId,
  }) async {
    final client = SupabaseService.client;
    if (client == null) {
      throw StateError('Supabase não configurado.');
    }

    final rows = await client
        .from('memberships')
        .update({
          'plan_id': newPlanId,
          'cuts_used_this_month': 0,
        })
        .eq('id', membershipId)
        .select('*, membership_plans(*), barbershops(name)');

    if (rows.isEmpty) {
      throw StateError(
        'Nenhuma assinatura foi atualizada. Verifique a policy da tabela memberships.',
      );
    }

    return _membership(Map<String, dynamic>.from(rows.first as Map));
  }

  /// Cancela e exclui a assinatura definitivamente — evita acumular
  /// linhas "cancelled" que poderiam colidir com uma nova assinatura
  /// futura na mesma barbearia.
  Future<void> cancelMembership(String membershipId) async {
    final client = SupabaseService.client;
    if (client == null) return;

    final rows = await client
        .from('memberships')
        .delete()
        .eq('id', membershipId)
        .select('id');

    if (rows.isEmpty) {
      throw StateError(
        'Nenhuma assinatura foi excluída. Verifique a policy da tabela memberships.',
      );
    }
  }

  Future<void> pauseMembership(String membershipId) async {
    await _updateStatus(membershipId, 'paused');
  }

  Future<void> resumeMembership(String membershipId) async {
    await _updateStatus(membershipId, 'active');
  }

  Future<void> _updateStatus(String membershipId, String status) async {
    final client = SupabaseService.client;
    if (client == null) return;

    final rows = await client
        .from('memberships')
        .update({'status': status})
        .eq('id', membershipId)
        .select('id');

    if (rows.isEmpty) {
      throw StateError(
        'Nenhuma assinatura foi atualizada. Verifique a policy da tabela memberships.',
      );
    }
  }

  Future<MembershipEntity> useCut(String membershipId) async {
    final client = SupabaseService.client;
    if (client == null) {
      throw StateError('Supabase não configurado.');
    }

    final current = await client
        .from('memberships')
        .select('cuts_used_this_month')
        .eq('id', membershipId)
        .single();
    final usedSoFar = _int(
        Map<String, dynamic>.from(current as Map)['cuts_used_this_month']);

    final row = await client
        .from('memberships')
        .update({'cuts_used_this_month': usedSoFar + 1})
        .eq('id', membershipId)
        .select('*, membership_plans(*), barbershops(name)')
        .single();

    return _membership(Map<String, dynamic>.from(row as Map));
  }

  // ── Mapeamento ────────────────────────────────────────────────────────────

  List<Map<String, dynamic>> _rows(Object? value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
    }
    return const [];
  }

  MembershipPlanEntity _plan(Map<String, dynamic> row) {
    final tierName = _string(row['tier'], fallback: 'basic');
    final tier = MembershipTier.values.firstWhere(
      (t) => t.name == tierName,
      orElse: () => MembershipTier.basic,
    );

    return MembershipPlanEntity(
      id: _string(row['id']),
      barbershopId: _string(row['barbershop_id']),
      tier: tier,
      name: _string(row['name'], fallback: tier.label),
      priceMonthly: _double(row['price_monthly']),
      benefits: (row['benefits'] is List)
          ? List<String>.from((row['benefits'] as List).map((e) => e.toString()))
          : const [],
      cutsPerMonth:
          row['cuts_per_month'] == null ? null : _int(row['cuts_per_month']),
      includesBeard: _bool(row['includes_beard']),
      priorityBooking: _bool(row['priority_booking']),
      productDiscountPercent: _int(row['product_discount_percent']),
      isActive: _bool(row['is_active'], fallback: true),
    );
  }

  MembershipEntity _membership(
    Map<String, dynamic> row, {
    MembershipPlanEntity? planOverride,
  }) {
    final planRow = row['membership_plans'];
    final plan = planOverride ??
        (planRow is Map
            ? _plan(Map<String, dynamic>.from(planRow))
            : MembershipPlanEntity(
                id: _string(row['plan_id']),
                barbershopId: _string(row['barbershop_id']),
                tier: MembershipTier.basic,
                name: 'Plano',
                priceMonthly: 0,
                benefits: const [],
              ));

    final shopRow = row['barbershops'];
    final shopName = shopRow is Map
        ? _string(Map<String, dynamic>.from(shopRow)['name'], fallback: 'Barbearia')
        : 'Barbearia';

    final statusName = _string(row['status'], fallback: 'active');
    final status = MembershipStatus.values.firstWhere(
      (s) => s.name == statusName,
      orElse: () => MembershipStatus.active,
    );

    return MembershipEntity(
      id: _string(row['id']),
      clientId: _string(row['client_id']),
      clientName: _string(row['client_name']),
      barbershopId: _string(row['barbershop_id']),
      barbershopName: shopName,
      plan: plan,
      status: status,
      startDate: _date(row['start_date']),
      nextBillingDate: _date(row['next_billing_date']),
      cutsUsedThisMonth: _int(row['cuts_used_this_month']),
      renewalCount: _int(row['renewal_count']),
    );
  }

  String _string(Object? value, {String fallback = ''}) {
    if (value == null) return fallback;
    final text = value.toString();
    return text.isEmpty ? fallback : text;
  }

  double _double(Object? value, {double fallback = 0}) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  int _int(Object? value, {int fallback = 0}) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  bool _bool(Object? value, {bool fallback = false}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value?.toString().toLowerCase();
    if (text == 'true') return true;
    if (text == 'false') return false;
    return fallback;
  }

  DateTime _date(Object? value) {
    if (value is DateTime) return value;
    return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
  }
}
