import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:barber_hub/features/client/data/models/appointment_model.dart';
import 'package:barber_hub/features/client/data/models/service_model.dart';
import 'package:barber_hub/features/client/data/models/barber_model.dart';
import 'package:barber_hub/core/theme/app_theme.dart';
import 'package:barber_hub/core/utils/app_utils.dart';

// ─────────────────────────────────────────────────────────────────────────────
// BRAND
// ─────────────────────────────────────────────────────────────────────────────

class BarberLogo extends StatelessWidget {
  final double size;
  const BarberLogo({super.key, this.size = 48});
  @override
  Widget build(BuildContext context) => SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _ScissorsPainter()));
}

class _ScissorsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = AppTheme.gold
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final cx = size.width / 2, cy = size.height / 2, r = size.width * 0.18;
    canvas.drawLine(Offset(cx - r * .6, cy - r * 2.2),
        Offset(cx + r * 1.8, cy + r * 1.8), p);
    canvas.drawLine(Offset(cx + r * .6, cy - r * 2.2),
        Offset(cx - r * 1.8, cy + r * 1.8), p);
    canvas.drawCircle(Offset(cx - r * 1.4, cy + r * 1.4), r, p);
    canvas.drawCircle(Offset(cx + r * 1.4, cy + r * 1.4), r, p);
    canvas.drawCircle(
        Offset(cx, cy),
        2.5,
        Paint()
          ..color = AppTheme.gold
          ..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

class BrandHeader extends StatelessWidget {
  final String subtitle;
  const BrandHeader({super.key, this.subtitle = ''});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const BarberLogo(size: 36),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('BARBER',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.gold, fontSize: 11, letterSpacing: 4)),
          Text('HUB',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontSize: 28, height: .9, fontWeight: FontWeight.w700)),
        ]),
      ]),
      if (subtitle.isNotEmpty) ...[
        const SizedBox(height: 24),
        Text(subtitle,
            style:
                Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6)),
      ],
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LAYOUT
// ─────────────────────────────────────────────────────────────────────────────

class GoldAccent extends StatelessWidget {
  const GoldAccent({super.key});
  @override
  Widget build(BuildContext context) => Container(
        width: 40,
        height: 2,
        decoration: const BoxDecoration(
            gradient:
                LinearGradient(colors: [AppTheme.gold, AppTheme.goldDark])),
      );
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  const SectionHeader(
      {super.key, required this.title, this.actionLabel, this.onAction});
  @override
  Widget build(BuildContext context) => Row(children: [
        Text(title.toUpperCase(),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppTheme.textHint, fontSize: 10, letterSpacing: 3)),
        const SizedBox(width: 12),
        Expanded(child: Container(height: 1, color: AppTheme.divider)),
        if (actionLabel != null) ...[
          const SizedBox(width: 12),
          GestureDetector(
              onTap: onAction,
              child: Text(actionLabel!,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppTheme.gold, fontSize: 12))),
        ],
      ]);
}

class DividerWithText extends StatelessWidget {
  final String text;
  const DividerWithText({super.key, required this.text});
  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(child: Container(height: 1, color: AppTheme.divider)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(text,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontSize: 12)),
        ),
        Expanded(child: Container(height: 1, color: AppTheme.divider)),
      ]);
}

