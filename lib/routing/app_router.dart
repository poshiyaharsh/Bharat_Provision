import 'package:flutter/material.dart';

import '../core/widgets/app_scaffold.dart';
import '../features/billing/billing_home_screen.dart';
import '../features/inventory/category_list_screen.dart';
import '../features/inventory/item_list_screen.dart';
import '../features/inventory/item_edit_screen.dart';
import '../features/khata/customer_list_screen.dart';
import '../features/khata/customer_khata_detail_screen.dart';
import '../features/khata/customer_edit_screen.dart';
import '../features/reports/reports_home_screen.dart';
import '../features/settings/settings_screen.dart';

class AppRouter {
  AppRouter._();

  static const String billing = '/';
  static const String inventory = '/inventory';
  static const String khata = '/khata';
  static const String reports = '/reports';
  static const String settings = '/settings';
  static const String itemAdd = '/inventory/add';
  static const String itemEdit = '/inventory/edit';
  static const String categories = '/inventory/categories';
  static const String customerAdd = '/khata/add';
  static const String customerEdit = '/khata/edit';
  static const String customerKhata = '/khata/detail';

  static const List<String> _mainRoutes = [billing, inventory, khata, reports, settings];

  static int indexForRoute(String route) {
    final i = _mainRoutes.indexOf(route);
    return i >= 0 ? i : 0;
  }

  static Route<dynamic> onGenerateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case billing:
        return _buildShell(0, const BillingHomeScreen());
      case inventory:
        return _buildShell(1, const ItemListScreen());
      case khata:
        return _buildShell(2, const CustomerListScreen());
      case reports:
        return _buildShell(3, const ReportsHomeScreen());
      case settings:
        return _buildShell(4, const SettingsScreen());
      case categories:
        return _build(const CategoryListScreen());
      case itemAdd:
        return _build(const ItemEditScreen());
      case itemEdit:
        final id = routeSettings.arguments as int?;
        return _build(ItemEditScreen(itemId: id));
      case customerAdd:
        return _build(const CustomerEditScreen());
      case customerEdit:
        final id = routeSettings.arguments as int?;
        return _build(CustomerEditScreen(customerId: id));
      case customerKhata:
        final id = routeSettings.arguments as int;
        return _build(CustomerKhataDetailScreen(customerId: id));
      default:
        return _build(
          Scaffold(
            body: Center(
              child: Text('Not found: ${routeSettings.name}'),
            ),
          ),
        );
    }
  }

  static MaterialPageRoute<dynamic> _buildShell(int index, Widget child) {
    return MaterialPageRoute(
      builder: (context) => AppScaffold(
        currentIndex: index,
        onDestinationSelected: (i) {
          Navigator.of(context).pushReplacementNamed(_mainRoutes[i]);
        },
        child: child,
      ),
    );
  }

  static MaterialPageRoute<dynamic> _build(Widget page) {
    return MaterialPageRoute(builder: (_) => page);
  }
}
