/// Archivo de documentos (`tarc_*`). Las listas se bajan enteras y la búsqueda
/// es local: son cientos de cajas y un par de miles de líneas, y así responde al
/// tipear, por palabras y sin importar tildes ni mayúsculas.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show BuildContext;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:bosque_flutter/core/ui/visor_pdf.dart';
import 'package:bosque_flutter/core/utils/tipo_imagen.dart';
import 'package:bosque_flutter/data/repositories/archivo_documental_impl.dart';
import 'package:bosque_flutter/domain/entities/archivo_fisico_entity.dart';
import 'package:bosque_flutter/domain/entities/caja_archivo_entity.dart';
import 'package:bosque_flutter/domain/entities/contenido_caja_entity.dart';
import 'package:bosque_flutter/domain/entities/empresa_entity.dart';
import 'package:bosque_flutter/domain/entities/foto_caja_entity.dart';
import 'package:bosque_flutter/domain/entities/sucursal_archivo_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_documento_archivo_entity.dart';
import 'package:bosque_flutter/domain/repositories/archivo_documental_repository.dart';

/// Perezoso y reemplazable: las pruebas lo cambian con `overrideWithValue`.
final archivoDocumentalRepositoryProvider =
    Provider<ArchivoDocumentalRepository>((ref) => ArchivoDocumentalImpl());

@immutable
class ArchivoDocumentalState {
  const ArchivoDocumentalState({
    this.archivos = const [],
    this.tipos = const [],
    this.cajas = const [],
    this.contenido = const [],
    this.empresas = const [],
    this.cargando = false,
    this.cargado = false,
    this.error,
  });

  final List<ArchivoFisicoEntity> archivos;
  final List<TipoDocumentoArchivoEntity> tipos;
  final List<CajaArchivoEntity> cajas;
  final List<ContenidoCajaEntity> contenido;
  final List<EmpresaEntity> empresas;
  final bool cargando;

  /// Ya hubo una respuesta buena: distingue «no llegó» de «llegó vacío».
  final bool cargado;
  final Object? error;

  CajaArchivoEntity? caja(int codCaja) {
    for (final c in cajas) {
      if (c.codCaja == codCaja) return c;
    }
    return null;
  }

  List<ContenidoCajaEntity> lineasDe(int codCaja) =>
      contenido.where((l) => l.codCaja == codCaja).toList();

  ArchivoDocumentalState copyWith({
    List<ArchivoFisicoEntity>? archivos,
    List<TipoDocumentoArchivoEntity>? tipos,
    List<CajaArchivoEntity>? cajas,
    List<ContenidoCajaEntity>? contenido,
    List<EmpresaEntity>? empresas,
    bool? cargando,
    bool? cargado,
    Object? error,
    bool limpiarError = false,
  }) => ArchivoDocumentalState(
    archivos: archivos ?? this.archivos,
    tipos: tipos ?? this.tipos,
    cajas: cajas ?? this.cajas,
    contenido: contenido ?? this.contenido,
    empresas: empresas ?? this.empresas,
    cargando: cargando ?? this.cargando,
    cargado: cargado ?? this.cargado,
    error: limpiarError ? null : (error ?? this.error),
  );
}

class ArchivoDocumentalNotifier extends StateNotifier<ArchivoDocumentalState> {
  ArchivoDocumentalNotifier(this._repo) : super(const ArchivoDocumentalState()) {
    Future.microtask(cargar);
  }

  final ArchivoDocumentalRepository _repo;

  /// Solo la lectura más nueva escribe: una respuesta tardía no pisa a la buena.
  int _lectura = 0;
  Future<void>? _actual;

  Future<void> cargar() {
    if (!mounted) return Future<void>.value();
    final lectura = _leer(++_lectura);
    _actual = lectura;
    return lectura;
  }

  Future<void> _leer(int mia) async {
    state = state.copyWith(cargando: true, limpiarError: true);
    try {
      final r = await Future.wait<List<Object>>([
        _repo.listarArchivos(),
        _repo.listarTipos(),
        _repo.listarCajas(),
        _repo.listarContenido(),
        _repo.listarEmpresas(),
      ]);
      if (!mounted) return;
      if (mia != _lectura) return await _actual;
      state = state.copyWith(
        archivos: r[0].cast<ArchivoFisicoEntity>(),
        tipos: r[1].cast<TipoDocumentoArchivoEntity>(),
        cajas: r[2].cast<CajaArchivoEntity>(),
        contenido: r[3].cast<ContenidoCajaEntity>(),
        empresas: r[4].cast<EmpresaEntity>(),
        cargando: false,
        cargado: true,
      );
    } catch (e) {
      if (!mounted) return;
      if (mia != _lectura) return await _actual;
      state = state.copyWith(cargando: false, error: e);
    }
  }