class ScreenHeader extends StatelessWidget {
  final String eyebrow, title;
  const ScreenHeader({super.key, required this.eyebrow, required this.title});
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(eyebrow,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.gold, fontSize: 11, letterSpacing: 4)),
          Text(title, style: Theme.of(context).textTheme.displayMedium),
        ],
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// BUTTONS & INPUTS
// ─────────────────────────────────────────────────────────────────────────────

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool outlined;
  final bool isDanger;
  final IconData? icon;
  final Color? color;
  final double height;

  const CustomButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.outlined = false,
    this.isDanger = false,
    this.icon,
    this.color,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    final c = isDanger ? Colors.redAccent : (color ?? AppTheme.gold);
    if (outlined) {
      return SizedBox(
        width: double.infinity,
        height: height,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: c),
            foregroundColor: c,
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(4))),
          ),
          child: isLoading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: c))
              : Text(label.toUpperCase(),
                  style: GoogleFonts.jost(
                      fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppTheme.background))
            : icon != null
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 18, color: AppTheme.background),
                      const SizedBox(width: 8),
                      Text(label.toUpperCase(),
                          style: GoogleFonts.jost(
                              fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  )
                : Text(label.toUpperCase(),
                    style: GoogleFonts.jost(
                        fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const PrimaryButton(
      {super.key,
      required this.label,
      this.onPressed,
      this.isLoading = false});

  @override
  Widget build(BuildContext context) => CustomButton(
      label: label, onPressed: onPressed, isLoading: isLoading);
}

class AppTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool obscure;
  final bool isPassword;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final VoidCallback? onEditingComplete;
  final void Function(String)? onFieldSubmitted;
  final int maxLines;
  final List<TextInputFormatter>? inputFormatters;

  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.focusNode,
    this.obscure = false,
    this.isPassword = false,
    this.keyboardType,
    this.validator,
    this.textInputAction,
    this.onEditingComplete,
    this.onFieldSubmitted,
    this.inputFormatters,
    this.maxLines = 1,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _show = false;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(widget.label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppTheme.textSecondary, fontSize: 11, letterSpacing: 1)),
      const SizedBox(height: 8),
      TextFormField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        obscureText: (widget.obscure || widget.isPassword) && !_show,
        keyboardType: widget.keyboardType,
        validator: widget.validator,
        textInputAction: widget.textInputAction,
        onEditingComplete: widget.onEditingComplete,
        onFieldSubmitted: widget.onFieldSubmitted,
        inputFormatters: widget.inputFormatters,
        maxLines: (widget.obscure || widget.isPassword) ? 1 : widget.maxLines,
        style: Theme.of(context)
            .textTheme
            .bodyLarge
            ?.copyWith(fontSize: 15, color: AppTheme.textPrimary),
        decoration: InputDecoration(
          hintText: widget.hint,
          suffixIcon: (widget.obscure || widget.isPassword)
              ? IconButton(
                  icon: Icon(
                      _show ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppTheme.textHint,
                      size: 20),
                  onPressed: () => setState(() => _show = !_show),
                )
              : null,
        ),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SERVICE CARD
// ─────────────────────────────────────────────────────────────────────────────

class ServiceCard extends StatelessWidget {
  final ServiceModel service;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ServiceCard(
      {super.key,
      required this.service,
      this.onTap,
      this.onEdit,
      this.onDelete});

  static IconData iconFor(String name) {
    switch (name) {
      case 'face':
        return Icons.face_retouching_natural_outlined;
      case 'combo':
        return Icons.auto_awesome_outlined;
      case 'color':
        return Icons.palette_outlined;
      case 'spa':
        return Icons.spa_outlined;
      case 'brow':
        return Icons.visibility_outlined;
      default:
        return Icons.content_cut_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: AppTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.inputBorder)),
        child: Row(children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
                color: AppTheme.gold.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.gold.withValues(alpha: .2))),
            child:
                Icon(iconFor(service.iconName), color: AppTheme.gold, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(service.name,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontSize: 15)),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.schedule_outlined,
                      size: 12, color: AppTheme.textHint),
                  const SizedBox(width: 4),
                  Text(service.formattedDuration,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontSize: 12)),
                ]),
              ])),
          if (onEdit != null || onDelete != null) ...[
            if (onEdit != null)
              IconButton(
                  icon: const Icon(Icons.edit_outlined,
                      color: AppTheme.textSecondary, size: 18),
                  onPressed: onEdit,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints()),
            if (onDelete != null) ...[
              const SizedBox(width: 8),
              IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: AppTheme.error, size: 18),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints())
            ],
          ] else ...[
            Text(service.formattedPrice,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.gold,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 12, color: AppTheme.textHint),
          ],
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// APPOINTMENT CARD  (atualizado: mostra barbearia)
// ─────────────────────────────────────────────────────────────────────────────

class AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  final bool showClient;
  final bool showBarber;
  final bool showBarbershop; // ← novo
  final VoidCallback? onCancel;
  final VoidCallback? onReschedule;
  final void Function(AppointmentStatus)? onStatusChange;

  const AppointmentCard({
    super.key,
    required this.appointment,
    this.showClient = false,
    this.showBarber = true,
    this.showBarbershop = true, // ← padrão: mostrar
    this.onCancel,
    this.onReschedule,
    this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    final (statusColor, _) = AppUtils.statusColors(a.status);
    return Container(
      decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.inputBorder)),
      child: Column(children: [
        // ── Barbershop header ────────────────────────────────────────────
        if (showBarbershop)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.gold.withValues(alpha: 0.04),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(10)),
              border: const Border(
                  bottom: BorderSide(color: AppTheme.divider, width: 0.5)),
            ),
            child: Row(children: [
              const Icon(Icons.storefront_outlined,
                  size: 12, color: AppTheme.gold),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  a.barbershop.name,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppTheme.gold, fontSize: 11, letterSpacing: 0.3),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              StatusBadge(
                label: a.statusLabel.toUpperCase(),
                color: statusColor,
                bgColor: statusColor.withValues(alpha: .1),
              ),
            ]),
          ),

        // ── Main content ─────────────────────────────────────────────────
        Padding(
            padding: const EdgeInsets.all(14),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _DateBox(day: a.date.day, month: a.monthAbbr),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    // Se não há header de barbearia, mostra status inline
                    if (!showBarbershop)
                      Row(children: [
                        Expanded(
                            child: Text(a.service.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontSize: 15))),
                        StatusBadge(
                            label: a.statusLabel.toUpperCase(),
                            color: statusColor,
                            bgColor: statusColor.withValues(alpha: .1)),
                      ])
                    else
                      Text(a.service.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontSize: 15)),
                    const SizedBox(height: 4),
                    if (showClient)
                      _Meta(
                          icon: Icons.person_outline_rounded,
                          text: a.clientName),
                    if (showBarber)
                      _Meta(
                          icon: Icons.content_cut_rounded,
                          text: a.barber.name),
                    _Meta(
                        icon: Icons.schedule_outlined,
                        text:
                            '${a.timeSlot}  ·  ${a.service.formattedDuration}'),
                    _Meta(
                        icon: Icons.attach_money_rounded,
                        text: a.service.formattedPrice,
                        gold: true),
                  ])),
            ])),

        // ── Actions ───────────────────────────────────────────────────────
        if (onCancel != null ||
            onReschedule != null ||
            onStatusChange != null) ...[
          Container(height: 1, color: AppTheme.divider),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(children: [
                if (onReschedule != null && a.canReschedule)
                  _Btn(
                      icon: Icons.edit_calendar_outlined,
                      label: 'Remarcar',
                      onTap: onReschedule!),
                if (onStatusChange != null && a.canComplete)
                  _Btn(
                      icon: Icons.check_circle_outline,
                      label: 'Concluir',
                      color: AppTheme.gold,
                      onTap: () =>
                          onStatusChange!(AppointmentStatus.completed)),
                if (onCancel != null && a.canCancel) ...[
                  if (onReschedule != null || onStatusChange != null)
                    Container(width: 1, height: 20, color: AppTheme.divider),
                  _Btn(
                      icon: Icons.cancel_outlined,
                      label: 'Cancelar',
                      color: AppTheme.error,
                      onTap: onCancel!),
                ],
              ])),
        ],
      ]),
    );
  }
}

class _DateBox extends StatelessWidget {
  final int day;
  final String month;
  const _DateBox({required this.day, required this.month});
  @override
  Widget build(BuildContext context) => Container(
        width: 50,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
            color: AppTheme.gold.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.gold.withValues(alpha: .2))),
        child: Column(children: [
          Text('$day',
              style: Theme.of(context)
                  .textTheme
                  .headlineLarge
                  ?.copyWith(color: AppTheme.gold, fontSize: 22, height: 1)),
          Text(month,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.gold, fontSize: 9, letterSpacing: 1)),
        ]),
      );
}

class _Meta extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool gold;
  const _Meta({required this.icon, required this.text, this.gold = false});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Row(children: [
          Icon(icon, size: 13, color: AppTheme.textHint),
          const SizedBox(width: 5),
          Expanded(
            child: Text(text,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 13,
                    color: gold ? AppTheme.gold : AppTheme.textSecondary)),
          ),
        ]),
      );
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;
  const _Btn(
      {required this.icon,
      required this.label,
      this.color,
      required this.onTap});
  @override
  Widget build(BuildContext context) => Expanded(
          child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 15),
        label: Text(label),
        style: TextButton.styleFrom(
            foregroundColor: color ?? AppTheme.gold,
            textStyle:
                GoogleFonts.jost(fontSize: 12, fontWeight: FontWeight.w500)),
      ));
}

// ─────────────────────────────────────────────────────────────────────────────
// BADGES
// ─────────────────────────────────────────────────────────────────────────────

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color, bgColor;
  const StatusBadge(
      {super.key,
      required this.label,
      required this.color,
      required this.bgColor});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: bgColor, borderRadius: BorderRadius.circular(4)),
        child: Text(label,
            style: GoogleFonts.jost(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: .5)),
      );
}

