import 'dart:io';

import 'package:flutter/material.dart';

import '../localization/app_strings.dart';

/// Platform-aware navigation shell: bottom nav on Android, side rail on Windows
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.child,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget child;

  static const List<_NavItem> _items = [
    _NavItem(AppStrings.navBilling, Icons.point_of_sale),
    _NavItem(AppStrings.navInventory, Icons.inventory_2),
    _NavItem(AppStrings.navKhata, Icons.people),
    _NavItem(AppStrings.navReports, Icons.assessment),
    _NavItem(AppStrings.navSettings, Icons.settings),
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = !Platform.isAndroid;
    if (isDesktop) {
      final screenWidth = MediaQuery.sizeOf(context).width;
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              extended: screenWidth > 800,
              minExtendedWidth: 160,
              selectedIndex: currentIndex,
              onDestinationSelected: onDestinationSelected,
              destinations: _items
                  .map(
                    (e) => NavigationRailDestination(
                      icon: Icon(e.icon),
                      label: Text(e.label),
                    ),
                  )
                  .toList(),
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: _items
            .map(
              (e) => NavigationDestination(
                icon: Icon(e.icon),
                label: e.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.label, this.icon);
  final String label;
  final IconData icon;
}
