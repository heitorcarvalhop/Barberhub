import 'package:barber_hub/core/errors/failures.dart';
import 'package:barber_hub/features/membership/domain/entities/membership_entity.dart';
import 'package:barber_hub/features/membership/domain/entities/membership_plan_entity.dart';

/// Contrato do repositório de assinaturas.
/// Implementado na camada data — aqui apenas a interface de domínio.
abstract interface class IMembershipRepository {
  // ── Planos ────────────────────────────────────────────────────────────────

  /// Retorna os planos disponíveis de uma barbearia.
  Future<(List<MembershipPlanEntity>, Failure?)> getPlansForShop(String shopId);

  /// Cria um novo plano para a barbearia (proprietário).
  Future<(MembershipPlanEntity?, Failure?)> createPlan(MembershipPlanEntity plan);

  /// Atualiza configurações de um plano (proprietário).
  Future<Failure?> updatePlan(MembershipPlanEntity plan);

  /// Exclui um plano (proprietário).
  Future<Failure?> deletePlan(String planId);

  // ── Assinaturas ───────────────────────────────────────────────────────────

  /// Retorna todas as assinaturas de um cliente.
  Future<(List<MembershipEntity>, Failure?)> getClientMemberships(String clientId);

  /// Retorna todos os assinantes de uma barbearia.
  Future<(List<MembershipEntity>, Failure?)> getShopMemberships(String shopId);

  /// Inscreve um cliente em um plano.
  Future<(MembershipEntity?, Failure?)> subscribe({
    required String clientId,
    required String clientName,
    required String shopId,
    required String planId,
  });

  /// Faz upgrade/troca de plano de uma assinatura existente.
  Future<(MembershipEntity?, Failure?)> upgradeMembership({
    required String membershipId,
    required String newPlanId,
  });

  /// Cancela uma assinatura.
  Future<Failure?> cancelMembership(String membershipId);

  /// Pausa uma assinatura (suspende cobrança temporariamente).
  Future<Failure?> pauseMembership(String membershipId);

  /// Reativa uma assinatura pausada.
  Future<Failure?> resumeMembership(String membershipId);

  /// Registra o uso de um corte incluído no plano.
  Future<(MembershipEntity?, Failure?)> useCut(String membershipId);
}
