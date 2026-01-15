class MedicineLog {
  int? id;
  int medicineId; 
  String takenAt; // Tarih (2024-05-20 gibi)
  String slot;    // Sabah, Öğle, Akşam gibi

  MedicineLog({
    this.id,
    required this.medicineId,
    required this.takenAt,
    required this.slot,
  });

  factory MedicineLog.fromMap(Map<String, dynamic> map) {
    return MedicineLog(
      id: map['id'],
      medicineId: map['medicineId'],
      takenAt: map['takenAt'],
      slot: map['slot'] ?? "",
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medicineId': medicineId,
      'takenAt': takenAt,
      'slot': slot,
    };
  }
}