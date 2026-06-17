import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:barber_hub/core/theme/app_theme.dart';
import 'package:barber_hub/features/barber_shop/presentation/providers/shop_management_providers.dart';
import 'package:barber_hub/features/barber_shop/presentation/widgets/bs_widgets.dart';
import 'package:barber_hub/features/client/data/models/barber_model.dart';
import 'package:barber_hub/utils/validators.dart';

class BarberShopBarbersScreen extends ConsumerWidget {
  const BarberShopBarbersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(shopManagementProvider);
    final barbers = state.barbers;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(
              child: Column(children: [
            BsScreenHeader(
              eyebrow: 'gestao',
              title: 'Barbeiros',
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Text('${barbers.length} cadastrados',
                      style: GoogleFonts.jost(
                          color: AppTheme.textSecondary, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ])),
          if (barbers.isEmpty)
            SliverFillRemaining(
                child: BsEmptyState(
              icon: Icons.person_off_outlined,
              message: 'Nenhum barbeiro cadastrado.\nAdicione o primeiro!',
              actionLabel: 'Adicionar barbeiro',
              onAction: () => _showBarberModal(context, ref),
            ))
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                (_, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _BarberTile(
                    barber: barbers[i],
                    onEdit: () =>
                        _showBarberModal(context, ref, barber: barbers[i]),
                    onToggle: () => ref
                        .read(shopManagementProvider.notifier)
                        .updateBarber(
                          barbers[i].copyWith(isActive: !barbers[i].isActive),
                        ),
                  ),
                ),
                childCount: barbers.length,
              )),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ]),
      ),
      floatingActionButton: BsGoldFab(
        onPressed: () => _showBarberModal(context, ref),
        tooltip: 'Adicionar barbeiro',
      ),
    );
  }

  void _showBarberModal(BuildContext context, WidgetRef ref,
      {BarberModel? barber}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: _BarberModal(barber: barber, ref: ref),
      ),
    );
  }
}

// Barber Tile
class _BarberTile extends StatelessWidget {
  final BarberModel barber;
  final VoidCallback onEdit, onToggle;
  const _BarberTile(
      {required this.barber, required this.onEdit, required this.onToggle});

  @override
  Widget build(BuildContext context) => BsCard(
        child: Row(children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: barber.isActive
                  ? AppTheme.gold.withValues(alpha: 0.12)
                  : AppTheme.surface,
              border: Border.all(
                  color: barber.isActive
                      ? AppTheme.gold.withValues(alpha: 0.3)
                      : AppTheme.divider),
            ),
            child: Center(
                child: Text(barber.avatarInitials,
                    style: GoogleFonts.cormorantGaramond(
                        color:
                            barber.isActive ? AppTheme.gold : AppTheme.textHint,
                        fontSize: 16,
                        fontWeight: FontWeight.w700))),
          ),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(barber.name,
                    style: GoogleFonts.jost(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(barber.specialty,
                    style: GoogleFonts.jost(
                        color: AppTheme.textSecondary, fontSize: 12)),
                const SizedBox(height: 6),
                Row(children: [
                  BsStatusBadge(isActive: barber.isActive),
                  const SizedBox(width: 8),
                  const Icon(Icons.star_rounded,
                      size: 12, color: AppTheme.gold),
                  const SizedBox(width: 3),
                  Text(barber.rating.toStringAsFixed(1),
                      style: GoogleFonts.jost(
                          color: AppTheme.textSecondary, fontSize: 11)),
                ]),
              ])),
          // Actions
          Column(mainAxisSize: MainAxisSize.min, children: [
            IconButton(
                icon: const Icon(Icons.edit_rounded,
                    size: 18, color: AppTheme.textSecondary),
                onPressed: onEdit),
            IconButton(
              icon: Icon(
                  barber.isActive
                      ? Icons.pause_circle_outline
                      : Icons.play_circle_outline,
                  size: 18,
                  color: barber.isActive
                      ? AppTheme.error
                      : const Color(0xFF2ECC71)),
              onPressed: onToggle,
              tooltip: barber.isActive ? 'Desativar' : 'Ativar',
            ),
          ]),
        ]),
      );
}

