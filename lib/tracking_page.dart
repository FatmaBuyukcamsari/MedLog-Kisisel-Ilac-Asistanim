import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'medicine_model.dart';
import 'database_helper.dart';
import 'special_meds_page.dart';

class TrackingPage extends StatefulWidget {
  const TrackingPage({super.key});

  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  DateTime _selectedDay = DateTime.now();
  final ScrollController _scrollController = ScrollController();
  final double _itemWidth = 70.0;
  
  
  // Veriyi burada tutacağız, sürekli veritabanını darlamayacağız.
  late Future<List<Medicine>> _medicinesFuture;

  @override
  void initState() {
    super.initState();
    // 1. Verileri sadece sayfa ilk açıldığında çek:
    _refreshMedicines();
    
    // 2. Takvimi bugüne odakla
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToDate(DateTime.now()));
  }

  // Verileri tazelemek için özel fonksiyon
  void _refreshMedicines() {
    setState(() {
      _medicinesFuture = DatabaseHelper().getMedicines();
    });
  }

  void _scrollToDate(DateTime date) {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final diffDays = date.difference(today).inDays;
    
    // Geçmiş günleri göstermiyorsak negatif index hatasını önle
    double targetIndex = diffDays < 0 ? 0 : diffDays.toDouble();

    double offset = (targetIndex * _itemWidth) - (MediaQuery.of(context).size.width / 2) + (_itemWidth / 2);
    
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        offset < 0 ? 0 : offset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

 Future<void> _selectDateFromCalendar() async {
    try {
      // Güvenlik Önlemi: Saat/Dakika farkı yüzünden çökmemesi için
      // tarihleri sadeleştiriyoruz.
      final DateTime now = DateTime.now();
      final DateTime firstDate = DateTime(2023, 1, 1);
      final DateTime lastDate = DateTime(2030, 12, 31);
      
      // Eğer seçili gün sınırlar dışındaysa bugüne çek
      DateTime initialDate = _selectedDay;
      if (initialDate.isBefore(firstDate) || initialDate.isAfter(lastDate)) {
        initialDate = now;
      }

      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: lastDate,
        
        // Tema (renk) ayarlarını şimdilik kaldırdım, belki donma sebebi budur.
        // Eğer bu şekilde çalışırsa renk kodunu sonra tekrar ekleriz.
        builder: (context, child) {
          return Theme(
            data: ThemeData.light().copyWith(
              colorScheme: const ColorScheme.light(
                primary: Colors.teal,
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: Colors.black,
              ),
            ),
            child: child!,
          );
        },
      );

      if (picked != null && picked != _selectedDay) {
        setState(() => _selectedDay = picked);
        _scrollToDate(picked);
      }
    } catch (e) {
      // Hata olursa konsola yaz ama uygulamayı dondurma
      debugPrint("Takvim Hatası: $e");
    }
  }

  // --- GÜNCELLENMİŞ STOK DÜŞME FONKSİYONU ---
  void _markAsTaken(Medicine med, String slot) async {
    // 1. DOZU HESAPLA (AKILLI KISIM)
    int amountToDrop = 1; // Eğer doz yazısı okunamazsa varsayılan 1 düşer

    try {
      // İlacın o anki gün ve vakit ayarlarına ulaşıyoruz
      Map<String, dynamic> currentSlots = {};
      
      // Haftalık mı Günlük mü diye kontrol edip doğru listeyi alıyoruz
      if (med.type == "Haftalık") {
        final dayName = DateFormat('E', 'tr_TR').format(_selectedDay);
        // Haftalık detayda o günün verisi var mı?
        if (med.dayConfig['weeklyDetail'] != null && med.dayConfig['weeklyDetail'][dayName] != null) {
          currentSlots = Map<String, dynamic>.from(med.dayConfig['weeklyDetail'][dayName]);
        }
      } else {
        // Normal (Her gün) ilaç
        if (med.dayConfig['slots'] != null) {
          currentSlots = Map<String, dynamic>.from(med.dayConfig['slots']);
        }
      }

      // Tıklanan vaktin (slot) detaylarına bakıyoruz (Örn: "Sabah")
      if (currentSlots.containsKey(slot)) {
        final slotData = currentSlots[slot]; 
        
        // Dose verisini çekiyoruz (Örn: "2 tablet")
        String doseString = "1";
        if (slotData is Map && slotData.containsKey('dose')) {
          doseString = slotData['dose'].toString();
        } else if (slotData is String) {
          // Eski veri yapısı string olabilir
          doseString = slotData;
        }

        // Yazının içindeki sayıyı bul (Regex)
        // "2 tablet" -> 2
        // "3 tane" -> 3
        final RegExp regExp = RegExp(r'\d+');
        final match = regExp.firstMatch(doseString);
        if (match != null) {
          amountToDrop = int.parse(match.group(0)!);
        }
      }
    } catch (e) {
      print("Doz hesaplama hatası: $e");
      amountToDrop = 1; // Hata olursa en azından 1 düşsün
    }

    // 2. VERİTABANI İŞLEMİ
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay);
    
    // BURASI DEĞİŞTİ: Artık sabit '1' yerine hesapladığımız 'amountToDrop'u gönderiyoruz
    bool success = await DatabaseHelper().markAsTaken(med, slot, dateStr, amountToDrop);
    
    if (success) {
      // Sadece işlem başarılıysa veriyi tazele ve ekranı güncelle
      _refreshMedicines();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            // Mesajda kaç adet düştüğünü de gösterelim
            content: Text("${med.name} - $slot alındı ($amountToDrop adet düşüldü)"), 
            backgroundColor: Colors.green, 
            duration: const Duration(milliseconds: 800)
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Stok yetersiz!"), backgroundColor: Colors.red),
        );
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // --- ÖZEL BAŞLIK ALANI ---
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
                Text("MEDLOG", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 24, color: Colors.white)),
                Text("Kişisel İlaç Asistanım", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w300, color: Colors.white70)),
              ],
            ),
          ),

          // 1. TAKVİM ŞERİDİ
          Container(
            height: 90,
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.05), 
              border: Border(bottom: BorderSide(color: Colors.teal.shade100))
            ),
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              itemCount: 3650, // SONSUZ DÖNGÜYÜ ENGELLEMEK İÇİN LİMİT (10 Yıl)
              itemBuilder: (context, index) {
                final date = DateTime.now().add(Duration(days: index));
                final isSelected = isSameDay(date, _selectedDay);
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedDay = date);
                    _scrollToDate(date);
                  },
                  child: Container(
                    width: _itemWidth - 10,
                    margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.teal : Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: isSelected ? [BoxShadow(color: Colors.teal.withOpacity(0.3), blurRadius: 5, offset: const Offset(0, 3))] : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(DateFormat('E', 'tr_TR').format(date).toUpperCase(), style: TextStyle(color: isSelected ? Colors.white70 : Colors.grey, fontSize: 10)),
                        Text("${date.day}", style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // TARİH VE TAKVİM İKONU
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('d MMMM yyyy', 'tr_TR').format(_selectedDay), 
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)
                ),
                IconButton(
                  onPressed: _selectDateFromCalendar,
                  icon: const Icon(Icons.calendar_month, color: Colors.teal),
                  tooltip: "Tarih Seç",
                )
              ],
            ),
          ),

          // 2. İLAÇ LİSTESİ (ARTIK OPTİMİZE EDİLDİ)
          Expanded(
            child: FutureBuilder<List<Medicine>>(
              future: _medicinesFuture, // ARTIK CACHE'LENMİŞ VERİYİ KULLANIYORUZ
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                   return const Center(child: Text("Henüz ilaç eklenmedi."));
                }
                
                final dayName = DateFormat('E', 'tr_TR').format(_selectedDay);
                
                final dailyMeds = snapshot.data!.where((m) {
                  // Arşivlenmiş ilaçları gösterme
                  if (m.isDeleted == 1) return false; // Eğer modelinde isDeleted varsa kullan, yoksa veritabanı zaten getirmez.
                  
                  if (m.type == "Özel") return false;

                  final startDate = DateTime.parse(m.startDate);
                  final onlyDateStart = DateTime(startDate.year, startDate.month, startDate.day);
                  final onlySelectedDay = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
                  
                  if (onlySelectedDay.isBefore(onlyDateStart)) return false;

                  if (m.type == "Haftalık") {
                    return m.dayConfig['weeklyDetail']?.containsKey(dayName) ?? false;
                  }
                  return true;
                }).toList();

                if (dailyMeds.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.event_available, size: 50, color: Colors.grey),
                        SizedBox(height: 10),
                        Text("Bugün için planlanmış ilaç yok.", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  itemCount: dailyMeds.length,
                  itemBuilder: (context, index) => _buildMedicineCard(dailyMeds[index], dayName),
                );
              },
            ),
          ),
          
          const Divider(height: 1),
          
          // ÖZEL İLAÇLARA GİT BUTONU
          Padding(
            padding: const EdgeInsets.all(15),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SpecialMedsPage()),
                ).then((_) => _refreshMedicines()); // Geri dönünce listeyi tazele
              },
              icon: const Icon(Icons.timer_outlined, color: Colors.white),
              label: const Text("ÖZEL ARALIKLI İLAÇLARIM"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade800,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineCard(Medicine med, String dayName) {
    Map<String, dynamic> slots = {};

    if (med.type == "Haftalık") {
      slots = Map<String, dynamic>.from(med.dayConfig['weeklyDetail'][dayName] ?? {});
    } else {
      slots = Map<String, dynamic>.from(med.dayConfig['slots'] ?? {});
    }

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12, left: 5, right: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.teal.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.medication, color: Colors.teal),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(med.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                      Text("${med.stock} Adet Kaldı", style: TextStyle(color: med.stock < 5 ? Colors.red : Colors.grey, fontSize: 12)),
                    ],
                  )
                ),
              ],
            ),
            const SizedBox(height: 15),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: slots.keys.map((slotKey) {
                // İÇİLDİ BİLGİSİNİ KONTROL ETMEK İÇİN KÜÇÜK BİR SORGUCUK (Hafif)
                return FutureBuilder<List<String>>(
                  future: DatabaseHelper().getTakenSlots(med.id!, DateFormat('yyyy-MM-dd').format(_selectedDay)),
                  builder: (context, snap) {
                    final isTaken = snap.data?.contains(slotKey) ?? false;
                    
                    return ActionChip(
                      avatar: isTaken ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                      label: Text(slotKey, style: const TextStyle(fontWeight: FontWeight.w600)),
                      backgroundColor: Colors.teal.withOpacity(0.08),
                      disabledColor: Colors.green, 
                      labelStyle: TextStyle(color: isTaken ? Colors.white : Colors.teal.shade800),
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
                      onPressed: isTaken ? null : () => _markAsTaken(med, slotKey),
                    );
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}