import 'package:bosque_flutter/domain/entities/login_entity.dart';
import 'package:bosque_flutter/domain/entities/usuarioBtn_entity.dart';
abstract class AuthRepository {
  Future<(LoginEntity?, String)> login(String username, String password);

  Future<List<LoginEntity>> getUsers();

  Future<bool> changePassword( LoginEntity user );

  
  Future<List<UsuarioBtnEntity>> cargarPermisosBotones( int codUsuario );
  
  bool tienePermiso(String nombreBtn);
  
}