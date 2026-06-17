import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:barber_hub/core/theme/app_theme.dart';
import 'package:barber_hub/models/app_data_provider.dart';
import 'package:barber_hub/models/barber_model.dart';
import 'package:barber_hub/models/review_model.dart';
import 'package:barber_hub/features/barber_shop/presentation/widgets/bs_widgets.dart';

/// Avaliações da barbearia, na visão do proprietário.
/// Recebe via arguments: shopId (String).
class BarberShopReviewsScreen extends StatelessWidget {
  const BarberShopReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final shopId = ModalRoute.of(context)!.settings.arguments as String;
    final data = context.watch<AppDataProvider>();
    final reviews = data.reviewsForShop(shopId);
    final rating = data.ratingForShop(shopId);
    final distribution = data.ratingDistributionForShop(shopId);
    final barbers = data.barbersForShop(shopId);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 24, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 18, color: AppTheme.textSecondary),
                    ),
                    Text('Avaliações',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontSize: 22)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child:
                    _RatingSummary(rating: rating, distribution: distribution),
              ),
              if (barbers.isNotEmpty) ...[
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: BsSectionHeader(title: 'Por barbeiro'),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: barbers
                        .map((b) => _BarberRatingRow(
                              barber: b,
                              rating: data.ratingForBarber(b.id),
                              reviewCount:
                                  data.reviewsForBarber(b.id).length,
                            ))
                        .toList(),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: BsSectionHeader(title: 'Comentários (${reviews.length})'),
              ),
              const SizedBox(height: 12),
              reviews.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 24),
                      child: Center(
                        child: Text(
                          'Nenhuma avaliação ainda.',
                          style:
                              GoogleFonts.jost(color: AppTheme.textSecondary),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: reviews.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _ReviewCard(review: reviews[i]),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarberRatingRow extends StatelessWidget {
  final BarberModel barber;
  final double rating;
  final int reviewCount;

  const _BarberRatingRow({
    required this.barber,
    required this.rating,
    required this.reviewCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: BsCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(barber.name,
                  style: GoogleFonts.jost(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
            ),
            if (reviewCount == 0)
              Text('Sem avaliações',
                  style: GoogleFonts.jost(color: AppTheme.textHint, fontSize: 11))
            else ...[
              Icon(Icons.star_rounded, color: AppTheme.gold, size: 14),
              const SizedBox(width: 4),
              Text(rating.toStringAsFixed(1),
                  style: GoogleFonts.jost(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
              const SizedBox(width: 4),
              Text('($reviewCount)',
                  style: GoogleFonts.jost(color: AppTheme.textHint, fontSize: 11)),
            ],
          ],
        ),
      ),
    );
  }
}

class _RatingSummary extends StatelessWidget {
  final double rating;
  final Map<int, int> distribution;
  const _RatingSummary({required this.rating, required this.distribution});

  @override
  Widget build(BuildContext context) {
    final total = distribution.values.fold(0, (a, b) => a + b);

    return BsCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            children: [
              Text(rating.toStringAsFixed(1),
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(color: AppTheme.gold, fontSize: 32)),
              const Icon(Icons.star_rounded, color: AppTheme.gold, size: 18),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              children: [5, 4, 3, 2, 1].map((star) {
                final count = distribution[star] ?? 0;
                final fraction = total == 0 ? 0.0 : count / total;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text('$star', style: GoogleFonts.jost(fontSize: 11, color: AppTheme.textSecondary)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: fraction,
                            minHeight: 6,
                            backgroundColor: AppTheme.inputBorder,
                            color: AppTheme.gold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 22,
                        child: Text('$count',
                            style: GoogleFonts.jost(fontSize: 11, color: AppTheme.textHint)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final ReviewModel review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return BsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(review.clientName,
                    style: GoogleFonts.jost(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
              ),
              Text(review.formattedDate,
                  style: GoogleFonts.jost(color: AppTheme.textHint, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text('Barbearia',
                  style: GoogleFonts.jost(color: AppTheme.textHint, fontSize: 11)),
              const SizedBox(width: 4),
              ...List.generate(5, (i) => Icon(
                    i < review.barbershopRating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: AppTheme.gold,
                    size: 13,
                  )),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text('Barbeiro',
                  style: GoogleFonts.jost(color: AppTheme.textHint, fontSize: 11)),
              const SizedBox(width: 4),
              ...List.generate(5, (i) => Icon(
                    i < review.barberRating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: AppTheme.gold,
                    size: 13,
                  )),
              const SizedBox(width: 8),
              Expanded(
                child: Text('${review.barberName} · ${review.serviceName}',
                    style: GoogleFonts.jost(color: AppTheme.textSecondary, fontSize: 12),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          if (review.comment != null) ...[
            const SizedBox(height: 8),
            Text(review.comment!,
                style: GoogleFonts.jost(color: AppTheme.textSecondary, fontSize: 13, height: 1.4)),
          ],
        ],
      ),
    );
  }
}
