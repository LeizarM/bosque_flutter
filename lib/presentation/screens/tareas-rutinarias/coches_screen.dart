// Destino final: lib/presentation/screens/tareas-rutinarias/coches_screen.dart
import 'package:bosque_flutter/core/constants/tareas_breakpoints.dart';
import 'package:bosque_flutter/core/state/coches_provider.dart';
import 'package:bosque_flutter/core/theme/tareas_colors.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/utils/formatear_fecha.dart';
import 'package:bosque_flutter/domain/entities/coche_del_dia_entity.dart';
import 'package:bosque_flutter/core/theme/tareas_tema.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/presentation/widgets/tareas-rutinarias/pagina_tareas.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/core/ui/cerrar_ruta.dart';
import 'package:bosque_flutter/presentation/widgets/tareas-rutinarias/tabla_modulo.dart';

/// Reemplaza dlgCoches del legacy. A diferencia de WizardTareas.java (que
/// cerraba la tarea al marcar CUALQUIER coche), aquí el backend
/// (p_coches_marcarLlegada) recién cierra cuando el último coche pendiente
/// queda con respuesta — ver hallazgo de code-review, 2026-09-03.
class CochesScreen extends ConsumerWidget {
  final int idTarRuti;
  final int idBitTarea;
  final String nombreTarea;

  const CochesScreen({
    super.key,
    required this.idTarRuti,
    required this.idBitTarea,
    required this.nombreTarea,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = (idTarRuti: idTarRuti, idBitTarea: idBitTarea);
    final state = ref.watch(cochesProvider(params));
    final notifier = ref.read(cochesProvider(params).notifier);

    ref.listen(cochesProvider(params), (previo, actual) {
      if (actual.tareaCerrada && previo?.tareaCerrada != true) {
        HapticFeedback.mediumImpact();
        mostrarAviso(
          context,
          'Todos los coches quedaron revisados — tarea completada.',
        );
        cerrarRuta(context, true);
      }
      if (actual.mensajeError != null &&
          actual.mensajeError != previo?.mensajeError) {
        HapticFeedback.lightImpact();
        mostrarAviso(context, actual.mensajeError!, tono: TonoAviso.error);
      }
    });

    final revisados = state.items.where((c) => c.yaMarcado).length;
    final total = state.items.length;

    return TareasScope(
      child: Scaffold(
        appBar: AppBarTareas(
          titulo: nombreTarea,
          subtitulo:
              !state.cargado || total == 0
                  ? null
                  : revisados == total
                  ? (total == 1 ? 'El coche está revisado' : 'Los $total coches están revisados')
                  : '$revisados de $total revisados',
          insignia: InsigniaTarea.deTipo(context, 6),
          // El avance como una línea fina bajo el encabezado: se lee de
          // reojo mientras se recorre la lista.
          bottom:
              total == 0
                  ? null
                  : PreferredSize(
                    preferredSize: const Size.fromHeight(4),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: revisados / total),
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOutCubic,
                      builder:
                          (context, value, _) => LinearProgressIndicator(
                            value: value,
                            minHeight: 4,
                            backgroundColor:
                                Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation(
                              TareasColors.realizadoTexto(context),
                            ),
                          ),
                    ),
                  ),
        ),
        body: MargenPaginaTareas(
          abajo: false,
          child: RefreshIndicator(
          onRefresh: notifier.cargar,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child:
                !state.cargado
                    ? (state.cargando
                        ? const Center(
                          key: ValueKey('cargando'),
                          child: CircularProgressIndicator(),
                        )
                        // Un error de lectura no es "no hay coches configurados".
                        : EstadoTareas.error(
                          key: const ValueKey('error'),
                          titulo: 'No se pudo leer los coches del día',
                          error: state.errorCarga,
                          onReintentar: notifier.cargar,
                        ))
                    : state.items.isEmpty
                    ? const EstadoTareas(
                      key: ValueKey('vacio'),
                      icono: Icons.directions_car_outlined,
                      titulo: 'No hay coches activos configurados para tu sucursal',
                    )
                    : _Grilla(
                      key: const ValueKey('lista'),
                      items: state.items,
                      guardandoIdCo: state.guardandoIdCo,
                      onMarcar: (idCo, llego, obs) {
                        HapticFeedback.selectionClick();
                        notifier.marcarLlegada(idCo, llego, obs: obs);
                      },
                    ),
          ),
        ),
        ),
      ),
    );
  }
}

