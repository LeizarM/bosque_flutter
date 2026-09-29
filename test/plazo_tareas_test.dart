// El plazo para responder una tarea rutinaria (2026-09-11).
//
// Marcelo, mirando "Mis tareas rutinarias": "las vencidas, ya no debería poder
// hacerlos porque ya pasaron el plazo". El sistema anterior tampoco las dejaba
// —las escondía de la consulta, en p_list_tarRuCargo— y la migración perdió esa
// regla: de ahí salen 70.635 ocurrencias vencidas todavía abiertas.
//
// Lo que se prueba aquí es el criterio, que ANTES estaba copiado en tres
// lugares del cliente, cada copia comparando contra el reloj del dispositivo y
// con un comentario avisando que tenían que quedar idénticas. Ahora vive en un
// solo método que recibe el día: por eso estas pruebas pueden fijar una fecha
// en vez de depender de cuándo se ejecutan.
import 'package:bosque_flutter/domain/entities/bit_tarea_ruti_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  BitTareaRutiEntity tarea({
    DateTime? presentacion,
    DateTime? limite,
    int? diasPlazo,
  }) => BitTareaRutiEntity(
    idBitTarea: 1,
    nombreTareaRutinaria: 'Arqueo de Caja',
    fechaPresentacion: presentacion ?? DateTime(2026, 9, 8),
    fechaLimite: limite,
    diasPlazo: diasPlazo,
    fueRealizado: 12,
    audUsuario: 0,
  );

  group('hasta cuándo acepta respuesta', () {
    test('con plazo 0 vence ese mismo día', () {
      // Lo que hacía el sistema anterior con las diarias: fechaPresentacion =
      // CAST(GETDATE() AS DATE), ni un día más.
      final t = tarea(limite: DateTime(2026, 9, 8), diasPlazo: 0);

      expect(t.fueraDePlazo(DateTime(2026, 9, 8)), isFalse);
      expect(t.fueraDePlazo(DateTime(2026, 9, 9)), isTrue);
    });

    test('el día de vencimiento cuenta entero, hasta la última hora', () {
      // El error que este criterio evita: comparar una fecha sin hora contra un
      // instante marca la tarea vencida desde su propia medianoche, horas antes
      // de que el día termine.
      final t = tarea(limite: DateTime(2026, 9, 8), diasPlazo: 0);

      expect(t.fueraDePlazo(DateTime(2026, 9, 8, 23, 59)), isFalse);
    });

    test('con plazo de dos días se puede responder dos días después', () {
      final t = tarea(limite: DateTime(2026, 9, 10), diasPlazo: 2);

      expect(t.fueraDePlazo(DateTime(2026, 9, 10)), isFalse);
      expect(t.fueraDePlazo(DateTime(2026, 9, 11)), isTrue);
    });

    test('una tarea futura no está vencida', () {
      final t = tarea(
        presentacion: DateTime(2026, 12, 1),
        limite: DateTime(2026, 12, 1),
      );

      expect(t.fueraDePlazo(DateTime(2026, 9, 11)), isFalse);
    });
  });

  group('cuando el backend todavía no manda el plazo', () {
    test('se cae a fechaPresentacion, que es el plazo estricto', () {
      // Una versión del backend anterior al archivo SQL 65 no manda
      // fechaLimite. No se inventa margen: vale la fecha de presentación.
      final t = tarea(presentacion: DateTime(2026, 9, 8), limite: null);

      expect(t.venceEl, DateTime(2026, 9, 8));
      expect(t.fueraDePlazo(DateTime(2026, 9, 9)), isTrue);
    });

    test('sin ninguna fecha no se da por vencida', () {
      // Falla hacia el lado seguro: preferible dejar responder una ocurrencia
      // sin fecha que bloquear a alguien por un dato que falta.
      final t = BitTareaRutiEntity(idBitTarea: 1, audUsuario: 0);

      expect(t.venceEl, isNull);
      expect(t.fueraDePlazo(DateTime(2026, 9, 11)), isFalse);
    });
  });

  test('el plazo de la base manda sobre la fecha de presentación', () {
    // fechaLimite no se recalcula en el cliente: si la base dice que esta
    // ocurrencia vence el 10, vence el 10, aunque se presentara el 8.
    final t = tarea(
      presentacion: DateTime(2026, 9, 8),
      limite: DateTime(2026, 9, 10),
      diasPlazo: 2,
    );

    expect(t.venceEl, DateTime(2026, 9, 10));
    expect(t.fueraDePlazo(DateTime(2026, 9, 9)), isFalse);
  });
}
