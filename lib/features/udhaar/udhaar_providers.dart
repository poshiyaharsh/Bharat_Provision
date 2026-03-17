import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database_helper.dart';
import '../../data/repositories/udhaar_repository.dart';
import '../../shared/models/bill_item_model.dart';
import '../../shared/models/customer_model.dart';

// ─── Core repository provider ─────────────────────────────────────────────────

final udhaarRepositoryProvider = Provider<UdhaarRepository>(
    (ref) => UdhaarRepository(DatabaseHelper.instance));

// ─── Dashboard providers ──────────────────────────────────────────────────────

final udhaarTotalOutstandingProvider = FutureProvider<double>((ref) async {
  return ref.watch(udhaarRepositoryProvider).getTotalOutstanding();
});

final udhaarCustomerListProvider =
    FutureProvider<List<CustomerSummaryRow>>((ref) async {
  return ref.watch(udhaarRepositoryProvider).getAllCustomersSorted();
});

// ─── Per-customer providers ───────────────────────────────────────────────────

final udhaarCustomerProvider =
    FutureProvider.family<Customer?, int>((ref, customerId) async {
  return ref.watch(udhaarRepositoryProvider).getCustomerById(customerId);
});

final unpaidBillsProvider =
    FutureProvider.autoDispose.family<List<UnpaidBillRow>, int>(
        (ref, customerId) async {
  return ref.watch(udhaarRepositoryProvider).getUnpaidBills(customerId);
});

final finalTotalProvider =
    FutureProvider.autoDispose.family<FinalTotalData, int>(
        (ref, customerId) async {
  return ref.watch(udhaarRepositoryProvider).getFinalTotal(customerId);
});

final availableMonthsProvider =
    FutureProvider.autoDispose.family<List<String>, int>(
        (ref, customerId) async {
  return ref.watch(udhaarRepositoryProvider).getAvailableMonths(customerId);
});

// ─── Settings provider ────────────────────────────────────────────────────────

final udhaarSettingsProvider =
    FutureProvider.autoDispose<Map<String, String>>((ref) async {
  return ref.watch(udhaarRepositoryProvider).getSettings([
    'reminder_whatsapp',
    'reminder_sms',
    'reminder_pdf',
    'print_payment_receipt',
    'shop_name',
  ]);
});

// ─── Bill items (on-demand, loaded when a ledger row is expanded) ─────────────

final billItemsProvider =
    FutureProvider.autoDispose.family<List<BillItem>, int>(
        (ref, billId) async {
  return ref.watch(udhaarRepositoryProvider).getBillItems(billId);
});
