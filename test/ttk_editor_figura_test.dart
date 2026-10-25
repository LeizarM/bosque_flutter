import 'package:bosque_flutter/core/network/tiempo_real.dart';
import 'package:bosque_flutter/domain/entities/ttk_estado_publico_entity.dart';
import 'package:bosque_flutter/presentation/widgets/tickets/ttk_bingo_piezas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// El editor de figura escribe la máscara de 0/1 que guarda `p_abm_ttk_BingoJuego`
/// (fila por fila), y el estado en vivo solo avanza con versiones mayores.
void main() {
  group('Máscara de la figura', () {
    test('centro, alternar y casillas útiles sin el comodín', () {
      expect(ttkCentro(5, 5), 12);
      expect(ttkCentro(3, 7), 10);
      expect(ttkEsComodin(12, 5, 5, true), isTrue);
      expect(ttkEsComodin(12, 5, 5, false), isFalse);
      expect(
        ttkEsComodin(10, 4, 5, true),
        isFalse,
        reason: 'con filas pares no hay centro',
      );
      expect(ttkAlternar('00000', 2), '00100');
      expect(ttkAlternar('00100', 2), '00000');
      expect(ttkCasillasUtiles('1' * 25, 5, 5, true), 24);
      expect(ttkCasillasUtiles('1' * 25, 5, 5, false), 25);
      expect(ttkMascara('101', 5), '10100');
      expect(ttkMascara('1x0y1110', 4), '1011');
      expect(ttkMascara(null, 3), '000');
    });

    test('formas rápidas', () {
      expect(ttkFormaRapida(FormaRapidaTtk.marco, '', 3, 3), '111101111');
      expect(ttkFormaRapida(FormaRapidaTtk.equis, '', 3, 3), '101010101');
      expect(
        ttkFormaRapida(FormaRapidaTtk.invertir, '110000000', 3, 3),
        '001111111',
      );
      expect(ttkFormaRapida(FormaRapidaTtk.vacia, '111', 1, 3), '000');
      expect(ttkFormaRapida(FormaRapidaTtk.llena, '', 2, 2), '1111');
    });
  });

  testWidgets('tocar casillas cambia la máscara', (tester) async {
    var mascara = '0' * 25;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder:
                (context, setState) => EditorFiguraTtk(
                  mascara: mascara,
                  filas: 5,
                  columnas: 5,
                  conComodin: true,
                  letras: 'BINGO',
                  alCambiar: (m) => setState(() => mascara = m),
                ),
          ),
        ),
      ),
    );

    // Primera fila, primera casilla: se marca y se desmarca.
    await tester.tap(find.byKey(const ValueKey('ttk-figura-0')));
    await tester.pump();
    expect(mascara, '1${'0' * 24}');
    await tester.tap(find.byKey(const ValueKey('ttk-figura-0')));
    await tester.pump();
    expect(mascara, '0' * 25);

    // Última casilla (fila 5, columna O) y el comodín del centro.
    await tester.tap(find.byKey(const ValueKey('ttk-figura-24')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('ttk-figura-12')));
    await tester.pump();
    expect(mascara[24], '1');
    expect(mascara[12], '1');
    expect(
      find.byIcon(Icons.star_rounded),
      findsOneWidget,
      reason: 'el centro se ve como comodín',
    );
    expect(
      find.textContaining('1 casillas en la figura'),
      findsOneWidget,
      reason: 'el comodín no cuenta',
    );

    // Forma rápida «Marco».
    await tester.tap(find.text('Marco'));
    await tester.pump();
    expect(mascara, ttkFormaRapida(FormaRapidaTtk.marco, '', 5, 5));
    expect(mascara.length, 25);
  });

  testWidgets('deshabilitado no cambia nada', (tester) async {
    var cambios = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EditorFiguraTtk(
            mascara: '1' * 9,
            filas: 3,
            columnas: 3,
            habilitado: false,
            alCambiar: (_) => cambios++,
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('ttk-figura-4')));
    await tester.pump();
    expect(cambios, 0);
    expect(find.text('Marco'), findsNothing);
  });

  group('Tablero que llena el área', () {
    test('proyector: una línea por letra y bolillos grandes', () {
      final m = ttkMedidaTablero(
        ancho: 1856,
        alto: 760,
        grupos: 5,
        porGrupo: 15,
      );
      expect(m.porLinea, 15);
      expect(m.diametro, greaterThan(100));
    });

    test('teléfono: líneas parejas y el alto también cuenta', () {
      final m = ttkMedidaTablero(
        ancho: 358,
        alto: 560,
        grupos: 5,
        porGrupo: 15,
      );
      // La última línea queda casi llena (8 + 7, 5 + 5 + 5), nunca con uno suelto.
      final ultima = 15 - ((15 / m.porLinea).ceil() - 1) * m.porLinea;
      expect(ultima, greaterThanOrEqualTo(m.porLinea - 1));
      final lineas = 5 * (15 / m.porLinea).ceil();
      expect(
        lineas * m.diametro,
        lessThanOrEqualTo(560),
        reason: 'entra en el alto',
      );
      final masAlto = ttkMedidaTablero(
        ancho: 358,
        alto: 900,
        grupos: 5,
        porGrupo: 15,
      );
      expect(masAlto.diametro, greaterThanOrEqualTo(m.diametro));
    });

    test('sin alto (dentro de un scroll) manda el ancho', () {
      final m = ttkMedidaTablero(ancho: 1000, grupos: 5, porGrupo: 15);
      expect(m.porLinea, 15);
      final angosto = ttkMedidaTablero(
        ancho: 300,
        grupos: 5,
        porGrupo: 15,
        minimo: 30,
      );
      expect(angosto.diametro, greaterThanOrEqualTo(30));
      final resto =
          15 - ((15 / angosto.porLinea).ceil() - 1) * angosto.porLinea;
      expect(resto, greaterThanOrEqualTo(angosto.porLinea - 1));
    });
  });

  group('Estado en vivo', () {
    test(
      'solo reemplaza con versión mayor y sondea mientras no hay conexión',
      () async {
        late void Function(TtkEstadoPublicoEntity) emitir;
        late void Function(bool) conexion;
        var consultas = 0;
        var cerrada = false;
        final n = TiempoRealNotifier<TtkEstadoPublicoEntity>(
          version: (e) => e.version,
          consultar: () async {
            consultas++;
            return const TtkEstadoPublicoEntity(version: 3);
          },
          suscribir: (alRecibir, alCambiar) {
            emitir = alRecibir;
            conexion = alCambiar;
            return () => cerrada = true;
          },
          intervaloSondeo: const Duration(milliseconds: 20),
        );
        await Future<void>.delayed(Duration.zero);
        expect(n.state.dato?.version, 3);

        emitir(const TtkEstadoPublicoEntity(version: 2));
        expect(
          n.state.dato?.version,
          3,
          reason: 'una versión vieja no pisa la nueva',
        );
        emitir(const TtkEstadoPublicoEntity(version: 7));
        expect(n.state.dato?.version, 7);

        // Desconectado: consulta por POST cada intervalo.
        final antes = consultas;
        await Future<void>.delayed(const Duration(milliseconds: 70));
        expect(consultas, greaterThan(antes));

        // Conectado: deja de sondear.
        conexion(true);
        await Future<void>.delayed(const Duration(milliseconds: 10));
        final conectado = consultas;
        await Future<void>.delayed(const Duration(milliseconds: 70));
        expect(consultas, conectado);
        expect(n.state.conectado, isTrue);

        n.dispose();
        expect(cerrada, isTrue, reason: 'al salir se cierra la suscripción');
      },
    );
  });
}
