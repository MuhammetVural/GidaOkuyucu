// lib/features/product/ui/product_info_page.dart
import 'package:flutter/material.dart';
import '../../product/model/product.dart';
import '../../product/model/nutrients.dart';
import '../logic/allergen_extractor.dart';

///Ürün bilgisini gösteren sayfa + küçük yardımcılar.

class ProductInfoPage extends StatelessWidget {
  final Product product;
  final String barcode;
  const ProductInfoPage({super.key, required this.product, required this.barcode});

  @override
  Widget build(BuildContext context) {
    final nutr = product.nutrients;
    final flags = nutritionFlags(nutr);
    // DB’de yoksa (eski kayıtlar) metinden çıkar:
    final allergens = product.ingredientsAllergens.isNotEmpty
        ? product.ingredientsAllergens
        : extractAllergens(product.ingredientsText);

    return Scaffold(
      appBar: AppBar(title: Text(product.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CircleAvatar(radius: 36, child: Text(product.brand.isNotEmpty ? product.brand[0] : '?')),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(product.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('${product.brand} • ${product.packageSize} • Barkod: $barcode',
                    style: TextStyle(color: Colors.grey[700])),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6, runSpacing: 6,
                  children: flags
                      .map((f) => Chip(
                    label: Text(f.label),
                    backgroundColor: f.color.withOpacity(.15),
                    labelStyle: TextStyle(color: f.color.shade800),
                    side: BorderSide(color: f.color.shade300),
                  ))
                      .toList(),
                ),
              ]),
            )
          ]),
          const SizedBox(height: 16),

          const Text('İçindekiler', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(product.ingredientsText.isEmpty ? '—' : product.ingredientsText),
          const SizedBox(height: 8),
          if (allergens.isNotEmpty)
            Wrap(
              spacing: 8, runSpacing: 8,
              children: allergens
                  .map((a) => Chip(
                label: Text('Alerjen: ${a.toUpperCase()}'),
                avatar: const Icon(Icons.warning_amber_outlined, size: 18),
                backgroundColor: Colors.orange.shade50,
                side: BorderSide(color: Colors.orange.shade200),
                labelStyle: TextStyle(color: Colors.orange.shade900),
              ))
                  .toList(),
            ),

          const SizedBox(height: 16),
          Text('Besin Değerleri (${nutr.isLiquid ? '100 ml' : '100 g'})', style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          NutritionTable(n: nutr),
        ],
      ),
    );
  }
}

class Flag { final String label; final MaterialColor color; Flag(this.label, this.color); }


List<Flag> nutritionFlags(Nutrients n) {
  final liquid = n.isLiquid;
  final sugar = n.sugarsG?.toDouble();
  final fat = n.fatG?.toDouble();
  final sat = n.satFatG?.toDouble();
  final salt = n.saltG?.toDouble();
  final out = <Flag>[];

  if (sugar != null) {
    if (sugar > (liquid ? 11.25 : 22.5)) out.add(Flag('Şeker: Yüksek', Colors.red));
    else if (sugar > (liquid ? 2.5 : 5)) out.add(Flag('Şeker: Orta', Colors.orange));
    else out.add(Flag('Şeker: Düşük', Colors.green));
  }
  if (fat != null) {
    if (fat > (liquid ? 8.75 : 17.5)) out.add(Flag('Yağ: Yüksek', Colors.red));
    else if (fat > (liquid ? 3.0 : 6.0)) out.add(Flag('Yağ: Orta', Colors.orange));
    else out.add(Flag('Yağ: Düşük', Colors.green));
  }
  if (sat != null) {
    if (sat > (liquid ? 2.5 : 5)) out.add(Flag('Doymuş Yağ: Yüksek', Colors.red));
    else if (sat > (liquid ? 0.75 : 1.5)) out.add(Flag('Doymuş Yağ: Orta', Colors.orange));
    else out.add(Flag('Doymuş Yağ: Düşük', Colors.green));
  }
  if (salt != null) {
    if (salt > (liquid ? 0.75 : 1.5)) out.add(Flag('Tuz: Yüksek', Colors.red));
    else if (salt > (liquid ? 0.3 : 0.9)) out.add(Flag('Tuz: Orta', Colors.orange));
    else out.add(Flag('Tuz: Düşük', Colors.green));
  }
  return out;
}

class NutritionTable extends StatelessWidget {
  final Nutrients n;
  const NutritionTable({super.key, required this.n});

  String _fmt(num? v, {String unit = 'g'}) {
    if (v == null) return '—';
    final isInt = v % 1 == 0;
    return '${isInt ? v.toInt() : v.toStringAsFixed(1)} $unit';
  }

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {0: FlexColumnWidth(1.8), 1: FlexColumnWidth()},
      border: TableBorder.all(color: Colors.grey.shade200),
      children: [
        _row('Baz', n.isLiquid ? '100 ml' : '100 g'),
        _row('Enerji', n.energyKcal?.toString() ?? '—', tail: 'kcal'),
        _row('Protein', _fmt(n.proteinG)),
        _row('Yağ', _fmt(n.fatG)),
        _row(' • Doymuş yağ', _fmt(n.satFatG)),
        _row('Karbonhidrat', _fmt(n.carbsG)),
        _row(' • Şekerler', _fmt(n.sugarsG)),
        _row('Lif', _fmt(n.fiberG)),
        _row('Tuz', _fmt(n.saltG)),
      ],
    );
  }

  TableRow _row(String a, String b, {String? tail}) {
    return TableRow(children: [
      Padding(padding: const EdgeInsets.all(8), child: Text(a)),
      Padding(padding: const EdgeInsets.all(8), child: Text(tail == null ? b : '$b $tail')),
    ]);
  }
}