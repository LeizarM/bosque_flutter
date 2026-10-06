import 'dart:typed_data';

import 'package:bosque_flutter/domain/entities/accion_cheque_request_entity.dart';
import 'package:bosque_flutter/domain/entities/catalogos_cheque_entity.dart';
import 'package:bosque_flutter/domain/entities/cheque_detalle_entity.dart';
import 'package:bosque_flutter/domain/entities/cheque_fila_entity.dart';
import 'package:bosque_flutter/domain/entities/cheque_filtro_entity.dart';
import 'package:bosque_flutter/domain/entities/cheque_pagina_entity.dart';
import 'package:bosque_flutter/domain/entities/cheque_registro_entity.dart';
import 'package:bosque_flutter/domain/entities/cheque_resumen_entity.dart';
import 'package:bosque_flutter/domain/entities/custodia_cheque_request_entity.dart';
import 'package:bosque_flutter/domain/entities/dar_custodia_request_entity.dart';
import 'package:bosque_flutter/domain/entities/empresa_cheque_entity.dart';
import 'package:bosque_flutter/domain/entities/entrega_cheque_entity.dart';
import 'package:bosque_flutter/domain/entities/hora_traspaso_cheque_entity.dart';
import 'package:bosque_flutter/domain/entities/nota_remision_cheque_entity.dart';
import 'package:bosque_flutter/domain/entities/pdf_cheque_estado_entity.dart';
import 'package:bosque_flutter/domain/entities/pdf_cheque_subida_entity.dart';
import 'package:bosque_flutter/domain/entities/personal_cheque_entity.dart';
import 'package:bosque_flutter/domain/entities/postergacion_entity.dart';
import 'package:bosque_flutter/domain/entities/socio_negocio_entity.dart';
import 'package:bosque_flutter/domain/entities/sucursal_cheque_entity.dart';
import 'package:bosque_flutter/domain/entities/talonario_validacion_entity.dart';
import 'package:bosque_flutter/domain/entities/transaccion_bancaria_entity.dart';

/// Contrato del modulo de cheques (tch, vista 42). Espeja API_CHEQUES.md del
/// proyecto de migracion.
///
/// Reglas que valen para TODOS los metodos:
///
/// * Todo es POST, tambien las lecturas, y siempre con cuerpo JSON.
/// * Un 204 es exito sin datos: los listados devuelven lista vacia, la grilla
///   una pagina vacia y las consultas de una fila, null. Nunca es un error.
/// * Un 400 llega como el mensaje del backend, listo para mostrar tal cual;
///   varios errores vienen separados por salto de linea.
/// * El usuario de auditoria NO viaja: el backend lo toma del token.
/// * Las escrituras y varias lecturas exigen el boton de la vista 42 que indica
///   cada metodo; sin el, el backend responde 403. La pantalla oculta la
///   accion, pero la puerta que cierra es la del servidor.
/// * Escribir en una sucursal exige ser administrador o figurar en
///   `p_list_Sucursal` rama D; si no: «No tiene permisos para modificar datos
///   de otras sucursales».
abstract class ChequesRepository {
  // ========================= APOYO Y CATALOGOS =============================

  /// Tipos, monedas, estados y los estados que permite cada boton del detalle.
  Future<CatalogosChequeEntity> obtenerCatalogos();

  /// Las empresas del combo «Empresa» de la pantalla, ordenadas por codEmpresa.
  /// La primera es con la que abre la pantalla. De la elegida salen sucursales,
  /// clientes y la empresa del cheque nuevo; nunca la de la sesion de login.
  Future<List<EmpresaChequeEntity>> listarEmpresas();

  /// La sucursal con la que el usuario abre la pantalla en [codEmpresa]; 0 si
  /// no tiene en esa empresa. Con [codEmpresa] 0 no manda empresa y el servidor
  /// toma la primera de [listarEmpresas]; la pantalla siempre manda la suya.
  Future<int> obtenerSucursalInicial({int codEmpresa = 0});

