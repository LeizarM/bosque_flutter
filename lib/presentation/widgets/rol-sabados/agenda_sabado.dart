import 'package:bosque_flutter/core/state/rol_sabados_provider.dart';
import 'package:bosque_flutter/domain/entities/celda_turno_entity.dart';
import 'package:bosque_flutter/domain/entities/participante_turno_entity.dart';
import 'package:bosque_flutter/domain/entities/sabado_entity.dart';
import 'package:bosque_flutter/presentation/widgets/rol-sabados/editor_celda.dart';
import 'package:bosque_flutter/presentation/widgets/rol-sabados/estilo_modulo.dart';
import 'package:bosque_flutter/presentation/widgets/rol-sabados/evento_sheet.dart';
import 'package:bosque_flutter/presentation/widgets/rol-sabados/exportar_sabado.dart';
import 'package:bosque_flutter/presentation/widgets/rol-sabados/rol_sabados_comunes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// La grilla vista desde un teléfono: **un sábado a la vez**.
///
/// La matriz de 29×52 no se arregla encogiéndola. En 360 px la columna de
/// nombres se come más de la mitad de la pantalla y quedan tres columnas
/// visibles de cincuenta y dos: no es una tabla, es una ventanita.
///
/// Pero es que además la pregunta cambia con el dispositivo. Frente a la
/// planilla en el escritorio uno mira el año entero y busca desequilibrios;
/// con el teléfono en la mano uno quiere saber **quién viene este sábado**.
/// Esta vista responde eso, con exactamente los mismos datos que ya están en
/// memoria — no hay una sola llamada extra al backend.
///
/// La tira de fechas de arriba es el encabezado de la matriz convertido en
/// navegación: mismo dato, misma jerarquía visual (día, mes, cuánta gente
/// viene), operable con el pulgar.
class AgendaSabado extends ConsumerStatefulWidget {
  const AgendaSabado({
    super.key,
    required this.grilla,
    required this.sabados,
    required this.participantes,
  });

  final GrillaRol grilla;

  /// Ya filtrados por mes y por búsqueda; [grilla] conserva el rol entero
  /// porque los contadores se calculan sobre todo el año.
  final List<SabadoEntity> sabados;
  final List<ParticipanteTurnoEntity> participantes;

  @override
  ConsumerState<AgendaSabado> createState() => _AgendaSabadoState();
}

class _AgendaSabadoState extends ConsumerState<AgendaSabado> {
  final _tira = ScrollController();
  int? _idSabado;

  static const double _anchoChip = 68;

  @override
  void initState() {
    super.initState();
    _idSabado = _sabadoInicial()?.idSabado;
    // Abrir en enero cuando estamos en septiembre obliga a arrastrar medio año.
    WidgetsBinding.instance.addPostFrameCallback((_) => _centrarEnElActual());
  }

  @override
  void dispose() {
    _tira.dispose();
    super.dispose();
  }

  /// El próximo sábado que no pasó, o el último del año si ya pasaron todos.
  SabadoEntity? _sabadoInicial() {
    final sabados = widget.sabados;
    if (sabados.isEmpty) return null;
    final hoy = DateTime.now();
    for (final s in sabados) {
      if (s.fecha != null && !s.fecha!.isBefore(hoy)) return s;
    }
    return sabados.last;
  }

