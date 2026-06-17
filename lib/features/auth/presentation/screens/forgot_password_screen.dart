import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:barber_hub/core/theme/app_theme.dart';
import 'package:barber_hub/core/routes/app_routes.dart';
import 'package:barber_hub/shared/widgets/app_widgets.dart';
import 'package:barber_hub/features/auth/presentation/providers/auth_providers.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _emailFormKey = GlobalKey<FormState>();
  final _codeFormKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  bool _codeSent = false;
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
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSendCode() async {
    if (!_emailFormKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await ref
        .read(authNotifierProvider.notifier)
        .sendPasswordReset(_emailCtrl.text.trim());
    if (!mounted) return;
    setState(() => _codeSent = true);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.mark_email_read_outlined,
            color: AppTheme.gold, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Código enviado para ${_emailCtrl.text.trim()}',
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ]),
    ));
  }

  Future<void> _handleVerifyCode() async {
    if (!_codeFormKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final error =
        await ref.read(authNotifierProvider.notifier).verifyPasswordResetCode(
              _emailCtrl.text.trim(),
              _codeCtrl.text.trim(),
            );

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

    Navigator.of(context).pushReplacementNamed(AppRoutes.resetPassword);
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
                  onPressed: () => Navigator.pop(context),
                ),
              ]),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
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
                      child: const Icon(Icons.lock_reset_rounded,
                          color: AppTheme.gold, size: 28),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Recuperar\nsenha.',
                      style: Theme.of(context)
                          .textTheme
                          .displayMedium
                          ?.copyWith(height: 1.1),
                    ),
                    const SizedBox(height: 8),
                    const GoldAccent(),
                    const SizedBox(height: 16),
                    Text(
                      _codeSent
                          ? 'Verifique seu email e insira o código de 6 dígitos recebido.'
                          : 'Informe o e-mail cadastrado e enviaremos um código de recuperação.',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(height: 1.6),
                    ),
                    const SizedBox(height: 40),

                    // ── Passo 1: email ──────────────────────────────────────
                    if (!_codeSent) ...[
                      Form(
                        key: _emailFormKey,
                        child: AppTextField(
                          label: 'E-mail',
                          hint: 'seu@email.com',
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          onEditingComplete: _handleSendCode,
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Informe o e-mail';
                            }
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
                              return 'E-mail inválido';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 32),
                      PrimaryButton(
                        label: 'Enviar código',
                        onPressed: _handleSendCode,
                        isLoading: isLoading,
                      ),
                    ],

                    // ── Passo 2: código ─────────────────────────────────────
                    if (_codeSent) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.gold.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppTheme.gold.withValues(alpha: 0.25)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.mark_email_read_outlined,
                              color: AppTheme.gold, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Código enviado para\n${_emailCtrl.text.trim()}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppTheme.textSecondary,
                                    height: 1.5,
                                  ),
                            ),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 28),
                      Form(
                        key: _codeFormKey,
                        child: AppTextField(
                          label: 'Código de recuperação',
                          hint: '000000',
                          controller: _codeCtrl,
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.done,
                          onEditingComplete: _handleVerifyCode,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Informe o código';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 32),
                      PrimaryButton(
                        label: 'Verificar código',
                        onPressed: _handleVerifyCode,
                        isLoading: isLoading,
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton(
                          onPressed: isLoading
                              ? null
                              : () => setState(() {
                                    _codeSent = false;
                                    _codeCtrl.clear();
                                  }),
                          child: Text(
                            'Não recebi o código — tentar de novo',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppTheme.textSecondary),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
