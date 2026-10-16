import 'package:flutter/material.dart';
import 'data/db.dart';
import 'features/threads/thread_stock_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDb.autoBackup();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext c) => MaterialApp(
    title: 'Thread Recommender',
    theme: ThemeData(colorSchemeSeed: const Color(0xFF8E2A4A), useMaterial3: true,
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(minimumSize: const Size(64, 56)))),
    home: const ThreadStockPage());
}
