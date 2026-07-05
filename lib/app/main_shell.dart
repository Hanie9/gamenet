import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/responsive.dart';
import '../features/admin/admin_screen.dart';
import '../features/cafe/cafe_screen.dart';
import '../features/customers/customers_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/gaming/gaming_screen.dart';
import '../services/app_state.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  void navigateTo(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final width = MediaQuery.sizeOf(context).width;
    final useBottomNav = width < Responsive.medium;

    final destinations = [
      (icon: Icons.dashboard_outlined, selected: Icons.dashboard, label: 'داشبورد'),
      (icon: Icons.people_outline, selected: Icons.people, label: 'مشتریان'),
      (icon: Icons.sports_esports_outlined, selected: Icons.sports_esports, label: 'بازی'),
      (icon: Icons.local_cafe_outlined, selected: Icons.local_cafe, label: 'کافه'),
      (icon: Icons.settings_outlined, selected: Icons.settings, label: 'مدیریت'),
    ];

    final screens = [
      const DashboardScreen(),
      const CustomersScreen(),
      GamingScreen(onNavigateToCafe: () => navigateTo(3)),
      const CafeScreen(),
      const AdminScreen(),
    ];

    return Scaffold(
        body: useBottomNav
            ? screens[_selectedIndex]
            : Row(
                children: [
                  NavigationRail(
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: (i) =>
                        setState(() => _selectedIndex = i),
                    extended: width > Responsive.expanded,
                    minExtendedWidth: 200,
                    labelType: width > Responsive.expanded
                        ? NavigationRailLabelType.none
                        : NavigationRailLabelType.selected,
                    leading: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.gaming, AppColors.primary],
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.sports_esports,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          if (width > Responsive.expanded) ...[
                            const SizedBox(height: 12),
                            const Text(
                              '201',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              '${state.gamingActiveSessions.length} بازی فعال',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    destinations: destinations
                        .map(
                          (d) => NavigationRailDestination(
                            icon: Icon(d.icon),
                            selectedIcon: Icon(d.selected),
                            label: Text(d.label),
                          ),
                        )
                        .toList(),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: screens[_selectedIndex]),
                ],
              ),
        bottomNavigationBar: useBottomNav
            ? NavigationBar(
                selectedIndex: _selectedIndex,
                onDestinationSelected: (i) =>
                    setState(() => _selectedIndex = i),
                destinations: destinations
                    .map(
                      (d) => NavigationDestination(
                        icon: Icon(d.icon),
                        selectedIcon: Icon(d.selected),
                        label: d.label,
                      ),
                    )
                    .toList(),
              )
            : null,
    );
  }
}
