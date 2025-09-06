// lib/features/product/ui/barcode_input_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gida_okuyucu/features/product/ui/scan_barcode_page.dart';
import '../../product/data/product_repository.dart';
import '../../product/model/product.dart';
import '../../product/model/nutrients.dart';
import '../logic/allergen_extractor.dart';
import 'admin_product_form_page.dart';
import 'product_info_page.dart';

// Riverpod providers
final barcodeProvider = StateProvider<String>((ref) => '');
final errorTextProvider = StateProvider<String?>((ref) => null);
final productRepoProvider = Provider<ProductRepository>((ref) => ProductRepository());


// Alerjen çıkarımı (otomatik) — TR duyarlı normalizasyon + olumsuzluk kontrolü
String _normalizeTr(String input) {
  // Küçük harfe çevir + Türkçe karakterleri sadeleştir
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
  // Örn: "laktozsuz", "laktoz icERmeZ", "laktoz yoktur"
  // temel ek varyasyonları: -siz -suz -sız -süz
  final negSuffixes = ['siz', 'suz', 'siz', 'suz', 'sız', 'süz'];
  // 1) Birleşik ekle kullanım: "keyword"+"suffix"
  for (final suf in negSuffixes) {
    if (haystackNorm.contains('$keywordNorm$suf')) return true;
  }
  // 2) "keyword içermez", "keyword yoktur"
  if (haystackNorm.contains('$keywordNorm icermez')) return true;
  if (haystackNorm.contains('$keywordNorm yoktur')) return true;
  // 3) "içermez keyword" gibi ters kullanım da nadiren görülür
  if (haystackNorm.contains('icermez $keywordNorm')) return true;
  return false;
}


/// Barkod girişi + bulunamazsa ekleme diyaloğu (Riverpod/ConsumerWidget)
class BarcodeInputPage extends ConsumerWidget {
  const BarcodeInputPage({super.key});

  num? _toNum(String s) {
    final t = s.trim().replaceAll(',', '.');
    if (t.isEmpty) return null;
    return num.tryParse(t);
  }

  Widget _numField(TextEditingController c, String label) {
    return SizedBox(
      width: 160,
      child: TextField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
  Future<void> _openScanner(BuildContext context, WidgetRef ref) async {
    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const ScanBarcodePage()),
    );
    if (code != null && code.isNotEmpty) {
      ref.read(barcodeProvider.notifier).state = code;
      await _search(context, ref);
    }
  }

