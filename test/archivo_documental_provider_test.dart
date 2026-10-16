import 'dart:typed_data';

import 'package:bosque_flutter/core/state/archivo_documental_provider.dart';
import 'package:bosque_flutter/core/utils/tipo_imagen.dart';
import 'package:bosque_flutter/domain/entities/caja_archivo_entity.dart';
import 'package:bosque_flutter/domain/entities/contenido_caja_entity.dart';
import 'package:bosque_flutter/domain/entities/entrega_documento_entity.dart';
import 'package:bosque_flutter/domain/entities/foto_caja_entity.dart';
import 'package:bosque_flutter/domain/entities/prestamo_documento_entity.dart';
import 'package:bosque_flutter/domain/repositories/archivo_documental_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/repositorio_archivo_documental.dart';

/// La búsqueda del archivo, la regla de años (la misma de dbo.f_tarc_anio) y la carga del estado.
void main() {
  group('normalizarBusqueda', () {
    test('quita tildes y mayúsculas y colapsa espacios', () {
      expect(normalizarBusqueda('  Notas de REMISIÓN   Nº 68 '), 'notas de remision nº 68');
    });
  });

  group('anioDeGestion: mismos casos que la prueba de dbo.f_tarc_anio', () {
    final casos = <String?, (int?, int?)>{
      '2015': (2015, 2015),
      '2003 - 2004 - 2005': (2003, 2005),
      '2011, 2012 y 2013': (2011, 2013),
      '2021 - 22': (2021, 2021),
      '2011 - 2012 - 2013 - 2014 - 2015 - 2017 - 2018 - 2019': (2011, 2019),
      'Nro 12015 de 2019': (2019, 2019),
      'sin anio': (null, null),
      '': (null, null),
      null: (null, null),
      '1899 y 2101': (null, null),
      '2100': (2100, 2100),
    };
    casos.forEach((texto, esperado) {
      test('«$texto» → ${esperado.$1}-${esperado.$2}', () {
        expect(anioDeGestion(texto), esperado.$1);
        expect(anioDeGestion(texto, mayor: true), esperado.$2);
      });
    });
  });

  group('FiltroArchivo.aplicar', () {
    final repo = RepositorioArchivoFalso();
    List<CajaArchivoEntity> cajasDe(List<ResultadoCaja> r) => [for (final x in r) x.caja];
    List<int> lineasDe(ResultadoCaja r) => [for (final l in r.coincidencias) l.codContenido];

    test('sin filtro devuelve todas las cajas ordenadas por archivo y número', () {
      final r = const FiltroArchivo().aplicar(repo.cajas, repo.contenido);
      expect([for (final c in cajasDe(r)) '${c.nombreArchivo} ${c.numero}'],
          ['ACHOCALLA 1', 'ACHOCALLA 2', 'OFICINA CENTRAL 1']);
      expect(r.every((x) => !x.filtrada), isTrue);
    });

    test('el texto no distingue tildes: «remision» encuentra «remisión»', () {
      final r = const FiltroArchivo(texto: 'remision').aplicar(repo.cajas, repo.contenido);
      expect(r.single.caja.codCaja, 1);
      expect(lineasDe(r.single), [1]);
    });

    test('todas las palabras tienen que aparecer en la misma línea', () {
      final r = const FiltroArchivo(texto: 'facturas 2016').aplicar(repo.cajas, repo.contenido);
      expect(r.single.caja.codCaja, 2);
      expect(lineasDe(r.single), [2]);
    });

    test('el nombre del archivo cuenta como parte de cada línea', () {
      final r = const FiltroArchivo(texto: 'achocalla facturas').aplicar(repo.cajas, repo.contenido);
      expect(lineasDe(r.single), [2, 3]);
    });

    test('el año encuentra las gestiones que lo cubren, también los rangos', () {
      final r = const FiltroArchivo(anio: 2016).aplicar(repo.cajas, repo.contenido);
      expect(r.single.caja.codCaja, 2);
      expect(lineasDe(r.single), [2, 3]);
    });

    test('«Sin empresa» trae solo las líneas sin empresa (los OTROS del Excel)', () {
      final r = const FiltroArchivo(codEmpresa: sinEmpresa).aplicar(repo.cajas, repo.contenido);
      expect([for (final x in r) ...lineasDe(x)], [1, 3, 4, 5]);
    });

    test('el número de caja se repite entre archivos: el filtro trae las dos', () {
      final r = const FiltroArchivo(numeroCaja: 1).aplicar(repo.cajas, repo.contenido);
      expect([for (final c in cajasDe(r)) c.codCaja], [1, 3]);
    });

    test('archivo y número juntos señalan una sola caja', () {
      final r = const FiltroArchivo(codArchivo: 2, numeroCaja: 1).aplicar(repo.cajas, repo.contenido);
      expect(r.single.caja.codCaja, 3);
    });

    test('cuenta los criterios para el panel plegado del teléfono', () {
      const f = FiltroArchivo(texto: 'x', codArchivo: 1, anio: 2016);
      expect(f.criterios, 2);
      expect(f.hayAlgo, isTrue);
      expect(const FiltroArchivo().hayAlgo, isFalse);
      expect(f.copyWith(limpiarAnio: true).criterios, 1);
    });
  });

  group('ArchivoDocumentalNotifier', () {
    ProviderContainer contenedor(RepositorioArchivoFalso repo) {
      final c = ProviderContainer(
        overrides: [archivoDocumentalRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(c.dispose);
      // autoDispose: sin alguien que escuche se liberaría a mitad de la prueba.
      c.listen(archivoDocumentalProvider, (_, __) {});
      return c;
    }

    test('carga las cinco listas en una sola lectura', () async {
      final c = contenedor(RepositorioArchivoFalso());
      await c.read(archivoDocumentalProvider.notifier).cargar();
      final s = c.read(archivoDocumentalProvider);
      expect(s.cargado, isTrue);
      expect([s.archivos.length, s.tipos.length, s.cajas.length, s.contenido.length, s.empresas.length],
          [2, 3, 3, 5, 2]);
      expect(s.lineasDe(2).length, 2);
    });

    test('si la lectura falla queda el error y no se marca como cargado', () async {
      final c = contenedor(RepositorioArchivoFalso(fallaLectura: true));
      await c.read(archivoDocumentalProvider.notifier).cargar();
      final s = c.read(archivoDocumentalProvider);
      expect(s.cargado, isFalse);
      expect(s.error, isNotNull);
    });

    test('una escritura rechazada lanza con el motivo del servidor', () async {
      final repo = RepositorioArchivoFalso()..rechazo = 'Ya existe la caja 1 en el archivo ACHOCALLA.';
      final c = contenedor(repo);
      await expectLater(
        c.read(archivoDocumentalProvider.notifier).guardarCaja(
              const CajaArchivoEntity(codCaja: 0, codArchivo: 1, numero: 1),
            ),
        throwsA(predicate((e) => e.toString().contains('Ya existe la caja 1'))),
      );
    });
  });

  // Las fotos se validan por sus bytes: en la web el nombre llega como
  // `scaled_<nombre>` y en el escritorio el selector no achica la imagen.
  group('fotos antes de subir', () {
    Uint8List con(List<int> cabecera, {int largo = 64}) =>
        Uint8List.fromList([...cabecera, ...List.filled(largo - cabecera.length, 0)]);

    test('reconoce JPG, PNG y WEBP por su cabecera, no por el nombre', () {
      expect(tipoDeImagen(con([0xFF, 0xD8, 0xFF, 0xE0])), TipoImagen.jpeg);
      expect(tipoDeImagen(pngDePrueba), TipoImagen.png);
      expect(
        tipoDeImagen(con([0x52, 0x49, 0x46, 0x46, 1, 2, 3, 4, 0x57, 0x45, 0x42, 0x50])),
        TipoImagen.webp,
      );
    });

    test('rechaza GIF, HEIC y archivos vacíos con un motivo que se entiende', () {
      expect(motivoFotoInvalida(con([0x47, 0x49, 0x46, 0x38])), contains('ni un PDF'));
      expect(
        motivoFotoInvalida(con([0, 0, 0, 0x18, 0x66, 0x74, 0x79, 0x70, 0x68, 0x65, 0x69, 0x63])),
        contains('no es una foto JPG, PNG o WEBP'),
      );
      expect(motivoFotoInvalida(Uint8List(0)), contains('vacío'));
      expect(motivoFotoInvalida(pngDePrueba), isNull);
    });

    test('un PDF se reconoce por «%PDF-» y se acepta', () {
      final pdf = con('%PDF-1.4'.codeUnits);
      expect(esPdf(pdf), isTrue);
      expect(esPdf(con('%PD'.codeUnits)), isFalse);
      expect(tipoDeImagen(pdf), isNull, reason: 'un PDF no es una imagen');
      expect(motivoFotoInvalida(pdf), isNull);
    });

    test('más de 10 MB no se sube: lo dice con el peso y si es foto o PDF', () {
      final grande = con([0xFF, 0xD8, 0xFF], largo: maximoBytesFoto + 1);
      expect(motivoFotoInvalida(grande), allOf(contains('La foto pesa 10,0 MB'), contains('máximo es 10 MB')));
      expect(motivoFotoInvalida(con([0xFF, 0xD8, 0xFF], largo: maximoBytesFoto)), isNull);
      expect(motivoFotoInvalida(con('%PDF-1.7'.codeUnits, largo: maximoBytesFoto + 1)), startsWith('El PDF pesa'));
    });
  });

  group('situación de las líneas', () {
    test('una línea prestada se encuentra buscando a quién se le prestó', () {
      const prestada = ContenidoCajaEntity(
        codContenido: 9,
        codCaja: 2,
        codTipoDocumento: 10,
        detalle: 'Facturas de compra',
        situacion: ContenidoCajaEntity.prestada,
        prestadoA: 'LLANQUE VICTOR',
      );
      const enCaja = ContenidoCajaEntity(codContenido: 10, codCaja: 2, codTipoDocumento: 10, detalle: 'Facturas de venta');
      expect(FiltroArchivo.textoDeLinea(prestada), contains('llanque victor'));
      expect(FiltroArchivo.textoDeLinea(enCaja), isNot(contains('llanque')));
      expect(prestada.estaPrestada && !prestada.estaEnLaCaja, isTrue);
      expect(enCaja.estaEnLaCaja, isTrue, reason: 'sin situación del servidor, la línea está en la caja');
    });

    test('prestar desde la caja es una entrega de esa caja: sin líneas, la caja completa', () {
      const completa = PedidoMovimientoCaja(codCaja: 7, codEmpleado: 240, observacion: 'Auditoría');
      expect(completa.cajaCompleta, isTrue);
      expect(completa.aEntrega().toJson(), {
        'codEmpleado': 240,
        'cajas': [7],
        'lineas': <int>[],
        'observacion': 'Auditoría',
      });
      final sueltas = const PedidoMovimientoCaja(codCaja: 7, lineas: [3, 4], codEmpleado: 23).aEntrega();
      expect(sueltas.cajas, isEmpty, reason: 'con líneas no se lleva la caja entera');
      expect(sueltas.lineas, [3, 4]);
    });

    test('la destrucción no manda empleado', () {
      expect(const PedidoMovimientoCaja(codCaja: 7, codEmpleado: 240).toJson(), {
        'codCaja': 7,
        'lineas': <int>[],
        'observacion': null,
      });
    });

    test('las entregas abiertas son las que tienen algo afuera, y sus renglones van por caja', () {
      const s = ArchivoDocumentalState(
        entregas: [
          EntregaDocumentoEntity(codEntrega: 1, codEmpleado: 23, cajas: 1, documentos: 1, pendientes: 1),
          EntregaDocumentoEntity(codEntrega: 2, codEmpleado: 23, documentos: 1),
        ],
        prestamos: [
          PrestamoDocumentoEntity(codPrestamo: 5, codEntrega: 1, codCaja: 9, codContenido: 30, numeroCaja: 9, nombreArchivo: 'ACHOCALLA'),
          PrestamoDocumentoEntity(codPrestamo: 4, codEntrega: 1, codCaja: 3, numeroCaja: 3, nombreArchivo: 'ACHOCALLA'),
          PrestamoDocumentoEntity(codPrestamo: 6, codEntrega: 2, codCaja: 3, codContenido: 8, numeroCaja: 3),
        ],
      );
      expect([for (final e in s.entregasAbiertas) e.codEntrega], [1]);
      expect([for (final p in s.renglonesDe(1)) p.codPrestamo], [4, 5]);
    });

    test('una foto es PDF por la extensión que le puso el servidor', () {
      expect(const FotoCajaEntity(codFoto: 1, codCaja: 2, orden: 1, ruta: 'archivo-cajas/caja-2-x.PDF').esPdf, isTrue);
      expect(const FotoCajaEntity(codFoto: 1, codCaja: 2, orden: 1, ruta: 'archivo-cajas/caja-2-x.jpg').esPdf, isFalse);
    });
  });

  test('el pedido de reporte manda la clave del backend y la empresa 0 como sin empresa', () {
    final j = const PedidoReporteArchivo(reporte: ReporteArchivo.porTipo, codEmpresa: sinEmpresa).toJson();
    expect(j['reporte'], 'POR_TIPO');
    expect(j['codEmpresa'], 0);
    expect(j['codSucursal'], isNull);
  });
}
