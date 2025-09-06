// lib/features/product/model/product.dart
import 'nutrients.dart';

class Product {
  // Ürün adı
  final String name;
  // Marka adı
  final String brand;
  // Paket boyutu (örn. 1 L / 500 g)
  final String packageSize;
  // İçindekiler metni
  final String ingredientsText;
  // İçindekilerdeki alerjenler (opsiyonel)
  final List<String> ingredientsAllergens;
  // 100 ml/g bazlı besin değerleri
  final Nutrients nutrients;

  Product({
    required this.name,
    required this.brand,
    required this.packageSize,
    required this.ingredientsText,
    this.ingredientsAllergens = const [],
    required this.nutrients,
  });

  factory Product.fromMap(Map<String, dynamic> m) {
    return Product(
      name: (m['name'] ?? '') as String,
      brand: (m['brand'] ?? '') as String,
      packageSize: (m['package_size'] ?? '') as String,
      ingredientsText: (m['ingredients_text'] ?? '') as String,
      ingredientsAllergens: (m['ingredients_allergens'] as List?)?.cast<String>() ?? const [],
      nutrients: Nutrients.fromMap(m),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'brand': brand,
      'package_size': packageSize,
      'ingredients_text': ingredientsText,
      'ingredients_allergens': ingredientsAllergens,
      ...nutrients.toMap(),
    };
  }
}