// Destino final: lib/presentation/screens/tareas-rutinarias/caja_fuerte_screen.dart
import 'package:bosque_flutter/core/constants/tareas_breakpoints.dart';
import 'package:bosque_flutter/core/state/caja_fuerte_provider.dart';
import 'package:bosque_flutter/core/theme/tareas_colors.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/utils/formatear_fecha.dart';
import 'package:bosque_flutter/core/utils/formato_moneda.dart';
import 'package:bosque_flutter/domain/entities/llegada_caja_fuerte_entity.dart';
import 'package:bosque_flutter/core/theme/tareas_tema.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/presentation/widgets/tareas-rutinarias/pagina_tareas.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/presentation/widgets/tareas-rutinarias/tabla_modulo.dart';

/// Reemplaza dlgCajaFuerte del legacy ("REPORTAR DINERO PARA CAJA FUERTE").
/// El tipo (cheque/efectivo) es obligatorio en cada fila — el backend
/// rechaza el lote entero si falta en alguna, igual que
/// WizardTareas.guardarCajaFuerte(); aquí se exige antes de poder tocar
/// "Guardar" en vez de dejar mandar y recién avisar.
class CajaFuerteScreen extends ConsumerWidget {
  final int idTarRuti;
  final int idBitTarea;
  final String nombreTarea;

  const CajaFuerteScreen({
    super.key,
    required this.idTarRuti,
    required this.idBitTarea,
    required this.nombreTarea,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cajaFuerteProvider);
    final notifier = ref.read(cajaFuerteProvider.notifier);

    ref.listen(cajaFuerteProvider, (previo, actual) {
      if (actual.filasGuardadas != null &&
          actual.filasGuardadas != previo?.filasGuardadas) {
        HapticFeedback.mediumImpact();
        // Ni PDF ni cierre de la pantalla (Marcelo, 2026-10-05: "que me
        // aparezcan ya los registrados en el día o que me diga algo que fue
        // registrado, y eso del pdf quítalo, no es necesario en esa
        // pantalla"). Lo guardado se ve abajo, en "Registrado hoy", releído
        // del servidor: así se muestra como quedó en la base y no como se
        // escribió.
        //
        // El formulario se limpia: si las filas recién guardadas se quedaran,
        // tocar "Guardar" otra vez registraría lo mismo dos veces.
        final cuantas = actual.filasGuardadas!;
        mostrarAviso(
          context,
          cuantas == 1
              ? 'Registrada, y la tarea quedó completada. La ves abajo, en '
                  '"Registrado hoy".'
              : '$cuantas llegadas registradas, y la tarea quedó completada. '
                  'Las ves abajo, en "Registrado hoy".',
        );
        notifier.limpiarFormulario();
        ref.invalidate(llegadasCajaFuerteDeHoyProvider(idBitTarea));
      }
      if (actual.mensajeError != null &&
          actual.mensajeError != previo?.mensajeError) {
        HapticFeedback.lightImpact();
        mostrarAviso(context, actual.mensajeError!, tono: TonoAviso.error);
      }
    });

    return TareasScope(
      child: Scaffold(
        appBar: AppBarTareas(
          titulo: nombreTarea,
          subtitulo:
              'Dinero que llega a caja fuerte hoy · '
              '${state.filas.length == 1 ? '1 registro' : '${state.filas.length} registros'}',
          insignia: InsigniaTarea.deTipo(context, 4),
          acciones: [
            // Agregar una fila es una accion de la TABLA, no del formulario:
            // va en el encabezado, que no se mueve al crecer la planilla. Al
            // final del todo obligaba a scrollear para cargar el siguiente.
            OutlinedButton.icon(
              onPressed: () {
                HapticFeedback.selectionClick();
                notifier.agregarFila();
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Agregar registro'),
            ),
          ],
        ),
        body: MargenPaginaTareas(
          abajo: false,
          child: LayoutBuilder(
          builder: (context, cajon) {
            // En una resolucion de escritorio esto es una planilla: seis
            // columnas por registro y una fila por cliente. Las tarjetas
            // lado a lado se veian como tres formularios distintos, y para
            // comparar dos importes habia que barrer la pantalla en zig-zag.
            // El ancho del cajón y no el de la ventana (el sidebar se come
            // 260 px). Sin tope centrado: la planilla usa todo el ancho.
            final esTabla = cajon.maxWidth >= TareasBreakpoints.splitMin;

            return ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.only(bottom: Esp.xl),
              children: [
                if (esTabla)
                  MarcoTabla(
                    child: Column(
                      children: [
                        const EncabezadoTabla(
                          anchos: _anchosCajaFuerte,
                          titulos: [
                            'Cliente',
                            'Moneda',
                            'Importe',
                            'Tipo',
                            'Destino',
                            'Observación',
                            '',
                          ],
                          aLaDerecha: {2},
                        ),
                        for (var i = 0; i < state.filas.length; i++)
                          _FilaTablaLlegada(
                            key: ValueKey(state.filas[i].id),
                            fila: state.filas[i],
                            rayado: i.isOdd,
                            puedeQuitar: state.filas.length > 1,
                            onCambio:
                                (actualizar) => notifier.actualizarFila(
                                  state.filas[i].id,
                                  actualizar,
                                ),
                            onQuitar: () {
                              HapticFeedback.selectionClick();
                              notifier.quitarFila(state.filas[i].id);
                            },
                          ),
                      ],
                    ),
                  )
                else
                  for (final fila in state.filas)
                    _FilaAnimada(
                      key: ValueKey(fila.id),
                      child: _FilaLlegada(
                        fila: fila,
                        puedeQuitar: state.filas.length > 1,
                        onCambio:
                            (actualizar) =>
                                notifier.actualizarFila(fila.id, actualizar),
                        onQuitar: () {
                          HapticFeedback.selectionClick();
                          notifier.quitarFila(fila.id);
                        },
                      ),
                    ),
                const SizedBox(height: Esp.l),
                _RegistradasHoy(idBitTarea: idBitTarea, esTabla: esTabla),
              ],
            );
          },
        ),
        ),
        // Guardar cierra la tarea y se hace una sola vez: abajo, fijo, al
        // final del recorrido de lectura. Antes quedaba al final del scroll
        // y con varios registros había que ir a buscarlo.
        bottomNavigationBar: BarraAccionTareas(
          resumen: Text(
            state.filas.length == 1
                ? '1 registro para guardar'
                : '${state.filas.length} registros para guardar',
            style: context.apagado(),
          ),
          accion: FilledButton.icon(
            onPressed:
                state.guardando
                    ? null
                    : () => notifier.registrar(
                      idTarRuti: idTarRuti,
                      idBitTarea: idBitTarea,
                    ),
            icon:
                state.guardando
                    ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    )
                    : const Icon(Icons.check, size: 18),
            label: Text(
              state.guardando ? 'Guardando…' : 'Guardar y cerrar tarea',
            ),
          ),
        ),
      ),
    );
  }
}

