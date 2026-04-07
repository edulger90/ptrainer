/// Represents a user account. The `password` field contains the **hashed**
/// password (SHA-256 + salt) stored in the database; raw passwords should never
/// be kept in memory longer than necessary.
class User {
  final int? id;
  final String username;
  final String email;
  final String password;
  final String? salt;
  final String? securityQuestion;
  final String? securityAnswer;

  User({
    this.id,
    required this.username,
    required this.email,
    required this.password,
    this.salt,
    this.securityQuestion,
    this.securityAnswer,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'password': password,
      'salt': salt,
      'securityQuestion': securityQuestion,
      'securityAnswer': securityAnswer,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      username: map['username'] as String,
      email: map['email'] as String,
      password: map['password'] as String,
      salt: map['salt'] as String?,
      securityQuestion: map['securityQuestion'] as String?,
      securityAnswer: map['securityAnswer'] as String?,
    );
  }
}
