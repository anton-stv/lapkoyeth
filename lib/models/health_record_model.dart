enum HealthRecordType { anamnesis, visit, vaccination, medication }

class HealthRecordModel {
  final int? id;
  final int petId;
  final HealthRecordType type;
  final String title;
  final String date;
  final String? description;
  final String? doctor;
  final String? nextDate;
  final String? dose; // для препаратов

  const HealthRecordModel({
    this.id,
    required this.petId,
    required this.type,
    required this.title,
    required this.date,
    this.description,
    this.doctor,
    this.nextDate,
    this.dose,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'pet_id': petId,
        'type': type.name,
        'title': title,
        'date': date,
        'description': description,
        'doctor': doctor,
        'next_date': nextDate,
        'dose': dose,
      };

  factory HealthRecordModel.fromMap(Map<String, dynamic> map) => HealthRecordModel(
        id: map['id'] as int?,
        petId: map['pet_id'] as int,
        type: HealthRecordType.values.firstWhere(
          (e) => e.name == map['type'],
          orElse: () => HealthRecordType.visit,
        ),
        title: map['title'] as String,
        date: map['date'] as String,
        description: map['description'] as String?,
        doctor: map['doctor'] as String?,
        nextDate: map['next_date'] as String?,
        dose: map['dose'] as String?,
      );
}
