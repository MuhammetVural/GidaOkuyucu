// lib/features/product/ui/admin_product_form_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../product/data/product_repository.dart';
import '../../product/model/nutrients.dart';
import '../../product/model/product.dart';
import '../logic/allergen_extractor.dart';
import 'barcode_input_page.dart';
import 'product_info_page.dart';

final _savingProvider = StateProvider<bool>((ref) => false);

class AdminProductFormPage extends ConsumerStatefulWidget {
  const AdminProductFormPage({super.key});

  @override
  ConsumerState<AdminProductFormPage> createState() => _AdminProductFormPageState();
}

class _AdminProductFormPageState extends ConsumerState<AdminProductFormPage> {
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  final _barcodeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _sizeCtrl = TextEditingController(text: '1 L');
  final _ingredientsCtrl = TextEditingController();

  final _energyCtrl = TextEditingController();
  final _proteinCtrl = TextEditingController();
  final _fatCtrl = TextEditingController();
  final _satFatCtrl = TextEditingController();
  final _carbsCtrl = TextEditingController();
  final _sugarsCtrl = TextEditingController();
  final _fiberCtrl = TextEditingController();
  final _saltCtrl = TextEditingController();

  bool _isLiquid = true;

  num? _toNum(String s) {
    final t = s.trim().replaceAll(',', '.');
    if (t.isEmpty) return null;
    return num.tryParse(t);
  }

  @override
  void dispose() {
    _barcodeCtrl.dispose();
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _sizeCtrl.dispose();
    _ingredientsCtrl.dispose();
    _energyCtrl.dispose();
    _proteinCtrl.dispose();
    _fatCtrl.dispose();
    _satFatCtrl.dispose();
    _carbsCtrl.dispose();
    _sugarsCtrl.dispose();
    _fiberCtrl.dispose();
    _saltCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    ref.read(_savingProvider.notifier).state = true;

    final nutr = Nutrients(
      isLiquid: _isLiquid,
      energyKcal: _toNum(_energyCtrl.text),
      proteinG: _toNum(_proteinCtrl.text),
      fatG: _toNum(_fatCtrl.text),
      satFatG: _toNum(_satFatCtrl.text),
      carbsG: _toNum(_carbsCtrl.text),
      sugarsG: _toNum(_sugarsCtrl.text),
      fiberG: _toNum(_fiberCtrl.text),
      saltG: _toNum(_saltCtrl.text),
    );

    final ingredientsText = _ingredientsCtrl.text.trim();

    // İçindekilerden alerjenleri otomatik çıkar (negatifleri ayıklar)
    final allergens = extractAllergens(ingredientsText);

    final p = Product(
      name: _nameCtrl.text.trim(),
      brand: _brandCtrl.text.trim(),
      packageSize: _sizeCtrl.text.trim(),
      ingredientsText: ingredientsText,
      ingredientsAllergens: allergens,
      nutrients: nutr,
    );

    final repo = ref.read(productRepoProvider);
    final ok = await repo.insert(_barcodeCtrl.text.trim(), p);

    ref.read(_savingProvider.notifier).state = false;

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ürün kaydedildi')),
      );
      // İstersen kaydettikten sonra ürün sayfasına gidelim:
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ProductInfoPage(product: p, barcode: _barcodeCtrl.text.trim())),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kayıt başarısız')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final saving = ref.watch(_savingProvider);

    InputDecoration dec(String label) => InputDecoration(labelText: label, border: const OutlineInputBorder());

    return Scaffold(
      appBar: AppBar(title: const Text('Admin • Ürün Ekle')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _barcodeCtrl,
                    decoration: dec('Barkod / GTIN'),
                    keyboardType: TextInputType.number,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Barkod gerekli' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _sizeCtrl,
                    decoration: dec('Paket boyutu (örn. 1 L / 500 g)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameCtrl,
              decoration: dec('Ürün adı'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Ürün adı gerekli' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _brandCtrl,
              decoration: dec('Marka'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Checkbox(
                  value: _isLiquid,
                  onChanged: (v) => setState(() => _isLiquid = v ?? true),
                ),
                const Text('Sıvı ürün (100 ml baz)'),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _ingredientsCtrl,
              decoration: dec('İçindekiler'),
              minLines: 2,
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            const Text('Besin Değerleri (100 ml / 100 g)', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _numField(_energyCtrl, 'Enerji (kcal/100)'),
                _numField(_proteinCtrl, 'Protein (g/100)'),
                _numField(_fatCtrl, 'Yağ (g/100)'),
                _numField(_satFatCtrl, 'Doymuş yağ (g/100)'),
                _numField(_carbsCtrl, 'Karbonhidrat (g/100)'),
                _numField(_sugarsCtrl, 'Şekerler (g/100)'),
                _numField(_fiberCtrl, 'Lif (g/100)'),
                _numField(_saltCtrl, 'Tuz (g/100)'),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed: saving ? null : _save,
                icon: saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
                label: const Text('Kaydet'),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Not: Alerjenler, içindekiler metninden otomatik çıkarılır (ör. süt, laktoz, gluten, soya, yumurta, kuruyemiş vb.). '
                  'Negatif ifadeler (örn. laktozsuz, gluten içermez) tespit edilirse o anahtar kelime alerjen listesine eklenmez.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _numField(TextEditingController c, String label) {
    return SizedBox(
      width: 180,
      child: TextFormField(
        controller: c,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
      ),
    );
  }
}