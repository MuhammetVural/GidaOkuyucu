// lib/features/product/ui/scan_nutrition_page.dart
// Besin değerlerini OCR ile çıkarma ekranı — Riverpod + Hooks ile Stateless.

// Gerekli paketler (pubspec.yaml):
//   camera: ^0.10.5+9
//   google_mlkit_text_recognition: ^0.13.0
//   flutter_hooks: ^0.20.5
//   hooks_riverpod: ^2.5.1

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../product/model/nutrients.dart';

class ScanNutritionPage extends HookConsumerWidget {
  final String barcode;
  const ScanNutritionPage({super.key, required this.barcode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final camCtrl = useState<CameraController?>(null);
    final busy = useState(false);
    final err = useState<String?>(null);

    // Kamera init / dispose
    useEffect(() {
      bool cancelled = false;

      Future<void> init() async {
        try {
          final cams = await availableCameras();
          final back = cams.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.back,
            orElse: () => cams.first,
          );
          final ctrl = CameraController(
            back,
            ResolutionPreset.high,
            enableAudio: false,
          );
          await ctrl.initialize();
          if (!cancelled) camCtrl.value = ctrl;
        } catch (e) {
          if (!cancelled) err.value = 'Kamera başlatılamadı: $e';
        }
      }

      init();
      return () {
        cancelled = true;
        camCtrl.value?.dispose();
      };
    }, const []);

    Future<void> captureAndOcr() async {
      final c = camCtrl.value;
      if (c == null || busy.value) return;
      busy.value = true;
      err.value = null;
      try {
        final shot = await c.takePicture();
        final input = InputImage.fromFilePath(shot.path);
        final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
        final result = await recognizer.processImage(input);
        await recognizer.close();

        final text = result.text;
        if (text.trim().isEmpty) {
          err.value = 'Metin tespit edilemedi. Lütfen daha net bir fotoğraf çekin.';
          busy.value = false;
          return;
        }

        final nutr = _parseNutrients(text);

        final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Çıkarılan Besin Değerleri (100 ml/g)'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _row('Enerji (kcal)', nutr.energyKcal),
                _row('Protein (g)', nutr.proteinG),
                _row('Yağ (g)', nutr.fatG),
                _row('Doymuş yağ (g)', nutr.satFatG),
                _row('Karbonhidrat (g)', nutr.carbsG),
                _row('Şekerler (g)', nutr.sugarsG),
                _row('Tuz (g)', nutr.saltG),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Tekrar Dene'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Onayla'),
              ),
            ],
          ),
        );

        if (ok == true && context.mounted) {
          Navigator.of(context).pop(nutr); // çağırana Nutrients döndür
        }
      } catch (e) {
        err.value = 'OCR hatası: $e';
      } finally {
        busy.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text('Besin Değerlerini Tara • $barcode')),
      body: camCtrl.value == null
          ? Center(child: err.value != null ? Text(err.value!) : const CircularProgressIndicator())
          : Stack(
              fit: StackFit.expand,
              children: [
                CameraPreview(camCtrl.value!),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (err.value != null)
                          Container(
                            padding: const EdgeInsets.all(8),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(err.value!, style: const TextStyle(color: Colors.white)),
                          ),
                        ElevatedButton.icon(
                          onPressed: busy.value ? null : captureAndOcr,
                          icon: const Icon(Icons.camera_alt),
                          label: Text(busy.value ? 'İşleniyor...' : 'Besin Değeri Fotoğrafı Çek'),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'İpucu: Paketin arkasındaki \"Besin Değerleri\" tablosuna yakınlaşın, netleyip çekin.',
                          style: TextStyle(color: Colors.white, shadows: [Shadow(blurRadius: 4)]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

Widget _row(String k, num? v) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Expanded(child: Text(k)),
        Text(v == null ? '—' : (v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(1))),
      ],
    ),
  );
}

// Basit metin çıkarımı: anahtar kelime + hemen sonraki sayı.
Nutrients _parseNutrients(String raw) {
  final t = raw.toLowerCase().replaceAll(',', '.');

  num? find(List<String> keys) {
    for (final key in keys) {
      final i = t.indexOf(key);
      if (i == -1) continue;
      final tail = t.substring(i + key.length);
      final m = RegExp(r'(\\d+(\\.\\d{1,2})?)\\s*(kcal|kj|g|mg|mcg)?').firstMatch(tail);
      if (m != null) {
        final val = num.tryParse(m.group(1)!);
        if (val != null) return val;
      }
    }
    return null;
  }

  final isLiquid = t.contains('100 ml') || t.contains('ml için');

  return Nutrients(
    isLiquid: isLiquid,
    energyKcal: find(['enerji', 'energy']),
    proteinG:   find(['protein']),
    fatG:       find(['yağ', 'yag', 'fat']),
    satFatG:    find(['doymuş yağ', 'doymus yag', 'saturated']),
    carbsG:     find(['karbonhidrat', 'carb']),
    sugarsG:    find(['şeker', 'seker', 'sugar']),
    saltG:      find(['tuz', 'salt', 'sodyum']),
  );
}