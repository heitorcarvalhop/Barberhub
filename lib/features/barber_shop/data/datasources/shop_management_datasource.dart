import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:barber_hub/features/barber_shop/domain/entities/shop_settings_entity.dart';
import 'package:barber_hub/features/barber_shop/domain/entities/blocked_date_entity.dart';
import 'package:barber_hub/features/client/data/models/barber_model.dart';
import 'package:barber_hub/features/client/data/models/product_model.dart';
import 'package:barber_hub/data/supabase_blocked_dates_datasource.dart';

/// Datasource local para gestão de barbearia.
/// Persiste dados via SharedPreferences (chaves prefixadas por shopId).
/// Projetado para ser substituído por datasource HTTP sem alterar a camada de domínio.
class ShopManagementDatasource {
  final _blockedRemote = SupabaseBlockedDatesDatasource();

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  String _settingsKey(String id) => 'bh_settings_$id';
  String _barbersKey(String id) => 'bh_barbers_$id';
  String _productsKey(String id) => 'bh_products_$id';
  String _blockedDatesKey(String id) => 'bh_blocked_$id';

  // ── Settings ──────────────────────────────────────────────────────────────

  Future<ShopSettingsEntity?> loadSettings(String shopId) async {
    final p = await _prefs;
    final raw = p.getString(_settingsKey(shopId));
    if (raw == null) return null;
    try {
      return ShopSettingsEntity.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map));
    } catch (_) {
      return null;
    }
  }

  Future<void> saveSettings(ShopSettingsEntity s) async {
    final p = await _prefs;
    await p.setString(_settingsKey(s.shopId), jsonEncode(s.toJson()));
  }

  // ── Barbers ───────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>?> loadBarbers(String shopId) async {
    final p = await _prefs;
    final raw = p.getString(_barbersKey(shopId));
    if (raw == null) return null;
    try {
      return List<Map<String, dynamic>>.from((jsonDecode(raw) as List)
          .map((e) => Map<String, dynamic>.from(e as Map)));
    } catch (_) {
      return null;
    }
  }

  Future<void> saveBarbers(String shopId, List<BarberModel> barbers) async {
    final p = await _prefs;
    await p.setString(
        _barbersKey(shopId),
        jsonEncode(barbers
            .map((b) => {
                  'id': b.id,
                  'name': b.name,
                  'specialty': b.specialty,
                  'rating': b.rating,
                  'reviewCount': b.reviewCount,
                  'avatarInitials': b.avatarInitials,
                  'phone': b.phone,
                  'isActive': b.isActive,
                })
            .toList()));
  }

  // ── Products ──────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>?> loadProducts(String shopId) async {
    final p = await _prefs;
    final raw = p.getString(_productsKey(shopId));
    if (raw == null) return null;
    try {
      return List<Map<String, dynamic>>.from((jsonDecode(raw) as List)
          .map((e) => Map<String, dynamic>.from(e as Map)));
    } catch (_) {
      return null;
    }
  }

  Future<void> saveProducts(String shopId, List<ProductModel> products) async {
    final p = await _prefs;
    await p.setString(
        _productsKey(shopId),
        jsonEncode(products
            .map((pr) => {
                  'id': pr.id,
                  'barbershopId': pr.barbershopId,
                  'name': pr.name,
                  'description': pr.description,
                  'price': pr.price,
                  'originalPrice': pr.originalPrice,
                  'category': pr.category.name,
                  'imageEmoji': pr.imageEmoji,
                  'brand': pr.brand,
                  'isFeatured': pr.isFeatured,
                  'stockQty': pr.stockQty,
                })
            .toList()));
  }

  // ── Blocked Dates ─────────────────────────────────────────────────────────

  Future<List<BlockedDateEntity>> loadBlockedDates(String shopId) async {
    if (_blockedRemote.isConfigured) {
      return _blockedRemote.loadBlockedDates(shopId);
    }

    final p = await _prefs;
    final raw = p.getString(_blockedDatesKey(shopId));
    if (raw == null) return [];
    try {
      return List<Map<String, dynamic>>.from((jsonDecode(raw) as List)
              .map((e) => Map<String, dynamic>.from(e as Map)))
          .map(BlockedDateEntity.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveBlockedDates(
      String shopId, List<BlockedDateEntity> blocks) async {
    if (_blockedRemote.isConfigured) {
      await _blockedRemote.replaceBlockedDates(shopId, blocks);
      return;
    }

    final p = await _prefs;
    await p.setString(_blockedDatesKey(shopId),
        jsonEncode(blocks.map((b) => b.toJson()).toList()));
  }
}
