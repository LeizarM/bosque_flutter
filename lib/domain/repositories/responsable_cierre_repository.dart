// Destino final: lib/domain/repositories/responsable_cierre_repository.dart
import 'package:bosque_flutter/domain/entities/responsable_cierre_entity.dart';

/// La matriz de Verificar Cierre (archivo SQL 81). Las reglas son del servidor:
/// si no acepta algo, lanza su mensaje tal cual.
abstract class ResponsableCierreRepository {
  Future<List<ResponsableCierre>> lista(int idTarRuti);

  Future<List<CandidatoCierre>> candidatos(int idTarRuti);

  Future<List<SucursalCaja>> sucursales();

  Future<void> agregar({
    required int idTarRuti,
    required String seccion,
    int? codSucursal,
    int? codCargoSucursal,
    int? codEmpleado,
    bool puedeAutorrevisar = false,
  });

  /// Cambia si puede revisar lo propio; el resto de la fila viaja igual.
  Future<void> cambiarAutorrevision(ResponsableCierre fila, bool puede);

  Future<void> quitar(int idRC);

  /// El catálogo de secciones (archivo SQL 86).
  Future<List<SeccionCierre>> secciones(int idTarRuti);

  /// Las consultas de otros módulos que se pueden usar como sección.
  Future<List<FuenteCierre>> fuentes();

  /// Alta ([codigo] null) o cambio de una sección.
  Future<void> guardarSeccion({
    String? codigo,
    required String nombre,
    String? queRevisar,
    bool? porSucursal,
    String? fuente,
    bool? marcaPorFila,
    bool? firmaSola,
    int? obsDesde,
    String? diaRevisado,
    int? orden,
  });

  /// [quitar]: desde hoy ya no se pide; si no, se vuelve a pedir.
  Future<void> quitarSeccion(String codigo, {required bool quitar});

  /// Todas las fuentes, también las inactivas (archivo SQL 87).
  Future<List<FuenteCierre>> fuentesTodas();

  /// Las consultas del cierre que existen en la base y no se registraron.
  Future<List<CandidatoFuente>> candidatasFuente();

  /// Registra [fuente] o cambia su nombre, descripción y SP de marca.
  Future<void> guardarFuente({
    required String fuente,
    required String nombre,
    String? descripcion,
    String? spMarcar,
  });

  Future<void> activarFuente(String fuente, {required bool activa});

  /// La borra del registro; la función queda en la base.
  Future<void> borrarFuente(String fuente);
}
