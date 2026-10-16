import 'dart:typed_data';

import 'package:bosque_flutter/domain/entities/archivo_fisico_entity.dart';
import 'package:bosque_flutter/domain/entities/caja_archivo_entity.dart';
import 'package:bosque_flutter/domain/entities/contenido_caja_entity.dart';
import 'package:bosque_flutter/domain/entities/destruccion_documento_entity.dart';
import 'package:bosque_flutter/domain/entities/empleado_archivo_entity.dart';
import 'package:bosque_flutter/domain/entities/empresa_entity.dart';
import 'package:bosque_flutter/domain/entities/entrega_documento_entity.dart';
import 'package:bosque_flutter/domain/entities/foto_caja_entity.dart';
import 'package:bosque_flutter/domain/entities/prestamo_documento_entity.dart';
import 'package:bosque_flutter/domain/entities/sucursal_archivo_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_documento_archivo_entity.dart';

/// Archivo de documentos. Las escrituras lanzan con el motivo del servidor;
/// alta si el id es 0, edición si no, y devuelven el id.
abstract class ArchivoDocumentalRepository {
  Future<List<ArchivoFisicoEntity>> listarArchivos();
  Future<int> registrarArchivo(ArchivoFisicoEntity archivo);
  Future<void> eliminarArchivo(int codArchivo);

  Future<List<TipoDocumentoArchivoEntity>> listarTipos();
  Future<int> registrarTipo(TipoDocumentoArchivoEntity tipo);
  Future<void> eliminarTipo(int codTipoDocumento);

  /// Todas las cajas: la búsqueda se hace del lado del cliente.
  Future<List<CajaArchivoEntity>> listarCajas();
  Future<int> siguienteNumero(int codArchivo);
  Future<int> registrarCaja(CajaArchivoEntity caja);
  Future<void> eliminarCaja(int codCaja);

  /// Todo el contenido de todas las cajas.
  Future<List<ContenidoCajaEntity>> listarContenido();
  Future<int> registrarContenido(ContenidoCajaEntity contenido);
  Future<void> eliminarContenido(int codContenido);

  /// Las fotos y los PDF de la caja (comparten los tres lugares).
  Future<List<FotoCajaEntity>> listarFotos(int codCaja);

  /// [alProgreso] recibe bytes enviados y total, para la barra de la subida.
  /// [bytes] puede ser una imagen o un PDF: el servidor mira el contenido.
  Future<int> subirFoto(
    int codCaja,
    Uint8List bytes,
    String nombre, {
    void Function(int enviados, int total)? alProgreso,
  });
  Future<void> reemplazarFoto(
    int codFoto,
    Uint8List bytes,
    String nombre, {
    void Function(int enviados, int total)? alProgreso,
  });
  Future<void> eliminarFoto(int codFoto);
  Future<Uint8List> verFoto(int codFoto);

  Future<List<EmpresaEntity>> listarEmpresas();

  /// Las sucursales (`tb_sucursal`) para ubicar un archivo físico.
  Future<List<SucursalArchivoEntity>> listarSucursales();

  /// Los empleados (`tb_empleado`) para el responsable y los préstamos.
  Future<List<EmpleadoArchivoEntity>> listarEmpleados();

  /// Las entregas a empleados, las que tienen algo afuera primero.
  Future<List<EntregaDocumentoEntity>> listarEntregas();

  /// Cajas completas y documentos de cualquier caja a un empleado, en un solo
  /// paso: todo o nada, con la misma hora. Devuelve el número de la entrega.
  Future<int> registrarEntrega(PedidoEntrega pedido);

  /// Vuelve todo lo que sigue afuera de la entrega, con la hora del servidor.
  Future<void> devolverEntrega(int codEntrega, {String? observacion});

  /// Solo una entrega sin devoluciones (registrada por error).
  Future<void> anularEntrega(int codEntrega);

  /// Todos los renglones de las entregas, lo que sigue afuera primero.
  Future<List<PrestamoDocumentoEntity>> listarPrestamos();

