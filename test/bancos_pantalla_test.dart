import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosque_flutter/domain/entities/banco_entity.dart';
import 'package:bosque_flutter/domain/utils/permisos_banco.dart';
import 'package:bosque_flutter/presentation/screens/bancos/bancos_screen.dart';

import 'fakes/arnes_bancos.dart';
import 'fakes/arnes_cheques.dart';
import 'fakes/repositorio_bancos.dart';

/// La pantalla de Bancos (vista 43) con un repositorio falso: tabla en escritorio
/// y tarjetas en movil, botones segun permisos, el formulario de un solo campo
/// con la regla del nombre, la baja con su confirmacion y los estados que no son
/// datos (cargando, vacio, error).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(cargarRoboto);

  late RepositorioBancosFalso repo;
  setUp(() => repo = RepositorioBancosFalso());

  Widget pantalla({PermisosBanco permisos = permisosBancoAdmin}) =>
      appBancos(hijo: const BancosScreen(), repo: repo, permisos: permisos);

  /// Nombres largos que estiran el diseno.
  List<BancoEntity> bancosLargos() => [
    bancoFalso(
      1,
      'BANCO MERCANTIL SANTA CRUZ SOCIEDAD ANONIMA SUCURSAL CHIQUITOS ZONA NORTE',
    ),
    bancoFalso(2, 'BANCO UNION'),
    for (var i = 3; i <= 14; i++) bancoFalso(i, 'BANCO NUMERO $i'),
  ];

  Finder fila(int cod) => find.byKey(ValueKey('banco-$cod'));

  Finder accionDeFila(int cod, String tooltip) =>
      find.descendant(of: fila(cod), matching: find.byTooltip(tooltip));

  Future<void> escribirNombre(WidgetTester tester, String texto) async {
    await tester.enterText(
      find.byKey(const ValueKey('campo-nombre-banco')),
      texto,
    );
    await esperar(tester);
  }

  Future<void> pulsar(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.tap(f);
    await esperar(tester);
  }

  Finder boton(String etiqueta) => find.widgetWithText(FilledButton, etiqueta);

  // ── Sin desbordes: movil, tablet y escritorio, tambien con texto grande ───

  final modoPorAncho = {
    390.0: 'lista-tarjetas',
    700.0: 'lista-tarjetas',
    800.0: 'lista-tabla',
    1400.0: 'lista-tabla',
  };

  for (final escala in [1.0, 1.5]) {
    modoPorAncho.forEach((ancho, modo) {
      testWidgets(
        'no desborda a ${ancho.toInt()} px con texto al ${(escala * 100).toInt()} % ($modo)',
        (tester) async {
          repo.bancos = bancosLargos();
          if (escala != 1.0) conTexto(tester, escala);

          final errores = await capturandoErrores(() async {
            await montar(tester, pantalla(), ancho: ancho);
          });

          expect(errores, isEmpty, reason: 'a $ancho');
          expect(find.byKey(ValueKey(modo)), findsOneWidget);
          expect(find.textContaining('SOCIEDAD ANONIMA'), findsOneWidget);
        },
      );
    });
  }

  for (final ancho in [390.0, 800.0, 1400.0]) {
    testWidgets(
      'el formulario y la confirmacion no desbordan a ${ancho.toInt()} px al 150 %',
      (tester) async {
        conTexto(tester, 1.5);
        repo.bancos = bancosLargos();
        repo.errorEscritura = Exception(
          'No se puede eliminar el banco: tiene registros relacionados\n'
          'Depositos o Pagos al Exterior con este banco',
        );
        var errorEnFormulario = false;
        final errores = await capturandoErrores(() async {
          await montar(tester, pantalla(), ancho: ancho);
          // Formulario nuevo con error del servidor.
          await pulsar(
            tester,
            ancho < 600 ? find.byTooltip('Nuevo banco') : find.text('Nuevo'),
          );
          await escribirNombre(tester, 'BANCO NUEVO');
          await pulsar(tester, boton('Registrar banco'));
          errorEnFormulario =
              find
                  .text('Depositos o Pagos al Exterior con este banco')
                  .evaluate()
                  .isNotEmpty;
          await pulsar(tester, find.text('Cancelar'));
          // Confirmacion de baja y su error.
          if (ancho < 600) {
            await pulsar(tester, accionDeFila(1, 'Acciones'));
            await pulsar(tester, find.text('Eliminar'));
          } else {
            await pulsar(tester, accionDeFila(1, 'Eliminar'));
          }
          await pulsar(tester, boton('Eliminar banco'));
        });
        expect(errores, isEmpty, reason: 'a $ancho');
        expect(errorEnFormulario, isTrue);
        expect(find.text('No se pudo eliminar el banco'), findsOneWidget);
      },
    );
  }

  // ── Lista ─────────────────────────────────────────────────────────────────

  testWidgets(
    'escritorio: una columna por dato, orden del servidor y el total',
    (tester) async {
      await montar(tester, pantalla(), ancho: 1400);

      final tabla = find.byKey(const ValueKey('lista-tabla'));
      for (final c in ['Código', 'Nombre', 'Acciones']) {
        expect(
          find.descendant(of: tabla, matching: find.text(c)),
          findsOneWidget,
          reason: 'columna $c',
        );
      }
      expect(find.text('BANCO MERCANTIL SANTA CRUZ'), findsOneWidget);
      expect(find.text('BANCO UNION'), findsOneWidget);
      expect(find.text('BISA'), findsOneWidget);
      // El mismo orden en que llegaron: no se reordena en el cliente.
      final y = [
        for (final n in ['BANCO MERCANTIL SANTA CRUZ', 'BANCO UNION', 'BISA'])
          tester.getTopLeft(find.text(n)).dy,
      ];
      expect(y, [...y]..sort());
      expect(find.text('3 bancos'), findsOneWidget);
      expect(find.text('Bancos'), findsOneWidget);
    },
  );

  testWidgets('en una pantalla muy ancha la tabla no pasa de 960 px', (
    tester,
  ) async {
    await montar(tester, pantalla(), ancho: 1800);
    final tabla = find.byKey(const ValueKey('lista-tabla'));
    expect(tester.getSize(tabla).width, 960);
    // Pegada a la izquierda, como el titulo.
    expect(
      tester.getTopLeft(tabla).dx,
      tester.getTopLeft(find.text('Bancos')).dx,
    );
  });

  testWidgets(
    'movil: tarjetas con el nombre y el codigo, sin scroll horizontal',
    (tester) async {
      await montar(tester, pantalla(), ancho: 390);

      expect(find.byKey(const ValueKey('lista-tabla')), findsNothing);
      expect(find.byKey(const ValueKey('lista-tarjetas')), findsOneWidget);
      expect(find.text('BANCO UNION'), findsOneWidget);
      expect(find.text('Código 7'), findsOneWidget);
      expect(find.text('3 bancos'), findsOneWidget);
      final horizontales = find.byWidgetPredicate(
        (w) =>
            w is SingleChildScrollView && w.scrollDirection == Axis.horizontal,
      );
      expect(horizontales, findsNothing);
    },
  );

  testWidgets('un solo banco se cuenta en singular', (tester) async {
    repo.bancos = [bancoFalso(7, 'BANCO UNION')];
    await montar(tester, pantalla(), ancho: 1400);
    expect(find.text('1 banco'), findsOneWidget);
  });

  testWidgets('el boton de actualizar vuelve a pedir la lista', (tester) async {
    await montar(tester, pantalla(), ancho: 1400);
    expect(repo.contar('listar'), 1);
    repo.bancos = [...repo.bancos, bancoFalso(20, 'BANCO NUEVO')];
    await pulsar(tester, find.byTooltip('Actualizar'));
    expect(repo.contar('listar'), 2);
    expect(find.text('BANCO NUEVO'), findsOneWidget);
  });

  // ── Estados que no son datos ─────────────────────────────────────────────

  testWidgets('mientras llega la lista hay un esqueleto', (tester) async {
    final espera = Future<void>.delayed(const Duration(seconds: 3));
    repo.alListar = () async {
      await espera;
      return repo.bancos;
    };
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(pantalla());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const ValueKey('esqueleto-bancos')), findsOneWidget);
    expect(find.textContaining('Todavía no hay bancos'), findsNothing);
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();
    expect(find.byKey(const ValueKey('esqueleto-bancos')), findsNothing);
    expect(find.text('BANCO UNION'), findsOneWidget);
  });

  testWidgets('sin bancos: estado vacio que invita a registrar con permiso', (
    tester,
  ) async {
    repo.bancos = [];
    await montar(tester, pantalla(), ancho: 1400);
    expect(find.text('Todavía no hay bancos registrados'), findsOneWidget);
    expect(find.text('Registra el primero con «Nuevo».'), findsOneWidget);
    expect(find.text('Reintentar'), findsNothing);
  });

  testWidgets(
    'sin bancos y sin permiso de crear: no promete un boton que no ve',
    (tester) async {
      repo.bancos = [];
      await montar(
        tester,
        pantalla(permisos: permisosBancoNinguno),
        ancho: 1400,
      );
      expect(find.text('Todavía no hay bancos registrados'), findsOneWidget);
      expect(find.textContaining('«Nuevo»'), findsNothing);
    },
  );

  testWidgets('un fallo no se ve como lista vacia: el motivo y Reintentar', (
    tester,
  ) async {
    repo.errorLectura = Exception(
      'No tiene permiso para esta accion.\nLinea 2',
    );
    await montar(tester, pantalla(), ancho: 1400);

    expect(find.text('No se pudieron cargar los bancos'), findsOneWidget);
    expect(find.text('No tiene permiso para esta accion.'), findsOneWidget);
    expect(find.text('Linea 2'), findsOneWidget);
    expect(find.textContaining('Todavía no hay bancos'), findsNothing);
    expect(find.byKey(const ValueKey('lista-tabla')), findsNothing);

    repo.errorLectura = null;
    await pulsar(tester, find.text('Reintentar'));
    expect(find.text('Reintentar'), findsNothing);
    expect(find.text('BANCO UNION'), findsOneWidget);
    expect(repo.contar('listar'), 2);
  });

  testWidgets('un error inesperado tambien se dice y deja reintentar', (
    tester,
  ) async {
    repo.errorLectura = StateError('boom');
    await montar(tester, pantalla(), ancho: 390);
    expect(find.text('No se pudieron cargar los bancos'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  // ── Botones segun los permisos ───────────────────────────────────────────

  group('botones segun permisos (escritorio)', () {
    final casos =
        <String, ({PermisosBanco permisos, bool nuevo, Set<String> fila})>{
          'administrador': (
            permisos: permisosBancoAdmin,
            nuevo: true,
            fila: {'Editar', 'Eliminar'},
          ),
          'solo btnNuevoB': (
            permisos: permisosBancoCon([PermisosBanco.btnNuevo]),
            nuevo: true,
            fila: <String>{},
          ),
          'solo btnEditarB': (
            permisos: permisosBancoCon([PermisosBanco.btnEditar]),
            nuevo: false,
            fila: {'Editar'},
          ),
          'solo btnEliminarB': (
            permisos: permisosBancoCon([PermisosBanco.btnEliminar]),
            nuevo: false,
            fila: {'Eliminar'},
          ),
          'sin ningun boton': (
            permisos: permisosBancoNinguno,
            nuevo: false,
            fila: <String>{},
          ),
        };

    casos.forEach((nombre, caso) {
      testWidgets(nombre, (tester) async {
        await montar(tester, pantalla(permisos: caso.permisos), ancho: 1400);
        expect(find.text('Nuevo'), caso.nuevo ? findsOneWidget : findsNothing);
        for (final a in ['Editar', 'Eliminar']) {
          expect(
            find.byTooltip(a),
            caso.fila.contains(a) ? findsNWidgets(3) : findsNothing,
            reason: '$nombre / $a',
          );
        }
        // Sin acciones, ni siquiera la columna.
        expect(
          find.text('Acciones'),
          caso.fila.isEmpty ? findsNothing : findsOneWidget,
        );
        // La lista se ve igual: los permisos solo quitan botones.
        expect(find.text('BANCO UNION'), findsOneWidget);
      });
    });
  });

  group('botones segun permisos (movil)', () {
    testWidgets('administrador: Nuevo y un menu por tarjeta', (tester) async {
      await montar(tester, pantalla(), ancho: 390);
      expect(find.byTooltip('Nuevo banco'), findsOneWidget);
      expect(find.byTooltip('Acciones'), findsNWidgets(3));
      // Nada suelto en la tarjeta.
      expect(find.byTooltip('Editar'), findsNothing);

      await pulsar(tester, accionDeFila(7, 'Acciones'));
      expect(find.text('Editar'), findsOneWidget);
      expect(find.text('Eliminar'), findsOneWidget);
    });

    testWidgets('solo btnEditarB: el menu trae solo Editar y no hay Nuevo', (
      tester,
    ) async {
      await montar(
        tester,
        pantalla(permisos: permisosBancoCon([PermisosBanco.btnEditar])),
        ancho: 390,
      );
      expect(find.byTooltip('Nuevo banco'), findsNothing);
      await pulsar(tester, accionDeFila(7, 'Acciones'));
      expect(find.text('Editar'), findsOneWidget);
      expect(find.text('Eliminar'), findsNothing);
    });

    testWidgets('sin ningun boton: ni Nuevo ni menus', (tester) async {
      await montar(
        tester,
        pantalla(permisos: permisosBancoNinguno),
        ancho: 390,
      );
      expect(find.byTooltip('Nuevo banco'), findsNothing);
      expect(find.byTooltip('Acciones'), findsNothing);
      expect(find.text('BANCO UNION'), findsOneWidget);
    });
  });

  // ── Formulario ────────────────────────────────────────────────────────────

  group('formulario', () {
    Future<void> abrirNuevo(WidgetTester tester, {double ancho = 1400}) async {
      await montar(tester, pantalla(), ancho: ancho);
      await pulsar(
        tester,
        ancho < 600 ? find.byTooltip('Nuevo banco') : find.text('Nuevo'),
      );
    }

    testWidgets('el nombre es obligatorio y no llama al servidor vacio', (
      tester,
    ) async {
      await abrirNuevo(tester);
      expect(find.text('Nuevo banco'), findsOneWidget);
      await pulsar(tester, boton('Registrar banco'));

      expect(find.text('Ingresa el nombre del banco.'), findsOneWidget);
      expect(repo.contar('registrar'), 0);
    });

    for (final caso
        in <String, String>{
          'con punto': 'BANCO S.A.',
          'con acento': 'BANCÓ UNION',
          'con ene': 'BANCO DEL PIÑO',
          'muy corto': 'AB',
          'solo espacios entre dos letras de borde': '  A  ',
          'con coma': 'BANCO UNION, SA',
          'con guion medio (el regex del legacy no lo admite)': 'BANCO-X',
        }.entries) {
      testWidgets('rechaza un nombre ${caso.key}', (tester) async {
        await abrirNuevo(tester);
        await escribirNombre(tester, caso.value);
        await pulsar(tester, boton('Registrar banco'));

        expect(
          find.textContaining('De 3 a 50 caracteres: letras sin acento'),
          findsOneWidget,
          reason: caso.value,
        );
        expect(repo.contar('registrar'), 0);
      });
    }

    for (final valido in [
      'BANCO UNION',
      'Banco 2000',
      "BANCO D'ORO",
      'BANCO A/B',
      'ABC',
      'A' * 50,
    ]) {
      testWidgets('acepta «$valido»', (tester) async {
        await abrirNuevo(tester);
        await escribirNombre(tester, valido);
        await pulsar(tester, boton('Registrar banco'));
        expect(repo.contar('registrar'), 1);
      });
    }

    testWidgets('no deja escribir mas de 50 caracteres', (tester) async {
      await abrirNuevo(tester);
      await escribirNombre(tester, 'A' * 60);
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const ValueKey('campo-nombre-banco')),
            )
            .controller!
            .text
            .length,
        50,
      );
      await pulsar(tester, boton('Registrar banco'));
      expect(repo.ultimoCuerpo('registrar')['nombre'], 'A' * 50);
    });

    testWidgets('un mensaje de error largo se lee entero en el telefono', (
      tester,
    ) async {
      await abrirNuevo(tester, ancho: 390);
      await escribirNombre(tester, 'BANCO S.A.');
      await pulsar(tester, boton('Registrar banco'));
      final error = find.textContaining(
        'De 3 a 50 caracteres: letras sin acento',
      );
      // Cabe en las tres lineas permitidas: no se corta con puntos suspensivos.
      expect(tester.widget<Text>(error).maxLines, 3);
      expect(
        tester.renderObject<RenderParagraph>(error).didExceedMaxLines,
        isFalse,
      );
      expect(find.textContaining('Sin punto ni acentos.'), findsOneWidget);
    });

    testWidgets('el error se actualiza al corregir, sin volver a guardar', (
      tester,
    ) async {
      await abrirNuevo(tester);
      await escribirNombre(tester, 'BANCO S.A.');
      await pulsar(tester, boton('Registrar banco'));
      expect(find.textContaining('De 3 a 50 caracteres'), findsOneWidget);

      await escribirNombre(tester, 'BANCO SA');
      expect(find.textContaining('De 3 a 50 caracteres: letras'), findsNothing);
    });

    testWidgets(
      'un alta valida manda codBanco 0 y el nombre sin espacios sobrantes',
      (tester) async {
        await abrirNuevo(tester);
        await escribirNombre(tester, '  BANCO NACIONAL  ');
        await pulsar(tester, boton('Registrar banco'));

        expect(repo.ultimoCuerpo('registrar'), {
          'codBanco': 0,
          'nombre': 'BANCO NACIONAL',
        });
        // Se cierra, avisa y la lista muestra el banco nuevo.
        expect(find.text('Nuevo banco'), findsNothing);
        expect(find.text('Banco BANCO NACIONAL registrado.'), findsOneWidget);
        expect(find.text('BANCO NACIONAL'), findsOneWidget);
        expect(repo.contar('listar'), 2);
        expect(find.text('4 bancos'), findsOneWidget);
      },
    );

    testWidgets('editar parte del nombre actual y manda el codigo', (
      tester,
    ) async {
      await montar(tester, pantalla(), ancho: 1400);
      await pulsar(tester, accionDeFila(7, 'Editar'));

      expect(find.text('Editar banco'), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const ValueKey('campo-nombre-banco')),
            )
            .controller!
            .text,
        'BANCO UNION',
      );
      await escribirNombre(tester, 'BANCO UNION SA');
      await pulsar(tester, boton('Guardar cambios'));

      expect(repo.ultimoCuerpo('registrar'), {
        'codBanco': 7,
        'nombre': 'BANCO UNION SA',
      });
      expect(find.text('Banco actualizado.'), findsOneWidget);
      expect(find.text('BANCO UNION SA'), findsOneWidget);
      expect(find.text('BANCO UNION'), findsNothing);
    });

    testWidgets(
      'el error del servidor se ve completo y el formulario sigue abierto',
      (tester) async {
        repo.errorEscritura = Exception(
          'Llenado Requerido.\nEl Registro NO fue Hallado',
        );
        await abrirNuevo(tester);
        await escribirNombre(tester, 'BANCO NUEVO');
        await pulsar(tester, boton('Registrar banco'));

        expect(find.text('Llenado Requerido.'), findsOneWidget);
        expect(find.text('El Registro NO fue Hallado'), findsOneWidget);
        expect(find.textContaining('Exception'), findsNothing);
        expect(find.text('Nuevo banco'), findsOneWidget);
        // La lista no se releyo: no se guardo nada.
        expect(repo.contar('listar'), 1);

        repo.errorEscritura = null;
        await pulsar(tester, boton('Registrar banco'));
        expect(find.text('Llenado Requerido.'), findsNothing);
        expect(find.text('Nuevo banco'), findsNothing);
      },
    );

    testWidgets(
      'el error de un intento anterior no aparece al abrir de nuevo',
      (tester) async {
        repo.errorEscritura = Exception('Error viejo');
        await abrirNuevo(tester);
        await escribirNombre(tester, 'BANCO NUEVO');
        await pulsar(tester, boton('Registrar banco'));
        expect(find.text('Error viejo'), findsOneWidget);

        await pulsar(tester, find.text('Cancelar'));
        await pulsar(tester, find.text('Nuevo'));
        expect(find.text('Error viejo'), findsNothing);
      },
    );

    testWidgets('Cancelar cierra sin guardar', (tester) async {
      await abrirNuevo(tester);
      await escribirNombre(tester, 'BANCO NUEVO');
      await pulsar(tester, find.text('Cancelar'));
      expect(find.text('Nuevo banco'), findsNothing);
      expect(repo.contar('registrar'), 0);
    });

    testWidgets('en movil el formulario ocupa toda la pantalla', (
      tester,
    ) async {
      await abrirNuevo(tester, ancho: 390);
      expect(find.byType(Dialog), findsOneWidget);
      expect(tester.getSize(find.byType(Dialog)).width, 390);
    });
  });

  // ── Baja ──────────────────────────────────────────────────────────────────

  group('eliminar', () {
    testWidgets(
      'pide confirmacion y avisa que borrar un banco con cheques los saca del listado',
      (tester) async {
        await montar(tester, pantalla(), ancho: 1400);
        await pulsar(tester, accionDeFila(7, 'Eliminar'));

        expect(find.text('¿Eliminar el banco BANCO UNION?'), findsOneWidget);
        expect(
          find.textContaining('dejan de aparecer en el listado de Cheques'),
          findsOneWidget,
        );
        expect(
          find.textContaining('depósitos o pagos al exterior'),
          findsOneWidget,
        );
        // Todavia no se borro nada.
        expect(repo.contar('eliminar'), 0);
      },
    );

    testWidgets('Cancelar no elimina', (tester) async {
      await montar(tester, pantalla(), ancho: 1400);
      await pulsar(tester, accionDeFila(7, 'Eliminar'));
      await pulsar(tester, find.text('Cancelar'));

      expect(repo.contar('eliminar'), 0);
      expect(find.text('BANCO UNION'), findsOneWidget);
    });

    testWidgets('confirmar elimina, avisa y relee la lista', (tester) async {
      await montar(tester, pantalla(), ancho: 1400);
      await pulsar(tester, accionDeFila(7, 'Eliminar'));
      await pulsar(tester, boton('Eliminar banco'));

      expect(repo.ultimoCuerpo('eliminar'), {'id': 7});
      expect(find.text('Banco eliminado.'), findsOneWidget);
      expect(find.text('BANCO UNION'), findsNothing);
      expect(find.text('2 bancos'), findsOneWidget);
      expect(repo.contar('listar'), 2);
    });

    testWidgets('en movil, desde el menu de la tarjeta', (tester) async {
      await montar(tester, pantalla(), ancho: 390);
      await pulsar(tester, accionDeFila(12, 'Acciones'));
      await pulsar(tester, find.text('Eliminar'));
      await pulsar(tester, boton('Eliminar banco'));
      expect(repo.ultimoCuerpo('eliminar'), {'id': 12});
      expect(find.text('BISA'), findsNothing);
    });

    testWidgets('el error 547 se muestra tal cual, completo, y el banco sigue', (
      tester,
    ) async {
      repo.errorEscritura = Exception(
        'No se puede eliminar el banco: tiene registros relacionados en Depositos o Pagos al Exterior.\n'
        'Quite primero esos registros.',
      );
      await montar(tester, pantalla(), ancho: 1400);
      await pulsar(tester, accionDeFila(7, 'Eliminar'));
      await pulsar(tester, boton('Eliminar banco'));

      expect(find.text('No se pudo eliminar el banco'), findsOneWidget);
      expect(
        find.text(
          'No se puede eliminar el banco: tiene registros relacionados en Depositos o Pagos al Exterior.',
        ),
        findsOneWidget,
      );
      expect(find.text('Quite primero esos registros.'), findsOneWidget);
      expect(find.textContaining('Exception'), findsNothing);
      expect(find.text('Banco eliminado.'), findsNothing);
      // El banco sigue y la lista no se releyo.
      expect(find.text('BANCO UNION'), findsOneWidget);
      expect(repo.contar('listar'), 1);

      await pulsar(tester, find.text('Entendido'));
      expect(find.text('No se pudo eliminar el banco'), findsNothing);
    });
  });
}
