import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:barber_hub/core/theme/app_theme.dart';
import 'package:barber_hub/features/auth/presentation/providers/auth_providers.dart';
import 'package:barber_hub/features/auth/presentation/providers/auth_state.dart';
import 'package:barber_hub/models/service_model.dart';

// CORREÇÃO: import corrigido â€” usa models/app_data_provider.dart (registrado
// no MultiProvider de main.dart), não features/client/presentation/providers/.
// Os dois são classes Dart distintas; usar a errada causa ProviderNotFoundException.
import 'package:barber_hub/models/app_data_provider.dart';

/// Tela de Serviços da Barbearia â€” CRUD completo.
class BarberShopServicesScreen extends ConsumerWidget {
  const BarberShopServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final shopId =
        authState is AuthAuthenticated ? authState.user.linkedId : null;

    // Lê o AppDataProvider registrado no MultiProvider (models/app_data_provider.dart)
    final data = context.watch<AppDataProvider>();
    final services =
        shopId != null ? data.servicesForShop(shopId) : <ServiceModel>[];

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // â”€â”€ Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
              child: Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SERVIÇOS',
                        style: GoogleFonts.jost(
                            color: AppTheme.gold,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 4),
                      ),
                      Text(
                        'Meus Serviços',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontSize: 26),
                      ),
                    ],
                  ),
                ),
                // â”€â”€ Botão Novo â”€â”€
                GestureDetector(
                  onTap: shopId == null
                      ? null
                      : () => _showSheet(context, data, shopId, null),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                        color: AppTheme.gold,
                        borderRadius: BorderRadius.circular(8)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.add_rounded,
                          color: AppTheme.background, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Novo',
                        style: GoogleFonts.jost(
                            color: AppTheme.background,
                            fontWeight: FontWeight.w700,
                            fontSize: 13),
                      ),
                    ]),
                  ),
                ),
              ]),
            ),

            // â”€â”€ Contador â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Text(
                '${services.length} serviço${services.length != 1 ? "s" : ""} '
                'cadastrado${services.length != 1 ? "s" : ""}',
                style: GoogleFonts.jost(
                    color: AppTheme.textSecondary, fontSize: 13),
              ),
            ),

            // â”€â”€ Lista â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Expanded(
              child: shopId == null
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.gold))
                  : services.isEmpty
                      ? _EmptyState(
                          onAdd: () => _showSheet(context, data, shopId, null))
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                          itemCount: services.length,
                          separatorBuilder: (_, __) =>
                              Container(height: 1, color: AppTheme.divider),
                          itemBuilder: (_, i) => _Tile(
                            service: services[i],
                            onEdit: () =>
                                _showSheet(context, data, shopId, services[i]),
                            onDelete: () => _confirmDelete(
                                context, data, shopId, services[i]),
                            onToggle: () => data.toggleShopServiceActive(
                                shopId, services[i].id),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // â”€â”€ Sheet helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  void _showSheet(BuildContext ctx, AppDataProvider data, String shopId,
          ServiceModel? existing) =>
      showModalBottomSheet(
        context: ctx,
        isScrollControlled: true,
        backgroundColor: AppTheme.surface,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        builder: (_) =>
            _FormSheet(data: data, shopId: shopId, existing: existing),
      );

  void _confirmDelete(BuildContext ctx, AppDataProvider data, String shopId,
          ServiceModel s) =>
      showDialog(
        context: ctx,
        builder: (_) => AlertDialog(
          backgroundColor: AppTheme.surfaceElevated,
          title: Text(
            'Excluir serviço?',
            style: GoogleFonts.jost(
                color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
          ),
          content: Text(
            'Tem certeza que deseja excluir "${s.name}"?',
            style: GoogleFonts.jost(color: AppTheme.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancelar',
                  style: GoogleFonts.jost(color: AppTheme.textSecondary)),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await data.deleteShopService(shopId, s.id);
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  if (!ctx.mounted) return;
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              },
              child: Text('Excluir',
                  style: GoogleFonts.jost(color: AppTheme.error)),
            ),
          ],
        ),
      );
}

// â”€â”€ Tile de serviço â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _Tile extends StatelessWidget {
  final ServiceModel service;
  final VoidCallback onEdit, onDelete, onToggle;

  const _Tile({
    required this.service,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: service.isActive
                  ? AppTheme.gold.withValues(alpha: 0.1)
                  : AppTheme.inputBorder,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.content_cut_rounded,
                color: service.isActive ? AppTheme.gold : AppTheme.textHint,
                size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(
                      service.name,
                      style: GoogleFonts.jost(
                        color: service.isActive
                            ? AppTheme.textPrimary
                            : AppTheme.textHint,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (!service.isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                          color: AppTheme.inputBorder,
                          borderRadius: BorderRadius.circular(20)),
                      child: Text('Inativo',
                          style: GoogleFonts.jost(
                              color: AppTheme.textHint,
                              fontSize: 10,
                              fontWeight: FontWeight.w600)),
                    ),
                ]),
                const SizedBox(height: 3),
                Row(children: [
                  Text(
                    service.formattedPrice,
                    style: GoogleFonts.jost(
                        color: AppTheme.gold,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.timer_outlined,
                      size: 12, color: AppTheme.textHint),
                  const SizedBox(width: 3),
                  Text(service.formattedDuration,
                      style: GoogleFonts.jost(
                          color: AppTheme.textHint, fontSize: 12)),
                ]),
              ],
            ),
          ),
          PopupMenuButton<String>(
            color: AppTheme.surfaceElevated,
            icon: const Icon(Icons.more_vert_rounded,
                color: AppTheme.textSecondary, size: 20),
            onSelected: (v) {
              if (v == 'edit') onEdit();
              if (v == 'toggle') onToggle();
              if (v == 'delete') onDelete();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(children: [
                  const Icon(Icons.edit_outlined,
                      color: AppTheme.gold, size: 16),
                  const SizedBox(width: 10),
                  Text('Editar',
                      style: GoogleFonts.jost(color: AppTheme.textPrimary)),
                ]),
              ),
              PopupMenuItem(
                value: 'toggle',
                child: Row(children: [
                  Icon(
                      service.isActive
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppTheme.textSecondary,
                      size: 16),
                  const SizedBox(width: 10),
                  Text(service.isActive ? 'Desativar' : 'Ativar',
                      style: GoogleFonts.jost(color: AppTheme.textPrimary)),
                ]),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(children: [
                  const Icon(Icons.delete_outline_rounded,
                      color: AppTheme.error, size: 16),
                  const SizedBox(width: 10),
                  Text('Excluir',
                      style: GoogleFonts.jost(color: AppTheme.error)),
                ]),
              ),
            ],
          ),
        ]),
      );
}

