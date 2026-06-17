import 'package:flutter/foundation.dart';
import 'package:barber_hub/core/services/cache_service.dart';
import 'package:barber_hub/features/auth/data/models/user_model.dart';

/// Datasource local: persiste sessão e usuários registrados.
///
/// MELHORIA #9: delegação completa para [CacheService].
///
/// Antes (ZIP 3): este datasource gerenciava seu próprio acesso ao
/// SharedPreferences com _cachedPrefs, duplicando a lógica já existente
/// no CacheService (mesmas chaves, mesmo padrão lazy-init, mesma
/// serialização JSON). Dois escritores independentes para as mesmas
/// chaves era uma condição de corrida latente.
///
/// Agora: toda a persistência passa pelo CacheService singleton.
/// Este datasource responsabiliza-se apenas pela camada de domínio:
/// serializar/deserializar [UserModel] ↔ Map<String, dynamic>.
class AuthLocalDatasource {
  // Alias de conveniência — evita repetir CacheService.instance em cada linha.
  CacheService get _cache => CacheService.instance;

  // ── Sessão ────────────────────────────────────────────────────────────────

  Future<void> saveSession(UserModel user) async {
    await _cache.saveSession(user.toJson());
  }

  Future<UserModel?> loadSession() async {
    final map = await _cache.loadSession();
    if (map == null) return null;
    try {
      return UserModel.fromJson(map);
    } catch (e, st) {
      // CacheService já limpa a chave corrompida no catch interno.
      // Aqui apenas logamos para facilitar debug.
      if (kDebugMode) {
        debugPrint(
            '[AuthLocalDatasource.loadSession] Deserialização falhou: $e');
        debugPrint(st.toString());
      }
      await _cache.clearSession();
      return null;
    }
  }

  Future<void> clearSession() async {
    await _cache.clearSession();
  }

  // ── Usuários registrados ──────────────────────────────────────────────────

  Future<void> saveRegisteredUser(Map<String, dynamic> userJson) async {
    await _cache.upsertRegisteredUser(userJson);
  }

  Future<List<Map<String, dynamic>>> loadRegisteredUsers() async {
    return _cache.loadRegisteredUsers();
  }
}
