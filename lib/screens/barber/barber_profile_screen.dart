import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart';
import '../../models/app_data_provider.dart';
import '../../models/appointment_model.dart';
import '../../core/routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';
import 'package:barber_hub/features/auth/presentation/providers/auth_providers.dart';

class BarberProfileScreen extends ConsumerWidget {
  const BarberProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final data = context.watch<AppDataProvider>();
    final user = authState is AuthAuthenticated ? authState.user : null;
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFFD4A853))),
      );
    }
    final barberId = user.linkedId ?? '';
    final barber = data.allBarbers.where((b) => b.id == barberId).firstOrNull;
    final liveRating = data.ratingForBarber(barberId);
    final liveReviewCount = data.reviewsForBarber(barberId).length;
    final appts = data.appointmentsForBarber(barberId);
    final completed =
        appts.where((a) => a.status == AppointmentStatus.completed).length;
    final revenue = appts
        .where((a) => a.status == AppointmentStatus.completed)
        .fold(0.0, (s, a) => s + a.service.price);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(children: [
            // Hero
            Container(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.gold.withValues(alpha: .1),
                    AppTheme.gold.withValues(alpha: .02)
                  ],
                ),
              ),
              child: Row(children: [
                BarberAvatar(initials: user.initials, size: 72),
                const SizedBox(width: 16),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(user.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontSize: 18)),
                      const SizedBox(height: 4),
                      if (barber != null)
                        Text(barber.specialty,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontSize: 13)),
                      const SizedBox(height: 8),
                      Row(children: [
                        RoleBadge(label: user.roleLabel.toUpperCase()),
                        if (barber != null) ...[
                          const SizedBox(width: 8),
                          StarRating(
                              rating:
                                  liveReviewCount > 0 ? liveRating : barber.rating,
                              reviewCount: liveReviewCount),
                        ],
                      ]),
                    ])),
                IconButton(
                  icon: const Icon(Icons.logout_rounded,
                      color: AppTheme.textSecondary, size: 20),
                  onPressed: () {
                    ref.read(authNotifierProvider.notifier).logout();
                    if (context.mounted) Navigator.pushReplacementNamed(context, AppRoutes.login);
                  },
                ),
              ]),
            ),

            // Stats
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(children: [
                StatCard(value: '${appts.length}', label: 'Total'),
                const SizedBox(width: 10),
                StatCard(value: '$completed', label: 'Concluídos'),
                const SizedBox(width: 10),
                StatCard(
                    value: 'R\$ ${revenue.toStringAsFixed(0)}',
                    label: 'Receita',
                    valueColor: const Color(0xFF4CAF50)),
              ]),
            ),

            const SizedBox(height: 28),

            // ── Reviews do barbeiro ─────────────────────────────────
            if (barberId.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _BarberReviewsSection(barberId: barberId),
              ),
              const SizedBox(height: 24),
            ],

            // Info section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(title: 'Informações'),
                    const SizedBox(height: 14),
                    _InfoRow(
                        icon: Icons.email_outlined,
                        label: 'E-mail',
                        value: user.email),
                    if (barber?.phone.isNotEmpty == true) ...[
                      const SizedBox(height: 10),
                      _InfoRow(
                          icon: Icons.phone_outlined,
                          label: 'Telefone',
                          value: barber!.phone),
                    ],
                    const SizedBox(height: 24),
                    const SectionHeader(title: 'Conta'),
                    const SizedBox(height: 14),
                    const _MenuItem(
                        icon: Icons.lock_outline_rounded,
                        label: 'Alterar senha'),
                    const _MenuItem(
                        icon: Icons.notifications_outlined,
                        label: 'Notificações'),
                    const SizedBox(height: 24),
                    CustomButton(
                      label: 'Sair da conta',
                      isDanger: true,
                      icon: Icons.logout_rounded,
                      onPressed: () {
                        ref.read(authNotifierProvider.notifier).logout();
                        if (context.mounted) Navigator.pushReplacementNamed(context, AppRoutes.login);
                      },
                    ),
                    const SizedBox(height: 32),
                  ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: AppTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.inputBorder)),
        child: Row(children: [
          Icon(icon, color: AppTheme.gold, size: 18),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontSize: 11)),
            const SizedBox(height: 2),
            Text(value,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(fontSize: 14)),
          ]),
        ]),
      );
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MenuItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
            color: AppTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.inputBorder)),
        child: Row(children: [
          Icon(icon, color: AppTheme.textSecondary, size: 20),
          const SizedBox(width: 14),
          Expanded(
              child: Text(label,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(fontSize: 14))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: AppTheme.textHint.withValues(alpha: .15),
                borderRadius: BorderRadius.circular(4)),
            child: Text('Em breve',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontSize: 10, color: AppTheme.textHint)),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right_rounded,
              size: 18, color: AppTheme.textHint),
        ]),
      );
}

// ── Seção de avaliações do barbeiro ───────────────────────────────────────────
class _BarberReviewsSection extends StatelessWidget {
  final String barberId;
  const _BarberReviewsSection({required this.barberId});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppDataProvider>();
    final reviews = data.reviewsForBarber(barberId);
    final rating = data.ratingForBarber(barberId);
    final dist = data.ratingDistributionForBarber(barberId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Minhas Avaliações'),
        const SizedBox(height: 14),
        if (reviews.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.inputBorder),
            ),
            child: Row(children: [
              const Icon(Icons.star_outline_rounded,
                  color: AppTheme.textHint, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Você ainda não recebeu avaliações.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppTheme.textHint, fontSize: 13),
                ),
              ),
            ]),
          )
        else ...[
          // Rating summary compacto
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.gold.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Column(children: [
                  Text(
                    rating.toStringAsFixed(1),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppTheme.gold, fontSize: 36, height: 1),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < rating.round()
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 12,
                        color: AppTheme.gold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${reviews.length} avaliações',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontSize: 10, color: AppTheme.textHint),
                  ),
                ]),
                const SizedBox(width: 16),
                Container(width: 1, height: 60, color: AppTheme.divider),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: List.generate(5, (i) {
                      final star = 5 - i;
                      final qty = dist[star] ?? 0;
                      final pct =
                          reviews.isNotEmpty ? qty / reviews.length : 0.0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(children: [
                          Text('$star',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                      fontSize: 10, color: AppTheme.textHint)),
                          const SizedBox(width: 3),
                          const Icon(Icons.star_rounded,
                              size: 9, color: AppTheme.gold),
                          const SizedBox(width: 5),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: pct,
                                minHeight: 5,
                                backgroundColor: AppTheme.inputBorder,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.gold.withValues(alpha: 0.65)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text('$qty',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                      fontSize: 10, color: AppTheme.textHint)),
                        ]),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Últimas 3 avaliações
          ...reviews.take(3).map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.inputBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(
                            5,
                            (i) => Icon(
                              i < r.barberRating
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              size: 13,
                              color: AppTheme.gold,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(r.clientName,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary)),
                        const SizedBox(width: 8),
                        Text(r.formattedDate,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                    fontSize: 10, color: AppTheme.textHint)),
                      ]),
                      if (r.comment != null && r.comment!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(r.comment!,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                    height: 1.4)),
                      ],
                    ],
                  ),
                ),
              )),
        ],
      ],
    );
  }
}
