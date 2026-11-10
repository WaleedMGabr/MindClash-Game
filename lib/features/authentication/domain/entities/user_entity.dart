import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String email;
  final String userId;
  final String username;

  const UserEntity({
    required this.userId,
    required this.email,
    required this.username,
  });

  @override
  List<Object?> get props => [username, email, userId];
}