/// La lista de coches: planilla en escritorio, tarjetas en telefono.
///
/// En una resolucion de escritorio esto es una checklist de cinco a diecisiete
/// vehiculos. Como tarjetas ocupaba tres columnas y media pantalla en blanco, y
/// para saber cuales faltaban habia que leer tarjeta por tarjeta. En planilla
/// la columna de estado se lee en vertical de un vistazo, que es exactamente
/// la pregunta que la pantalla tiene que contestar.
class _Grilla extends StatelessWidget {
  final List<CocheDelDiaEntity> items;
  final int? guardandoIdCo;
  final void Function(int idCo, int llego, String? obs) onMarcar;

  const _Grilla({
    super.key,
    required this.items,
    required this.guardandoIdCo,
    required this.onMarcar,
  });

  static const _anchos = <AnchoCol>[
    AnchoCol.flexible(3), // vehiculo
    AnchoCol.fijo(150), // placa
    AnchoCol.flexible(3), // observacion
    AnchoCol.fijo(230), // llego / no llego
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, cajon) {
    // El ancho del cajón y no el de la ventana: el sidebar del dashboard se
    // come 260 px. Sin tope centrado: la planilla usa todo el ancho.
    final esTabla = cajon.maxWidth >= TareasBreakpoints.splitMin;

    if (!esTabla) {
      return ListView.builder(
        padding: const EdgeInsets.only(bottom: Esp.m),
        itemCount: items.length,
        itemBuilder:
            (context, i) => _CocheCard(
              coche: items[i],
              guardando: guardandoIdCo == items[i].idCo,
              onMarcar:
                  (llego, obs) => onMarcar(items[i].idCo, llego, obs),
            ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: Esp.xl),
      children: [
        MarcoTabla(
          child: Column(
            children: [
              const EncabezadoTabla(
                anchos: _anchos,
                titulos: ['Vehículo', 'Placa', 'Observación', 'Estado'],
              ),
              for (var i = 0; i < items.length; i++)
                _FilaTablaCoche(
                  key: ValueKey(items[i].idCo),
                  coche: items[i],
                  anchos: _anchos,
                  rayado: i.isOdd,
                  guardando: guardandoIdCo == items[i].idCo,
                  onMarcar:
                      (llego, obs) => onMarcar(items[i].idCo, llego, obs),
                ),
            ],
          ),
        ),
      ],
    );
      },
    );
  }
}

/// Un vehiculo como fila de planilla.
class _FilaTablaCoche extends StatefulWidget {
  final CocheDelDiaEntity coche;
  final List<AnchoCol> anchos;
  final bool rayado;
  final bool guardando;
  final void Function(int llego, String? obs) onMarcar;

  const _FilaTablaCoche({
    super.key,
    required this.coche,
    required this.anchos,
    required this.rayado,
    required this.guardando,
    required this.onMarcar,
  });

  @override
  State<_FilaTablaCoche> createState() => _FilaTablaCocheState();
}

class _FilaTablaCocheState extends State<_FilaTablaCoche> {
  late final TextEditingController _obsCtrl = TextEditingController(
    text: widget.coche.obs,
  );

  @override
  void dispose() {
    _obsCtrl.dispose();
    super.dispose();
  }

