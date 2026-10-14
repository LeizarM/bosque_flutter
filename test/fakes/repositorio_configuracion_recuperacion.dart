import 'package:bosque_flutter/domain/entities/configuracion_recuperacion_entity.dart';
import 'package:bosque_flutter/domain/repositories/configuracion_recuperacion_repository.dart';

ConfiguracionRecuperacionEntity _p(
  String clave,
  String? valor,
  String nombre,
  String tipo,
  String grupo,
  int orden, {
  int? minimo,
  int? maximo,
  List<String> opciones = const [],
  bool configurado = true,
}) => ConfiguracionRecuperacionEntity(
  clave: clave,
  valor: valor,
  nombre: nombre,
  descripcion: 'Descripción de $nombre.',
  tipo: tipo,
  opciones: opciones,
  minimo: minimo,
  maximo: maximo,
  grupo: grupo,
  orden: orden,
  audUsuario: 28,
  audFecha: DateTime(2026, 10, 13),
  configurado: configurado,
);

/// Los parámetros del script 02, sin backend. Un `String` en los errores imita al repositorio real.
class RepoConfiguracionRecuperacionFalso implements ConfiguracionRecuperacionRepository {
  int lecturas = 0;
  final List<(String, String)> guardados = [];
  final List<String> pruebas = [];
  Object? errorAlGuardar;
  Object? errorAlProbar;

  List<ConfiguracionRecuperacionEntity> parametros = [
    _p('remitente', 'bosque@esppapel.com', 'Remitente', 'correo', 'Correo', 1),
    _p('smtpServidor', 'mail.esppapel.com', 'Servidor SMTP', 'texto', 'Correo', 2),
    _p('smtpPuerto', '587', 'Puerto', 'numero', 'Correo', 3, minimo: 1, maximo: 65535),
    _p('smtpSeguridad', 'STARTTLS', 'Seguridad', 'opcion', 'Correo', 4, opciones: const ['STARTTLS', 'SSL', 'NINGUNA']),
    _p('smtpUsuario', 'bosque@esppapel.com', 'Usuario SMTP', 'texto', 'Correo', 5),
    _p('smtpClave', null, 'Contraseña SMTP', 'secreto', 'Correo', 6),
    _p('dominios', 'esppapel.com,impexpap.com', 'Dominios corporativos', 'dominios', 'Correo', 7),
    _p('vigenciaMinutos', '15', 'Vigencia del código', 'numero', 'Límites', 1, minimo: 5, maximo: 60),
    _p('maxIntentos', '5', 'Intentos por código', 'numero', 'Límites', 2, minimo: 3, maximo: 10),
    _p('esperaSegundos', '60', 'Espera entre pedidos', 'numero', 'Límites', 3, minimo: 30, maximo: 600),
    _p('maxPorHora', '5', 'Códigos por hora', 'numero', 'Límites', 4, minimo: 1, maximo: 20),
  ];

  @override
  Future<List<ConfiguracionRecuperacionEntity>> listar() async {
    lecturas++;
    return parametros;
  }

  @override
  Future<String> guardar({required String clave, required String valor}) async {
    final error = errorAlGuardar;
    if (error != null) throw error;
    guardados.add((clave, valor));
    return 'Guardado. Rige desde el próximo pedido de código.';
  }

  @override
  Future<String> probar(String correo) async {
    final error = errorAlProbar;
    if (error != null) throw error;
    pruebas.add(correo);
    return 'Enviamos un correo de prueba a $correo. Revisa esa casilla.';
  }
}
