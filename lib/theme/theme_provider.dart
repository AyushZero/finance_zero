import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _darkModeKey = 'darkMode';
  final Box _settingsBox = Hive.box('appSettings');
  
  bool get isDarkMode => _settingsBox.get(_darkModeKey, defaultValue: false);
  
  ThemeMode get themeMode => isDarkMode ? ThemeMode.dark : ThemeMode.light;
  
  void toggleTheme() {
    _settingsBox.put(_darkModeKey, !isDarkMode);
    notifyListeners();
  }
  
  // Light theme
  ThemeData get lightTheme {
    return ThemeData(
      primarySwatch: Colors.teal,
      brightness: Brightness.light,
      useMaterial3: true,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.teal,
        brightness: Brightness.light,
      ),
    );
  }
  
  // Dark theme
  ThemeData get darkTheme {
    return ThemeData(
      primarySwatch: Colors.teal,
      brightness: Brightness.dark,
      useMaterial3: true,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.teal,
        brightness: Brightness.dark,
      ),
    );
  }
}
