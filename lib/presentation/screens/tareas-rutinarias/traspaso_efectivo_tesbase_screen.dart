// Destino final: lib/presentation/screens/tareas-rutinarias/traspaso_efectivo_tesbase_screen.dart
import 'package:bosque_flutter/core/constants/tareas_breakpoints.dart';
import 'package:bosque_flutter/core/state/traspaso_efectivo_tesbase_provider.dart';
import 'package:bosque_flutter/core/theme/tareas_colors.dart';
import 'package:bosque_flutter/core/theme/tareas_tema.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/cerrar_ruta.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/core/utils/formatear_fecha.dart';
import 'package:bosque_flutter/domain/entities/traspaso_efectivo_tesbase_entity.dart';
import 'package:bosque_flutter/presentation/widgets/tareas-rutinarias/pagina_tareas.dart';
import 'package:bosque_flutter/presentation/widgets/tareas-rutinarias/tabla_modulo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tarea 289 — "Verificar Traspaso de Efectivo Entre Sistemas" (idATR 11).
///
/// Es TesBase, de tesorería: cuando un cliente pasa efectivo de una base a
/// otra, Cobranza lo registra en el sistema anterior (vista 102) y la
/// transferencia nace PENDIENTE. Esta tarea es verificar que el efectivo pasó
/// y cerrarla.
///
/// **No confundir con Caja AXA** ([TraspasoEntreSistemasScreen], idATR 12). Los
/// nombres casi iguales ya costaron un archivo SQL de vuelta atrás (el 51).
///
/// **Qué día revisa.** La ocurrencia del día D revisa lo que se registró el día
/// hábil anterior (Marcelo, 2026-09-11: "tiene que aparecer de un día anterior
/// por defecto y si es feriado, domingo o lunes, de dos días antes"). Lo
/// calcula el servidor con los feriados de la sucursal (archivo SQL 58). La
/// pantalla abre ese día, dice por qué es ese y deja mirar otro; "Sin
/// pendientes" siempre cuenta hasta el día revisado. Las pendientes de días
/// anteriores se muestran arriba aunque se mire otro día: son las más
/// atrasadas.
///
/// **Lo que cambia respecto del sistema anterior.** Allá, cambiar el estado de
/// la transferencia no cerraba la tarea, y la 289 juntó 1372 ocurrencias sin
/// responder. Aquí se cierran las pendientes una por una y, cuando no queda
/// ninguna, "Sin pendientes" deja constancia del día. El servidor vuelve a
/// contar antes de aceptar.
///
/// Solo se migró la verificación. El registro sigue en el sistema anterior
/// hasta que se migre Cobranza.
class TraspasoEfectivoTesBaseScreen extends ConsumerWidget {
  final int idBitTarea;
  final String nombreTarea;

  /// La fecha de la ocurrencia según la tarjeta de "Mis tareas". Se muestra
  /// solo hasta que responde el servidor.
  final DateTime fecha;

