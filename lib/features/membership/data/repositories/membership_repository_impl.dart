import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:barber_hub/core/errors/failures.dart';
import 'package:barber_hub/features/membership/data/datasources/membership_supabase_datasource.dart';
import 'package:barber_hub/features/membership/domain/entities/membership_entity.dart';
import 'package:barber_hub/features/membership/domain/entities/membership_plan_entity.dart';
import 'package:barber_hub/features/membership/domain/repositories/i_membership_repository.dart';

class MembershipRepositoryImpl implements IMembershipRepository {
  final MembershipSupabaseDatasource _datasource;
  const MembershipRepositoryImpl(this._datasource);

  @override
  Future<(List<MembershipPlanEntity>, Failure?)> getPlansForShop(
      String shopId) async {
    try {
      final plans = await _datasource.getPlansForShop(shopId);
      return (plans, null);
    } catch (e) {
      return (const <MembershipPlanEntity>[], const UnknownFailure('Erro ao carregar planos.'));
    }
  }

  @override
  Future<(MembershipPlanEntity?, Failure?)> createPlan(
      MembershipPlanEntity plan) async {
    try {
      final created = await _datasource.createPlan(plan);
      return (created, null);
    } catch (e) {
      if (e is PostgrestException && e.code == '23505') {
        return (
          null,
          ValidationFailure(
              'Já existe um plano "${plan.tier.name}" para esta barbearia. Edite-o ou exclua-o antes de criar outro do mesmo tier.'),
        );
      }
      return (null, UnknownFailure('Erro ao criar plano: ${_describe(e)}'));
    }
  }

  @override
  Future<Failure?> updatePlan(MembershipPlanEntity plan) async {
    try {
      await _datasource.updatePlan(plan);
      return null;
    } catch (e) {
      return UnknownFailure('Erro ao atualizar plano: ${_describe(e)}');
    }
  }

  @override
  Future<Failure?> deletePlan(String planId) async {
    try {
      await _datasource.deletePlan(planId);
      return null;
    } catch (e) {
      return UnknownFailure('Erro ao excluir plano: ${_describe(e)}');
    }
  }

  String _describe(Object e) => e is StateError ? e.message : e.toString();

  @override
  Future<(List<MembershipEntity>, Failure?)> getClientMemberships(
      String clientId) async {
    try {
      final memberships = await _datasource.getClientMemberships(clientId);
      return (memberships, null);
    } catch (e) {
      return (const <MembershipEntity>[], const UnknownFailure('Erro ao carregar assinaturas.'));
    }
  }

  @override
  Future<(List<MembershipEntity>, Failure?)> getShopMemberships(
      String shopId) async {
    try {
      final memberships = await _datasource.getShopMemberships(shopId);
      return (memberships, null);
    } catch (e) {
      return (const <MembershipEntity>[], const UnknownFailure('Erro ao carregar assinantes.'));
    }
  }

  @override
  Future<(MembershipEntity?, Failure?)> subscribe({
    required String clientId,
    required String clientName,
    required String shopId,
    required String planId,
  }) async {
    try {
      final membership = await _datasource.subscribe(
        clientId: clientId,
        clientName: clientName,
        shopId: shopId,
        planId: planId,
      );
      return (membership, null);
    } catch (e) {
      return (null, const UnknownFailure('Erro ao realizar assinatura.'));
    }
  }

  @override
  Future<(MembershipEntity?, Failure?)> upgradeMembership({
    required String membershipId,
    required String newPlanId,
  }) async {
    try {
      final updated = await _datasource.upgradeMembership(
        membershipId: membershipId,
        newPlanId: newPlanId,
      );
      return (updated, null);
    } catch (e) {
      return (null, UnknownFailure('Erro ao atualizar plano: ${_describe(e)}'));
    }
  }

  @override
  Future<Failure?> cancelMembership(String membershipId) async {
    try {
      await _datasource.cancelMembership(membershipId);
      return null;
    } catch (e) {
      return UnknownFailure('Erro ao cancelar assinatura: ${_describe(e)}');
    }
  }

  @override
  Future<Failure?> pauseMembership(String membershipId) async {
    try {
      await _datasource.pauseMembership(membershipId);
      return null;
    } catch (e) {
      return UnknownFailure('Erro ao pausar assinatura: ${_describe(e)}');
    }
  }

  @override
  Future<Failure?> resumeMembership(String membershipId) async {
    try {
      await _datasource.resumeMembership(membershipId);
      return null;
    } catch (e) {
      return UnknownFailure('Erro ao reativar assinatura: ${_describe(e)}');
    }
  }

  @override
  Future<(MembershipEntity?, Failure?)> useCut(String membershipId) async {
    try {
      final updated = await _datasource.useCut(membershipId);
      return (updated, null);
    } catch (e) {
      return (null, const UnknownFailure('Erro ao registrar uso.'));
    }
  }
}
