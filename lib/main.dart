import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'models.dart';
import 'progress_store.dart';
import 'screens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await ProgressStore.open();
  final content = await Content.load();
  runApp(RaghadApp(store: store, content: content));
}

class RaghadApp extends StatelessWidget {
  const RaghadApp({super.key, required this.store, required this.content});
  final ProgressStore store;
  final Content content;

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF7B4BC7);
    return MaterialApp(
      title: 'رغد',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: seed),
      darkTheme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: seed,
          brightness: Brightness.dark),
      themeMode: ThemeMode.system,
      home: Shell(store: store, content: content),
    );
  }
}
