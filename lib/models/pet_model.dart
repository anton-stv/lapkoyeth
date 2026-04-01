class PetModel {
  final int? id;
  final int ownerId;
  final String name;
  final String? breed;
  final String? gender;
  final String? dateOfBirth;
  final double? weight;
  final double? height;
  final String? photoPath;

  const PetModel({
    this.id,
    required this.ownerId,
    required this.name,
    this.breed,
    this.gender,
    this.dateOfBirth,
    this.weight,
    this.height,
    this.photoPath,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'owner_id': ownerId,
        'name': name,
        'breed': breed,
        'gender': gender,
        'date_of_birth': dateOfBirth,
        'weight': weight,
        'height': height,
        'photo_path': photoPath,
      };

  factory PetModel.fromMap(Map<String, dynamic> map) => PetModel(
        id: map['id'] as int?,
        ownerId: map['owner_id'] as int,
        name: map['name'] as String,
        breed: map['breed'] as String?,
        gender: map['gender'] as String?,
        dateOfBirth: map['date_of_birth'] as String?,
        weight: (map['weight'] as num?)?.toDouble(),
        height: (map['height'] as num?)?.toDouble(),
        photoPath: map['photo_path'] as String?,
      );

  PetModel copyWith({
    int? id,
    int? ownerId,
    String? name,
    String? breed,
    String? gender,
    String? dateOfBirth,
    double? weight,
    double? height,
    String? photoPath,
  }) =>
      PetModel(
        id: id ?? this.id,
        ownerId: ownerId ?? this.ownerId,
        name: name ?? this.name,
        breed: breed ?? this.breed,
        gender: gender ?? this.gender,
        dateOfBirth: dateOfBirth ?? this.dateOfBirth,
        weight: weight ?? this.weight,
        height: height ?? this.height,
        photoPath: photoPath ?? this.photoPath,
      );
}
