import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'medicine_model.dart';
import 'database_helper.dart';
import 'notification_helper.dart';
import 'tracking_page.dart';
import 'add_medicine_sheet.dart';
import 'archive_page.dart';
import 'package:timezone/data/latest_all.dart' as tz; // latest yerine latest_all daha garanti
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart'; // Yeni eklediğimiz paket

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Timezone veritabanını yükle
  tz.initializeTimeZones();
  
  // 2. EMÜLATÖRÜN (TELEFONUN) SAAT DİLİMİNİ OTOMATİK BUL VE AYARLA
  try {
    var localTimezone = await FlutterTimezone.getLocalTimezone();
    final String currentTimeZone = localTimezone.toString();
    tz.setLocalLocation(tz.getLocation(currentTimeZone));
    print("Cihaz Zaman Dilimi Ayarlandı: $currentTimeZone");
  } catch (e) {
    print("Saat dilimi alınamadı, UTC kullanılıyor: $e");
    // Hata olursa varsayılan olarak UTC veya İstanbul'a düşebilirsin
    // tz.setLocalLocation(tz.getLocation('Europe/Istanbul')); 
  }

  // 3. Tarih formatını ayarla
  await initializeDateFormatting('tr_TR', null);
  
  // 4. Bildirim Servisini Başlat
  await NotificationHelper().init(); 
  
  runApp(const MedLogApp());
}

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

class MedLogApp extends StatelessWidget {
  const MedLogApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) => MaterialApp(
        debugShowCheckedModeBanner: false,
        themeMode: mode,
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
        darkTheme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal, brightness: Brightness.dark),
        home: const MainScreen(),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _idx = 1; // Başlangıçta Takvim (Ortadaki sayfa) açılsın

  // Sayfaları buraya tanımlıyoruz.
  // Bu yöntemle her sekme değişiminde sayfa yenilenir ve STOK GÜNCELLENİR.
  final List<Widget> _pages = [
    const MedicinePage(),
    const TrackingPage(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      
      body: _pages[_idx], // IndexedStack yerine bunu kullandım ki veriler yenilensin.
      
      bottomNavigationBar: NavigationBar(
        selectedIndex: _idx,
        onDestinationSelected: (i) => setState(() => _idx = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.medication), label: 'İlaçlarım'),
          NavigationDestination(icon: Icon(Icons.calendar_month), label: 'Takvim'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Ayarlar'),
        ],
      ),
    );
  }
}

// --- İLAÇLARIM SAYFASI ---
class MedicinePage extends StatefulWidget {
  const MedicinePage({super.key});
  @override
  State<MedicinePage> createState() => _MedicinePageState();
}

class _MedicinePageState extends State<MedicinePage> {
  List<Medicine> meds = [];
  
  // Veritabanından ilaçları çeken fonksiyon
  void refresh() async { 
    meds = await DatabaseHelper().getMedicines(); 
    if (mounted) setState(() {}); 
  }

