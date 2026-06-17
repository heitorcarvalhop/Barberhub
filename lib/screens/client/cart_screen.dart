import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/membership/presentation/providers/membership_providers.dart';
import '../../models/cart_provider.dart';
import '../../models/product_model.dart';
import '../../theme/app_theme.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncMembershipDiscount());
  }

  Future<void> _syncMembershipDiscount() async {
    final cart = context.read<CartProvider>();
    final shopId = cart.barbershop?.id;
    if (shopId == null) return;

    final authState = ref.read(authNotifierProvider);
    if (authState is! AuthAuthenticated) return;

    await ref
        .read(clientMembershipProvider.notifier)
        .load(clientId: authState.user.id, shopId: shopId);
    if (!mounted) return;

    final membership =
        ref.read(clientMembershipProvider).activeForShop(shopId);
    cart.setMembershipDiscountPercent(
        membership?.plan.productDiscountPercent ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 18, color: AppTheme.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  Text(
                    'CARRINHO',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppTheme.textHint,
                          fontSize: 11,
                          letterSpacing: 3,
                        ),
                  ),
                  if (cart.isNotEmpty) ...[
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () => _confirmClear(context, cart),
                      child: Text(
                        'Limpar',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppTheme.error, fontSize: 13),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ── Barbearia badge ────────────────────────────────────────
            if (cart.barbershop != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: _BarbershopBadge(
                    name: cart.barbershop!.name,
                    iconData: cart.barbershop!.coverIconData),
              ),

            // ── Conteúdo ────────────────────────────────────────────────
            Expanded(
              child: cart.isEmpty ? _EmptyCart() : _CartItemsList(cart: cart),
            ),

            // ── Footer com total + checkout ────────────────────────────
            if (cart.isNotEmpty) _CartFooter(cart: cart),
          ],
        ),
      ),
    );
  }

  void _confirmClear(BuildContext context, CartProvider cart) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Limpar carrinho',
            style: Theme.of(context).textTheme.titleLarge),
        content: Text('Tem certeza que deseja remover todos os itens?',
            style: Theme.of(context).textTheme.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              cart.clearCart();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );
  }
}

// ── Barbershop badge ──────────────────────────────────────────────────────────
class _BarbershopBadge extends StatelessWidget {
  final String name;
  final IconData iconData;
  const _BarbershopBadge({required this.name, required this.iconData});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.gold.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.gold.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(iconData, size: 22, color: AppTheme.gold),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pedido para',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontSize: 10, color: AppTheme.textHint),
                ),
                Text(
                  name,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: AppTheme.gold, fontSize: 14),
                ),
              ],
            ),
          ),
          const Icon(Icons.storefront_outlined, size: 14, color: AppTheme.gold),
        ],
      ),
    );
  }
}

// ── Empty cart ────────────────────────────────────────────────────────────────
class _EmptyCart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppTheme.inputBorder),
              ),
              child: const Icon(Icons.shopping_bag_outlined,
                  color: AppTheme.textHint, size: 36),
            ),
            const SizedBox(height: 24),
            Text('Carrinho vazio',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Adicione produtos de uma barbearia\npara continuar.',
              style:
                  Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Items list ────────────────────────────────────────────────────────────────
class _CartItemsList extends StatelessWidget {
  final CartProvider cart;
  const _CartItemsList({required this.cart});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      itemCount: cart.items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) =>
          _CartItemCard(item: cart.items[i], cart: cart),
    );
  }
}

// ── Cart item card ────────────────────────────────────────────────────────────
class _CartItemCard extends StatelessWidget {
  final CartItem item;
  final CartProvider cart;
  const _CartItemCard({required this.item, required this.cart});

