import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';

final largeTextProvider = StateProvider<bool>((ref) => false);

final settingsValuesProvider = FutureProvider<Map<String, String>>((ref) async {
  final repo = await ref.watch(settingsRepositoryFutureProvider.future);
  return {
    'shop_name': await repo.get('shop_name') ?? 'મારી દુકાન',
    'shop_address': await repo.get('shop_address') ?? '',
    'shop_phone': await repo.get('shop_phone') ?? '',
    'gstin': await repo.get('gstin') ?? '',
    'bill_footer': await repo.get('bill_footer') ?? '',
  };
});
