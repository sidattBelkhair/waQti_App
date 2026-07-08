import 'package:flutter/material.dart';
import '../profile/profile_screen.dart';
import '../../l10n/app_strings.dart';
import 'gestionnaire_file_screen.dart';
import 'gestionnaire_stats_screen.dart';
import 'gestionnaire_services_screen.dart';

class GestionnaireHomeScreen extends StatefulWidget {
  const GestionnaireHomeScreen({super.key});
  @override State<GestionnaireHomeScreen> createState() => _State();
}

class _State extends State<GestionnaireHomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      const GestionnaireFileScreen(),
      const GestionnaireStatsScreen(),
      const GestionnaireServicesScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: screens[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
              icon: const Icon(Icons.confirmation_number_outlined),
              selectedIcon: const Icon(Icons.confirmation_number),
              label: context.tr('g_nav_file')),
          NavigationDestination(
              icon: const Icon(Icons.bar_chart_outlined),
              selectedIcon: const Icon(Icons.bar_chart),
              label: context.tr('g_nav_stats')),
          NavigationDestination(
              icon: const Icon(Icons.layers_outlined),
              selectedIcon: const Icon(Icons.layers),
              label: context.tr('g_nav_services')),
          NavigationDestination(
              icon: const Icon(Icons.person_outline),
              selectedIcon: const Icon(Icons.person),
              label: context.tr('profile')),
        ],
      ),
    );
  }
}
