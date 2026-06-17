import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:barber_hub/features/membership/data/datasources/membership_supabase_datasource.dart';
import 'package:barber_hub/features/membership/data/repositories/membership_repository_impl.dart';
import 'package:barber_hub/features/membership/domain/repositories/i_membership_repository.dart';
import 'membership_notifier.dart';
import 'membership_state.dart';

// ── Infraestrutura ────────────────────────────────────────────────────────────

final _membershipDatasourceProvider = Provider<MembershipSupabaseDatasource>(
  (_) => MembershipSupabaseDatasource(),
);

final membershipRepositoryProvider = Provider<IMembershipRepository>(
  (ref) => MembershipRepositoryImpl(
    ref.read(_membershipDatasourceProvider),
  ),
);

// ── Cliente ───────────────────────────────────────────────────────────────────

final clientMembershipProvider =
    StateNotifierProvider<ClientMembershipNotifier, ClientMembershipState>(
  (ref) => ClientMembershipNotifier(ref.read(membershipRepositoryProvider)),
);

// ── Barbearia ─────────────────────────────────────────────────────────────────

final shopMembershipProvider =
    StateNotifierProvider<ShopMembershipNotifier, ShopMembershipState>(
  (ref) => ShopMembershipNotifier(ref.read(membershipRepositoryProvider)),
);
