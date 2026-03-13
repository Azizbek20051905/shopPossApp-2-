class User {
  final int id;
  final String username;
  final String role;
  final String? phone;
  final String? firstName;
  final String? lastName;

  User({
    required this.id,
    required this.username,
    required this.role,
    this.phone,
    this.firstName,
    this.lastName,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      role: json['role'] ?? 'cashier',
      phone: json['phone'],
      firstName: json['first_name'],
      lastName: json['last_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'role': role,
      'phone': phone,
      'first_name': firstName,
      'last_name': lastName,
    };
  }
}

class AuthResponse {
  final String token;
  final String username;
  final String role;

  AuthResponse({
    required this.token,
    required this.username,
    required this.role,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'],
      username: json['username'],
      role: json['role'],
    );
  }
}