  const TraspasoEfectivoTesBaseScreen({
    super.key,
    required this.idBitTarea,
    required this.nombreTarea,
    required this.fecha,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = traspasoEfectivoTesBaseProvider(idBitTarea);
    final state = ref.watch(provider);
    final notifier = ref.read(provider.notifier);

    ref.listen(provider, (previo, actual) {
      if (actual.error != null && actual.error != previo?.error) {
        mostrarAviso(context, actual.error!, tono: TonoAviso.error);
      }
      if (actual.aviso != null && actual.aviso != previo?.aviso) {
        mostrarAviso(context, actual.aviso!, tono: TonoAviso.exito);
      }
    });

    final revisado = state.diaRevisado;
    final faltan = state.pendientesHastaElDiaRevisado.length;
    final contexto = [
      'Tarea del ${_conDia(revisado?.fechaTarea ?? fecha)}',
      if (state.cargado && faltan > 0)
        faltan == 1 ? '1 por cerrar' : '$faltan por cerrar',
    ].join(' · ');

    return TareasScope(
      child: Scaffold(
        appBar: AppBarTareas(
          titulo: nombreTarea,
          subtitulo: contexto,
          insignia: InsigniaTarea.deTipo(context, 11),
          acciones: [
            IconButton(
              tooltip: 'Volver a consultar',
              icon: const Icon(Icons.refresh),
              onPressed: state.cargando ? null : notifier.cargar,
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            // Estirada: si no, la barra del día medía lo que su texto y
            // quedaba como una isla gris en el medio de la pantalla.
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (revisado != null && state.dia != null)
                _BarraDia(
                  revisado: revisado,
                  dia: state.dia!,
                  mirandoElRevisado: state.mirandoElDiaRevisado,
                  onElegir: () => _elegirDia(context, ref),
                  onVolver: () => notifier.verDia(revisado.fechaRevisada),
                ),
              Expanded(
                child: MargenPaginaTareas(
                  // El ancho del cajón, no el de la ventana: el sidebar del
                  // dashboard se come 260 px.
                  child: LayoutBuilder(
                    builder:
                        (context, cajon) => _cuerpo(
                          context,
                          ref,
                          state,
                          cajon.maxWidth >= TareasBreakpoints.wideMax,
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar:
            state.cargado
                ? _BarraCierre(
                  revisado: revisado,
                  faltan: faltan,
                  cerrandoDia: state.cerrandoDia,
                  onSinPendientes: () => _darDiaPorRevisado(context, ref),
                )
                : null,
      ),
    );
  }

  Widget _cuerpo(
    BuildContext context,
    WidgetRef ref,
    TraspasoEfectivoTesBaseState state,
    bool enTabla,
  ) {
    final notifier = ref.read(
      traspasoEfectivoTesBaseProvider(idBitTarea).notifier,
    );

    if (!state.cargado) {
      // Una lectura fallida NO cae en "no hay pendientes": ese estado habilita
      // dar el día por revisado, y no se puede afirmar sin haber leído.
      return state.cargando
          ? const Center(child: CircularProgressIndicator())
          : EstadoTareas.error(
            titulo: 'No se pudo leer las transferencias.',
            detalle: 'Hasta leerlas no se puede dar el día por revisado.',
            onReintentar: notifier.cargar,
          );
    }

    final dia = state.dia!;
    if (state.cargandoDia) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!state.diaLeido) {
      return EstadoTareas.error(
        titulo: 'No se pudo leer las transferencias del ${_conDia(dia)}.',
        onReintentar: () => notifier.verDia(dia),
      );
    }

    final anteriores = state.pendientesAnteriores;
    if (anteriores.isEmpty && state.delDia.isEmpty) {
      final listo = state.mirandoElDiaRevisado && state.puedeCerrarDia;
      return EstadoTareas(
        icono: listo ? Icons.task_alt : Icons.event_busy_outlined,
        tono: listo ? TonoEstadoTareas.listo : TonoEstadoTareas.neutro,
        titulo: 'No se registraron transferencias el ${_conDia(dia)}',
        detalle:
            listo
                ? 'Aun así hay que dejar constancia de que revisaste. Sin '
                    'eso, en la bitácora este día se ve igual que uno que '
                    'nadie miró.'
                : null,
      );
    }

    return _Lista(
      secciones: [
        if (anteriores.isNotEmpty)
          _Seccion(
            titulo: 'Pendientes de días anteriores',
            icono: Icons.history,
            atrasada: true,
            filas: anteriores,
          ),
        _Seccion(
          titulo: 'Registradas ese día',
          icono: Icons.event_note_outlined,
          filas: state.delDia,
          vacia: 'Ese día no se registró ninguna.',
        ),
      ],
      enTabla: enTabla,
      cerrando: state.cerrando,
      onCerrar: (fila) => _cerrar(context, ref, fila),
    );
  }

  Future<void> _elegirDia(BuildContext context, WidgetRef ref) async {
    final actual =
        ref.read(traspasoEfectivoTesBaseProvider(idBitTarea)).dia ??
        DateTime.now();
    final hoy = DateTime.now();
    final elegido = await showDatePicker(
      context: context,
      initialDate: actual,
      // La primera transferencia de ttes_TesBase es de marzo de 2023.
      firstDate: DateTime(2023),
      lastDate: actual.isAfter(hoy) ? actual : hoy,
      helpText: 'Ver las transferencias registradas el',
    );
    if (elegido == null || !context.mounted) return;
    ref
        .read(traspasoEfectivoTesBaseProvider(idBitTarea).notifier)
        .verDia(elegido);
  }

  Future<void> _cerrar(
    BuildContext context,
    WidgetRef ref,
    TraspasoEfectivoTesBaseEntity fila,
  ) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Cerrar la transferencia'),
            content: Text(
              '${fila.cliente}\n\n'
              'Confirma que verificaste que el efectivo pasó de un sistema al '
              'otro. La transferencia deja de estar pendiente.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Sí, cerrar'),
              ),
            ],
          ),
    );
    if (confirmado != true || !context.mounted) return;
    HapticFeedback.selectionClick();
    await ref
        .read(traspasoEfectivoTesBaseProvider(idBitTarea).notifier)
        .cerrar(fila: fila);
  }

  Future<void> _darDiaPorRevisado(BuildContext context, WidgetRef ref) async {
    final revisado =
        ref.read(traspasoEfectivoTesBaseProvider(idBitTarea)).diaRevisado;
    final hasta =
        revisado == null
            ? ''
            : ' registradas hasta el ${_conDia(revisado.fechaRevisada)}';
    final confirmado = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Dar el día por revisado'),
            content: Text(
              'Se va a dejar constancia de que revisaste las transferencias'
              '$hasta y no quedaba ninguna pendiente.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Sí, dar por revisado'),
              ),
            ],
          ),
    );
    if (confirmado != true || !context.mounted) return;

    final ok =
        await ref
            .read(traspasoEfectivoTesBaseProvider(idBitTarea).notifier)
            .sinPendientes();
    if (ok && context.mounted) cerrarRuta(context, true);
  }
}

