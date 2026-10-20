import 'dart:io';

import 'package:bosque_flutter/core/theme/app_theme.dart';
import 'package:bosque_flutter/core/utils/pegado_personas_examen.dart';
import 'package:bosque_flutter/data/models/tcpe_credencial_model.dart';
import 'package:bosque_flutter/data/models/tcpe_lote_generado_model.dart';
import 'package:bosque_flutter/data/models/tcpe_pedido_examenes_model.dart';
import 'package:bosque_flutter/domain/entities/tcpe_credencial_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_pedido_examenes_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_persona_examen_entity.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/destinatarios_lote.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/dialogos_lote.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/editor_personas.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Modo "Lista de personas": pegado desde Excel, reglas de la lista, body del
/// pedido (sin `claveEsCi`: la clave siempre es temporal), credenciales con CI
/// y nombre, y sus widgets en teléfono y escritorio.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    Future<void> cargar(String familia, List<String> archivos) async {
      final c = FontLoader(familia);
      for (final a in archivos) {
        final f = File('assets/fonts/$a.ttf');
        if (f.existsSync()) c.addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
      }
      await c.load();
    }

    await cargar('Roboto', ['Roboto-Regular', 'Roboto-Medium', 'Roboto-Bold']);
    await cargar('JetBrainsMono', ['JetBrainsMono-400', 'JetBrainsMono-500', 'JetBrainsMono-700']);
  });

  Future<void> montar(WidgetTester tester, double ancho, Widget hijo) async {
    tester.view.physicalSize = Size(ancho, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme().getTheme(),
        home: Scaffold(body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: hijo)),
      ),
    );
  }

  for (final ancho in [360.0, 1000.0]) {
    testWidgets('lista de personas a $ancho px: sin desbordes, pega, valida y quita', (tester) async {
      final destinatarios = ControladorDestinatarios()..modoExternos = ModoExternos.personas;
      final ControladorPersonas personas = destinatarios.personas;
      await montar(tester, ancho, SelectorDestinatarios(controlador: destinatarios));
      expect(find.text('La clave es el CI'), findsNothing, reason: 'v3: la clave siempre es temporal');
      expect(find.textContaining('clave temporal'), findsOneWidget);
      expect(find.text('Pegar desde Excel'), findsOneWidget);

      expect(personas.pegar('1\tAna\tPaz\tMena\n1;Luis;Rojas;'), (2, 0));
      await tester.pump();
      expect(find.text(ancho < 560 ? 'Persona 2' : 'Apellido paterno'), findsOneWidget);
      expect(personas.validar(), 'Fila 1: el CI 1 está repetido.');
      await tester.pump();
      expect(find.text('CI repetido'), findsNWidgets(2));

      personas.quitar(1);
      await tester.pump();
      expect(personas.validar(), isNull);
      expect(personas.personas.single.nombres, 'Ana');
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox());
      destinatarios.dispose();
    });

    testWidgets('credenciales a $ancho px: login, nombre, CI y clave temporal', (tester) async {
      await montar(
        tester,
        ancho,
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 360),
          child: ListaCredenciales(
            credenciales: const [
              TcpeCredencialEntity(
                login: 'IPX-4',
                password: '1234567',
                ci: '1234567',
                nombreCompleto: 'Paz Mena Ana María',
              ),
              TcpeCredencialEntity(login: 'IPX-5', password: 'Kq7mZt9wHp', nombreCompleto: 'Rojas Luis'),
            ],
          ),
        ),
      );
      expect(find.text('IPX-4'), findsOneWidget);
      expect(find.text('Paz Mena Ana María'), findsOneWidget);
      expect(find.text('1234567'), findsWidgets, reason: 'CI y clave');
      expect(find.text('clave = CI'), findsNothing);
      expect(find.text('Kq7mZt9wHp'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  group('pegar desde Excel', () {
    test('tabulación, punto y coma y coma, en el orden ci, nombres, paterno, materno', () {
      final p = parsearPersonasPegadas(
        '4567890\tAna María\tPérez\tGómez\r\n'
        '5678901;Luis;Rojas;\n'
        '6789012, Eva , Luna , Soria\n',
      );
      expect(p, const [
        TcpePersonaExamenEntity(ci: '4567890', nombres: 'Ana María', apellidoPaterno: 'Pérez', apellidoMaterno: 'Gómez'),
        TcpePersonaExamenEntity(ci: '5678901', nombres: 'Luis', apellidoPaterno: 'Rojas'),
        TcpePersonaExamenEntity(ci: '6789012', nombres: 'Eva', apellidoPaterno: 'Luna', apellidoMaterno: 'Soria'),
      ]);
    });

    test('salta líneas vacías y el encabezado; con tabulación las comas son parte del texto', () {
      final p = parsearPersonasPegadas('CI\tNombres\tPaterno\tMaterno\n\n   \n123\tPaz, Ana\tMena\t\n');
      expect(p, const [TcpePersonaExamenEntity(ci: '123', nombres: 'Paz, Ana', apellidoPaterno: 'Mena')]);
    });

    test('una celda inicial vacía no corre las columnas y faltan campos quedan vacíos', () {
      final p = parsearPersonasPegadas('\tAna\tPaz\n777');
      expect(p.first.ci, '');
      expect(p.first.nombres, 'Ana');
      expect(p.first.apellidoPaterno, 'Paz');
      expect(p.last, const TcpePersonaExamenEntity(ci: '777', nombres: '', apellidoPaterno: ''));
    });

    test('quita las comillas con que Excel envuelve una celda', () {
      final p = parsearPersonasPegadas('"99"\t"Ana ""Anita"""\tPaz');
      expect(p.single.ci, '99');
      expect(p.single.nombres, 'Ana "Anita"');
    });
  });

  group('reglas de la lista', () {
    const ana = TcpePersonaExamenEntity(ci: '1', nombres: 'Ana', apellidoPaterno: 'Paz');
    const vacia = TcpePersonaExamenEntity(ci: ' ', nombres: '', apellidoPaterno: '');

    test('una lista correcta pasa, ignorando las filas vacías', () {
      expect(validarPersonasExamen(const [ana, vacia]), isNull);
    });

    test('al menos una persona y como máximo 200', () {
      expect(validarPersonasExamen(const [vacia]), isNotNull);
      final muchas = [
        for (var i = 0; i <= kMaxPersonasPorVez; i++)
          TcpePersonaExamenEntity(ci: '$i', nombres: 'N', apellidoPaterno: 'P'),
      ];
      expect(validarPersonasExamen(muchas), contains('200'));
    });

    test('CI obligatorio y único (sin distinguir espacios ni mayúsculas), con el número de fila', () {
      expect(
        validarPersonasExamen(const [ana, TcpePersonaExamenEntity(ci: '', nombres: 'Eva', apellidoPaterno: 'Luna')]),
        'Fila 2: falta el CI.',
      );
      expect(
        validarPersonasExamen(const [
          TcpePersonaExamenEntity(ci: '12-a', nombres: 'Ana', apellidoPaterno: 'Paz'),
          TcpePersonaExamenEntity(ci: ' 12-A ', nombres: 'Eva', apellidoPaterno: 'Luna'),
        ]),
        'Fila 1: el CI 12-a está repetido.',
      );
    });

    test('nombres obligatorios y al menos un apellido, paterno o materno', () {
      expect(
        validarPersonasExamen(const [TcpePersonaExamenEntity(ci: '1', nombres: '', apellidoPaterno: 'Paz')]),
        'Fila 1: faltan los nombres.',
      );
      expect(
        validarPersonasExamen(const [TcpePersonaExamenEntity(ci: '1', nombres: 'Ana', apellidoPaterno: ' ')]),
        'Fila 1: falta un apellido (paterno o materno).',
      );
      expect(erroresDePersona(ana), isEmpty);
      // Solo el materno basta.
      const soloMaterno = TcpePersonaExamenEntity(ci: '2', nombres: 'Eva', apellidoPaterno: '', apellidoMaterno: 'Mena');
      expect(erroresDePersona(soloMaterno), isEmpty);
      expect(validarPersonasExamen(const [soloMaterno]), isNull);
    });

    test('pegado con la columna del paterno vacía conserva el materno', () {
      final p = parsearPersonasPegadas('123;Eva;;Mena');
      expect(p, const [TcpePersonaExamenEntity(ci: '123', nombres: 'Eva', apellidoPaterno: '', apellidoMaterno: 'Mena')]);
    });
  });

  group('body del pedido', () {
    test('personas: solo personas, con los textos recortados y sin claveEsCi', () {
      const pedido = TcpePedidoExamenesEntity.personas([
        TcpePersonaExamenEntity(ci: ' 4567890 ', nombres: 'Ana ', apellidoPaterno: 'Paz', apellidoMaterno: ' '),
      ]);
      expect(TcpePedidoExamenesModel.fromEntity(pedido).toJson(), {
        'personas': [
          {'ci': '4567890', 'nombres': 'Ana', 'apellidoPaterno': 'Paz', 'apellidoMaterno': null},
        ],
      });
    });

    test('el materno viaja tal cual y no hay clave de CI', () {
      const pedido = TcpePedidoExamenesEntity.personas([
        TcpePersonaExamenEntity(ci: '1', nombres: 'A', apellidoPaterno: 'B', apellidoMaterno: 'C'),
      ]);
      final json = TcpePedidoExamenesModel.fromEntity(pedido).toJson();
      expect(json.containsKey('claveEsCi'), isFalse);
      expect((json['personas'] as List).single['apellidoMaterno'], 'C');
    });

    test('cantidad y empleados solos mandan solo su clave', () {
      expect(TcpePedidoExamenesModel.fromEntity(const TcpePedidoExamenesEntity.cantidad(5)).toJson(), {'cantidad': 5});
      expect(
        TcpePedidoExamenesModel.fromEntity(TcpePedidoExamenesEntity.empleados([BigInt.from(9007199254740)])).toJson(),
        {
          'codEmpleados': [9007199254740],
        },
      );
    });

    test('ida y vuelta: JSON → Model → Entity → Model → JSON', () {
      final json = {
        'personas': [
          {'ci': '1', 'nombres': 'Ana', 'apellidoPaterno': 'Paz', 'apellidoMaterno': 'Mena'},
        ],
      };
      final e = TcpePedidoExamenesModel.fromJson(json).toEntity();
      expect(e.personas.single.ci, '1');
      expect(e.total, 1);
      expect(TcpePedidoExamenesModel.fromEntity(e).toJson(), json);
    });
  });

  group('credencial', () {
    test('fromJson trae ci y nombreCompleto; claveEsCi ya no existe', () {
      final m =
          TcpeCredencialModel.fromJson({
            'codExamen': 401,
            'login': 'IPX-4',
            'password': '1234567',
            'codEmpleado': null,
            'nombreCompleto': 'Paz Mena Ana',
            'ci': '1234567',
            'claveEsCi': true,
          });
      expect(m.toJson().containsKey('claveEsCi'), isFalse, reason: 'se ignora si el backend viejo la manda');
      final c = m.toEntity();
      expect(c.codExamen, BigInt.from(401));
      expect(c.login, 'IPX-4');
      expect(c.ci, '1234567');
      expect(c.nombreCompleto, 'Paz Mena Ana');
      expect(c.tieneClave, isTrue);
    });

    test('sin CI ni nombre (anónimo) quedan en null', () {
      final c = TcpeCredencialModel.fromJson({'codExamen': 1, 'login': 'IPX-1', 'password': 'Kq7mZt9wHp'}).toEntity();
      expect(c.ci, isNull);
      expect(c.nombreCompleto, isNull);
    });

    test('dentro de la respuesta de generar', () {
      final g =
          TcpeLoteGeneradoModel.fromJson({
            'codRolExamen': 30,
            'credenciales': [
              {'codExamen': 401, 'login': 'IPX-4', 'password': 'Kq7mZt9wHp', 'ci': '99', 'nombreCompleto': 'Luna Eva'},
            ],
          }).toEntity();
      expect(g.credenciales.single.password, 'Kq7mZt9wHp');
      expect(g.credenciales.single.nombreCompleto, 'Luna Eva');
    });
  });
}
