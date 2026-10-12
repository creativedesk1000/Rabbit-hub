class BreedingRecord {
  const BreedingRecord({
    required this.id,
    required this.doeId,
    required this.buckId,
    required this.matingDate,
    required this.status,
    this.kindledAt,
    this.kitCount,
    this.notes,
  });

  static const int gestationWindowStartDays = 28;
  static const int gestationWindowEndDays = 33;
  static const int typicalGestationDays = 31;

  final int id;
  final int doeId;
  final int buckId;
  final DateTime matingDate;
  final String status;
  final DateTime? kindledAt;
  final int? kitCount;
  final String? notes;

  DateTime get estimatedKindlingStart =>
      matingDate.add(const Duration(days: gestationWindowStartDays));

  DateTime get estimatedKindlingDate =>
      matingDate.add(const Duration(days: typicalGestationDays));

  DateTime get estimatedKindlingEnd =>
      matingDate.add(const Duration(days: gestationWindowEndDays));

  factory BreedingRecord.fromMap(Map<String, Object?> map) {
    return BreedingRecord(
      id: map['id'] as int,
      doeId: map['doe_id'] as int,
      buckId: map['buck_id'] as int,
      matingDate: DateTime.parse(map['mating_date'] as String),
      status: map['status'] as String,
      kindledAt: map['kindled_at'] == null
          ? null
          : DateTime.parse(map['kindled_at'] as String),
      kitCount: map['kit_count'] as int?,
      notes: map['notes'] as String?,
    );
  }
}
