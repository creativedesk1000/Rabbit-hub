import 'package:intl/intl.dart';

const rabbitStatuses = <String>[
  'Active',
  'Growing',
  'Breeding',
  'Pregnant',
  'Nursing',
  'Sick',
  'Under Treatment',
  'Retired',
  'Sold',
  'Deceased',
];

class Rabbit {
  const Rabbit({
    required this.id,
    required this.rabbitId,
    required this.name,
    required this.gender,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.breed,
    this.color,
    this.dateOfBirth,
    this.estimatedBirthDate,
    this.isEstimatedDob = false,
    this.weight,
    this.weightUnit = 'kg',
    this.earTag,
    this.fatherId,
    this.motherId,
    this.acquisitionDate,
    this.source,
    this.location,
    this.notes,
    this.mainPhotoPath,
  });

  final int id;
  final String rabbitId;
  final String name;
  final String gender;
  final String status;
  final String createdAt;
  final String updatedAt;
  final String? breed;
  final String? color;
  final DateTime? dateOfBirth;
  final DateTime? estimatedBirthDate;
  final bool isEstimatedDob;
  final double? weight;
  final String weightUnit;
  final String? earTag;
  final int? fatherId;
  final int? motherId;
  final DateTime? acquisitionDate;
  final String? source;
  final String? location;
  final String? notes;
  final String? mainPhotoPath;

  factory Rabbit.fromMap(Map<String, Object?> map) {
    DateTime? date(String key) {
      final value = map[key] as String?;
      return value == null ? null : DateTime.tryParse(value);
    }

    return Rabbit(
      id: map['id'] as int,
      rabbitId: map['rabbit_id'] as String,
      name: map['name'] as String,
      gender: map['gender'] as String,
      status: map['status'] as String,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
      breed: map['breed'] as String?,
      color: map['color'] as String?,
      dateOfBirth: date('date_of_birth'),
      estimatedBirthDate: date('estimated_birth_date'),
      isEstimatedDob: (map['is_estimated_dob'] as int? ?? 0) == 1,
      weight: (map['weight'] as num?)?.toDouble(),
      weightUnit: map['weight_unit'] as String? ?? 'kg',
      earTag: map['ear_tag'] as String?,
      fatherId: map['father_id'] as int?,
      motherId: map['mother_id'] as int?,
      acquisitionDate: date('acquisition_date'),
      source: map['source'] as String?,
      location: map['location'] as String?,
      notes: map['notes'] as String?,
      mainPhotoPath: map['main_photo_path'] as String?,
    );
  }

  String get ageLabel {
    final dob = dateOfBirth ?? estimatedBirthDate;
    if (dob == null) {
      return 'Age unknown';
    }
    final today = DateTime.now();
    var months = (today.year - dob.year) * 12 + today.month - dob.month;
    if (today.day < dob.day) months--;
    if (months < 1) {
      return isEstimatedDob ? 'Approx. under 1 month' : 'Under 1 month';
    }
    final years = months ~/ 12;
    final remainingMonths = months % 12;
    final age = years > 0
        ? '$years year${years == 1 ? '' : 's'}${remainingMonths > 0 ? ' $remainingMonths month${remainingMonths == 1 ? '' : 's'}' : ''}'
        : '$months month${months == 1 ? '' : 's'}';
    return isEstimatedDob ? 'Approx. $age' : age;
  }

  String get dateOfBirthLabel {
    final dob = dateOfBirth ?? estimatedBirthDate;
    if (dob == null) return 'Not recorded';
    final formatted = DateFormat.yMMMd().format(dob);
    return isEstimatedDob ? 'Estimated: $formatted' : formatted;
  }
}
