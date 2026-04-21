class WeightRecordModel {
  final int? id;
  final int petId;
  final double weight;
  final String date; // ISO 8601

  const WeightRecordModel({
    this.id,
    required this.petId,
    required this.weight,
    required this.date,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'pet_id': petId,
        'weight': weight,
        'date': date,
      };

  factory WeightRecordModel.fromMap(Map<String, dynamic> map) => WeightRecordModel(
        id: map['id'] as int?,
        petId: map['pet_id'] as int,
        weight: (map['weight'] as num).toDouble(),
        date: map['date'] as String,
      );
}
