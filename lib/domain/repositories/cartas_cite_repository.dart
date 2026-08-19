import 'dart:typed_data';

import 'package:bosque_flutter/domain/entities/carta_cite_entity.dart';

/// Contrato del módulo Cartas CITE.
abstract class CartasCiteRepository {
  /// Listado paginado. El total viaja en `totalRegistros` de cada fila.
  ///
  /// [idTipoDoc] y [codEmpresa] en 0 significan "todos".
  Future<List<CartaCiteEntity>> listar({
    required DateTime fechaDesde,
    required DateTime fechaHasta,
    required int idTipoDoc,
    required int codEmpresa,
    required int codUsuario,
    String? buscar,
    required int pagina,
    required int tamanoPagina,
  });

  /// Documento completo con sus copias, destinatarios y remitentes.
  Future<CartaCiteEntity?> obtener(BigInt idDocumento);

  /// Número que tocaría para ese tipo y empresa. Es previsualización: el
  /// definitivo lo asigna la base al guardar.
  Future<GestionCiteEntity?> siguienteCite({
    required int idTipoDoc,
    required int codEmpresa,
  });

  Future<List<TipoDocumentoCiteEntity>> tiposDocumento();

  Future<List<AreaCiteEntity>> areas(int codEmpresa);

  Future<List<EmpleadoCiteEntity>> empleados();

  Future<EmpleadoCiteEntity?> empleado(int codEmpleado);

  /// Nombre y cargo del usuario logueado, para precargar el primer remitente.
  Future<EmpleadoCiteEntity?> firmaUsuario(int codUsuario);

  Future<List<GestionCiteEntity>> gestiones();

  /// Deja activa la gestión del año en curso. Se llama al entrar al módulo:
  /// sin esto, el primer documento de enero se numeraría dentro del
  /// correlativo del año anterior.
  Future<void> prepararGestion(int audUsuario);

  /// Guarda cabecera e hijos en una sola transacción.
  ///
  /// Devuelve el mensaje del SP, que en un alta incluye el número de CITE
  /// que quedó asignado —que puede no ser el que mostraba la pantalla si
  /// alguien guardó primero.
  Future<String> guardar(
    CartaCiteEntity carta, {
    required List<BigInt> copiasAEliminar,
    required List<BigInt> destinatariosAEliminar,
    required List<BigInt> remitentesAEliminar,
    required int audUsuario,
  });

  /// Baja lógica. El número de CITE queda consumido.
  ///
  /// [motivo] queda en `tcr_documentoAnulado` junto con quién anuló y cuándo.
  Future<String> anular(BigInt idDocumento, int audUsuario, {String? motivo});

  /// PDF del documento con el formato Jasper de siempre.
  ///
  /// [logo] sólo lo mira la carta, que se imprime con o sin membrete según si
  /// el papel ya lo trae preimpreso.
  Future<Uint8List> generarPdf({
    required BigInt idDocumento,
    required bool conLogo,
    required int audUsuario,
  });

  /// Reporte mensual de documentos emitidos. [mes] en 0 = toda la gestión.
  Future<Uint8List> reporteMensual({
    required int mes,
    required int anio,
    required int idTipoDoc,
    required int codEmpresa,
  });
}