  void _centrarEnElActual() {
    if (!_tira.hasClients || _idSabado == null) return;
    final i = widget.sabados.indexWhere((s) => s.idSabado == _idSabado);
    if (i < 0) return;
    final destino = (i * _anchoChip) - 100;
    _tira.jumpTo(destino.clamp(0.0, _tira.position.maxScrollExtent));
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.grilla;
    if (widget.sabados.isEmpty) {
      return const MensajeVacio(
        icono: Icons.grid_off,
        titulo: 'El rol no tiene sábados',
        detalle: 'Regenéralo para que se armen las fechas.',
      );
    }

    // Al cambiar de mes, el sábado elegido puede quedar fuera de la lista.
    final sabado = widget.sabados.firstWhere(
      (s) => s.idSabado == _idSabado,
      orElse: () => widget.sabados.first,
    );

    // Quién viene, quién falta y por qué: se arma del mismo mapa de celdas.
    final vienen = <ParticipanteTurnoEntity>[];
    final noVienen = <(ParticipanteTurnoEntity, CeldaTurnoEntity?)>[];
    for (final p in widget.participantes) {
      final celda = g.celda(p.idParticipante, sabado.idSabado);
      if (celda?.codigoExcel == '1') {
        vienen.add(p);
      } else {
        noVienen.add((p, celda));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Tira(
          controlador: _tira,
          anchoChip: _anchoChip,
          grilla: g,
          sabados: widget.sabados,
          seleccionado: sabado.idSabado,
          onElegir: (id) => setState(() => _idSabado = id),
        ),
        const Divider(height: 1),
        _Encabezado(grilla: g, sabado: sabado, vienen: vienen.length),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              _Seccion(
                titulo: 'Vienen',
                cantidad: vienen.length,
                vacio: 'Ese sábado no viene nadie.',
                hijos: [
                  for (final p in vienen)
                    _FilaPersona(
                      grilla: g,
                      participante: p,
                      sabado: sabado,
                      celda: g.celda(p.idParticipante, sabado.idSabado),
                    ),
                ],
              ),
              _Seccion(
                titulo: 'No vienen',
                cantidad: noVienen.length,
                vacio: 'Vienen todos.',
                hijos: [
                  for (final (p, celda) in noVienen)
                    _FilaPersona(
                      grilla: g,
                      participante: p,
                      sabado: sabado,
                      celda: celda,
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// LA TIRA DE SÁBADOS
// ═══════════════════════════════════════════════════════════════════════════

class _Tira extends StatelessWidget {
  const _Tira({
    required this.controlador,
    required this.anchoChip,
    required this.grilla,
    required this.sabados,
    required this.seleccionado,
    required this.onElegir,
  });

  final ScrollController controlador;
  final double anchoChip;
  final GrillaRol grilla;
  final List<SabadoEntity> sabados;
  final int seleccionado;
  final ValueChanged<int> onElegir;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 78,
    child: ListView.builder(
      controller: controlador,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: Esp.s, vertical: Esp.s),
      itemCount: sabados.length,
      itemExtent: anchoChip,
      itemBuilder: (context, i) {
        final s = sabados[i];
        return _ChipFecha(
          sabado: s,
          cobertura: grilla.coberturaDe(s.idSabado),
          activo: s.idSabado == seleccionado,
          onTap: () => onElegir(s.idSabado),
        );
      },
    ),
  );
}

class _ChipFecha extends StatelessWidget {
  const _ChipFecha({
    required this.sabado,
    required this.cobertura,
    required this.activo,
    required this.onTap,
  });

  final SabadoEntity sabado;
  final int cobertura;
  final bool activo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final f = sabado.fecha;

    // El feriado y el evento se marcan con una barra arriba, no con el fondo:
    // el fondo ya lo usa la selección y dos señales en el mismo canal se pisan.
    final Color? marca =
        sabado.esFeriadoBool
            ? cs.error
            : sabado.tieneEvento
            ? cs.tertiary
            : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Esp.xs),
      child: Material(
        color: activo ? cs.primaryContainer : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 3,
                width: 22,
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: marca ?? Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                f == null ? '--' : f.day.toString().padLeft(2, '0'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: Peso.dato,
                  height: 1.1,
                  color: activo ? cs.onPrimaryContainer : null,
                  fontFeatures: cifrasTabulares,
                ),
              ),
              Text(
                f == null ? '' : mesCorto(f.month),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  height: 1.1,
                  color: activo ? cs.onPrimaryContainer : cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$cobertura',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  height: 1.1,
                  color: activo ? cs.onPrimaryContainer : cs.onSurfaceVariant,
                  fontFeatures: cifrasTabulares,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════

/// Qué sábado se está viendo, cómo viene de gente, y qué se puede hacer con él.
///
/// **Acá el PDF sí es un botón visible**, al revés que en la matriz. Es la
/// pantalla del teléfono, que es desde donde se comparte al grupo de WhatsApp:
/// esconder la acción de la semana detrás de un menú, en el único lugar donde
/// hay lugar de sobra para mostrarla, sería esconderla por gusto.
class _Encabezado extends ConsumerStatefulWidget {
  const _Encabezado({
    required this.grilla,
    required this.sabado,
    required this.vienen,
  });

  final GrillaRol grilla;
  final SabadoEntity sabado;
  final int vienen;

  @override
  ConsumerState<_Encabezado> createState() => _EncabezadoState();
}

class _EncabezadoState extends ConsumerState<_Encabezado> {
  /// Mientras el PDF se arma. El botón queda apagado: son 85 personas y el
  /// reporte tarda, y un botón que no contesta se aprieta de nuevo.
  bool _ocupado = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final grilla = widget.grilla;
    final sabado = widget.sabado;
    final vienen = widget.vienen;
    final objetivo = grilla.rol.coberturaObjetivo;
    final corto = objetivo > 0 && vienen < objetivo;

    return Padding(
      padding: const EdgeInsets.fromLTRB(Esp.l, Esp.m, Esp.s, Esp.m),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sábado ${fechaCorta(sabado.fecha)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  objetivo > 0
                      ? 'Vienen $vienen de $objetivo · rota el grupo '
                          '${sabado.grupoQueRota}'
                      : 'Vienen $vienen · rota el grupo ${sabado.grupoQueRota}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: corto ? cs.error : Theme.of(context).hintColor,
                    fontWeight: corto ? FontWeight.w600 : null,
                  ),
                ),
                if (sabado.esFeriadoBool || sabado.tieneEvento) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (sabado.esFeriadoBool)
                        const Etiqueta(
                          texto: 'FERIADO',
                          tono: TonoEtiqueta.error,
                        ),
                      if (sabado.tieneEvento)
                        Etiqueta(
                          texto: sabado.alcanceEvento!,
                          tono: TonoEtiqueta.aviso,
                        ),
                      if (sabado.motivoEspecial.isNotEmpty)
                        Etiqueta(texto: sabado.motivoEspecial),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Siempre, también con el rol CERRADO: el PDF de un sábado que ya
          // pasó se sigue necesitando, y compartirlo no cambia nada del rol.
          IconButton(
            tooltip: 'Compartir el PDF de este sábado',
            icon:
                _ocupado
                    // Del tamaño del ícono que reemplaza, así el botón no salta
                    // de lugar al empezar y la fila mide siempre lo mismo.
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.picture_as_pdf_outlined),
            onPressed: _ocupado ? null : _exportar,
          ),
          if (!grilla.rol.estaCerrado)
            IconButton(
              tooltip: 'Declarar el evento del día',
              icon: const Icon(Icons.event_available_outlined),
              onPressed:
                  () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    showDragHandle: true,
                    builder:
                        (_) => EventoSheet(
                          idRol: grilla.rol.idRol,
                          sabado: sabado,
                          participantes: grilla.participantes,
                        ),
                  ),
            ),
        ],
      ),
    );
  }

