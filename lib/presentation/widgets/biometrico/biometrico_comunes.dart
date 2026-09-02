/// Piezas compartidas por las pestañas del módulo Biométrico.
///
/// Mismo criterio que `permisos_rrhh_comunes.dart`: el color y el espaciado
/// salen de `core/ui/`, acá sólo lo que es propio de este módulo.
library;

import 'package:bosque_flutter/core/state/biometrico_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart' as compartido;
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'package:bosque_flutter/core/ui/aviso.dart';
export 'package:bosque_flutter/core/ui/piezas_bosque.dart';
export 'package:bosque_flutter/core/ui/tokens_bosque.dart';

const nombresMeses = [
  'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
  'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
];

/// Estilo para los `IconButton` de acción (actualizar, descargar PDF,
/// chevrons de mes) — reemplaza `IconButton.filled`/`.filledTonal`.
///
/// **Por qué no las variantes de Material 3 directas.** `.filledTonal` usa
/// `secondaryContainer` — una de las dos familias que `colorDeAsistencia`
/// (acá mismo, en `tokens_bosque.dart`) evita a propósito, porque no
/// sobrevive bien a las nueve semillas de `colorList` (`app_theme.dart`) ni
/// a los dos modos: con la semilla verde en oscuro sale un verde oliva
/// apagado, casi sin contraste contra un fondo ya casi negro — "se ve
/// horrible". `.filled` (`cs.primary` a pleno) es la otra punta del mismo
/// problema: un punto verde brillante y suelto, gaudy contra tanto negro
/// alrededor.
///
/// Este estilo usa el mismo truco que ya usa el calendario para las celdas
/// (`_CeldaDia`, `colorDeAsistencia`): `primary` — la única familia
/// garantizada en las nueve semillas — atenuado sobre `cs.surface`, nunca a
/// pleno. Se adapta solo a claro/oscuro porque `cs.surface` ya lo hace.
ButtonStyle estiloBotonAccion(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  final fondo = Color.alphaBlend(cs.primary.withValues(alpha: 0.14), cs.surface);
  return IconButton.styleFrom(
    backgroundColor: fondo,
    foregroundColor: cs.primary,
    disabledForegroundColor: cs.onSurface.withValues(alpha: 0.38),
  );
}

/// Cuenta un error, ya traducido al idioma de quien usa la app. Va por el
/// Overlay raíz — nunca `ScaffoldMessenger` — para no quedar tapado por un
/// diálogo o una hoja modal.
void avisarError(BuildContext context, Object error) =>
    compartido.avisar(context, textoDeError(error), esError: true);

String textoDeError(Object error) {
  final texto = error.toString();
  return texto.startsWith('Exception: ') ? texto.substring(11) : texto;
}

/// Pregunta antes de una escritura que importa, y dice exactamente qué va a
/// pasar. Mismo patrón que `permisos-rrhh`/`rol-sabados`.
Future<bool> confirmar(
  BuildContext context, {
  required String titulo,
  required String mensaje,
  required String accion,
  bool destructiva = false,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) {
      final cs = Theme.of(c).colorScheme;
      return AlertDialog(
        title: Text(titulo),
        content: SingleChildScrollView(child: Text(mensaje)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style:
                destructiva
                    ? FilledButton.styleFrom(
                      backgroundColor: cs.error,
                      foregroundColor: cs.onError,
                    )
                    : null,
            onPressed: () => Navigator.pop(c, true),
            child: Text(accion),
          ),
        ],
      );
    },
  );
  return ok ?? false;
}

/// `HH:mm`, o `--:--` si no hay hora. `fechaCorta` (dd/MM/yyyy) ya viene de
/// `piezas_bosque.dart`, reexportado arriba.
String horaCorta(DateTime? h) =>
    h == null
        ? '--:--'
        : '${h.hour.toString().padLeft(2, '0')}:${h.minute.toString().padLeft(2, '0')}';

/// El mismo formato `dd/MM/yyyy HH:mm:00.00` que arma el SP internamente a
/// partir de CHECKTIME — hace falta como filtro exacto para 'D'/'U' de una
/// marcación adicional, que buscan por `fechaString`, no por `CHECKTIME`.
String fechaStringBiometrico(DateTime? f) {
  if (f == null) return '';
  String p2(int n) => n.toString().padLeft(2, '0');
  return '${p2(f.day)}/${p2(f.month)}/${f.year} ${p2(f.hour)}:${p2(f.minute)}:00.00';
}

