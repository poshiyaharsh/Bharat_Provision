import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_strings.dart';
import 'features/products/presentation/add_edit_product_screen.dart';
import 'features/products/presentation/product_list_screen.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: AppStrings.fontFamilyGujarati,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B5E20),
        ),
      ),
      initialRoute: '/products',
      routes: {
        '/products': (_) => const ProductListScreen(),
        '/products/add': (_) => const AddEditProductScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/products/edit' && settings.arguments is int) {
          final id = settings.arguments as int;
          return MaterialPageRoute(
            builder: (_) => AddEditProductScreen(productId: id),
          );
        }
        return null;
      },
    );
  }
}