/// Los anchos de la planilla de Caja Fuerte. Compartidos por el encabezado y
/// todas las filas: ahi esta la alineacion.
/// Lo que YA quedó registrado hoy, releído del servidor.
///
/// Antes, después de guardar, no quedaba rastro de lo cargado: el formulario
/// volvía a estar vacío y la única señal era un aviso que se va solo (Marcelo,
/// 2026-10-05: "que me aparezcan ya los registrados en el día").
///
/// Es de SOLO LECTURA. Corregir una llegada ya registrada no es trabajo de
/// esta pantalla, y mostrarla editable prometería algo que el backend de este
/// flujo no hace.
class _RegistradasHoy extends ConsumerWidget {
  final int idBitTarea;
  final bool esTabla;

  const _RegistradasHoy({required this.idBitTarea, required this.esTabla});

  String _hora(DateTime? d) =>
      d == null ? '—' : FormatearFecha.formatearHora(d);

  String _texto(String? v) {
    final limpio = v?.trim() ?? '';
    return limpio.isEmpty ? '—' : limpio;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = Theme.of(context);
    final asinc = ref.watch(llegadasCajaFuerteDeHoyProvider(idBitTarea));

    return asinc.when(
      loading:
          () => Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 10),
              Text(
                'Buscando lo registrado hoy…',
                style: tema.textTheme.bodySmall,
              ),
            ],
          ),
      // Un error acá no es un vacío: decirlo y ofrecer reintentar, en vez de
      // dejar la pantalla como si no se hubiera registrado nada.
      error:
          (e, _) => Row(
            children: [
              Icon(
                Icons.error_outline,
                size: 18,
                color: TareasColors.vencidoTexto(context),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'No se pudo leer lo registrado hoy.',
                  style: tema.textTheme.bodySmall,
                ),
              ),
              TextButton(
                onPressed:
                    () => ref.invalidate(
                      llegadasCajaFuerteDeHoyProvider(idBitTarea),
                    ),
                child: const Text('Reintentar'),
              ),
            ],
          ),
      data: (filas) {
        if (filas.isEmpty) {
          return Text(
            'Todavía no hay llegadas registradas hoy.',
            style: tema.textTheme.bodySmall?.copyWith(
              color: tema.colorScheme.onSurfaceVariant,
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: Esp.s, left: 4),
              child: Text(
                filas.length == 1
                    ? 'Registrado hoy · 1 llegada'
                    : 'Registrado hoy · ${filas.length} llegadas',
                style: tema.textTheme.titleSmall,
              ),
            ),
            if (esTabla)
              MarcoTabla(
                child: Column(
                  children: [
                    const EncabezadoTabla(
                      anchos: _anchosRegistradas,
                      titulos: [
                        'Hora',
                        'Cliente',
                        'Importe',
                        'Tipo',
                        'Destino',
                        'Observación',
                      ],
                      aLaDerecha: {2},
                    ),
                    for (final l in filas)
                      FilaTabla(
                        anchos: _anchosRegistradas,
                        borde: Border(
                          top: BorderSide(color: tema.colorScheme.outlineVariant),
                        ),
                        celdas: [
                          Text(_hora(l.hora), style: tema.textTheme.bodySmall),
                          Text(_texto(l.cliente)),
                          Text(
                            FormatoMoneda.conUnidad(l.moneda, l.importe),
                            textAlign: TextAlign.right,
                          ),
                          Text(_texto(l.tipo)),
                          Text(_texto(l.destino)),
                          Text(_texto(l.obs)),
                        ],
                      ),
                  ],
                ),
              )
            else
              for (final l in filas)
                Card(
                  margin: const EdgeInsets.only(bottom: Esp.s),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _texto(l.cliente),
                                style: tema.textTheme.titleSmall,
                              ),
                            ),
                            Text(
                              FormatoMoneda.conUnidad(l.moneda, l.importe),
                              style: tema.textTheme.titleSmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_hora(l.hora)} · ${_texto(l.tipo)} · ${_texto(l.destino)}',
                          style: tema.textTheme.bodySmall?.copyWith(
                            color: tema.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if ((l.obs ?? '').trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(l.obs!.trim(), style: tema.textTheme.bodySmall),
                        ],
                      ],
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }
}

