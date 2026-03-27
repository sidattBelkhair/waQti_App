import 'package:flutter/material.dart';
import '../profile/profile_screen.dart';
import 'gestionnaire_etablissement_screen.dart';
import 'gestionnaire_services_screen.dart';
import 'gestionnaire_tickets_screen.dart';

class GestionnaireHomeScreen extends StatefulWidget {
  const GestionnaireHomeScreen({super.key});
  @override State<GestionnaireHomeScreen> createState() => _State();
}

class _State extends State<GestionnaireHomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      const GestionnaireEtablissementScreen(),
      const GestionnaireServicesScreen(),
      const GestionnaireTicketsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: screens[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.business_outlined),
              selectedIcon: Icon(Icons.business),
              label: 'Établissement'),
          NavigationDestination(
              icon: Icon(Icons.layers_outlined),
              selectedIcon: Icon(Icons.layers),
              label: 'Services'),
          NavigationDestination(
              icon: Icon(Icons.confirmation_number_outlined),
              selectedIcon: Icon(Icons.confirmation_number),
              label: 'Tickets'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profil'),
        ],
      ),
    );
  }
}
