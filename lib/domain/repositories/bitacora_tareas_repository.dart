// Destino final: lib/domain/repositories/bitacora_tareas_repository.dart
import 'dart:typed_data';

import 'package:bosque_flutter/domain/entities/bitacora_tareas_entity.dart';

/// Las bitácoras de tareas rutinarias (archivo SQL 55).
///
/// Ninguno de estos pedidos dice a quién puede ver quien pregunta: el servidor
/// lo resuelve desde el token (Sistemas y RR.HH., toda la empresa; los demás,
/// su equipo y ellos mismos).
abstract class BitacoraTareasRepository {
  /// Todas las ocurrencias del rango (hasta un año) que quien pregunta puede
  /// ver. Los demás filtros se aplican en la pantalla.
  Future<List<BitacoraCumplimientoEntity>> cumplimiento({
    required DateTime desde,
    required DateTime hasta,
  });

  /// La bitácora en PDF con exactamente estos filtros.
  Future<Uint8List> cumplimientoPdf(FiltroBitacora filtro);

  /// Los motivos por corrida del generador en el rango.
  Future<List<ResumenGeneracionEntity>> generacion({
    required DateTime desde,
    required DateTime hasta,
  });

  /// Por qué a una persona le llegó o no cada tarea de sus cargos en una
  /// fecha. Sin [codEmpleado], por quien pregunta. Si la persona no es de su
  /// equipo, lanza con el mensaje del servidor.
  Future<List<DiagnosticoGeneracionEntity>> porQue({
    int? codEmpleado,
    required DateTime fecha,
    int? idTarRuti,
  });

  Future<List<PersonaBuscada>> buscarPersonas(String texto);
}
