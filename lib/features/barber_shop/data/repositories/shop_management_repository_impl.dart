import 'dart:async';
import 'dart:math';
import 'package:barber_hub/data/supabase_catalog_datasource.dart';
import 'package:barber_hub/features/barber_shop/data/datasources/shop_management_datasource.dart';
import 'package:barber_hub/features/barber_shop/domain/entities/blocked_date_entity.dart';
import 'package:barber_hub/features/barber_shop/domain/entities/shop_settings_entity.dart';
import 'package:barber_hub/features/barber_shop/domain/entities/working_hours_entity.dart';
import 'package:barber_hub/features/barber_shop/domain/repositories/i_shop_management_repository.dart';
import 'package:barber_hub/features/client/data/models/barber_model.dart';
import 'package:barber_hub/features/client/data/models/product_model.dart';
import 'package:barber_hub/shared/mock/mock_data.dart';
import 'package:barber_hub/core/services/supabase_service.dart';

class ShopManagementRepositoryImpl implements IShopManagementRepository {
  final ShopManagementDatasource _ds;
  final _catalogDatasource = SupabaseCatalogDatasource();

  ShopManagementRepositoryImpl(this._ds);

  // Settings

  @override
  Future<ShopSettingsEntity?> getSettings(String shopId) async {
    final cached = await _ds.loadSettings(shopId);
    final remoteShop = await _loadRemoteShop(shopId);

    if (remoteShop != null) {
      return ShopSettingsEntity(
        shopId: shopId,
        name: remoteShop.name as String,
        address: remoteShop.address as String,
        phone: remoteShop.phone as String? ?? '',
        workingHours: remoteShop.workingHours as Map<int, WorkingHoursEntity>,
      );
    }

    if (cached != null) return cached;

    final legacyId = _legacyShopId(shopId);
    final shop =
        MockData.barbershops().where((s) => s.id == legacyId).firstOrNull;
    if (shop == null) return null;
    return ShopSettingsEntity(
      shopId: shopId,
      name: shop.name,
      address: shop.address,
      phone: shop.phone ?? '',
      workingHours: WorkingHoursEntity.defaultSchedule(),
    );
  }

  @override
  Future<void> saveSettings(ShopSettingsEntity settings) async {
    await _saveRemoteSettings(settings);
    await _ds.saveSettings(settings);
  }

  // Barbers

  @override
  Future<List<BarberModel>> getBarbers(String shopId) async {
    final remote = await _loadRemoteBarbers(shopId);
    if (remote != null) return remote;

    final cached = await _ds.loadBarbers(shopId);
    if (cached != null) {
      return cached
          .map((m) => BarberModel(
                id: m['id'] as String,
                name: m['name'] as String,
                specialty: m['specialty'] as String,
                rating: (m['rating'] as num).toDouble(),
                reviewCount: m['reviewCount'] as int? ?? 0,
                avatarInitials: m['avatarInitials'] as String,
                phone: m['phone'] as String? ?? '',
                isActive: m['isActive'] as bool? ?? true,
              ))
          .toList();
    }
    final shop =
        MockData.barbershops().where((s) => s.id == shopId).firstOrNull;
    return shop?.barbers ?? [];
  }

  @override
  Future<void> addBarber(String shopId, BarberModel barber) async {
    final saved = await _createRemoteBarber(shopId, barber);
    if (saved != null) return;

    final list = await getBarbers(shopId);
    list.add(barber);
    await _ds.saveBarbers(shopId, list);
  }

  @override
  Future<void> updateBarber(String shopId, BarberModel barber) async {
    final saved = await _updateRemoteBarber(barber);
    if (saved != null) return;

    final list = await getBarbers(shopId);
    final idx = list.indexWhere((b) => b.id == barber.id);
    if (idx != -1) list[idx] = barber;
    await _ds.saveBarbers(shopId, list);
  }

  // Products

  @override
  Future<List<ProductModel>> getProducts(String shopId) async {
    final remote = await _loadRemoteProducts(shopId);
    if (remote != null) return remote;

    final cached = await _ds.loadProducts(shopId);
    if (cached != null) {
      return cached.map((m) {
        final catStr = m['category'] as String? ?? 'pomade';
        final cat = ProductCategory.values.firstWhere((c) => c.name == catStr,
            orElse: () => ProductCategory.pomade);
        return ProductModel(
          id: m['id'] as String,
          barbershopId: m['barbershopId'] as String,
          name: m['name'] as String,
          description: m['description'] as String,
          price: (m['price'] as num).toDouble(),
          originalPrice: m['originalPrice'] != null
              ? (m['originalPrice'] as num).toDouble()
              : null,
          category: cat,
          imageEmoji: m['imageEmoji'] as String? ?? 'package',
          brand: m['brand'] as String? ?? '',
          isFeatured: m['isFeatured'] as bool? ?? false,
          stockQty: m['stockQty'] as int? ?? 0,
        );
      }).toList();
    }
    final shop =
        MockData.barbershops().where((s) => s.id == shopId).firstOrNull;
    return shop?.products ?? [];
  }

