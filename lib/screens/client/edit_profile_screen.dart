import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';
import 'package:barber_hub/features/auth/presentation/providers/auth_providers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nameFormKey = GlobalKey<FormState>();
  final _newEmailFormKey = GlobalKey<FormState>();
  final _emailCodeFormKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  final _newEmailController = TextEditingController();
  final _emailCodeController = TextEditingController();

  bool _isEditingEmail = false;
  bool _emailCodeSent = false;

  @override
  void initState() {
    super.initState();
    final state = ref.read(authNotifierProvider);
    final user = state is AuthAuthenticated ? state.user : null;
    _nameController = TextEditingController(text: user?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _newEmailController.dispose();
    _emailCodeController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(message)),
      ]),
    ));
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_outline, color: AppTheme.gold, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(message)),
      ]),
    ));
  }

  // ── Nome ───────────────────────────────────────────────────────────────

  Future<void> _handleSaveName() async {
    if (!_nameFormKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final error = await ref
        .read(authNotifierProvider.notifier)
        .updateProfile(name: _nameController.text.trim());

    if (!mounted) return;

    if (error != null) {
      _showError(error);
      return;
    }
    _showSuccess('Perfil atualizado com sucesso!');
  }

  // ── Troca de e-mail ───────────────────────────────────────────────────

  void _startEmailEdit() {
    setState(() => _isEditingEmail = true);
  }

  void _cancelEmailEdit() {
    setState(() {
      _isEditingEmail = false;
      _emailCodeSent = false;
      _newEmailController.clear();
      _emailCodeController.clear();
    });
  }

  Future<void> _handleSendEmailCode() async {
    if (!_newEmailFormKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final newEmail = _newEmailController.text.trim();
    final error = await ref
        .read(authNotifierProvider.notifier)
        .requestEmailChange(newEmail);

    if (!mounted) return;

    if (error != null) {
      _showError(error);
      return;
    }
    setState(() => _emailCodeSent = true);
    _showSuccess('Código enviado para $newEmail');
  }

  Future<void> _handleConfirmEmailChange() async {
    if (!_emailCodeFormKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final newEmail = _newEmailController.text.trim();
    final error =
        await ref.read(authNotifierProvider.notifier).confirmEmailChange(
              newEmail: newEmail,
              token: _emailCodeController.text.trim(),
            );

    if (!mounted) return;

    if (error != null) {
      _showError(error);
      return;
    }
    setState(() {
      _isEditingEmail = false;
      _emailCodeSent = false;
      _newEmailController.clear();
      _emailCodeController.clear();
    });
    _showSuccess('E-mail atualizado com sucesso!');
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;
    final isLoading = authState is AuthLoading;

    if (user == null) {
      return const Scaffold(
        body:
            Center(child: CircularProgressIndicator(color: Color(0xFFD4A853))),
      );
    }

    final initials =
        user.name.split(' ').take(2).map((e) => e[0].toUpperCase()).join();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar (fixo, não rola com o conteúdo) ─────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 18, color: AppTheme.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  Text(
                    'EDITAR PERFIL',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
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
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.gold.withValues(alpha: 0.15),
                          border: Border.all(color: AppTheme.gold, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            initials,
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(color: AppTheme.gold),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── Nome ───────────────────────────────────────────
                    Form(
                      key: _nameFormKey,
                      child: AppTextField(
                        label: 'Nome completo',
                        hint: 'Seu nome',
                        controller: _nameController,
                        keyboardType: TextInputType.name,
                        textInputAction: TextInputAction.done,
                        onEditingComplete: _handleSaveName,
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
                    ),
                    const SizedBox(height: 16),
                    PrimaryButton(
                      label: 'SALVAR NOME',
                      isLoading: isLoading,
                      onPressed: isLoading ? null : _handleSaveName,
                    ),

                    const SizedBox(height: 36),
                    Container(height: 1, color: AppTheme.divider),
                    const SizedBox(height: 28),

                    // ── E-mail ───────────────────────────────────────────
                    Text(
                      'E-MAIL',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                            letterSpacing: 1,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.inputBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.mail_outline_rounded,
                              size: 16, color: AppTheme.textHint),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              user.email,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                      fontSize: 15,
                                      color: AppTheme.textSecondary),
                            ),
                          ),
                          if (!_isEditingEmail)
                            TextButton(
                              onPressed: isLoading ? null : _startEmailEdit,
                              child: Text(
                                'ALTERAR',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(
                                        color: AppTheme.gold,
                                        fontSize: 11,
                                        letterSpacing: 0.5),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // ── Passo 1: novo e-mail ────────────────────────────
                    if (_isEditingEmail && !_emailCodeSent) ...[
                      const SizedBox(height: 16),
                      Form(
                        key: _newEmailFormKey,
                        child: AppTextField(
                          label: 'Novo e-mail',
                          hint: 'novo@email.com',
                          controller: _newEmailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          onEditingComplete: _handleSendEmailCode,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Informe o novo e-mail';
                            }
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                .hasMatch(v.trim())) {
                              return 'E-mail inválido';
                            }
                            if (v.trim().toLowerCase() ==
                                user.email.toLowerCase()) {
                              return 'Informe um e-mail diferente do atual';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: CustomButton(
                              label: 'CANCELAR',
                              outlined: true,
                              color: AppTheme.textSecondary,
                              onPressed: isLoading ? null : _cancelEmailEdit,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: PrimaryButton(
                              label: 'ENVIAR CÓDIGO',
                              isLoading: isLoading,
                              onPressed:
                                  isLoading ? null : _handleSendEmailCode,
                            ),
                          ),
                        ],
                      ),
                    ],

                    // ── Passo 2: confirmar com código ───────────────────
                    if (_emailCodeSent) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
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
                              'Código enviado para\n${_newEmailController.text.trim()}',
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
                      const SizedBox(height: 16),
                      Form(
                        key: _emailCodeFormKey,
                        child: AppTextField(
                          label: 'Código de confirmação',
                          hint: '000000',
                          controller: _emailCodeController,
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.done,
                          onEditingComplete: _handleConfirmEmailChange,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Informe o código';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: CustomButton(
                              label: 'CANCELAR',
                              outlined: true,
                              color: AppTheme.textSecondary,
                              onPressed: isLoading ? null : _cancelEmailEdit,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: PrimaryButton(
                              label: 'CONFIRMAR E-MAIL',
                              isLoading: isLoading,
                              onPressed:
                                  isLoading ? null : _handleConfirmEmailChange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton(
                          onPressed: isLoading
                              ? null
                              : () => setState(() {
                                    _emailCodeSent = false;
                                    _emailCodeController.clear();
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
          ],
        ),
      ),
    );
  }
}
