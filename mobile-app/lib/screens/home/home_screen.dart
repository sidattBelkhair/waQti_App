import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../search/search_screen.dart';
import '../ticket/ticket_tracking_screen.dart';
import '../profile/profile_screen.dart';
import '../gestionnaire/gestionnaire_home_screen.dart';

// Notifier global pour switcher d'onglet depuis n'importe quel écran
final homeTabNotifier = ValueNotifier<int>(0);

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().user?.role;
    if (role == 'gestionnaire') return const GestionnaireHomeScreen();
    return const ClientHomeScreen();
  }
}

// ─── NAVIGATION CLIENT ───────────────────────────────────────
class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});
  @override State<ClientHomeScreen> createState() => _ClientHomeState();
}

class _ClientHomeState extends State<ClientHomeScreen> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    homeTabNotifier.addListener(_onTab);
  }

  void _onTab() => setState(() => _index = homeTabNotifier.value);

  @override
  void dispose() {
    homeTabNotifier.removeListener(_onTab);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const SearchScreen(),
      const TicketTrackingScreen(),
      const ProfileScreen(),
    ];
    return Scaffold(
      body: screens[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          setState(() => _index = i);
          homeTabNotifier.value = i;
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home), label: 'Accueil'),
          NavigationDestination(icon: Icon(Icons.confirmation_number_outlined),
              selectedIcon: Icon(Icons.confirmation_number), label: 'Mes Tickets'),
          NavigationDestination(icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}