  @override
  void initState() { 
    super.initState(); 
    refresh(); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar'ı sildik, yerine özel tasarımımızı koyuyoruz.
      body: Column(
        children: [
          // --- 1. ÖZEL YEŞİL BAŞLIK ALANI (MEDLOG) ---
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 15,
              bottom: 15
            ),
            decoration: const BoxDecoration(
              color: Colors.teal,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20))
            ),
            child: Column(
              children: const [
                Text(
                  "MEDLOG", 
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    letterSpacing: 1.5, 
                    fontSize: 24, 
                    color: Colors.white
                  )
                ),
                Text(
                  "Kişisel İlaç Asistanım", 
                  style: TextStyle(
                    fontSize: 12, 
                    fontWeight: FontWeight.w300, 
                    color: Colors.white70
                  )
                ),
              ],
            ),
          ),

          // --- 2. İLAÇ LİSTESİ ---
          Expanded(
            child: meds.isEmpty 
              ? const Center(
                  child: Text(
                    "Henüz ilaç eklenmedi.", 
                    style: TextStyle(color: Colors.grey)
                  )
                )
              : ListView.builder(
                  itemCount: meds.length,
                  padding: const EdgeInsets.only(top: 10, bottom: 80), 
                  itemBuilder: (c, i) {
                    final m = meds[i];
                    
                    // Stok kritik mi kontrolü
                    bool critical = m.stock <= 5;
                    
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: ListTile(
                        // Tıklayınca düzenleme penceresini açar (Eski fonksiyonun)
                        onTap: () => _showAddSheet(med: m), 
                        leading: CircleAvatar(
                          backgroundColor: critical ? Colors.red : Colors.teal, 
                          child: Text(
                            m.stock.toString(), 
                            style: const TextStyle(color: Color.fromARGB(255, 16, 69, 1), fontWeight: FontWeight.bold)
                          )
                        ),
                        title: Text(
                          m.name, 
                          style: TextStyle(
                            color: critical ? Colors.red : const Color.fromARGB(255, 0, 0, 0), 
                            fontWeight: FontWeight.bold
                          )
                        ),
                        subtitle: Text(
                          "Tür: ${m.type} | Başlangıç: ${m.startDate.split(" ")[0]}",
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.grey),
                          // Silme onayı fonksiyonun
                          onPressed: () => _confirmDelete(m.id!), 
                        ),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
      
      // SAĞ ALTAKİ EKLEME BUTONU
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSheet(),
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _confirmDelete(int id) {
    showDialog(context: context, builder: (c) => AlertDialog(
      title: const Text("Silinsin mi?"),
      content: const Text("Bu ilaç arşive taşınacak."),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: const Text("İptal")),
        ElevatedButton(
          onPressed: () async { 
            await DatabaseHelper().softDelete(id); 
            Navigator.pop(c); 
            refresh(); 
          }, 
          child: const Text("Sil")
        ),
      ],
    ));
  }

  void _showAddSheet({Medicine? med}) {
    showModalBottomSheet(
      context: context, 
      isScrollControlled: true, 
      builder: (c) => AddMedicineSheet(onSaved: refresh, editMed: med)
    );
  }
}

// --- GÜNCELLENMİŞ AYARLAR SAYFASI ---
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar YOK, sildik.
      body: Column(
        children: [
          // 1. ÖZEL YEŞİL BAŞLIK ALANI
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 15, // Çentik payı
              bottom: 15
            ),
            decoration: const BoxDecoration(
              color: Colors.teal,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20))
            ),
            child: Column(
              children: const [
                Text(
                  "MEDLOG",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    fontSize: 24,
                    color: Colors.white
                  )
                ),
                Text(
                  "Kişisel İlaç Asistanım",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w300,
                    color: Colors.white70
                  )
                ),
              ],
            ),
          ),

          // 2. AYARLAR LİSTESİ
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 10), // Başlıkla araya az mesafe
              children: [
                ValueListenableBuilder<ThemeMode>(
                  valueListenable: themeNotifier, 
                  builder: (context, mode, child) {
                    return SwitchListTile(
                      secondary: const Icon(Icons.dark_mode, color: Colors.teal), // İkon rengi yeşil oldu
                      title: const Text("Koyu Mod"),
                      value: mode == ThemeMode.dark,
                      activeColor: Colors.teal, // Switch açılınca yeşil olsun
                      onChanged: (v) {
                        themeNotifier.value = v ? ThemeMode.dark : ThemeMode.light;
                      },
                    );
                  },
                ),
                
                const Divider(indent: 20, endIndent: 20), // Araya ince çizgi
                
                ListTile(
                  leading: const Icon(Icons.archive_outlined, color: Colors.teal), // İkon rengi yeşil oldu
                  title: const Text("Arşiv (Silinen İlaçlar)"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey), // Sağa ok işareti
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const ArchivePage())),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


