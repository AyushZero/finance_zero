import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/tracker_home.dart';
import 'theme/theme_provider.dart';

class FinanceZeroApp extends StatelessWidget {
  const FinanceZeroApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Finance Zero',
      themeMode: themeProvider.themeMode,
      theme: themeProvider.lightTheme,
      darkTheme: themeProvider.darkTheme,
      home: const TrackerHomePage(),
    );
  }
}