// ─────────────────────────────────────────────────────────────────────────────

const _diasDeLaSemana = [
  'lunes',
  'martes',
  'miércoles',
  'jueves',
  'viernes',
  'sábado',
  'domingo',
];

/// "sábado 05/09/2026". El día de la semana es lo que explica que un lunes se
/// revise el sábado.
String _conDia(DateTime d) =>
    '${_diasDeLaSemana[d.weekday - 1]} ${FormatearFecha.formatearFecha(d)}';

/// "DIA DE LA PAZ" → "Dia de la Paz": el calendario de RR.HH. guarda los
/// motivos en mayúsculas.
String _nombreFeriado(String motivo) {
  const menores = {'de', 'del', 'la', 'las', 'el', 'los', 'y', 'e'};
  final palabras = motivo.trim().toLowerCase().split(RegExp(r'\s+'));
  return [
    for (var i = 0; i < palabras.length; i++)
      if (palabras[i].isNotEmpty)
        i > 0 && menores.contains(palabras[i])
            ? palabras[i]
            : palabras[i][0].toUpperCase() + palabras[i].substring(1),
  ].join(' ');
}

/// Por qué la ocurrencia revisa ese día y no el anterior a la tarea.
String _porQueEseDia(DiaRevisadoTesBase r) {
  final saltados = r.diasSaltados;
  if (saltados.isEmpty) return 'Es el día anterior a la tarea.';

  final feriados = [
    for (final d in saltados)
      if (d.weekday != DateTime.sunday) d,
  ];
  final domingos = saltados.length - feriados.length;
  final nombre = r.feriado == null ? '' : ' (${_nombreFeriado(r.feriado!)})';
  final partes = [
    if (domingos == 1) 'el domingo no se trabaja',
    if (domingos > 1) 'los domingos no se trabajan',
    if (feriados.length == 1)
      'el ${_diasDeLaSemana[feriados.first.weekday - 1]} fue feriado$nombre',
    if (feriados.length > 1) 'hubo ${feriados.length} días de feriado$nombre',
  ];
  return 'Es el día hábil anterior a la tarea: ${partes.join(' y ')}.';
}

