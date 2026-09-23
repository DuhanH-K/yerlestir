# Oyun Tasarımı — Yerleştir!

## Temel döngü
Üç sabit yönlü poliyomino şekil 8×8 tahtaya yerleştirilir. Şekiller döndürülmez.
Dolu satır/sütunlar, kesişim hücreleri dahil aynı anlık tahtadan hesaplanıp tek işlemde temizlenir.
Üç şekil kullanıldığında yeni üçlü gelir. Geçersiz yerleştirme turu veya puanı değiştirmez.
Tahtada boşluk aranırken tüm 64 olası başlangıç konumu kontrol edilir.

## Skor ve performans
Yerleştirilen hücre başına 10 puan.
Temizlenen çizgi başına 80 × kombo puan.
Temizlemeli ardışık hamleler komboyu artırır; temizlemeyen hamle sıfırlar.
Yolculuk hedefi: 220 + bölüm × 35. Hamle bütçesi: 20 + min(bölüm ~/ 5, 12).
İlk 40 bölüm Ege Kıyıları, sonraki 40 Tarihin İzinde, son 40 Güzel Yarınlar.
Hedefe hamle bütçesinin ilk %70'inde ulaşmak 3, ilk %90'ında 2, kalanında 1 yıldız getirir.
Günlük hedef 800 puan, bütçe 30 hamledir. Tarih YYYYMMDD tohumu kullanılır.
Klasikte zaman veya hamle sınırı yoktur; parçalardan hiçbiri sığmadığında tur biter.

## İpucu ve geri bildirim
Sarı lambaya dokunmak 30 altına en iyi geçerli yerleşimi gösterir; çizgi temizleme önceliklidir.
İpucu hamle yapılana kadar kayıtlıdır; aynı öneriye ikinci kez ücret alınmaz.
Bomba ve parça yenileme bulunmaz. Hiçbir parça sığmıyorsa tur biter.
Geçersiz hamlede 320 ms hafif sarsılma; çizgi temizlemede yerleştirme tarafından sıralı 600 ms balon patlaması.

## Ekonomi
İlk bölüm/günlük tamamlamasında 50 altın, üç yıldızda ilave 20.
Klasik tur başına en az 500 puanda 20 altın.
Günlük giriş yedi günde toplam 460 altın verir. Gün kaçırmak sırayı sıfırlamaz.
Temalar: Klasik ücretsiz, Gün Batımı 4990, Orman 4990, Gece 8990.
Blok paletleri: Şeker 790, Okyanus 990.
Satın alma yalnız yerel oyun altınıyla yapılır ve görünüm kalıcı olarak açılır.

## Görsel ve erişilebilirlik
Portre düzeni, dar ekranlarda kaydırma, geniş ekranlarda en çok 560 mantıksal piksel.
Parça sürükleme dışında seç/dokun alternatifi vardır. Düğmelerde basılma animasyonu ve semantik etiketler bulunur.
Ses/müzik/titreşim kapatılabilir. Baskılı bir kaybetme ekranı yerine yeniden deneme sunulur.
Koleksiyon her beş ilk bölüm tamamlamasında bir yeni hatıra açar.