/// Las columnas de la lista de arriba. No se reusan las del formulario: aquí
/// no hay columna para quitar la fila, y sí una de hora.
const _anchosRegistradas = <AnchoCol>[
  AnchoCol.fijo(72), // hora
  AnchoCol.flexible(3), // cliente
  AnchoCol.fijo(132), // importe
  AnchoCol.fijo(120), // tipo
  AnchoCol.flexible(2), // destino
  AnchoCol.flexible(2), // observacion
];

const _anchosCajaFuerte = <AnchoCol>[
  AnchoCol.flexible(3), // cliente
  AnchoCol.fijo(104), // moneda — ver la nota de isExpanded mas abajo
  AnchoCol.fijo(118), // importe
  AnchoCol.fijo(136), // tipo
  AnchoCol.flexible(2), // destino
  AnchoCol.flexible(2), // observacion
  AnchoCol.fijo(40), // quitar
];

/// Un registro como fila de planilla.
///
/// Es el mismo formulario que `_FilaLlegada`, con los campos en linea. Se
/// mantienen los dos: en el telefono una fila de seis columnas no entra, y
/// apilar la planilla la volveria ilegible.
///
/// Los campos usan `isDense` + `TextInputAction.next`, asi que se carga un
/// registro entero con Tab sin soltar el teclado — que es como se llena una
/// planilla de verdad.
class _FilaTablaLlegada extends StatelessWidget {
  final LlegadaCajaFuerteEntity fila;
  final bool rayado;
  final bool puedeQuitar;
  final void Function(LlegadaCajaFuerteEntity Function(LlegadaCajaFuerteEntity))
  onCambio;
  final VoidCallback onQuitar;

