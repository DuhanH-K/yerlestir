# YERLEŞTİR — App Store Connect taslak

## Store listing

**APP NAME:** YERLEŞTİR

**Subtitle (öneri, 30 karakter):** Düşün, yerleştir, tamamla

**Promotional Text (öneri):** Parçaları doğru yerlere yerleştir, satırları temizle ve her bölümde daha iyi hamleyi bul.

**Description:**

YERLEŞTİR, parçaları 8×8 tahtaya yerleştirerek satır ve sütunları tamamladığın sade ve dikkat isteyen bir bulmaca oyunudur.

Parçaları seç, tahtada uygun alanı düşün ve hamleni yap. Dolu satır ve sütunları temizleyerek alan aç, kombo kur ve puanını yükselt. Klasik, Yolculuk ve Günlük modlarda kendi ritminde ilerle.

- Öğrenmesi kolay, ustalaşması keyifli oynanış
- Kısa ve tekrar oynanabilir bölümler
- Klasik, Yolculuk ve Günlük oyun modları
- İpucu sistemi ve oyun içi günlük ödüller
- Hesap açmadan, çevrimdışı oynanabilen temel oyun

YERLEŞTİR ücretsiz oynanır. Reklamlar ve bazı reklam destekli ödüller için internet bağlantısı gerekebilir.

**Keywords (100 karakter altında öneri):** bulmaca,blok,zeka,oyun,yerleştir,tahta,kombo,offline,günlük,klasik

**Support URL:** https://yerlestir.web.app/support

**Marketing URL:** https://yerlestir.web.app/

**Privacy Policy URL:** https://yerlestir.web.app/privacy

**Category:** Games → Puzzle

**Secondary Category:** Games → Casual

**Copyright:** © 2026 Duhan Hamit Kaplan

## Age Rating

Mevcut içerik temelinde önerilen cevaplar:

- Cartoon or Fantasy Violence: No
- Realistic Violence: No
- Sexual Content or Nudity: No
- Profanity or Crude Humor: No
- Alcohol, Tobacco, or Drug Use: No
- Gambling: No
- Horror or Fear Themes: No
- Medical/Treatment Information: No
- User-Generated Content: No
- Unrestricted Web Access: No
- Loot Boxes: No

Reklamların varlığı ve uygulama içi reklam davranışı App Store Connect yaş derecelendirme sorularında ayrıca doğru şekilde işaretlenmelidir. Apple'ın güncel soru formu son kontroldür.

## Kids Category

YERLEŞTİR genel kullanıcı kitlesi için tasarlanmıştır; yalnızca çocuklara özel bir uygulama olarak konumlandırılmamıştır. Bu nedenle Kids Category önerilmez. Mini Melodi'nin ayarı kopyalanmamıştır. AdMob kullanımı nedeniyle Kids Category seçimi ayrıca Apple'ın güncel kurallarıyla değerlendirilmelidir.

## App Review Notes

```
No account or login is required.

The reviewer can open the app and select Classic, Journey, or Daily from the home screen. Select a piece from the tray, then tap an available top-left board cell to place it. Completing a full row or column clears it. The game saves progress locally on the device.

The app may show Google Mobile Ads on Android and iOS. In regions where consent is required, the Google consent flow is shown before ads are requested. The core game does not require an account or paid purchase.
```

## APP PRIVACY

Bu öneri, `google_mobile_ads` SDK'sının build'e dahil olması ve uygulamanın AdMob reklamları göstermesi temel alınarak hazırlanmıştır. App Store Connect'te SDK'nın güncel veri güvenliği beyanını da kontrol et:

- **Data Collected:** Yes, data from this app may be collected by Google Mobile Ads.
- **Identifiers:** Device ID / Advertising ID, SDK'nın reklam sunumu ve ölçümü için kullandığı kapsamda.
- **Usage Data:** Product interaction / advertising interaction, reklam gösterimi ve etkileşimi kapsamında.
- **Diagnostics:** SDK'nın hata ve performans tanılaması etkinse Diagnostics olarak bildir.
- **Contact Info, Location, User Content, Purchases:** Bu uygulama kodunda kullanıcı hesabı, konum, kişi listesi, kamera, mikrofon, kullanıcı içeriği veya satın alma akışı bulunmadığı için seçilmemeli.
- **Tracking:** ATT izni ve gerçek reklam yapılandırması App Store Connect beyanıyla birlikte kontrol edilmeli. Uygulama kodu doğrudan IDFA/AdSupport çağrısı yapmıyor; ATT metni eklenmedi.
- **Linked to User:** Reklam SDK'sının kendi ilişkilendirme davranışını güncel Google beyanından kontrol et; doğrulanmadan “not linked” seçme.
- **Used for Tracking:** Kullanıcı ATT izni olmadan IDFA tabanlı tracking yapılmıyor; kişiselleştirilmiş reklam seçeneğini Google consent ve Apple izinleriyle uyumlu beyan et.

Uygulama ilerlemesi ve ayarlar cihazda `shared_preferences` ile yerel tutulur; bu veriler uygulamanın kendi sunucusuna gönderilmez.

## Build bilgisi

- Bundle ID: `com.yerlestir.game.yerlestir`
- Version: `1.0.0`
- Current build: `1`
- iOS production App ID: `ca-app-pub-4879558726064660~4522234287`
- iOS production banner/interstitial/rewarded ID'leri Dart platform seçimiyle iOS release'te kullanılır.
