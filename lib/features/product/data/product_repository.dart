// lib/features/product/data/product_repository.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/env.dart';
import '../../../core/supa.dart';
import '../model/product.dart';

class ProductRepository {
  SupabaseClient get _db => Supa.client;

  Future<Product?> getByBarcode(String barcode) async {
    try {
      final res = await _db
          .from(Env.tableProducts)
          .select()
          .eq('barcode', barcode)
          .limit(1)
          .maybeSingle();
      if (res == null) return null;
      return Product.fromMap(res as Map<String, dynamic>);
    } catch (e) {
      debugPrint('getByBarcode error: $e');
      return null;
    }
  }

  Future<bool> insert(String barcode, Product p) async {
    try {
      final map = p.toMap()..['barcode'] = barcode;
      await _db.from(Env.tableProducts).insert(map);
      return true;
    } catch (e) {
      debugPrint('insert error: $e');
      return false;
    }
  }
}