  const _FilaTablaLlegada({
    super.key,
    required this.fila,
    required this.rayado,
    required this.puedeQuitar,
    required this.onCambio,
    required this.onQuitar,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    InputDecoration deco(String hint) => InputDecoration(
      isDense: true,
      hintText: hint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      border: const OutlineInputBorder(),
    );

    return FilaTabla(
      anchos: _anchosCajaFuerte,
      alineacion: CrossAxisAlignment.start,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      fondo:
          rayado
              ? scheme.surfaceContainerHighest.withValues(alpha: 0.3)
              : null,
      celdas: [
        TextFormField(
          initialValue: fila.cliente,
          textInputAction: TextInputAction.next,
          decoration: deco('Nombre del cliente'),
          onChanged: (v) => onCambio((f) => f.copyWith(cliente: v)),
        ),
        // `isExpanded` es el arreglo del overflow, no el ancho: sin el, el
        // Dropdown se mide por su item mas largo y desborda la celda apenas la
        // etiqueta no entra (eran 2.1px con "Bolivianos"). Con el, el texto se
        // adapta a la columna. Las etiquetas van cortas igual porque en una
        // planilla con encabezado "Moneda" el nombre completo no agrega nada.
        DropdownButtonFormField<String>(
          value: fila.moneda,
          isDense: true,
          isExpanded: true,
          decoration: deco(''),
          items: const [
            DropdownMenuItem(value: 'BS', child: Text('Bs')),
            DropdownMenuItem(value: 'USD', child: Text(r'$us')),
          ],
          onChanged:
              (v) => onCambio((f) => f.copyWith(moneda: v ?? f.moneda)),
        ),
        TextFormField(
          initialValue: fila.importe?.toString() ?? '',
          textAlign: TextAlign.right,
          textInputAction: TextInputAction.next,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: deco('0.00'),
          onChanged:
              (v) => onCambio(
                (f) => f.copyWith(importe: double.tryParse(v.trim())),
              ),
        ),
        DropdownButtonFormField<String>(
          value: fila.tipo,
          isDense: true,
          isExpanded: true,
          decoration: deco('Elegir'),
          // 'chq'/'efect' son los valores REALES del legacy y no
          // 'CHEQUE'/'EFECTIVO': los dos sistemas escriben la misma columna
          // tac_llegada.tipo.
          items: const [
            DropdownMenuItem(value: 'efect', child: Text('Efectivo')),
            DropdownMenuItem(value: 'chq', child: Text('Cheque')),
          ],
          onChanged: (v) => onCambio((f) => f.copyWith(tipo: v)),
        ),
        TextFormField(
          initialValue: fila.destino,
          textInputAction: TextInputAction.next,
          decoration: deco('Opcional'),
          onChanged: (v) => onCambio((f) => f.copyWith(destino: v)),
        ),
        TextFormField(
          initialValue: fila.obs,
          textInputAction: TextInputAction.next,
          decoration: deco('Opcional'),
          onChanged: (v) => onCambio((f) => f.copyWith(obs: v)),
        ),
        // El boton de quitar se alinea con la primera linea del campo, no con
        // el centro de la fila: si un campo muestra su error la fila crece y
        // el icono quedaria flotando a media altura.
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: IconButton(
            tooltip: puedeQuitar ? 'Quitar este registro' : null,
            onPressed: puedeQuitar ? onQuitar : null,
            icon: const Icon(Icons.delete_outline, size: 20),
            // Rojo, no gris: es el unico control de la fila que destruye algo.
            // Deshabilitado vuelve al gris de siempre, para que "no se puede
            // borrar la ultima fila" se lea sin tener que intentarlo.
            color:
                puedeQuitar
                    ? TareasColors.eliminar(context)
                    : Theme.of(context).colorScheme.outline,
            hoverColor: TareasColors.eliminarFondo(context),
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    );
  }
}

/// Entrada suave para una fila nueva — cero costo cuando ya está en pantalla
/// (el tween arranca y termina de una en el primer frame si no cambió).
class _FilaAnimada extends StatelessWidget {
  final Widget child;

  const _FilaAnimada({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      builder:
          (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, (1 - value) * 12),
              child: child,
            ),
          ),
      child: child,
    );
  }
}

class _FilaLlegada extends StatelessWidget {
  final LlegadaCajaFuerteEntity fila;
  final bool puedeQuitar;
  final void Function(LlegadaCajaFuerteEntity Function(LlegadaCajaFuerteEntity))
  onCambio;
  final VoidCallback onQuitar;

