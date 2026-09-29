import 'dart:typed_data';

import 'package:bosque_flutter/domain/entities/accion_cbr_entity.dart';
import 'package:bosque_flutter/domain/entities/cbr_detalle_entity.dart';
import 'package:bosque_flutter/domain/entities/cliente_sap_entity.dart';
import 'package:bosque_flutter/domain/entities/garantia_cbr_entity.dart';
import 'package:bosque_flutter/domain/entities/garantia_registro_entity.dart';
import 'package:bosque_flutter/domain/entities/garantia_resumen_cliente_entity.dart';
import 'package:bosque_flutter/domain/entities/garantia_vista_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_cbr_entity.dart';

/// Contrato del modulo de garantias de cobranza (tcbr). Espeja
/// API_GARANTIAS.md del proyecto de migracion.
///
/// Reglas que valen para TODOS los metodos:
///
/// * Todo es POST, tambien las lecturas, y siempre con cuerpo JSON.
/// * Un 204 es exito sin datos: los listados devuelven lista vacia y las
///   consultas de una fila, null. Nunca es un error.
/// * Un 400 llega como el mensaje del backend, listo para mostrar tal cual.
/// * El usuario de auditoria NO viaja: el backend lo toma del token.
/// * Las escrituras y los PDF exigen el boton de la vista 45 que indica cada
///   metodo; sin el, el backend responde 403. La pantalla oculta la accion,
///   pero la puerta que cierra es la del servidor.
abstract class GarantiasRepository {
  // ============================ LECTURAS ===================================

  /// Una fila por cliente con garantias. [buscar] filtra por codigo o nombre;
  /// null trae todos.
  Future<List<GarantiaResumenClienteEntity>> obtenerResumenClientes({
    String? buscar,
  });

  /// Garantias con sus datos calculados. Todos los filtros son opcionales:
  /// `venc*` filtra por fecha de expiracion y `reg*` por fecha de registro.
  /// [estado] es VIGENTE, CADUCADO o CERRADO.
  Future<List<GarantiaVistaEntity>> listarGarantias({
    String? codClienteSAP,
    String? estado,
    String? tipoGarantia,
    DateTime? vencDesde,
    DateTime? vencHasta,
    DateTime? regDesde,
    DateTime? regHasta,
  });

  /// Una garantia por id. El backend responde 400 si no existe.
  Future<GarantiaVistaEntity?> obtenerGarantia(BigInt codGarantia);

  /// Clientes de SAP para el alta. [buscar] necesita al menos 3 caracteres;
  /// el backend devuelve hasta 50.
  Future<List<ClienteSapEntity>> buscarClientesSap(String buscar);

  Future<List<CbrDetalleEntity>> obtenerDetalles(BigInt codGarantia);

  Future<List<AccionCbrEntity>> obtenerAcciones(BigInt codGarantia);

  /// Cuantas garantias esperan el traspaso a custodia.
  Future<int> contarTraspasosPendientes();

  /// Catalogo de tipos de garantia (v_tipos grupo 28).
  Future<List<TipoCbrEntity>> obtenerTiposGarantia();

  /// Catalogo de estados de accion (v_tipos grupo 29), para las etiquetas.
  Future<List<TipoCbrEntity>> obtenerEstadosAccion();

  // =========================== ESCRITURAS ==================================

  /// Alta (codGarantia 0; boton btnNewGarCbr) o edicion de firmas, protesta y
  /// detalles nuevos (codGarantia > 0; boton btnEditGarCbr). Devuelve el id.
  Future<BigInt> registrarGarantia(GarantiaRegistroEntity registro);

  /// Edicion administrativa (btnEditAdmGarCbr): reemplaza todo menos el
  /// cliente. Hay que mandar el registro completo: un null en recFirmas o
  /// nroProtesta los borra.
  Future<BigInt> actualizarGarantia(GarantiaCbrEntity garantia);

  /// Extension (btnExtAcCbr): registra la accion EXT y mueve la fecha de
  /// expiracion. Exige traspaso previo y una fecha nueva mayor a la actual.
  Future<BigInt> registrarExtension({
    required BigInt codGarantia,
    required DateTime fecha,
    required String? observacion,
    required DateTime fechaExpiracion,
  });

  /// Alta de un detalle, o cambio de su monto (btnEditGarCbr).
  Future<BigInt> registrarDetalle(CbrDetalleEntity detalle);

  /// Baja de un detalle (btnEditGarCbr).
  Future<BigInt> eliminarDetalle(BigInt codDetalle);

  /// Alta (btnNewAcCbr; solo NOT o CER) o edicion de la observacion
  /// (btnEditAcCbr).
  Future<BigInt> registrarAccion(AccionCbrEntity accion);

  /// Baja de una accion (btnDelAcCbr).
  Future<BigInt> eliminarAccion(BigInt codAccion);

  /// Traspasa todas las pendientes (btnTraspGarCbr). Devuelve cuantas; 0 no es
  /// error.
  Future<int> generarTraspaso();

  // ============================ REPORTES ===================================

  /// Recibo de una garantia con sus detalles (btnRptUltGarCbr).
  Future<Uint8List> reporteRecibo(BigInt codGarantia);

  /// Nomina del ultimo traspaso (btnTraspGarCbr).
  Future<Uint8List> reporteTraspaso();

  /// Listado filtrado (btnRptGaCbr). Mismos filtros que [listarGarantias].
  Future<Uint8List> reporteBusqueda({
    String? codClienteSAP,
    String? estado,
    String? tipoGarantia,
    DateTime? vencDesde,
    DateTime? vencHasta,
    DateTime? regDesde,
    DateTime? regHasta,
  });
}
