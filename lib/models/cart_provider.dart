import 'package:flutter/foundation.dart';
import 'barbershop_model.dart';

/// Representa um item no carrinho: produto + quantidade.
class CartItem {
  final ProductModel product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get subtotal => product.price * quantity;

  String get formattedSubtotal =>
      'R\$ ${subtotal.toStringAsFixed(2).replaceAll('.', ',')}';
}

/// Provider que gerencia o estado do carrinho em memória.
/// O carrinho é vinculado a uma única barbearia por vez.
/// Ao tentar adicionar produto de outra barbearia, o provider
/// expõe um [pendingConflict] para que a UI possa confirmar
/// o descarte do carrinho atual antes de trocar.
class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  BarbershopModel? _barbershop;
  int _membershipDiscountPercent = 0;

  /// Percentual de desconto em produtos do plano de assinatura ativo
  /// do cliente na barbearia deste carrinho (0 = não assinante).
  int get membershipDiscountPercent => _membershipDiscountPercent;

  /// Atualiza o desconto de assinatura aplicável ao carrinho atual.
  void setMembershipDiscountPercent(int percent) {
    if (_membershipDiscountPercent == percent) return;
    _membershipDiscountPercent = percent;
    notifyListeners();
  }

  // ── Conflito pendente ──────────────────────────────────────────────────────
  // Quando o usuário tenta adicionar um produto de outra barbearia,
  // guardamos a intenção aqui para resolver via diálogo na UI.
  _PendingAdd? _pendingConflict;
  _PendingAdd? get pendingConflict => _pendingConflict;

  // ── Getters ────────────────────────────────────────────────────────────────
  List<CartItem> get items => List.unmodifiable(_items);
  BarbershopModel? get barbershop => _barbershop;

  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal => _items.fold(0.0, (sum, item) => sum + item.subtotal);

  double get discountAmount => subtotal * _membershipDiscountPercent / 100;

  double get total => subtotal - discountAmount;

  String get formattedSubtotal =>
      'R\$ ${subtotal.toStringAsFixed(2).replaceAll('.', ',')}';

  String get formattedDiscount =>
      '-R\$ ${discountAmount.toStringAsFixed(2).replaceAll('.', ',')}';

  String get formattedTotal =>
      'R\$ ${total.toStringAsFixed(2).replaceAll('.', ',')}';

  bool contains(String productId) =>
      _items.any((i) => i.product.id == productId);

  int quantityOf(String productId) {
    final idx = _items.indexWhere((i) => i.product.id == productId);
    return idx == -1 ? 0 : _items[idx].quantity;
  }

  // ── Verificação de barbearia ──────────────────────────────────────────────
  bool _isSameBarbershop(ProductModel product) =>
      _barbershop == null || _barbershop!.id == product.barbershopId;

  // ── Adicionar ao carrinho ─────────────────────────────────────────────────
  /// Retorna `true` se adicionado com sucesso.
  /// Retorna `false` se houver conflito de barbearia (ver [pendingConflict]).
  bool addItem(ProductModel product, BarbershopModel shop) {
    // Conflito: carrinho tem itens de outra barbearia
    if (_barbershop != null && _barbershop!.id != shop.id && isNotEmpty) {
      _pendingConflict = _PendingAdd(product: product, shop: shop);
      notifyListeners();
      return false;
    }

    _barbershop = shop;

    final idx = _items.indexWhere((i) => i.product.id == product.id);
    if (idx != -1) {
      _items[idx].quantity++;
    } else {
      _items.add(CartItem(product: product));
    }
    notifyListeners();
    return true;
  }

  /// Confirma a troca de barbearia: descarta o carrinho atual e adiciona o produto pendente.
  void confirmConflictSwitch() {
    if (_pendingConflict == null) return;
    final pending = _pendingConflict!;
    _pendingConflict = null;
    clearCart();
    addItem(pending.product, pending.shop);
  }

  /// Cancela a tentativa de troca: descarta o item pendente.
  void cancelConflict() {
    _pendingConflict = null;
    notifyListeners();
  }

  // ── Remover / alterar quantidade ──────────────────────────────────────────
  void removeItem(String productId) {
    _items.removeWhere((i) => i.product.id == productId);
    if (_items.isEmpty) _barbershop = null;
    notifyListeners();
  }

  void incrementItem(String productId) {
    final idx = _items.indexWhere((i) => i.product.id == productId);
    if (idx != -1) {
      _items[idx].quantity++;
      notifyListeners();
    }
  }

  void decrementItem(String productId) {
    final idx = _items.indexWhere((i) => i.product.id == productId);
    if (idx == -1) return;
    if (_items[idx].quantity <= 1) {
      removeItem(productId);
    } else {
      _items[idx].quantity--;
      notifyListeners();
    }
  }

  // ── Limpar ────────────────────────────────────────────────────────────────
  void clearCart() {
    _items.clear();
    _barbershop = null;
    _pendingConflict = null;
    _membershipDiscountPercent = 0;
    notifyListeners();
  }

  // ── Finalizar compra (simulado) ───────────────────────────────────────────
  Future<CartCheckoutResult> checkout() async {
    await Future.delayed(const Duration(milliseconds: 1100));
    final result = CartCheckoutResult(
      barbershopName: _barbershop?.name ?? '',
      itemCount: itemCount,
      total: formattedTotal,
      orderId: DateTime.now().millisecondsSinceEpoch.toString().substring(5),
    );
    clearCart();
    return result;
  }
}

/// Dados do pedido após checkout simulado.
class CartCheckoutResult {
  final String barbershopName;
  final int itemCount;
  final String total;
  final String orderId;

  const CartCheckoutResult({
    required this.barbershopName,
    required this.itemCount,
    required this.total,
    required this.orderId,
  });
}

/// Intenção pendente de adição ao carrinho (conflito de barbearia).
class _PendingAdd {
  final ProductModel product;
  final BarbershopModel shop;
  _PendingAdd({required this.product, required this.shop});
}