// â”€â”€ Formulário criar/editar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _FormSheet extends StatefulWidget {
  final AppDataProvider data;
  final String shopId;
  final ServiceModel? existing;

  const _FormSheet({
    required this.data,
    required this.shopId,
    this.existing,
  });

  @override
  State<_FormSheet> createState() => _FormSheetState();
}

class _FormSheetState extends State<_FormSheet> {
  late final TextEditingController _name, _desc, _price, _duration;
  bool _active = true;

  @override
  void initState() {
    super.initState();
    final s = widget.existing;
    _name = TextEditingController(text: s?.name ?? '');
    _desc = TextEditingController(text: s?.description ?? '');
    _price = TextEditingController(
        text: s != null ? s.price.toStringAsFixed(2) : '');
    _duration =
        TextEditingController(text: s != null ? '${s.durationMinutes}' : '30');
    _active = s?.isActive ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _price.dispose();
    _duration.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final nm = _name.text.trim();
    if (nm.isEmpty) return;
    final price = double.tryParse(_price.text.replaceAll(',', '.')) ?? 0.0;
    final dur = int.tryParse(_duration.text) ?? 30;

    try {
      if (widget.existing == null) {
        await widget.data.addShopService(
          widget.shopId,
          ServiceModel(
            id: 'pending',
            name: nm,
            description: _desc.text.trim(),
            price: price,
            durationMinutes: dur,
            iconName: 'scissors',
            isActive: _active,
          ),
        );
      } else {
        await widget.data.updateShopService(
          widget.shopId,
          widget.existing!.copyWith(
            name: nm,
            description: _desc.text.trim(),
            price: price,
            durationMinutes: dur,
            isActive: _active,
          ),
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: AppTheme.divider,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isEdit ? 'Editar Serviço' : 'Novo Serviço',
              style: GoogleFonts.jost(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            _tf(_name, 'Nome do serviço', 'Ex: Corte Clássico'),
            const SizedBox(height: 12),
            _tf(_desc, 'Descrição', 'Descreva brevemente', maxLines: 2),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  child: _tf(_price, 'Preço (R\$)', '45,00',
                      type: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(
                  child: _tf(_duration, 'Duração (min)', '30',
                      type: TextInputType.number)),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              Switch(
                value: _active,
                onChanged: (v) => setState(() => _active = v),
                activeThumbColor: AppTheme.gold,
                inactiveTrackColor: AppTheme.inputBorder,
              ),
              const SizedBox(width: 10),
              Text(
                _active ? 'Serviço ativo' : 'Serviço inativo',
                style: GoogleFonts.jost(
                    color: AppTheme.textSecondary, fontSize: 13),
              ),
            ]),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.gold,
                  foregroundColor: AppTheme.background,
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8))),
                ),
                child: Text(
                  isEdit ? 'SALVAR ALTERAÇÕES' : 'CRIAR SERVIÇO',
                  style: GoogleFonts.jost(
                      fontWeight: FontWeight.w700, letterSpacing: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tf(
    TextEditingController c,
    String lbl,
    String hint, {
    int maxLines = 1,
    TextInputType type = TextInputType.text,
  }) =>
      TextField(
        controller: c,
        maxLines: maxLines,
        keyboardType: type,
        style: GoogleFonts.jost(color: AppTheme.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          labelText: lbl,
          hintText: hint,
          labelStyle:
              GoogleFonts.jost(color: AppTheme.textSecondary, fontSize: 13),
          hintStyle: GoogleFonts.jost(color: AppTheme.textHint, fontSize: 13),
          filled: true,
          fillColor: AppTheme.surfaceElevated,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.inputBorder)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.inputBorder)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.gold)),
        ),
      );
}

// â”€â”€ Empty state â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.gold.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.gold.withValues(alpha: 0.2)),
                ),
                child: const Icon(Icons.content_cut_rounded,
                    color: AppTheme.gold, size: 36),
              ),
              const SizedBox(height: 20),
              Text(
                'Nenhum serviço',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 10),
              Text(
                'Crie seus primeiros serviços\npara que os clientes possam agendar.',
                style: GoogleFonts.jost(
                    color: AppTheme.textSecondary, fontSize: 13, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text('CRIAR PRIMEIRO SERVIÇO',
                      style: GoogleFonts.jost(
                          fontWeight: FontWeight.w700, letterSpacing: 1)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.gold,
                    foregroundColor: AppTheme.background,
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8))),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
