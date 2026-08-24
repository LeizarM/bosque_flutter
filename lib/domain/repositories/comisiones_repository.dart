import 'package:bosque_flutter/domain/entities/comision_dinamica_entity.dart';
import 'package:bosque_flutter/domain/entities/comision_por_rango_entity.dart';
import 'package:bosque_flutter/domain/entities/grupo_comision_entity.dart';
import 'package:bosque_flutter/domain/entities/grupo_x_vendedor_entity.dart';
import 'dart:typed_data';

import 'package:bosque_flutter/domain/entities/estado_periodo_entity.dart';
import 'package:bosque_flutter/domain/entities/nota_pendiente_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_cambio_comision_entity.dart';
import 'package:bosque_flutter/domain/entities/nota_preliminar_entity.dart';
import 'package:bosque_flutter/domain/entities/pagado_item_entity.dart';
import 'package:bosque_flutter/domain/entities/politica_bond_entity.dart';
import 'package:bosque_flutter/domain/entities/preliminar_comision_entity.dart';
import 'package:bosque_flutter/domain/entities/vendedor_comision_entity.dart';

/// Contrato del modulo de Comisiones (tcom).
///
/// Todas las escrituras devuelven el id generado o actualizado. Los listados
/// devuelven lista vacia cuando el backend responde 204, que es exito sin datos.
abstract class ComisionesRepository {
  // ---------- Grupos ----------

  /// Alta si idGrupo es cero, modificacion si es mayor.
  Future<BigInt> registrarGrupo(GrupoComisionEntity grupo);

  /// Baja logica. El backend rechaza la baja si el grupo tiene vendedores vigentes.
  Future<BigInt> eliminarGrupo(GrupoComisionEntity grupo);

  /// Grupos activos. idGrupo cero devuelve todos.
  Future<List<GrupoComisionEntity>> obtenerGrupos({BigInt? idGrupo});

  /// Grupos que el vendedor todavia no tiene asignados y vigentes.
  Future<List<GrupoComisionEntity>> obtenerGruposAsignables(BigInt idVendedor);

  /// Incluye los dados de baja.
  Future<List<GrupoComisionEntity>> obtenerGruposTodos();

  // ---------- Vendedores ----------

  Future<BigInt> registrarVendedor(VendedorComisionEntity vendedor);

  Future<BigInt> eliminarVendedor(VendedorComisionEntity vendedor);

  /// Vendedores activos con sus codigos por empresa. idVendedor cero devuelve todos.
  Future<List<VendedorComisionEntity>> obtenerVendedores({BigInt? idVendedor});

  /// Vendedores de una empresa SAP. codEmpresa cero devuelve todas.
  Future<List<VendedorComisionEntity>> obtenerVendedoresPorEmpresa(
    int codEmpresa,
  );

  Future<List<VendedorComisionEntity>> obtenerVendedoresTodos();

  // ---------- Asignacion grupo / vendedor ----------

  Future<BigInt> registrarGrupoVendedor(GrupoXVendedorEntity asignacion);

  /// Cierra la vigencia. No borra, porque la historia de comisiones la referencia.
  Future<BigInt> eliminarGrupoVendedor(GrupoXVendedorEntity asignacion);

  Future<List<GrupoXVendedorEntity>> obtenerGruposPorVendedor(
    BigInt idVendedor,
  );

  Future<List<GrupoXVendedorEntity>> obtenerAsignacionesVigentes();

  // ---------- Comision dinamica ----------

  Future<BigInt> registrarComisionDinamica(ComisionDinamicaEntity escala);

  Future<BigInt> eliminarComisionDinamica(ComisionDinamicaEntity escala);

  /// esInterno nulo devuelve internas y externas.
  Future<List<ComisionDinamicaEntity>> obtenerComisionesDinamicas({
    int? esInterno,
  });

  /// Escalas vigentes a la fecha indicada. Sin fecha se usa la de hoy.
  Future<List<ComisionDinamicaEntity>> obtenerComisionesDinamicasVigentes({
    int? esInterno,
    DateTime? fecha,
  });

  // ---------- Vistas preliminares ----------
  //
  // Devuelven exactamente lo mismo que Bosque v2: por debajo llaman al SP
  // p_list_paraPagar heredado, sin cambiar la matematica.

  /// Rama F. Vendedores internos.
  Future<List<PreliminarComisionEntity>> preliminarInterno({
    required int mes,
    required int anio,
    required double tc,
  });

