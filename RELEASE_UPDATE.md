# YERLEŞTİR 1.0.1 (2) güncellemesi

- Sürüm kaynağı: `pubspec.yaml`, `version: 1.0.1+2`.
- Android: Gradle `flutter.versionName` / `flutter.versionCode` kullanır.
- iOS: Info.plist `FLUTTER_BUILD_NAME` / `FLUTTER_BUILD_NUMBER` kullanır;
  Release.xcconfig Flutter'ın derlemede ürettiği Generated.xcconfig dosyasını içerir.
- Android ve iOS kimliği: `com.yerlestir.game.yerlestir`.
- Mevcut reklam kimlikleri, Android anahtarı ve iOS signing ayarları korunmuştur.

## Mevcut Codemagic UI workflow

Bu repoda codemagic.yaml yoktur. Yeni workflow eklenmedi. Buluttaki mevcut
workflow, sertifika/provisioning ve App Store Connect entegrasyonu bu ortamdan
doğrulanamadı. Windows üzerinde IPA üretilmedi.

Mevcut signed iOS release workflow'u main branch'in bu commit'i ile çalıştırın.
Flutter stable sürümü pubspec'teki Dart >=3.13 gereksinimini karşılamalıdır
(yerelde Flutter 3.47.0 / Dart 3.13.0 ile doğrulandı).
Eski --build-name / --build-number parametreleri veya ortam değişkenleri varsa
1.0.1 / 2 değerlerini geçersiz kılmamalıdır. Dinamik build sayacı kullanılıyorsa
App Store Connect'teki son build'den büyük bir değer kullanılmalıdır.
Signing/provisioning mevcut uygulamanın bundle ID'si ile eşleşmelidir.
Mevcut App Store Connect publishing ayarlarını koruyun.

Başarılı macOS archive sonrasında signed IPA, Runner.app.zip ve dSYM çıktıları
ile IPA'nın gerçek sürüm/build değerlerini Codemagic'te doğrulayın.
Bu çıktıların üretildiği veya mağazaya yüklendiği yerel kontrollerle kanıtlanamaz.

## Dağıtım

Android AAB mevcut Play Console uygulamasının kapalı test kanalına;
iOS signed IPA mevcut App Store Connect uygulamasına / TestFlight'a yüklenir.
Projede ve origin/main'de önceki sürüm 1.0.0+1 idi. Mağazaların mevcut en yüksek
build numarası bu ortamdan okunmadı; 2 zaten kullanılmışsa yeni build gerekir.

## Sürüm notları

- Daha akıcı blok yerleştirme ve çizgi temizleme efektleri.
- Oyun alanını kapatmayan kompakt kombo ve puan gösterimi.
- Çerçevesiz blok seçimi ve sadeleştirilmiş oyun arka planı.
- Güncellenmiş yerleştirme, temizleme ve kombo sesleri.
