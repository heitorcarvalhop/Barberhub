import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/app_data_provider.dart';
import '../../theme/app_theme.dart';
import '../client/ai_assistant_screen.dart';
import 'admin_overview_screen.dart';
import 'admin_services_screen.dart';
import 'admin_barbers_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  final _pages = const [
    AdminOverviewScreen(),
    AdminServicesScreen(),
    AdminBarbersScreen(),
    AiAssistantScreen(canConfigure: true, showBackButton: false),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Seletor de barbearia (aparece nas abas de Serviços/Barbeiros)
          if (_index == 1 || _index == 2) _BarbershopSelector(),
          _AdminNav(
            currentIndex: _index,
            onTap: (i) => setState(() => _index = i),
          ),
        ],
      ),
    );
  }
}

// ── Seletor de barbearia para admin ──────────────────────────────────────────
class _BarbershopSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppDataProvider>();
    final selected = data.selectedBarbershop ?? data.barbershops.first;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          top: BorderSide(color: AppTheme.divider),
          bottom: BorderSide(color: AppTheme.divider, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.storefront_outlined, size: 14, color: AppTheme.gold),
          const SizedBox(width: 8),
          Text(
            'Barbearia:',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontSize: 11, color: AppTheme.textSecondary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: data.barbershops.map((shop) {
                  final isSel = shop.id == selected.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => data.selectBarbershop(shop),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isSel
                              ? AppTheme.gold.withValues(alpha: 0.15)
                              : AppTheme.surfaceElevated,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSel ? AppTheme.gold : AppTheme.inputBorder,
                            width: isSel ? 1.5 : 1,
                          ),
                        ),
                        child: Text(
                          shop.name.split(' ').first,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color: isSel
                                    ? AppTheme.gold
                                    : AppTheme.textSecondary,
                                fontSize: 11,
                                fontWeight:
                                    isSel ? FontWeight.w700 : FontWeight.w400,
                              ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _AdminNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.divider)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(children: [
            _Item(
                icon: Icons.dashboard_outlined,
                activeIcon: Icons.dashboard_rounded,
                label: 'Visão Geral',
                selected: currentIndex == 0,
                onTap: () => onTap(0)),
            _Item(
                icon: Icons.content_cut_outlined,
                activeIcon: Icons.content_cut_rounded,
                label: 'Serviços',
                selected: currentIndex == 1,
                onTap: () => onTap(1)),
            _Item(
                icon: Icons.people_outline_rounded,
                activeIcon: Icons.people_rounded,
                label: 'Barbeiros',
                selected: currentIndex == 2,
                onTap: () => onTap(2)),
            _Item(
                icon: Icons.auto_awesome_outlined,
                activeIcon: Icons.auto_awesome_rounded,
                label: 'IA',
                selected: currentIndex == 3,
                onTap: () => onTap(3)),
          ]),
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final IconData icon, activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Item(
      {required this.icon,
      required this.activeIcon,
      required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(selected ? activeIcon : icon,
                  key: ValueKey(selected),
                  color: selected ? AppTheme.gold : AppTheme.textHint,
                  size: 22),
            ),
            const SizedBox(height: 4),
            Text(label,
                style: GoogleFonts.jost(
                    fontSize: 10,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? AppTheme.gold : AppTheme.textHint),
                overflow: TextOverflow.ellipsis),
          ]),
        ),
      );
}