  /// Rama I. Vendedores externos.
  Future<List<PreliminarComisionEntity>> preliminarExterno({
    required int mes,
    required int anio,
    required double tc,
  });

  /// Rama J. Comision dinamica, modalidad anterior.
  Future<List<PreliminarComisionEntity>> preliminarDinamicaAnterior({
    required int mes,
    required int anio,
    required double tc,
  });

  /// Rama K. Comision dinamica, modalidad vigente.
  Future<List<PreliminarComisionEntity>> preliminarDinamicaVigente({
    required int mes,
    required int anio,
    required double tc,
  });

  // ---------- Carga y ejecucion del periodo ----------

  /// Indica si el periodo ya fue ejecutado, y con cuantos registros.
  Future<EstadoPeriodoEntity?> obtenerEstadoPeriodo({
    required int mes,
    required int anio,
    required int esInterno,
  });

  /// Prepara las notas del periodo. No mueve dinero: se puede repetir.
  /// Devuelve la cantidad de notas cargadas.
  Future<BigInt> cargarNotas({
    required int mes,
    required int anio,
    required int esInterno,
    required int audUsuario,
  });

  /// Realiza el corte y marca las notas como pagadas.
  /// NO ES REVERSIBLE. Devuelve la cantidad de registros de pago generados.
  Future<BigInt> ejecutarPago({
    required int mes,
    required int anio,
    required int esInterno,
    required int audUsuario,
  });

  // ---------- Comision por rango de dias ----------

  /// Tramos vigentes, ordenados por tipo y dia inicial.
  Future<List<ComisionPorRangoEntity>> obtenerRangosComision();

  /// Alta o modificacion. Requiere ROLE_ADM.
  Future<BigInt> registrarRangoComision(ComisionPorRangoEntity rango);

  /// Elimina un tramo. Requiere ROLE_ADM.
  Future<BigInt> eliminarRangoComision(ComisionPorRangoEntity rango);

  /// Las notas que componen UNA fila del preliminar.
  ///
  /// [comision] es el factor en base 1 de esa fila, y [modalidad] la pestana
  /// desde la que se pide: el backend la usa para saber con que boton del ACL
  /// autoriza, porque en el legacy el boton vivia dentro de cada pestana.
  Future<List<NotaPreliminarEntity>> notasDeFila({
    required int idVendedor,
    required int mes,
    required int anio,
    required double comision,
    required String modalidad,
  });

  // ---------- Ítems congelados al ejecutar el pago ----------

  /// El detalle por ítem de un período ya pagado: `p_list_tcom_PagadoItem`.
  ///
  /// El preliminar no sirve para esto, y no es un detalle: lista notas
  /// cerradas y SIN pagar, y al ejecutar el período esas notas pasan a
  /// `tcom_pagado`. Esto lee el otro lado, el que hasta ahora solo existía
  /// como un varchar armado con FOR XML PATH en `tcom_pagado.detalleItems`.
  ///
  /// El SP exige [mes], [anio] y [esInterno]; [idPagado], [docNum] y [origen]
  /// son filtros opcionales y en null devuelven el período entero.
  ///
  /// [docNum] y [origen] van SIEMPRE juntos: `docNum` no es único entre
  /// empresas —198 casos medidos en un mismo período—, así que el número solo
  /// no identifica una nota. Y `origen` es lo único que separa ESPPAPEL de
  /// IMPEXPAP/PAPIRUS/PRODUCTIVA PAPEL, que se congelan las cuatro con
  /// `esInterno = 1`.
  ///
  /// No hay parámetro para «solo lo excluido», y no es un olvido: el SP lo
  /// acepta, pero es un `where` sobre un campo que ya viene en cada fila
  /// (`aplicaDescuento`). Pedirlo al backend obliga a bajar dos veces el mismo
  /// mes para tildar y destildar un chip.
  Future<List<PagadoItemEntity>> obtenerItemsPagados({
    required int mes,
    required int anio,
    required int esInterno,
    int? idPagado,
    int? docNum,
    String? origen,
  });

  /// Rama 'R' del mismo SP: cuántos ítems y cuánto monto cayó en cada motivo.
  ///
  /// Va aparte y no contado sobre el listado porque el SP suma sobre la
  /// tabla, que es la fuente, y no sobre lo que una pantalla haya decidido
  /// mostrar.
  ///
  /// Acepta los MISMOS [docNum] y [origen] que el listado: es lo que hace que
  /// el titular («2 de 3 ítems no descontaron») hable de la misma nota que las
  /// líneas de abajo.
  Future<List<PagadoItemResumenEntity>> obtenerResumenItemsPagados({
    required int mes,
    required int anio,
    required int esInterno,
    int? idPagado,
    int? docNum,
    String? origen,
  });

