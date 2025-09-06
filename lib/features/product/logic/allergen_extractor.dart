// lib/features/product/logic/allergen_extractor.dart
import 'package:characters/characters.dart';

String _normalizeTr(String input) {
  final lower = input.toLowerCase();
  final map = {
    'ç': 'c', 'ğ': 'g', 'ı': 'i', 'i̇': 'i', 'ö': 'o', 'ş': 's', 'ü': 'u',
    'â': 'a', 'î': 'i', 'û': 'u', 'ã': 'a', 'é': 'e'
  };
  final sb = StringBuffer();
  for (final ch in lower.characters) {
    sb.write(map[ch] ?? ch);
  }
  return sb.toString();
}

bool _isNegated(String haystackNorm, String keywordNorm) {
  final negSuffixes = ['siz','suz','sız','süz'];
  for (final suf in negSuffixes) {
    if (haystackNorm.contains('$keywordNorm$suf')) return true;
  }
  if (haystackNorm.contains('$keywordNorm icermez')) return true;
  if (haystackNorm.contains('$keywordNorm yoktur')) return true;
  if (haystackNorm.contains('icermez $keywordNorm')) return true;
  return false;
}

/// İçindekiler metninden alerjenleri çıkarır (tahmin değil, anahtar kelime eşleşmesi).
List<String> extractAllergens(String ingredientsText) {
  if (ingredientsText.trim().isEmpty) return const [];
  final hits = <String>{};

  const dictRaw = <String, List<String>>{
    'süt': ['sut', 'inek sutu', 'mandira sutu'],
    'laktoz': ['laktoz', 'lactose'],
    'gluten': ['gluten'],
    'buğday': ['bugday'],
    'arpa': ['arpa'],
    'çavdar': ['cavdar'],
    'yulaf': ['yulaf'],
    'soya': ['soya', 'soy'],
    'yumurta': ['yumurta', 'albumen'],
    'yer fıstığı': ['yer fistigi', 'fistik', 'peanut', 'arachis'],
    'fındık': ['findik', 'hazelnut'],
    'badem': ['badem', 'almond'],
    'ceviz': ['ceviz', 'walnut'],
    'antep fıstığı': ['antep fistigi', 'pistachio'],
    'pikan': ['pikan', 'pekan', 'pecan'],
    'susam': ['susam', 'sesame'],
    'balık': ['balik', 'fish'],
    'kabuklu deniz ürünleri': ['kabuklu deniz urunleri', 'crustacean', 'shellfish', 'krustase'],
    'karides': ['karides', 'shrimp', 'prawn'],
    'istiridye': ['istiridye', 'oyster'],
    'midye': ['midye', 'mussel'],
    'yengeç': ['yengec', 'crab'],
  };

  final haystackNorm = _normalizeTr(ingredientsText);
  for (final entry in dictRaw.entries) {
    final display = entry.key;
    for (final variant in entry.value) {
      final keyNorm = _normalizeTr(variant);
      if (haystackNorm.contains(keyNorm) && !_isNegated(haystackNorm, keyNorm)) {
        hits.add(display);
        break;
      }
    }
  }
  return hits.toList();
}