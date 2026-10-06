import 'package:flutter/material.dart' show Icons;
import 'package:flutter_test/flutter_test.dart';

import 'package:bosque_flutter/domain/entities/cheque_registro_entity.dart';
import 'package:bosque_flutter/domain/utils/modo_edicion_cheque.dart';
import 'package:bosque_flutter/domain/utils/permisos_cheque.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/lista_cheques.dart';

import 'fakes/repositorio_cheques.dart';

/// El lapiz unico de la fila: con que formulario se edita un cheque
/// (`modoDeEdicionCheque`) y que acciones muestra cada fila (`accionesDeFila`).
/// Logica pura: el servidor sigue decidiendo por el modo del cuerpo y por el
/// boton de la vista 42.
void main() {
  PermisosCheque usuario(Iterable<String> botones) =>
      PermisosCheque(botones: botones.toSet(), esAdmin: false);
  const admin = PermisosCheque(botones: <String>{}, esAdmin: true);

  // Fecha del cheque fija; el cobro se mide contra ella.
  final fechaCheque = DateTime(2026, 8, 10);
  DateTime cobro(int dias) => DateTime(2026, 8, 10 + dias);

  ModoEdicionCheque? modo(
    PermisosCheque p,
    String? estado, {
    DateTime? cheque,
    DateTime? cobrar,
    bool sinFechas = false,
  }) => modoDeEdicionCheque(
    p,
    estado: estado,
    fechaCheque: sinFechas ? null : (cheque ?? fechaCheque),
    fechaCobrar: sinFechas ? null : (cobrar ?? cobro(5)),
  );

  const soloAdmin = ModoEdicionCheque(ModoRegistroCheque.admin);
  const soloEstandar = ModoEdicionCheque(ModoRegistroCheque.estandar);
  const soloTalonario = ModoEdicionCheque(ModoRegistroCheque.talonario);
  const talonarioConAviso = ModoEdicionCheque(
    ModoRegistroCheque.talonario,
    avisoCobroFueraDeRango: true,
  );

  group('modoDeEdicionCheque: el administrador', () {
    test('cheque abierto: modo administrador', () {
      expect(modo(admin, 'PEN'), soloAdmin);
    });

    test('cheque cerrado con el cobro dentro de rango: modo administrador', () {
      expect(modo(admin, 'CER', cobrar: cobro(5)), soloAdmin);
      expect(modo(admin, 'CER', cobrar: cobro(0)), soloAdmin);
      expect(modo(admin, 'CER', cobrar: cobro(-20)), soloAdmin);
    });

    test('cheque cerrado con el cobro fuera de rango: talonario con aviso', () {
      expect(modo(admin, 'CER', cobrar: cobro(60)), talonarioConAviso);
      expect(modo(admin, 'CER', cobrar: cobro(-60)), talonarioConAviso);
    });

    test('la frontera esta en 28 dias, a un lado y al otro', () {
      // Dentro: exactamente 28 dias despues y 28 dias antes.
      expect(modo(admin, 'CER', cobrar: cobro(28)), soloAdmin);
      expect(modo(admin, 'CER', cobrar: cobro(-28)), soloAdmin);
      // Fuera: 29.
      expect(modo(admin, 'CER', cobrar: cobro(29)), talonarioConAviso);
      expect(modo(admin, 'CER', cobrar: cobro(-29)), talonarioConAviso);
    });

    test('la frontera compara dias, no horas', () {
      final cheque = DateTime(2026, 8, 10, 23, 59);
      expect(
        modo(
          admin,
          'CER',
          cheque: cheque,
          cobrar: DateTime(2026, 9, 7, 0, 1),
        ),
        soloAdmin,
      );
      expect(
        modo(
          admin,
          'CER',
          cheque: cheque,
          cobrar: DateTime(2026, 9, 8, 0, 1),
        ),
        talonarioConAviso,
      );
    });

    test('la excepcion es solo del cheque cerrado: abierto, el rango no importa', () {
      expect(modo(admin, 'PEN', cobrar: cobro(90)), soloAdmin);
      expect(modo(admin, 'PEN', cobrar: cobro(-90)), soloAdmin);
      // Sin estado se trata como abierto, como en PermisosCheque.
      expect(modo(admin, null, cobrar: cobro(90)), soloAdmin);
      expect(modo(admin, '', cobrar: cobro(90)), soloAdmin);
    });

    test('«CER» con espacios cuenta como cerrado', () {
      expect(modo(admin, ' CER ', cobrar: cobro(60)), talonarioConAviso);
    });

    test('si falta una fecha no hay rango que comprobar: modo administrador', () {
      expect(modo(admin, 'CER', sinFechas: true), soloAdmin);
      expect(
        modoDeEdicionCheque(
          admin,
          estado: 'CER',
          fechaCheque: fechaCheque,
          fechaCobrar: null,
        ),
        soloAdmin,
      );
      expect(
        modoDeEdicionCheque(
          admin,
          estado: 'CER',
          fechaCheque: null,
          fechaCobrar: cobro(60),
        ),
        soloAdmin,
      );
    });
  });

  group('modoDeEdicionCheque: btnEditar3CH (sin ser administrador)', () {
    final u = usuario(['btnEditar3CH']);

    test('cheque abierto: modo administrador', () {
      expect(modo(u, 'PEN'), soloAdmin);
      // La excepcion del rango no aplica a un cheque abierto.
      expect(modo(u, 'PEN', cobrar: cobro(90)), soloAdmin);
    });

    test('cheque cerrado: no puede editar como administrador, ni de otro modo', () {
      expect(modo(u, 'CER'), isNull);
      expect(modo(u, 'CER', cobrar: cobro(90)), isNull);
    });

    test('con btnEditar1CH ademas, el cheque cerrado se edita como talonario', () {
      final dos = usuario(['btnEditar3CH', 'btnEditar1CH']);
      expect(modo(dos, 'PEN'), soloAdmin);
      expect(modo(dos, 'CER'), soloTalonario);
      // Sin aviso: el aviso es de quien pidio el modo administrador.
      expect(modo(dos, 'CER', cobrar: cobro(90)), soloTalonario);
    });
  });

  group('modoDeEdicionCheque: btnEditar1CH', () {
    final u = usuario(['btnEditar1CH']);

    test('cheque abierto: modo estandar', () {
      expect(modo(u, 'PEN'), soloEstandar);
      expect(modo(u, null), soloEstandar);
      expect(modo(u, 'PEN', cobrar: cobro(90)), soloEstandar);
    });

    test('cheque cerrado: modo talonario, sin aviso, este o no en rango', () {
      expect(modo(u, 'CER'), soloTalonario);
      expect(modo(u, 'CER', cobrar: cobro(90)), soloTalonario);
    });
  });

  group('modoDeEdicionCheque: sin permiso de edicion', () {
    test('sin ningun boton no hay modo', () {
      final nadie = usuario(const []);
      expect(modo(nadie, 'PEN'), isNull);
      expect(modo(nadie, 'CER'), isNull);
      expect(modo(PermisosCheque.ninguno, 'PEN'), isNull);
    });

    test('otros botones no sirven para editar', () {
      final otros = usuario([
        'btnNuevoCH',
        'btnNuevo2CH',
        'btnEditar2CH',
        'btnDetalleCH',
        'btnTraspasoCH',
      ]);
      expect(modo(otros, 'PEN'), isNull);
      expect(modo(otros, 'CER'), isNull);
    });
  });

  group('modoDeEdicionCheque: la respuesta coincide con los permisos', () {
    // Para toda combinacion de botones y estados: hay modo exactamente cuando
    // PermisosCheque deja editar de alguna forma, y el modo respeta cada regla.
    const botones = ['btnEditar1CH', 'btnEditar3CH', 'btnEditar2CH'];
    const estados = <String?>['PEN', 'CER', null, '', ' CER ', 'XYZ'];

    for (final esAdmin in [false, true]) {
      for (var mascara = 0; mascara < 8; mascara++) {
        final conjunto = {
          for (var i = 0; i < botones.length; i++)
            if (mascara & (1 << i) != 0) botones[i],
        };
        test('esAdmin=$esAdmin botones=$conjunto', () {
          final p = PermisosCheque(botones: conjunto, esAdmin: esAdmin);
          for (final e in estados) {
            final m = modo(p, e, cobrar: cobro(60));
            final puede =
                p.puedeEditarComoAdmin(e) ||
                p.puedeEditar(e) ||
                p.puedeEditarTalonario(e);
            expect(m != null, puede, reason: 'estado $e');
            if (m == null) continue;
            // El aviso solo acompana al talonario del administrador.
            if (m.avisoCobroFueraDeRango) {
              expect(m.modo, ModoRegistroCheque.talonario);
              expect(p.puedeEditarComoAdmin(e), isTrue);
              expect(PermisosCheque.estaCerrado(e), isTrue);
            }
            // El modo administrador nunca se abre sin el permiso de la variante.
            if (m.modo == ModoRegistroCheque.admin) {
              expect(p.puedeEditarComoAdmin(e), isTrue, reason: 'estado $e');
            }
          }
        });
      }
    }
  });

  group('ModoEdicionCheque', () {
    test('igualdad por valor', () {
      expect(soloAdmin, const ModoEdicionCheque(ModoRegistroCheque.admin));
      expect(soloAdmin, isNot(soloTalonario));
      expect(soloTalonario, isNot(talonarioConAviso));
      expect(talonarioConAviso.hashCode, talonarioConAviso.hashCode);
      expect(talonarioConAviso.toString(), contains('TALONARIO'));
    });
  });

  // ── accionesDeFila: un solo lapiz ──────────────────────────────────────────

  group('accionesDeFila', () {
    // Las que dependen de permisos: «Documento PDF» no (esta siempre) y se prueba
    // aparte, al final del grupo.
    List<AccionFilaCheque> acciones(PermisosCheque p, String estado) => [
      for (final a in accionesDeFila(p, chequeFalso(1, estado: estado)))
        if (a != AccionFilaCheque.documentoPdf) a,
    ];

    test('la constante editarAdmin ya no existe', () {
      expect(AccionFilaCheque.values.map((a) => a.name), isNot(contains('editarAdmin')));
      for (final a in AccionFilaCheque.values) {
        expect(a.etiqueta, isNot(contains('administrador')), reason: a.name);
      }
      // Editar, editar talonario, fecha de cobro, completar y el documento PDF.
      expect(AccionFilaCheque.values, hasLength(5));
    });

    test('el lapiz se llama «Editar»', () {
      expect(AccionFilaCheque.editar.etiqueta, 'Editar');
      expect(AccionFilaCheque.editarTalonario.etiqueta, 'Editar talonario');
    });

    for (final estado in ['PEN', 'CER']) {
      test('administrador, cheque $estado: un lapiz, fecha de cobro y completar', () {
        expect(acciones(admin, estado), [
          AccionFilaCheque.editar,
          AccionFilaCheque.fechaCobro,
          AccionFilaCheque.completar,
        ]);
      });
    }

    test('administrador: nunca editar talonario aparte', () {
      for (final e in ['PEN', 'CER']) {
        expect(acciones(admin, e), isNot(contains(AccionFilaCheque.editarTalonario)));
      }
    });

    test('btnEditar3CH con el cheque abierto: un solo lapiz y la fecha de cobro', () {
      expect(acciones(usuario(['btnEditar3CH']), 'PEN'), [
        AccionFilaCheque.editar,
        AccionFilaCheque.fechaCobro,
      ]);
    });

    test('btnEditar3CH con el cheque cerrado: ninguna de las dos', () {
      expect(acciones(usuario(['btnEditar3CH']), 'CER'), isEmpty);
    });

    test('btnEditar1CH y btnEditar3CH: el abierto tiene un lapiz, el cerrado talonario', () {
      final u = usuario(['btnEditar1CH', 'btnEditar3CH']);
      expect(acciones(u, 'PEN'), [
        AccionFilaCheque.editar,
        AccionFilaCheque.fechaCobro,
      ]);
      expect(acciones(u, 'CER'), [AccionFilaCheque.editarTalonario]);
    });

    test('solo btnEditar1CH con el cheque cerrado: editar talonario', () {
      expect(acciones(usuario(['btnEditar1CH']), 'CER'), [
        AccionFilaCheque.editarTalonario,
      ]);
    });

    test('solo btnEditar1CH con el cheque abierto: editar', () {
      expect(acciones(usuario(['btnEditar1CH']), 'PEN'), [
        AccionFilaCheque.editar,
      ]);
    });

    test('cajero completo: editar, fecha de cobro y completar', () {
      final cajero = usuario([
        'btnEditar1CH',
        'btnEditar2CH',
        'btnDetalleCH',
      ]);
      expect(acciones(cajero, 'PEN'), [
        AccionFilaCheque.editar,
        AccionFilaCheque.fechaCobro,
        AccionFilaCheque.completar,
      ]);
      expect(acciones(cajero, 'CER'), [
        AccionFilaCheque.editarTalonario,
        AccionFilaCheque.completar,
      ]);
    });

    test('sin permisos no hay acciones que dependan de ellos', () {
      expect(acciones(PermisosCheque.ninguno, 'PEN'), isEmpty);
      expect(acciones(PermisosCheque.ninguno, 'CER'), isEmpty);
    });

    test('«Documento PDF» esta siempre, una sola vez y al final, sin permiso', () {
      expect(AccionFilaCheque.documentoPdf.etiqueta, 'Documento PDF');
      expect(AccionFilaCheque.documentoPdf.icono, Icons.picture_as_pdf_outlined);
      final casos = [
        PermisosCheque.ninguno,
        admin,
        usuario(['btnEditar1CH']),
        usuario(['btnEditar1CH', 'btnEditar2CH', 'btnDetalleCH']),
      ];
      for (final p in casos) {
        for (final e in ['PEN', 'CER']) {
          final todas = accionesDeFila(p, chequeFalso(1, estado: e));
          expect(todas.last, AccionFilaCheque.documentoPdf, reason: e);
          expect(
            todas.where((a) => a == AccionFilaCheque.documentoPdf),
            hasLength(1),
          );
        }
      }
      // Un usuario sin ningun boton ve solo ese icono.
      expect(
        accionesDeFila(PermisosCheque.ninguno, chequeFalso(1)),
        [AccionFilaCheque.documentoPdf],
      );
    });

    test('ninguna fila tiene a la vez editar y editar talonario', () {
      const botones = [
        'btnEditar1CH',
        'btnEditar2CH',
        'btnEditar3CH',
        'btnDetalleCH',
      ];
      for (final esAdmin in [false, true]) {
        for (var m = 0; m < 16; m++) {
          final p = PermisosCheque(
            botones: {
              for (var i = 0; i < botones.length; i++)
                if (m & (1 << i) != 0) botones[i],
            },
            esAdmin: esAdmin,
          );
          for (final e in ['PEN', 'CER']) {
            final a = acciones(p, e);
            expect(
              a.contains(AccionFilaCheque.editar) &&
                  a.contains(AccionFilaCheque.editarTalonario),
              isFalse,
              reason: 'esAdmin=$esAdmin m=$m $e',
            );
            // Y la fila siempre tiene como mucho tres acciones.
            expect(a.length, lessThanOrEqualTo(3), reason: 'm=$m $e');
          }
        }
      }
    });
  });
}
