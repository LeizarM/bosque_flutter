import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosque_flutter/core/state/bancos_provider.dart';
import 'package:bosque_flutter/core/state/button_permissions_provider.dart';
import 'package:bosque_flutter/core/state/cheques_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/data/models/accion_cheque_model.dart';
import 'package:bosque_flutter/data/models/usuarioBtn_model.dart';
import 'package:bosque_flutter/domain/entities/accion_cheque_entity.dart';
import 'package:bosque_flutter/domain/entities/botones_cheque_entity.dart';
import 'package:bosque_flutter/domain/entities/cheque_detalle_entity.dart';
import 'package:bosque_flutter/domain/entities/cheque_registro_entity.dart';
import 'package:bosque_flutter/domain/entities/login_entity.dart';
import 'package:bosque_flutter/domain/entities/sucursal_cheque_entity.dart';
import 'package:bosque_flutter/domain/entities/usuarioBtn_entity.dart';
import 'package:bosque_flutter/domain/utils/modo_edicion_cheque.dart';
import 'package:bosque_flutter/domain/utils/permisos_banco.dart';
import 'package:bosque_flutter/domain/utils/permisos_cheque.dart';
import 'package:bosque_flutter/presentation/screens/bancos/bancos_screen.dart';
import 'package:bosque_flutter/presentation/screens/cheques/cheques_screen.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/detalle_cheque.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/lista_cheques.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/piezas_cheques.dart';

import 'fakes/arnes_bancos.dart';
import 'fakes/arnes_cheques.dart';
import 'fakes/repositorio_bancos.dart';
import 'fakes/repositorio_cheques.dart';