  Future<void> _exportar() async {
    setState(() => _ocupado = true);
    await exportarSabadoPdf(context: context, ref: ref, sabado: widget.sabado);
    if (mounted) setState(() => _ocupado = false);
  }
}

class _Seccion extends StatelessWidget {
  const _Seccion({
    required this.titulo,
    required this.cantidad,
    required this.vacio,
    required this.hijos,
  });

  final String titulo;
  final int cantidad;
  final String vacio;
  final List<Widget> hijos;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(Esp.l, Esp.l, Esp.l, Esp.s),
        child: Text(
          '$titulo · $cantidad',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      if (hijos.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Esp.l,
            vertical: Esp.xs,
          ),
          child: Text(vacio, style: Theme.of(context).textTheme.bodySmall),
        )
      else
        ...hijos,
    ],
  );
}

/// Una persona en el sábado elegido.
///
/// Es un `ListTile` y no una celda de 32 px justamente porque acá sí hay lugar:
/// el objetivo táctil llega a los 48 px que pide Material, cosa que en la matriz
/// es imposible.
class _FilaPersona extends ConsumerWidget {
  const _FilaPersona({
    required this.grilla,
    required this.participante,
    required this.sabado,
    required this.celda,
  });

  final GrillaRol grilla;
  final ParticipanteTurnoEntity participante;
  final SabadoEntity sabado;
  final CeldaTurnoEntity? celda;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    // Acá el provider se observa por fila y no una vez arriba, al revés que en
    // la matriz: son las personas de UN sábado, unas decenas, no 4.420 celdas.
    final puedeEditar = ref
        .watch(permisoDeCeldaProvider)
        .puedeCon(participante.codEmpleado);

