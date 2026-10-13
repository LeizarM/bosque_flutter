import 'dart:convert';
import 'dart:typed_data';

import 'package:bosque_flutter/domain/entities/archivo_fisico_entity.dart';
import 'package:bosque_flutter/domain/entities/caja_archivo_entity.dart';
import 'package:bosque_flutter/domain/entities/contenido_caja_entity.dart';
import 'package:bosque_flutter/domain/entities/empresa_entity.dart';
import 'package:bosque_flutter/domain/entities/foto_caja_entity.dart';
import 'package:bosque_flutter/domain/entities/sucursal_archivo_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_documento_archivo_entity.dart';
import 'package:bosque_flutter/domain/repositories/archivo_documental_repository.dart';

/// PNG de 1x1: decodifica de verdad, así una miniatura no reporta error.
final Uint8List pngDePrueba = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
);

/// Datos calcados de los Excel: la caja 1 existe en los dos archivos y solo
/// la de Oficina Central tiene estante.
class RepositorioArchivoFalso implements ArchivoDocumentalRepository {
  RepositorioArchivoFalso({this.vacio = false, this.fallaLectura = false}) {
    if (!vacio) _sembrar();
  }

  final bool vacio;
  bool fallaLectura;

  final archivos = <ArchivoFisicoEntity>[];
  final tipos = <TipoDocumentoArchivoEntity>[];
  final cajas = <CajaArchivoEntity>[];
  final contenido = <ContenidoCajaEntity>[];
  final fotos = <FotoCajaEntity>[];
  final empresas = [
    EmpresaEntity(codEmpresa: 1, nombre: 'IMPEXPAP', codPadre: 0, sigla: 'IPX', audUsuario: 0),
    EmpresaEntity(codEmpresa: 5, nombre: 'ESPPAPEL', codPadre: 0, sigla: 'EPP', audUsuario: 0),
  ];

  /// Lo que la pantalla mandó a guardar, en orden.
  final escrituras = <String>[];

  /// Los reportes pedidos, en orden.
  final pedidos = <PedidoReporteArchivo>[];
  String? rechazo;
  int _id = 100;

  void _sembrar() {
    archivos.addAll(const [
      ArchivoFisicoEntity(codArchivo: 1, nombre: 'ACHOCALLA', responsable: 'Victor', codSucursal: 15, nombreSucursal: 'Sucursal 15 Achocalla', ciudadSucursal: 'LA PAZ', cajas: 2, lineas: 3),
      ArchivoFisicoEntity(codArchivo: 2, nombre: 'OFICINA CENTRAL', codSucursal: 1, nombreSucursal: 'Central', ciudadSucursal: 'LA PAZ', cajas: 1, lineas: 2),
    ]);
    tipos.addAll(const [
      TipoDocumentoArchivoEntity(codTipoDocumento: 10, nombre: 'Facturas', usos: 2),
      TipoDocumentoArchivoEntity(codTipoDocumento: 11, nombre: 'Notas de remisión', usos: 1),
      TipoDocumentoArchivoEntity(codTipoDocumento: 12, nombre: 'Importaciones', usos: 2),
    ]);
    cajas.addAll(const [
      CajaArchivoEntity(codCaja: 1, codArchivo: 1, numero: 1, nombreArchivo: 'ACHOCALLA', lineas: 1, anioDesde: 2010, anioHasta: 2010),
      CajaArchivoEntity(codCaja: 2, codArchivo: 1, numero: 2, nombreArchivo: 'ACHOCALLA', lineas: 2, anioDesde: 2015, anioHasta: 2017),
      CajaArchivoEntity(codCaja: 3, codArchivo: 2, numero: 1, estante: '1', fila: '1', nombreArchivo: 'OFICINA CENTRAL', lineas: 2, anioDesde: 2018, anioHasta: 2019),
    ]);
    contenido.addAll(const [
      ContenidoCajaEntity(codContenido: 1, codCaja: 1, codTipoDocumento: 11, nombreTipoDocumento: 'Notas de remisión', detalle: 'Notas de remisión Suc. 8 enero 2010', gestion: '2010', anioDesde: 2010, anioHasta: 2010),
      ContenidoCajaEntity(codContenido: 2, codCaja: 2, codTipoDocumento: 10, codEmpresa: 1, nombreTipoDocumento: 'Facturas', nombreEmpresa: 'IMPEXPAP', detalle: 'Facturas emisores septiembre 2016', gestion: '2016', anioDesde: 2016, anioHasta: 2016),
      ContenidoCajaEntity(codContenido: 3, codCaja: 2, codTipoDocumento: 10, nombreTipoDocumento: 'Facturas', detalle: 'Facturas Papirus talonarios 1 - 6', gestion: '2015 - 2017', anioDesde: 2015, anioHasta: 2017),
      ContenidoCajaEntity(codContenido: 4, codCaja: 3, codTipoDocumento: 12, nombreTipoDocumento: 'Importaciones', detalle: 'Registro de Importaciones COMEX Nº 68', gestion: '2018', anioDesde: 2018, anioHasta: 2018),
      ContenidoCajaEntity(codContenido: 5, codCaja: 3, codTipoDocumento: 12, nombreTipoDocumento: 'Importaciones', detalle: 'Proceso de Importación Nº 18/03', gestion: '2018 - 2019', anioDesde: 2018, anioHasta: 2019),
    ]);
  }

