import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/customer.dart';
import '../../data/models/khata_entry.dart';
import '../../data/providers.dart';

final customerSearchProvider = StateProvider<String>((ref) => '');

final customerListProvider = FutureProvider<List<Customer>>((ref) async {
  final repo = await ref.watch(customerRepositoryFutureProvider.future);
  final query = ref.watch(customerSearchProvider);
  return repo.search(query);
});

final customerWithBalanceProvider =
    FutureProvider.family<({Customer customer, double balance}), int>((ref, customerId) async {
  final customerRepo = await ref.watch(customerRepositoryFutureProvider.future);
  final khataRepo = await ref.watch(khataRepositoryFutureProvider.future);
  final customer = await customerRepo.getById(customerId);
  if (customer == null) throw StateError('Customer not found');
  final balance = await khataRepo.getBalance(customerId);
  return (customer: customer, balance: balance);
});

final customerKhataEntriesProvider =
    FutureProvider.family<List<KhataEntry>, int>((ref, customerId) async {
  final repo = await ref.watch(khataRepositoryFutureProvider.future);
  return repo.getEntries(customerId);
});
