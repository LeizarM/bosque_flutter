import 'package:bosque_flutter/core/state/comisiones_provider.dart';
import 'package:flutter_test/flutter_test.dart';

/// Paridad de permisos entre Comisiones.xhtml (Bosque v2) y el módulo nuevo.
///
/// El ERP viejo decide con `Loggin.autorizarBtn()`: busca el botón en la lista
/// del usuario y autoriza si `nivelAcceso != 0`; si no lo encuentra, autoriza
/// igual cuando el usuario es `adm`. Los casos de abajo son los datos **reales**
/// de `tb_usuarioBtn` para la vista 82, leídos el 2026-08-23 de BOSQUE-2_0 y
/// BOSQUE2PRUEBA (idénticos en las dos).
///
/// El dato que hace falta entender antes de leerlos: de los 134 usuarios,
/// **los 134 tienen las 11 filas** de la vista 82 — pero casi todas en
/// `nivelAcceso = 0`. Contar filas da "todos pueden todo"; contar autorizados
/// da cuatro usuarios y ocho permisos en total. Es la diferencia entre existir
/// y estar autorizado, y es la que este archivo fija.
void main() {
  /// Un usuario con exactamente estos botones autorizados.
  bool Function(String) con(Set<String> botones) => botones.contains;

  /// El `adm` del ERP viejo: pasa aunque el ACL no lo mencione.
  bool admin(String _) => true;

  /// Lo que ve, en títulos, para poder comparar de un vistazo.
  List<String> ve(bool Function(String) tiene) =>
      superficiesComision(tiene).pestanias.map((p) => p.titulo).toList();

  List<String> modalidades(bool Function(String) tiene) =>
      superficiesComision(tiene).modalidades.map((m) => m.etiqueta).toList();

  group('los cuatro usuarios que hoy tienen algo autorizado', () {
    // aaguilar: tabPreliminarExt + tabPreliminarComDinamicaNew.
    // En el XHTML veía dos pestañas de preliminar y ninguna más. Acá las dos
    // son modalidades de una sola pestaña: una pestaña, dos modalidades.
    test('aaguilar ve solo preliminar, con sus dos modalidades', () {
      final tiene = con({'tabPreliminarExt', 'tabPreliminarComDinamicaNew'});

      expect(ve(tiene), ['Preliminar']);
      expect(modalidades(tiene), ['Externos', 'Internos dinamica vigente']);
    });

    // naneiva: TabEjecutar y nada más. Es el único usuario no-adm que puede
    // ejecutar el pago del período.
    test('naneiva ve solo ejecutar', () {
      final tiene = con({'TabEjecutar'});

      expect(ve(tiene), ['Ejecutar']);
      expect(
        modalidades(tiene),
        isEmpty,
        reason:
            'TabEjecutar no habilita ninguna modalidad del preliminar. En el '
            'XHTML eran tabs hermanos, no anidados.',
      );
    });

    test('pvillafuerte ve preliminar internos y externos', () {
      final tiene = con({'tabPreliminar', 'tabPreliminarExt'});

      expect(ve(tiene), ['Preliminar']);
      expect(modalidades(tiene), ['Internos', 'Externos']);
    });

    test('vfernandez tendría tres modalidades — pero no abre la vista 82', () {
      final tiene = con({
        'tabPreliminar',
        'tabPreliminarComDinamica',
        'tabPreliminarExt',
      });

      expect(ve(tiene), ['Preliminar']);
      expect(modalidades(tiene), [
        'Internos',
        'Externos',
        'Internos dinamica anterior',
      ]);

      // El segundo candado: tb_vistaUsuario.nivelAcceso = 0 para la vista 82,
      // así que el menú nunca le ofrece Comisiones y estos tres botones no
      // llegan a usarse. Igual que en el ERP viejo. No es un caso a arreglar:
      // es la razón por la que "tiene 3 botones" no significa "ve 3 cosas".
    });
  });

  group('el resto del padrón', () {
    // 130 de los 134 usuarios están así: las 11 filas existen, todas en cero.
    test('las filas en nivelAcceso 0 no muestran nada', () {
      final tiene = con(const {});

      expect(
        superficiesComision(tiene).vacio,
        isTrue,
        reason:
            'Un usuario sin botones autorizados no puede ver ninguna pestaña. '
            'Si esto falla, alguna pestaña quedó sin gate y la ve todo el '
            'padrón.',
      );
    });

    test('el admin ve las ocho, como en el ERP viejo', () {
      expect(ve(admin), [
        'Vendedores',
        'Grupos',
        'Asignaciones',
        'Escala por dias',
        'Politica',
        'Preliminar',
        'Ejecutar',
        'Pendientes',
      ]);
      expect(superficiesComision(admin).modalidades, hasLength(4));
    });
  });

  group('el mapeo con Comisiones.xhtml', () {
    // Cada `esAutorizado(...)` del XHTML tiene que seguir abriendo lo mismo.
    // Si alguien renombra un permiso, acá se cae.
    const delLegacy = {'TabEjecutar': 'Ejecutar', 'btnGrpVen': 'Asignaciones'};

    for (final entrada in delLegacy.entries) {
      test('${entrada.key} abre ${entrada.value}', () {
        expect(ve(con({entrada.key})), [entrada.value]);
      });
    }

    // Los cuatro preliminares del XHTML son cuatro tabs de primer nivel; acá
    // son modalidades. Lo que se conserva es cuál abre cuál.
    const preliminares = {
      'tabPreliminar': 'Internos',
      'tabPreliminarExt': 'Externos',
      'tabPreliminarComDinamica': 'Internos dinamica anterior',
      'tabPreliminarComDinamicaNew': 'Internos dinamica vigente',
    };

    for (final entrada in preliminares.entries) {
      test('${entrada.key} abre la modalidad ${entrada.value}', () {
        final tiene = con({entrada.key});
        expect(ve(tiene), ['Preliminar']);
        expect(modalidades(tiene), [entrada.value]);
      });
    }

    // btnGrpVen abría dlgGrpVen, y ese diálogo traía TAMBIÉN el alta de
    // vendedores y la de grupos. Acá se partió en tres permisos: quien otorgue
    // btnGrpVen esperando lo de antes recibe un tercio. Queda fijado para que
    // sea una decisión y no una sorpresa.
    test('btnGrpVen solo no administra vendedores ni grupos', () {
      expect(
        ve(con({'btnGrpVen'})),
        isNot(contains('Vendedores')),
        reason:
            'btnGrpVen volvió a arrastrar el alta de vendedores. Si es a '
            'propósito, hay que decirlo acá y en superficiesComision().',
      );
      expect(ve(con({'btnGrpVen'})), isNot(contains('Grupos')));
      expect(ve(con({'btnGrpVen', 'btnComVendedores', 'btnComGrupos'})), [
        'Vendedores',
        'Grupos',
        'Asignaciones',
      ]);
    });
  });

  group('superficie que el XHTML no tenía', () {
    // Escala por días, Política y Pendientes son pantallas nuevas. No hay nada
    // que replicar, pero sí que exigir: que ninguna se dibuje sin permiso.
    const nuevas = {
      'btnComRangos': 'Escala por dias',
      'btnComPolitica': 'Politica',
      'btnComPendientes': 'Pendientes',
      'btnComVendedores': 'Vendedores',
      'btnComGrupos': 'Grupos',
    };

    for (final entrada in nuevas.entries) {
      test('${entrada.value} necesita ${entrada.key}', () {
        expect(ve(con({entrada.key})), [entrada.value]);
      });
    }
  });

  group('los reportes que viven dentro de una pestaña', () {
    // En Comisiones.xhtml los tres reportes de lo pagado —internas, externas e
    // IMPORTACIÓN— colgaban de la pestaña EJECUTAR COMISIONES, detrás de
    // `TabEjecutar`. En la app nueva viven en la pestaña Ejecutar por la misma
    // razón, y sin candado propio: el XHTML tampoco se lo ponía a un botón
    // dentro de un panel ya protegido.
    //
    // Este caso existe porque el requisito se dijo con nombre y apellido:
    // aaguilar NO debe ver el reporte de importación. La única forma de que lo
    // viera sería que apareciera una pestaña suya que monte la barra completa.
    test(
      'aaguilar no llega a la pestaña que tiene el reporte de importación',
      () {
        final aaguilar = con({
          'tabPreliminarExt',
          'tabPreliminarComDinamicaNew',
        });

        expect(
          ve(aaguilar),
          isNot(contains('Ejecutar')),
          reason:
              'aaguilar entró a Ejecutar. Ahí vive «Comisiones pagadas por '
              'importación», que en el ERP viejo nunca vio: no tiene TabEjecutar.',
        );
        expect(ve(aaguilar), ['Preliminar']);
      },
    );

    // El contraste: quien SÍ lo tenía en el ERP viejo lo sigue teniendo.
    test('naneiva sí, porque tiene TabEjecutar', () {
      expect(ve(con({'TabEjecutar'})), ['Ejecutar']);
    });
  });

  // btnComDinamica está en tb_vistaBtn (codBtn 297, "ABM de porcentajes de
  // comisión dinámica") y lo tienen las 134 filas, todas en cero. Ninguna
  // pestaña lo consulta, y DialogoComisionDinamica —que es esa ABM— no se
  // construye en ningún lado. No es un agujero: es un permiso sin pantalla.
  // Si algún día se cablea, este test tiene que empezar a fallar.
  test('btnComDinamica no abre nada (todavía)', () {
    expect(
      superficiesComision(con({'btnComDinamica'})).vacio,
      isTrue,
      reason:
          'btnComDinamica empezó a abrir una pestaña. Revisar que el permiso '
          'esté otorgado a quien corresponda: hoy lo tienen los 134 usuarios '
          'en nivelAcceso 0, o sea nadie.',
    );
  });
}