/// El día que se mira, con qué se elige otro y por qué es ese.
///
/// La explicación importa tanto como la fecha: sin ella, abrir la tarea un
/// lunes y ver el sábado parece un error.
class _BarraDia extends StatelessWidget {
  final DiaRevisadoTesBase revisado;
  final DateTime dia;
  final bool mirandoElRevisado;
  final VoidCallback onElegir;
  final VoidCallback onVolver;

  const _BarraDia({
    required this.revisado,
    required this.dia,
    required this.mirandoElRevisado,
    required this.onElegir,
    required this.onVolver,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Material(
      color: tema.colorScheme.surfaceContainerLow,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: tema.colorScheme.outlineVariant),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Esp.l,
            vertical: Esp.s,
          ),
          child: Wrap(
            spacing: Esp.m,
            runSpacing: Esp.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Registradas el', style: tema.textTheme.labelLarge),
              OutlinedButton.icon(
                onPressed: onElegir,
                icon: const Icon(Icons.calendar_month_outlined, size: 18),
                label: Text(_conDia(dia)),
              ),
              if (mirandoElRevisado)
                Text(_porQueEseDia(revisado), style: context.apagado())
              else ...[
                Text(
                  'La tarea revisa el ${_conDia(revisado.fechaRevisada)}.',
                  style: context.apagado(),
                ),
                TextButton.icon(
                  onPressed: onVolver,
                  icon: const Icon(Icons.undo, size: 18),
                  label: Text('Volver al ${_conDia(revisado.fechaRevisada)}'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

const _anchos = <AnchoCol>[
  AnchoCol.flexible(3), // cliente
  AnchoCol.fijo(150), // base de origen
  AnchoCol.fijo(130), // registrada
  AnchoCol.flexible(3), // observación
  AnchoCol.fijo(180), // estado o botón
];

/// Un bloque de la lista: las pendientes atrasadas o las del día que se mira.
class _Seccion {
  final String titulo;
  final IconData icono;
  final bool atrasada;
  final List<TraspasoEfectivoTesBaseEntity> filas;

  /// Lo que se dice si no tiene filas. Nulo: vacía no se muestra.
  final String? vacia;

  const _Seccion({
    required this.titulo,
    required this.icono,
    required this.filas,
    this.atrasada = false,
    this.vacia,
  });
}

class _Lista extends StatelessWidget {
  final List<_Seccion> secciones;
  final bool enTabla;
  final int? cerrando;
  final void Function(TraspasoEfectivoTesBaseEntity) onCerrar;

  const _Lista({
    required this.secciones,
    required this.enTabla,
    required this.cerrando,
    required this.onCerrar,
  });

  @override
  Widget build(BuildContext context) {
    final hoy = DateTime.now();

    // Una sola lista perezosa, con los encabezados de sección intercalados.
    final items = <Object>[
      for (final s in secciones)
        if (s.filas.isNotEmpty || s.vacia != null) ...[
          s,
          if (s.filas.isEmpty) s.vacia!,
          ...s.filas,
        ],
    ];

    Widget item(BuildContext context, int i) {
      final x = items[i];
      if (x is _Seccion) {
        return _EncabezadoSeccion(seccion: x, primera: i == 0, enTabla: enTabla);
      }
      if (x is String) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            enTabla ? Esp.m : Esp.xs,
            0,
            Esp.m,
            Esp.m,
          ),
          child: Text(x, style: context.apagado()),
        );
      }

      final fila = x as TraspasoEfectivoTesBaseEntity;
      final trabajando = cerrando == fila.codTes;
      final bloqueado = cerrando != null;
      final accion =
          fila.pendiente
              ? _BotonCerrar(
                trabajando: trabajando,
                bloqueado: bloqueado,
                onPressed: () => onCerrar(fila),
              )
              : _EstadoCerrada(fila: fila);

      if (!enTabla) {
        return _Tarjeta(fila: fila, hoy: hoy, accion: accion);
      }

      final obs = (fila.observacion ?? '').trim();
      return DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: context.cs.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
        ),
        child: FilaTabla(
          anchos: _anchos,
          celdas: [
            _Cliente(fila: fila),
            Text(fila.nombreEmpresa ?? '—', overflow: TextOverflow.ellipsis),
            _Antiguedad(fila: fila, hoy: hoy),
            Text(
              obs.isEmpty ? '—' : obs,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.apagado(),
            ),
            Align(alignment: Alignment.centerLeft, child: accion),
          ],
        ),
      );
    }

    if (!enTabla) {
      return ListView.builder(
        padding: const EdgeInsets.only(bottom: Esp.m),
        itemCount: items.length,
        itemBuilder: item,
      );
    }

    return MarcoTabla(
      child: Column(
        children: [
          const EncabezadoTabla(
            anchos: _anchos,
            titulos: [
              'Cliente',
              'Base de origen',
              'Registrada',
              'Observación',
              'Estado',
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: item,
            ),
          ),
        ],
      ),
    );
  }
}

class _EncabezadoSeccion extends StatelessWidget {
  final _Seccion seccion;
  final bool primera;
  final bool enTabla;