/// El diálogo "Registrar marcación olvidada" — compartido entre la pestaña
/// Marcaciones Olvidadas y el detalle de un día del calendario de Reporte
/// (mismo flujo, dos puntos de entrada: uno para cargar en lote, otro para
/// corregir un día puntual que se está mirando).
Future<void> registrarMarcacionOlvidada(
  BuildContext context,
  WidgetRef ref, {
  required int userId,
  required int codEmpleado,
  DateTime? fechaSugerida,
}) async {
  DateTime fecha = fechaSugerida ?? DateTime.now();
  TimeOfDay hora = TimeOfDay.now();
  final motivoCtrl = TextEditingController();

  final ok = await showDialog<bool>(
    context: context,
    builder:
        (c) => StatefulBuilder(
          builder:
              (c, setState) => AlertDialog(
                title: const Text('Registrar marcación olvidada'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () async {
                        final f = await showDatePicker(
                          context: c,
                          initialDate: fecha,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (f != null) setState(() => fecha = f);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Fecha'),
                        child: Text(fechaCorta(fecha)),
                      ),
                    ),
                    const SizedBox(height: Esp.m),
                    InkWell(
                      onTap: () async {
                        final h = await showTimePicker(context: c, initialTime: hora);
                        if (h != null) setState(() => hora = h);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Hora'),
                        child: Text(hora.format(c)),
                      ),
                    ),
                    const SizedBox(height: Esp.m),
                    TextField(
                      controller: motivoCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Motivo',
                        hintText: 'Por qué se registra a mano — p.ej. "Olvidó marcar salida"',
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(c, false),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(c, true),
                    child: const Text('Registrar'),
                  ),
                ],
              ),
        ),
  );
  if (ok != true || !context.mounted) return;

  final checkTime = DateTime(
    fecha.year,
    fecha.month,
    fecha.day,
    hora.hour,
    hora.minute,
  );

  try {
    await ref.read(biometricoRepositoryProvider).registrarMarcacionAdicional({
      'USERID': userId,
      'CHECKTIME': checkTime.toIso8601String(),
      'CODEMPLEADO': codEmpleado,
      'fechaString': fechaStringBiometrico(checkTime),
    }, 'I', motivo: motivoCtrl.text);
    ref.invalidate(bioCheckInOutAdicionalListProvider(userId));
    if (context.mounted) compartido.avisar(context, 'Marcación registrada.');
  } catch (e) {
    if (context.mounted) avisarError(context, e);
  }
}

/// **"Quién y por qué"** — el historial de UNA fila puntual (una marcación
/// olvidada, una asignación de horario, una plantilla de turno...), leído de
/// `tbio_bioBitacora`. Compartido por Marcaciones olvidadas y las 3 tablas de
/// Horarios: mismo mecanismo, sólo cambia qué `tabla`/`idRegistro` se le pasa
/// — ver `sql/03_bitacora_biometrico.sql` para cómo se arma cada `idRegistro`.
Future<void> mostrarHistorialBitacora(
  BuildContext context, {
  required String tabla,
  required String idRegistro,
  String titulo = 'Historial de cambios',
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder:
      (_) => _HistorialBitacoraSheet(
        tabla: tabla,
        idRegistro: idRegistro,
        titulo: titulo,
      ),
);

class _HistorialBitacoraSheet extends ConsumerWidget {
  const _HistorialBitacoraSheet({
    required this.tabla,
    required this.idRegistro,
    required this.titulo,
  });
  final String tabla;
  final String idRegistro;
  final String titulo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(
      bitacoraBiometricoProvider((tabla: tabla, idRegistro: idRegistro)),
    );

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Esp.l, 0, Esp.l, Esp.l),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo, style: context.tituloSeccion()),
              const SizedBox(height: Esp.s),
              Flexible(
                child: async.when(
                  loading:
                      () => const Padding(
                        padding: EdgeInsets.all(Esp.xl),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                  error:
                      (e, _) => MensajeVacio(
                        icono: Icons.error_outline,
                        titulo: 'No se pudo cargar el historial',
                        detalle: textoDeError(e),
                      ),
                  data: (lista) {
                    if (lista.isEmpty) {
                      return const MensajeVacio(
                        icono: Icons.history,
                        titulo: 'Sin historial',
                        detalle: 'Todavía no hay cambios registrados para esto.',
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: lista.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final h = lista[i];
                        final tieneMotivo =
                            h.motivo != null && h.motivo!.trim().isNotEmpty;
                        return ListTile(
                          leading: Icon(_iconoDeAccion(h.accion)),
                          title: Text(
                            '${_accionLegible(h.accion)} — ${h.nombreUsuario}',
                          ),
                          subtitle: Text(
                            [
                              if (tieneMotivo) h.motivo!,
                              '${fechaCorta(h.audFecha)} ${horaCorta(h.audFecha)}',
                            ].join(' · '),
                          ),
                          isThreeLine: tieneMotivo,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _accionLegible(String accion) => switch (accion) {
  'I' => 'Creado',
  'U' => 'Editado',
  'D' => 'Eliminado',
  'A' => 'Inactivado',
  'E' => 'Reiniciado',
  _ => accion,
};

IconData _iconoDeAccion(String accion) => switch (accion) {
  'I' => Icons.add_circle_outline,
  'U' => Icons.edit_outlined,
  'D' => Icons.delete_outline,
  'A' => Icons.pause_circle_outline,
  'E' => Icons.restart_alt,
  _ => Icons.circle_outlined,
};
