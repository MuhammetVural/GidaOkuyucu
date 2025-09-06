// lib/features/product/model/nutrients.dart
class Nutrients {
  // Sıvı mı? true => 100 ml, false => 100 g
  final bool isLiquid;
  final num? energyKcal;
  final num? fatG;
  final num? satFatG;
  final num? carbsG;
  final num? sugarsG;
  final num? fiberG;
  final num? proteinG;
  final num? saltG;

  const Nutrients({
    required this.isLiquid,
    this.energyKcal,
    this.fatG,
    this.satFatG,
    this.carbsG,
    this.sugarsG,
    this.fiberG,
    this.proteinG,
    this.saltG,
  });

  factory Nutrients.fromMap(Map<String, dynamic> m) {
    return Nutrients(
      isLiquid: (m['is_liquid'] as bool?) ?? true,
      energyKcal: m['energy_kcal'] as num?,
      fatG: m['fat_g'] as num?,
      satFatG: m['sat_fat_g'] as num?,
      carbsG: m['carbs_g'] as num?,
      sugarsG: m['sugars_g'] as num?,
      fiberG: m['fiber_g'] as num?,
      proteinG: m['protein_g'] as num?,
      saltG: m['salt_g'] as num?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'is_liquid': isLiquid,
      'energy_kcal': energyKcal,
      'fat_g': fatG,
      'sat_fat_g': satFatG,
      'carbs_g': carbsG,
      'sugars_g': sugarsG,
      'fiber_g': fiberG,
      'protein_g': proteinG,
      'salt_g': saltG,
    };
  }
}