  const _EncabezadoSeccion({
    required this.seccion,
    required this.primera,
    required this.enTabla,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        seccion.atrasada
            ? TareasColors.vencidoTexto(context)
            : context.cs.onSurfaceVariant;
    final lado = enTabla ? Esp.m : Esp.xs;
    return Padding(
      padding: EdgeInsets.fromLTRB(lado, primera ? Esp.m : Esp.l, lado, Esp.s),
      child: Row(
        children: [
          Icon(seccion.icono, size: 18, color: color),
          const SizedBox(width: Esp.s),
          Expanded(
            child: Text(
              seccion.titulo,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: color,
                fontWeight: Peso.titulo,
              ),
            ),
          ),
          if (seccion.filas.isNotEmpty)
            Text('${seccion.filas.length}', style: context.numero(color: color)),
        ],
      ),
    );
  }
}

/// Nombre arriba, código abajo: se busca por nombre y el código solo
/// desempata.
class _Cliente extends StatelessWidget {
  final TraspasoEfectivoTesBaseEntity fila;

  const _Cliente({required this.fila});

  @override
  Widget build(BuildContext context) {
    final nombre = (fila.datoCliente ?? '').trim();
    final codigo = (fila.codCliente ?? '').trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          nombre.isEmpty ? fila.cliente : nombre,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: Peso.titulo),
        ),
        if (nombre.isNotEmpty && codigo.isNotEmpty)
          Text(codigo, style: context.numero(color: context.cs.onSurfaceVariant)),
      ],
    );
  }
}

class _Tarjeta extends StatelessWidget {
  final TraspasoEfectivoTesBaseEntity fila;
  final DateTime hoy;
  final Widget accion;

  const _Tarjeta({required this.fila, required this.hoy, required this.accion});

