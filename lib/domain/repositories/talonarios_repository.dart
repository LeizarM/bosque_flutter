import 'dart:typed_data';

import 'package:bosque_flutter/data/models/talonario_lote_model.dart';
import 'package:bosque_flutter/domain/entities/talonario_detalle_entity.dart';
import 'package:bosque_flutter/domain/entities/talonario_entity.dart';
import 'package:bosque_flutter/domain/entities/talonario_grupo_entity.dart';
import 'package:bosque_flutter/domain/entities/talonario_por_grupo_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_recibo_entity.dart';

/// Módulo de Talonarios. Cinco tablas, cinco entidades.
///
/// El estado de un talonario no está guardado: el backend lo deriva contando
/// el log de eventos y lo devuelve resuelto en `estadoActual` y en los flags
/// `puedeEntregar` / `puedeDevolver` / `puedeCerrar`. La UI no recalcula nada.
abstract class TalonariosRepository {
  // ==================== TIPOS DE RECIBO ====================

  Future<List<TipoReciboEntity>> listarTipos();
  Future<TipoReciboEntity?> obtenerTipo(BigInt codTipoRecibo);

  /// Alta si codTipoRecibo == 0, edición si viene con id. Devuelve el id.
  Future<BigInt> registrarTipo(TipoReciboEntity tipo);

  /// Falla si el tipo tiene talonarios o está asignado a un grupo.
  Future<BigInt> eliminarTipo(BigInt codTipoRecibo, BigInt audUsuario);

  // ==================== GRUPOS ====================

  Future<List<TalonarioGrupoEntity>> listarGrupos();
  Future<TalonarioGrupoEntity?> obtenerGrupo(BigInt codGrupo);
  Future<BigInt> registrarGrupo(TalonarioGrupoEntity grupo);

  /// Falla si el grupo tiene tipos asignados.
  Future<BigInt> eliminarGrupo(BigInt codGrupo, BigInt audUsuario);

  // ==================== TIPOS POR GRUPO ====================

  /// Con codGrupo null devuelve todas las asignaciones.
  Future<List<TalonarioPorGrupoEntity>> listarTiposPorGrupo(BigInt? codGrupo);

  /// Los tipos que TODAVÍA NO están en el grupo, para el combo de agregar.
  Future<List<TalonarioPorGrupoEntity>> listarTiposDisponibles(BigInt codGrupo);

  Future<BigInt> asignarTipoAGrupo(TalonarioPorGrupoEntity asignacion);

  /// La tabla no admite edición: para mover un tipo de grupo, quitar + asignar.
  Future<BigInt> quitarTipoDeGrupo(TalonarioPorGrupoEntity asignacion);

  // ==================== TALONARIOS ====================

  /// Todos los filtros son opcionales.
  /// [codEstadoActual]: 1 Adquirido, 2 Entregado, 3 Devuelto, 4 Cerrado.
  /// [incluirCerrados] en false saca los cerrados: son estado terminal y hoy
  /// el 54% de las filas (1045 -> 480, y el payload de 334 KB a 153 KB).
  /// Pedir un [codEstadoActual] explícito manda por encima de ese interruptor.
  ///
  /// [desde]/[hasta] filtran por fecha de alta. Ojo con los defaults: los datos
  /// son históricos —nada entre 2024 y 2025— así que "últimos 12 meses" deja
  /// la pantalla en 10 filas.
  Future<List<TalonarioEntity>> listarTalonarios({
    BigInt? codTipoRecibo,
    BigInt? codEmpresa,
    BigInt? codGrupo,
    int? codEstadoActual,
    DateTime? desde,
    DateTime? hasta,
    bool? incluirCerrados,
  });

  /// Listos para entregar o reentregar: nunca cerrados y libres.
  Future<List<TalonarioEntity>> listarDisponibles({BigInt? codGrupo});

  Future<TalonarioEntity?> obtenerTalonario(BigInt codTalonario);
  Future<BigInt> registrarTalonario(TalonarioEntity talonario);

  /// Falla si el talonario ya tiene movimientos.
  Future<BigInt> eliminarTalonario(BigInt codTalonario, BigInt audUsuario);

  // ==================== ALTA MASIVA ====================

  /// Previsualiza el lote SIN escribir nada. Devuelve el mismo DTO con
  /// `talonarios` armado y `duplicados` con los nroTalonario que ya existen.
  Future<TalonarioLoteModel> simularLote(TalonarioLoteModel lote);

