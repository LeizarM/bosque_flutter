import 'package:bosque_flutter/domain/entities/Ciudad_entity.dart';
import 'package:bosque_flutter/domain/entities/pais_entity.dart';
import 'package:bosque_flutter/domain/entities/resultado_escritura_entity.dart';
import 'package:bosque_flutter/domain/entities/zona_entity.dart';

/// Mantenimiento de países, ciudades y zonas (vista 26). Alta si el código
/// es 0, edición si es mayor.
abstract class UbicacionGeograficaRepository {
  Future<List<PaisEntity>> listarPaises();

  /// Todas las ciudades, con el nombre del país y lo que las usa.
  Future<List<CiudadEntity>> listarCiudades();

  /// Todas las zonas, con el nombre de la ciudad y cuántas personas la usan.
  Future<List<ZonaEntity>> listarZonas();

  Future<ResultadoEscrituraEntity> registrarPais(PaisEntity pais);
  Future<ResultadoEscrituraEntity> registrarCiudad(CiudadEntity ciudad);
  Future<ResultadoEscrituraEntity> registrarZona(ZonaEntity zona);

  Future<ResultadoEscrituraEntity> eliminarPais(int codPais);
  Future<ResultadoEscrituraEntity> eliminarCiudad(int codCiudad);
  Future<ResultadoEscrituraEntity> eliminarZona(int codZona);
}
