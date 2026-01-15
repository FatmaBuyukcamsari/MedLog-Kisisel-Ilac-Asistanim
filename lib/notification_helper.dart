import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'dart:io';
import 'medicine_model.dart';
import 'package:flutter/foundation.dart';

class NotificationHelper {
  static final NotificationHelper _instance = NotificationHelper._internal();
  factory NotificationHelper() => _instance;
  NotificationHelper._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // 1. Timezone veritabanını yükle
    tz.initializeTimeZones();
    
    // 2. Sistem saat dilimini kontrol et (Debug amaçlı)
    try {
       final String currentTimeZone = DateTime.now().timeZoneName; 
       if (kDebugMode) print("Sistem Zaman Dilimi: $currentTimeZone");
    } catch (e) {
       if (kDebugMode) print("Zaman dilimi hatası: $e");
    }

    // Android için varsayılan ikon ayarı
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    
    await _notifications.initialize(settings);

    // İzinleri İste (Android 13+ ve 12+ için kritik)
    if (Platform.isAndroid) {
      final androidImplementation = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      // Bildirim gösterme izni
      await androidImplementation?.requestNotificationsPermission();
      // Tam zamanlı alarm kurma izni
      await androidImplementation?.requestExactAlarmsPermission(); 
    }
  }

  Future<void> scheduleMedicineNotifications(Medicine med) async {
    // Eski bildirimleri temizle (Çakışma olmasın)
    await _notifications.cancel(med.id!);

    final slots = med.dayConfig['slots'] as Map<String, dynamic>?;
    if (slots == null) return;

    for (var entry in slots.entries) {
      String slotName = entry.key;
      String timeStr = entry.value['time']; // Örnek: "9:15 PM" veya "21:15"

      try {
        // --- YENİ VE AKILLI SAAT ÇEVİRİCİ ---
        // Önce saatin içinde PM veya AM var mı kontrol et
        bool isPm = timeStr.toLowerCase().contains("pm");
        bool isAm = timeStr.toLowerCase().contains("am");

        // ":" işaretinden böl
        final parts = timeStr.split(':');
        int hour = int.parse(parts[0].trim());
        
        // Dakika kısmındaki harfleri temizle (sadece sayıyı al)
        final minutePart = parts[1].trim().replaceAll(RegExp(r'[^0-9]'), '');
        final minute = int.parse(minutePart);

        // Eğer PM ise ve saat 12'den küçükse, 12 ekle (Örn: 9 PM -> 21, ama 12 PM -> 12 kalır)
        if (isPm && hour < 12) {
          hour += 12;
        }
        // Eğer AM ise ve saat 12 ise, 0 yap (Gece yarısı 12 AM -> 00)
        else if (isAm && hour == 12) {
          hour = 0;
        }
        // -------------------------------------

        // Benzersiz ID oluştur
        int notificationId = med.id! + slotName.hashCode;
        
        // Emülatörün saat dilimine göre zamanı hesapla
        final scheduledTime = _nextInstance(hour, minute);
        
        if (kDebugMode) {
          print("--- ALARM KURULUYOR ---");
          print("Gelen String: $timeStr");
          print("Çevrilen Saat (24h): $hour:$minute");
          print("Emülatör Şu An: ${DateTime.now()}");
          print("Alarmın Çalacağı Zaman: $scheduledTime");
          print("-----------------------");
        }

        await _notifications.zonedSchedule(
          notificationId,
          'İlaç Vakti: ${med.name}',
          '$slotName dozunu almayı unutma! ($timeStr)',
          scheduledTime,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'med_channel_id_v2', // Kanal ID (v2 yaptık, ayarlar sıfırlansın)
              'İlaç Bildirimleri',
              channelDescription: 'İlaç saati geldiğinde bildirim gönderir', 
              importance: Importance.max,
              priority: Priority.high,
              playSound: true,
              icon: '@mipmap/ic_launcher', // İkon kesin eklendi
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, 
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time, // Her gün tekrar et
        );

      } catch (e) {
        if (kDebugMode) print("Hata: $e");
      }
    }
  }

  tz.TZDateTime _nextInstance(int hour, int minute) {
    // "tz.local" kullanarak emülatörün o anki saati neyse onu baz alıyoruz
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    
    // Eğer saat geçmişse yarına kur
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}