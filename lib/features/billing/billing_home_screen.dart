import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_format.dart';
import '../../core/widgets/numpad.dart';
import '../../data/models/item.dart';
import '../../data/providers.dart';
import '../../data/repositories/bill_repository.dart';
import 'billing_providers.dart';

class BillingHomeScreen extends ConsumerStatefulWidget {
  const BillingHomeScreen({super.key});

  @override
  ConsumerState<BillingHomeScreen> createState() => _BillingHomeScreenState();
}

class _BillingHomeScreenState extends ConsumerState<BillingHomeScreen> {
  final _searchController = TextEditingController();
  final _quantityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      ref.read(itemSearchQueryProvider.notifier).state = _searchController.text;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Color _stockColor(Item item) {
    if (item.isLowStock) return AppColors.alert;
    if (item.currentStock <= item.lowStockThreshold * 1.2) return AppColors.warning;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final itemsAsync = ref.watch(billingItemsProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600 && constraints.maxWidth.isFinite;
        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 2,
                child: _ItemList(
                  itemsAsync: itemsAsync,
                  onItemTap: _onItemTap,
                  searchController: _searchController,
                  stockColor: _stockColor,
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: _CartPanel(
                  cart: cart,
                  onQuantityTap: _showQuantityDialog,
                  onRemoveAt: (i) => ref.read(cartProvider.notifier).removeAt(i),
                  onDiscountTap: _showDiscountDialog,
                  onPayTap: _showPaymentDialog,
                  hasFlexibleHeight: true,
                ),
              ),
            ],
          );
        }
        return Column(
          children: [
            Expanded(
              child: _ItemList(
                itemsAsync: itemsAsync,
                onItemTap: _onItemTap,
                searchController: _searchController,
                stockColor: _stockColor,
              ),
            ),
            const Divider(height: 1),
            SizedBox(
              height: 220,
              child: _CartPanel(
                cart: cart,
                onQuantityTap: _showQuantityDialog,
                onRemoveAt: (i) => ref.read(cartProvider.notifier).removeAt(i),
                onDiscountTap: _showDiscountDialog,
                onPayTap: _showPaymentDialog,
                hasFlexibleHeight: false,
              ),
            ),
          ],
        );
      },
    );
  }

  void _onItemTap(Item item) {
    ref.read(cartProvider.notifier).addItem(item);
  }

  void _showQuantityDialog(int index) {
    final line = ref.read(cartProvider).lines[index];
    final ctrl = TextEditingController(text: line.quantity.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${line.item.nameGu} - ${AppStrings.currentStock}'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                NumpadTextField(
                  controller: ctrl,
                  allowDecimal: true,
                  decoration: const InputDecoration(labelText: 'Quantity'),
                ),
                const SizedBox(height: 16),
                NumpadWidget(
                  controller: ctrl,
                  allowDecimal: true,
                  onSubmit: () {
                    final qty = double.tryParse(ctrl.text) ?? 1;
                    ref.read(cartProvider.notifier).updateQuantity(index, qty);
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDiscountDialog() {
    final ctrl = TextEditingController(text: ref.read(cartProvider).discountAmount.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.discount),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                NumpadTextField(
                  controller: ctrl,
                  allowDecimal: true,
                  decoration: const InputDecoration(labelText: 'Amount'),
                ),
                const SizedBox(height: 16),
                NumpadWidget(
                  controller: ctrl,
                  allowDecimal: true,
                  onSubmit: () {
                    final amt = double.tryParse(ctrl.text) ?? 0;
                    ref.read(cartProvider.notifier).setDiscount(amt);
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPaymentDialog() async {
    final cart = ref.read(cartProvider);
    if (cart.lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.errorGeneric)),
      );
      return;
    }

    final paidCtrl = TextEditingController(text: cart.total.toStringAsFixed(2));
    String paymentMode = 'cash';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text(AppStrings.payNow),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('${AppStrings.total}: ${formatCurrency(cart.total)}'),
                const SizedBox(height: 8),
                NumpadTextField(
                  controller: paidCtrl,
                  allowDecimal: true,
                  decoration: InputDecoration(
                    labelText: AppStrings.amountReceived,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text(AppStrings.cash),
                      selected: paymentMode == 'cash',
                      onSelected: (_) => setState(() => paymentMode = 'cash'),
                    ),
                    ChoiceChip(
                      label: const Text(AppStrings.upi),
                      selected: paymentMode == 'upi',
                      onSelected: (_) => setState(() => paymentMode = 'upi'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text(AppStrings.cancelButton),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(AppStrings.saveButton),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    final paid = double.tryParse(paidCtrl.text) ?? cart.total;
    final billRepo = await ref.read(billRepositoryFutureProvider.future);

    try {
      final billId = await billRepo.createBill(
        customerId: cart.customerId,
        items: cart.lines
            .map((l) => BillItemInput(
                  itemId: l.item.id!,
                  quantity: l.quantity,
                  unitPrice: l.unitPrice,
                ))
            .toList(),
        discountAmount: cart.discountAmount,
        paidAmount: paid,
        paymentMode: paymentMode,
      );

      ref.read(cartProvider.notifier).clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('બીલ #$billId સફળતાપૂર્વક સેવ થયું')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppStrings.errorGeneric} $e')),
        );
      }
    }
  }
}

class _ItemList extends StatelessWidget {
  const _ItemList({
    required this.itemsAsync,
    required this.onItemTap,
    required this.searchController,
    required this.stockColor,
  });

  final AsyncValue<List<Item>> itemsAsync;
  final void Function(Item) onItemTap;
  final TextEditingController searchController;
  final Color Function(Item) stockColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: AppStrings.searchHintItems,
              prefixIcon: const Icon(Icons.search),
            ),
          ),
        ),
        Expanded(
          child: itemsAsync.when(
            data: (items) {
              if (items.isEmpty) {
                return Center(child: Text(AppStrings.noItemsFound));
              }
              return ListView.builder(
                itemCount: items.length,
                itemBuilder: (ctx, i) {
                  final item = items[i];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: stockColor(item),
                      child: const Icon(Icons.inventory_2, color: Colors.white),
                    ),
                    title: Text(item.nameGu),
                    subtitle: Text(
                      '${formatCurrency(item.salePrice)} • ${item.currentStock} ${item.unit}',
                    ),
                    onTap: () => onItemTap(item),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('${AppStrings.errorGeneric} $e')),
          ),
        ),
      ],
    );
  }
}

