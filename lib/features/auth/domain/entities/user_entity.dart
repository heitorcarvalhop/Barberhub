import 'package:barber_hub/core/constants/user_role.dart';

/// Entidade de domínio do usuário.
/// Pura — sem dependências de framework ou infraestrutura.
class UserEntity {
  final String id;
  final String name;
  final String email;
  final UserRole role;

  /// ID vinculado: barbeiro funcionário → barber ID | barbearia → shop ID
  final String? linkedId;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.linkedId,
  });

  // ── Helpers de negócio ────────────────────────────────────────────────────

  String get roleLabel => role.label;

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  bool get isClient => role.isClient;
  bool get isBarberShop => role.isBarberShop;
  bool get isBarber => role.isBarber;
  bool get isAdmin => role.isAdmin;

  /// Rota inicial após login bem-sucedido
  String get initialRoute {
    switch (role) {
      case UserRole.client:
        return '/home';
      case UserRole.barberShop:
        return '/barber-shop-home';
      case UserRole.barber:
        return '/barber-home';
      case UserRole.admin:
        return '/admin-home';
    }
  }

  UserEntity copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    String? linkedId,
  }) =>
      UserEntity(
        id: id ?? this.id,
        name: name ?? this.name,
        email: email ?? this.email,
        role: role ?? this.role,
        linkedId: linkedId ?? this.linkedId,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is UserEntity && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
