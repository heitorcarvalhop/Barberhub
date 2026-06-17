import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_data_provider.dart';
import '../../models/barber_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_utils.dart';
import '../../widgets/app_widgets.dart';

class AdminBarbersScreen extends StatelessWidget {
  const AdminBarbersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppDataProvider>();
    final shop = data.selectedBarbershop ?? data.barbershops.firstOrNull;
    final barbers = shop == null ? <BarberModel>[] : data.barbersForShop(shop.id);

    return Scaffold(
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Row(children: [
              const Expanded(child: ScreenHeader(eyebrow: 'ADMINISTRADOR', title: 'Barbeiros')),
              if (shop != null)
                _AddButton(onTap: () => _showBarberDialog(context, data, shop.id)),
            ]),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: Text('${barbers.where((b) => b.isActive).length} barbeiros ativos',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13)),
          ),

          const SizedBox(height: 20),

          Expanded(
            child: shop == null || barbers.isEmpty
                ? EmptyState(
                    icon: Icons.people_outline_rounded,
                    title: 'Sem barbeiros',
                    subtitle: shop == null
                        ? 'Crie uma barbearia primeiro.'
                        : 'Adicione o primeiro barbeiro.',
                    actionLabel: shop == null ? null : 'Adicionar',
                    onAction:
                        shop == null ? null : () => _showBarberDialog(context, data, shop.id),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: barbers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final b = barbers[i];
                      return Opacity(
                        opacity: b.isActive ? 1.0 : 0.4,
                        child: _BarberAdminCard(
                          barber: b,
                          appointmentCount: data.appointmentsForBarber(b.id).length,
                          onEdit: () => _showBarberDialog(context, data, shop.id, existing: b),
                          onDelete: b.isActive
                              ? () => _confirmDelete(context, data, shop.id, b)
                              : null,
                        ),
                      );
                    },
                  ),
          ),
        ]),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext ctx, AppDataProvider data, String shopId, BarberModel b) async {
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: Text('Remover barbeiro', style: Theme.of(ctx).textTheme.titleLarge),
        content: Text('Remover "${b.name}"? Os agendamentos existentes serão mantidos.',
            style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(height: 1.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await data.deleteBarber(shopId, b.id);
      if (ctx.mounted) AppUtils.showSnack(ctx, '"${b.name}" removido.', isError: true);
    }
  }

  void _showBarberDialog(BuildContext context, AppDataProvider data, String shopId,
      {BarberModel? existing}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _BarberFormDialog(existing: existing, data: data, shopId: shopId),
    );
  }
}

// ── Barber Admin Card ──────────────────────────────────────────────────────────
class _BarberAdminCard extends StatelessWidget {
  final BarberModel barber;
  final int appointmentCount;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _BarberAdminCard({
    required this.barber,
    required this.appointmentCount,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.inputBorder),
      ),
      child: Column(children: [
        Row(children: [
          BarberAvatar(initials: barber.avatarInitials, size: 50),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(barber.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 15)),
            const SizedBox(height: 3),
            Text(barber.specialty, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12)),
            const SizedBox(height: 5),
            Row(children: [
              StarRating(rating: barber.rating, reviewCount: barber.reviewCount),
              const SizedBox(width: 12),
              const Icon(Icons.calendar_today_outlined, size: 12, color: AppTheme.textHint),
              const SizedBox(width: 4),
              Text('$appointmentCount atend.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11)),
            ]),
          ])),
        ]),
        if (barber.phone.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(height: 1, color: AppTheme.divider),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.phone_outlined, size: 13, color: AppTheme.textHint),
            const SizedBox(width: 6),
            Text(barber.phone, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12)),
            const Spacer(),
            if (onEdit != null)
              _ActionChip(icon: Icons.edit_outlined, label: 'Editar', onTap: onEdit!),
            const SizedBox(width: 8),
            if (onDelete != null)
              _ActionChip(icon: Icons.delete_outline_rounded, label: 'Remover', onTap: onDelete!, isDestructive: true),
          ]),
        ] else ...[
          const SizedBox(height: 10),
          Container(height: 1, color: AppTheme.divider),
          const SizedBox(height: 8),
          Row(children: [
            const Spacer(),
            if (onEdit != null)
              _ActionChip(icon: Icons.edit_outlined, label: 'Editar', onTap: onEdit!),
            const SizedBox(width: 8),
            if (onDelete != null)
              _ActionChip(icon: Icons.delete_outline_rounded, label: 'Remover', onTap: onDelete!, isDestructive: true),
          ]),
        ],
      ]),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ActionChip({required this.icon, required this.label, required this.onTap, this.isDestructive = false});

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppTheme.error : AppTheme.textSecondary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: .2)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }
}

