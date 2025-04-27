import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';

const String entriesBoxName = 'financeEntries';
const String transactionsBoxName = 'transactions';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox<String>(entriesBoxName);
  await Hive.openBox<String>(transactionsBoxName);
  runApp(const FinanceZeroApp());
}