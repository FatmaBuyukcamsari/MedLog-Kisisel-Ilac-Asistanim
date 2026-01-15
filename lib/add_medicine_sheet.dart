import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'medicine_model.dart';
import 'database_helper.dart';
import 'notification_helper.dart'; // Bildirim dosyasının burada olduğundan emin ol

class AddMedicineSheet extends StatefulWidget {
  final VoidCallback onSaved;
  final Medicine? editMed;

  const AddMedicineSheet({super.key, required this.onSaved, this.editMed});

  @override
  State<AddMedicineSheet> createState() => _AddMedicineSheetState();
}

class _AddMedicineSheetState extends State<AddMedicineSheet> {
  String type = "Günlük";
  int intervalHours = 8;
  int intervalMinutes = 0;
  final nameC = TextEditingController();
  final stockC = TextEditingController();
  DateTime startD = DateTime.now();
  String activeDay = "Pzt";
  
  // Özel mod için yeni alanlar
  String specialStatus = "Tok";
  String specialDose = "1";

  Map<String, dynamic> dailySlots = {};
  Map<String, Map<String, dynamic>> weeklyDetail = {
    "Pzt": {}, "Sal": {}, "Çar": {}, "Per": {}, "Cum": {}, "Cmt": {}, "Paz": {},
  };

  @override
  void initState() {
    super.initState();
    if (widget.editMed != null) {
      nameC.text = widget.editMed!.name;
      stockC.text = widget.editMed!.stock.toString();
      type = widget.editMed!.type;
      startD = DateTime.parse(widget.editMed!.startDate);
      intervalHours = widget.editMed!.intervalHours ?? 8;
      intervalMinutes = widget.editMed!.intervalMinutes ?? 0;

      if (type == "Günlük") {
        dailySlots = Map<String, dynamic>.from(widget.editMed!.dayConfig['slots'] ?? {});
      } else if (type == "Haftalık") {
        final Map<String, dynamic> incoming = Map<String, dynamic>.from(widget.editMed!.dayConfig['weeklyDetail'] ?? {});
        incoming.forEach((key, value) {
          if (weeklyDetail.containsKey(key)) {
            weeklyDetail[key] = Map<String, dynamic>.from(value ?? {});
          }
        });
      } else if (type == "Özel") {
        specialStatus = widget.editMed!.dayConfig['specialStatus'] ?? "Tok";
        specialDose = widget.editMed!.dayConfig['specialDose'] ?? "1";
      }
    }
  }

  Map<String, dynamic> get currentMap {
    if (type == "Günlük") return dailySlots;
    if (type == "Haftalık") {
      if (weeklyDetail[activeDay] == null) weeklyDetail[activeDay] = {};
      return weeklyDetail[activeDay]!;
    }
    return {};
  }