  /// El legacy deja editar la observacion en cualquier momento, aunque ya se
  /// haya contestado si llego (ajax propio, sin relacion con esa respuesta) —
  /// reenvia el `llego` YA guardado, nunca lo pisa.
  void _guardarObs() {
    final llego = widget.coche.llego;
    if (llego == null) return;
    widget.onMarcar(llego, _obsCtrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.coche;
    final scheme = Theme.of(context).colorScheme;
    final marcado = c.yaMarcado;

    final Color? fondo =
        marcado
            ? (c.llego == 1
                    ? TareasColors.realizado(context)
                    : TareasColors.vencido(context))
                .withValues(alpha: 0.28)
            : (widget.rayado
                ? scheme.surfaceContainerHighest.withValues(alpha: 0.3)
                : null);

    return FilaTabla(
      anchos: widget.anchos,
      alineacion: CrossAxisAlignment.start,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      fondo: fondo,
      celdas: [
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.directions_car_filled_outlined,
                    size: 17,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      '${c.marca ?? ''} ${c.clase ?? ''}'.trim().isEmpty
                          ? 'Coche'
                          : '${c.marca ?? ''} ${c.clase ?? ''}'.trim(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              // Lo que hizo OTRO con este mismo coche hoy (archivo SQL 45).
              // Las listas se siembran por ocurrencia: si dos personas abren
              // la pantalla el mismo dia, cada una tiene su copia y no ve la
              // otra. Esto es para que nadie salga a mirar un vehiculo que ya
              // fue revisado.
              if (c.marcadoPorOtro)
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    c.otroCuando == null
                        ? '${c.quienLoMarco} ya lo marco: ${c.queMarcoElOtro}'
                        : '${c.quienLoMarco} ya lo marco: ${c.queMarcoElOtro}'
                            ' (${FormatearFecha.formatearFechaHora(c.otroCuando!)})',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 9),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                c.placa ?? '-',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                '${c.color ?? ''} ${c.anio ?? ''}'.trim(),
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        TextField(
          controller: _obsCtrl,
          maxLines: 1,
          onChanged: (_) => setState(() {}),
          onSubmitted: marcado ? (_) => _guardarObs() : null,
          decoration: InputDecoration(
            isDense: true,
            hintText: 'Observación (opcional)',
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 10,
            ),
            border: const OutlineInputBorder(),
            suffixIcon:
                marcado && _obsCtrl.text.trim() != (c.obs ?? '').trim()
                    ? IconButton(
                      tooltip: 'Guardar observacion',
                      icon: const Icon(Icons.save_outlined, size: 18),
                      // Verde de "hecho": aparece solo cuando hay algo sin
                      // guardar, asi que es una invitacion a confirmar, no un
                      // adorno. En gris se confundia con el icono de un campo.
                      color: TareasColors.realizadoTexto(context),
                      onPressed: _guardarObs,
                    )
                    : null,
          ),
        ),
        widget.guardando
            ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
              ),
            )
            : marcado
            ? Padding(
              padding: const EdgeInsets.only(top: 10),
              child: _ResultadoLlegada(llego: c.llego == 1),
            )
            : _BotonesLlegada(
              onMarcar:
                  (llego) => widget.onMarcar(llego, _obsCtrl.text.trim()),
            ),
      ],
    );
  }
}

class _CocheCard extends StatefulWidget {
  final CocheDelDiaEntity coche;
  final bool guardando;
  final void Function(int llego, String? obs) onMarcar;

  const _CocheCard({
    required this.coche,
    required this.guardando,
    required this.onMarcar,
  });

  @override
  State<_CocheCard> createState() => _CocheCardState();
}

class _CocheCardState extends State<_CocheCard> {
  late final TextEditingController _obsCtrl = TextEditingController(
    text: widget.coche.obs,
  );

  @override
  void dispose() {
    _obsCtrl.dispose();
    super.dispose();
  }