  @override
  Widget build(BuildContext context) {
    final obs = (fila.observacion ?? '').trim();

    return Card(
      margin: const EdgeInsets.only(bottom: Esp.s),
      child: Padding(
        padding: const EdgeInsets.all(Esp.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(fila.cliente, style: context.tituloSeccion()),
            const SizedBox(height: 2),
            Text(
              fila.nombreEmpresa ?? 'Base sin nombre',
              style: context.apagado(),
            ),
            const SizedBox(height: Esp.s),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: _Antiguedad(fila: fila, hoy: hoy)),
                accion,
              ],
            ),
            if (obs.isNotEmpty) ...[
              const SizedBox(height: Esp.s),
              Text(obs, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }
}

/// La fecha de registro y, si sigue pendiente, cuánto hace. Una pendiente de
/// varios días es la que hay que mirar primero.
class _Antiguedad extends StatelessWidget {
  final TraspasoEfectivoTesBaseEntity fila;
  final DateTime hoy;

  const _Antiguedad({required this.fila, required this.hoy});

  @override
  Widget build(BuildContext context) {
    final registro = fila.fechaRegistro;
    if (registro == null) return const Text('—');
    final fecha = Text(
      FormatearFecha.formatearFecha(registro),
      style: context.numero(),
    );
    if (!fila.pendiente) return fecha;

    final dias = fila.diasPendiente(hoy) ?? 0;
    final hace =
        dias <= 0
            ? 'hoy'
            : dias == 1
            ? 'hace 1 día'
            : 'hace $dias días';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        fecha,
        Text(
          hace,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color:
                dias > 1
                    ? TareasColors.vencidoTexto(context)
                    : context.cs.onSurfaceVariant,
            fontWeight: dias > 1 ? Peso.titulo : null,
          ),
        ),
      ],
    );
  }
}

class _BotonCerrar extends StatelessWidget {
  final bool trabajando;

  /// Otra transferencia está viajando: no se manda una segunda a la vez.
  final bool bloqueado;
  final VoidCallback onPressed;

  const _BotonCerrar({
    required this.trabajando,
    required this.bloqueado,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (trabajando) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: Esp.xl, vertical: Esp.s),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    return FilledButton.tonalIcon(
      onPressed: bloqueado ? null : onPressed,
      icon: const Icon(Icons.task_alt, size: 18),
      label: const Text('Cerrar'),
    );
  }
}

/// Una que ya no está pendiente, con la fecha en que se cerró.
class _EstadoCerrada extends StatelessWidget {
  final TraspasoEfectivoTesBaseEntity fila;

  const _EstadoCerrada({required this.fila});

  @override
  Widget build(BuildContext context) {
    final fin = fila.fechaFinalizacion;
    return PildoraTareas(
      texto:
          fin == null
              ? fila.estadoTexto
              : '${fila.estadoTexto} el ${FormatearFecha.formatearFecha(fin)}',
      icono: Icons.check_circle_outline,
      fondo: TareasColors.realizado(context),
      color: TareasColors.realizadoTexto(context),
    );
  }
}

/// Cuánto falta hasta el día revisado y "Sin pendientes".
///
/// El botón se ve siempre y se habilita recién cuando no queda nada: así se
/// entiende qué hace falta para cerrar la tarea.
class _BarraCierre extends StatelessWidget {
  final DiaRevisadoTesBase? revisado;
  final int faltan;
  final bool cerrandoDia;
  final VoidCallback onSinPendientes;

  const _BarraCierre({
    required this.revisado,
    required this.faltan,
    required this.cerrandoDia,
    required this.onSinPendientes,
  });

  @override
  Widget build(BuildContext context) {
    final r = revisado;
    final hasta =
        r == null
            ? ''
            : ' hasta el ${FormatearFecha.formatearFecha(r.fechaRevisada)}';
    final listo = faltan == 0;

    return BarraAccionTareas(
      resumen: Row(
        children: [
          Icon(
            listo ? Icons.check_circle_outline : Icons.pending_outlined,
            size: 18,
            color:
                listo
                    ? TareasColors.realizadoTexto(context)
                    : TareasColors.pendienteTexto(context),
          ),
          const SizedBox(width: Esp.s),
          Expanded(
            child: Text(
              listo
                  ? 'No queda ninguna pendiente$hasta.'
                  : faltan == 1
                  ? 'Falta 1 por cerrar$hasta.'
                  : 'Faltan $faltan por cerrar$hasta.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
      accion:
          cerrandoDia
              ? const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
              : FilledButton.icon(
                onPressed: listo ? onSinPendientes : null,
                icon: const Icon(Icons.done_all),
                label: const Text('Sin pendientes'),
              ),
    );
  }
}
