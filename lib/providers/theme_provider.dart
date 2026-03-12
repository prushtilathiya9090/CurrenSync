import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('themeMode') ?? 'light';
    _themeMode = saved == 'light' ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _themeMode = isDark ? ThemeMode.light : ThemeMode.dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', isDark ? 'dark' : 'light');
    notifyListeners();
  }

  // ── Dark colours ──────────────────────────────────────────
  static const darkBg         = Color(0xFF0A0E1A);
  static const darkSurface    = Color(0xFF1A2035);
  static const darkCard       = Color(0xFF131929);
  static const darkBorder     = Color(0x14FFFFFF);   // white 8 %
  static const darkTextPrim   = Colors.white;
  static const darkTextSec    = Color(0x99FFFFFF);   // white 60 %
  static const darkTextHint   = Color(0x61FFFFFF);   // white 38 %

  // ── Light colours ─────────────────────────────────────────
  static const lightBg        = Color(0xFFF0F4FF);
  static const lightSurface   = Color(0xFFFFFFFF);
  static const lightCard      = Color(0xFFF7F9FF);
  static const lightBorder    = Color(0x1A1A2035);   // navy 10 %
  static const lightTextPrim  = Color(0xFF0A0E1A);
  static const lightTextSec   = Color(0xFF4A5568);
  static const lightTextHint  = Color(0xFF9AA5B4);

  // ── Accent (same in both) ─────────────────────────────────
  static const accent         = Color(0xFF00C896);
  static const accentBlue     = Color(0xFF0099FF);
  static const danger         = Color(0xFFFF4D6A);
  static const gold           = Color(0xFFFFC107);

  // ── Helpers ───────────────────────────────────────────────
  Color bg(bool dark)       => dark ? darkBg       : lightBg;
  Color surface(bool dark)  => dark ? darkSurface  : lightSurface;
  Color card(bool dark)     => dark ? darkCard     : lightCard;
  Color border(bool dark)   => dark ? darkBorder   : lightBorder;
  Color textPrim(bool dark) => dark ? darkTextPrim : lightTextPrim;
  Color textSec(bool dark)  => dark ? darkTextSec  : lightTextSec;
  Color textHint(bool dark) => dark ? darkTextHint : lightTextHint;
}