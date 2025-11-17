import 'package:bosque_flutter/domain/entities/empleado_entity.dart';
import 'package:bosque_flutter/domain/entities/login_entity.dart';
import 'package:bosque_flutter/domain/entities/usuarioBtn_entity.dart';
import 'package:bosque_flutter/domain/entities/vista_usuario_entity.dart';

abstract class AuthRepository {
  Future<bool> registrarLogin(LoginEntity user);

  Future<(LoginEntity?, String)> login(String username, String password);

  Future<List<LoginEntity>> getUsers();

  Future<bool> changePassword(LoginEntity user);

  Future<List<UsuarioBtnEntity>> cargarPermisosBotones(int codUsuario);

  bool tienePermiso(String nombreBtn);

  Future<bool> copiarPermisos(VistaUsuarioEntity vistaUsuario);

  Future<List<EmpleadoEntity>> listarEmpleados();

  Future<int> verificarDuplicadoUsuario(LoginEntity user);

  Future<List<VistaUsuarioEntity>> cargarPermisosVista(int codUsuario);

  Future<bool> actualizarPermisos(VistaUsuarioEntity vu);
}
