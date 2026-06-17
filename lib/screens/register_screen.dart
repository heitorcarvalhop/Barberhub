import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/presentation/providers/auth_providers.dart';
import '../core/routes/app_routes.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final error = await ref.read(authNotifierProvider.notifier).register(
          name: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          confirmPassword: _confirmController.text,
        );

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppTheme.error, size: 18),
              const SizedBox(width: 10),
              Text(error),
            ],
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_outline, color: AppTheme.gold, size: 18),
              SizedBox(width: 10),
              Text('Conta criada com sucesso!'),
            ],
          ),
        ),
      );
      final state = ref.read(authNotifierProvider);
      final route =
          state is AuthAuthenticated ? state.user.initialRoute : AppRoutes.home;
      Navigator.pushReplacementNamed(context, route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authNotifierProvider) is AuthLoading;

    return Scaffold(
      body: Stack(
        children: [
          // Background decorative circle
          Positioned(
            top: -60,
            left: -100,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.gold.withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Column(
                  children: [
                    // Top bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 18,
                              color: AppTheme.textSecondary,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Spacer(),
                          Text(
                            'NOVA CONTA',
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  color: AppTheme.textHint,
                                  fontSize: 11,
                                  letterSpacing: 3,
                                ),
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Crie sua\nconta.',
                                style: Theme.of(context)
                                    .textTheme
                                    .displayMedium
                                    ?.copyWith(
                                      height: 1.1,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              const GoldAccent(),
                              const SizedBox(height: 12),
                              Text(
                                'Preencha os dados abaixo para começar.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(height: 1.5),
                              ),
                              const SizedBox(height: 40),
                              AppTextField(
                                label: 'Nome completo',
                                hint: 'Seu nome',
                                controller: _nameController,
                                focusNode: _nameFocus,
                                keyboardType: TextInputType.name,
                                textInputAction: TextInputAction.next,
                                onEditingComplete: () => FocusScope.of(context)
                                    .requestFocus(_emailFocus),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Informe seu nome';
                                  }
                                  if (v.trim().length < 3) {
                                    return 'Nome muito curto';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              AppTextField(
                                label: 'E-mail',
                                hint: 'seu@email.com',
                                controller: _emailController,
                                focusNode: _emailFocus,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                onEditingComplete: () => FocusScope.of(context)
                                    .requestFocus(_passwordFocus),
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Informe o e-mail';
                                  }
                                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                      .hasMatch(v)) {
                                    return 'E-mail inválido';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              AppTextField(
                                label: 'Senha',
                                hint: 'Mínimo 6 caracteres',
                                controller: _passwordController,
                                focusNode: _passwordFocus,
                                isPassword: true,
                                textInputAction: TextInputAction.next,
                                onEditingComplete: () => FocusScope.of(context)
                                    .requestFocus(_confirmFocus),
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Crie uma senha';
                                  }
                                  if (v.length < 6) {
                                    return 'Mínimo 6 caracteres';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              AppTextField(
                                label: 'Confirmar senha',
                                hint: 'Repita a senha',
                                controller: _confirmController,
                                focusNode: _confirmFocus,
                                isPassword: true,
                                textInputAction: TextInputAction.done,
                                onEditingComplete: () => _handleRegister(),
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Confirme a senha';
                                  }
                                  if (v != _passwordController.text) {
                                    return 'As senhas não coincidem';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 36),
                              PrimaryButton(
                                label: 'Cadastrar',
                                onPressed: _handleRegister,
                                isLoading: isLoading,
                              ),
                              const SizedBox(height: 28),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Já tem uma conta? ',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontSize: 13),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                    ),
                                    child: const Text('Entrar'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
