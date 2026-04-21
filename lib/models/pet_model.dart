class PetModel {
  final int? id;
  final int ownerId;
  final String name;
  final String? breed;
  final String? gender; // 'male' | 'female'
  final String? dateOfBirth;
  final double? weight;
  final double? height;
  final String? photoPath;
  // Идентификация
  final String? chipNumber;
  final String? tattooNumber;
  // Питание
  final String? foodType;
  final String? foodBrand;
  final String? feedingComment;
  final String? feedingSchedule; // JSON список времён
  // Режим дня
  final String? walkTimes;   // JSON
  final String? playTimes;   // JSON
  final String? trainNotes;
  // О питомце
  final String? about;

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
    this.chipNumber,
    this.tattooNumber,
    this.foodType,
    this.foodBrand,
    this.feedingComment,
    this.feedingSchedule,
    this.walkTimes,
    this.playTimes,
    this.trainNotes,
    this.about,
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
        'chip_number': chipNumber,
        'tattoo_number': tattooNumber,
        'food_type': foodType,
        'food_brand': foodBrand,
        'feeding_comment': feedingComment,
        'feeding_schedule': feedingSchedule,
        'walk_times': walkTimes,
        'play_times': playTimes,
        'train_notes': trainNotes,
        'about': about,
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
        chipNumber: map['chip_number'] as String?,
        tattooNumber: map['tattoo_number'] as String?,
        foodType: map['food_type'] as String?,
        foodBrand: map['food_brand'] as String?,
        feedingComment: map['feeding_comment'] as String?,
        feedingSchedule: map['feeding_schedule'] as String?,
        walkTimes: map['walk_times'] as String?,
        playTimes: map['play_times'] as String?,
        trainNotes: map['train_notes'] as String?,
        about: map['about'] as String?,
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
    String? chipNumber,
    String? tattooNumber,
    String? foodType,
    String? foodBrand,
    String? feedingComment,
    String? feedingSchedule,
    String? walkTimes,
    String? playTimes,
    String? trainNotes,
    String? about,
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
        chipNumber: chipNumber ?? this.chipNumber,
        tattooNumber: tattooNumber ?? this.tattooNumber,
        foodType: foodType ?? this.foodType,
        foodBrand: foodBrand ?? this.foodBrand,
        feedingComment: feedingComment ?? this.feedingComment,
        feedingSchedule: feedingSchedule ?? this.feedingSchedule,
        walkTimes: walkTimes ?? this.walkTimes,
        playTimes: playTimes ?? this.playTimes,
        trainNotes: trainNotes ?? this.trainNotes,
        about: about ?? this.about,
      );

  /// Возраст в читаемом виде
  String get ageString {
    if (dateOfBirth == null) return 'Возраст не указан';
    final dob = DateTime.tryParse(dateOfBirth!);
    if (dob == null) return 'Возраст не указан';
    final now = DateTime.now();
    final months = (now.year - dob.year) * 12 + now.month - dob.month;
    if (months < 12) return '$months мес.';
    final years = months ~/ 12;
    return '$years ${_yearLabel(years)}';
  }

  String _yearLabel(int y) {
    if (y % 10 == 1 && y % 100 != 11) return 'год';
    if (y % 10 >= 2 && y % 10 <= 4 && (y % 100 < 10 || y % 100 >= 20)) return 'года';
    return 'лет';
  }

  String get genderLabel => gender == 'male' ? 'Мальчик' : gender == 'female' ? 'Девочка' : '';
}
