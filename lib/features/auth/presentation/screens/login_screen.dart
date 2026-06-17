import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:barber_hub/core/theme/app_theme.dart';
import 'package:barber_hub/core/routes/app_routes.dart';
import 'package:barber_hub/shared/widgets/app_widgets.dart';
import 'package:barber_hub/features/auth/presentation/providers/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  final _passFocus = FocusNode();
  late AnimationController _anim;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..forward();
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _anim.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final error = await ref.read(authNotifierProvider.notifier).login(
          _emailCtrl.text,
          _passCtrl.text,
        );

    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppTheme.error, size: 18),
          const SizedBox(width: 10),
          Text(error),
        ]),
      ));
      return;
    }

    // Redireciona com base no role do usuário autenticado
    final state = ref.read(authNotifierProvider);
    if (state is AuthAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Row(children: [
          Icon(Icons.check_circle_outline, color: AppTheme.gold, size: 18),
          SizedBox(width: 10),
          Text('Bem-vindo de volta!'),
        ]),
      ));
      Navigator.pushReplacementNamed(context, state.user.initialRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authNotifierProvider) is AuthLoading;

    return Scaffold(
      body: Stack(children: [
        Positioned(top: -80, right: -80, child: _bgCircle(300, 0.06)),
        Positioned(bottom: -100, left: -100, child: _bgCircle(350, 0.04)),
        SafeArea(
          child: FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      const BrandHeader(
                          subtitle:
                              'Sua barbearia favorita,\nna palma da mão.'),
                      const SizedBox(height: 52),
                      Row(children: [
                        const GoldAccent(),
                        const SizedBox(width: 12),
                        Text('ACESSO',
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  color: AppTheme.textHint,
                                  fontSize: 11,
                                  letterSpacing: 3,
                                )),
                      ]),
                      const SizedBox(height: 28),
                      AppTextField(
                        label: 'E-mail',
                        hint: 'seu@email.com',
                        controller: _emailCtrl,
                        focusNode: _emailFocus,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        onEditingComplete: () =>
                            FocusScope.of(context).requestFocus(_passFocus),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Informe o e-mail';
                          if (!v.contains('@')) return 'E-mail inválido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Senha',
                        hint: '••••••••',
                        controller: _passCtrl,
                        focusNode: _passFocus,
                        isPassword: true,
                        textInputAction: TextInputAction.done,
                        onEditingComplete: _handleLogin,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Informe a senha';
                          if (v.length < 6) return 'Mínimo 6 caracteres';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.pushNamed(
                              context, AppRoutes.forgotPassword),
                          style: TextButton.styleFrom(
                              padding: EdgeInsets.zero, minimumSize: Size.zero),
                          child: Text('Esqueci minha senha',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                      color: AppTheme.gold, fontSize: 13)),
                        ),
                      ),
                      const SizedBox(height: 32),
                      PrimaryButton(
                          label: 'Entrar',
                          onPressed: _handleLogin,
                          isLoading: isLoading),
                      const SizedBox(height: 40),
                      const DividerWithText(text: 'NÃO TEM UMA CONTA'),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, AppRoutes.register),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: AppTheme.inputBorder, width: 1),
                            shape: const RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(4))),
                          ),
                          child: Text('CRIAR CONTA',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                      color: AppTheme.textPrimary,
                                      fontSize: 13)),
                        ),
                      ),
                      const SizedBox(height: 36),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _bgCircle(double size, double opacity) => Container(
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
