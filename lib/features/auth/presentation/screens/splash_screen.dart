import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:barber_hub/core/theme/app_theme.dart';
import 'package:barber_hub/core/utils/app_icons.dart';
import 'package:barber_hub/features/auth/presentation/providers/auth_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))
      ..forward();
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _boot() async {
    final route = await ref.read(authNotifierProvider.notifier).tryAutoLogin();
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(children: [
        Positioned(top: -120, right: -120, child: _circle(400, 0.07)),
        Positioned(bottom: -80, left: -80, child: _circle(300, 0.04)),
        Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.gold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppTheme.gold.withValues(alpha: 0.3),
                        width: 1.5),
                  ),
                  child: const Center(
                    child: Icon(LucideIcons.scissors,
                        color: AppTheme.gold, size: 36),
                  ),
                ),
                const SizedBox(height: 24),
                Text('BARBER HUB',
                    style: GoogleFonts.jost(
                      color: AppTheme.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 5,
                      decoration: TextDecoration.none,
                    )),
                const SizedBox(height: 8),
                Text('Seu estilo, na palma da mão.',
                    style: GoogleFonts.jost(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      decoration: TextDecoration.none,
                    )),
                const SizedBox(height: 64),
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.gold.withValues(alpha: 0.7)),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _circle(double size, double opacity) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [
            AppTheme.gold.withValues(alpha: opacity),
            Colors.transparent
          ]),
        ),
      );
}
