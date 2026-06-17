import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart';
import '../../models/app_data_provider.dart';
import '../../models/appointment_model.dart';
import '../../core/routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';
import 'package:barber_hub/features/auth/presentation/providers/auth_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final data = context.watch<AppDataProvider>();
    final user = authState is AuthAuthenticated ? authState.user : null;
    if (user == null) {
      return const Scaffold(
          body: Center(
              child: CircularProgressIndicator(color: Color(0xFFD4A853))));
    }
    final clientId = user.id;
    final initials =
        user.name.split(' ').take(2).map((e) => e[0].toUpperCase()).join();

    final allAppts = data.appointmentsForClient(clientId);
    final active = data.activeForClient(clientId);
    final past = data.pastForClient(clientId);

    // Barbearias visitadas (únicas, ordenadas pela mais recente)
    final visitedShops = <String, String>{};
    for (final a in allAppts) {
      visitedShops[a.barbershop.id] = a.barbershop.name;
    }

    // Receita total gasta
    final totalSpent = past
        .where((a) => a.status == AppointmentStatus.completed)
        .fold(0.0, (s, a) => s + a.service.price);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── Hero ──────────────────────────────────────────────────
              Stack(
                children: [
                  Container(
                    height: 170,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.gold.withValues(alpha: 0.12),
                          AppTheme.gold.withValues(alpha: 0.02),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: IconButton(
                      icon: const Icon(Icons.logout_rounded,
                          color: AppTheme.textSecondary, size: 20),
                      onPressed: () {
                        ref.read(authNotifierProvider.notifier).logout();
                        Navigator.pushReplacementNamed(
                            context, AppRoutes.login);
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 36, 24, 0),
                    child: Row(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
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
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontSize: 18),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user.email,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              RoleBadge(label: user.roleLabel),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // ── Stats ─────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Row(
                  children: [
                    _StatTile(value: '${allAppts.length}', label: 'Total'),
                    const SizedBox(width: 10),
                    _StatTile(value: '${active.length}', label: 'Ativos'),
                    const SizedBox(width: 10),
                    _StatTile(
                        value: 'R\$ ${totalSpent.toInt()}',
                        label: 'Investido',
                        gold: true),
                  ],
                ),
              ),

              // ── Barbearias visitadas ───────────────────────────────────
              if (visitedShops.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 28, 24, 14),
                  child: SectionHeader(title: 'Barbearias visitadas'),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: visitedShops.values.map((name) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceElevated,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.inputBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.storefront_outlined,
                                size: 12, color: AppTheme.gold),
                            const SizedBox(width: 6),
                            Text(
                              name,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],

              // ── Próximo agendamento ────────────────────────────────────
              if (active.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 28, 24, 14),
                  child: SectionHeader(title: 'Próximo agendamento'),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: GestureDetector(
                    onTap: () => Navigator.pushReplacementNamed(
                        context, AppRoutes.home,
                        arguments: 1),
                    child: AppointmentCard(
                      appointment: active.first,
                      showBarbershop: true,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 28),

              // ── Menu ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(title: 'Conta'),
                    const SizedBox(height: 12),
                    _MenuItem(
                        icon: Icons.person_outline_rounded,
                        label: 'Editar perfil',
                        onTap: () => Navigator.pushNamed(
                            context, AppRoutes.editProfile)),
                    const _MenuItem(
                        icon: Icons.notifications_outlined,
                        label: 'Notificações',
                        tag: 'Em breve'),
                    _MenuItem(
                        icon: Icons.lock_outline_rounded,
                        label: 'Alterar senha',
                        onTap: () => Navigator.pushNamed(
                            context, AppRoutes.forgotPassword)),
                    const SizedBox(height: 20),
                    const SectionHeader(title: 'Suporte'),
                    const SizedBox(height: 12),
                    const _MenuItem(
                        icon: Icons.help_outline_rounded,
                        label: 'Central de ajuda',
                        tag: 'Em breve'),
                    const _MenuItem(
                        icon: Icons.star_outline_rounded,
                        label: 'Avaliar o app',
                        tag: 'Em breve'),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ref.read(authNotifierProvider.notifier).logout();
                          Navigator.pushReplacementNamed(
                              context, AppRoutes.login);
                        },
                        style: OutlinedButton.styleFrom(
                          side:
                              const BorderSide(color: AppTheme.error, width: 1),
                          foregroundColor: AppTheme.error,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(4)),
                          ),
                        ),
                        icon: const Icon(Icons.logout_rounded, size: 18),
                        label: const Text('SAIR DA CONTA'),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Center(
                      child: Text(
                        'Barber Hub v2.0.0',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontSize: 11),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final bool gold;
  const _StatTile(
      {required this.value, required this.label, this.gold = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.inputBorder),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: gold ? AppTheme.gold : AppTheme.textPrimary,
                    fontSize: gold ? 18 : 24,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? tag;
  final VoidCallback? onTap;
  const _MenuItem(
      {required this.icon, required this.label, this.tag, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.inputBorder),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.textSecondary, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(fontSize: 14)),
            ),
            if (tag != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.textHint.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(tag!,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontSize: 10, color: AppTheme.textHint)),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: AppTheme.textHint),
          ],
        ),
      ),
    );
  }
}