  // Cada escritura lanza con el motivo del servidor y, si sale bien, recarga.

  Future<int> guardarCaja(CajaArchivoEntity c) => _y(_repo.registrarCaja(c));
  Future<void> eliminarCaja(int codCaja) => _y(_repo.eliminarCaja(codCaja));
  Future<int> guardarContenido(ContenidoCajaEntity c) =>
      _y(_repo.registrarContenido(c));
  Future<void> eliminarContenido(int cod) => _y(_repo.eliminarContenido(cod));
  Future<int> guardarArchivo(ArchivoFisicoEntity a) =>
      _y(_repo.registrarArchivo(a));
  Future<void> eliminarArchivo(int cod) => _y(_repo.eliminarArchivo(cod));
  Future<int> guardarTipo(TipoDocumentoArchivoEntity t) =>
      _y(_repo.registrarTipo(t));
  Future<void> eliminarTipo(int cod) => _y(_repo.eliminarTipo(cod));

  /// Tras una foto solo cambia el contador de la caja, pero recargar todo
  /// mantiene una única forma de quedar al día.
  Future<void> fotosCambiaron() => cargar();

  Future<T> _y<T>(Future<T> escritura) async {
    final r = await escritura;
    await cargar();
    return r;
  }
}

final archivoDocumentalProvider = StateNotifierProvider.autoDispose<
  ArchivoDocumentalNotifier,
  ArchivoDocumentalState
>((ref) => ArchivoDocumentalNotifier(ref.watch(archivoDocumentalRepositoryProvider)));

// ── Fotos ─────────────────────────────────────────────────────────────────

final fotosCajaProvider = FutureProvider.autoDispose
    .family<List<FotoCajaEntity>, int>(
      (ref, codCaja) =>
          ref.watch(archivoDocumentalRepositoryProvider).listarFotos(codCaja),
    );

/// La ruta cambia con cada reemplazo: con ella en la clave, una foto nueva
/// nunca muestra la imagen vieja que quedó en caché.
typedef ClaveFoto = ({int codFoto, String? ruta});

final bytesFotoProvider = FutureProvider.autoDispose
    .family<Uint8List, ClaveFoto>(
      (ref, clave) =>
          ref.watch(archivoDocumentalRepositoryProvider).verFoto(clave.codFoto),
    );

enum OrigenFoto { camara, galeria }

@immutable
class FotoElegida {
  const FotoElegida(this.bytes, this.nombre);
  final Uint8List bytes;
  final String nombre;
}

typedef ElegirFoto = Future<FotoElegida?> Function(OrigenFoto origen);

/// El mismo tope que el servidor: rechazar aquí ahorra subir megas para nada.
const int maximoBytesFoto = 8 * 1024 * 1024;

/// Por qué no se puede subir [bytes], o null si se puede. En escritorio el
/// selector no achica la imagen y en la web, si no la puede leer, devuelve el
/// original: por eso se mira el formato real y el peso después de elegir.
String? motivoFotoInvalida(Uint8List bytes) {
  if (bytes.isEmpty) return 'La foto llegó vacía. Elige otra.';
  if (tipoDeImagen(bytes) == null) {
    return 'Esa imagen no es JPG, PNG ni WEBP. Elige otra o sácale una captura.';
  }
  if (bytes.length > maximoBytesFoto) {
    final mb = (bytes.length / (1024 * 1024)).toStringAsFixed(1).replaceAll('.', ',');
    return 'La foto pesa $mb MB y el máximo es 8 MB. Elige una más liviana.';
  }
  return null;
}