  @override
  Future<void> addProduct(ProductModel product) async {
    final saved = await _createRemoteProduct(product);
    if (saved != null) return;

    final list = await getProducts(product.barbershopId);
    list.add(product);
    await _ds.saveProducts(product.barbershopId, list);
  }

  @override
  Future<void> updateProduct(ProductModel product) async {
    final saved = await _updateRemoteProduct(product);
    if (saved != null) return;

    final list = await getProducts(product.barbershopId);
    final idx = list.indexWhere((p) => p.id == product.id);
    if (idx != -1) list[idx] = product;
    await _ds.saveProducts(product.barbershopId, list);
  }

  @override
  Future<void> deleteProduct(String shopId, String productId) async {
    final deleted = await _deactivateRemoteProduct(productId);
    if (deleted) return;

    final list = await getProducts(shopId);
    list.removeWhere((p) => p.id == productId);
    await _ds.saveProducts(shopId, list);
  }

  // Blocked Dates

  @override
  Future<List<BlockedDateEntity>> getBlockedDates(String shopId) =>
      _ds.loadBlockedDates(shopId);

  @override
  Future<void> addBlockedDate(BlockedDateEntity block) async {
    final list = await getBlockedDates(block.shopId);
    list.add(block);
    await _ds.saveBlockedDates(block.shopId, list);
  }

  @override
  Future<void> removeBlockedDate(String shopId, String blockId) async {
    final list = await getBlockedDates(shopId);
    list.removeWhere((b) => b.id == blockId);
    await _ds.saveBlockedDates(shopId, list);
  }

