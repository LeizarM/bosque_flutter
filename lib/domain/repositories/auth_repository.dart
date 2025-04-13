import 'package:bosque_flutter/domain/entities/login_entity.dart';
abstract class AuthRepository {
  Future<(LoginEntity?, String)> login(String username, String password);
}