  const _FilaLlegada({
    required this.fila,
    required this.puedeQuitar,
    required this.onCambio,
    required this.onQuitar,
  });

  /// "Tocada" = tiene algún dato cargado. Distingue de una fila recién
  /// agregada y todavía vacía, que no debe leerse como "incompleta" (mismo
  /// criterio que ya usa cajaFuerteProvider.registrar() para no bloquear por
  /// filas que el usuario ni empezó a llenar).
  bool get _tocada =>
      fila.cliente.trim().isNotEmpty ||
      (fila.importe ?? 0) > 0 ||
      fila.tipo != null;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final completa = fila.esValida;
    final incompleta = _tocada && !completa;

    final Color borde =
        incompleta
            ? TareasColors.vencido(context)
            : completa
            ? TareasColors.realizado(context)
            : scheme.outlineVariant;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borde,
          width: incompleta || completa ? 1.4 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child:
                      completa
                          ? Icon(
                            Icons.check_circle,
                            key: const ValueKey('ok'),
                            size: 18,
                            color: TareasColors.realizadoTexto(context),
                          )
                          : incompleta
                          ? Icon(
                            Icons.error_outline,
                            key: const ValueKey('falta'),
                            size: 18,
                            color: TareasColors.vencidoTexto(context),
                          )
                          : const SizedBox(
                            key: ValueKey('vacio'),
                            width: 18,
                            height: 18,
                          ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    completa
                        ? 'Lista'
                        : (incompleta ? 'Falta completar' : 'Nuevo registro'),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color:
                          incompleta
                              ? TareasColors.vencidoTexto(context)
                              : completa
                              ? TareasColors.realizadoTexto(context)
                              : scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (puedeQuitar)
                  IconButton(
                    tooltip: 'Quitar este registro',
                    onPressed: onQuitar,
                    icon: const Icon(Icons.delete_outline, size: 20),
                    color: TareasColors.eliminar(context),
                    hoverColor: TareasColors.eliminarFondo(context),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            TextFormField(
              initialValue: fila.cliente,
              decoration: const InputDecoration(
                labelText: 'Cliente',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
              onChanged: (v) => onCambio((f) => f.copyWith(cliente: v)),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: fila.moneda,
                    decoration: const InputDecoration(
                      labelText: 'Moneda',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'BS', child: Text('Bolivianos (Bs)')),
                      DropdownMenuItem(value: 'USD', child: Text(r'Dólares ($us)')),
                    ],
                    onChanged: (v) => onCambio((f) => f.copyWith(moneda: v)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    initialValue: fila.importe?.toString(),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Importe',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.next,
                    onChanged:
                        (v) => onCambio(
                          (f) => f.copyWith(importe: double.tryParse(v)),
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: fila.tipo,
              decoration: InputDecoration(
                labelText: 'Tipo',
                isDense: true,
                border: const OutlineInputBorder(),
                // Sin helperText de "Obligatorio": el tipo arranca en Efectivo,
                // así que nunca llega vacío y el aviso no podía dispararse.
              ),
              // Valores 'chq'/'efect' — EXACTOS al legacy (Tareas.xhtml), no
              // 'CHEQUE'/'EFECTIVO': misma columna tac_llegada.tipo que
              // escribe el sistema anterior. Solo la etiqueta visible es
              // libre.
              items: const [
                DropdownMenuItem(value: 'efect', child: Text('Efectivo')),
                DropdownMenuItem(value: 'chq', child: Text('Cheque')),
              ],
              onChanged: (v) => onCambio((f) => f.copyWith(tipo: v)),
            ),
            const SizedBox(height: 10),
            TextFormField(
              initialValue: fila.destino,
              decoration: const InputDecoration(
                labelText: 'Destino (opcional)',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
              onChanged: (v) => onCambio((f) => f.copyWith(destino: v)),
            ),
            const SizedBox(height: 10),
            TextFormField(
              initialValue: fila.obs,
              decoration: const InputDecoration(
                labelText: 'Observación (opcional)',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.done,
              onChanged: (v) => onCambio((f) => f.copyWith(obs: v)),
            ),
          ],
        ),
      ),
    );
  }
}
