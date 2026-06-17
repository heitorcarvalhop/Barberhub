import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_data_provider.dart';
import '../../models/appointment_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_utils.dart';
import '../../widgets/app_widgets.dart';

/// Recebe via arguments: AppointmentModel
class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  int _barbershopRating = 0;
  int _barberRating = 0;
  final _commentCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(AppointmentModel appt) async {
    if (_barbershopRating == 0 || _barberRating == 0) {
      AppUtils.showSnack(
          context, 'Avalie a barbearia e o barbeiro antes de enviar.');
      return;
    }
    setState(() => _submitting = true);
    try {
      await context.read<AppDataProvider>().submitReview(
            appointment: appt,
            barbershopRating: _barbershopRating,
            barberRating: _barberRating,
            comment: _commentCtrl.text,
          );
      if (mounted) {
        Navigator.pop(context, true); // true = sucesso
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        AppUtils.showSnack(context, 'Erro ao enviar avaliação.', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appt =
        ModalRoute.of(context)!.settings.arguments as AppointmentModel;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        size: 20, color: AppTheme.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  Text('AVALIAR ATENDIMENTO',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppTheme.textHint,
                          fontSize: 11,
                          letterSpacing: 2)),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Resumo do agendamento ─────────────────────────
                    _AppointmentSummary(appointment: appt),
                    const SizedBox(height: 28),

                    // ── Avaliação da barbearia ────────────────────────
                    _RatingSection(
                      title: 'Como foi a barbearia?',
                      subtitle: appt.barbershop.name,
                      icon: Icons.storefront_rounded,
                      value: _barbershopRating,
                      onChanged: (v) => setState(() => _barbershopRating = v),
                    ),
                    const SizedBox(height: 28),

                    // ── Avaliação do barbeiro ──────────────────────────
                    _RatingSection(
                      title: 'Como foi o atendimento do barbeiro?',
                      subtitle: appt.barber.name,
                      icon: Icons.person_rounded,
                      value: _barberRating,
                      onChanged: (v) => setState(() => _barberRating = v),
                    ),
                    const SizedBox(height: 36),

                    // ── Campo de comentário ───────────────────────────
                    const SectionHeader(title: 'Comentário'),
                    const SizedBox(height: 14),
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.inputBorder),
                      ),
                      child: TextField(
                        controller: _commentCtrl,
                        maxLines: 5,
                        maxLength: 300,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                                color: AppTheme.textPrimary, fontSize: 15),
                        decoration: InputDecoration(
                          hintText:
                              'Conte como foi a experiência (opcional)...',
                          hintStyle: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppTheme.textHint),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                          counterStyle: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                  fontSize: 11, color: AppTheme.textHint),
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),

                    // ── Botão enviar ──────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: (_submitting ||
                                _barbershopRating == 0 ||
                                _barberRating == 0)
                            ? null
                            : () => _submit(appt),
                        icon: _submitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.background))
                            : const Icon(Icons.star_rounded, size: 18),
                        label: Text(
                          _submitting
                              ? 'ENVIANDO...'
                              : 'ENVIAR AVALIAÇÃO',
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
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

// ── Seção de avaliação (título + estrelas) ──────────────────────────────────
class _RatingSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final int value;
  final ValueChanged<int> onChanged;

  const _RatingSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  static String _label(int r) {
    switch (r) {
      case 5: return '🤩  Excelente!';
      case 4: return '😊  Bom';
      case 3: return '😐  Regular';
      case 2: return '😕  Ruim';
      default: return '😞  Péssimo';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: AppTheme.gold),
              const SizedBox(width: 6),
              Text(subtitle,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontSize: 12, color: AppTheme.textSecondary)),
            ],
          ),
          const SizedBox(height: 6),
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontSize: 17),
              textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(
            value == 0 ? 'Toque nas estrelas para avaliar' : _label(value),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: value == 0 ? AppTheme.textHint : AppTheme.gold,
                  fontSize: 13,
                ),
          ),
          const SizedBox(height: 14),
          _StarRatingInput(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

// ── Resumo do agendamento ─────────────────────────────────────────────────────
class _AppointmentSummary extends StatelessWidget {
  final AppointmentModel appointment;
  const _AppointmentSummary({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.gold.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppTheme.gold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.gold.withValues(alpha: 0.3)),
            ),
            child: Center(
              child: Icon(a.barbershop.coverIconData, size: 24, color: AppTheme.gold),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.service.name,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontSize: 15)),
                const SizedBox(height: 3),
                Text(a.barber.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 13, color: AppTheme.textSecondary)),
                const SizedBox(height: 2),
                Text(
                  '${a.barbershop.name} · ${a.formattedDate}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 11, color: AppTheme.textHint),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Star rating input interativo ──────────────────────────────────────────────
class _StarRatingInput extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _StarRatingInput({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final star = i + 1;
        final filled = star <= value;
        return GestureDetector(
          onTap: () => onChanged(star),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Icon(
              filled ? Icons.star_rounded : Icons.star_outline_rounded,
              size: filled ? 38 : 34,
              color: filled ? AppTheme.gold : AppTheme.textHint,
            ),
          ),
        );
      }),
    );
  }
}