  Future<List<T>> _leer<T>(List<T> l) async {
    if (fallaLectura) throw Exception('No se pudo conectar con el servidor. Revisa tu conexión a internet.');
    return List<T>.of(l);
  }

  Future<int> _escribir(String que) async {
    escrituras.add(que);
    final r = rechazo;
    if (r != null) {
      rechazo = null;
      throw Exception(r);
    }
    return ++_id;
  }

  @override
  Future<List<ArchivoFisicoEntity>> listarArchivos() => _leer(archivos);
  @override
  Future<int> registrarArchivo(ArchivoFisicoEntity a) => _escribir('archivo ${a.codArchivo} ${a.nombre}');
  @override
  Future<void> eliminarArchivo(int codArchivo) => _escribir('eliminar archivo $codArchivo');

  @override
  Future<List<TipoDocumentoArchivoEntity>> listarTipos() => _leer(tipos);
  @override
  Future<int> registrarTipo(TipoDocumentoArchivoEntity t) => _escribir('tipo ${t.codTipoDocumento} ${t.nombre}');
  @override
  Future<void> eliminarTipo(int codTipoDocumento) => _escribir('eliminar tipo $codTipoDocumento');

  @override
  Future<List<CajaArchivoEntity>> listarCajas() => _leer(cajas);
  @override
  Future<int> siguienteNumero(int codArchivo) async =>
      cajas.where((c) => c.codArchivo == codArchivo).fold<int>(0, (m, c) => c.numero > m ? c.numero : m) + 1;
  @override
  Future<int> registrarCaja(CajaArchivoEntity c) => _escribir('caja ${c.codCaja} ${c.codArchivo}/${c.numero}');
  @override
  Future<void> eliminarCaja(int codCaja) async {
    await _escribir('eliminar caja $codCaja');
    cajas.removeWhere((c) => c.codCaja == codCaja);
  }

  @override
  Future<List<ContenidoCajaEntity>> listarContenido() => _leer(contenido);
  @override
  Future<int> registrarContenido(ContenidoCajaEntity c) =>
      _escribir('contenido ${c.codContenido} caja ${c.codCaja} tipo ${c.codTipoDocumento} "${c.detalle}" gestion ${c.gestion}');
  @override
  Future<void> eliminarContenido(int codContenido) => _escribir('eliminar contenido $codContenido');

  @override
  Future<List<FotoCajaEntity>> listarFotos(int codCaja) async =>
      fotos.where((f) => f.codCaja == codCaja).toList();
  @override
  Future<int> subirFoto(int codCaja, Uint8List bytes, String nombre, {void Function(int, int)? alProgreso}) async {
    final id = await _escribir('subir foto caja $codCaja $nombre');
    fotos.add(FotoCajaEntity(codFoto: id, codCaja: codCaja, orden: fotos.where((f) => f.codCaja == codCaja).length + 1, ruta: 'archivo-cajas/$id.png'));
    return id;
  }

  @override
  Future<void> reemplazarFoto(int codFoto, Uint8List bytes, String nombre, {void Function(int, int)? alProgreso}) =>
      _escribir('reemplazar foto $codFoto');
  @override
  Future<void> eliminarFoto(int codFoto) async {
    await _escribir('eliminar foto $codFoto');
    fotos.removeWhere((f) => f.codFoto == codFoto);
  }

  /// Lo que devuelve `verFoto`; las capturas ponen una foto de verdad.
  Uint8List bytesFoto = pngDePrueba;

  @override
  Future<Uint8List> verFoto(int codFoto) async => bytesFoto;

  @override
  Future<List<EmpresaEntity>> listarEmpresas() => _leer(empresas);

  @override
  Future<List<SucursalArchivoEntity>> listarSucursales() async => const [
    SucursalArchivoEntity(codSucursal: 1, nombre: 'Central', codEmpresa: 1, nombreEmpresa: 'IMPEXPAP', ciudad: 'LA PAZ'),
    SucursalArchivoEntity(codSucursal: 15, nombre: 'Sucursal 15 Achocalla', codEmpresa: 1, nombreEmpresa: 'IMPEXPAP', ciudad: 'LA PAZ'),
  ];

  /// Un PDF mínimo de mentira: el visor de las pruebas solo lo anota.
  @override
  Future<Uint8List> generarReporte(PedidoReporteArchivo pedido) async {
    pedidos.add(pedido);
    final r = rechazo;
    if (r != null) {
      rechazo = null;
      throw Exception(r);
    }
    return Uint8List.fromList(utf8.encode('%PDF-1.4 prueba'));
  }
}
