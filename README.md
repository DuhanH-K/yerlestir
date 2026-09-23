# Yerleştir!

Flutter ile geliştirilen, internet bağlantısı gerektirmeyen portre blok bulmaca oyunu.
Oyun hesap veya sunucu gerektirmez. Android sürümünde Google Mobile Ads banner ve geçiş reklamları bulunur; geliştirme sürümü varsayılan olarak Google test reklamlarını kullanır.

## İçerik

- Gerçek 8×8 oyun tahtası; dokunma ve sürükleme, geçerli/geçersiz konum önizlemesi.
- Satır ve sütunların aynı hamlede birlikte temizlenmesi; art arda temizlemelerde kombo.
- Klasik sonsuz mod, 120 veri odaklı yolculuk bölümü ve tarih tohumlu günlük bulmaca.
- Sarı lamba ile 30 oyun altınına ipucu; aynı ipucu için tekrar ücret alınmaz. Klasikte zaman sınırı yoktur.
- Ana menü, açılış, yolculuk, oyun, sonuç, mağaza, günlük ödül, koleksiyon, ayarlar ve ebeveyn kontrolü.
- 24 koleksiyon hatırası; her beş tamamlanan yolculuk bölümünde bir açılır.
- Dört tema ve iki blok paleti. Mağazadaki görünümler ortak görünüm yuvasına uygulanır.
- Ses, müzik, titreşim, TR/EN ekran metinleri ve ebeveyn kilidi. Marka/slogan ve bölge adları Türkçedir.
- Her hamlede yerel kayıt; kaldığın turu, parçaları ve aynı rastgele sayı sırasını geri yükleme.
- Sürümlü kayıt doğrulama, son sağlam kayıt yedeği ve depolama hatası bildirimi.
- Hareketli düğmeler, parlak bloklar, bölüm kutlaması, özgün logo ve Akdeniz arka planı.

## Çalıştırma

Gerekenler: Flutter stable (bu çalışma: 3.47.0 / Dart 3.13.0), Android SDK ve Java 17+.

```powershell
flutter pub get
flutter run -d chrome
flutter run -d <android-device-id>
```

Bu bilgisayarda Flutter analiz sunucusu Türkçe karakter içeren proje yolunda hata verdiği için
kaynakları taşımadan `C:\Projects\yerlestir-build` adlı bir junction oluşturuldu. Bu yol aynı dosyalara gider.
Analiz ve derlemeleri o dizinden çalıştır:

```powershell
cd C:\Projects\yerlestir-build
dart format lib test
flutter analyze
flutter test
flutter build apk --debug
```

Son APK: `output/Yerlestir-debug.apk`.
Standart Flutter çıktısı: `build/app/outputs/flutter-apk/app-debug.apk`.
Bu bir kurulabilir debug APK'dır. Mağaza yayını için geliştiriciye ait imzalama anahtarıyla release/AAB hazırlanmalıdır.
Bağlı kişisel telefona otomatik kurulum yapılmamıştır.

## Mimari

`lib/app`: bootstrap sonrası uygulama, yönlendirme ve açılış.
`lib/core`: ortak bileşenler, geri bildirim, reklam soyutlaması ve kayıt durumu.
`lib/features/gameplay/domain`: tahta kuralları, şekiller, seviye fabrikası.
`lib/features/gameplay/application`: tur durumu, skor, yardımcılar, deterministik devam.
`lib/features/gameplay/presentation`: etkileşimli tahta, oyun ekranı, yardım ve sonuç.
`lib/features/progress`: PlayerProgress, ProgressRepository, SharedPreferences adapter ve Riverpod controller.
Diğer feature klasörleri menü, yolculuk, mağaza, günlük ödül ve ayarları içerir.

## Kayıt ve ödüller

Ana anahtar `yerlestir_progress_v1`, yedek `yerlestir_progress_v1_backup`.
JSON bozuksa son sağlam yedeğe, o da geçersizse güvenli varsayılana dönülür.
Yazımlar sıraya alınır. İlerlemeyi sıfırlama iki kaydı da temizler.
Yolculuk/günlük bölüm ödülleri yalnız ilk tamamlamada verilir; yeniden oynama yıldızları iyileştirebilir.
Klasikte 500+ puanla tur bitirildiğinde 20 altın verilir. Aynı tur ikinci kez ödüllendirilemez.
Günlük ödül 20/30/40/50/70/100/150 döngüsündedir; aynı tarih ve geriye alınmış tarih yeniden ödül vermez.
Tamamen çevrimdışı olduğundan cihaz saatini ileri alma sunucu olmadan doğrulanamaz.

