/// El botón "Artículos SAP" de Registro Lote de Producción.
///
/// Lo que importa no es que llame al backend sino lo que pasa después: que la
/// orden ya elegida encuentre el artículo recién llegado, y que si sigue sin
/// aparecer se diga cuál, en vez de dar la sincronización por buena y callar.
library;

import 'package:bosque_flutter/core/state/lote_produccion_provider.dart';
import 'package:bosque_flutter/data/repositories/lote_produccion_impl.dart';
import 'package:bosque_flutter/domain/entities/empresa_entity.dart';
import 'package:bosque_flutter/domain/entities/lote_produccion_entity.dart';
import 'package:bosque_flutter/domain/entities/maquina_produccion_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/repositorio_lote_produccion.dart';

const _audUsuario = 33;
const _bobina = 'BBH0650871200FBP';
const _resma = 'PBB075065090ASZ';

LoteProduccionEntity _articulo(String cod) =>
    loteDePrueba(codArticulo: cod, datoArt: '$cod 500 HJS');

/// Una orden de fabricación que pide [_bobina] de ingreso y [_resma] de salida.
LoteProduccionEntity _orden() =>
    loteDePrueba()
      ..codArtEntrada = _bobina
      ..codArtSalida = _resma;

/// Catálogo que cambia al sincronizar: [antes] hasta correr la rama F,
/// [despues] desde entonces.
class _RepoSap implements LoteProduccionImpl {
  _RepoSap({required this.antes, required this.despues, this.falla});

  final List<LoteProduccionEntity> antes;
  final List<LoteProduccionEntity> despues;
  final String? falla;
  int sincronizaciones = 0;

  @override
  Future<List<LoteProduccionEntity>> obtenerArticulos() async => [
    ...(sincronizaciones == 0 ? antes : despues),
  ];

  @override
  Future<void> sincronizarArticulosSap() async {
    if (falla != null) throw Exception(falla);
    sincronizaciones++;
  }

  @override
  Future<List<MaquinaProduccionEntity>> obtenerMaquinas() async => const [];

  @override
  Future<List<EmpresaEntity>> obtenerEmpresas() async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late ProviderContainer contenedor;

  Future<LoteProduccionRegistroNotifier> abrir(_RepoSap repo) async {
    contenedor = ProviderContainer(
      overrides: [loteProduccionRepoProvider.overrideWithValue(repo)],
    );
    addTearDown(contenedor.dispose);
    final notifier = contenedor.read(
      loteProduccionRegistroProvider(_audUsuario).notifier,
    );
    // El constructor dispara la carga de catálogos sin devolver nada que
    // esperar: se deja correr antes de seguir.
    await Future<void>.delayed(Duration.zero);
    return notifier;
  }

  LoteProduccionRegistroState estado() =>
      contenedor.read(loteProduccionRegistroProvider(_audUsuario));

  test(
    'trae el artículo que faltaba y se lo pone a la orden ya elegida',
    () async {
      final notifier = await abrir(
        _RepoSap(
          antes: [_articulo(_bobina)],
          despues: [_articulo(_bobina), _articulo(_resma)],
        ),
      );
      notifier.onDocNumChange(_orden());
      expect(estado().salidaArticuloErrorCodigo, _resma);
      expect(estado().articuloSalida, isNull);

      final r = await notifier.sincronizarArticulosSap();

      expect(r.ok, isTrue);
      expect(r.pendientes, isEmpty);
      expect(r.mensaje, contains('Se agregó 1 artículo nuevo'));
      expect(estado().articuloSalida?.codArticulo, _resma);
      expect(estado().salidaArticuloErrorCodigo, isNull);
      expect(estado().isTableSalidaEnabled, isTrue);
      expect(
        estado().lstSalida.map((s) => s.codArticulo),
        everyElement(_resma),
      );
      expect(estado().isSincronizandoArticulos, isFalse);
    },
  );

  test('si SAP no lo trae, dice cuál sigue faltando', () async {
    final notifier = await abrir(
      _RepoSap(antes: [_articulo(_bobina)], despues: [_articulo(_bobina)]),
    );
    notifier.onDocNumChange(_orden());

    final r = await notifier.sincronizarArticulosSap();

    expect(r.ok, isTrue);
    expect(r.pendientes, [_resma]);
    expect(r.mensaje, contains('No había artículos nuevos'));
    expect(r.mensaje, contains(_resma));
    expect(estado().salidaArticuloErrorCodigo, _resma);
  });

  test('un error del backend se muestra tal cual y libera el botón', () async {
    const motivo =
        "No tiene habilitada la pantalla 'tprod_loteProduccion/loteProduccion'.";
    final notifier = await abrir(
      _RepoSap(antes: [_articulo(_bobina)], despues: const [], falla: motivo),
    );

    final r = await notifier.sincronizarArticulosSap();

    expect(r.ok, isFalse);
    expect(r.mensaje, motivo);
    expect(estado().isSincronizandoArticulos, isFalse);
    expect(estado().lstArticulos, hasLength(1));
  });

  test(
    'un catálogo vacío después de sincronizar no borra el que había',
    () async {
      final notifier = await abrir(
        _RepoSap(antes: [_articulo(_bobina)], despues: const []),
      );

      await notifier.sincronizarArticulosSap();

      // obtenerArticulos devuelve [] ante cualquier error de red.
      expect(estado().lstArticulos.map((a) => a.codArticulo), [_bobina]);
    },
  );
}
