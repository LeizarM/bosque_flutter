import 'package:bosque_flutter/domain/entities/sesion_entity.dart';
import 'package:bosque_flutter/domain/repositories/sesiones_repository.dart';

/// Sesión de prueba con valores por defecto razonables.
SesionEntity sesionDePrueba({
  int id = 1,
  String login = 'jperez',
  String nombre = 'Pérez Gómez Juan Carlos',
  String plataforma = 'web',
  String estado = 'C',
  String? motivo,
  String? loginCierre,
  bool esActual = false,
  DateTime? inicio,
  DateTime? senal,
  DateTime? cierre,
}) {
  final ahora = DateTime.now();
  return SesionEntity(
    idSesion: BigInt.from(id),
    codUsuario: id,
    plataforma: plataforma,
    versionApp: '1.0.2',
    ip: '192.168.3.${id % 250}',
    fechaInicio: inicio ?? ahora.subtract(const Duration(hours: 2)),
    fechaVence: ahora.add(const Duration(hours: 8)),
    fechaUltimaSenal: senal ?? ahora.subtract(const Duration(minutes: 1)),
    fechaCierre: cierre,
    motivoCierre: motivo,
    codUsuarioCierre: null,
    audUsuario: id,
    audFecha: ahora,
    login: login,
    nombreCompleto: nombre,
    loginCierre: loginCierre,
    estado: estado,
    esActual: esActual,
  );
}

class RepoSesionesFalso implements SesionesRepository {
  List<SesionEntity> abiertasDevueltas = [
    sesionDePrueba(id: 1, login: 'mjaimes', nombre: 'Jaimes Marcelo', esActual: true),
    sesionDePrueba(id: 2, login: 'jperez', plataforma: 'android'),
    sesionDePrueba(
      id: 3,
      login: 'avila',
      nombre: 'Ávila Rocha María Fernanda de los Ángeles',
      plataforma: 'ios',
      estado: 'N',
      senal: DateTime.now().subtract(const Duration(minutes: 40)),
    ),
  ];
  List<SesionEntity> historialDevuelto = [
    sesionDePrueba(id: 10, login: 'jbalderrama', nombre: 'Balderrama Jorge', estado: 'X', motivo: 'A',
        loginCierre: 'mjaimes', cierre: DateTime.now().subtract(const Duration(minutes: 30))),
    sesionDePrueba(id: 11, login: 'jperez', estado: 'X', motivo: 'S',
        cierre: DateTime.now().subtract(const Duration(hours: 1))),
    sesionDePrueba(id: 12, login: 'avila', nombre: 'Ávila Rocha María', estado: 'N'),
  ];
  final List<BigInt> cerradas = [];
  final List<({DateTime desde, DateTime hasta})> rangos = [];
  int lecturasAbiertas = 0;
  String mensajeAlCerrar = 'Sesión cerrada. Esa persona vuelve al inicio de sesión en su próxima acción o en 2 minutos como máximo.';

  @override
  Future<List<SesionEntity>> abiertas() async {
    lecturasAbiertas++;
    return abiertasDevueltas;
  }

  @override
  Future<List<SesionEntity>> historial({required DateTime desde, required DateTime hasta}) async {
    rangos.add((desde: desde, hasta: hasta));
    return historialDevuelto;
  }

  @override
  Future<String> cerrar(BigInt idSesion) async {
    cerradas.add(idSesion);
    return mensajeAlCerrar;
  }
}
