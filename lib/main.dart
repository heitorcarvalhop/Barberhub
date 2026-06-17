import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/app_data_provider.dart';
import 'models/cart_provider.dart';
import 'models/onboarding_provider.dart';
import 'core/routes/app_routes.dart';
import 'core/services/supabase_service.dart';

import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'features/auth/presentation/screens/register_screen.dart';
import 'features/auth/presentation/screens/forgot_password_screen.dart';
import 'features/auth/presentation/screens/reset_password_screen.dart';
import 'features/barber_shop/presentation/screens/barber_shop_shell.dart';
import 'features/barber_shop/presentation/screens/barber_shop_reviews_screen.dart';

// Membership feature
import 'features/membership/presentation/screens/client/membership_plans_screen.dart';
import 'features/membership/presentation/screens/barber_shop/membership_management_screen.dart';

import 'screens/main_shell.dart';
import 'screens/barber/barber_shell.dart';
import 'screens/admin/admin_shell.dart';
import 'screens/client/barbershop_detail_screen.dart';
import 'screens/client/service_detail_screen.dart';
import 'screens/client/booking_screen.dart';
import 'screens/client/product_detail_screen.dart';
import 'screens/client/cart_screen.dart';
import 'screens/client/review_screen.dart';
import 'screens/client/ai_assistant_screen.dart';
import 'screens/client/edit_profile_screen.dart';
import 'theme/app_theme.dart';

final _navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  await SupabaseService.initialize();

  // Redireciona para a tela de nova senha quando o usuário clica no link do email
  SupabaseService.client?.auth.onAuthStateChange.listen((data) {
    if (data.event == AuthChangeEvent.passwordRecovery) {
      _navigatorKey.currentState?.pushNamedAndRemoveUntil(
        AppRoutes.resetPassword,
        (route) => false,
      );
    }
  });

  runApp(const ProviderScope(child: BarberHubApp()));
}

class BarberHubApp extends StatelessWidget {
  const BarberHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return provider.MultiProvider(
      providers: [
        provider.ChangeNotifierProvider(create: (_) => AppDataProvider()),
        provider.ChangeNotifierProvider(create: (_) => CartProvider()),
        provider.ChangeNotifierProvider(create: (_) => OnboardingProvider()),
      ],
      child: MaterialApp(
          navigatorKey: _navigatorKey,
          title: 'Barber Hub',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          initialRoute: AppRoutes.splash,
          onGenerateRoute: (settings) {
            final routeMap = <String, WidgetBuilder>{
              AppRoutes.splash: (_) => const SplashScreen(),
              AppRoutes.login: (_) => const LoginScreen(),
              AppRoutes.register: (_) => const RegisterScreen(),
              AppRoutes.forgotPassword: (_) => const ForgotPasswordScreen(),
              AppRoutes.resetPassword: (_) => const ResetPasswordScreen(),
              AppRoutes.home: (_) => MainShell(
                    initialIndex: settings.arguments is int
                        ? settings.arguments as int
                        : 0,
                  ),
              AppRoutes.barberShopHome: (_) => const BarberShopShell(),
              AppRoutes.barberHome: (_) => const BarberShell(),
              AppRoutes.adminHome: (_) => const AdminShell(),
              AppRoutes.barbershopDetail: (_) => const BarbershopDetailScreen(),
              AppRoutes.serviceDetail: (_) => const ServiceDetailScreen(),
              AppRoutes.booking: (_) => const BookingScreen(),
              AppRoutes.productDetail: (_) => const ProductDetailScreen(),
              AppRoutes.cart: (_) => const CartScreen(),
              AppRoutes.review: (_) => const ReviewScreen(),
              AppRoutes.aiAssistant: (_) => const AiAssistantScreen(),
              AppRoutes.editProfile: (_) => const EditProfileScreen(),
              AppRoutes.membershipPlans: (_) => const MembershipPlansScreen(),
              AppRoutes.membershipManagement: (_) =>
                  const MembershipManagementScreen(),
              AppRoutes.shopReviews: (_) => const BarberShopReviewsScreen(),
            };

            final builder = routeMap[settings.name];
            if (builder == null) {
              return PageRouteBuilder(
                settings: settings,
                pageBuilder: (_, __, ___) => _NotFoundPage(
                  route: settings.name ?? 'desconhecida',
                ),
                transitionsBuilder: (_, animation, __, child) => FadeTransition(
                  opacity:
                      CurvedAnimation(parent: animation, curve: Curves.easeOut),
                  child: child,
                ),
                transitionDuration: const Duration(milliseconds: 280),
              );
            }

            return PageRouteBuilder(
              settings: settings,
              pageBuilder: (context, animation, __) => builder(context),
              transitionsBuilder: (_, animation, __, child) => FadeTransition(
                opacity:
                    CurvedAnimation(parent: animation, curve: Curves.easeOut),
                child: child,
              ),
              transitionDuration: const Duration(milliseconds: 280),
            );
          }),
    );
  }
}

class _NotFoundPage extends StatelessWidget {
  final String route;

  const _NotFoundPage({required this.route});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rota não encontrada')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Rota não encontrada: $route',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.splash,
                (route) => false,
              ),
              child: const Text('Voltar ao início'),
            ),
          ],
        ),
      ),
    );
  }
}
