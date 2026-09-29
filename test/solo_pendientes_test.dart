// "Mis tareas rutinarias" muestra SOLO lo que falta hacer (2026-09-08).
//
// Marcelo: "las tareas rutinarias que ya se completaron/finalizaron/hicieron
// que ya no se muestren (solo en reporte por ahora) para dar paso a las nuevas
// que se van a ir generando".
//
// El riesgo de este cambio no es visual: es que alguien vuelva a contar como
// pendiente algo ya respondido. `fueRealizado` tiene CUATRO valores y solo dos
// significan "sin responder" — y el `0` ya causó exactamente ese bug una vez
// ("el filtro no está funcionando", 2026-09-07): responder **No** se guarda
// como 0, y durante un tiempo se leyó como pendiente.
import 'package:bosque_flutter/domain/entities/bit_tarea_ruti_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  BitTareaRutiEntity tarea(int? fueRealizado) => BitTareaRutiEntity(
    idBitTarea: 1,
    nombreTareaRutinaria: 'Revisar bandeja de correo',
    fechaPresentacion: DateTime(2026, 9, 8),
    fueRealizado: fueRealizado,
    audUsuario: 0,
  );

  // La misma regla que aplica la pantalla.
  bool sinResponder(BitTareaRutiEntity t) =>
      t.fueRealizado == null || t.fueRealizado == 12;

  group('qué sigue estando pendiente', () {
    test('12 y null son las únicas pendientes', () {
      expect(sinResponder(tarea(12)), isTrue, reason: '12 = en curso');
      expect(sinResponder(tarea(null)), isTrue, reason: 'nunca tocada');
    });

    test('responder Sí la saca de la lista', () {
      expect(sinResponder(tarea(13)), isFalse);
    });

    test('responder NO también la saca — este es el que se escapa', () {
      // 0 es "No", no "sin dato". Es el valor que rompió el filtro anterior.
      expect(
        sinResponder(tarea(0)),
        isFalse,
        reason:
            'Responder "No" es responder. Si vuelve a contar como pendiente, '
            'la tarea reaparece todos los días y nunca se puede cerrar.',
      );
    });

    test('"No aplica" también la saca', () {
      expect(sinResponder(tarea(14)), isFalse);
    });
  });

  test('de una lista mezclada solo sobreviven las dos sin responder', () {
    final todas = [
      tarea(12),
      tarea(13),
      tarea(0),
      tarea(14),
      tarea(null),
    ];
    expect(todas.where(sinResponder).length, 2);
  });
}
