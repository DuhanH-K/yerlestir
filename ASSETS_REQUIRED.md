# Görseller ve Sesler

Çalışmayı engelleyen eksik asset yoktur. Görseller yüklenemezse renkli arka plan/yazı fallback'i kullanılır;
ses hataları oyun akışını durdurmaz.

| Dosya | Kaynak / kullanım |
| --- | --- |
| assets/backgrounds/coast.png | Yerleşik image_gen ile bu proje için üretilen yazısız Akdeniz sahnesi |
| assets/backgrounds/logo.png | Yerleşik image_gen ile üretilen şeffaf Yerleştir! logosu |
| assets/sounds/place.wav | Yerel sentez, kısa yerleştirme sesi |
| assets/sounds/pop_8.wav … pop_64.wav | Yerel sentez, 28 ms aralıklı balon patlamaları |
| assets/sounds/clear.wav | Yerel sentez, temizleme akoru |
| assets/sounds/music.wav | Yerel sentez, 12 saniyelik düşük sesli döngü |
| android/app/src/main/res/drawable/ic_launcher.xml | Kodla oluşturulan native vektör uygulama simgesi |
| web/favicon.svg | Kodla oluşturulan web simgesi |

Ses üretimini tekrarlamak için proje kökünden `python tools/generate_audio.py` çalıştırılır.
Arayüz blokları Flutter tarafından çizilir; bütün ekran tek görsel üzerine görünmez butonlardan oluşmaz.
Tema değişiklikleri gerçek oyun tahtası ve parça paletine yansır.

## Kullanılan son görsel istemleri

Araç: yerleşik `image_gen`; API/CLI fallback kullanılmadı. Üretilen dosyalar proje içine kopyalandı.

### coast.png
Create a polished portrait mobile puzzle game background, 9:16. Charming premium 3D cartoon Mediterranean seaside terrace, turquoise Aegean sea, distant white village with terracotta roofs on right, blue sky upper half, cream limestone terrace lower third, bougainvillea pink flowers and green foliage framing outer edges. A small adorable sleeping orange tabby cat on a limestone ledge on far left around mid-height. Beautiful warm sunshine, vivid cyan sky, soft cinematic depth. Central 75% area very uncluttered to overlay functional game UI. NO text, NO letters, NO interface, NO buttons, NO blocks, NO logos. Full bleed illustration.

### logo.png
Use case logo-brand. Create a premium mobile block puzzle game logo on a genuinely transparent background (alpha). Exact Turkish lettering: "Yerleştir!" with correctly dotted i and ş. Huge playful rounded chunky 3D golden yellow letters with orange extruded sides, thick deep navy blue outline and glossy highlights. One small red L-shaped cluster of three shiny square puzzle blocks floating above the left side and one cyan L-shaped cluster above right. Tight horizontal composition approximately 2:1, logo occupies canvas. Professional polished 3D casual game branding matching cheerful Mediterranean puzzle art. No tagline, no other text, no background, no white rectangle, no scenery. Transparent outside all artwork.

Android kombo konuşması kurulu çevrimdışı TextToSpeech sesiyle üretilir; ağ gerektiren sesler seçilmez. Türkçe ses yoksa görsel kutlama ve patlama sesi sürer.
