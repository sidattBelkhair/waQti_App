import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/locale_provider.dart';
import 'l10n/app_strings.dart';
import 'services/api_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService().init();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: const WaQtiApp(),
    ),
  );
}

class WaQtiApp extends StatelessWidget {
  const WaQtiApp({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale;
    final isAr = locale == 'ar';
    return MaterialApp(
      title: 'WaQti',
      debugShowCheckedModeBanner: false,
      theme: WaqtiTheme.lightTheme,
      builder: (context, child) => LocaleWrapper(
        locale: locale,
        child: Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: child!,
        ),
      ),
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.loading) {
            return Scaffold(
              body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(AppStrings.get('app_name', locale),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ])),
            );
          }
          return auth.isLoggedIn ? const HomeScreen() : const LoginScreen();
        },
      ),
    );
  }
}
