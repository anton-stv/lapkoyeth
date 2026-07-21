class UserModel {
  static const Object _unset = Object();

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
  final String? bio;

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
    this.bio,
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
    'bio': bio,
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
    bio: map['bio'] as String?,
  );

  UserModel copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? email,
    String? passwordHash,
    Object? city = _unset,
    Object? phone = _unset,
    Object? dateOfBirth = _unset,
    Object? gender = _unset,
    Object? photoPath = _unset,
    Object? bio = _unset,
  }) => UserModel(
    id: id ?? this.id,
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    email: email ?? this.email,
    passwordHash: passwordHash ?? this.passwordHash,
    city: city == _unset ? this.city : city as String?,
    phone: phone == _unset ? this.phone : phone as String?,
    dateOfBirth: dateOfBirth == _unset
        ? this.dateOfBirth
        : dateOfBirth as String?,
    gender: gender == _unset ? this.gender : gender as String?,
    photoPath: photoPath == _unset ? this.photoPath : photoPath as String?,
    bio: bio == _unset ? this.bio : bio as String?,
  );
}