/// PARIDAD DE PERMISOS del modulo Cheques con el legacy (JSF) para quien **no es
/// administrador**. El documento con la tabla de verdad, la matriz y las
/// diferencias es `PERMISOS_CHEQUES.md` del espacio de migracion.
///
/// Tres capas:
/// 1. **La verdad del legacy**, transcrita de `WizardCheque.esAutorizado*` y de
///    `Loggin.autorizarBtn` (cada regla con su archivo y linea) en [VerdadLegacy].
/// 2. **Logica pura**: `PermisosCheque`, `accionesDeFila`, `modoDeEdicionCheque`
///    y `PermisosBanco` dan, para los 12 perfiles reales mas «sin botones» y
///    «administrador», lo que da la verdad del legacy. El cableado real
///    (`/view/vistaBtn` -> `buttonPermissionsProvider` -> `permisosChequeProvider`)
///    tambien.
/// 3. **La pantalla montada** (390 y 1280 px) con el repositorio falso: que
///    botones y acciones se ven y cuales no.
///
/// Los perfiles son los medidos en BOSQUE2PRUEBA y BOSQUE-2_0 el 2026-10-03
/// (`replicar_gate_cheques.ps1`), sin nombres de personas.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(cargarRoboto);
  // El cliente HTTP lee dotenv al armarse; solo lo arma el cableado de permisos.
  setUpAll(() => dotenv.testLoad(fileInput: ''));

  // ═══════════════════════════════════════════════════════════════════════════
  // 1. LA VERDAD DEL LEGACY
  // ═══════════════════════════════════════════════════════════════════════════

  /// Transcripcion de la logica de habilitado de `cheque.xhtml`. `adm` es
  /// `Loggin.tipoUsuario.equals("adm")`.
  final verdad = VerdadLegacy.nueva;

  // ═══════════════════════════════════════════════════════════════════════════
  // 2. LOGICA PURA
  // ═══════════════════════════════════════════════════════════════════════════

  group('la logica pura da lo que da el legacy', () {
    for (final p in perfilesReales) {
      group(p.id, () {
        final l = verdad(p);
        final f = p.permisos;

        test('barra superior: un permiso por boton (cheque.xhtml L99-L117)', () {
          expect(
            f.puedeVerRegistrar,
            l.registrar || l.registre,
            reason: 'Registrar (btnNuevoCH L99) o Registre (btnNuevo2CH L113)',
          );
          expect(
            f.modoDeRegistro,
            l.registre ? ModoRegistroCheque.admin : ModoRegistroCheque.estandar,
            reason: 'con btnNuevo2CH abre el formulario de administrador',
          );
          expect(f.puedeTraspasar, l.traspaso, reason: 'Traspaso L101');
          expect(f.puedeEntregarACustodia, l.aCustodio, reason: 'A Custodio L103');
          expect(f.puedeDarCustodia, l.darCustodia, reason: 'Dar Custodia L117');
          expect(f.puedeReporteRecibidos, l.rpt1, reason: 'Reporte L105');
          expect(f.puedeReporteCobranzas, l.rpt2, reason: 'Reporte Cheques L107');
          expect(f.puedeReporteCustodio, l.rpt3, reason: 'Reporte Custodio L109');
          expect(f.puedeReciboUltimoCheque, l.rpt4, reason: 'Recibo L111');
          expect(f.puedeReimprimirTraspaso, l.rpt5, reason: 'Imp Traspso L115');
          expect(
            f.puedeVerReportes,
            l.rpt1 || l.rpt2 || l.rpt3 || l.rpt4 || l.rpt5,
          );
          expect(f.puedeElegirSucursal, l.comboSucursal, reason: 'combo L87');
        });

        for (final estado in ['PEN', 'CER']) {
          test('acciones de la fila con el cheque $estado (L176-L206)', () {
            final fila = chequeFalso(1, estado: estado, descTipo: 'PAGO');
            final vistas =
                accionesDeFila(f, fila).map((a) => a.etiqueta).toSet();
            expect(vistas, l.accionesDeFila(estado));
          });

          test('formulario del lapiz con el cheque $estado', () {
            final edicion = modoDeEdicionCheque(
              f,
              estado: estado,
              fechaCheque: DateTime(2026, 8, 10),
              fechaCobrar: DateTime(2026, 8, 20),
            );
            expect(edicion?.modo, l.modoDelLapiz(estado));
            expect(edicion?.avisoCobroFueraDeRango ?? false, isFalse);
          });
        }

        test('detalle: sin permiso de boton para las 4 acciones; eliminar accion = btnEliminarSegCH', () {
          // Las cuatro las gobierna la rama K (disabled=verificarHabilitar, L386-L401): ningun ACL.
          expect(f.puedeCompletar, l.completar, reason: 'Completar L198');
          expect(
            f.puedeEliminarAccion,
            l.eliminarAccion,
            reason: 'Eliminar accion L427 (esAutorizadoB, sin estado)',
          );
          expect(
            f.puedeFechaCobroDesdeDetalle,
            l.estado('btnEditar2CH', 'PEN') ||
                l.estado('btnEditar3CH', 'PEN') ||
                l.completar,
            reason: 'el servidor acepta btnEditar2CH, btnEditar3CH o btnDetalleCH',
          );
          expect(f.fechaCobroSinLimite, l.sin('btnEditar3CH'));
        });

        test('bancos (vista 43): Nuevo, Editar y Eliminar, un boton cada uno', () {
          final b = p.permisosBanco;
          expect(b.puedeCrear, l.sin('btnNuevoB'), reason: 'banco.xhtml L23');
          expect(b.puedeEditar, l.sin('btnEditarB'), reason: 'banco.xhtml L33');
          expect(b.puedeEliminar, l.sin('btnEliminarB'), reason: 'banco.xhtml L36');
        });

        test('esAdmin es tipoUsuario ROLE_ADM (el "adm" de Loggin.validaUsuario)', () {
          expect(f.esAdmin, p.admin);
        });
      });
    }

    test('ningun no administrador puede editar como administrador ni dar custodia sin el boton', () {
      for (final p in perfilesReales.where((p) => !p.admin)) {
        final f = p.permisos;
        expect(f.puedeEditarComoAdmin('PEN'), p.v42.contains('btnEditar3CH'), reason: p.id);
        expect(f.puedeDarCustodia, p.v42.contains('btnCustodia2CH'), reason: p.id);
      }
    });

    test('administrador: todo, con el cheque abierto o cerrado, aunque no tenga filas en su ACL', () {
      final f = perfilesReales.firstWhere((p) => p.admin).permisos;
      for (final e in ['PEN', 'CER']) {
        expect(f.puedeEditar(e), isTrue);
        expect(f.puedeEditarTalonario(e), isTrue);
        expect(f.puedeCambiarFechaCobro(e), isTrue);
        expect(f.puedeEditarComoAdmin(e), isTrue);
      }
      expect(f.puedeTraspasar && f.puedeDarCustodia && f.puedeVerReportes, isTrue);
    });

    test('estado del cheque: solo "CER" exacto cierra (como equals("CER")); el resto cuenta como abierto', () {
      // En PRUEBA hay 9708 cheques CER y 11 PEN y ninguno con espacios ni nulo.
      final f = perfilesReales.firstWhere((p) => p.id == 'P12').permisos;
      expect(f.puedeEditar('PEN'), isTrue);
      expect(f.puedeEditar('CER'), isFalse);
      expect(f.puedeEditar('cer'), isTrue, reason: 'el legacy compara con equals: "cer" no es CER');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // LA MATRIZ DEL DOCUMENTO (solo se imprime con --dart-define=MATRIZ=true)
  // ═══════════════════════════════════════════════════════════════════════════

  test(
    'imprime la matriz legacy vs frontend (la que va en PERMISOS_CHEQUES.md)',
    () {
      final lineas = <String>[];
      final cols = perfilesReales.map((p) => p.id == 'SIN_BOTONES' ? 'SIN' : p.id == 'ADMIN' ? 'ADM' : p.id).toList();
      lineas.add('| Componente (legacy) | ${cols.join(' | ')} |');
      lineas.add('|---|${cols.map((_) => ':-:').join('|')}|');

      /// `✔` si legacy y frontend dan que si, `✘` si dan que no, `✔*` si el
      /// legacy da que si y el frontend lo junta con otro boton (administrador),
      /// `DIF` si discrepan.
      String celda(bool l, bool f, {bool fusion = false}) {
        if (l == f) return l ? '✔' : '✘';
        if (l && !f && fusion) return '✔*';
        return 'DIF';
      }

      void fila(String nombre, bool Function(PerfilReal) legacy, bool Function(PerfilReal) front, {bool Function(PerfilReal)? fusion}) {
        final celdas = [
          for (final p in perfilesReales)
            celda(legacy(p), front(p), fusion: fusion?.call(p) ?? false),
        ];
        lineas.add('| $nombre | ${celdas.join(' | ')} |');
      }

      bool tieneAccion(PerfilReal p, String estado, String etiqueta) => accionesDeFila(
        p.permisos,
        chequeFalso(1, estado: estado, descTipo: 'PAGO'),
      ).any((a) => a.etiqueta == etiqueta);

      fila('Registrar / Registre (btnNuevoCH o btnNuevo2CH) · L99, L113', (p) => verdad(p).registrar || verdad(p).registre, (p) => p.permisos.puedeVerRegistrar);
      fila('  abre el formulario de administrador (btnNuevo2CH) · L113', (p) => verdad(p).registre, (p) => p.permisos.modoDeRegistro == ModoRegistroCheque.admin);
      fila('Traspaso (btnTraspasoCH) · L101', (p) => verdad(p).traspaso, (p) => p.permisos.puedeTraspasar);
      fila('A Custodio (btnCustodiaCH) · L103', (p) => verdad(p).aCustodio, (p) => p.permisos.puedeEntregarACustodia);
      fila('Dar Custodia (btnCustodia2CH) · L117', (p) => verdad(p).darCustodia, (p) => p.permisos.puedeDarCustodia);
      fila('Reporte recibidos (btnRpt1CH) · L105', (p) => verdad(p).rpt1, (p) => p.permisos.puedeReporteRecibidos);
      fila('Reporte Cheques (btnRpt2CH) · L107', (p) => verdad(p).rpt2, (p) => p.permisos.puedeReporteCobranzas);
      fila('Reporte Custodio (btnRpt3CH) · L109', (p) => verdad(p).rpt3, (p) => p.permisos.puedeReporteCustodio);
      fila('Recibo del ultimo cheque (btnRpt4CH) · L111', (p) => verdad(p).rpt4, (p) => p.permisos.puedeReciboUltimoCheque);
      fila('Imp Traspso (btnRpt5CH) · L115', (p) => verdad(p).rpt5, (p) => p.permisos.puedeReimprimirTraspaso);
      fila('Combo de sucursal habilitado (btnChqSucrs) · L87', (p) => verdad(p).comboSucursal, (p) => p.permisos.puedeElegirSucursal);

      for (final e in ['PEN', 'CER']) {
        fila('Fila $e · Editar (btnEditar1CH o btnEditar3CH, abierto) · L176, L186', (p) => verdad(p).estado('btnEditar1CH', e) || verdad(p).estado('btnEditar3CH', e), (p) => tieneAccion(p, e, 'Editar'));
        fila('Fila $e · Editar talonario (btnEditar1CH, cerrado) · L179', (p) => verdad(p)._talCer('btnEditar1CH', e), (p) => tieneAccion(p, e, 'Editar talonario'), fusion: (p) => p.admin);
        fila('Fila $e · Fecha Cobro (btnEditar2CH o btnEditar3CH, abierto) · L182, L190', (p) => verdad(p).estado('btnEditar2CH', e) || verdad(p).estado('btnEditar3CH', e), (p) => tieneAccion(p, e, 'Fecha de cobro'));
        fila('Fila $e · Completar (btnDetalleCH) · L198', (p) => verdad(p).completar, (p) => tieneAccion(p, e, 'Completar'));
        fila('Fila $e · Documento PDF (sin boton) · L202, L206', (p) => true, (p) => tieneAccion(p, e, 'Documento PDF'));
      }
      fila('Detalle · Eliminar accion (btnEliminarSegCH) · L427', (p) => verdad(p).eliminarAccion, (p) => p.permisos.puedeEliminarAccion);
      fila('Detalle · Fecha de cobro/Devolver/Cerrar: solo rama K (sin boton) · L386-L401', (p) => verdad(p).completar, (p) => p.permisos.puedeCompletar);
      fila('Bancos · Nuevo (btnNuevoB) · banco.xhtml L23', (p) => verdad(p).sin('btnNuevoB'), (p) => p.permisosBanco.puedeCrear);
      fila('Bancos · Editar (btnEditarB) · L33', (p) => verdad(p).sin('btnEditarB'), (p) => p.permisosBanco.puedeEditar);
      fila('Bancos · Eliminar (btnEliminarB) · L36', (p) => verdad(p).sin('btnEliminarB'), (p) => p.permisosBanco.puedeEliminar);

      // ignore: avoid_print
      print('\n=== MATRIZ LEGACY vs FRONTEND ===\n${lineas.join('\n')}\n=== FIN MATRIZ ===');
      expect(lineas.where((l) => l.contains('DIF')), isEmpty);
    },
    skip:
        const bool.fromEnvironment('MATRIZ')
            ? false
            : 'solo imprime la matriz del documento: flutter test --dart-define=MATRIZ=true',
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // 2b. EL CABLEADO REAL: /view/vistaBtn -> buttonPermissionsProvider -> permisos
  // ═══════════════════════════════════════════════════════════════════════════

  group('el cableado real entrega a cada perfil sus permisos', () {
    for (final p in perfilesReales) {
      test('${p.id}: permisosChequeProvider y permisosBancoProvider', () {
        final c = ProviderContainer(
          overrides: [
            userProvider.overrideWith(
              (ref) => UserStateNotifier.sinStorage(
                LoginEntity.fromJson(<String, dynamic>{
                  'tipoUsuario': p.tipoUsuario,
                  'codUsuario': 7,
                }),
              ),
            ),
            buttonPermissionsProvider.overrideWith(
              (ref) => _BotonesFalsos(ref, AsyncValue.data(p.filasAcl)),
            ),
          ],
        );
        addTearDown(c.dispose);

        expect(c.read(permisosChequeProvider), p.permisos);
        expect(c.read(permisosBancoProvider), p.permisosBanco);
      });
    }

    test('la fila del servidor se lee tal cual la serializa Jackson (UsuarioBtn: 7 enteros y el nombre)', () {
      final m = UsuarioBtnModel.fromJson(const {
        'codUsuario': 0,
        'codBtn': 0,
        'nivelAcceso': 0,
        'audUsuario': 0,
        'boton': 'btnNuevoCH',
        'permiso': 1,
        'pertenVist': 42,
      });
      expect(m.toEntity().boton, 'btnNuevoCH');
      expect(m.toEntity().permiso, 1);
      expect(m.toEntity().pertenVist, 42);
    });

    test('permiso 2 cuenta y permiso 0 no: es "!= 0" de p_list_UsuarioBtn y de autorizarBtn', () {
      UsuarioBtnEntity fila(String b, int permiso) => UsuarioBtnEntity(
        codUsuario: 0,
        codBtn: 0,
        nivelAcceso: 0,
        audUsuario: 0,
        boton: b,
        permiso: permiso,
        pertenVist: 42,
      );
      final f = PermisosCheque.desde(
        tipoUsuario: 'ROLE_LIM',
        botones: [fila('btnNuevoCH', 2), fila('btnTraspasoCH', 0)],
      );
      expect(f.puedeRegistrar, isTrue);
      expect(f.puedeTraspasar, isFalse);
    });

    test('mientras llegan los botones, un usuario comun no tiene ninguno y el administrador si', () {
      ProviderContainer con(String tipo) {
        final c = ProviderContainer(
          overrides: [
            userProvider.overrideWith(
              (ref) => UserStateNotifier.sinStorage(
                LoginEntity.fromJson(<String, dynamic>{
                  'tipoUsuario': tipo,
                  'codUsuario': 7,
                }),
              ),
            ),
            buttonPermissionsProvider.overrideWith(
              (ref) => _BotonesFalsos(ref, const AsyncValue.loading()),
            ),
          ],
        );
        addTearDown(c.dispose);
        return c;
      }

      expect(con('ROLE_LIM').read(permisosChequeProvider).botones, isEmpty);
      expect(con('ROLE_ADM').read(permisosChequeProvider).puedeTraspasar, isTrue);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 3. LA PANTALLA MONTADA
  // ═══════════════════════════════════════════════════════════════════════════

  // 1280 px para todos; 390 px para los que pide la auditoria (P5, P3, P8, sin
  // botones) y los que cambian la forma de los menus (P1: dos opciones de
  // custodia; P11: custodia, administrador y reimpresion; P12: el mas completo)
  // mas el administrador.
  const idsMovil = {'P5', 'P3', 'P8', 'P1', 'P11', 'P12', 'SIN_BOTONES', 'ADMIN'};

  group('barra a 1280 px', () {
    for (final p in perfilesReales) {
      testWidgets('${p.id}: Registrar, Custodia y Reportes', (tester) async {
        await montar(tester, _cheques(p, RepositorioChequesFalso(total: 0)), ancho: 1280);
        final l = verdad(p);

        expect(
          find.text('Registrar'),
          (l.registrar || l.registre) ? findsOneWidget : findsNothing,
          reason: 'Registrar',
        );
        for (final ya in ['Registrar como administrador', 'Registre', 'Editar (administrador)']) {
          expect(find.text(ya), findsNothing, reason: '$ya ya no existe');
        }

        final custodia = {
          if (l.traspaso) 'Traspaso',
          if (l.aCustodio) 'A Custodio',
          if (l.darCustodia) 'Dar Custodia',
        };
        // Un menu «Custodia» con dos o tres; con una sola, su boton directo.
        expect(
          find.text('Custodia'),
          custodia.length >= 2 ? findsOneWidget : findsNothing,
          reason: 'menu Custodia',
        );
        expect(await _opcionesDeCustodia(tester), custodia, reason: 'Traspaso / A Custodio / Dar Custodia');

        final reportes = {
          if (l.rpt1) 'Cheques recibidos',
          if (l.rpt2) 'Cheques de cobranza',
          if (l.rpt3) 'Cheques en custodia',
          if (l.rpt4) 'Recibo del último cheque',
          if (l.rpt5) 'Reimprimir traspaso',
        };
        expect(
          find.text('Reportes'),
          reportes.isEmpty ? findsNothing : findsOneWidget,
          reason: 'menu Reportes',
        );
        expect(await _opcionesDeReportes(tester), reportes, reason: 'reportes');
      });
    }
  });

  group('barra a 390 px (menu contextual, sin scroll horizontal)', () {
    for (final p in perfilesReales.where((p) => idsMovil.contains(p.id))) {
      testWidgets('${p.id}: un solo menu con lo que corresponde', (tester) async {
        await montar(tester, _cheques(p, RepositorioChequesFalso(total: 0)), ancho: 390);
        final l = verdad(p);

        expect(
          find.byTooltip('Registrar cheque'),
          (l.registrar || l.registre) ? findsOneWidget : findsNothing,
          reason: 'Registrar',
        );
        final esperadas = {
          if (l.traspaso) 'Traspaso',
          if (l.aCustodio) 'A Custodio',
          if (l.darCustodia) 'Dar Custodia',
          if (l.rpt1) 'Cheques recibidos',
          if (l.rpt2) 'Cheques de cobranza',
          if (l.rpt3) 'Cheques en custodia',
          if (l.rpt4) 'Recibo del último cheque',
          if (l.rpt5) 'Reimprimir traspaso',
        };
        // «Actualizar datos SAP» (btnNuevoCH) es de la segunda fase de la auditoria.
        expect(await _itemsDelMenuDeLaBarra(tester), esperadas);

        final horizontales = find.byWidgetPredicate(
          (w) => w is SingleChildScrollView && w.scrollDirection == Axis.horizontal,
        );
        expect(horizontales, findsNothing);
      });
    }
  });

  for (final ancho in [1280.0, 390.0]) {
    group('acciones de la fila a ${ancho.toInt()} px', () {
      for (final p in perfilesReales.where((p) => ancho > 450 || idsMovil.contains(p.id))) {
        for (final estado in ['PEN', 'CER']) {
          testWidgets('${p.id} con el cheque $estado', (tester) async {
            final repo = RepositorioChequesFalso(total: 0)
              ..cheques = [chequeFalso(1, estado: estado, descTipo: 'PAGO')];
            await montar(tester, _cheques(p, repo), ancho: ancho);

            final l = verdad(p);
            expect(
              await _accionesDeLaFila(tester),
              l.accionesDeFila(estado),
              reason: '${p.id} / $estado',
            );
          });
        }
      }
    });
  }

  group('la sucursal: propia, ajena, con y sin btnChqSucrs', () {
    for (final ancho in [1280.0, 390.0]) {
      for (final p in perfilesReales.where((p) => idsMovil.contains(p.id) || p.id == 'P10')) {
        testWidgets('${p.id} a ${ancho.toInt()} px: el combo solo se habilita con btnChqSucrs', (tester) async {
          await montar(tester, _cheques(p, RepositorioChequesFalso(total: 3)), ancho: ancho);
          final combo = tester.widget<DropdownButtonFormField<int>>(comboSucursal());
          expect(combo.onChanged != null, verdad(p).comboSucursal, reason: 'L87: disabled = !btnChqSucrs');
        });
      }
    }

    testWidgets('sin btnChqSucrs y sin sucursal inicial (p_list_Sucursal E = 0): no hay nada que ver y se dice por que', (tester) async {
      final p = perfilesReales.firstWhere((p) => p.id == 'P10'); // btnNuevoCH, sin btnChqSucrs
      final repo = RepositorioChequesFalso(total: 3)..sucursalInicial = 0;
      repo.sucursalInicialPorEmpresa = {};
      await montar(tester, _cheques(p, repo), ancho: 1280);

      expect(find.text('Tu usuario no tiene una sucursal asignada en esta empresa'), findsOneWidget);
      expect(find.text('Selecciona la sucursal en el filtro para ver sus cheques.'), findsNothing);
      // Registrar se ve (btnNuevoCH) pero apagado: no tiene donde guardar.
      final registrar = tester.widget<FilledButton>(
        find.ancestor(of: find.text('Registrar'), matching: find.bySubtype<FilledButton>()),
      );
      expect(registrar.onPressed, isNull);
      expect(tester.widget<DropdownButtonFormField<int>>(comboSucursal()).onChanged, isNull);
    });

    testWidgets('con btnChqSucrs y sin sucursal inicial: el combo esta habilitado y pide elegir una', (tester) async {
      final p = perfilesReales.firstWhere((p) => p.id == 'P11'); // btnChqSucrs
      final repo = RepositorioChequesFalso(total: 3)..sucursalInicial = 0;
      repo.sucursalInicialPorEmpresa = {};
      await montar(tester, _cheques(p, repo), ancho: 1280);

      expect(find.text('Selecciona la sucursal en el filtro para ver sus cheques.'), findsOneWidget);
      expect(find.text('Tu usuario no tiene una sucursal asignada en esta empresa'), findsNothing);
      expect(tester.widget<DropdownButtonFormField<int>>(comboSucursal()).onChanged, isNotNull);
    });

    testWidgets(
      'una sucursal inicial que no esta en el combo (usuario 49: E=9, C=[1]) se muestra igual, sin romper el desplegable '
      '(el alta la rechaza el servidor: DIFERENCIA #1 de PERMISOS_CHEQUES.md)',
      (tester) async {
        final p = perfilesReales.firstWhere((p) => p.id == 'P1');
        final repo = RepositorioChequesFalso(total: 3)..sucursalInicial = 9;
        repo.sucursalesPorEmpresa = {
          1: const [SucursalChequeEntity(codSucursal: 1, nombre: 'Central')],
          5: const [SucursalChequeEntity(codSucursal: 13, nombre: 'Central')],
        };
        final errores = await capturandoErrores(() async {
          await montar(tester, _cheques(p, repo), ancho: 1280);
        });
        expect(errores, isEmpty);
        expect(find.text('Sucursal 9'), findsWidgets);
      },
    );
  });

  group('detalle (Completar): las cuatro acciones no piden boton, solo la rama K', () {
    // Quien llega aqui tiene btnDetalleCH (o es administrador): los demas no ven «Completar».
    for (final p in perfilesReales.where((p) => verdad(p).completar)) {
      testWidgets('${p.id}: botones habilitados = flags de K; Eliminar accion = btnEliminarSegCH', (tester) async {
        final repo = RepositorioChequesFalso(total: 0);
        _detalleConK(repo, '1011');
        await montar(tester, _detalle(p, repo), ancho: 1280);

        expect(_habilitado(tester, 'fechaCobro'), isTrue);
        expect(_habilitado(tester, 'devolver'), isFalse);
        expect(_habilitado(tester, 'cerrarConVerificacion'), isTrue);
        expect(_habilitado(tester, 'cerrarSinVerificacion'), isTrue);

        expect(
          find.byTooltip('Eliminar acción'),
          verdad(p).eliminarAccion ? findsNWidgets(3) : findsNothing,
          reason: 'una por accion del historial; solo con btnEliminarSegCH',
        );
        // «Editar accion» (btnEditarSegCH) no existe: en el legacy guardaba nada.
        expect(find.text('Editar acción'), findsNothing);
      });
    }

    testWidgets('con K = 0000 (cheque cerrado) ninguna de las cuatro, ni siquiera para el administrador', (tester) async {
      for (final id in ['P8', 'ADMIN']) {
        final p = perfilesReales.firstWhere((p) => p.id == id);
        final repo = RepositorioChequesFalso(total: 0);
        _detalleConK(repo, '0000', estado: 'CER');
        await montar(tester, _detalle(p, repo), ancho: 1280);
        for (final t in ['fechaCobro', 'devolver', 'cerrarConVerificacion', 'cerrarSinVerificacion']) {
          expect(_habilitado(tester, t), isFalse, reason: '$id $t');
        }
      }
    });

    testWidgets('el documento PDF no pide boton: lo ve quien entra al detalle', (tester) async {
      final p = perfilesReales.firstWhere((p) => p.id == 'P8');
      final repo = RepositorioChequesFalso(total: 0);
      _detalleConK(repo, '1111');
      await montar(tester, _detalle(p, repo), ancho: 1280);
      expect(find.byKey(const ValueKey('boton-documento-pdf')), findsOneWidget);
    });
  });

  group('bancos (vista 43) montada', () {
    for (final ancho in [1280.0, 390.0]) {
      for (final p in perfilesReales.where((p) => ancho > 450 || idsMovil.contains(p.id))) {
        testWidgets('${p.id} a ${ancho.toInt()} px: Nuevo, Editar y Eliminar', (tester) async {
          final repo = RepositorioBancosFalso();
          await montar(
            tester,
            appBancos(hijo: const BancosScreen(), repo: repo, permisos: p.permisosBanco),
            ancho: ancho,
          );
          final l = verdad(p);
          // Nuevo: banco.xhtml L23. Escritorio: boton «Nuevo»; telefono: el + «Nuevo banco».
          expect(
            ancho > 450 ? find.text('Nuevo') : find.byTooltip('Nuevo banco'),
            l.sin('btnNuevoB') ? findsOneWidget : findsNothing,
            reason: 'Nuevo (btnNuevoB)',
          );
          // Editar (L33) y Eliminar (L36): cada uno con su boton, tabla o tarjetas.
          expect(await _accionesDeBancos(tester), {
            if (l.sin('btnEditarB')) 'Editar',
            if (l.sin('btnEliminarB')) 'Eliminar',
          });
        });
      }
    }
  });
}

// ═════════════════════════════════════════════════════════════════════════════
// PERFILES REALES
// ═════════════════════════════════════════════════════════════════════════════

/// Un perfil de botones. [v42] son los botones de la vista 42 con
/// `nivelAcceso <> '0'`; [v43], los de la vista 43 del mismo usuario.
class PerfilReal {
  const PerfilReal(
    this.id,
    this.v42, {
    this.v43 = const {},
    this.admin = false,
    this.usuarios = '',
  });

  final String id;
  final Set<String> v42;
  final Set<String> v43;
  final bool admin;

  /// Cuantos usuarios lo tienen (PRUEBA / produccion) y de esos cuantos pueden entrar (estado D).
  final String usuarios;

  String get tipoUsuario => admin ? 'ROLE_ADM' : 'ROLE_LIM';

  /// Lo que entrega `POST /view/vistaBtn` (`p_list_UsuarioBtn 'A'`): una fila por
  /// boton con permiso distinto de 0 **de todas las vistas**; aqui tambien una
  /// de otra vista (24) como ruido. Se lee con el mismo modelo de la app.
  List<UsuarioBtnEntity> get filasAcl {
    UsuarioBtnEntity fila(String b, int vista) =>
        UsuarioBtnModel.fromJson({
          'codUsuario': 0,
          'codBtn': 0,
          'nivelAcceso': 0,
          'audUsuario': 0,
          'boton': b,
          'permiso': 1,
          'pertenVist': vista,
        }).toEntity();
    return [
      fila('btnDetalles', 24),
      for (final b in v42) fila(b, 42),
      for (final b in v43) fila(b, 43),
    ];
  }

  PermisosCheque get permisos =>
      PermisosCheque.desde(tipoUsuario: tipoUsuario, botones: filasAcl);

  PermisosBanco get permisosBanco =>
      PermisosBanco.desde(tipoUsuario: tipoUsuario, botones: filasAcl);
}

/// Los 12 perfiles reales de usuarios que no son administradores, mas «sin
/// botones» y «administrador». Ver PERMISOS_CHEQUES.md para quienes pueden entrar
/// de verdad (estado D) y cuantos son.
const perfilesReales = <PerfilReal>[
  PerfilReal('P1', {
    'btnCustodiaCH', 'btnDetalleCH', 'btnEditar2CH', 'btnNuevoCH', 'btnNuevoNRCH',
    'btnNuevoSegCH', 'btnRpt1CH', 'btnRpt2CH', 'btnRpt3CH', 'btnRpt4CH', 'btnTraspasoCH',
  }, v43: {'btnNuevoB'}, usuarios: '4 (4 activos)'),
  PerfilReal('P2', {'btnRpt1CH'}, usuarios: '3 (0 activos)'),
  PerfilReal('P3', {
    'btnChqSucrs', 'btnCustodiaCH', 'btnDetalleCH', 'btnEditar2CH', 'btnNuevoNRCH',
    'btnNuevoSegCH', 'btnRpt1CH', 'btnRpt2CH', 'btnRpt3CH',
  }, usuarios: '3 (1 activo)'),
  PerfilReal('P4', {
    'btnCustodiaCH', 'btnDetalleCH', 'btnEditar2CH', 'btnEliminarNRCH', 'btnNuevoNRCH',
    'btnNuevoSegCH', 'btnRpt1CH', 'btnRpt2CH', 'btnRpt3CH',
  }, usuarios: '3 (0 activos)'),
  PerfilReal('P5', {
    'btnDetalleCH', 'btnEditar1CH', 'btnNuevoCH', 'btnRpt1CH', 'btnRpt4CH', 'btnTraspasoCH',
  }, v43: {'btnNuevoB'}, usuarios: '3 (1 activo en PRUEBA, 0 en produccion)'),
  PerfilReal('P6', {
    'btnDetalleCH', 'btnEditar1CH', 'btnNuevoCH', 'btnRpt1CH', 'btnTraspasoCH',
  }, v43: {'btnNuevoB'}, usuarios: '3 (0 activos)'),
  PerfilReal('P7', {'btnDetalleCH', 'btnRpt1CH'}, usuarios: '2 (0 activos)'),
  PerfilReal('P8', {'btnDetalleCH'}, v43: {'btnNuevoB'}, usuarios: '2 (1 activo; ese tiene ademas btnNuevoB)'),
  PerfilReal('P9', {'btnDetalleCH', 'btnEditarSegCH', 'btnNuevoCH'}, usuarios: '1 (0 activos)'),
  PerfilReal('P10', {
    'btnDetalleCH', 'btnNuevoCH', 'btnRpt1CH', 'btnRpt4CH', 'btnTraspasoCH',
  }, v43: {'btnNuevoB'}, usuarios: '1 (1 activo)'),
  PerfilReal('P11', {
    'btnChqSucrs', 'btnCustodia2CH', 'btnCustodiaCH', 'btnDetalleCH', 'btnEditar1CH',
    'btnEditar2CH', 'btnNuevoNRCH', 'btnNuevoSegCH', 'btnRpt1CH', 'btnRpt2CH', 'btnRpt3CH',
    'btnRpt5CH',
  }, usuarios: '1 (1 activo)'),
  PerfilReal('P12', {
    'btnChqSucrs', 'btnCustodiaCH', 'btnDetalleCH', 'btnEditar1CH', 'btnEditar2CH',
    'btnEliminarNRCH', 'btnNuevoCH', 'btnNuevoNRCH', 'btnNuevoSegCH', 'btnRpt1CH',
    'btnRpt2CH', 'btnRpt3CH', 'btnRpt4CH',
  }, usuarios: '1 (1 activo)'),
  PerfilReal('SIN_BOTONES', {}, usuarios: '103 (83 activos) en PRUEBA, 103 (63) en produccion'),
  PerfilReal('ADMIN', {}, admin: true, usuarios: '4 (tipoUsuario adm)'),
];

// ═════════════════════════════════════════════════════════════════════════════
// LA VERDAD DEL LEGACY (transcrita del codigo)
// ═════════════════════════════════════════════════════════════════════════════

class VerdadLegacy {
  VerdadLegacy._(this._botones, this.adm);

  static VerdadLegacy Function(PerfilReal) get nueva =>
      (p) => VerdadLegacy._({...p.v42, ...p.v43}, p.admin);

  final Set<String> _botones;

  /// `Loggin.validaUsuario()`: `tipoUsuario.equals("adm")`.
  final bool adm;

  /// `Loggin.autorizarBtn` (Loggin.java:385-412): el boton con permiso != 0, o el
  /// respaldo del administrador.
  bool _autorizarBtn(String b) => _botones.contains(b) || adm;

  /// `WizardCheque.esAutorizado(btn)` (:1927) y `esAutorizadoB(btn, cerrado)`
  /// (:1991, el estado esta comentado): solo el ACL.
  bool sin(String b) => _autorizarBtn(b);

  /// `WizardCheque.esAutorizado(btn, estado)` (:1946): ACL y estado distinto de
  /// CER; el administrador siempre.
  bool estado(String b, String e) => (_autorizarBtn(b) && e != 'CER') || adm;

  /// `WizardCheque.esAutorizadoTalCer(btn, estado)` (:1969): ACL y estado CER; el
  /// administrador siempre.
  bool _talCer(String b, String e) => (_autorizarBtn(b) && e == 'CER') || adm;

  /// Para la matriz impresa del documento.
  bool talCer(String b, String e) => _talCer(b, e);

  // ── barra (cheque.xhtml, vistaActiva == 1) ──
  bool get registrar => sin('btnNuevoCH'); // L99
  bool get traspaso => sin('btnTraspasoCH'); // L101
  bool get aCustodio => sin('btnCustodiaCH'); // L103
  bool get rpt1 => sin('btnRpt1CH'); // L105
  bool get rpt2 => sin('btnRpt2CH'); // L107
  bool get rpt3 => sin('btnRpt3CH'); // L109
  bool get rpt4 => sin('btnRpt4CH'); // L111
  bool get registre => sin('btnNuevo2CH'); // L113
  bool get rpt5 => sin('btnRpt5CH'); // L115
  bool get darCustodia => sin('btnCustodia2CH'); // L117
  bool get comboSucursal => sin('btnChqSucrs'); // L87: disabled = !esAutorizado

  // ── detalle ──
  bool get completar => sin('btnDetalleCH'); // L198
  bool get eliminarAccion => sin('btnEliminarSegCH'); // L427

  /// Las acciones de la fila, con los nombres de la app nueva. El administrador
  /// del legacy tenia seis botones («Editar», «Editar talonario», «Fecha Cobro»,
  /// «Edite», «Fecha Cobr», «Completar»); la app nueva los junta en tres iconos
  /// (decision del usuario, fase 4), asi que para el el resultado es otro.
  Set<String> accionesDeFila(String e) {
    if (adm) return {'Editar', 'Fecha de cobro', 'Completar', 'Documento PDF'};
    final editar = estado('btnEditar1CH', e); // L176
    final edite = estado('btnEditar3CH', e); // L186
    final talonario = _talCer('btnEditar1CH', e); // L179
    final fecha = estado('btnEditar2CH', e) || estado('btnEditar3CH', e); // L182, L190
    return {
      if (editar || edite) 'Editar',
      if (talonario) 'Editar talonario',
      if (fecha) 'Fecha de cobro',
      if (completar) 'Completar',
      'Documento PDF', // L202, L206: sin ninguna condicion
    };
  }

  /// El formulario del lapiz: lo que abre cada boton del legacy.
  ModoRegistroCheque? modoDelLapiz(String e) {
    if (adm) return ModoRegistroCheque.admin; // con las fechas dentro de rango
    if (estado('btnEditar3CH', e)) return ModoRegistroCheque.admin; // L186: chequeModalMad
    if (estado('btnEditar1CH', e)) return ModoRegistroCheque.estandar; // L176: chequeModal
    if (_talCer('btnEditar1CH', e)) return ModoRegistroCheque.talonario; // L179: chequeModalTal
    return null;
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// APOYO DE LAS PRUEBAS DE PANTALLA
// ═════════════════════════════════════════════════════════════════════════════

/// La pantalla de cheques para el perfil [p] (el administrador con login ROLE_ADM).
Widget _cheques(PerfilReal p, RepositorioChequesFalso repo) => appCheques(
  hijo: const ChequesScreen(),
  repo: repo,
  permisos: p.permisos,
  login: loginCheques(tipo: p.tipoUsuario),
);

/// El detalle del cheque 5 para el perfil [p].
Widget _detalle(PerfilReal p, RepositorioChequesFalso repo) => appCheques(
  hijo: DetalleCheque(codCheque: BigInt.from(5), onVolver: () {}),
  repo: repo,
  permisos: p.permisos,
  login: loginCheques(tipo: p.tipoUsuario),
);

/// Fija el detalle del cheque 5 con tres acciones en el historial y los flags de K.
void _detalleConK(
  RepositorioChequesFalso repo,
  String codigo, {
  String estado = 'PEN',
}) {
  final hoy = hoyDeLaPrueba();
  AccionChequeEntity accion(int n, String est, String desc) => AccionChequeModel.fromJson({
    'codAccion': 500 + n,
    'codCheque': 5,
    'fecha': '2026-08-01T0${8 + n}:30:00',
    'estado': est,
    'codEmpleado': est == 'CUS' ? 12 : null,
    'nroSAP': null,
    'observacion': null,
    'audUsuario': 47,
    'audFecha': '2026-08-01T0${8 + n}:30:00',
    'descripcion': desc,
    'nro': n,
  }).toEntity();
  repo.alObtenerDetalle =
      (cod) async => ChequeDetalleEntity(
        cheque: chequeFalso(
          5,
          estado: estado,
          descTipo: 'PAGO',
          aOrdenDe: 'BOSQUE SA',
          fechaCheque: isoDia(hoy.subtract(const Duration(days: 5))),
          fechaCobrar: isoDia(hoy.add(const Duration(days: 10))),
        ),
        acciones: [
          accion(1, 'REC', 'RECIBIDO'),
          accion(2, 'TRASP', 'TRASPASO'),
          accion(3, 'CUS', 'A COBRANZA'),
        ],
        botones: BotonesChequeEntity(
          fechaCobro: codigo[0] == '1',
          devolver: codigo[1] == '1',
          cerrarConVerificacion: codigo[2] == '1',
          cerrarSinVerificacion: codigo[3] == '1',
          codigo: codigo,
        ),
      );
}

bool _habilitado(WidgetTester tester, String tipo) =>
    tester.widget<ButtonStyleButton>(find.byKey(ValueKey('accion-$tipo'))).onPressed != null;

/// Los textos de los items del menu abierto.
Set<String> _itemsAbiertos(WidgetTester tester) => {
  for (final m in tester.widgetList<MenuItemButton>(find.byType(MenuItemButton)))
    if (m.child is Text) (m.child as Text).data!,
};

Future<Set<String>> _opcionesDeCustodia(WidgetTester tester) async {
  const todas = ['Traspaso', 'A Custodio', 'Dar Custodia'];
  final menu = find.text('Custodia');
  if (menu.evaluate().isEmpty) {
    // Una sola opcion: su boton directo.
    return {for (final t in todas) if (find.text(t).evaluate().isNotEmpty) t};
  }
  await tester.tap(menu);
  await esperar(tester);
  final items = _itemsAbiertos(tester);
  await tester.tap(menu); // cierra
  await esperar(tester);
  return items.intersection(todas.toSet());
}

Future<Set<String>> _opcionesDeReportes(WidgetTester tester) async {
  final menu = find.text('Reportes');
  if (menu.evaluate().isEmpty) return {};
  await tester.tap(menu);
  await esperar(tester);
  final items = _itemsAbiertos(tester);
  await tester.tap(menu);
  await esperar(tester);
  return items;
}

/// El menu de la barra del telefono (el unico `MenuAccionesCheque` con la
/// grilla vacia), sin «Actualizar datos SAP».
Future<Set<String>> _itemsDelMenuDeLaBarra(WidgetTester tester) async {
  final menus = find.byType(MenuAccionesCheque);
  if (menus.evaluate().isEmpty) return {};
  await tester.tap(menus.first);
  await esperar(tester);
  return _itemsAbiertos(tester)..remove('Actualizar datos SAP');
}

/// Las acciones de la unica fila: iconos con tooltip (escritorio) o un menu
/// «Acciones» (telefono y anchos medios).
Future<Set<String>> _accionesDeLaFila(WidgetTester tester) async {
  const etiquetas = ['Editar', 'Editar talonario', 'Fecha de cobro', 'Completar', 'Documento PDF'];
  final menu = find.byTooltip('Acciones');
  if (menu.evaluate().isNotEmpty) {
    await tester.tap(menu.first);
    await esperar(tester);
    return _itemsAbiertos(tester).intersection(etiquetas.toSet());
  }
  return {for (final e in etiquetas) if (find.byTooltip(e).evaluate().isNotEmpty) e};
}

/// Editar y Eliminar de la primera fila de bancos: iconos con tooltip (tabla) o
/// un menu «Acciones» (tarjetas).
Future<Set<String>> _accionesDeBancos(WidgetTester tester) async {
  const etiquetas = ['Editar', 'Eliminar'];
  final menu = find.byTooltip('Acciones');
  if (menu.evaluate().isNotEmpty) {
    await tester.tap(menu.first);
    await esperar(tester);
    return _itemsAbiertos(tester).intersection(etiquetas.toSet());
  }
  return {for (final e in etiquetas) if (find.byTooltip(e).evaluate().isNotEmpty) e};
}

/// Igual que en `cheques_provider_test.dart`: un `ButtonPermissionsNotifier` sin
/// red que arranca con el estado que se le da.
class _BotonesFalsos extends ButtonPermissionsNotifier {
  _BotonesFalsos(Ref ref, AsyncValue<List<UsuarioBtnEntity>> inicial)
    : super(ref, UserStateNotifier.sinStorage(null), null) {
    state = inicial;
  }
}
