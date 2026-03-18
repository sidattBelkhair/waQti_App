import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'services/api_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService().init();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider()..init(),
      child: const WaQtiApp(),
    ),
  );
}

class WaQtiApp extends StatelessWidget {
  const WaQtiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WaQti',
      debugShowCheckedModeBanner: false,
      theme: WaqtiTheme.lightTheme,
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.loading) {
            return const Scaffold(
              body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('WaQti', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ])),
            );
          }
          return auth.isLoggedIn ? const HomeScreen() : const LoginScreen();
        },
      ),
    );
  }
}