  /// Sucursales parametrizadas de [codEmpresa] y permitidas al usuario (el combo
  /// del legacy). La pantalla siempre manda la empresa elegida; con 0 el
  /// servidor toma la primera de [listarEmpresas].
  Future<List<SucursalChequeEntity>> listarSucursales({int codEmpresa = 0});

  /// Clientes de [codEmpresa], para el combo del formulario. La pantalla siempre
  /// manda la empresa elegida; con 0 el servidor toma la primera de
  /// [listarEmpresas]. Es la misma entidad que usa Depositos de cheques.
  Future<List<SocioNegocioEntity>> listarClientes({int codEmpresa = 0});

  /// «Entregado por»: jefe de cobranzas, cobradores y choferes activos de la
  /// sucursal.
  Future<List<PersonalChequeEntity>> listarQuienesEntregan(int codSucursal);

  /// Responsables de custodia: jefe de cobranzas y cobradores activos de la
  /// sucursal (sin choferes).
  Future<List<PersonalChequeEntity>> listarResponsablesDeCustodia(
    int codSucursal,
  );

  // ============================== CHEQUES ==================================

  /// Una pagina de la grilla. Solo hay cheques con accion REC, banco y cliente
  /// en `text_SocioNegocio`. Sin resultados devuelve una pagina vacia.
  Future<ChequePaginaEntity> listar(ChequeFiltroEntity filtro);

  /// «Completar» (btnDetalleCH): el cheque, su historial y las cuatro acciones
  /// habilitadas.
  Future<ChequeDetalleEntity?> obtenerDetalle(BigInt codCheque);

  /// Alta (codCheque 0) o edicion. El [ModoRegistroCheque] decide que se acepta
  /// y que boton se exige. Devuelve el codCheque.
  Future<BigInt> registrar(ChequeRegistroEntity registro);

  /// Comprueba un par talonario / recibo manual contra la numeracion de la
  /// empresa, para avisar al usuario mientras escribe. Solo consulta: no escribe
  /// ni necesita sucursal, y **no sustituye** la validacion de [registrar].
  ///
  /// Un par incorrecto NO es un error: responde `valido == false` con el motivo
  /// en `mensaje`. Un 204 o un `data` nulo se toma por valido sin detalle. Solo
  /// lanza si la empresa falta o no es una de [listarEmpresas] (400), si el
  /// usuario no puede registrar ni editar cheques (403) o por red. Los dos
  /// textos viajan recortados.
  Future<TalonarioValidacionEntity> validarTalonario({
    required int codEmpresa,
    required String nroTalonario,
    required String reciboManual,
  });

  // ====================== ACCIONES DEL DETALLE =============================

  /// Nueva fecha de cobro: cambia `fechaCobrar` y registra la accion VEN o ADE,
  /// en una transaccion. Botones btnEditar2CH, btnEditar3CH o btnDetalleCH; la
  /// rama K tiene que habilitarla. Devuelve el codAccion.
  Future<BigInt> cambiarFechaCobro(AccionChequeRequestEntity accion);

  /// Devolver (btnDetalleCH): accion DEV. Devuelve el codAccion.
  Future<BigInt> devolver(AccionChequeRequestEntity accion);

  /// Cerrar con o sin verificacion (btnDetalleCH): registra la accion de cierre
  /// y pasa el cheque a CER, en una transaccion. Exige Nro SAP. Devuelve el
  /// codAccion.
  Future<BigInt> cerrar(AccionChequeRequestEntity accion);

  /// Baja de una accion (btnEliminarSegCH). El legacy no mira si el cheque esta
  /// cerrado ni excluye REC, TRASP o CUS; el backend lo conserva. Borrar REC
  /// saca al cheque de la grilla.
  Future<BigInt> eliminarAccion(BigInt codAccion);

  // ======================== TRASPASO Y CUSTODIA ============================

  /// Cuantos cheques de la sucursal esperan el traspaso (btnTraspasoCH).
  Future<int> contarTraspasosPendientes(int codSucursal);

  /// Traspaso masivo de la sucursal (btnTraspasoCH). Devuelve cuantos; el
  /// backend responde 400 si no habia ninguno.
  Future<int> traspasar(int codSucursal);

