// Destino final: lib/domain/repositories/traspaso_efectivo_tesbase_repository.dart
import 'package:bosque_flutter/domain/entities/traspaso_efectivo_tesbase_entity.dart';

/// La verificación de la tarea 289 (idATR 11, TesBase). Solo la verificación:
/// el registro de transferencias sigue en el sistema anterior.
abstract class TraspasoEfectivoTesBaseRepository {
  /// Qué día revisa la ocurrencia: el hábil anterior a su fecha, con los
  /// feriados de la sucursal de quien la tiene. Lo decide el servidor
  /// (archivo SQL 58) porque "Sin pendientes" cuenta hasta ese mismo día.
  Future<DiaRevisadoTesBase> diaRevisado({required int idBitTarRuti});

  /// Las transferencias registradas en [fecha], en cualquier estado y con las
  /// pendientes primero.
  Future<List<TraspasoEfectivoTesBaseEntity>> delDia(DateTime fecha);

  /// Las transferencias en estado PEN, de cualquier fecha: una que quedó
  /// pendiente hace una semana sigue pendiente hoy.
  Future<List<TraspasoEfectivoTesBaseEntity>> pendientes();

  /// Cierra una (PEN a CER). El servidor rechaza si otra persona ya la cerró.
  Future<void> cerrar({required int codTes, required int idBitTarRuti});

  /// Da el día por revisado. El servidor vuelve a contar las pendientes
  /// registradas hasta el día revisado y rechaza si queda alguna, así que
  /// esto no sirve para saltearse el trabajo.
  Future<void> sinPendientes({required int idBitTarRuti});
}
