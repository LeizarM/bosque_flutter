/// Agregar una bobina al material de ingreso de un lote ya registrado.
///
/// Lo que se comprueba no es que la lista crezca —eso es evidente— sino las dos
/// cosas que se pueden romper sin que se note: que los totales del detalle se
/// muevan solos con la fila nueva, y que la cabecera que viaja al guardar salga
/// recalculada y no con los números que trajo el listado.
library;

import 'package:bosque_flutter/core/state/ver_lote_produccion_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/repositorio_lote_produccion.dart';

const _params = (idLp: 7, audUsuario: 33);

void main() {
  late RepositorioLoteProduccion repo;
  late ProviderContainer contenedor;

  /// Un lote con tres bobinas de 100 kg y 99 de balanza.
  Future<DetalleLoteNotifier> abrirDetalle() async {
    repo = RepositorioLoteProduccion(
      ingresos: [
        bobina(idMi: 1, pesoKilos: 100, balanza: 99),
        bobina(idMi: 2, pesoKilos: 100, balanza: 99),
        bobina(idMi: 3, pesoKilos: 100, balanza: 99),
      ],
    );
    contenedor = ProviderContainer(
      overrides: [loteProduccionRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(contenedor.dispose);

    // El provider es autoDispose: sin alguien escuchando, el notifier se
    // destruye apenas termina el `read` y todo lo que venga despues explota.
    contenedor.listen(detalleLoteProvider(_params), (_, _) {});
    final notifier = contenedor.read(detalleLoteProvider(_params).notifier);
    // El constructor ya dispara `cargar()`, pero no devuelve nada que esperar:
    // se lo vuelve a pedir para tener el detalle cargado antes de seguir.
    await notifier.cargar();
    notifier.setLote(loteDePrueba());
    return notifier;
  }

  DetalleLoteState estado() => contenedor.read(detalleLoteProvider(_params));

  test('agregar una bobina la deja en blanco y lista para insertar', () async {
    final notifier = await abrirDetalle();
    expect(estado().ingresos, hasLength(3));

    notifier.agregarIngreso();

    expect(estado().ingresos, hasLength(4));
    final nueva = estado().ingresos.last;
    // idMi 0 es lo que hace que el backend inserte en vez de actualizar.
    expect(nueva.idMi, 0);
    expect(nueva.idLp, _params.idLp);
    expect(nueva.audUsuario, _params.audUsuario);
    expect(nueva.pesoKilos, 0);
    expect(nueva.balanza, 0);
  });

  test('los totales del detalle se mueven con la fila nueva', () async {
    final notifier = await abrirDetalle();
    expect(estado().totalPesoIngreso, 300);
    expect(estado().totalBalanza, 297);
    expect(estado().difProduccion, 300);

    // Agregarla sin cargarle nada no inventa kilos.
    notifier.agregarIngreso();
    expect(estado().ingresos, hasLength(4));
    expect(estado().totalPesoIngreso, 300);

    // Y cargarle el peso los suma sin que nadie recalcule a mano.
    notifier.editarIngreso(3, pesoKilos: 120, balanza: 118);
    expect(estado().totalPesoIngreso, 420);
    expect(estado().totalBalanza, 415);
    expect(estado().difProduccion, 420);
  });

  test('quitar solo alcanza a las bobinas que todavia no se guardaron', () async {
    final notifier = await abrirDetalle();

    notifier.agregarIngreso();
    notifier.editarIngreso(3, pesoKilos: 120);
    expect(estado().totalPesoIngreso, 420);

    // La nueva se va y el total vuelve atras.
    notifier.quitarIngreso(3);
    expect(estado().ingresos, hasLength(3));
    expect(estado().totalPesoIngreso, 300);

    // Una que ya esta en la base no se toca: el backend no tiene baja.
    notifier.quitarIngreso(0);
    expect(estado().ingresos, hasLength(3));
    expect(estado().ingresos.first.idMi, 1);

    // Un indice fuera de rango tampoco explota.
    notifier.quitarIngreso(9);
    expect(estado().ingresos, hasLength(3));
  });

  test('al guardar viaja la fila nueva y la cabecera recalculada', () async {
    final notifier = await abrirDetalle();

    notifier.agregarIngreso();
    notifier.editarIngreso(3, pesoKilos: 120, balanza: 118);

    expect(await notifier.guardar(), isNull);

    // El detalle: cuatro filas, y la nueva sigue con idMi 0 para que se inserte.
    expect(repo.ingresosGuardados, hasLength(4));
    expect(repo.ingresosGuardados!.last.idMi, 0);
    expect(repo.ingresosGuardados!.last.pesoKilos, 120);

    // La cabecera: contada y sumada de nuevo, no la que trajo el listado.
    final cabecera = repo.cabeceraGuardada!;
    expect(cabecera.cantBobinasIngresoTotal, 4);
    expect(cabecera.pesoKilosTotalIngreso, 420);
    expect(cabecera.pesoBalanzaTotal, 415);
    expect(cabecera.diferenciaProduccion, 420);
  });
}
