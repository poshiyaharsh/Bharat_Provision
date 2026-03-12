import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart'; // TODO: Add to pubspec.yaml

import '../../core/constants/app_strings.dart' as strings;
import '../../core/utils/currency_format.dart';
import '../../core/utils/weight_calculator.dart';
import '../../shared/models/product_model.dart';
import '../../shared/providers/product_provider.dart';
import 'billing_providers.dart';

/// Simplified single-screen billing - Create bills and print them.
class BillingHomeScreen extends ConsumerStatefulWidget {
  const BillingHomeScreen({super.key});

  @override
  ConsumerState<BillingHomeScreen> createState() => _BillingHomeScreenState();
}

class _BillingHomeScreenState extends ConsumerState<BillingHomeScreen> {
  final _searchController = TextEditingController();
  List<BillLineItem> _billLines = [];
  double _discount = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  double get _subtotal => _billLines.fold(0, (sum, line) => sum + line.amount);
  double get _total => _subtotal - _discount;

  void _addProductToBill(Product product) async {
    double amountPaid = product.sellPrice;
    double weightGrams = 1000;
    String mode = 'amount';

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            double? calculatedWeight;
            double? calculatedAmount;

            if (mode == 'amount') {
              calculatedWeight = WeightCalculator.calculateWeightFromAmount(
                amountPaid: amountPaid,
                sellPricePerKg: product.sellPrice,
              );
            } else {
              calculatedAmount = WeightCalculator.calculateAmountFromWeight(
                weightGrams: weightGrams,
                sellPricePerKg: product.sellPrice,
              );
            }

            return AlertDialog(
              title: Text(product.nameGujarati),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('₹ રૂપિયાથી'),
                        selected: mode == 'amount',
                        onSelected: (_) => setState(() => mode = 'amount'),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('⚖ વજનથી'),
                        selected: mode == 'weight',
                        onSelected: (_) => setState(() => mode = 'weight'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (mode == 'amount') ...[
                    TextField(
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: '₹ રકમ દાખલ કરો',
                      ),
                      onChanged: (v) {
                        final parsed = double.tryParse(v);
                        if (parsed != null) setState(() => amountPaid = parsed);
                      },
                    ),
                    const SizedBox(height: 8),
                    if (calculatedWeight != null)
                      Text(
                        'આપો: ${WeightCalculator.formatWeight(calculatedWeight)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                          fontSize: 16,
                        ),
                      ),
                  ] else ...[
                    TextField(
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'ગ્રામમાં વજન દાખલ કરો',
                      ),
                      onChanged: (v) {
                        final parsed = double.tryParse(v);
                        if (parsed != null)
                          setState(() => weightGrams = parsed);
                      },
                    ),
                    const SizedBox(height: 8),
                    if (calculatedAmount != null)
                      Text(
                        'રકમ: ${formatCurrency(calculatedAmount)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                          fontSize: 16,
                        ),
                      ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text(strings.AppStrings.cancelButton),
                ),
                ElevatedButton(
                  onPressed: () {
                    double finalAmount, finalQty;
                    if (mode == 'amount') {
                      finalQty = WeightCalculator.calculateWeightFromAmount(
                        amountPaid: amountPaid,
                        sellPricePerKg: product.sellPrice,
                      );
                      finalAmount = amountPaid;
                    } else {
                      finalAmount = WeightCalculator.calculateAmountFromWeight(
                        weightGrams: weightGrams,
                        sellPricePerKg: product.sellPrice,
                      );
                      finalQty = weightGrams;
                    }
                    setState(() {
                      _billLines.add(
                        BillLineItem(
                          product: product,
                          qtyGrams: finalQty,
                          amount: finalAmount,
                        ),
                      );
                    });
                    Navigator.of(ctx).pop();
                  },
                  child: const Text(strings.AppStrings.addButton),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _removeLine(int index) {
    setState(() => _billLines.removeAt(index));
  }

  void _setDiscount() async {
    final controller = TextEditingController(
      text: _discount.toStringAsFixed(2),
    );
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ડિસ્કાઉન્ટ સેટ કરો'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: '₹ રકમ'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(strings.AppStrings.cancelButton),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _discount = double.tryParse(controller.text) ?? 0);
              Navigator.of(ctx).pop();
            },
            child: const Text(strings.AppStrings.saveButton),
          ),
        ],
      ),
    );
  }

  Future<void> _printBill() async {
    if (_billLines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('બિલ ખાલી છે. કૃપया આઇટમ ઉમેરો.')),
      );
      return;
    }
    try {
      final billText = _generateBillText();
      // TODO: Integrate with print_bluetooth_thermal package
      // For now, show bill in a dialog
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('બિલ ટેક્સ્ટ'),
          content: SingleChildScrollView(
            child: Text(
              billText,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('બંધ કરો'),
            ),
          ],
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('બિલ તૈયાર! (Bluetooth print pending integration)'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ભૂલ: $e')));
    }
  }

  String _generateBillText() {
    StringBuffer buffer = StringBuffer();
    buffer.writeln('===============================');
    buffer.writeln('            બિલ');
    buffer.writeln('===============================\n');
    for (var line in _billLines) {
      buffer.writeln('${line.product.nameGujarati}');
      buffer.writeln(
        '  ${WeightCalculator.formatWeight(line.qtyGrams)}  ${formatCurrency(line.amount)}',
      );
    }
    buffer.writeln('\n-------------------------------');
    buffer.writeln('કુલ: ${formatCurrency(_subtotal)}');
    if (_discount > 0) buffer.writeln('ડિસ્ક: -${formatCurrency(_discount)}');
    buffer.writeln('-------------------------------');
    buffer.writeln('દેય: ${formatCurrency(_total)}');
    buffer.writeln('===============================');
    buffer.writeln('ધન્યવાદ!');
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    return Scaffold(
      appBar: AppBar(
        title: const Text(strings.AppStrings.billingTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _printBill,
            tooltip: 'બિલ છાપો',
          ),
        ],
      ),
      body: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(flex: 2, child: _buildProductPanel()),
        const VerticalDivider(width: 1),
        Expanded(flex: 3, child: _buildBillPanel()),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        Expanded(flex: 2, child: _buildProductPanel()),
        const Divider(height: 1),
        Expanded(flex: 3, child: _buildBillPanel()),
      ],
    );
  }

  Widget _buildProductPanel() {
    final state = ref.watch(productProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: strings.AppStrings.searchHintProducts,
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              if (value.trim().isEmpty) {
                ref.read(productProvider.notifier).loadAllProducts();
              } else {
                ref.read(productProvider.notifier).searchProducts(value);
              }
            },
          ),
        ),
        Expanded(
          child: state.when(
            data: (products) {
              if (products.isEmpty) {
                return const Center(
                  child: Text(strings.AppStrings.noProductsFound),
                );
              }
              return ListView.builder(
                itemCount: products.length,
                itemBuilder: (ctx, i) {
                  final p = products[i];
                  return ListTile(
                    leading: const Icon(Icons.inventory_2),
                    title: Text(p.nameGujarati),
                    subtitle: Text('₹${p.sellPrice.toStringAsFixed(2)}'),
                    onTap: () => _addProductToBill(p),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) =>
                Center(child: Text('${strings.AppStrings.errorGeneric} $e')),
          ),
        ),
      ],
    );
  }

  Widget _buildBillPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: const Text(
            'હાલનો બિલ',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        const Divider(height: 1),
        if (_billLines.isEmpty)
          const Expanded(child: Center(child: Text('કોઇ આઇટમ નહીં')))
        else
          Expanded(
            child: ListView.builder(
              itemCount: _billLines.length,
              itemBuilder: (ctx, i) {
                final line = _billLines[i];
                return Dismissible(
                  key: Key(i.toString()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => _removeLine(i),
                  child: ListTile(
                    title: Text(line.product.nameGujarati),
                    subtitle: Text(
                      WeightCalculator.formatWeight(line.qtyGrams),
                    ),
                    trailing: Text(
                      formatCurrency(line.amount),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('કુલ:'),
                  Text(
                    formatCurrency(_subtotal),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: _setDiscount,
                    child: const Text(
                      'ડિસ્કાઉન્ટ:',
                      style: TextStyle(decoration: TextDecoration.underline),
                    ),
                  ),
                  Text(
                    '-${formatCurrency(_discount)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'દેય:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  Text(
                    formatCurrency(_total),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.clear),
                label: const Text('બિલ ક્લીયર કરો'),
                onPressed: _billLines.isEmpty
                    ? null
                    : () {
                        setState(() {
                          _billLines.clear();
                          _discount = 0;
                        });
                      },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Simple bill line item model.
class BillLineItem {
  final Product product;
  final double qtyGrams;
  final double amount;

  BillLineItem({
    required this.product,
    required this.qtyGrams,
    required this.amount,
  });
}