  /// Graba el lote. TODO O NADA: si falla uno no queda ninguno.
  /// Devuelve los ids generados.
  Future<List<BigInt>> aplicarLote(TalonarioLoteModel lote);

  // ==================== EVENTOS ====================

  /// Historial de un talonario, del evento más viejo al más nuevo.
  Future<List<TalonarioDetalleEntity>> listarEventos(BigInt codTalonario);

  /// [TalonarioDetalleEntity.codEstado]: 2 Entregado, 3 Devuelto, 4 Cerrado.
  /// El 1 (Adquirido) lo genera el alta del talonario.
  Future<BigInt> registrarEvento(TalonarioDetalleEntity evento);

  /// Solo se puede borrar el ÚLTIMO evento, y nunca el inicial.
  Future<BigInt> eliminarEvento(BigInt codDetalle, BigInt audUsuario);

  // ==================== ENTREGA MASIVA ====================

  /// Entrega varios talonarios al mismo destinatario. TODO O NADA.
  /// El destinatario es excluyente: sucursal O empleado, uno de los dos en cero.
  Future<List<BigInt>> entregarLote({
    required List<BigInt> codTalonarios,
    required DateTime fechaEvento,
    BigInt? codSucursal,
    BigInt? codEmpleado,
    String observacion,
    required BigInt audUsuario,
  });

  // ==================== REPORTES ====================
  //
  // Devuelven los bytes del PDF ya armado por Jasper en el backend. La pantalla
  // decide qué hacer con ellos —verlos, imprimirlos o compartirlos—; el
  // repositorio no toca la UI.

  /// Inventario: qué talonarios hay, de quién son y en qué estado están.
  ///
  /// Reemplaza a los dos reportes del wizard viejo (`RptTalMantFisico` y
  /// `RptTalMantEntregad`), que eran el mismo SP con la acción escrita a mano
  /// y sin ningún filtro.
  Future<Uint8List> reporteInventario({
    BigInt? codTipoRecibo,
    BigInt? codEmpresa,
    BigInt? codGrupo,
    int? codEstadoActual,
    DateTime? desde,
    DateTime? hasta,
    bool? incluirCerrados,
  });

  /// Trazabilidad: una fila por ENTREGA, con su devolución si volvió.
  ///
  /// `codSucursal` y `codEmpleado` son excluyentes entre sí: en la base, una
  /// entrega tiene destinatario sucursal o empleado, nunca los dos.
  Future<Uint8List> reporteTrazabilidad({
    BigInt? codTalonario,
    BigInt? codTipoRecibo,
    BigInt? codEmpresa,
    BigInt? codSucursal,
    BigInt? codEmpleado,
    DateTime? desde,
    DateTime? hasta,
  });

  /// Custodia: quién tiene talonarios ahora y quién registró la entrega.
  ///
  /// Es lo que Trazabilidad no contestaba: ese reporte devuelve las entregas
  /// históricas y no tiene con qué quedarse solo con las abiertas. Acá el
  /// default son las vigentes.
  ///
  /// [tipoDestinatario] es `'S'` sucursales, `'E'` personal, null ambos.
  /// [diasMinimos] deja solo lo que lleva N o más días en poder de alguien.
  Future<Uint8List> reporteCustodia({
    BigInt? codTipoRecibo,
    BigInt? codEmpresa,
    BigInt? codSucursal,
    BigInt? codEmpleado,
    String? tipoDestinatario,
    int? diasMinimos,
    DateTime? desde,
    DateTime? hasta,
    bool incluirCerrados = false,
  });

  /// Ficha de un talonario: su historial completo, para imprimir y adjuntar.
  Future<Uint8List> reporteFicha(BigInt codTalonario);

  /// Conciliación contra SAP.
  ///
  /// [origen] es `'cobros'` o `'salidas'` —son dos stored procedures distintos—
  /// y [accionSap] es `'A'` conciliados o `'D'` documentos sin talonario. `'B'`
  /// y `'C'` existen para no perder nada del wizard viejo.
  ///
  /// [codEmpresa], [codTipoRecibo] y el rango de fechas NO son parámetros del
  /// stored procedure de SAP: el backend los traduce a la lista de talonarios
  /// que sí acepta. Sin al menos uno el reporte recorre todo y no termina.
  Future<Uint8List> reporteConciliacionSap({
    required String origen,
    required String accionSap,
    BigInt? codEmpresa,
    BigInt? codTipoRecibo,
    DateTime? desde,
    DateTime? hasta,
    List<BigInt>? seleccion,
  });
}