  Future<Product?> _showAddDialogAndSave(BuildContext context, WidgetRef ref, String barcode) async {
    final nameCtrl = TextEditingController();
    final brandCtrl = TextEditingController();
    final sizeCtrl = TextEditingController(text: '1 L');
    final ingCtrl = TextEditingController();
    final energyCtrl = TextEditingController();
    final proteinCtrl = TextEditingController();
    final fatCtrl = TextEditingController();
    final satFatCtrl = TextEditingController();
    final carbsCtrl = TextEditingController();
    final sugarsCtrl = TextEditingController();
    final saltCtrl = TextEditingController();
    bool isLiquid = true;

    Product? result;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setLocal) {
          return AlertDialog(
            title: const Text('Yeni Ürün Ekle'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  Text('Barkod: $barcode', style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Ürün adı')),
                  TextField(controller: brandCtrl, decoration: const InputDecoration(labelText: 'Marka')),
                  TextField(controller: sizeCtrl, decoration: const InputDecoration(labelText: 'Paket boyutu (ör. 1 L / 500 g)')),
                  TextField(controller: ingCtrl, decoration: const InputDecoration(labelText: 'İçindekiler')),
                  const SizedBox(height: 8),
                  Row(children: [
                    Checkbox(value: isLiquid, onChanged: (v) => setLocal(() => isLiquid = v ?? true)),
                    const Text('Sıvı ürün (100 ml baz)'),
                  ]),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    _numField(energyCtrl, 'Enerji (kcal/100)'),
                    _numField(proteinCtrl, 'Protein (g/100)'),
                    _numField(fatCtrl, 'Yağ (g/100)'),
                    _numField(satFatCtrl, 'Doymuş yağ (g/100)'),
                    _numField(carbsCtrl, 'Karbonhidrat (g/100)'),
                    _numField(sugarsCtrl, 'Şekerler (g/100)'),
                    _numField(saltCtrl, 'Tuz (g/100)'),
                  ]),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Vazgeç')),
              FilledButton(
                onPressed: () async {
                  final nutr = Nutrients(
                    isLiquid: isLiquid,
                    energyKcal: _toNum(energyCtrl.text),
                    proteinG: _toNum(proteinCtrl.text),
                    fatG: _toNum(fatCtrl.text),
                    satFatG: _toNum(satFatCtrl.text),
                    carbsG: _toNum(carbsCtrl.text),
                    sugarsG: _toNum(sugarsCtrl.text),
                    saltG: _toNum(saltCtrl.text),
                  );

                  // İçindekilerden alerjenleri otomatik çıkar
                  final autoAllergens = extractAllergens(ingCtrl.text.trim());

                  final p = Product(
                    name: nameCtrl.text.trim(),
                    brand: brandCtrl.text.trim(),
                    packageSize: sizeCtrl.text.trim(),
                    ingredientsText: ingCtrl.text.trim(),
                    ingredientsAllergens: autoAllergens,
                    nutrients: nutr,
                  );

                  final repo = ref.read(productRepoProvider);
                  final ok = await repo.insert(barcode, p);
                  if (ok) {
                    result = p;
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('Kaydet'),
              ),
            ],
          );
        });
      },
    );

    return result;
  }

  Future<void> _search(BuildContext context, WidgetRef ref) async {
    final barcode = ref.read(barcodeProvider);
    final code = barcode.trim();

    if (code.isEmpty) {
      ref.read(errorTextProvider.notifier).state = 'Barkod girin';
      return;
    }
    ref.read(errorTextProvider.notifier).state = null;

    final repo = ref.read(productRepoProvider);
    Product? product = await repo.getByBarcode(code);

    if (product == null) {
      final created = await _showAddDialogAndSave(context, ref, code);
      if (created != null) {
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ProductInfoPage(product: created, barcode: code)),
          );
        }
      } else {
        ref.read(errorTextProvider.notifier).state = 'Veritabanında bulunamadı ve ekleme iptal edildi.';
      }
      return;
    }

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProductInfoPage(product: product, barcode: code)),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final errorText = ref.watch(errorTextProvider);
    final barcode = ref.watch(barcodeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gıda Okuyucu'),
        actions: [
          IconButton(
            tooltip: 'Admin',
            icon: const Icon(Icons.admin_panel_settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminProductFormPage()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Barkodu gir (şimdilik manuel)\nSonraki adımda kamera ile tarama eklenecek.'),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Barkod / GTIN',
                    border: const OutlineInputBorder(),
                    errorText: errorText,
                  ),
                  onChanged: (v) => ref.read(barcodeProvider.notifier).state = v,
                  onSubmitted: (_) => _search(context, ref),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Kamerayla Tara',
                icon: const Icon(Icons.qr_code_scanner),
                onPressed: () => _openScanner(context, ref),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () => _search(context, ref),
                icon: const Icon(Icons.search),
                label: const Text('Göster'),
              ),
            ]),
            const SizedBox(height: 16),
            const _HintCard(),
          ],
        ),
      ),
    );
  }
}

class _HintCard extends StatelessWidget {
  const _HintCard();
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Deneme için barkodlar:'),
            SizedBox(height: 6),
            Text('• 8690000000001  (Birşah %3,1 Yağlı Süt 1 L – örnek)'),
          ],
        ),
      ),
    );
  }
}

