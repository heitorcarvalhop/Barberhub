import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:barber_hub/core/theme/app_theme.dart';
import 'package:barber_hub/features/barber_shop/domain/entities/shop_settings_entity.dart';
import 'package:barber_hub/features/barber_shop/domain/entities/working_hours_entity.dart';
import 'package:barber_hub/features/barber_shop/presentation/providers/shop_management_providers.dart';
import 'package:barber_hub/features/barber_shop/presentation/widgets/bs_widgets.dart';

class BarberShopSettingsScreen extends ConsumerStatefulWidget {
  const BarberShopSettingsScreen({super.key});
  @override
  ConsumerState<BarberShopSettingsScreen> createState() => _State();
}

class _State extends ConsumerState<BarberShopSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  Map<int, WorkingHoursEntity> _hours = {};
  bool _loaded = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _syncFromState(ShopSettingsEntity s) {
    if (_loaded) return;
    _loaded = true;
    _nameCtrl.text = s.name;
    _addressCtrl.text = s.address;
    _phoneCtrl.text = s.phone;
    setState(() => _hours = Map.from(s.workingHours));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final settings = ref.read(shopManagementProvider).settings;
    if (settings == null) return;

    try {
      await ref.read(shopManagementProvider.notifier).saveSettings(
            settings.copyWith(
              name: _nameCtrl.text.trim(),
              address: _addressCtrl.text.trim(),
              phone: _phoneCtrl.text.trim(),
              workingHours: _hours,
            ),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Row(children: [
          Icon(Icons.check_circle_outline, color: AppTheme.gold, size: 18),
          SizedBox(width: 10),
          Text('Configurações salvas!'),
        ]),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline, color: AppTheme.error, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(e.toString())),
        ]),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shopManagementProvider);
    if (state.settings != null) _syncFromState(state.settings!);

    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: CustomScrollView(slivers: [
            // â”€â”€ Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            const SliverToBoxAdapter(
                child: Column(children: [
              BsScreenHeader(eyebrow: 'barbearia', title: 'Configurações'),
              SizedBox(height: 28),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: BsSectionHeader(title: 'Informações gerais'),
              ),
            ])),

            // â”€â”€ Campos básicos â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            SliverToBoxAdapter(
                child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
              child: Column(children: [
                BsTextField(
                  label: 'Nome da barbearia',
                  controller: _nameCtrl,
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      (v?.trim().isEmpty ?? true) ? 'Obrigatório' : null,
                ),
                const SizedBox(height: 14),
                BsTextField(
                  label: 'Localização / Endereço',
                  hint: 'Ex: Rua das Flores, 123 â€“ Centro',
                  controller: _addressCtrl,
                  maxLines: 2,
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      (v?.trim().isEmpty ?? true) ? 'Obrigatório' : null,
                ),
                const SizedBox(height: 14),
                BsTextField(
                  label: 'Telefone',
                  hint: '(11) 99999-9999',
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                ),
              ]),
            )),

            // â”€â”€ Horários por dia â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            const SliverToBoxAdapter(
                child: Padding(
              padding: EdgeInsets.fromLTRB(24, 28, 24, 14),
              child: BsSectionHeader(title: 'Horário de funcionamento'),
            )),

            SliverList(
                delegate: SliverChildBuilderDelegate(
              (_, i) {
                final weekday = i + 1;
                final h =
                    _hours[weekday] ?? const WorkingHoursEntity(isOpen: true);
                return Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
                  child: _DayRow(
                    weekday: weekday,
                    hours: h,
                    onChanged: (updated) =>
                        setState(() => _hours[weekday] = updated),
                  ),
                );
              },
              childCount: 7,
            )),

            // â”€â”€ Salvar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            SliverToBoxAdapter(
                child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: BsSaveButton(
                label: 'Salvar configurações',
                onPressed: _save,
                isLoading: state.isSaving,
              ),
            )),
          ]),
        ),
      ),
    );
  }
}

// â”€â”€ Day Row â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _DayRow extends StatelessWidget {
  final int weekday;
  final WorkingHoursEntity hours;
  final ValueChanged<WorkingHoursEntity> onChanged;
  const _DayRow(
      {required this.weekday, required this.hours, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final name = WorkingHoursEntity.weekdayNames[weekday] ?? '';
    return BsCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(children: [
        Row(children: [
          SizedBox(
            width: 72,
            child: Text(name,
                style: GoogleFonts.jost(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ),
          const Spacer(),
          BsStatusBadge(
              isActive: hours.isOpen,
              activeLabel: 'Aberto',
              inactiveLabel: 'Fechado'),
          const SizedBox(width: 10),
          Switch.adaptive(
            value: hours.isOpen,
            activeColor: AppTheme.gold,
            onChanged: (v) => onChanged(hours.copyWith(isOpen: v)),
          ),
        ]),
        if (hours.isOpen) ...[
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
                child: _TimePicker(
              label: 'Abertura',
              value: hours.openTime,
              onChanged: (t) => onChanged(hours.copyWith(openTime: t)),
            )),
            const SizedBox(width: 12),
            Expanded(
                child: _TimePicker(
              label: 'Fechamento',
              value: hours.closeTime,
              onChanged: (t) => onChanged(hours.copyWith(closeTime: t)),
            )),
          ]),
        ],
      ]),
    );
  }
}

class _TimePicker extends StatelessWidget {
  final String label, value;
  final ValueChanged<String> onChanged;
  const _TimePicker(
      {required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () async {
          final parts = value.split(':');
          final picked = await showTimePicker(
            context: context,
            initialTime: TimeOfDay(
                hour: int.parse(parts[0]), minute: int.parse(parts[1])),
            builder: (ctx, child) => Theme(
              data: Theme.of(ctx).copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: AppTheme.gold,
                  onPrimary: AppTheme.background,
                  surface: AppTheme.surfaceElevated,
                  onSurface: AppTheme.textPrimary,
                ),
                dialogTheme:
                    const DialogThemeData(backgroundColor: AppTheme.surface),
              ),
              child: child!,
            ),
          );
          if (picked != null) {
            onChanged(
                '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.inputBorder),
          ),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(label,
                style:
                    GoogleFonts.jost(color: AppTheme.textHint, fontSize: 11)),
            Text(value,
                style: GoogleFonts.jost(
                    color: AppTheme.gold,
                    fontSize: 14,
                    fontWeight: FontWeight.w700)),
          ]),
        ),
      );
}
