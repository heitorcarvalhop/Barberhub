import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/app_data_provider.dart';
import '../../models/service_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_utils.dart';
import '../../widgets/app_widgets.dart';

class AdminServicesScreen extends StatelessWidget {
  const AdminServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppDataProvider>();
    final shop = data.selectedBarbershop ?? data.barbershops.firstOrNull;
    final services = shop == null ? <ServiceModel>[] : data.servicesForShop(shop.id);

    return Scaffold(
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Row(children: [
              const Expanded(child: ScreenHeader(eyebrow: 'ADMINISTRADOR', title: 'Serviços')),
              if (shop != null)
                _AddButton(onTap: () => _showServiceDialog(context, data, shop.id)),
            ]),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: Text('${services.where((s) => s.isActive).length} serviços ativos',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13)),
          ),

          const SizedBox(height: 20),

          Expanded(
            child: shop == null || services.isEmpty
                ? EmptyState(
                    icon: Icons.content_cut_outlined,
                    title: 'Sem serviços',
                    subtitle: shop == null
                        ? 'Crie uma barbearia primeiro.'
                        : 'Adicione o primeiro serviço.',
                    actionLabel: shop == null ? null : 'Adicionar',
                    onAction: shop == null
                        ? null
                        : () => _showServiceDialog(context, data, shop.id),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: services.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final s = services[i];
                      return Opacity(
                        opacity: s.isActive ? 1.0 : 0.4,
                        child: ServiceCard(
                          service: s,
                          onEdit: () =>
                              _showServiceDialog(context, data, shop.id, existing: s),
                          onDelete: s.isActive
                              ? () => _confirmDelete(context, data, shop.id, s)
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
      BuildContext ctx, AppDataProvider data, String shopId, ServiceModel s) async {
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: Text('Remover serviço', style: Theme.of(ctx).textTheme.titleLarge),
        content: Text('Remover "${s.name}"? Esta ação não pode ser desfeita.',
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
      await data.deleteService(shopId, s.id);
      if (ctx.mounted) AppUtils.showSnack(ctx, '"${s.name}" removido.', isError: true);
    }
  }

  void _showServiceDialog(BuildContext context, AppDataProvider data, String shopId,
      {ServiceModel? existing}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ServiceFormDialog(existing: existing, data: data, shopId: shopId),
    );
  }
}

// ── Service Form Dialog ────────────────────────────────────────────────────────
class _ServiceFormDialog extends StatefulWidget {
  final ServiceModel? existing;
  final AppDataProvider data;
  final String shopId;
  const _ServiceFormDialog({this.existing, required this.data, required this.shopId});

  @override
  State<_ServiceFormDialog> createState() => _ServiceFormDialogState();
}

class _ServiceFormDialogState extends State<_ServiceFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _price;
  late final TextEditingController _duration;
  late String _iconName;

  bool _loading = false;

  static const _icons = ['cut', 'face', 'combo', 'color', 'spa', 'brow'];
  static const _iconLabels = {
    'cut': 'Corte', 'face': 'Barba', 'combo': 'Combo',
    'color': 'Coloração', 'spa': 'Spa', 'brow': 'Sobrancelha',
  };

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _description = TextEditingController(text: widget.existing?.description ?? '');
    _price = TextEditingController(text: widget.existing != null ? widget.existing!.price.toStringAsFixed(2) : '');
    _duration = TextEditingController(text: widget.existing != null ? '${widget.existing!.durationMinutes}' : '');
    _iconName = widget.existing?.iconName ?? 'cut';
  }

  @override
  void dispose() {
    _name.dispose(); _description.dispose();
    _price.dispose(); _duration.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(isEdit ? 'Editar Serviço' : 'Novo Serviço',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 22)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ]),
            const GoldAccent(),
            const SizedBox(height: 24),

            // Icon picker
            Text('Ícone', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12, letterSpacing: .5)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _icons.map((ico) {
                final sel = _iconName == ico;
                return GestureDetector(
                  onTap: () => setState(() => _iconName = ico),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? AppTheme.gold.withValues(alpha: .12) : AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: sel ? AppTheme.gold : AppTheme.inputBorder, width: sel ? 1.5 : 1),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(ServiceCard.iconFor(ico), size: 16, color: sel ? AppTheme.gold : AppTheme.textSecondary),
                      const SizedBox(width: 6),
                      Text(_iconLabels[ico]!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 12, color: sel ? AppTheme.gold : AppTheme.textSecondary,
                          fontWeight: sel ? FontWeight.w600 : FontWeight.w400)),
                    ]),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),
            AppTextField(
              label: 'Nome do serviço', hint: 'ex: Corte Clássico', controller: _name,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo obrigatório' : null,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Descrição', hint: 'Descreva o serviço...', controller: _description,
              maxLines: 3,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo obrigatório' : null,
            ),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                child: AppTextField(
                  label: 'Preço (R\$)', hint: '0,00', controller: _price,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Obrigatório';
                    final n = double.tryParse(v.replaceAll(',', '.'));
                    if (n == null || n <= 0) return 'Valor inválido';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppTextField(
                  label: 'Duração (min)', hint: '30', controller: _duration,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Obrigatório';
                    final n = int.tryParse(v);
                    if (n == null || n <= 0) return 'Inválido';
                    return null;
                  },
                ),
              ),
            ]),

            const SizedBox(height: 28),
            CustomButton(
              label: isEdit ? 'Salvar alterações' : 'Criar serviço',
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

    final price = double.parse(_price.text.replaceAll(',', '.'));
    final duration = int.parse(_duration.text);

    if (widget.existing != null) {
      final updated = widget.existing!.copyWith(
        name: _name.text.trim(),
        description: _description.text.trim(),
        price: price,
        durationMinutes: duration,
        iconName: _iconName,
      );
      await widget.data.updateService(widget.shopId, updated);
    } else {
      final newService = ServiceModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _name.text.trim(),
        description: _description.text.trim(),
        price: price,
        durationMinutes: duration,
        iconName: _iconName,
      );
      await widget.data.addService(widget.shopId, newService);
    }

    if (mounted) {
      Navigator.pop(context);
      AppUtils.showSnack(context,
          widget.existing != null ? 'Serviço atualizado!' : 'Serviço criado!',
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
      decoration: BoxDecoration(
        color: AppTheme.gold,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.add_rounded, color: AppTheme.background, size: 18),
        const SizedBox(width: 6),
        Text('Adicionar', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 12, color: AppTheme.background)),
      ]),
    ),
  );
}
