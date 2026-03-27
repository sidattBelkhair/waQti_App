import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  String _locale = 'fr';
  String get locale => _locale;
  bool get isArabic => _locale == 'ar';

  LocaleProvider() { _load(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _locale = prefs.getString('locale') ?? 'fr';
    notifyListeners();
  }

  Future<void> toggle() async {
    _locale = _locale == 'fr' ? 'ar' : 'fr';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', _locale);
    notifyListeners();
  }
}
