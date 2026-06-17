import 'package:flutter/material.dart';
import 'package:barber_hub/core/theme/app_theme.dart';

/// Tier de assinatura — define a hierarquia dos planos.
enum MembershipTier { basic, premium, vip }

extension MembershipTierExt on MembershipTier {
  String get label {
    switch (this) {
      case MembershipTier.basic:   return 'Basic';
      case MembershipTier.premium: return 'Premium';
      case MembershipTier.vip:     return 'VIP';
    }
  }

  String get tagline {
    switch (this) {
      case MembershipTier.basic:   return 'Cortes mensais garantidos';
      case MembershipTier.premium: return 'Corte + Barba ilimitados';
      case MembershipTier.vip:     return 'Prioridade total + benefícios exclusivos';
    }
  }

  /// Cor de destaque do plano (usada em cards e badges).
  Color get accentColor {
    switch (this) {
      case MembershipTier.basic:   return const Color(0xFF6B9FD4);
      case MembershipTier.premium: return AppTheme.gold;
      case MembershipTier.vip:     return const Color(0xFFB87FE8);
    }
  }

  /// Ícone representativo do plano.
  IconData get icon {
    switch (this) {
      case MembershipTier.basic:   return Icons.card_membership_outlined;
      case MembershipTier.premium: return Icons.workspace_premium_outlined;
      case MembershipTier.vip:     return Icons.diamond_outlined;
    }
  }

  /// Ordem para exibição de planos (crescente).
  int get sortOrder {
    switch (this) {
      case MembershipTier.basic:   return 0;
      case MembershipTier.premium: return 1;
      case MembershipTier.vip:     return 2;
    }
  }
}

/// Plano de assinatura de uma barbearia.
/// Entidade pura de domínio — sem dependências de framework.
class MembershipPlanEntity {
  final String id;
  final String barbershopId;
  final MembershipTier tier;
  final String name;

  /// Preço da cobrança mensal em BRL.
  final double priceMonthly;

  /// Lista de benefícios descritos textualmente para exibição ao cliente.
  final List<String> benefits;

  /// Número de cortes incluídos por mês. null = ilimitado.
  final int? cutsPerMonth;

  /// Se inclui serviços de barba sem custo adicional.
  final bool includesBeard;

  /// Se o assinante tem prioridade na fila de agendamento.
  final bool priorityBooking;

  /// Percentual de desconto em produtos para assinantes (0-100).
  final int productDiscountPercent;

  /// Se o plano está ativo e disponível para assinaturas.
  final bool isActive;

  const MembershipPlanEntity({
    required this.id,
    required this.barbershopId,
    required this.tier,
    required this.name,
    required this.priceMonthly,
    required this.benefits,
    this.cutsPerMonth,
    this.includesBeard = false,
    this.priorityBooking = false,
    this.productDiscountPercent = 0,
    this.isActive = true,
  });

  String get formattedPrice =>
      'R\$ ${priceMonthly.toStringAsFixed(2).replaceAll('.', ',')}';

  String get cutsLabel =>
      cutsPerMonth == null ? 'Ilimitados' : '$cutsPerMonth/mês';

  MembershipPlanEntity copyWith({
    String? id, String? barbershopId, MembershipTier? tier,
    String? name, double? priceMonthly, List<String>? benefits,
    int? cutsPerMonth, bool? includesBeard, bool? priorityBooking,
    int? productDiscountPercent, bool? isActive,
  }) =>
      MembershipPlanEntity(
        id: id ?? this.id,
        barbershopId: barbershopId ?? this.barbershopId,
        tier: tier ?? this.tier,
        name: name ?? this.name,
        priceMonthly: priceMonthly ?? this.priceMonthly,
        benefits: benefits ?? this.benefits,
        cutsPerMonth: cutsPerMonth ?? this.cutsPerMonth,
        includesBeard: includesBeard ?? this.includesBeard,
        priorityBooking: priorityBooking ?? this.priorityBooking,
        productDiscountPercent:
            productDiscountPercent ?? this.productDiscountPercent,
        isActive: isActive ?? this.isActive,
      );
}