  Future<List<ProductModel>?> _loadRemoteProducts(String shopId) async {
    final client = SupabaseService.client;
    if (client == null) return null;

    final rows = await client
        .from('products')
        .select()
        .eq('barbershop_id', _remoteShopId(shopId))
        .eq('is_available', true)
        .order('name')
        .timeout(const Duration(seconds: 12));

    return rows
        .whereType<Map>()
        .map((row) => _productFromRow(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<ProductModel?> _createRemoteProduct(ProductModel product) async {
    final client = SupabaseService.client;
    if (client == null) return null;

    await client.from('products').insert({
      'id': product.id,
      'barbershop_id': _remoteShopId(product.barbershopId),
      'name': product.name,
      'description': product.description,
      'price': product.price,
      'original_price': product.originalPrice,
      'category': product.category.name,
      'image_emoji': product.imageEmoji,
      'brand': product.brand,
      'is_available': product.isAvailable,
      'is_featured': product.isFeatured,
      'stock': product.stockQty,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).timeout(
      const Duration(seconds: 12),
      onTimeout: () => throw TimeoutException(
        'Tempo esgotado ao salvar produto no Supabase.',
      ),
    );

    return product;
  }

  Future<ProductModel?> _updateRemoteProduct(ProductModel product) async {
    final client = SupabaseService.client;
    if (client == null) return null;

    await client
        .from('products')
        .update({
          'barbershop_id': _remoteShopId(product.barbershopId),
          'name': product.name,
          'description': product.description,
          'price': product.price,
          'original_price': product.originalPrice,
          'category': product.category.name,
          'image_emoji': product.imageEmoji,
          'brand': product.brand,
          'is_available': product.isAvailable,
          'is_featured': product.isFeatured,
          'stock': product.stockQty,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', product.id)
        .timeout(
          const Duration(seconds: 12),
          onTimeout: () => throw TimeoutException(
            'Tempo esgotado ao atualizar produto no Supabase.',
          ),
        );

    return product;
  }

  Future<bool> _deactivateRemoteProduct(String productId) async {
    final client = SupabaseService.client;
    if (client == null) return false;

    await client
        .from('products')
        .update({
          'is_available': false,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', productId)
        .timeout(
          const Duration(seconds: 12),
          onTimeout: () => throw TimeoutException(
            'Tempo esgotado ao remover produto no Supabase.',
          ),
        );

    return true;
  }

  ProductModel _productFromRow(Map<String, dynamic> row) {
    final categoryName = row['category']?.toString() ?? 'pomade';
    final category = ProductCategory.values.firstWhere(
      (item) => item.name == categoryName,
      orElse: () => ProductCategory.pomade,
    );

    return ProductModel(
      id: row['id'].toString(),
      barbershopId: row['barbershop_id'].toString(),
      name: row['name']?.toString() ?? 'Produto',
      description: row['description']?.toString() ?? '',
      price: (row['price'] as num?)?.toDouble() ?? 0,
      originalPrice: (row['original_price'] as num?)?.toDouble(),
      category: category,
      imageEmoji: row['image_emoji']?.toString() ?? category.iconKey,
      brand: row['brand']?.toString() ?? '',
      isAvailable: row['is_available'] as bool? ?? true,
      isFeatured: row['is_featured'] as bool? ?? false,
      stockQty: (row['stock'] as num?)?.toInt() ??
          (row['stock_qty'] as num?)?.toInt() ??
          0,
    );
  }

  Future<List<BarberModel>?> _loadRemoteBarbers(String shopId) async {
    final client = SupabaseService.client;
    if (client == null) return null;

    final rows = await client
        .from('barbers')
        .select()
        .eq(
          'barbershop_id',
          _remoteShopId(shopId),
        )
        .timeout(const Duration(seconds: 12));

    return rows
        .whereType<Map>()
        .map((row) => _barberFromRow(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<BarberModel?> _createRemoteBarber(
    String shopId,
    BarberModel barber,
  ) async {
    final client = SupabaseService.client;
    if (client == null) return null;

    await client.from('barbers').insert({
      'id': barber.id,
      'barbershop_id': _remoteShopId(shopId),
      'name': barber.name,
      'specialty': barber.specialty,
      'rating': barber.rating,
      'review_count': barber.reviewCount,
      'avatar_initials': barber.avatarInitials,
      'phone': barber.phone,
      'is_active': barber.isActive,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).timeout(
      const Duration(seconds: 12),
      onTimeout: () => throw TimeoutException(
        'Tempo esgotado ao salvar barbeiro no Supabase.',
      ),
    );

    return barber;
  }

  Future<BarberModel?> _updateRemoteBarber(BarberModel barber) async {
    final client = SupabaseService.client;
    if (client == null) return null;

    await client
        .from('barbers')
        .update({
          'name': barber.name,
          'specialty': barber.specialty,
          'rating': barber.rating,
          'review_count': barber.reviewCount,
          'avatar_initials': barber.avatarInitials,
          'phone': barber.phone,
          'is_active': barber.isActive,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', barber.id)
        .timeout(
          const Duration(seconds: 12),
          onTimeout: () => throw TimeoutException(
            'Tempo esgotado ao atualizar barbeiro no Supabase.',
          ),
        );

    return barber;
  }

  BarberModel _barberFromRow(Map<String, dynamic> row) {
    final name = row['name']?.toString() ?? 'Barbeiro';
    return BarberModel(
      id: row['id'].toString(),
      name: name,
      specialty: row['specialty']?.toString() ?? '',
      rating: (row['rating'] as num?)?.toDouble() ?? 5,
      reviewCount: (row['review_count'] as num?)?.toInt() ?? 0,
      avatarInitials: row['avatar_initials']?.toString().isNotEmpty == true
          ? row['avatar_initials'].toString()
          : _initials(name),
      phone: row['phone']?.toString() ?? '',
      isActive: row['is_active'] as bool? ?? true,
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isEmpty
        ? 'XX'
        : name.substring(0, min(name.length, 2)).toUpperCase();
  }

  Future<void> _saveRemoteSettings(ShopSettingsEntity settings) async {
    if (!_catalogDatasource.isConfigured) return;

    await _catalogDatasource.updateBarbershopInfo(
      id: _remoteShopId(settings.shopId),
      name: settings.name.trim(),
      address: settings.address.trim(),
      phone: settings.phone.trim(),
    );
    await _catalogDatasource.updateWorkingHours(
      id: _remoteShopId(settings.shopId),
      workingHours: settings.workingHours,
    );
  }

  Future<dynamic> _loadRemoteShop(String shopId) async {
    if (!_catalogDatasource.isConfigured) return null;
    final shops = await _catalogDatasource.loadBarbershops();

    for (final id in {shopId, _remoteShopId(shopId), _legacyShopId(shopId)}) {
      final match = shops.where((s) => s.id == id).firstOrNull;
      if (match != null) return match;
    }

    return null;
  }

  String _remoteShopId(String shopId) {
    switch (shopId) {
      case 'bs1':
        return '00000000-0000-0000-0000-000000000b01';
      case 'bs2':
        return '00000000-0000-0000-0000-000000000b02';
      case 'bs3':
        return '00000000-0000-0000-0000-000000000b03';
      default:
        return shopId;
    }
  }

  String _legacyShopId(String shopId) {
    switch (shopId) {
      case '00000000-0000-0000-0000-000000000b01':
        return 'bs1';
      case '00000000-0000-0000-0000-000000000b02':
        return 'bs2';
      case '00000000-0000-0000-0000-000000000b03':
        return 'bs3';
      default:
        return shopId;
    }
  }
}
