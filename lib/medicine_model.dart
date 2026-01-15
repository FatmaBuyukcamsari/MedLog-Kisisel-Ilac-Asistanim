import 'dart:convert';

class Medicine {
  int? id;
  String name;
  int stock;
  String type; // 'Günlük', 'Haftalık', 'Özel'
  String startDate;
  String? endDate; // Özel aralık için
  int? intervalHours;
  int? intervalMinutes; // Özel aralık (örn: 8 saatte bir)
  Map<String, dynamic> dayConfig; // Slotlar, günler, saatler, dozajlar burada
  int isDeleted;

  Medicine({
    this.id, required this.name, required this.stock, required this.type,
    required this.startDate, this.endDate, this.intervalHours, this.intervalMinutes,
    required this.dayConfig, this.isDeleted = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id, 'name': name, 'stock': stock, 'type': type,
      'startDate': startDate, 'endDate': endDate,
      'intervalHours': intervalHours,
      'intervalMinutes' : intervalMinutes,
      'dayConfig': jsonEncode(dayConfig),
      'isDeleted': isDeleted,
    };
  }

  factory Medicine.fromMap(Map<String, dynamic> map) {
    return Medicine(
      id: map['id'], name: map['name'], stock: map['stock'],
      type: map['type'], startDate: map['startDate'], endDate: map['endDate'],
      intervalHours: map['intervalHours'],
      intervalMinutes: map['intervalMinutes'],
      dayConfig: jsonDecode(map['dayConfig'] ?? '{}'),
      isDeleted: map['isDeleted'] ?? 0,
    );
  }
}