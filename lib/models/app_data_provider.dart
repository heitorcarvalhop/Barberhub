import 'package:flutter/foundation.dart';
import 'service_model.dart';
import 'barber_model.dart';
import 'appointment_model.dart';
import '../mock/mock_data.dart';
import '../data/supabase_appointment_datasource.dart';
import '../data/supabase_catalog_datasource.dart';
import '../data/supabase_blocked_dates_datasource.dart';
import '../data/supabase_review_datasource.dart';
import '../features/barber_shop/domain/entities/blocked_date_entity.dart';

class AppDataProvider extends ChangeNotifier {
  final _appointmentDatasource = SupabaseAppointmentDatasource();
  final _blockedDatesDatasource = SupabaseBlockedDatesDatasource();
  final _catalogDatasource = SupabaseCatalogDatasource();
  final _reviewDatasource = SupabaseReviewDatasource();
  late List<BarbershopModel> _barbershops;
  late List<ServiceModel> _services;
  late List<BarberModel> _barbers;
  late List<AppointmentModel> _appointments;
  late List<ReviewModel> _reviews;
  List<BlockedDateEntity> _blockedDates = [];
  BarbershopModel? _selectedBarbershop;
  bool _isLoading = false;

  AppDataProvider() {
    _barbershops = MockData.barbershops();
    _services = MockData.services();
    _barbers = MockData.barbers();
    _appointments = MockData.seedAppointments(_barbershops);
    _reviews = MockData.seedReviews(_appointments);
    _loadCatalogFromSupabase();
  }

  Future<void> refreshCatalog() => _loadCatalogFromSupabase();

