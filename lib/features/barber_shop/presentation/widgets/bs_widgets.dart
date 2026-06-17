/// Widgets reutilizáveis exclusivos da feature barber_shop.
/// Evitam duplicação entre as telas do painel do proprietário.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:barber_hub/core/theme/app_theme.dart';

// ── Section header ────────────────────────────────────────────────────────────
class BsSectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? actionIcon;
  const BsSectionHeader({super.key, required this.title, this.actionLabel, this.onAction, this.actionIcon});

  @override
  Widget build(BuildContext context) => Row(children: [
    Text(title.toUpperCase(), style: GoogleFonts.jost(
      color: AppTheme.textHint, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 3)),
    const SizedBox(width: 12),
    Expanded(child: Container(height: 1, color: AppTheme.divider)),
    if (actionLabel != null) ...[
      const SizedBox(width: 12),
      GestureDetector(
        onTap: onAction,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (actionIcon != null) Icon(actionIcon, color: AppTheme.gold, size: 14),
          if (actionIcon != null) const SizedBox(width: 4),
          Text(actionLabel!, style: GoogleFonts.jost(color: AppTheme.gold, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      ),
    ],
  ]);
}

// ── Card container ────────────────────────────────────────────────────────────
class BsCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final bool highlight;
  const BsCard({super.key, required this.child, this.padding, this.onTap, this.highlight = false});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: highlight ? AppTheme.gold.withValues(alpha: 0.4) : AppTheme.inputBorder),
      ),
      child: child,
    ),
  );
}

// ── Status badge ──────────────────────────────────────────────────────────────
class BsStatusBadge extends StatelessWidget {
  final bool isActive;
  final String? activeLabel;
  final String? inactiveLabel;
  const BsStatusBadge({super.key, required this.isActive, this.activeLabel, this.inactiveLabel});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? const Color(0xFF2ECC71) : AppTheme.textHint;
    final bg    = isActive ? const Color(0xFF1A3A1A) : AppTheme.surface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(isActive ? (activeLabel ?? 'Ativo') : (inactiveLabel ?? 'Inativo'),
          style: GoogleFonts.jost(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}

// ── Screen header ─────────────────────────────────────────────────────────────
class BsScreenHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final List<Widget>? actions;
  const BsScreenHeader({super.key, required this.eyebrow, required this.title, this.actions});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
    child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(eyebrow.toUpperCase(), style: GoogleFonts.jost(
          color: AppTheme.gold, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 3)),
        const SizedBox(height: 4),
        Text(title, style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 28)),
      ])),
      if (actions != null) ...actions!,
    ]),
  );
}

// ── Empty state ───────────────────────────────────────────────────────────────
class BsEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  const BsEmptyState({super.key, required this.icon, required this.message, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: AppTheme.textHint, size: 48),
        const SizedBox(height: 16),
        Text(message, style: GoogleFonts.jost(color: AppTheme.textSecondary, fontSize: 14),
            textAlign: TextAlign.center),
        if (actionLabel != null) ...[
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.add, size: 16),
            label: Text(actionLabel!),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.gold,
              side: const BorderSide(color: AppTheme.gold),
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
            ),
          ),
        ],
      ]),
    ),
  );
}

// ── Gold FAB ──────────────────────────────────────────────────────────────────
class BsGoldFab extends StatelessWidget {
  final VoidCallback onPressed;
  final String tooltip;
  const BsGoldFab({super.key, required this.onPressed, this.tooltip = 'Adicionar'});

  @override
  Widget build(BuildContext context) => FloatingActionButton(
    onPressed: onPressed,
    tooltip: tooltip,
    backgroundColor: AppTheme.gold,
    foregroundColor: AppTheme.background,
    elevation: 4,
    child: const Icon(Icons.add_rounded, size: 28),
  );
}

// ── Bottom sheet modal wrapper ────────────────────────────────────────────────
class BsModalSheet extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;
  const BsModalSheet({super.key, required this.title, required this.child, this.actions});

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color: AppTheme.surface,
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      // Handle
      Container(margin: const EdgeInsets.only(top: 12, bottom: 4),
          width: 40, height: 4,
          decoration: BoxDecoration(color: AppTheme.divider, borderRadius: BorderRadius.circular(2))),
      // Title row
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
        child: Row(children: [
          Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20))),
          IconButton(icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary),
              onPressed: () => Navigator.pop(context)),
        ]),
      ),
      const Divider(height: 24),
      Flexible(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(24, 0, 24, 8), child: child)),
      if (actions != null)
        Padding(
          padding: EdgeInsets.fromLTRB(24, 8, 24, MediaQuery.of(context).viewInsets.bottom + 16),
          child: Row(mainAxisAlignment: MainAxisAlignment.end, children: actions!),
        ),
    ]),
  );
}

// ── Text field clean (para modais) ────────────────────────────────────────────
class BsTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final Widget? suffix;
  final List<TextInputFormatter>? inputFormatters;
  const BsTextField({
    super.key, required this.label, this.hint, this.controller,
    this.keyboardType, this.maxLines = 1, this.validator,
    this.focusNode, this.textInputAction, this.suffix,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    maxLines: maxLines,
    focusNode: focusNode,
    textInputAction: textInputAction,
    validator: validator,
    inputFormatters: inputFormatters,
    style: GoogleFonts.jost(color: AppTheme.textPrimary, fontSize: 15),
    decoration: InputDecoration(
      labelText: label, hintText: hint, suffix: suffix,
      labelStyle: GoogleFonts.jost(color: AppTheme.textSecondary, fontSize: 13),
      floatingLabelStyle: GoogleFonts.jost(color: AppTheme.gold, fontSize: 12),
      filled: true, fillColor: AppTheme.surfaceElevated,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.inputBorder)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.inputBorder)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.gold, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.error)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}

// ── Save button ───────────────────────────────────────────────────────────────
class BsSaveButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  const BsSaveButton({super.key, this.label = 'Salvar', this.onPressed, this.isLoading = false});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48, width: double.infinity,
    child: ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.background))
          : Text(label.toUpperCase(), style: GoogleFonts.jost(
              fontWeight: FontWeight.w700, letterSpacing: 1.5, fontSize: 13)),
    ),
  );
}
