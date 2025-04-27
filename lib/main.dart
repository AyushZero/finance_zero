import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';
import 'theme/theme_provider.dart';
import 'package:provider/provider.dart';

const String entriesBoxName = 'financeEntries';
const String transactionsBoxName = 'transactions';
const String settingsBoxName = 'appSettings';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox<String>(entriesBoxName);
  await Hive.openBox<String>(transactionsBoxName);
  await Hive.openBox<dynamic>(settingsBoxName);

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const FinanceZeroApp(),
    ),
  );
}