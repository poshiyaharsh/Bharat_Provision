import 'dart:io';

import 'package:flutter/material.dart';

import '../localization/app_strings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/role_provider.dart';

/// Platform-aware navigation shell: bottom nav on Android, side rail on Windows
class AppScaffold extends ConsumerWidget {
  const AppScaffold({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.child,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(currentRoleProvider);
    final isAdmin = canAccessUdhaar(role);
    final items = [
      const _NavItem(AppStrings.navBilling, Icons.point_of_sale),
      const _NavItem(AppStrings.navInventory, Icons.inventory_2),
      const _NavItem(AppStrings.navKhata, Icons.people),
      const _NavItem(AppStrings.navReports, Icons.assessment),
      const _NavItem(AppStrings.navSettings, Icons.settings),
      if (isAdmin) const _NavItem('ઉધાર', Icons.account_balance_wallet),
    ];
    final effectiveIndex = currentIndex.clamp(0, items.length - 1);
    final isDesktop = !Platform.isAndroid;
    if (isDesktop) {
      final screenWidth = MediaQuery.sizeOf(context).width;
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              extended: screenWidth > 800,
              minExtendedWidth: 160,
              selectedIndex: effectiveIndex,
              onDestinationSelected: onDestinationSelected,
              destinations: items
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
        selectedIndex: effectiveIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: items
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
