// lib/core/supa.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'env.dart';

class Supa {
  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> init() async {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
    );
  }
}