/// Se comprime en el dispositivo: 1600 px y calidad 80 dejan legible la
/// etiqueta de una caja en unos cientos de KB. Siempre por bytes (nunca
/// `File`), que es lo único que existe igual en la web y en el teléfono.
final elegirFotoProvider = Provider<ElegirFoto>(
  (ref) => (origen) async {
    final XFile? x;
    try {
      x = await ImagePicker().pickImage(
        source: origen == OrigenFoto.camara ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 80,
      );
    } on PlatformException catch (e) {
      throw Exception(switch (e.code) {
        'camera_access_denied' =>
          'No hay permiso para usar la cámara. Actívalo en los ajustes del teléfono.',
        'photo_access_denied' =>
          'No hay permiso para ver tus fotos. Actívalo en los ajustes del teléfono.',
        _ => 'No se pudo abrir ${origen == OrigenFoto.camara ? 'la cámara' : 'la galería'}.',
      });
    }
    if (x == null) return null;
    final bytes = await x.readAsBytes();
    final motivo = motivoFotoInvalida(bytes);
    if (motivo != null) throw Exception(motivo);
    return FotoElegida(bytes, x.name);
  },
);

/// En la web solo el navegador de un teléfono abre la cámara: en escritorio
/// «Tomar foto» sería otro selector de archivos con distinto nombre.
final camaraDisponibleProvider = Provider<bool>((ref) {
  if (kIsWeb) {
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }
  return ImagePicker().supportsImageSource(ImageSource.camera);
});

typedef VerPdf =
    Future<void> Function(
      BuildContext context, {
      required Uint8List bytes,
      required String titulo,
      required String nombreArchivo,
    });

/// El visor de los reportes. Reemplazable en las pruebas: `PdfPreview` usa
/// plugins que `flutter test` no tiene.
final visorPdfArchivoProvider = Provider<VerPdf>((ref) => mostrarPdf);

/// Las sucursales para ubicar un archivo: solo las pide la ficha del archivo.
final sucursalesArchivoProvider = FutureProvider.autoDispose<List<SucursalArchivoEntity>>(
  (ref) => ref.watch(archivoDocumentalRepositoryProvider).listarSucursales(),
);

// ── Búsqueda ──────────────────────────────────────────────────────────────

/// Valor de [FiltroArchivo.codEmpresa] para las líneas sin empresa (OTROS).
const int sinEmpresa = 0;

@immutable
class FiltroArchivo {
  const FiltroArchivo({
    this.texto = '',
    this.codArchivo,
    this.numeroCaja,
    this.codTipoDocumento,
    this.codEmpresa,
    this.anio,
  });

  /// Cada palabra tiene que aparecer en la línea o en los datos de su caja.
  final String texto;
  final int? codArchivo;
  final int? numeroCaja;
  final int? codTipoDocumento;

  /// [sinEmpresa] filtra las líneas que no tienen empresa.
  final int? codEmpresa;

  /// Las líneas cuya gestión cubre ese año.
  final int? anio;

  int get criterios => [
    codArchivo,
    numeroCaja,
    codTipoDocumento,
    codEmpresa,
    anio,
  ].where((v) => v != null).length;

  bool get hayAlgo => texto.trim().isNotEmpty || criterios > 0;

  bool get _filtraLineas =>
      texto.trim().isNotEmpty ||
      codTipoDocumento != null ||
      codEmpresa != null ||
      anio != null;

  FiltroArchivo copyWith({
    String? texto,
    int? codArchivo,
    int? numeroCaja,
    int? codTipoDocumento,
    int? codEmpresa,
    int? anio,
    bool limpiarArchivo = false,
    bool limpiarNumero = false,
    bool limpiarTipo = false,
    bool limpiarEmpresa = false,
    bool limpiarAnio = false,
  }) => FiltroArchivo(
    texto: texto ?? this.texto,
    codArchivo: limpiarArchivo ? null : (codArchivo ?? this.codArchivo),
    numeroCaja: limpiarNumero ? null : (numeroCaja ?? this.numeroCaja),
    codTipoDocumento:
        limpiarTipo ? null : (codTipoDocumento ?? this.codTipoDocumento),
    codEmpresa: limpiarEmpresa ? null : (codEmpresa ?? this.codEmpresa),
    anio: limpiarAnio ? null : (anio ?? this.anio),
  );

