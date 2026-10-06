// Destino final: lib/domain/repositories/cierre_operaciones_repository.dart
import 'dart:typed_data';

import 'package:bosque_flutter/domain/entities/bitacora_tareas_entity.dart';
import 'package:bosque_flutter/domain/entities/cierre_operaciones_entity.dart';
import 'package:bosque_flutter/domain/entities/traspaso_mov_caja_entity.dart';

/// La revisión de Cierre de Operaciones: sus secciones, lo que se marca en
/// ellas y el cierre.
///
/// Todas las lecturas llevan la fecha, y es obligatoria a propósito: el
/// 2026-09-11 Marcelo vio el mismo día con 818 traspasos y sin ninguno, porque
/// una pantalla pedía sin fecha y el servidor devolvía la tabla entera.
///
/// Todas las escrituras llevan la ocurrencia: **la tarea es el permiso**. El
/// servidor comprueba que quien llama tenga esa ocurrencia de una tarea de
/// revisión; la sucursal también sale de ahí, nunca del cliente.
abstract class CierreOperacionesRepository {
  Future<List<ArqueoDelCierre>> arqueos(
    int idBitTarea, {
    required DateTime fecha,
    bool todasSucursales = false,
  });

  /// Lo que SAP devuelve para [fecha] cruzado con lo ya verificado en Bosque
  /// (el mismo listado que la tarea de Caja AXA). Falla si SAP no contesta.
  Future<List<TraspasoMovCajaEntity>> traspasos({required DateTime fecha});

  Future<List<LlegadaDelCierre>> cajaFuerte(
    int idBitTarea, {
    required DateTime fecha,
    bool todasSucursales = false,
  });

  /// Los cheques de [fecha] cruzados contra SAP. Falla si SAP no contesta.
  Future<List<ChequeDelCierre>> cheques(
    int idBitTarea, {
    required DateTime fecha,
  });

  /// Las tareas que generó el Job en [fecha] en la sucursal de la ocurrencia,
  /// sin las que este mismo cierre va a completar (archivo SQL 62).
  Future<List<BitacoraCumplimientoEntity>> tareas(
    int idBitTarea, {
    required DateTime fecha,
    bool todasSucursales = false,
  });

  /// Con [revisado] en false le quita la marca: a veces se da por error
  /// (Marcelo, 2026-10-05).
  Future<void> marcarArqueoRevisado(
    int idAC, {
    required int idBitTarea,
    bool revisado = true,
  });

  /// Con [verificada] en false le quita la marca.
  Future<void> marcarLlegadaVerificada(
    int idRp, {
    required int idBitTarea,
    bool verificada = true,
  });

  // Los traspasos no se marcan desde aquí: son de la tarea del cajero
  // ("Verificar traspaso Caja AXA", 295), que tiene su propia pantalla.

  /// Cierra la revisión. En [ModoCierre.cierre] cierra la ocurrencia; en
  /// [ModoCierre.verificacion], las de todos para ese día, y devuelve cuántas.
  Future<int> cerrar(
    int idBitTarea, {
    required ModoCierre modo,
    required DateTime fecha,
  });

  Future<Uint8List> pdfCierre(
    int idBitTarea, {
    required DateTime fecha,
    bool todasSucursales = false,
  });

  Future<Uint8List> pdfCajaFuerte(
    int idBitTarea, {
    required DateTime fecha,
    bool todasSucursales = false,
  });

  Future<Uint8List> pdfArqueo(int idAC);
}
