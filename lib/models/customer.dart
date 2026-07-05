class Customer {
  const Customer({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.createdAt,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String phone;
  final DateTime createdAt;

  String get fullName => '$firstName $lastName';

  Customer copyWith({
    String? firstName,
    String? lastName,
    String? phone,
  }) {
    return Customer(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'first_name': firstName,
        'last_name': lastName,
        'phone': phone,
        'created_at': createdAt.toIso8601String(),
      };

  factory Customer.fromMap(Map<String, dynamic> map) => Customer(
        id: map['id'] as String,
        firstName: map['first_name'] as String,
        lastName: map['last_name'] as String,
        phone: map['phone'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}