## Reklam noktaları

`lib/core/services/ad_service.dart` Google Mobile Ads SDK adaptörüdür. Banner yüklenince
ayrı alt alanda gösterilir; yüklenmezse boş reklam barı bırakılmaz. Geçiş reklamları
en az üç hamlelik iki turun ardından, en az 90 saniye arayla, bitiş animasyonu ve
sonuç ekranı arasında gösterilir. Hazır olmayan reklam için oyun bekletilmez.

Release derlemeleri artık gerçek reklam kimliklerini kullanır; debug/profile
Google test reklamları kullanır. Release sürümünde test için
`--dart-define=ADS_TEST_MODE=true` eklenir. Kimlikler projede kayıtlıdır.
AdMob gizlilik mesajları, app-ads.txt ve uygulama incelemesi panelde ayrıca
tamamlanmalıdır. Release halen debug anahtarıyla imzalanmaktadır;
mağaza yayını için yayın anahtarı gereklidir.

Kaynaklar: [Google banner](https://developers.google.com/admob/flutter/banner),
[geçiş reklamı](https://developers.google.com/admob/flutter/interstitial),
[UMP](https://developers.google.com/admob/flutter/privacy).

## Kontroller

Test kapsamı:

Unit testler: çakışma/sınırlar, kesişen satır-sütun temizliği, hamle arama, günlük deterministik sıra,
kayıttan aynı RNG sırasıyla devam, yardımcılar, hedefler, bozuk/yedek kayıt, ödül yarışları ve tekrar ödülü.
Widget testleri: küçük telefon ekranları, günlük ödül, dokunma, sürükleme, duraklat/devam ve bölümden sonraki bölüme geçiş.
Son kontrol sonuçları ve artefakt bilgileri `output/VALIDATION.md` içindedir.
Görseller referansların işlevsel Flutter uyarlamasıdır; ekranların tek parça görsel kopyası değildir.

## Oynanış düzenlemesi

Oyun ekranında sade mavi zemin, büyük skor, küçük rekor göstergesi ve sarı ipucu lambası vardır. Tahta ve üç parça kaydırmadan ekrana sığar. Sürüklenen parça tahta hücresi ölçüsündedir ve parmağın üzerinde görünür. Çizgi patlamaları yerleştirme tarafından 28 ms aralıklarla ilerler; toplam animasyon 600 ms sürer. Geçersiz hamlede kısa sarsılma olur. Android cihazda kurulu çevrimdışı Türkçe ses varsa Harika, Mükemmel ve Muhteşem kombo seslendirilir. Ses ayarı bunu da kontrol eder.

Telefon için performans derlemesi: `flutter build apk --release --target-platform android-arm64`. Bu yerel paket debug anahtarıyla imzalanır; mağaza dağıtımı için özel anahtar gerekir.

Son değişiklikler: yeni turda 850 ms renkli tahta açılışı, puan parlaması ve yeni rekor kutlaması. Beşli parçanın alt satıra bırakılması için hedef, parmak yerine görünen parçanın merkezidir. Önizleme yarı saydamdır. Telefon sürümü `output/Yerlestir-release.apk` (ARM64).

## Kademeli zorluk

Klasikte her 12 hamlede, yolculukta bölüm ve hamle ilerledikçe altı kademeli
zorluk artar. Üçlüler çizgi temizlemelerini içeren geçerli bir çözüm planıyla üretilir.
İleri kademeler daha fazla farklı yönlü şekil, karışık parça sırası ve önce çizgi
açarak yer yaratmayı gerektiren diziler seçer. Bütün parçalara en baştan yer olması
gerekmez; doğru sıra oynandığında üçünün de sığması gerekir. Kullanıcının her
yerleştirmesi garantili değildir. İpucu kalan parçaları birlikte çözmeye çalışır.

Windows Türkçe klasör yolu için geçici ASCII sürücü yolu kullanılabilir:
`subst Y: "C:\Users\pc\Documents\ChatGPT\yerleştir"`, ardından `Y:` üzerinden
`flutter analyze` ve `flutter build apk --release`. Kotlin farklı sürücü kökleri
için artımlı önbellek kapalıdır.

Reklaml� devam: kaybedilen turda bir kez �d�ll� reklam izleyerek alt �� sat�r� temizle, yeni ��l� al ve s�n�rl� modlarda +5 hamle kazan. Erken kapat�lan veya y�klenmeyen reklam devam hakk� vermez. Ger�ek yay�n i�in `ADMOB_REWARDED_ID` de sa�lanmal�d�r.