// Barber Modal
class _BarberModal extends ConsumerStatefulWidget {
  final BarberModel? barber;
  final WidgetRef ref;
  const _BarberModal({this.barber, required this.ref});

  @override
  ConsumerState<_BarberModal> createState() => _BarberModalState();
}

class _BarberModalState extends ConsumerState<_BarberModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _specialtyCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _isActive = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  bool get _isEditing => widget.barber != null;

  @override
  void initState() {
    super.initState();
    if (widget.barber != null) {
      _nameCtrl.text = widget.barber!.name;
      _specialtyCtrl.text = widget.barber!.specialty;
      _phoneCtrl.text = widget.barber!.phone;
      _isActive = widget.barber!.isActive;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _specialtyCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'XX';
  }

  Future<void> _save() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) return;
    final notifier = ref.read(shopManagementProvider.notifier);
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      if (_isEditing) {
        await notifier
            .updateBarber(widget.barber!.copyWith(
              name: _nameCtrl.text.trim(),
              specialty: _specialtyCtrl.text.trim(),
              phone: _phoneCtrl.text.trim(),
              avatarInitials: _initials(_nameCtrl.text.trim()),
              isActive: _isActive,
            ))
            .timeout(const Duration(seconds: 13));
      } else {
        await notifier
            .addBarber(BarberModel(
              id: _uuidV4(),
              name: _nameCtrl.text.trim(),
              specialty: _specialtyCtrl.text.trim(),
              phone: _phoneCtrl.text.trim(),
              avatarInitials: _initials(_nameCtrl.text.trim()),
              isActive: _isActive,
            ))
            .timeout(const Duration(seconds: 13));
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      final message = e is TimeoutException
          ? 'Tempo esgotado ao salvar. Confira as permissoes da tabela barbers no Supabase.'
          : e.toString();
      setState(() => _errorMessage = message);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _uuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    String hex(int value) => value.toRadixString(16).padLeft(2, '0');
    final chars = bytes.map(hex).join();
    return '${chars.substring(0, 8)}-${chars.substring(8, 12)}-${chars.substring(12, 16)}-${chars.substring(16, 20)}-${chars.substring(20)}';
  }

  @override
  Widget build(BuildContext context) {
    return BsModalSheet(
      title: _isEditing ? 'Editar barbeiro' : 'Novo barbeiro',
      child: Form(
        key: _formKey,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          BsTextField(
              label: 'Nome completo',
              controller: _nameCtrl,
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v?.trim().isEmpty ?? true) ? 'Obrigatorio' : null),
          const SizedBox(height: 14),
          BsTextField(
              label: 'Especialidade',
              hint: 'Ex: Cortes Classicos & Fade',
              controller: _specialtyCtrl,
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v?.trim().isEmpty ?? true) ? 'Obrigatorio' : null),
          const SizedBox(height: 14),
          BsTextField(
              label: 'Telefone',
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              validator: Validators.phone,
              inputFormatters: Validators.phoneInputFormatters()),
          const SizedBox(height: 14),
          Row(children: [
            Text('Status:',
                style: GoogleFonts.jost(
                    color: AppTheme.textSecondary, fontSize: 14)),
            const SizedBox(width: 12),
            BsStatusBadge(isActive: _isActive),
            const Spacer(),
            Switch.adaptive(
                value: _isActive,
                activeColor: AppTheme.gold,
                onChanged: (v) => setState(() => _isActive = v)),
          ]),
          const SizedBox(height: 24),
          if (_errorMessage != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.error.withOpacity(0.35)),
              ),
              child: Text(
                _errorMessage!,
                style: GoogleFonts.jost(
                  color: AppTheme.error,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          BsSaveButton(
              label: _isEditing ? 'Salvar alteracoes' : 'Adicionar barbeiro',
              onPressed: _save,
              isLoading: _isSubmitting),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}