  Future<void> _loadCatalogFromSupabase() async {
    final datasource = _catalogDatasource;
    if (!datasource.isConfigured) return;

    try {
      _isLoading = true;
      notifyListeners();

      final remoteShops = await datasource.loadBarbershops();
      if (remoteShops.isNotEmpty) {
        _barbershops = remoteShops;
        _services = remoteShops.expand((shop) => shop.services).toList();
        _barbers = remoteShops.expand((shop) => shop.barbers).toList();
        _appointments =
            await _appointmentDatasource.loadAppointments(_barbershops);
        _reviews = _reviewDatasource.isConfigured
            ? await _reviewDatasource.loadReviews()
            : MockData.seedReviews(_appointments);
        for (final review in _reviews) {
          final apptIdx =
              _appointments.indexWhere((a) => a.id == review.appointmentId);
          if (apptIdx != -1) _appointments[apptIdx].review = review;
        }
        _blockedDates = await _blockedDatesDatasource.loadBlockedDates();

        if (_selectedBarbershop != null) {
          _selectedBarbershop = _barbershops
              .where((shop) => shop.id == _selectedBarbershop!.id)
              .firstOrNull;
        }
      }
    } catch (error) {
      debugPrint('[AppDataProvider] Falha ao carregar catalogo Supabase: $error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ Getters gerais ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬
  List<BarbershopModel> get barbershops => List.unmodifiable(_barbershops);
  BarbershopModel? get selectedBarbershop => _selectedBarbershop;
  bool get isBarbershopSelected => _selectedBarbershop != null;
  bool get isLoading => _isLoading;

  List<ServiceModel> get services {
    final src = _selectedBarbershop?.services ?? _services;
    return List.unmodifiable(src.where((s) => s.isActive));
  }

  List<ServiceModel> get allServices {
    final src = _selectedBarbershop?.services ?? _services;
    return List.unmodifiable(src);
  }

  List<BarberModel> get barbers {
    final src = _selectedBarbershop?.barbers ?? _barbers;
    return List.unmodifiable(src.where((b) => b.isActive));
  }

  List<BarberModel> get allBarbers {
    final src = _selectedBarbershop?.barbers ?? _barbers;
    return List.unmodifiable(src);
  }

  List<AppointmentModel> get appointments => List.unmodifiable(_appointments);
  List<BlockedDateEntity> get blockedDates => List.unmodifiable(_blockedDates);

  bool isDateBlockedForShop(String shopId, DateTime date) {
    return _blockedDates
        .any((block) => block.shopId == shopId && block.blocks(date));
  }

  Future<void> refreshBlockedDates() async {
    if (!_blockedDatesDatasource.isConfigured) return;
    _blockedDates = await _blockedDatesDatasource.loadBlockedDates();
    notifyListeners();
  }
  // ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ Reviews ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬

  List<ReviewModel> get allReviews => List.unmodifiable(_reviews);

  /// AvaliaÃÆ’Æâ€™Ãâ€šÃ‚§ÃÆ’Æâ€™Ãâ€šÃ‚Âµes de uma barbearia, da mais recente para a mais antiga.
  List<ReviewModel> reviewsForShop(String shopId) =>
      _reviews.where((r) => r.barbershopId == shopId).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  /// AvaliaÃÆ’Æâ€™Ãâ€šÃ‚§ÃÆ’Æâ€™Ãâ€šÃ‚Âµes de um barbeiro especÃÆ’Æâ€™Ãâ€šÃ‚Â­fico.
  List<ReviewModel> reviewsForBarber(String barberId) =>
      _reviews.where((r) => r.barberId == barberId).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  /// AvaliaÃÆ’Æâ€™Ãâ€šÃ‚§ÃÆ’Æâ€™Ãâ€šÃ‚Âµes feitas por um cliente.
  List<ReviewModel> reviewsByClient(String clientId) =>
      _reviews.where((r) => r.clientId == clientId).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  /// MÃÆ’Æâ€™Ãâ€šÃ‚Â©dia de rating de uma barbearia calculada a partir das avaliaÃÆ’Æâ€™Ãâ€šÃ‚§ÃÆ’Æâ€™Ãâ€šÃ‚Âµes reais.
  double ratingForShop(String shopId) {
    final reviews = reviewsForShop(shopId);
    if (reviews.isEmpty) return 0.0;
    final sum = reviews.fold(0, (s, r) => s + r.barbershopRating);
    return sum / reviews.length;
  }

  /// MÃÆ’Æâ€™Ãâ€šÃ‚Â©dia de rating de um barbeiro.
  double ratingForBarber(String barberId) {
    final reviews = reviewsForBarber(barberId);
    if (reviews.isEmpty) return 0.0;
    final sum = reviews.fold(0, (s, r) => s + r.barberRating);
    return sum / reviews.length;
  }

  /// DistribuiÃÆ’Æâ€™Ãâ€šÃ‚§ÃÆ’Æâ€™Ãâ€šÃ‚£o de notas (1ÃÆ’Ã‚Â¢ÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÂ¢ââ€šÂ¬Ã…â€œ5) de uma barbearia.
  Map<int, int> ratingDistributionForShop(String shopId) {
    final dist = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (final r in reviewsForShop(shopId)) {
      dist[r.barbershopRating] = (dist[r.barbershopRating] ?? 0) + 1;
    }
    return dist;
  }

  /// DistribuiÃÆ’Æâ€™Ãâ€šÃ‚§ÃÆ’Æâ€™Ãâ€šÃ‚£o de notas (1ÃÆ’Ã‚Â¢ÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÂ¢ââ€šÂ¬Ã…â€œ5) de um barbeiro.
  Map<int, int> ratingDistributionForBarber(String barberId) {
    final dist = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (final r in reviewsForBarber(barberId)) {
      dist[r.barberRating] = (dist[r.barberRating] ?? 0) + 1;
    }
    return dist;
  }

  /// Submete uma nova avaliaÃÆ’Æâ€™Ãâ€šÃ‚§ÃÆ’Æâ€™Ãâ€šÃ‚£o para um agendamento concluÃÆ’Æâ€™Ãâ€šÃ‚Â­do.
  Future<ReviewModel> submitReview({
    required AppointmentModel appointment,
    required int barbershopRating,
    required int barberRating,
    String? comment,
  }) async {
    if (!appointment.canReview) {
      throw StateError(
          'Este agendamento nao pode ser avaliado (ja avaliado ou nao concluido).');
    }
    if (barbershopRating < 1 || barbershopRating > 5 ||
        barberRating < 1 || barberRating > 5) {
      throw ArgumentError('A nota deve ser entre 1 e 5.');
    }

    _isLoading = true;
    notifyListeners();

    final review = _reviewDatasource.isConfigured
        ? await _reviewDatasource.createReview(
            appointment: appointment,
            barbershopRating: barbershopRating,
            barberRating: barberRating,
            comment: comment,
          )
        : ReviewModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            appointmentId: appointment.id,
            clientId: appointment.clientId,
            clientName: appointment.clientName,
            barbershopId: appointment.barbershop.id,
            barbershopName: appointment.barbershop.name,
            barberId: appointment.barber.id,
            barberName: appointment.barber.name,
            serviceName: appointment.service.name,
            barbershopRating: barbershopRating,
            barberRating: barberRating,
            comment: comment?.trim().isEmpty == true ? null : comment?.trim(),
            createdAt: DateTime.now(),
          );

    _reviews.add(review);

    // Vincula a avaliaÃÆ’Æâ€™Ãâ€šÃ‚§ÃÆ’Æâ€™Ãâ€šÃ‚£o ao agendamento
    final apptIdx = _appointments.indexWhere((a) => a.id == appointment.id);
    if (apptIdx != -1) _appointments[apptIdx].review = review;

    // Atualiza rating em memÃÆ’Æâ€™Ãâ€šÃ‚Â³ria da barbearia
    final shopIdx =
        _barbershops.indexWhere((s) => s.id == appointment.barbershop.id);
    if (shopIdx != -1) {
      final newRating = ratingForShop(appointment.barbershop.id);
      final newCount = reviewsForShop(appointment.barbershop.id).length;
      _barbershops[shopIdx] = _barbershops[shopIdx].copyWith(
        rating: double.parse(newRating.toStringAsFixed(1)),
        reviewCount: newCount,
      );
    }

    // Atualiza rating em memÃÆ’Æâ€™Ãâ€šÃ‚Â³ria do barbeiro
    final allBarbers = _barbershops.expand((s) => s.barbers).toList()
      ..addAll(_barbers);
    for (final b in allBarbers) {
      if (b.id == appointment.barber.id) {
        final newRating = ratingForBarber(b.id);
        final newCount = reviewsForBarber(b.id).length;
        b.rating = double.parse(newRating.toStringAsFixed(1));
        b.reviewCount = newCount;
      }
    }

    _isLoading = false;
    notifyListeners();
    return review;
  }

  // ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ Produtos ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬
  List<ProductModel> get products {
    final src = _selectedBarbershop?.availableProducts ?? [];
    return List.unmodifiable(src);
  }

  List<ProductModel> get featuredProducts {
    final src = _selectedBarbershop?.featuredProducts ?? [];
    return List.unmodifiable(src);
  }

  List<ProductModel> productsFor(BarbershopModel shop) =>
      List.unmodifiable(shopFor(shop).availableProducts);

  List<ProductModel> featuredProductsFor(BarbershopModel shop) =>
      List.unmodifiable(shopFor(shop).featuredProducts);

  List<ProductModel> productsByCategory(
          BarbershopModel shop, ProductCategory cat) =>
      List.unmodifiable(shopFor(shop).productsByCategory(cat));

  List<ProductCategory> availableCategoriesFor(BarbershopModel shop) {
    final cats = shopFor(shop).availableProducts.map((p) => p.category).toSet();
    return ProductCategory.values.where((c) => cats.contains(c)).toList();
  }

  // ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ SeleÃÆ’Æâ€™Ãâ€šÃ‚§ÃÆ’Æâ€™Ãâ€šÃ‚£o de barbearia ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬
  BarbershopModel shopFor(BarbershopModel shop) => _shopById(shop.id) ?? shop;

  void selectBarbershop(BarbershopModel shop) {
    _selectedBarbershop = shopFor(shop);
    notifyListeners();
  }

  void clearSelectedBarbershop() {
    _selectedBarbershop = null;
    notifyListeners();
  }

  // ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ Queries por barbearia ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬
  List<ServiceModel> servicesFor(BarbershopModel shop) =>
      shop.services.where((s) => s.isActive).toList();

  List<BarberModel> barbersFor(BarbershopModel shop) =>
      shop.barbers.where((b) => b.isActive).toList();

  List<AppointmentModel> appointmentsForShop(String shopId) =>
      _appointments.where((a) => a.barbershop.id == shopId).toList();

  // ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ Queries de cliente ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬
  List<AppointmentModel> appointmentsForClient(String clientId) =>
      _appointments.where((a) => a.clientId == clientId).toList();

  List<AppointmentModel> activeForClient(String clientId) =>
      appointmentsForClient(clientId)
          .where((a) => a.status == AppointmentStatus.scheduled)
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));

