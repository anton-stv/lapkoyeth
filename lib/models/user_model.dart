class UserModel {
  final int? id;
  final String firstName;
  final String lastName;
  final String email;
  final String passwordHash;
  final String? city;
  final String? phone;
  final String? dateOfBirth;
  final String? gender;
  final String? photoPath;

  const UserModel({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.passwordHash,
    this.city,
    this.phone,
    this.dateOfBirth,
    this.gender,
    this.photoPath,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'password_hash': passwordHash,
        'city': city,
        'phone': phone,
        'date_of_birth': dateOfBirth,
        'gender': gender,
        'photo_path': photoPath,
      };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        id: map['id'] as int?,
        firstName: map['first_name'] as String,
        lastName: map['last_name'] as String,
        email: map['email'] as String,
        passwordHash: map['password_hash'] as String,
        city: map['city'] as String?,
        phone: map['phone'] as String?,
        dateOfBirth: map['date_of_birth'] as String?,
        gender: map['gender'] as String?,
        photoPath: map['photo_path'] as String?,
      );

  UserModel copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? email,
    String? passwordHash,
    String? city,
    String? phone,
    String? dateOfBirth,
    String? gender,
    String? photoPath,
  }) =>
      UserModel(
        id: id ?? this.id,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        email: email ?? this.email,
        passwordHash: passwordHash ?? this.passwordHash,
        city: city ?? this.city,
        phone: phone ?? this.phone,
        dateOfBirth: dateOfBirth ?? this.dateOfBirth,
        gender: gender ?? this.gender,
        photoPath: photoPath ?? this.photoPath,
      );
}
