// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/supa.dart';
import 'features/product/ui/barcode_input_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supa.init(); // Supabase başlat
  runApp(const ProviderScope(child: GidaOkuyucuApp()));
}

class GidaOkuyucuApp extends StatelessWidget {
  const GidaOkuyucuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gıda Okuyucu',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const BarcodeInputPage(),
    );
  }
}