  List<AppointmentModel> pastForClient(String clientId) =>
      appointmentsForClient(clientId)
          .where((a) => a.status != AppointmentStatus.scheduled)
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  // ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ Queries de barbeiro ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬
  List<AppointmentModel> appointmentsForBarber(String barberId) =>
      _appointments.where((a) => a.barber.id == barberId).toList()
        ..sort((a, b) => a.date.compareTo(b.date));

  List<AppointmentModel> todayForBarber(String barberId) {
    final today = DateTime.now();
    return appointmentsForBarber(barberId).where((a) {
      return a.date.year == today.year &&
          a.date.month == today.month &&
          a.date.day == today.day;
    }).toList();
  }

  // ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ Admin ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬
  List<AppointmentModel> get allAppointmentsSorted =>
      List.of(_appointments)..sort((a, b) => b.date.compareTo(a.date));

  int get totalRevenue => _appointments
      .where((a) => a.status == AppointmentStatus.completed)
      .fold(0, (sum, a) => sum + a.service.price.toInt());

  int get scheduledCount => _appointments
      .where((a) => a.status == AppointmentStatus.scheduled)
      .length;

  int get completedCount => _appointments
      .where((a) => a.status == AppointmentStatus.completed)
      .length;

  // ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ ValidaÃÆ’Æâ€™Ãâ€šÃ‚§ÃÆ’Æâ€™Ãâ€šÃ‚Âµes ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬
  bool isServiceFromShop(ServiceModel service, BarbershopModel shop) =>
      shop.services.any((s) => s.id == service.id);