class _CartPanel extends StatelessWidget {
  const _CartPanel({
    required this.cart,
    required this.onQuantityTap,
    required this.onRemoveAt,
    required this.onDiscountTap,
    required this.onPayTap,
    this.hasFlexibleHeight = true,
  });

  final CartState cart;
  final void Function(int) onQuantityTap;
  final void Function(int) onRemoveAt;
  final VoidCallback onDiscountTap;
  final VoidCallback onPayTap;
  final bool hasFlexibleHeight;

  @override
  Widget build(BuildContext context) {
    final listContent = ListView.builder(
      itemCount: cart.lines.length,
      itemBuilder: (ctx, i) {
        final line = cart.lines[i];
        return ListTile(
          dense: true,
          title: Text(line.item.nameGu),
          subtitle: Text(
            '${line.quantity} x ${formatCurrency(line.unitPrice)} = ${formatCurrency(line.lineTotal)}',
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () => onQuantityTap(i),
              ),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, size: 20),
                onPressed: () => onRemoveAt(i),
              ),
            ],
          ),
        );
      },
    );

    final footer = Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            children: [
              Text(AppStrings.subtotal),
              Text(formatCurrency(cart.subtotal)),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            children: [
              Flexible(
                child: TextButton(
                  onPressed: onDiscountTap,
                  child: Text(AppStrings.discount),
                ),
              ),
              Text(formatCurrency(-cart.discountAmount)),
            ],
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            children: [
              Flexible(
                child: Text(
                  AppStrings.total,
                  style: Theme.of(context).textTheme.titleLarge,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                formatCurrency(cart.total),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: cart.lines.isEmpty ? null : onPayTap,
              icon: const Icon(Icons.payment),
              label: const Text(AppStrings.saveAndPrint),
            ),
          ),
        ],
      ),
    );

    if (hasFlexibleHeight) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              AppStrings.cart,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Expanded(child: listContent),
          footer,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(4),
          child: Text(
            AppStrings.cart,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Expanded(child: listContent),
        footer,
      ],
    );
  }
}