  /// Cheques de hoy listos para entregar en custodia (btnCustodiaCH).
  Future<List<ChequeFilaEntity>> listarChequesParaCustodia(int codSucursal);

  /// «A Custodio» (btnCustodiaCH): entrega los cheques al responsable. Todo o
  /// nada. Devuelve cuantos.
  Future<int> entregarEnCustodia(CustodiaChequeRequestEntity pedido);

  /// «Dar Custodia», paso 1 (btnCustodia2CH): todos los cheques de la sucursal.
  Future<List<ChequeResumenEntity>> listarChequesParaDarCustodia(
    int codSucursal,
  );

  /// «Dar Custodia», paso 2 (btnCustodia2CH): las entregas a cobranza de un
  /// dia.
  Future<List<EntregaChequeEntity>> listarEntregasDelDia({
    required int codSucursal,
    required DateTime fecha,
  });

  /// «Dar Custodia» (btnCustodia2CH): copia una accion CUS a otro cheque.
  /// Devuelve el codAccion nuevo.
  Future<BigInt> darCustodia(DarCustodiaRequestEntity pedido);

  // ============================== REPORTES =================================
  //
  // Los reportes responden con el PDF (bytes). Un error de negocio o de permiso
  // llega como excepcion con el mensaje del backend. Todos piden la empresa
  // activa de la pantalla y la sucursal de la grilla, nunca las del login. Las
  // fechas viajan yyyy-MM-dd y lo que no se indica (null, vacio o 0) no viaja:
  // el servidor lo toma como «todos».

  /// «Reporte» (btnRpt1CH): cheques recibidos en caja, entre dos fechas.
  Future<Uint8List> reporteRecibidos({
    required int codEmpresa,
    required int codSucursal,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  });

  /// «Reporte Cheques» (btnRpt2CH): cheques de cobranza. [estado] es PEN o CER
  /// y [codCliente] un CardCode; sin ellos, todos.
  Future<Uint8List> reporteCobranzas({
    required int codEmpresa,
    required int codSucursal,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
    String? estado,
    String? codCliente,
  });

  /// «Reporte Custodio» (btnRpt3CH): cheques entregados en custodia. Sin
  /// [codEmpleado] (o con 0), los de todos los cobradores.
  Future<Uint8List> reporteCustodio({
    required int codEmpresa,
    required int codSucursal,
    DateTime? fecha,
    int? codEmpleado,
  });

  /// «Recibo del Ultimo Cheque» (btnRpt4CH): el recibo del ultimo cheque que
  /// registro ESTE usuario en la sucursal. Sin ninguno, el backend responde 400.
  Future<Uint8List> reporteUltimoRecibo({
    required int codEmpresa,
    required int codSucursal,
  });

  /// Nomina del ultimo traspaso de la sucursal (btnTraspasoCH).
  Future<Uint8List> reporteTraspaso({
    required int codEmpresa,
    required int codSucursal,
  });

  /// «Imp Traspso» (btnRpt5CH, administrador): reimprime el traspaso de la
  /// accion [codAccion], que sale de [listarHorasDeTraspaso].
  Future<Uint8List> reporteReimpresionTraspaso({
    required int codEmpresa,
    required int codSucursal,
    required int codAccion,
  });

  /// Los traspasos a cobranza de un dia, para elegir cual reimprimir
  /// (btnRpt5CH). Sin ninguno, lista vacia.
  Future<List<HoraTraspasoChequeEntity>> listarHorasDeTraspaso({
    required int codSucursal,
    required DateTime fecha,
  });

  // ======================== DOCUMENTO PDF DEL CHEQUE =======================
  //
  // Un PDF por cheque, sin boton de ACL (como el legacy: «Cargar» y «Descargar
  // Documento PDF» no tienen ninguna condicion). El servidor lo guarda como
  // `<codCheque>.pdf` en el disco del legacy y lo baja como `<codCheque>_.pdf`.

  /// Si el cheque tiene PDF y, si lo tiene, su tamano y la fecha en que se
  /// cargo. Sin archivo no es un error: `existe` es false (tambien ante un 204).
  Future<PdfChequeEstadoEntity> estadoPdf(BigInt codCheque);