  bool isBarberFromShop(BarberModel barber, BarbershopModel shop) =>
      shop.barbers.any((b) => b.id == barber.id);

  Set<String> bookedSlotsFor(String barberId, DateTime date) {
    return _appointments
        .where((a) =>
            a.barber.id == barberId &&
            a.date.year == date.year &&
            a.date.month == date.month &&
            a.date.day == date.day &&
            a.status == AppointmentStatus.scheduled)
        .map((a) => a.timeSlot)
        .toSet();
  }

  // ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ Client: Agendar ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬
  Future<AppointmentModel> bookAppointment({
    required String clientId,
    required String clientName,
    required ServiceModel service,
    required BarberModel barber,
    required BarbershopModel barbershop,
    required DateTime date,
    required String timeSlot,
    bool paidViaMembership = false,
  }) async {
    if (!isServiceFromShop(service, barbershop)) {
      throw ArgumentError(
          'O servico "${service.name}" nao pertence a barbearia "${barbershop.name}".');
    }
    if (!isBarberFromShop(barber, barbershop)) {
      throw ArgumentError(
          'O barbeiro "${barber.name}" nao pertence a barbearia "${barbershop.name}".');
    }

    _isLoading = true;
    notifyListeners();

    try {
      final appt = _appointmentDatasource.isConfigured
          ? await _appointmentDatasource.createAppointment(
              clientId: clientId,
              clientName: clientName,
              service: service,
              barber: barber,
              barbershop: barbershop,
              date: date,
              timeSlot: timeSlot,
              paidViaMembership: paidViaMembership,
            )
          : AppointmentModel(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              clientId: clientId,
              clientName: clientName,
              service: service,
              barber: barber,
              barbershop: barbershop,
              date: date,
              timeSlot: timeSlot,
              paidViaMembership: paidViaMembership,
            );

      _appointments.add(appt);
      return appt;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cancelAppointment(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_appointmentDatasource.isConfigured) {
        await _appointmentDatasource.updateStatus(
          id,
          AppointmentStatus.cancelled,
        );
      }
      final idx = _appointments.indexWhere((a) => a.id == id);
      if (idx != -1) _appointments[idx].status = AppointmentStatus.cancelled;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<AppointmentModel?> rescheduleAppointment({
    required String id,
    required DateTime newDate,
    required String newTimeSlot,
    required BarberModel newBarber,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final idx = _appointments.indexWhere((a) => a.id == id);
      if (idx == -1) return null;

      final old = _appointments[idx];
      if (!isBarberFromShop(newBarber, old.barbershop)) {
        throw ArgumentError(
            'O barbeiro "${newBarber.name}" nao pertence a barbearia "${old.barbershop.name}".');
      }

      final newAppt = _appointmentDatasource.isConfigured
          ? await _appointmentDatasource.rescheduleAppointment(
              old: old,
              newDate: newDate,
              newTimeSlot: newTimeSlot,
              newBarber: newBarber,
            )
          : AppointmentModel(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              clientId: old.clientId,
              clientName: old.clientName,
              service: old.service,
              barber: newBarber,
              barbershop: old.barbershop,
              date: newDate,
              timeSlot: newTimeSlot,
            );

      old.status = AppointmentStatus.cancelled;
      _appointments.add(newAppt);
      return newAppt;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateAppointmentStatus(
      String id, AppointmentStatus status) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_appointmentDatasource.isConfigured) {
        await _appointmentDatasource.updateStatus(id, status);
      }
      final idx = _appointments.indexWhere((a) => a.id == id);
      if (idx != -1) _appointments[idx].status = status;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ Admin: Service CRUD ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬
  Future<void> addService(String shopId, ServiceModel service) =>
      addShopService(shopId, service);

  Future<void> updateService(String shopId, ServiceModel updated) =>
      updateShopService(shopId, updated);

  Future<void> deleteService(String shopId, String serviceId) =>
      deleteShopService(shopId, serviceId);

  // ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ Admin: Barber CRUD ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬
  Future<void> addBarber(String shopId, BarberModel barber) =>
      addShopBarber(shopId, barber);

  Future<void> updateBarber(String shopId, BarberModel updated) =>
      updateShopBarber(shopId, updated);

  Future<void> deleteBarber(String shopId, String barberId) =>
      deleteShopBarber(shopId, barberId);

  /// Cria uma nova barbearia (admin) e persiste no Supabase, junto com o
  /// login de acesso (role barberShop) do proprietário.
  Future<void> addBarbershop({
    required String name,
    required String address,
    required String phone,
    required String ownerEmail,
    required String ownerPassword,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final shop = _catalogDatasource.isConfigured
          ? await _catalogDatasource.createBarbershop(
              name: name,
              address: address,
              phone: phone,
            )
          : BarbershopModel(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: name,
              address: address,
              rating: 0,
              reviewCount: 0,
              coverEmoji: 'scissors',
              phone: phone,
              services: [],
              barbers: [],
              products: [],
              isOpen: true,
            );
      _barbershops.add(shop);

      if (_catalogDatasource.isConfigured) {
        await _catalogDatasource.createBarbershopOwnerLogin(
          barbershopId: shop.id,
          name: name,
          email: ownerEmail,
          password: ownerPassword,
        );
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ Barbearia: serviÃÆ’Æâ€™Ãâ€šÃ‚§os por shop (usados pelo BarberShopServicesScreen) ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬ÃÆ’Ã‚Â¢ÃÂ¢ââ€šÂ¬Ã‚ÂÃÂ¢ââ‚¬Å¡Ã‚Â¬
  // Distintos dos mÃÆ’Æâ€™Ãâ€šÃ‚Â©todos de admin acima (operam em _services global).
  // Estes operam na lista services de cada BarbershopModel individualmente.

  List<ServiceModel> servicesForShop(String shopId) {
    final shop = _shopById(shopId);
    return shop?.services ?? [];
  }

  List<BarberModel> barbersForShop(String shopId) {
    final shop = _shopById(shopId);
    return shop?.barbers ?? [];
  }

  Future<void> addShopBarber(String shopId, BarberModel barber) async {
    final shop = _shopById(shopId);
    if (shop == null) {
      throw StateError('Barbearia não encontrada (id: $shopId).');
    }

    final saved = _catalogDatasource.isConfigured
        ? await _catalogDatasource.createBarber(
            barbershopId: _remoteShopId(shopId),
            barber: barber,
          )
        : barber;

    shop.barbers.add(saved);
    notifyListeners();
  }

  Future<void> updateShopBarber(String shopId, BarberModel updated) async {
    final shop = _shopById(shopId);
    if (shop == null) return;
    final idx = shop.barbers.indexWhere((b) => b.id == updated.id);
    if (idx == -1) return;

    final saved = _catalogDatasource.isConfigured
        ? await _catalogDatasource.updateBarber(
            barberId: updated.id,
            barber: updated,
          )
        : updated;

    shop.barbers[idx] = saved;
    notifyListeners();
  }

  Future<void> deleteShopBarber(String shopId, String barberId) async {
    final shop = _shopById(shopId);
    if (shop == null) return;

    if (_catalogDatasource.isConfigured) {
      await _catalogDatasource.deactivateBarber(barberId);
    }

    final idx = shop.barbers.indexWhere((b) => b.id == barberId);
    if (idx != -1) shop.barbers[idx].isActive = false;
    notifyListeners();
  }

  Future<void> addShopService(String shopId, ServiceModel service) async {
    final shop = _shopById(shopId);
    if (shop == null) {
      throw StateError('Barbearia não encontrada (id: $shopId).');
    }

    final saved = _catalogDatasource.isConfigured
        ? await _catalogDatasource.createService(
            barbershopId: _remoteShopId(shopId),
            service: service,
          )
        : service;

    shop.services.add(saved);
    notifyListeners();
  }

  Future<void> updateShopService(String shopId, ServiceModel updated) async {
    final shop = _shopById(shopId);
    if (shop == null) return;
    final idx = shop.services.indexWhere((s) => s.id == updated.id);
    if (idx == -1) return;

    final saved = _catalogDatasource.isConfigured
        ? await _catalogDatasource.updateService(
            serviceId: updated.id,
            service: updated,
          )
        : updated;

    shop.services[idx] = saved;
    notifyListeners();
  }

  Future<void> deleteShopService(String shopId, String serviceId) async {
    final shop = _shopById(shopId);
    if (shop == null) return;

    if (_catalogDatasource.isConfigured) {
      await _catalogDatasource.deactivateService(serviceId);
    }

    shop.services.removeWhere((s) => s.id == serviceId);
    notifyListeners();
  }

  Future<void> toggleShopServiceActive(String shopId, String serviceId) async {
    final shop = _shopById(shopId);
    if (shop == null) return;
    final idx = shop.services.indexWhere((s) => s.id == serviceId);
    if (idx == -1) return;

    final updated = shop.services[idx].copyWith(
      isActive: !shop.services[idx].isActive,
    );
    final saved = _catalogDatasource.isConfigured
        ? await _catalogDatasource.updateService(
            serviceId: updated.id,
            service: updated,
          )
        : updated;

    shop.services[idx] = saved;
    notifyListeners();
  }

  BarbershopModel? _shopById(String shopId) {
    final exact = _barbershops.where((s) => s.id == shopId).firstOrNull;
    if (exact != null) return exact;

    final legacyId = _legacyShopId(shopId);
    return _barbershops.where((s) => s.id == legacyId).firstOrNull;
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
