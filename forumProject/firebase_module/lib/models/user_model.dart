import 'package:firebase_auth/firebase_auth.dart';

/// Immutable value object representing an authenticated user.
class UserModel {
  final String uid;
  final String email;
  final String displayName;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
  });

  /// Converts a Firebase [User] into a [UserModel].
  factory UserModel.fromFirebaseUser(User user) => UserModel(
        uid: user.uid,
        email: user.email ?? '',
        displayName:
            user.displayName ?? user.email?.split('@').first ?? 'Anonymous',
      );

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'email': email,
        'displayName': displayName,
      };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        uid: json['uid'] as String,
        email: json['email'] as String,
        displayName: json['displayName'] as String,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          uid == other.uid;

  @override
  int get hashCode => uid.hashCode;

  @override
  String toString() => 'UserModel(uid: $uid, email: $email)';
}
