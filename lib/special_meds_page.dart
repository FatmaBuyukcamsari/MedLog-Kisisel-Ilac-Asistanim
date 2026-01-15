import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'medicine_model.dart';
import 'database_helper.dart';

class SpecialMedsPage extends StatefulWidget {
  const SpecialMedsPage({super.key});

  @override
  State<SpecialMedsPage> createState() => _SpecialMedsPageState();
}

class _SpecialMedsPageState extends State<SpecialMedsPage> {
  // Özel ilaçlarda genelde bugünün takibi yapılır
  final String _todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

  void _markAsTaken(Medicine med, String slot) async {
    bool success = await DatabaseHelper().markAsTaken(med, slot, _todayStr, 1);
    if (success) {
      setState(() {}); // Sayfayı yenile ve stok düşsün
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${med.name} - $slot alındı"), backgroundColor: Colors.green, duration: const Duration(seconds: 1)),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Stok yetersiz!"), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Özel Aralıklı İlaçlar"),
        backgroundColor: Colors.orange.shade800,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Medicine>>(
        future: DatabaseHelper().getMedicines(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          // Sadece "Özel" tipindeki ilaçları filtrele
          final specialMeds = snapshot.data!.where((m) => m.type == "Özel").toList();

          if (specialMeds.isEmpty) {
            return const Center(
              child: Text("Henüz özel aralıklı bir ilaç eklemediniz.", style: TextStyle(color: Colors.grey, fontSize: 16)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: specialMeds.length,
            itemBuilder: (context, index) {
              final med = specialMeds[index];
              return _buildSpecialMedCard(med);
            },
          );
        },
      ),
    );
  }

  Widget _buildSpecialMedCard(Medicine med) {
    // Saat aralıklarını hesapla (Örn: 8 saat -> 00:00, 08:00, 16:00)
    List<String> timeSlots = [];
    int interval = med.intervalHours ?? 8;
    if (interval < 1) interval = 1; // Hata önleyici
    
    int count = 24 ~/ interval; // Gün içinde kaç kere
    for (int i = 0; i < count; i++) {
      // 00:00 dan başlatıyoruz, istersen başlangıç saatine göre de ayarlanabilir
      String hour = (i * interval).toString().padLeft(2, '0');
      timeSlots.add("$hour:00");
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.orangeAccent,
                  child: Icon(Icons.access_time_filled, color: Colors.white),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(med.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text("${med.stock} Adet Kaldı • ${med.intervalHours} Saatte bir", 
                        style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 25),
            const Text("Bugünkü Dozlar:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
            const SizedBox(height: 10),
            
            // ÇİPLER (Butonlar)
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: timeSlots.map((slot) {
                return FutureBuilder<List<String>>(
                  future: DatabaseHelper().getTakenSlots(med.id!, _todayStr),
                  builder: (context, snap) {
                    final isTaken = snap.data?.contains(slot) ?? false;
                    return ActionChip(
                      avatar: isTaken ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                      label: Text(slot),
                      backgroundColor: Colors.orange.shade50,
                      disabledColor: Colors.green, // İÇİLDİ GÖRÜNÜMÜ
                      labelStyle: TextStyle(color: isTaken ? Colors.white : Colors.black87),
                      onPressed: isTaken ? null : () => _markAsTaken(med, slot),
                    );
                  },
                );
              }).toList(),
            )
          ],
        ),
      ),
    );
  }
}