// ── Barber Form Dialog ─────────────────────────────────────────────────────────
class _BarberFormDialog extends StatefulWidget {
  final BarberModel? existing;
  final AppDataProvider data;
  final String shopId;
  const _BarberFormDialog({this.existing, required this.data, required this.shopId});

  @override
  State<_BarberFormDialog> createState() => _BarberFormDialogState();
}

class _BarberFormDialogState extends State<_BarberFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _specialty;
  late final TextEditingController _phone;
  bool _loading = false;

  static const _specialties = [
    'Cortes Clássicos & Fade',
    'Barba & Navalha',
    'Coloração & Química',
    'Cortes Modernos',
    'Hidratação & Tratamentos',
    'Sobrancelha & Design',
  ];

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _specialty = TextEditingController(text: widget.existing?.specialty ?? '');
    _phone = TextEditingController(text: widget.existing?.phone ?? '');
  }

  @override
  void dispose() {
    _name.dispose(); _specialty.dispose(); _phone.dispose();
    super.dispose();
  }

  String _initials(String name) {
    final p = name.trim().split(' ');
    if (p.length >= 2) return '${p.first[0]}${p.last[0]}'.toUpperCase();
    return name.isNotEmpty ? name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase() : 'BB';
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(isEdit ? 'Editar Barbeiro' : 'Novo Barbeiro',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 22)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ]),
            const GoldAccent(),
            const SizedBox(height: 24),

            // Preview avatar
            Center(
              child: AnimatedBuilder(
                animation: _name,
                builder: (_, __) => BarberAvatar(
                  initials: _name.text.isEmpty ? 'BB' : _initials(_name.text),
                  size: 64,
                ),
              ),
            ),
            const SizedBox(height: 20),

            AppTextField(
              label: 'Nome completo', hint: 'ex: Rafael Mendes', controller: _name,
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Campo obrigatório';
                if (v.trim().length < 3) return 'Nome muito curto';
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Specialty quick-pick
            Text('Especialidade', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12, letterSpacing: .5)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _specialties.map((sp) {
                final sel = _specialty.text == sp;
                return GestureDetector(
                  onTap: () => setState(() => _specialty.text = sp),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: sel ? AppTheme.gold.withValues(alpha: .12) : AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: sel ? AppTheme.gold : AppTheme.inputBorder, width: sel ? 1.5 : 1),
                    ),
                    child: Text(sp, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 11, color: sel ? AppTheme.gold : AppTheme.textSecondary,
                        fontWeight: sel ? FontWeight.w600 : FontWeight.w400)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Ou digite a especialidade', hint: 'ex: Cortes Modernos', controller: _specialty,
              textInputAction: TextInputAction.next,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo obrigatório' : null,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Telefone', hint: '(11) 99999-0000', controller: _phone,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
            ),

            const SizedBox(height: 28),
            CustomButton(
              label: isEdit ? 'Salvar alterações' : 'Adicionar barbeiro',
              isLoading: _loading,
              onPressed: _submit,
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final name = _name.text.trim();
    final initials = _initials(name);

    if (widget.existing != null) {
      final updated = widget.existing!.copyWith(
        name: name,
        specialty: _specialty.text.trim(),
        phone: _phone.text.trim(),
        avatarInitials: initials,
      );
      await widget.data.updateBarber(widget.shopId, updated);
    } else {
      final newBarber = BarberModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        specialty: _specialty.text.trim(),
        avatarInitials: initials,
        phone: _phone.text.trim(),
        rating: 5.0,
        reviewCount: 0,
      );
      await widget.data.addBarber(widget.shopId, newBarber);
    }

    if (mounted) {
      Navigator.pop(context);
      AppUtils.showSnack(context,
          widget.existing != null ? 'Barbeiro atualizado!' : 'Barbeiro adicionado!',
          isSuccess: true);
    }
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: AppTheme.gold, borderRadius: BorderRadius.circular(6)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.add_rounded, color: AppTheme.background, size: 18),
        const SizedBox(width: 6),
        Text('Adicionar', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 12, color: AppTheme.background)),
      ]),
    ),
  );
}
