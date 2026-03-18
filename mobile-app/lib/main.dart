import 'package:flutter/material.dart';

void main() {
  runApp(const WaQtiApp());
}

class WaQtiApp extends StatelessWidget {
  const WaQtiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WaQti',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF1565C0),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('WaQti', style: TextStyle(fontSize: 24)),
        ),
      ),
    );
  }
}
