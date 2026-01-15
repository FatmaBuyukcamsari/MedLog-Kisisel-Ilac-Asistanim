import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'medicine_model.dart';

class ArchivePage extends StatefulWidget {
  const ArchivePage({super.key});
  @override
  State<ArchivePage> createState() => _ArchivePageState();
}

class _ArchivePageState extends State<ArchivePage> {
  // Sayfayı tazelemek için
  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar yerine senin sevdiğin özel yeşil başlık
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 15, bottom: 15),
            decoration: const BoxDecoration(
              color: Colors.teal,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20))
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Expanded(
                  child: Center(
                    child: Text("İLAÇ ARŞİVİ", 
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          
          Expanded(
            child: FutureBuilder<List<Medicine>>(
              // Arşivlenmiş ilaçları çekiyoruz
              future: DatabaseHelper().getMedicines(archived: true),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final archived = snapshot.data!;
                if (archived.isEmpty) return const Center(child: Text("Arşivde ilaç yok."));

                return ListView.builder(
                  itemCount: archived.length,
                  itemBuilder: (context, i) {
                    final m = archived[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: ListTile(
                        title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Kalan Stok: ${m.stock}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // --- GERİ YÜKLEME BUTONU ---
                            IconButton(
                              icon: const Icon(Icons.settings_backup_restore, color: Colors.teal),
                              onPressed: () => _showConfirm(
                                context, 
                                "Geri Yükle", 
                                "${m.name} ilacını yeniden kaydetmek istiyor musunuz?", 
                                () async {
                                  await DatabaseHelper().restore(m.id!);
                                  _refresh();
                                }
                              ),
                            ),
                            // --- TAMAMEN SİLME BUTONU ---
                            IconButton(
                              icon: const Icon(Icons.delete_forever, color: Colors.red),
                              onPressed: () => _showConfirm(
                                context, 
                                "Tamamen Sil", 
                                "${m.name} tamamen silinecek. Emin misiniz?", 
                                () async {
                                  await DatabaseHelper().deleteMedicinePermanently(m.id!);
                                  _refresh();
                                }
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Ortak Onay Kutusu (Dialog)
  void _showConfirm(BuildContext context, String title, String content, Function action) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Vazgeç")),
          TextButton(
            onPressed: () async {
              await action();
              Navigator.pop(context);
              _refresh(); // İşlem sonrası listeyi yeniler
            }, 
            child: const Text("Evet", style: TextStyle(fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );
  }
}