class RoleBadge extends StatelessWidget {
  final String label;
  const RoleBadge({super.key, required this.label});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: AppTheme.gold.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.gold.withValues(alpha: .3))),
        child: Text(label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppTheme.gold, fontSize: 10, letterSpacing: 1)),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// BARBER COMPONENTS
// ─────────────────────────────────────────────────────────────────────────────

class BarberAvatar extends StatelessWidget {
  final String initials;
  final double size;
  final bool selected;
  const BarberAvatar(
      {super.key,
      required this.initials,
      this.size = 48,
      this.selected = false});
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected
                ? AppTheme.gold.withValues(alpha: .2)
                : AppTheme.surfaceElevated,
            border: Border.all(
                color: selected ? AppTheme.gold : AppTheme.inputBorder,
                width: selected ? 2 : 1)),
        child: Center(
            child: Text(initials,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: selected ? AppTheme.gold : AppTheme.textSecondary,
                    fontSize: size * .28,
                    letterSpacing: 1))),
      );
}

class StarRating extends StatelessWidget {
  final double rating;
  final int reviewCount;
  const StarRating(
      {super.key, required this.rating, required this.reviewCount});
  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.star_rounded, color: AppTheme.gold, size: 14),
        const SizedBox(width: 4),
        Text(rating.toStringAsFixed(1),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        const SizedBox(width: 4),
        Text('($reviewCount)',
            style:
                Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12)),
      ]);
}

class BarberListTile extends StatelessWidget {
  final BarberModel barber;
  final bool selected;
  final VoidCallback? onTap, onEdit, onDelete;
  const BarberListTile(
      {super.key,
      required this.barber,
      this.selected = false,
      this.onTap,
      this.onEdit,
      this.onDelete});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.gold.withValues(alpha: .06)
                : AppTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: selected ? AppTheme.gold : AppTheme.inputBorder,
                width: selected ? 1.5 : 1),
          ),
          child: Row(children: [
            BarberAvatar(
                initials: barber.avatarInitials, size: 44, selected: selected),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(barber.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(barber.specialty,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontSize: 12)),
                  const SizedBox(height: 4),
                  StarRating(
                      rating: barber.rating, reviewCount: barber.reviewCount),
                ])),
            if (onEdit != null || onDelete != null) ...[
              if (onEdit != null)
                IconButton(
                    icon: const Icon(Icons.edit_outlined,
                        color: AppTheme.textSecondary, size: 18),
                    onPressed: onEdit),
              if (onDelete != null)
                IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: AppTheme.error, size: 18),
                    onPressed: onDelete),
            ] else if (selected)
              const Icon(Icons.check_circle_rounded,
                  color: AppTheme.gold, size: 20),
          ]),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// MISC
// ─────────────────────────────────────────────────────────────────────────────

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  const EmptyState(
      {super.key,
      required this.icon,
      required this.title,
      required this.subtitle,
      this.actionLabel,
      this.onAction});
  @override
  Widget build(BuildContext context) => LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                  child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                    color: AppTheme.surfaceElevated,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: AppTheme.inputBorder)),
                                child: Icon(icon,
                                    color: AppTheme.textHint, size: 32)),
                            const SizedBox(height: 20),
                            Text(title,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(color: AppTheme.textPrimary),
                                textAlign: TextAlign.center),
                            const SizedBox(height: 8),
                            Text(subtitle,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(height: 1.5),
                                textAlign: TextAlign.center),
                            if (actionLabel != null) ...[
                              const SizedBox(height: 24),
                              SizedBox(
                                  width: 180,
                                  child: ElevatedButton(
                                      onPressed: onAction,
                                      child: Text(
                                          actionLabel!.toUpperCase())))
                            ],
                          ]))))));
}

class StatCard extends StatelessWidget {
  final String value, label;
  final IconData? icon;
  final Color? valueColor;
  const StatCard(
      {super.key,
      required this.value,
      required this.label,
      this.icon,
      this.valueColor});
  @override
  Widget build(BuildContext context) => Expanded(
          child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
            color: AppTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.inputBorder)),
        child: Column(children: [
          if (icon != null) ...[
            Icon(icon, color: AppTheme.gold, size: 18),
            const SizedBox(height: 6)
          ],
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(color: valueColor ?? AppTheme.gold, fontSize: 26)),
          const SizedBox(height: 4),
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontSize: 11),
              textAlign: TextAlign.center),
        ]),
      ));
}
