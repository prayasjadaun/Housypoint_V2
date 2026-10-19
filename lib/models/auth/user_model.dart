/// Logged-in user, as returned by `/api/auth/login/` and `/api/auth/profile/`.
class UserModel {
  const UserModel({
    required this.id,
    required this.phone,
    this.firstName = '',
    this.lastName = '',
    this.email = '',
    this.address = '',
    this.referralCode = '',
    this.dateJoined = '',
  });

  final String id;
  final String phone;
  final String firstName;
  final String lastName;
  final String email;
  final String address;
  final String referralCode;
  final String dateJoined;

  String get fullName => '$firstName $lastName'.trim();

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id']?.toString() ?? '',
    phone: json['phone']?.toString() ?? '',
    firstName: json['first_name']?.toString() ?? '',
    lastName: json['last_name']?.toString() ?? '',
    // The API uses `email_id`; some responses send `email`.
    email: (json['email_id'] ?? json['email'])?.toString() ?? '',
    address: json['address']?.toString() ?? '',
    referralCode: json['referral_code']?.toString() ?? '',
    dateJoined: json['date_joined']?.toString() ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'phone': phone,
    'first_name': firstName,
    'last_name': lastName,
    'email_id': email,
    'address': address,
    'referral_code': referralCode,
    'date_joined': dateJoined,
  };
}
