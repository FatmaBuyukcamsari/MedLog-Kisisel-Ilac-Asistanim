# MEDLOG KİSİSEL İLAC ASISTANIM


[▶️ Proje Tanıtım Videosunu İzlemek İçin Tıkla](https://youtu.be/Swn1Xp4rR7w)




#  MedLog - Kişisel İlaç Takip Asistanı

**MedLog**, kullanıcıların ilaçlarını zamanında almasını sağlayan, stok takibi yapabilen ve gelişmiş bildirim sistemine sahip bir Flutter uygulamasıdır. 


##  Özellikler

* ** Akıllı Bildirim Sistemi:** * Cihazın yerel saat dilimini (`flutter_timezone`) otomatik algılar.
    * Emülatör ve gerçek cihaz arasındaki saat farkı sorununu ortadan kaldırır.
    * İlaç saatlerini "AM/PM" veya "24 Saat" formatında sorunsuz işler.
* ** Stok Takibi & Uyarılar:**
    * Her ilaç için kalan stok miktarını gösterir.
    * Stok kritik seviyeye (5 ve altı) düştüğünde gösterge **kırmızıya** döner.
* ** Koyu/Açık Mod Desteği:** * `ValueNotifier` ile anlık tema değişimi.
    * Göz yormayan özel "Teal" (Turkuaz) renk paleti.
* **Arşivleme (Soft Delete):**
    * İlaçlar silindiğinde kaybolmaz, "Arşiv" klasörüne taşınır.
    * Yanlışlıkla silinen ilaçlar geri getirilebilir.
* ** Çevrimdışı Veritabanı:**
    * SQLite (`sqflite`) ile veriler cihazda güvenle saklanır. İnternet gerektirmez.

## 🛠️ Kullanılan Teknolojiler ve Paketler

Proje **Flutter** altyapısı ile geliştirilmiştir ve aşağıdaki temel paketleri kullanır:

| Paket | Amaç |
|---|---|
| `flutter_local_notifications` | Zamanlanmış yerel bildirimler için. |
| `flutter_timezone` | Cihazın saat dilimini (Örn: Europe/Istanbul) algılamak için. |
| `timezone` | Tarih ve saat hesaplamaları için. |
| `sqflite` | Yerel SQL veritabanı yönetimi. |
| `intl` | Tarih formatlama ve yerelleştirme. |
| `path_provider` | Dosya yollarına erişim. |

## 📸 Ekran Görüntüleri ve İşleyiş

* İlaç ekleme ekranın 3 kategoride ilaç ekleyebilirsiniz: Günlük, Haftalık ve Özel.
* Günlük içmeniz gereken ilaçlar için günlük kategorisini kullanabilirsiniz.
* Haftanın belirli günlerinde, belirli saat ve öğünlerde, belirli dozlarda almanız gereken ilaçlar için Haftalık kategorisini kullanabilirsiniz.
* Özel kategorisinde saatlik almanız gereken ilaçlar için tasarlanmıştır.

  
| <img src="EkranGoruntusu/ilaceklegunluk.png" width="200" > |
| <img src="EkranGoruntusu/ilaceklehaftalik.png" width="200"> |
| <img src="EkranGoruntusu/ilacekleozel.png" width="200"> |




* Takvim sayfasından ilacınızın takibini yapabilirsiniz.




| <img src="EkranGoruntusu/takvim1.png" width="200"> |
| <img src="EkranGoruntusu/takvim2.png" width="200"> |
| <img src="EkranGoruntusu/ilacicme1.png" width="200"> |
| <img src="EkranGoruntusu/ilacicme2.png" width="200"> |
| <img src="EkranGoruntusu/ozelilaclar.png" width="200"> |



*Stoğunuz 5'in altına düştüğünde uygulama size ilacınızın azaldığını gösterecek ve ilacınızı kırmızılaştıracaktr.



| <img src="EkranGoruntusu/stokazalma.png" width="200"> |
| <img src="EkranGoruntusu/stokyetersiz.png" width="200"> |






*İlacınızı düzenlemek için ilaçlarım sayfasında düzenlemek/güncellemek istediğiniz ilacın üzerine bir kez tıklamanız yeterlidir.


| <img src="EkranGoruntusu/ilacıduzenle.png" width="200"> |
| <img src="EkranGoruntusu/duzenlenmisilac.png" width="200"> |




*Ayarlar sayfasından uygulamanızın koyu/açık mod ayarını yapabilirsiniz. Dilerseniz Arşivden sildiğiniz ilaçları geri getirebilir ya da tamamen silebilirsiniz.




| <img src="EkranGoruntusu/acıkmodveayarlar.png" width="200"> |
| <img src="EkranGoruntusu/ilacarsivi.png" width="200"> |
| <img src="EkranGoruntusu/ilacsilme.png" width="200"> |
| <img src="EkranGoruntusu/geriyukleme.png" width="200"> |
| <img src="EkranGoruntusu/tamamensilme.png" width="200"> |



## Notlar

* **Android Ayarları:** Bildirimlerin çalışması için `AndroidManifest.xml` içinde gerekli izinlerin (`RECEIVE_BOOT_COMPLETED`, `VIBRATE`) tanımlı olduğundan emin olun.
* **Timezone:** Uygulama `main.dart` içinde `tz.initializeTimeZones()` fonksiyonunu asenkron olarak bekler.

## Katkıda Bulunma

Her türlü katkıya açığım. Hata bildirmek veya yeni özellik eklemek için lütfen "Issue" açın veya "Pull Request" gönderin.

---
**Geliştirici:** [Fatma Büyükçamsarı-132330014]
