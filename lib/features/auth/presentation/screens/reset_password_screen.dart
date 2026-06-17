import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:barber_hub/core/theme/app_theme.dart';
import 'package:barber_hub/core/routes/app_routes.dart';
import 'package:barber_hub/shared/widgets/app_widgets.dart';
import 'package:barber_hub/features/auth/presentation/providers/auth_providers.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  late AnimationController _anim;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _anim.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final error = await ref
        .read(authNotifierProvider.notifier)
        .updatePassword(_passwordCtrl.text);

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(error)),
        ]),
      ));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Row(children: [
        Icon(Icons.check_circle_outline, color: AppTheme.gold, size: 18),
        SizedBox(width: 10),
        Text('Senha atualizada com sucesso!'),
      ]),
    ));

    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.login,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authNotifierProvider) is AuthLoading;

    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 18, color: AppTheme.textSecondary),
                  onPressed: () => Navigator.of(context)
                      .pushNamedAndRemoveUntil(AppRoutes.login, (_) => false),
                ),
              ]),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppTheme.gold.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: AppTheme.gold.withValues(alpha: 0.2)),
                        ),
                        child: const Icon(Icons.lock_rounded,
                            color: AppTheme.gold, size: 28),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'Nova\nsenha.',
                        style: Theme.of(context)
                            .textTheme
                            .displayMedium
                            ?.copyWith(height: 1.1),
                      ),
                      const SizedBox(height: 8),
                      const GoldAccent(),
                      const SizedBox(height: 16),
                      Text(
                        'Escolha uma senha forte. Após salvar você precisará dela para entrar no app.',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(height: 1.6),
                      ),
                      const SizedBox(height: 40),
                      AppTextField(
                        label: 'Nova senha',
                        hint: 'Mínimo 6 caracteres',
                        controller: _passwordCtrl,
                        isPassword: true,
                        textInputAction: TextInputAction.next,
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Informe a senha';
                          }
                          if (v.length < 6) {
                            return 'Mínimo 6 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Confirmar nova senha',
                        hint: 'Repita a senha',
                        controller: _confirmCtrl,
                        isPassword: true,
                        textInputAction: TextInputAction.done,
                        onEditingComplete: _handleSave,
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Confirme a senha';
                          }
                          if (v != _passwordCtrl.text) {
                            return 'As senhas não coincidem';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 36),
                      PrimaryButton(
                        label: 'Salvar nova senha',
                        onPressed: _handleSave,
                        isLoading: isLoading,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
