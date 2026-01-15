import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'medicine_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._();
  static Database? _db;

  DatabaseHelper._();
  factory DatabaseHelper() => _instance;

  Future<Database> get db async {
    if (_db != null) return _db!;
    
    // Windows ve Linux için gerekli başlatma
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    
    _db = await _init();
    return _db!;
  }

  Future<Database> _init() async {
  String path = join(await getDatabasesPath(), 'medlog_final.db'); // İsim değişti, yeni tablo oluşacak
  return await openDatabase(
    path,
    version: 1,
    onCreate: (db, version) async {
      // Hata veren tüm sütunlar buraya eklendi (image_885edd.jpg)
      await db.execute('''
        CREATE TABLE medicines (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          stock INTEGER,
          type TEXT,
          startDate TEXT,
          endDate TEXT,
          intervalHours INTEGER,
          intervalMinutes INTEGER,
          dayConfig TEXT,
          isDeleted INTEGER DEFAULT 0
        )
      ''');
      await db.execute('''
        CREATE TABLE logs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          medId INTEGER,
          slot TEXT,
          date TEXT
        )
      ''');
    },
  );
}

  // --- CRUD İŞLEMLERİ ---

  Future<int> insertMedicine(Medicine m) async {
    final database = await db;
    return await database.insert('medicines', m.toMap());
  }

  // Hata 4 Çözümü: updateMedicine metodu eklendi
  Future<int> updateMedicine(Medicine m) async {
    final database = await db;
    return await database.update(
      'medicines',
      m.toMap(),
      where: 'id = ?',
      whereArgs: [m.id],
    );
  }

  Future<List<Medicine>> getMedicines({bool archived = false}) async {
    final database = await db;
    final res = await database.query(
      'medicines',
      where: 'isDeleted = ?',
      whereArgs: [archived ? 1 : 0],
    );
    return res.map((m) => Medicine.fromMap(m)).toList();
  }

  // Hata 2 Çözümü: softDelete metodu eklendi
  Future<void> softDelete(int id) async {
    final database = await db;
    await database.update(
      'medicines',
      {'isDeleted': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Hata 6 Çözümü: restore metodu eklendi
  Future<void> restore(int id) async {
    final database = await db;
    await database.update(
      'medicines',
      {'isDeleted': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- TAKİP VE STOK İŞLEMLERİ ---

  Future<bool> markAsTaken(Medicine m, String slot, String date, int dose) async {
  final database = await db;
  
  // Stok kontrolü: Stok, dozdan azsa işlem yapma ve eksiye düşürme
  if (m.stock < dose) return false;

  // 1. Stok düşürme
  await database.update(
    'medicines',
    {'stock': m.stock - dose},
    where: 'id = ?',
    whereArgs: [m.id],
  );

  // 2. İçildi kaydı (log) ekleme
  await database.insert('logs', {
    'medId': m.id,
    'slot': slot,
    'date': date,
  });
  
  return true;
}
// --- BU YENİ FONKSİYONU EKLE ---
// Bu fonksiyon "2 tane" yazısını görünce içindeki "2"yi bulur ve stoktan düşer.
Future<void> consumeSmart(int medId, String doseText) async {
  final database = await db;

  // 1. Önce ilacın güncel stoğunu bulalım
  final List<Map<String, dynamic>> maps = await database.query(
    'medicines',
    where: 'id = ?',
    whereArgs: [medId],
  );

  if (maps.isEmpty) return;

  int currentStock = maps.first['stock'] as int;

  // 2. Yazının içindeki sayıyı (Dozu) bulalım
  // Örn: "2 tablet" -> 2
  // Örn: "1 ölçek" -> 1
  // Örn: "Yarım" veya sayı yoksa -> 1 kabul et
  int amountToDrop = 1; 
  try {
    final RegExp regExp = RegExp(r'\d+'); // Yazıdaki sayıları bulan formül
    final match = regExp.firstMatch(doseText);
    if (match != null) {
      amountToDrop = int.parse(match.group(0)!);
    }
  } catch (e) {
    print("Doz okuma hatası: $e");
  }

  // 3. Stoktan düş
  int newStock = currentStock - amountToDrop;
  if (newStock < 0) newStock = 0; // Eksiye düşmesin

  // 4. Veritabanını güncelle
  await database.update(
    'medicines',
    {'stock': newStock},
    where: 'id = ?',
    whereArgs: [medId],
  );
}
// Arşivden tamamen silme metodu (Hata 2 ve 6'ya ek olarak)
Future<void> deleteMedicinePermanently(int id) async {
  final database = await db;
  await database.delete('medicines', where: 'id = ?', whereArgs: [id]);
  await database.delete('logs', where: 'medId = ?', whereArgs: [id]); // İlgili kayıtları da siler
}
  // Hata 3 Çözümü: getTakenSlots metodu eklendi
  Future<List<String>> getTakenSlots(int medId, String date) async {
    final database = await db;
    final res = await database.query(
      'logs',
      where: 'medId = ? AND date = ?',
      whereArgs: [medId, date],
    );
    return res.map((e) => e['slot'] as String).toList();
  }
}