  @override
  Widget build(BuildContext context) {
    final product = item.product;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.inputBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Emoji / imagem
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppTheme.gold.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.gold.withValues(alpha: 0.15)),
              ),
              child: Center(
                child: Text(product.imageEmoji,
                    style: const TextStyle(fontSize: 26)),
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontSize: 14)),
                  const SizedBox(height: 3),
                  Text(
                    '${product.brand} · ${product.category.label}',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontSize: 11, color: AppTheme.textHint),
                  ),
                  const SizedBox(height: 8),

                  // Controle de quantidade + preço
                  Row(
                    children: [
                      // Qty controls
                      _QtyControl(
                        quantity: item.quantity,
                        onDecrement: () => cart.decrementItem(product.id),
                        onIncrement: () => cart.incrementItem(product.id),
                      ),
                      const Spacer(),
                      // Subtotal
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            item.formattedSubtotal,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: AppTheme.gold,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          if (item.quantity > 1)
                            Text(
                              '${product.formattedPrice} cada',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                      fontSize: 10, color: AppTheme.textHint),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Remover
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => cart.removeItem(product.id),
              child: const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.close_rounded,
                    size: 16, color: AppTheme.textHint),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Qty control ───────────────────────────────────────────────────────────────
class _QtyControl extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrement, onIncrement;
  const _QtyControl({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _QtyBtn(icon: Icons.remove_rounded, onTap: onDecrement),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            '$quantity',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontSize: 15, color: AppTheme.textPrimary),
          ),
        ),
        _QtyBtn(icon: Icons.add_rounded, onTap: onIncrement),
      ],
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppTheme.gold.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.gold.withValues(alpha: 0.25)),
        ),
        child: Icon(icon, size: 14, color: AppTheme.gold),
      ),
    );
  }
}

// ── Cart footer ───────────────────────────────────────────────────────────────
class _CartFooter extends StatefulWidget {
  final CartProvider cart;
  const _CartFooter({required this.cart});

  @override
  State<_CartFooter> createState() => _CartFooterState();
}

class _CartFooterState extends State<_CartFooter> {
  bool _loading = false;

  Future<void> _checkout() async {
    setState(() => _loading = true);

    // Captura o navigator ANTES do await.
    // Depois do checkout() o carrinho é limpo → _CartFooter pode ser
    // desmontado → context fica inválido. Usar o navigator capturado
    // previamente garante que as chamadas de pop funcionem corretamente.
    final navigator = Navigator.of(context);

    final result = await widget.cart.checkout();

    // Não usar `mounted` aqui: o widget pode ter sido desmontado
    // exatamente porque o carrinho ficou vazio. Usamos `navigator`
    // capturado antes, que permanece válido.
    if (_loading) {
      try {
        setState(() => _loading = false);
      } catch (_) {
        // widget já desmontado — ignora
      }
    }

    _showSuccessDialog(navigator, result);
  }

  void _showSuccessDialog(NavigatorState navigator, CartCheckoutResult result) {
    // Usa o navigator capturado (ainda válido) para abrir o dialog.
    // O builder recebe seu próprio BuildContext (dialogContext) do dialog,
    // garantindo que nunca dependemos do context desmontado do _CartFooter.
    navigator.push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: false,
        barrierColor: Colors.black54,
        pageBuilder: (dialogContext, _, __) => _CheckoutSuccessDialog(
          result: result,
          onContinue: () {
            // Fecha o dialog (pop do PageRoute do dialog)
            navigator.pop();
            // Fecha a CartScreen (pop da rota do carrinho)
            navigator.pop();
          },
        ),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = widget.cart;

    return Container(
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, 16 + MediaQuery.of(context).viewPadding.bottom),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.divider)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (cart.membershipDiscountPercent > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: AppTheme.gold.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.gold.withOpacity(0.25)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.workspace_premium_rounded,
                          color: AppTheme.gold, size: 14),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Desconto assinatura (-${cart.membershipDiscountPercent}%)',
                          style: GoogleFonts.jost(
                              color: AppTheme.gold,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        cart.formattedDiscount,
                        style: GoogleFonts.jost(
                            color: AppTheme.gold,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('Subtotal',
                          style: GoogleFonts.jost(
                              color: AppTheme.textHint, fontSize: 11)),
                      const Spacer(),
                      Text(cart.formattedSubtotal,
                          style: GoogleFonts.jost(
                              color: AppTheme.textHint, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
          ],
          // Resumo
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${cart.itemCount} ${cart.itemCount == 1 ? 'item' : 'itens'}',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Total do pedido',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontSize: 11, color: AppTheme.textHint),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                cart.formattedTotal,
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(color: AppTheme.gold, fontSize: 26),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Botão de checkout
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _checkout,
              icon: _loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppTheme.background))
                  : const Icon(Icons.storefront_rounded, size: 18),
              label: Text(
                _loading ? 'PROCESSANDO...' : 'FINALIZAR PEDIDO',
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label, value;
  final bool highlight;
  const _ResultRow(
      {required this.label, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontSize: 13, color: AppTheme.textSecondary)),
        const Spacer(),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: highlight ? 16 : 14,
              color: highlight ? AppTheme.gold : AppTheme.textPrimary,
              fontWeight: highlight ? FontWeight.w700 : FontWeight.w500),
        ),
      ],
    );
  }
}

