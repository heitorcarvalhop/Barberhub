class AppRoutes {
  AppRoutes._();

  // ── Entry points ───────────────────────────────────────────────────────────
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';

  // ── Cliente ────────────────────────────────────────────────────────────────
  static const String home = '/home';
  static const String barbershopDetail = '/barbershop-detail';
  static const String serviceDetail = '/service-detail';
  static const String booking = '/booking';
  static const String productDetail = '/product-detail';
  static const String cart = '/cart';
  static const String review = '/review';
  static const String aiAssistant = '/ai-assistant';
  static const String editProfile = '/edit-profile';

  // ── Membership ────────────────────────────────────────────────────────────
  /// Planos de uma barbearia específica (requer MembershipPlansArgs).
  static const String membershipPlans = '/membership/plans';

  // ── Barbearia (proprietário) ───────────────────────────────────────────────
  static const String barberShopHome = '/barber-shop-home';
  static const String membershipManagement = '/barber-shop/memberships';
  static const String shopReviews = '/barber-shop/reviews';

  // ── Legado ────────────────────────────────────────────────────────────────
  static const String barberHome = '/barber-home';
  static const String adminHome = '/admin-home';
}