  /// Las cajas que cumplen, ordenadas por archivo y número, con sus líneas
  /// coincidentes cuando el filtro mira el contenido.
  List<ResultadoCaja> aplicar(
    List<CajaArchivoEntity> cajas,
    List<ContenidoCajaEntity> contenido,
  ) {
    final porCaja = <int, List<ContenidoCajaEntity>>{};
    for (final l in contenido) {
      (porCaja[l.codCaja] ??= []).add(l);
    }
    final palabras =
        normalizarBusqueda(texto).split(' ').where((p) => p.isNotEmpty).toList();

    bool lineaCumple(ContenidoCajaEntity l, String textoCaja) {
      if (codTipoDocumento != null && l.codTipoDocumento != codTipoDocumento) {
        return false;
      }
      if (codEmpresa == sinEmpresa && l.codEmpresa != null) return false;
      if (codEmpresa != null && codEmpresa != sinEmpresa && l.codEmpresa != codEmpresa) {
        return false;
      }
      if (anio != null &&
          (l.anioDesde == null || anio! < l.anioDesde! || anio! > l.anioHasta!)) {
        return false;
      }
      if (palabras.isEmpty) return true;
      final pajar = '$textoCaja ${textoDeLinea(l)}';
      return palabras.every(pajar.contains);
    }

    final resultado = <ResultadoCaja>[];
    for (final caja in cajas) {
      if (codArchivo != null && caja.codArchivo != codArchivo) continue;
      if (numeroCaja != null && caja.numero != numeroCaja) continue;
      final lineas = porCaja[caja.codCaja] ?? const <ContenidoCajaEntity>[];
      if (!_filtraLineas) {
        resultado.add(ResultadoCaja(caja, lineas));
        continue;
      }
      final textoCaja = textoDeCaja(caja);
      final coinciden = [for (final l in lineas) if (lineaCumple(l, textoCaja)) l];
      // Una caja vacía puede coincidir por sus propios datos (la observación).
      final soloPorCaja =
          coinciden.isEmpty &&
          lineas.isEmpty &&
          codTipoDocumento == null &&
          codEmpresa == null &&
          anio == null &&
          palabras.every(textoCaja.contains);
      if (coinciden.isEmpty && !soloPorCaja) continue;
      resultado.add(ResultadoCaja(caja, lineas, coincidencias: coinciden, filtrada: true));
    }
    resultado.sort((a, b) {
      final porArchivo = (a.caja.nombreArchivo ?? '').compareTo(
        b.caja.nombreArchivo ?? '',
      );
      return porArchivo != 0 ? porArchivo : a.caja.numero.compareTo(b.caja.numero);
    });
    return resultado;
  }

  static String textoDeCaja(CajaArchivoEntity c) => normalizarBusqueda(
    [c.nombreArchivo, c.estante, c.fila, c.observacion].whereType<String>().join(' '),
  );

  static String textoDeLinea(ContenidoCajaEntity l) => normalizarBusqueda(
    [
      l.nombreTipoDocumento,
      l.detalle,
      l.gestion,
      l.nombreEmpresa,
      l.observacion,
    ].whereType<String>().join(' '),
  );
}

@immutable
class ResultadoCaja {
  const ResultadoCaja(
    this.caja,
    this.lineas, {
    this.coincidencias = const [],
    this.filtrada = false,
  });

  final CajaArchivoEntity caja;
  final List<ContenidoCajaEntity> lineas;

  /// Las líneas que cumplen el filtro (vacía si el filtro no mira contenido).
  final List<ContenidoCajaEntity> coincidencias;
  final bool filtrada;
}

/// Minúsculas, sin tildes y con los espacios colapsados.
String normalizarBusqueda(String texto) {
  const de = 'áàäâéèëêíìïîóòöôúùüûñç';
  const a = 'aaaaeeeeiiiioooouuuunc';
  final b = StringBuffer();
  for (final ch in texto.toLowerCase().split('')) {
    final i = de.indexOf(ch);
    b.write(i < 0 ? ch : a[i]);
  }
  return b.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// El menor o mayor año de cuatro cifras (1900-2100) de una gestión: la misma
/// regla que `dbo.f_tarc_anio` en la base, para validar antes de enviar.
int? anioDeGestion(String? gestion, {bool mayor = false}) {
  int? r;
  for (final m in RegExp(r'(?<!\d)[12]\d{3}(?!\d)').allMatches(gestion ?? '')) {
    final n = int.parse(m.group(0)!);
    if (n < 1900 || n > 2100) continue;
    if (r == null || (mayor ? n > r : n < r)) r = n;
  }
  return r;
}