  /// El legacy deja editar la observación en cualquier momento, aunque ya se
  /// haya contestado ¿LLEGÓ? (ajax propio, sin relación con esa respuesta) —
  /// reenvía el `llego` YA guardado (nunca lo pisa) junto con el texto
  /// nuevo, reusando el mismo `onMarcar` que usa el botón SI/NO.
  void _guardarObs() {
    final llego = widget.coche.llego;
    if (llego == null) return;
    widget.onMarcar(llego, _obsCtrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.coche;
    final scheme = Theme.of(context).colorScheme;
    final marcado = c.yaMarcado;

    final Color borderColor =
        marcado
            ? (c.llego == 1
                ? TareasColors.realizado(context)
                : TareasColors.vencido(context))
            : scheme.outlineVariant;
    final Color fillColor =
        marcado
            ? (c.llego == 1
                    ? TareasColors.realizado(context)
                    : TareasColors.vencido(context))
                .withValues(alpha: 0.35)
            : Colors.transparent;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: marcado ? 1.4 : 1),
        color: fillColor,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.directions_car_filled_outlined,
                  color: scheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${c.marca ?? ''} ${c.clase ?? ''}'.trim().isEmpty
                            ? 'Coche'
                            : '${c.marca ?? ''} ${c.clase ?? ''}'.trim(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Placa ${c.placa ?? '—'} · ${c.color ?? ''} ${c.anio ?? ''}'
                            .trim(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Legacy (dlgCoches) tiene una columna FECHA de solo lectura
            // entre ¿LLEGO? y OBSERVACIONES — el backend ya la manda
            // (CocheDelDia.fecha, viva end-to-end) pero la pantalla nunca la
            // pintaba. Con hora: tac_cocheLlegadas.fecha sigue siendo
            // DATETIME hoy (la migración a DATE quedó pendiente de decisión
            // de Marcelo, ver file 29b — truncaría hora real en ~66% de las
            // filas), así que mostrar solo la fecha ocultaría información
            // real que la columna todavía guarda.
            if (c.fecha != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.event_outlined,
                    size: 15,
                    // La fecha de revision es un dato del vehiculo, no una
                    // nota al pie: lleva el color del flujo como el icono del
                    // auto, en vez del gris de los textos secundarios.
                    color: scheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    FormatearFecha.formatearFechaHora(c.fecha!),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
            // Lo que hizo OTRO con este mismo coche hoy (archivo SQL 45).
            //
            // Las listas se siembran por ocurrencia: si dos personas abren la
            // pantalla el mismo día, cada una tiene su copia y no ve la otra.
            // Esto es para que nadie salga a mirar un vehículo que ya fue
            // revisado. NO reemplaza la marca propia: cada uno cierra su tarea
            // con las suyas, y por eso los botones siguen ahí abajo.
            if (c.marcadoPorOtro) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      c.otroLlego == 1
                          ? Icons.how_to_reg_outlined
                          : Icons.person_off_outlined,
                      size: 15,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        c.otroCuando == null
                            ? '${c.quienLoMarco} ya lo marcó como «${c.queMarcoElOtro}».'
                            : '${c.quienLoMarco} ya lo marcó como «${c.queMarcoElOtro}» '
                                '(${FormatearFecha.formatearFechaHora(c.otroCuando!)}).',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            // Editable SIEMPRE, marcado o no — en el legacy la observación
            // no depende de la respuesta ¿LLEGÓ? (ajax propio). Antes aquí se
            // bloqueaba apenas se marcaba, una regresión real frente al
            // legacy.
            TextField(
              controller: _obsCtrl,
              maxLines: 1,
              onChanged: (_) => setState(() {}),
              onSubmitted: marcado ? (_) => _guardarObs() : null,
              decoration: InputDecoration(
                isDense: true,
                labelText: 'Observación (opcional)',
                border: const OutlineInputBorder(),
                suffixIcon:
                    marcado &&
                            _obsCtrl.text.trim() !=
                                (widget.coche.obs ?? '').trim()
                        ? IconButton(
                          tooltip: 'Guardar observación',
                          icon: const Icon(Icons.save_outlined, size: 20),
                          color: TareasColors.realizadoTexto(context),
                          onPressed: _guardarObs,
                        )
                        : null,
              ),
            ),
            const SizedBox(height: 10),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder:
                  (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SizeTransition(
                      sizeFactor: animation,
                      axisAlignment: -1,
                      child: child,
                    ),
                  ),
              child:
                  widget.guardando
                      ? const Padding(
                        key: ValueKey('guardando'),
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.4),
                          ),
                        ),
                      )
                      : marcado
                      ? _ResultadoLlegada(
                        key: const ValueKey('marcado'),
                        llego: c.llego == 1,
                      )
                      : _BotonesLlegada(
                        key: const ValueKey('sinMarcar'),
                        onMarcar:
                            (llego) =>
                                widget.onMarcar(llego, _obsCtrl.text.trim()),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Llegó" o "No llegó", ya respondido. Mismo texto y tono en la tabla y en
/// la tarjeta.
class _ResultadoLlegada extends StatelessWidget {
  final bool llego;

  const _ResultadoLlegada({super.key, required this.llego});

  @override
  Widget build(BuildContext context) {
    final color =
        llego
            ? TareasColors.realizadoTexto(context)
            : TareasColors.vencidoTexto(context);
    return Row(
      children: [
        Icon(llego ? Icons.check_circle : Icons.cancel, size: 18, color: color),
        const SizedBox(width: 6),
        Text(
          llego ? 'Llegó' : 'No llegó',
          style: TextStyle(fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }
}

/// La pregunta de si el coche llegó, con los botones de respuesta del módulo.
///
/// Antes eran dos pares distintos —compactos y sin icono en la tabla, con
/// icono en la tarjeta— y "Llegó" iba relleno con el color del tema. Ahora
/// son los mismos botones que Sí / No en "Mis tareas".
class _BotonesLlegada extends StatelessWidget {
  final void Function(int llego) onMarcar;

  const _BotonesLlegada({super.key, required this.onMarcar});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: BotonRespuestaTareas(
            etiqueta: 'No llegó',
            icono: Icons.close_rounded,
            tono: TareasColors.vencidoTexto(context),
            onPressed: () => onMarcar(0),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: BotonRespuestaTareas(
            etiqueta: 'Llegó',
            icono: Icons.check_rounded,
            tono: TareasColors.realizadoTexto(context),
            onPressed: () => onMarcar(1),
          ),
        ),
      ],
    );
  }
}