  void toggleSlot(String s) {
    setState(() {
      if (currentMap.containsKey(s)) {
        currentMap.remove(s);
      } else {
        currentMap[s] = {"time": "09:00", "status": "Tok", "dose": "1"};
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20, right: 20, top: 20),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 15),
          Text(widget.editMed == null ? "Yeni İlaç Planla" : "İlacı Düzenle", 
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal)),
          const SizedBox(height: 20),

          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'Günlük', label: Text('Günlük'), icon: Icon(Icons.today)),
              ButtonSegment(value: 'Haftalık', label: Text('Haftalık'), icon: Icon(Icons.calendar_view_week)),
              ButtonSegment(value: 'Özel', label: Text('Özel'), icon: Icon(Icons.tune)),
            ],
            selected: {type},
            onSelectionChanged: (s) => setState(() => type = s.first),
          ),

          const SizedBox(height: 20),
          TextField(controller: nameC, decoration: const InputDecoration(labelText: "İlaç Adı", prefixIcon: Icon(Icons.medication), border: OutlineInputBorder())),
          const SizedBox(height: 10),
          TextField(controller: stockC, decoration: const InputDecoration(labelText: "Mevcut Stok", prefixIcon: Icon(Icons.inventory), border: OutlineInputBorder()), keyboardType: TextInputType.number),

          ListTile(
            title: Text("Başlangıç Tarihi: ${DateFormat('dd/MM/yyyy').format(startD)}"),
            leading: const Icon(Icons.calendar_month, color: Colors.teal),
            onTap: () async {
              final d = await showDatePicker(context: context, initialDate: startD, firstDate: DateTime.now(), lastDate: DateTime(2030));
              if (d != null) setState(() => startD = d);
            },
          ),
          const Divider(),

          // --- HAFTALIK MODDA GÜN SEÇİCİ ---
          if (type == "Haftalık") ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ["Pzt", "Sal", "Çar", "Per", "Cum", "Cmt", "Paz"].map((day) {
                  bool hasData = weeklyDetail[day]?.isNotEmpty ?? false;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(day),
                      selected: activeDay == day,
                      avatar: hasData ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
                      selectedColor: Colors.teal,
                      labelStyle: TextStyle(color: activeDay == day ? Colors.white : Colors.black),
                      onSelected: (v) => setState(() => activeDay = day),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 10),
            Center(child: Text("$activeDay günü için vakitleri seçin", style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey))),
          ],

          // --- ORTAK VAKİT LİSTESİ ---
          if (type != "Özel") ...[
            ...["Sabah", "Öğle", "Akşam", "Gece"].map((s) => Column(children: [
              CheckboxListTile(
                title: Text(s),
                value: currentMap.containsKey(s),
                onChanged: (_) => toggleSlot(s),
                secondary: Icon(
                  s == "Sabah" ? Icons.wb_sunny_outlined : s == "Öğle" ? Icons.sunny : s == "Akşam" ? Icons.wb_twilight : Icons.bedtime_outlined,
                  color: Colors.orangeAccent
                ),
              ),
              if (currentMap.containsKey(s)) 
                _buildDetailRow(currentMap[s], (fn) => setState(fn)),
            ])),
          ],

          // --- ÖZEL MOD PANELİ ---
          if (type == "Özel") ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text("Hangi aralıkla alınacak?", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: TextEditingController(text: intervalHours.toString()),
                    decoration: const InputDecoration(labelText: "Saat", border: OutlineInputBorder(), isDense: true),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => intervalHours = int.tryParse(v) ?? 0,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: TextEditingController(text: intervalMinutes.toString()),
                    decoration: const InputDecoration(labelText: "Dakika", border: OutlineInputBorder(), isDense: true),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => intervalMinutes = int.tryParse(v) ?? 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            TextField(
              controller: TextEditingController(text: specialDose),
              decoration: const InputDecoration(
                labelText: "Doz (Örn: 1 adet)", 
                border: OutlineInputBorder(), 
                prefixIcon: Icon(Icons.medication_liquid),
                isDense: true
              ),
              onChanged: (v) => specialDose = v,
            ),
          ], 

          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: FilledButton.icon(
              icon: const Icon(Icons.save),
              label: const Text("KAYDET"),
              onPressed: _validateAndSave,
            ),
          ),
          const SizedBox(height: 30),
        ]),
      ),
    );
  }

  Widget _buildDetailRow(Map<String, dynamic> data, Function(VoidCallback) updateState) {
    return Padding(
      padding: const EdgeInsets.only(left: 45, bottom: 15, right: 10),
      child: Row(children: [
        ActionChip(
          avatar: const Icon(Icons.access_time, size: 16),
          label: Text(data['time']),
          onPressed: () async {
            final t = await showTimePicker(context: context, initialTime: TimeOfDay.now(),
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                child: child!,
             
              );
            },
            );
            if (t != null) {
  updateState(() {
    // Saati her zaman HH:mm formatında (Örn: 14:05) kaydediyoruz
    final String hour = t.hour.toString().padLeft(2, '0');
    final String minute = t.minute.toString().padLeft(2, '0');
    data['time'] = "$hour:$minute";
  });
}
          },
        ),
        const SizedBox(width: 8),
        DropdownButton<String>(
          value: data['status'],
          items: ["Aç", "Tok", "Farketmez"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => updateState(() => data['status'] = v!),
        ),
        const SizedBox(width: 8),
        Expanded(child: TextFormField(
          initialValue: data['dose']??"",
          decoration: const InputDecoration(hintText: "Doz", isDense: true),
          keyboardType: TextInputType.text,
          onChanged: (v) => data['dose'] = v,
        )),
      ]),
    );
  }

  // --- KRİTİK DEĞİŞİKLİK YAPILAN FONKSİYON BURADA ---
  void _validateAndSave() async {
    if (nameC.text.isEmpty) return _showError("İlaç adı boş olamaz!");
    if (stockC.text.isEmpty) return _showError("Stok giriniz!");

    final m = Medicine(
      id: widget.editMed?.id,
      name: nameC.text,
      stock: int.parse(stockC.text),
      type: type,
      startDate: DateFormat('yyyy-MM-dd').format(startD),
      endDate: null,
      intervalHours: type == "Özel" ? intervalHours : null,
      intervalMinutes: type == "Özel" ? intervalMinutes : null,
      dayConfig: {
        'slots': dailySlots,
        'weeklyDetail': weeklyDetail,
        'selectedDays': weeklyDetail.keys.where((k) => (weeklyDetail[k] as Map?)?.isNotEmpty ?? false).toList(),
        'specialStatus': type == "Özel" ? specialStatus : null,
        'specialDose': type == "Özel" ? specialDose : null,
      },
    );

    if (widget.editMed == null) {
      // 1. Yeni kayıt ekle ve ID'sini al
      int newId = await DatabaseHelper().insertMedicine(m);
      // 2. Bu ID'yi nesneye ata (Bildirim için gerekli)
      m.id = newId; 
    } else {
      // Güncelleme yap
      await DatabaseHelper().updateMedicine(m);
    }

    // 3. Bildirimleri kur! (Artık ID kesinlikle var)
    await NotificationHelper().scheduleMedicineNotifications(m);

    widget.onSaved();
    if (mounted) Navigator.pop(context);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.redAccent));
  }
}