  /// El corte del período: `p_list_tcom_PagadoItemCorte`.
  ///
  /// Se pide SIEMPRE junto con el listado, no solo cuando viene vacío: es lo
  /// único que separa «el congelado corrió y no había nada que congelar» de
  /// «el congelado no corrió». Sin él, un cero no se puede mostrar.
  ///
  /// Devuelve lista y no un objeto porque los tres filtros son opcionales en
  /// el SP: en null lista el histórico entero, una fila por período.
  Future<List<PagadoItemCorteEntity>> obtenerCorteItemsPagados({
    int? mes,
    int? anio,
    int? esInterno,
  });

  // ---------- Política del descuento por familia ----------

  /// Detalle de lo descontado, ítem por ítem.
  ///
  /// [accion]: P período abierto, H histórico ya pagado, R resumen.
  Future<List<DescuentoDetalleEntity>> obtenerDescuentoDetalle({
    required String accion,
    int? mes,
    int? anio,
    String? origen,
    int? idVendedor,
  });

  /// Familias de SAP. [soloDisponibles] deja fuera las que ya tienen política
  /// activa, que es lo que corresponde ofrecer al agregar una regla nueva.
  Future<List<FamiliaSapOpcionEntity>> obtenerFamiliasSap({
    bool soloDisponibles = false,
  });

  /// Todas las políticas, con su historial de vigencias.
  Future<List<FamiliaPoliticaEntity>> obtenerPoliticaFamilias();

  /// Solo lo que rige hoy: lo que se está aplicando en este momento.
  Future<List<FamiliaPoliticaEntity>> obtenerPoliticaFamiliasVigentes();

  Future<BigInt> guardarPoliticaFamilia(
    FamiliaPoliticaEntity mb,
    int codUsuario,
  );

  /// Baja lógica: el preliminar de un período viejo tiene que seguir siendo
  /// reconstruible con la política que regía entonces.
  Future<BigInt> eliminarPoliticaFamilia(
    FamiliaPoliticaEntity mb,
    int codUsuario,
  );

  Future<List<VendedorExentoEntity>> obtenerVendedoresExentos();
  Future<BigInt> guardarVendedorExento(VendedorExentoEntity mb, int codUsuario);
  Future<BigInt> eliminarVendedorExento(
    VendedorExentoEntity mb,
    int codUsuario,
  );

  Future<List<ClienteExcluidoEntity>> obtenerClientesExcluidos();
  Future<BigInt> guardarClienteExcluido(
    ClienteExcluidoEntity mb,
    int codUsuario,
  );
  Future<BigInt> eliminarClienteExcluido(
    ClienteExcluidoEntity mb,
    int codUsuario,
  );

  // ---------- Notas pendientes ----------

  /// Notas cerradas sin pagar, con sus totales por vendedor.
  Future<List<NotaPendienteEntity>> obtenerNotasPendientes();

  /// Tipo de cambio vigente a la fecha indicada; por defecto, el de hoy.
  Future<TipoCambioComisionEntity> obtenerTipoCambio({DateTime? fecha});

  // ---------- Reportes ----------

  /// Comisiones pagadas de vendedores internos.
  Future<Uint8List> reportePagadasInternas({
    required int mes,
    required int anio,
  });

  /// Comisiones pagadas de vendedores externos.
  Future<Uint8List> reportePagadasExternas({
    required int mes,
    required int anio,
  });

  /// Comisiones pagadas por importacion.
  Future<Uint8List> reporteImportaciones({required int mes, required int anio});

  /// Comisiones pagadas de Esppapel.
  Future<Uint8List> reportePagadasEpp({required int mes, required int anio});

  /// Notas pendientes. El SP filtra internamente, no lleva parametros.
  Future<Uint8List> reporteNotasPendientes();

  /// Comisiones pagadas por vendedor en un rango de fechas.
  Future<Uint8List> reportePorVendedor({
    required DateTime desde,
    required DateTime hasta,
  });

  /// Trae las notas de SAP si los datos ya estan viejos.
  ///
  /// Devuelve true solo si realmente cargo: si los datos estaban frescos o ya
  /// habia otra carga en curso devuelve false, y eso no es un error.
  Future<bool> sincronizarNotas();

}