    return ListTile(
      onTap:
          (grilla.rol.estaCerrado || !puedeEditar)
              ? null
              : () => mostrarEditorDeCelda(
                context: context,
                grilla: grilla,
                participante: participante,
                sabado: sabado,
                celda: celda,
              ),
      // La misma letra y la misma marca que en la matriz: si la señal cambiara
      // de forma entre las dos vistas habria que aprenderla dos veces.
      leading: SizedBox(
        width: 38,
        height: 38,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: fondoDeCelda(context, celda),
                shape: BoxShape.circle,
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Center(
                child: LetraDeCelda(
                  celda: celda,
                  estiloTexto: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: Peso.dato),
                ),
              ),
            ),
            if (celda?.esIntervencion == true)
              Positioned(
                top: 0,
                right: 0,
                child: MarcaDeIntervencion(color: cs.primary, lado: 9),
              ),
            // La misma esquina opuesta que en la matriz. Acá además hace de
            // ancla: el renglón de abajo puede quedar cortado por el
            // `maxLines`, la marca no se corta nunca.
            if (celda?.hayCambio == true)
              Positioned(
                bottom: 0,
                left: 0,
                child: MarcaDeCambio(color: cs.tertiary, lado: 9),
              ),
          ],
        ),
      ),
      title: Text(participante.nombreRol),
      isThreeLine: participante.puesto.isNotEmpty,
      // **Dos Text y no uno con `\n`.** Con un solo Text y `maxLines: 2`, un
      // cargo largo —«SUPERVISOR DE PRODUCCION · GALPON EL ALTO» mide ~345 px
      // sobre los ~274 utiles que quedan en 360 px— se parte en dos renglones y
      // se come el cupo entero: el estado, que es la respuesta a «¿viene?»,
      // desaparecia. Separados, cada uno tiene su propio limite y el estado no
      // se puede perder nunca.
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cargo y sucursal APAGADOS y arriba: son quien es esa persona, o sea
          // contexto para leer el renglon de abajo. La sucursal ademas explica
          // la 'X' —el feriado se resuelve por sucursal, no por rol— asi que
          // cuando la letra dice «Feriado» este renglon dice de donde salio.
          //
          // Se muestra siempre, tambien CENTRAL: aca la lista cambia de gente
          // con cada sabado y con el buscador, asi que «la mayoritaria» seria
          // una regla distinta en cada pantalla. El detalle del criterio esta en
          // la fila de «Grupos» (personal_tab).
          if (participante.puesto.isNotEmpty)
            Text(
              participante.puesto,
              style: context.apagado(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          Text(_detalle(), maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  /// Qué le pasa a esa persona ese sábado.
  ///
  /// **El cambio va antes que la observación** y no al final: el renglón se
  /// corta a dos líneas, y de las dos cosas la que no se puede perder es con
  /// quién. La observación suele ser el motivo del cambio —`trs_sp_corregirCelda`
  /// lo copia a la celda—, así que cuando se corta se está perdiendo lo que ya
  /// se dedujo, no un dato nuevo.
  String _detalle() {
    final c = celda;
    if (c == null) return 'Libre · grupo ${participante.grupoRotacion}';
    final nombre = grilla.estados[c.codigoExcel]?.nombre ?? c.codigoExcel;
    return '$nombre · grupo ${participante.grupoRotacion}'
        '${c.hayCambio ? ' · ${c.cambioTexto}' : ''}'
        '${c.observacion.isEmpty ? '' : ' · ${c.observacion}'}';
  }
}
