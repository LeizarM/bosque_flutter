import 'package:bosque_flutter/core/state/notifiers/rendicion_examen_notifier.dart';
import 'package:bosque_flutter/core/utils/cronometro_examen.dart';
import 'package:bosque_flutter/core/utils/sondeo_periodico.dart';
import 'package:bosque_flutter/core/utils/ultima_pregunta_storage.dart';
import 'package:bosque_flutter/domain/entities/tcpe_estado_examen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes/repositorio_rendicion_examen.dart';

/// El cronómetro cuenta desde lo que dijo el servidor, y la rendición guarda
/// cada respuesta, se re-sincroniza con ella y entrega sola al llegar a 0.
void main() {
  // La última pregunta vista va a SharedPreferences: en memoria en las pruebas.
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('CronometroExamen', () {
    late DateTime ahora;
    late CronometroExamen reloj;

    setUp(() {
      ahora = DateTime(2026, 10, 19, 9);
      reloj = CronometroExamen(reloj: () => ahora);
    });

    test('sin sincronizar no cuenta ni se da por agotado', () {
      expect(reloj.restantes, 0);
      expect(reloj.agotado, isFalse);
    });

    test('descuenta el tiempo transcurrido desde la respuesta del servidor', () {
      reloj.sincronizar(120);
      expect(reloj.restantes, 120);
      ahora = ahora.add(const Duration(milliseconds: 30900));
      expect(reloj.restantes, 90, reason: 'se trunca: 30,9 s pasados son 30');
      ahora = ahora.add(const Duration(minutes: 5));
      expect(reloj.restantes, 0, reason: 'nunca negativo');
      expect(reloj.agotado, isTrue);
    });

    test('re-sincronizar manda el servidor, no el reloj local', () {
      reloj.sincronizar(600);
      ahora = ahora.add(const Duration(seconds: 100));
      expect(reloj.restantes, 500);
      reloj.sincronizar(450); // el servidor dice que queda menos
      expect(reloj.restantes, 450);
      ahora = ahora.add(const Duration(seconds: 50));
      expect(reloj.restantes, 400);
      reloj.sincronizar(-5);
      expect(reloj.restantes, 0);
    });

    test('formato y tonos', () {
      expect(CronometroExamen.formato(0), '00:00');
      expect(CronometroExamen.formato(59), '00:59');
      expect(CronometroExamen.formato(1800), '30:00');
      expect(CronometroExamen.formato(3725), '1:02:05');
      expect(CronometroExamen.enAviso(301), isFalse);
      expect(CronometroExamen.enAviso(300), isTrue);
      expect(CronometroExamen.critico(61), isFalse);
      expect(CronometroExamen.critico(60), isTrue);
    });
  });

  group('RendicionExamenNotifier', () {
    late DateTime ahora;
    late RendicionFalsa repo;
    late RendicionExamenNotifier n;

    // testWidgets: los Timer del reloj y de la pausa al escribir corren sobre el
    // tiempo falso de tester.pump.
    Future<void> montar(WidgetTester tester, {int segundos = 1800, String estado = 'EN_CURSO'}) async {
      ahora = DateTime(2026, 10, 19, 9);
      repo = RendicionFalsa(estado: estado, segundos: segundos);
      n = RendicionExamenNotifier(
        repo,
        BigInt.from(10),
        cronometro: CronometroExamen(reloj: () => ahora),
      );
      await tester.pump();
    }

    Future<void> avanzar(WidgetTester tester, Duration d) async {
      ahora = ahora.add(d);
      await tester.pump(d);
    }

    testWidgets('carga el examen en curso con el reloj del servidor', (tester) async {
      await montar(tester, segundos: 1799);
      expect(n.state.cargando, isFalse);
      expect(n.state.preguntas, hasLength(3));
      expect(n.state.opciones[BigInt.from(1)], hasLength(2));
      expect(n.state.segundos, 1799);
      expect(n.state.pendientes, [0, 1, 2]);
      n.dispose();
    });

    testWidgets('marcar una opción la guarda al instante y re-sincroniza el reloj', (tester) async {
      await montar(tester);
      repo.segundosAlResponder = 1200;
      n.alternarOpcion(BigInt.from(1), BigInt.from(101));
      expect(n.state.marcadas[BigInt.from(1)], {BigInt.from(101)}, reason: 'se ve marcada antes de la respuesta');
      await tester.pump();
      expect(repo.respuestas.single.opciones, [BigInt.from(101)]);
      expect(n.state.segundos, 1200);
      expect(n.state.pendientes, [1, 2]);

      // Desmarcar manda la lista vacía: la pregunta queda sin responder.
      n.alternarOpcion(BigInt.from(1), BigInt.from(101));
      await tester.pump();
      expect(repo.respuestas.last.opciones, isEmpty);
      expect(n.state.pendientes, [0, 1, 2]);
      n.dispose();
    });

    testWidgets('el texto de una abierta se guarda una vez, tras la pausa', (tester) async {
      await montar(tester);
      n.escribir(BigInt.from(3), 'Bloq');
      await avanzar(tester, const Duration(milliseconds: 300));
      n.escribir(BigInt.from(3), 'Bloqueo y etiquetado');
      await avanzar(tester, const Duration(milliseconds: 300));
      expect(repo.respuestas, isEmpty);
      await avanzar(tester, const Duration(milliseconds: 600));
      expect(repo.respuestas.single.respuestaU, 'Bloqueo y etiquetado');
      n.dispose();
    });

    testWidgets('tiempo vencido al responder: queda entregado y avisa, sin reintentar', (tester) async {
      await montar(tester);
      repo.errorAlResponder = Exception('Se terminó el tiempo: el examen se entregó automáticamente.');
      n.alternarOpcion(BigInt.from(2), BigInt.from(201));
      await tester.pump();
      await tester.pump();
      expect(n.state.estadoExamen, EstadoExamenTcpe.porRevisar);
      expect(n.state.aviso, contains('Se terminó el tiempo'));
      expect(repo.respuestas, hasLength(1));
      expect(repo.finalizados, 0, reason: 'el servidor ya lo entregó');
      n.dispose();
    });

    testWidgets('error con otro texto pero el servidor ya lo entregó: queda cerrado (no depende del mensaje)', (tester) async {
      await montar(tester);
      repo.errorAlResponder = Exception('Texto nuevo que redactó el revisor.');
      n.alternarOpcion(BigInt.from(2), BigInt.from(201));
      await tester.pump();
      await tester.pump();
      await tester.pump();
      expect(n.state.estadoExamen, EstadoExamenTcpe.porRevisar);
      expect(n.state.aviso, contains('Texto nuevo'));
      expect(repo.finalizados, 0);
      n.dispose();
    });

    testWidgets('error común al responder: se revierte la marca y se avisa', (tester) async {
      await montar(tester);
      repo.errorAlResponder = Exception('Alguna opcion no pertenece a la pregunta.');
      repo.errorEntrega = false;
      n.alternarOpcion(BigInt.from(2), BigInt.from(201));
      await tester.pump();
      await tester.pump();
      await tester.pump();
      expect(n.state.estadoExamen, EstadoExamenTcpe.enCurso);
      expect(n.state.marcadas[BigInt.from(2)] ?? const <BigInt>{}, isEmpty);
      expect(n.state.aviso, contains('Alguna opcion'));
      n.dispose();
    });

    testWidgets('al llegar a 0 entrega solo, una vez', (tester) async {
      await montar(tester, segundos: 3);
      expect(n.state.segundos, 3);
      await avanzar(tester, const Duration(seconds: 1));
      expect(n.state.segundos, 2);
      await avanzar(tester, const Duration(seconds: 2));
      await tester.pump();
      expect(repo.finalizados, 1);
      expect(n.state.estadoExamen.cerrado, isTrue);
      await avanzar(tester, const Duration(seconds: 5));
      expect(repo.finalizados, 1);
      n.dispose();
    });

    testWidgets('sin iniciar: iniciar y cargar las preguntas', (tester) async {
      await montar(tester, estado: 'SIN_INICIAR');
      expect(n.state.estadoExamen, EstadoExamenTcpe.sinIniciar);
      expect(n.state.preguntas, isEmpty);
      await n.iniciar();
      await tester.pump();
      expect(repo.iniciados, 1);
      expect(n.state.estadoExamen, EstadoExamenTcpe.enCurso);
      expect(n.state.preguntas, hasLength(3));
      n.dispose();
    });

    testWidgets('entregar manda antes el texto que esperaba la pausa', (tester) async {
      await montar(tester);
      n.escribir(BigInt.from(3), 'Cortar energía');
      final entrega = n.entregar();
      await tester.pump();
      expect(await entrega, isTrue);
      expect(repo.respuestas.single.respuestaU, 'Cortar energía');
      expect(repo.finalizados, 1);
      n.dispose();
    });

    // v3: al recargar (F5) vuelve a la última pregunta vista, guardada por examen.
    testWidgets('recargar vuelve a la última pregunta vista', (tester) async {
      SharedPreferences.setMockInitialValues({UltimaPreguntaStorage.clave(BigInt.from(10)): '3'});
      await montar(tester);
      await tester.pump();
      expect(n.state.actual, 2, reason: 'la pregunta 3 es la tercera');
      expect(n.state.textos[BigInt.from(3)], isNotNull, reason: 'el estado sale del servidor');
      n.dispose();
    });

    testWidgets('cambiar de pregunta la guarda y entregar la olvida', (tester) async {
      await montar(tester);
      n.irA(1);
      await tester.pump();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(UltimaPreguntaStorage.clave(BigInt.from(10))), '2');
      final entrega = n.entregar();
      await tester.pump();
      expect(await entrega, isTrue);
      await tester.pump();
      expect(prefs.getString(UltimaPreguntaStorage.clave(BigInt.from(10))), isNull);
      n.dispose();
    });

    testWidgets('una pregunta guardada que ya no está no mueve nada', (tester) async {
      SharedPreferences.setMockInitialValues({UltimaPreguntaStorage.clave(BigInt.from(10)): '999'});
      await montar(tester);
      await tester.pump();
      expect(n.state.actual, 0);
      n.dispose();
    });

    // v5: latido al entrar, al cambiar de pregunta, periódico y al salir de la pestaña.
    testWidgets('latido: al cargar, al cambiar de pregunta y cada intervalo', (tester) async {
      ahora = DateTime(2026, 10, 19, 9);
      repo = RendicionFalsa();
      n = RendicionExamenNotifier(
        repo,
        BigInt.from(10),
        cronometro: CronometroExamen(reloj: () => ahora),
        intervaloLatido: const Duration(seconds: 10),
      );
      await tester.pump();
      expect(repo.latidos.single.codPreguntaH, BigInt.from(1));
      n.irA(2);
      await tester.pump();
      expect(repo.latidos.last.codPreguntaH, BigInt.from(3));
      expect(repo.latidos.last.salioPestana, isFalse);
      final antes = repo.latidos.length;
      await avanzar(tester, const Duration(seconds: 10));
      expect(repo.latidos.length, antes + 1);
      n.dispose();
    });

    testWidgets('salir de la pestaña avisa una vez por salida', (tester) async {
      await montar(tester);
      n.salioDePestana();
      n.salioDePestana(); // blur y visibilitychange de la misma salida
      await tester.pump();
      expect(repo.latidos.where((l) => l.salioPestana), hasLength(1));
      n.dispose();
    });

    testWidgets('el latido sincroniza el cronómetro', (tester) async {
      ahora = DateTime(2026, 10, 19, 9);
      repo = RendicionFalsa()..segundosAlLatido = 900;
      n = RendicionExamenNotifier(repo, BigInt.from(10), cronometro: CronometroExamen(reloj: () => ahora));
      await tester.pump();
      await tester.pump();
      expect(n.state.segundos, 900);
      n.dispose();
    });

    testWidgets('sin examen en curso no hay latidos', (tester) async {
      await montar(tester, estado: 'SIN_INICIAR');
      n.salioDePestana();
      await tester.pump();
      expect(repo.latidos, isEmpty);
      n.dispose();
    });
  });

  // v5: el panel "En vivo" consulta cada N s y se pausa si la pantalla no se ve.
  group('SondeoPeriodico', () {
    testWidgets('consulta cada intervalo, se pausa sin visibilidad y al volver consulta ya', (tester) async {
      var consultas = 0;
      final s = SondeoPeriodico(consultar: () async => consultas++, intervalo: const Duration(seconds: 5))..iniciar();
      await tester.pump(const Duration(seconds: 5));
      expect(consultas, 1);
      await tester.pump(const Duration(seconds: 5));
      expect(consultas, 2);
      s.visible = false;
      await tester.pump(const Duration(seconds: 30));
      expect(consultas, 2, reason: 'no consulta mientras no se ve');
      expect(s.activo, isFalse);
      s.visible = true;
      await tester.pump();
      expect(consultas, 3, reason: 'al volver a verse, enseguida');
      await tester.pump(const Duration(seconds: 5));
      expect(consultas, 4);
      s.detener();
      await tester.pump(const Duration(seconds: 20));
      expect(consultas, 4);
    });

    testWidgets('nunca dos consultas a la vez', (tester) async {
      var enCurso = 0;
      var maximo = 0;
      final s = SondeoPeriodico(
        consultar: () async {
          enCurso++;
          maximo = enCurso > maximo ? enCurso : maximo;
          await Future<void>.delayed(const Duration(seconds: 12));
          enCurso--;
        },
        intervalo: const Duration(seconds: 5),
      )..iniciar();
      await tester.pump(const Duration(seconds: 30));
      expect(maximo, 1);
      s.detener();
      await tester.pump(const Duration(seconds: 15));
    });
  });

  test('reconoce el mensaje de tiempo vencido del backend', () {
    expect(esTiempoVencido(Exception('Se terminó el tiempo: el examen se entregó automáticamente.')), isTrue);
    expect(esTiempoVencido('La opción no es de esa pregunta.'), isFalse);
  });
}