  /// Vuelve un renglón solo; la hora la pone el servidor.
  Future<void> devolver(int codPrestamo, {String? observacion});

  /// Un renglón que sigue afuera; si era el último, se va con su entrega.
  Future<void> anularPrestamo(int codPrestamo);

  /// La bitácora de destrucción, la más nueva arriba.
  Future<List<DestruccionDocumentoEntity>> listarDestrucciones();
  Future<void> destruir(PedidoMovimientoCaja pedido);
  Future<void> anularDestruccion(int codDestruccion);

  /// El PDF de un reporte. Sin documentos que cumplan lanza con el motivo.
  Future<Uint8List> generarReporte(PedidoReporteArchivo pedido);
}

/// Los reportes del archivo; [clave] es el nombre que espera el backend.
/// [porCaja] no se elige en la ficha de reportes: sale desde la caja abierta.
enum ReporteArchivo {
  porSucursal('POR_SUCURSAL', 'Documentos por sucursal'),
  porTipo('POR_TIPO', 'Dónde está cada tipo de documento'),
  detalle('DETALLE', 'Detalle de documentos por caja'),
  porCaja('POR_CAJA', 'Contenido de la caja');

  const ReporteArchivo(this.clave, this.titulo);

  final String clave;
  final String titulo;
}

/// Un pedido de reporte. Todo filtro null es «todos»; [codEmpresa] = 0 pide los
/// documentos sin empresa. [codCaja] solo lo usa [ReporteArchivo.porCaja].
class PedidoReporteArchivo {
  const PedidoReporteArchivo({
    required this.reporte,
    this.codSucursal,
    this.codTipoDocumento,
    this.codEmpresa,
    this.anioDesde,
    this.anioHasta,
    this.codCaja,
  });

  final ReporteArchivo reporte;
  final int? codSucursal;
  final int? codTipoDocumento;
  final int? codEmpresa;
  final int? anioDesde;
  final int? anioHasta;
  final int? codCaja;

  Map<String, dynamic> toJson() => {
    'reporte': reporte.clave,
    'codSucursal': codSucursal,
    'codTipoDocumento': codTipoDocumento,
    'codEmpresa': codEmpresa,
    'anioDesde': anioDesde,
    'anioHasta': anioHasta,
    'codCaja': codCaja,
  };
}

/// Prestar o destruir desde una caja: las [lineas] elegidas o, vacía, la caja
/// completa. [codEmpleado] solo cuenta al prestar, que viaja como [aEntrega].
class PedidoMovimientoCaja {
  const PedidoMovimientoCaja({
    required this.codCaja,
    this.lineas = const [],
    this.codEmpleado,
    this.observacion,
  });

  final int codCaja;
  final List<int> lineas;
  final int? codEmpleado;
  final String? observacion;

  bool get cajaCompleta => lineas.isEmpty;

  /// Lo que lee el registro de destrucción.
  Map<String, dynamic> toJson() => {'codCaja': codCaja, 'lineas': lineas, 'observacion': observacion};

  /// El préstamo desde la caja es una entrega de esa sola caja.
  PedidoEntrega aEntrega() => PedidoEntrega(
    codEmpleado: codEmpleado,
    cajas: cajaCompleta ? [codCaja] : const [],
    lineas: lineas,
    observacion: observacion,
  );
}

/// Una entrega a un empleado: [cajas] que se llevan completas y [lineas]
/// sueltas de cualquier caja. El servidor la guarda toda junta o nada.
class PedidoEntrega {
  const PedidoEntrega({this.codEmpleado, this.cajas = const [], this.lineas = const [], this.observacion});

  final int? codEmpleado;
  final List<int> cajas;
  final List<int> lineas;
  final String? observacion;

  Map<String, dynamic> toJson() => {
    'codEmpleado': codEmpleado,
    'cajas': cajas,
    'lineas': lineas,
    'observacion': observacion,
  };
}
