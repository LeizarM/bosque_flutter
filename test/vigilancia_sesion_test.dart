import 'package:bosque_flutter/presentation/widgets/shared/vigilancia_sesion.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Chequeo periódico de la sesión: cada dos minutos con la app a la vista, nada mientras
/// está oculta y en el acto al volver. Que el reloj muera con el widget ya lo exige
/// flutter_test, que falla si queda un Timer pendiente al desmontar.
void main() {
  late int chequeos;

  Future<void> montar(WidgetTester tester) async {
    chequeos = 0;
    await tester.pumpWidget(
      VigilanciaSesion(
        verificar: () async {
          chequeos++;
        },
        child: const SizedBox(),
      ),
    );
  }

  void cambiarCiclo(WidgetTester tester, List<AppLifecycleState> estados) {
    for (final estado in estados) {
      tester.binding.handleAppLifecycleStateChanged(estado);
    }
  }

  testWidgets('consulta cada dos minutos mientras la app está a la vista', (tester) async {
    await montar(tester);
    expect(chequeos, 0);

    await tester.pump(VigilanciaSesion.intervalo);
    expect(chequeos, 1);
    await tester.pump(VigilanciaSesion.intervalo);
    expect(chequeos, 2);
  });

  testWidgets('oculta no consulta y al volver revisa en el acto', (tester) async {
    await montar(tester);

    cambiarCiclo(tester, [AppLifecycleState.inactive, AppLifecycleState.hidden]);
    await tester.pump(VigilanciaSesion.intervalo * 3);
    expect(chequeos, 0);

    cambiarCiclo(tester, [AppLifecycleState.inactive, AppLifecycleState.resumed]);
    expect(chequeos, 1);
    await tester.pump(VigilanciaSesion.intervalo);
    expect(chequeos, 2);
  });
}