  /// Carga el PDF del cheque (multipart); si ya tenia uno, lo reemplaza. Los
  /// [bytes] van en memoria (en la web no hay ruta en disco). Si el servidor
  /// rechaza el archivo responde 400 con el motivo. [alProgreso] recibe los bytes
  /// enviados y el total, para una barra.
  Future<PdfChequeSubidaEntity> subirPdf(
    BigInt codCheque,
    Uint8List bytes,
    String nombreArchivo, {
    void Function(int enviados, int total)? alProgreso,
  });

  /// El PDF del cheque en bytes. Sin archivo, el servidor responde un error
  /// («No se encontro el archivo PDF») que llega como excepcion con su mensaje.
  Future<Uint8List> descargarPdf(BigInt codCheque);

  // ============ PANELES DEL DETALLE: NOTAS, TRANSACCIONES, POSTERGACIONES ====
  //
  // Los tres paneles del detalle del cheque. Listar no pide boton (el servidor
  // solo exige poder ver la sucursal del cheque). Registrar pide `btnNuevoNRCH`
  // en las tres. Eliminar una nota pide `btnEliminarNRCH`; eliminar una
  // transaccion o una postergacion no pide boton, como en el legacy. El usuario
  // de auditoria no viaja: lo toma el servidor del token.

  /// Las notas de remision del cheque, en el orden del servidor. Sin ninguna,
  /// lista vacia.
  Future<List<NotaRemisionChequeEntity>> listarNotasRemision(BigInt codCheque);

  /// Registra una nota de remision (`btnNuevoNRCH`). El servidor no rechaza una
  /// nota repetida, como el legacy.
  Future<void> registrarNotaRemision(NotaRemisionChequeEntity nota);

  /// Elimina la nota (`btnEliminarNRCH`). Devuelve **cuantas filas** elimino: si
  /// la nota estaba repetida en el cheque, todas.
  Future<int> eliminarNotaRemision({
    required BigInt codCheque,
    required String notaRemision,
  });

  /// Las transacciones bancarias del cheque. Sin ninguna, lista vacia.
  Future<List<TransaccionBancariaEntity>> listarTransacciones(BigInt codCheque);

  /// Registra una transaccion bancaria (`btnNuevoNRCH`).
  Future<void> registrarTransaccion(TransaccionBancariaEntity transaccion);

  /// Elimina la transaccion, sin boton de permiso. Devuelve cuantas filas
  /// elimino.
  Future<int> eliminarTransaccion({
    required BigInt codCheque,
    required String nroTransaccion,
  });

  /// Las postergaciones del cheque, con si cada una tiene PDF. Sin ninguna,
  /// lista vacia.
  Future<List<PostergacionEntity>> listarPostergaciones(BigInt codCheque);

  /// Registra una postergacion (`btnNuevoNRCH`). Devuelve su codPostergacion.
  Future<BigInt> registrarPostergacion(PostergacionEntity postergacion);

  /// Elimina la postergacion, sin boton de permiso; tiene que ser del cheque
  /// indicado. No borra su PDF.
  Future<BigInt> eliminarPostergacion({
    required BigInt codCheque,
    required BigInt codPostergacion,
  });

  /// Si la postergacion tiene PDF, su tamano y la fecha. Sin archivo no es un
  /// error: `existe` es false (tambien ante un 204). El PDF se llama
  /// `<codPostergacion>.pdf`.
  Future<PdfChequeEstadoEntity> estadoPdfPostergacion(BigInt codPostergacion);

  /// Carga el PDF de la postergacion (multipart); si ya tenia uno, lo reemplaza.
  /// Mismas reglas que [subirPdf].
  Future<PdfChequeSubidaEntity> subirPdfPostergacion(
    BigInt codPostergacion,
    Uint8List bytes,
    String nombreArchivo, {
    void Function(int enviados, int total)? alProgreso,
  });

  /// El PDF de la postergacion en bytes. Sin archivo, el servidor responde un
  /// error que llega como excepcion con su mensaje.
  Future<Uint8List> descargarPdfPostergacion(BigInt codPostergacion);
}