// ── Dialog de sucesso — widget standalone, sem depender de contexto externo ───
class _CheckoutSuccessDialog extends StatelessWidget {
  final CartCheckoutResult result;
  final VoidCallback onContinue;

  const _CheckoutSuccessDialog({
    required this.result,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Dialog(
            backgroundColor: AppTheme.surfaceElevated,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Ícone de sucesso
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.gold.withValues(alpha: 0.12),
                      border: Border.all(
                          color: AppTheme.gold.withValues(alpha: 0.3), width: 2),
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: AppTheme.gold, size: 36),
                  ),
                  const SizedBox(height: 20),

                  Text('Pedido realizado!',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 10),

                  // Detalhes do pedido
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.inputBorder),
                    ),
                    child: Column(
                      children: [
                        _ResultRow(
                            label: 'Pedido', value: '#${result.orderId}'),
                        const SizedBox(height: 8),
                        _ResultRow(
                            label: 'Barbearia', value: result.barbershopName),
                        const SizedBox(height: 8),
                        _ResultRow(
                            label: 'Itens', value: '${result.itemCount}'),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Divider(height: 1, color: AppTheme.divider),
                        ),
                        _ResultRow(
                            label: 'Total',
                            value: result.total,
                            highlight: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  Text(
                    'Retire seu pedido na barbearia\nno momento do atendimento.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                          color: AppTheme.textSecondary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onContinue,
                      child: const Text('CONTINUAR COMPRANDO'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Barra inferior persistente do Carrinho ────────────────────────────────────
// Garante que a nav bar permaneça visível mesmo na tela de carrinho (rota push).
class _CartBottomNav extends StatelessWidget {
  final BuildContext context;
  const _CartBottomNav({required this.context});

  @override
  Widget build(BuildContext _) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          border: Border(top: BorderSide(color: AppTheme.divider, width: 1)),
        ),
        child: SafeArea(
            top: false,
            child: SizedBox(
                height: 64,
                child: Row(children: [
                  _NavBtn(
                      icon: Icons.storefront_outlined,
                      label: 'Início',
                      onTap: () {
                        Navigator.of(context).pop();
                      }),
                  _NavBtn(
                      icon: Icons.calendar_today_outlined,
                      label: 'Agenda',
                      onTap: () {
                        Navigator.of(context).pop();
                      }),
                  _NavBtn(
                      icon: Icons.workspace_premium_outlined,
                      label: 'Assinatura',
                      onTap: () {
                        Navigator.of(context).pop();
                      }),
                  const _NavBtn(
                      icon: Icons.shopping_bag_rounded,
                      label: 'Carrinho',
                      selected: true,
                      onTap: null),
                  _NavBtn(
                      icon: Icons.person_outline_rounded,
                      label: 'Perfil',
                      onTap: () {
                        Navigator.of(context).pop();
                      }),
                ]))),
      );
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool selected;
  const _NavBtn(
      {required this.icon,
      required this.label,
      this.onTap,
      this.selected = false});

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon,
                color: selected ? AppTheme.gold : AppTheme.textHint, size: 22),
            const SizedBox(height: 4),
            Text(label,
                style: GoogleFonts.jost(
                    fontSize: 10,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? AppTheme.gold : AppTheme.textHint,
                    letterSpacing: 0.3)),
          ]),
        ),
      );
}
