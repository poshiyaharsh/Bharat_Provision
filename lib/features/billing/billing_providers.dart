import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/item.dart';
import '../../data/providers.dart';

class CartLine {
  CartLine({
    required this.item,
    required this.quantity,
    required this.unitPrice,
  });
  final Item item;
  double quantity;
  final double unitPrice;

  double get lineTotal => quantity * unitPrice;
}

class CartState {
  CartState({this.lines = const [], this.discountAmount = 0, this.customerId});

  final List<CartLine> lines;
  final double discountAmount;
  final int? customerId;

  double get subtotal => lines.fold(0, (s, l) => s + l.lineTotal);
  double get total => subtotal - discountAmount;

  CartState copyWith({
    List<CartLine>? lines,
    double? discountAmount,
    int? customerId,
  }) {
    return CartState(
      lines: lines ?? this.lines,
      discountAmount: discountAmount ?? this.discountAmount,
      customerId: customerId ?? this.customerId,
    );
  }
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(CartState());

  void addItem(Item item, {double quantity = 1}) {
    final existing = state.lines.where((l) => l.item.id == item.id).toList();
    if (existing.isNotEmpty) {
      final idx = state.lines.indexWhere((l) => l.item.id == item.id);
      final updated = List<CartLine>.from(state.lines);
      updated[idx] = CartLine(
        item: item,
        quantity: updated[idx].quantity + quantity,
        unitPrice: item.salePrice,
      );
      state = state.copyWith(lines: updated);
    } else {
      state = state.copyWith(
        lines: [
          ...state.lines,
          CartLine(item: item, quantity: quantity, unitPrice: item.salePrice),
        ],
      );
    }
  }

  void updateQuantity(int index, double qty) {
    if (qty <= 0) {
      removeAt(index);
      return;
    }
    final updated = List<CartLine>.from(state.lines);
    updated[index] = CartLine(
      item: updated[index].item,
      quantity: qty,
      unitPrice: updated[index].unitPrice,
    );
    state = state.copyWith(lines: updated);
  }

  void removeAt(int index) {
    final updated = List<CartLine>.from(state.lines)..removeAt(index);
    state = state.copyWith(lines: updated);
  }

  void setDiscount(double amount) {
    state = state.copyWith(discountAmount: amount);
  }

  void setCustomer(int? id) {
    state = state.copyWith(customerId: id);
  }

  void clear() {
    state = CartState();
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});

final itemSearchQueryProvider = StateProvider<String>((ref) => '');

final billingItemsProvider = FutureProvider<List<Item>>((ref) async {
  final repo = await ref.watch(itemRepositoryFutureProvider.future);
  final query = ref.watch(itemSearchQueryProvider);
  return repo.search(query, lowStockOnly: false);
});
