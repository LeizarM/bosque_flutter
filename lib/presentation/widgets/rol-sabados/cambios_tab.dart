import 'package:bosque_flutter/core/state/rol_sabados_provider.dart';
import 'package:bosque_flutter/domain/entities/cambio_entity.dart';
import 'package:bosque_flutter/domain/entities/participante_turno_entity.dart';
import 'package:bosque_flutter/domain/entities/sabado_entity.dart';
import 'package:bosque_flutter/presentation/widgets/rol-sabados/rol_sabados_comunes.dart';
import 'package:bosque_flutter/presentation/widgets/rol-sabados/filtros_grilla.dart';
import 'package:bosque_flutter/presentation/widgets/rol-sabados/mensajes_usuario.dart';
import 'package:bosque_flutter/presentation/widgets/rol-sabados/estilo_modulo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Permutas y coberturas: el caso «no puedo ese sábado».
///
/// La distinción que ordena toda la pantalla: **registrar un cambio no mueve la
/// grilla**. Nace SOLICITADO y ahí se queda. Recién al aprobarlo se escriben las
/// tres celdas —titular en 'C', el que cubre en '1', y la reposición liberada—
/// y las tres van juntas en una transacción.
///
/// Por eso APROBADO no se puede editar ni anular desde acá: sus celdas ya están
/// en la grilla y deshacerlas por este lado la dejaría mintiendo.
class CambiosTab extends ConsumerWidget {
  const CambiosTab({super.key, required this.idRol});

  final int idRol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cambios = ref.watch(cambiosProvider(idRol));
    final filtro = ref.watch(filtroEstadoCambioProvider);

    return Column(
      children: [
        _Filtros(filtro: filtro),
        const Divider(height: 1),
        Expanded(
          child: cambios.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error:
                (e, _) => MensajeVacio(
                  icono: Icons.error_outline,
                  titulo: 'No se pudieron cargar los cambios',
                  detalle: textoParaUsuario(e),
                ),
            data: (lista) {
              if (lista.isEmpty) {
                return MensajeVacio(
                  icono: Icons.swap_horiz,
                  titulo:
                      filtro.isEmpty
                          ? 'Sin permutas ni coberturas'
                          : 'Ninguno en estado $filtro',
                  detalle:
                      filtro.isEmpty
                          ? 'Nadie pidió cambiar su sábado. El rol se está '
                              'cumpliendo tal como salió.'
                          : 'Prueba con otro estado o quita el filtro.',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: lista.length,
                separatorBuilder: (_, __) => const SizedBox(height: Esp.xs),
                itemBuilder: (_, i) => _Tarjeta(idRol: idRol, cambio: lista[i]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Filtros extends ConsumerWidget {
  const _Filtros({required this.filtro});
  final String filtro;

  static const _estados = [
    '',
    'SOLICITADO',
    'APROBADO',
    'RECHAZADO',
    'ANULADO',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: Esp.l, vertical: Esp.m),
    child: Row(
      children: [
        for (final e in _estados) ...[
          ChoiceChip(
            label: Text(e.isEmpty ? 'Todos' : e),
            selected: filtro == e,
            onSelected:
                (_) => ref.read(filtroEstadoCambioProvider.notifier).state = e,
          ),
          const SizedBox(width: Esp.s),
        ],
      ],
    ),
  );
}

class _Tarjeta extends ConsumerStatefulWidget {
  const _Tarjeta({required this.idRol, required this.cambio});
  final int idRol;
  final CambioEntity cambio;

  @override
  ConsumerState<_Tarjeta> createState() => _TarjetaState();
}

class _TarjetaState extends ConsumerState<_Tarjeta> {
  bool _ocupado = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.cambio;
    final texto = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Sábado ${fechaCorta(c.sabadoCubierto)}',
                  style: texto.titleSmall,
                ),
                Etiqueta(texto: c.tipo),
                Etiqueta(texto: c.estado, tono: _tono(c.estado)),
              ],
            ),
            const SizedBox(height: Esp.s),

            _Linea(
              icono: Icons.person_off_outlined,
              titulo: 'No viene',
              valor: c.titular.isEmpty ? '#${c.codEmpleadoTitular}' : c.titular,
            ),
            _Linea(
              icono: Icons.person_add_alt,
              titulo: 'Cubre',
              valor:
                  c.reemplazo.isEmpty
                      ? (c.codEmpleadoReemplazo == 0
                          ? 'todavía nadie'
                          : '#${c.codEmpleadoReemplazo}')
                      : c.reemplazo,
            ),
            if (c.tipo == 'PERMUTA')
              _Linea(
                icono: Icons.event_repeat,
                titulo: 'Se le devuelve',
                valor: fechaCorta(c.fechaReposicion),
              ),
            if (c.motivo.isNotEmpty)
              _Linea(icono: Icons.notes, titulo: 'Motivo', valor: c.motivo),

            const SizedBox(height: Esp.xs),
            Text(
              c.aplicado
                  ? 'Aplicado a la grilla el ${fechaCorta(c.fechaResolucion)}.'
                  : c.pendiente
                  ? 'Todavía NO toca la grilla: hay que aprobarlo.'
                  : 'Sin efecto sobre la grilla.',
              style: texto.bodySmall?.copyWith(
                color:
                    c.pendiente
                        ? Theme.of(context).colorScheme.tertiary
                        : Theme.of(context).hintColor,
              ),
            ),

            if (c.pendiente)
              // Wrap y no Row: "Aprobar y aplicar" + "Anular" no entran juntos
              // en 360 px y una Row los cortaría en vez de bajarlos.
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  TextButton(
                    onPressed: _ocupado ? null : _anular,
                    child: const Text('Anular'),
                  ),
                  FilledButton.icon(
                    onPressed: _ocupado ? null : _confirmarAprobacion,
                    icon:
                        _ocupado
                            ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(Icons.check, size: 18),
                    label: const Text('Aprobar y aplicar'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  TonoEtiqueta _tono(String estado) => switch (estado) {
    'APROBADO' => TonoEtiqueta.exito,
    'SOLICITADO' => TonoEtiqueta.aviso,
    'RECHAZADO' || 'ANULADO' => TonoEtiqueta.error,
    _ => TonoEtiqueta.neutro,
  };

  /// Aprobar escribe celdas y no se deshace desde acá: conviene preguntar.
  Future<void> _confirmarAprobacion() async {
    final c = widget.cambio;
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('¿Aprobar y aplicar?'),
            content: Text(
              'Se van a escribir las celdas del sábado '
              '${fechaCorta(c.sabadoCubierto)}:\n\n'
              '• ${c.titular} pasa a "C"\n'
              '${c.reemplazo.isEmpty ? '' : '• ${c.reemplazo} pasa a "1"\n'}'
              '${c.idSabadoReposicion == 0 ? '' : '• se le libera el ${fechaCorta(c.fechaReposicion)}\n'}'
              '\nDespués de aprobar, esto no se deshace desde esta pantalla: '
              'hay que corregir celda por celda.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Aprobar'),
              ),
            ],
          ),
    );
    if (ok != true) return;

    setState(() => _ocupado = true);
    await ejecutarAccion(
      context,
      () => ref
          .read(rolSabadosAccionesProvider)
          .aprobarCambio(idRol: widget.idRol, idCambio: c.idCambio),
      exito: 'Cambio aprobado y aplicado a la grilla.',
    );
    if (mounted) setState(() => _ocupado = false);
  }

  Future<void> _anular() async {
    setState(() => _ocupado = true);
    await ejecutarAccion(
      context,
      () => ref
          .read(rolSabadosAccionesProvider)
          .anularCambio(idRol: widget.idRol, idCambio: widget.cambio.idCambio),
      exito: 'Cambio anulado.',
    );
    if (mounted) setState(() => _ocupado = false);
  }
}

class _Linea extends StatelessWidget {
  const _Linea({
    required this.icono,
    required this.titulo,
    required this.valor,
  });

  final IconData icono;
  final String titulo;
  final String valor;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, size: 15, color: Theme.of(context).hintColor),
        const SizedBox(width: Esp.s),
        SizedBox(
          // 96 en pantalla ancha, 78 cuando cada píxel del valor cuenta.
          width: MediaQuery.sizeOf(context).width < 400 ? 78 : 96,
          child: Text(
            titulo,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Theme.of(context).hintColor),
          ),
        ),
        Expanded(
          child: Text(valor, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// ALTA
// ═══════════════════════════════════════════════════════════════════════════

/// Formulario de alta de una permuta o cobertura.
///
/// **Lo que este formulario impide.** La tentacion es dejar elegir a cualquiera
/// de las dos listas, pero un cambio solo tiene sentido si:
///
/// - a quien no viene **le tocaba venir** ese sabado — si no, no hay nada que
///   cubrir; y
/// - quien cubre **estaba libre** — si ya venia, cubrir no agrega a nadie y la
///   cobertura del dia baja igual en uno.
///
/// El criterio NO es «que sean de grupos distintos». Un B puede tener turno un
/// sabado de A si hubo evento TOTAL, si lo convocaron, o si un jefe lo programo.
/// Por eso se mira la celda de verdad y no la paridad.
class NuevoCambioSheet extends ConsumerStatefulWidget {
  const NuevoCambioSheet({super.key, required this.grilla});
  final GrillaRol grilla;

  @override
  ConsumerState<NuevoCambioSheet> createState() => _NuevoCambioSheetState();
}

class _NuevoCambioSheetState extends ConsumerState<NuevoCambioSheet> {
  int? _idSabado;
  int? _titular;
  int? _reemplazo;
  int? _idSabadoReposicion;
  String _tipo = 'COBERTURA';
  final _motivo = TextEditingController();
  bool _guardando = false;

  @override
  void dispose() {
    _motivo.dispose();
    super.dispose();
  }

  // ── quien es quien ese sabado ────────────────────────────────────────

  /// Tiene turno: la celda dice '1'. Una 'V' o una 'X' no cuentan — esa persona
  /// ya no venia, asi que no hay nada que cubrirle.
  bool _tieneTurno(ParticipanteTurnoEntity p, int idSabado) =>
      widget.grilla.celda(p.idParticipante, idSabado)?.codigoExcel == '1';

  /// Esta libre: NO hay celda. En este modelo el libre es la ausencia de la
  /// fila, asi que esto es exactamente «ese dia no le tocaba nada».
  bool _estaLibre(ParticipanteTurnoEntity p, int idSabado) =>
      widget.grilla.celda(p.idParticipante, idSabado) == null;

  @override
  Widget build(BuildContext context) {
    final g = widget.grilla;

    // Los sabados del mes que se esta mirando en la grilla: si el filtro dice
    // agosto, ofrecer los 52 del anio obliga a buscar la fecha en una lista larga.
    final delMes = filtrarSabados(g.sabados, ref.watch(filtroMesProvider));
    final hoy = DateTime.now();
    final futuros =
        delMes
            .where((s) => s.fecha == null || !s.fecha!.isBefore(hoy))
            .toList();
    // Si el mes ya paso entero se muestran igual: puede haber que registrar algo
    // de atras.
    final sabados = futuros.isEmpty ? delMes : futuros;

    if (sabados.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: MensajeVacio(
          icono: Icons.event_busy,
          titulo: 'Ese mes no tiene sábados',
          detalle:
              'Cambia el mes en la pestaña Grilla y vuelve a abrir este '
              'formulario.',
        ),
      );
    }

    final elegido = _idSabado;
    final titulares =
        elegido == null
            ? <ParticipanteTurnoEntity>[]
            : g.participantes.where((p) => _tieneTurno(p, elegido)).toList();
    final suplentes =
        elegido == null
            ? <ParticipanteTurnoEntity>[]
            : g.participantes
                .where(
                  (p) => _estaLibre(p, elegido) && p.codEmpleado != _titular,
                )
                .toList();

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nueva permuta o cobertura',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              'Queda SOLICITADO. La grilla no se mueve hasta que alguien lo '
              'apruebe.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: Esp.l),

            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'COBERTURA',
                  label: Text('Cobertura'),
                  icon: Icon(Icons.person_add_alt, size: 16),
                ),
                ButtonSegment(
                  value: 'PERMUTA',
                  label: Text('Permuta'),
                  icon: Icon(Icons.swap_horiz, size: 16),
                ),
              ],
              selected: {_tipo},
              onSelectionChanged:
                  (v) => setState(() {
                    _tipo = v.first;
                    if (_tipo == 'COBERTURA') _idSabadoReposicion = null;
                  }),
            ),
            const SizedBox(height: Esp.s),
            Text(
              _tipo == 'PERMUTA'
                  ? 'Permuta: los dos se cambian el sábado. Uno toma el día del '
                      'otro y viceversa, así ninguno pierde turnos.'
                  : 'Cobertura: alguien cubre y no se devuelve nada. Quien pide '
                      'el cambio queda con un turno menos.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: Esp.l),

            _Combo<int>(
              etiqueta: 'Sábado a cubrir',
              valor: _idSabado,
              opciones: [
                for (final s in sabados)
                  DropdownMenuItem(
                    value: s.idSabado,
                    child: Text(
                      '${fechaCorta(s.fecha)}  ·  rota ${s.grupoQueRota}'
                      '${s.esFeriadoBool ? "  · FERIADO" : ""}',
                    ),
                  ),
              ],
              // Cambiar de sabado invalida a las dos personas: quien tenia turno
              // el 8 puede estar libre el 15.
              onChanged:
                  (v) => setState(() {
                    _idSabado = v;
                    _titular = null;
                    _reemplazo = null;
                    _idSabadoReposicion = null;
                  }),
            ),

            if (elegido == null) ...[
              const SizedBox(height: Esp.l),
              Text(
                'Elige el sábado primero: quién puede pedir el cambio y quién '
                'puede cubrirlo depende de a quién le tocaba ese día.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ] else ...[
              const SizedBox(height: Esp.m),
              ComboBuscable<int>(
                etiqueta: 'Quién no viene',
                valor: _titular,
                ayuda:
                    '${titulares.length} con turno ese sábado, de '
                    '${g.participantes.length}',
                opciones: entradasDePersonas(titulares),
                onElegir:
                    (v) => setState(() {
                      _titular = v;
                      if (_reemplazo == v) _reemplazo = null;
                    }),
              ),
              if (titulares.isEmpty)
                const _Nota(
                  'Ese sábado no viene nadie: puede ser feriado, o todavía no '
                  'se generaron sus celdas.',
                  esAviso: true,
                ),

              const SizedBox(height: Esp.m),
              ComboBuscable<int>(
                etiqueta:
                    _tipo == 'PERMUTA'
                        ? 'Con quién se cambia'
                        : 'Quién cubre (opcional)',
                valor: _reemplazo,
                ayuda: '${suplentes.length} libres ese sábado',
                opciones: entradasDePersonas(suplentes),
                onElegir:
                    (v) => setState(() {
                      _reemplazo = v;
                      _idSabadoReposicion = null;
                    }),
              ),
              const _Nota(
                'Sólo aparece quien estaba libre ese día. Alguien que ya venía '
                'no cubre a nadie: la cobertura bajaría en uno igual.',
              ),

              if (_tipo == 'PERMUTA') ...[
                const SizedBox(height: Esp.m),
                _Combo<int>(
                  etiqueta: 'Sábado que toma a cambio',
                  valor: _idSabadoReposicion,
                  ayuda:
                      _reemplazo == null
                          ? 'Elige primero con quién se cambia'
                          : 'los sábados de esa persona; pasan a ser del titular',
                  // Tiene que ser un dia en el que quien cubre SI tenia turno:
                  // es el que le pasa al titular. Si ya estaba libre no hay nada
                  // que intercambiar.
                  opciones: [
                    if (_reemplazo != null)
                      for (final s in _sabadosConTurnoDe(_reemplazo!))
                        if (s.idSabado != elegido)
                          DropdownMenuItem(
                            value: s.idSabado,
                            child: Text(fechaCorta(s.fecha)),
                          ),
                  ],
                  onChanged: (v) => setState(() => _idSabadoReposicion = v),
                ),
              ],
            ],

            const SizedBox(height: Esp.m),
            TextField(
              controller: _motivo,
              maxLength: 200,
              decoration: const InputDecoration(
                labelText: 'Motivo',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),

            const SizedBox(height: Esp.s),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _puedeGuardar ? _guardar : null,
                icon:
                    _guardando
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.save_outlined),
                label: const Text('Registrar solicitud'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Los sabados del rol en los que esa persona si tiene turno. Se recorre el
  /// anio entero y no solo el mes: la reposicion bien puede caer en otro mes.
  List<SabadoEntity> _sabadosConTurnoDe(int codEmpleado) {
    final p = widget.grilla.participantes.firstWhere(
      (x) => x.codEmpleado == codEmpleado,
      orElse: () => widget.grilla.participantes.first,
    );
    return widget.grilla.sabados
        .where((s) => _tieneTurno(p, s.idSabado))
        .toList();
  }

  bool get _puedeGuardar =>
      !_guardando &&
      _idSabado != null &&
      _titular != null &&
      (_tipo != 'PERMUTA' ||
          (_reemplazo != null && _idSabadoReposicion != null));

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    final ok = await ejecutarAccion(
      context,
      () => ref
          .read(rolSabadosAccionesProvider)
          .registrarCambio(
            idRol: widget.grilla.rol.idRol,
            idSabado: _idSabado!,
            codEmpleadoTitular: _titular!,
            codEmpleadoReemplazo: _reemplazo ?? 0,
            idSabadoReposicion: _idSabadoReposicion ?? 0,
            tipo: _tipo,
            motivo: _motivo.text.trim(),
          ),
      exito: 'Solicitud registrada. Falta aprobarla para que mueva la grilla.',
      cerrar: true,
    );
    if (mounted && !ok) setState(() => _guardando = false);
  }
}

/// Aclaracion corta bajo un campo. Explica POR QUE la lista es la que es: sin
/// eso, una lista corta parece un error de carga.
class _Nota extends StatelessWidget {
  const _Nota(this.texto, {this.esAviso = false});
  final String texto;
  final bool esAviso;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4, left: 2),
    child: Text(
      texto,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color:
            esAviso
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).hintColor,
      ),
    ),
  );
}

class _Combo<T> extends StatelessWidget {
  const _Combo({
    required this.etiqueta,
    required this.valor,
    required this.opciones,
    required this.onChanged,
    this.ayuda,
  });

  final String etiqueta;
  final T? valor;
  final List<DropdownMenuItem<T>> opciones;
  final ValueChanged<T?> onChanged;
  final String? ayuda;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<T>(
    value: valor,
    isExpanded: true,
    decoration: InputDecoration(
      labelText: etiqueta,
      helperText: ayuda,
      border: const OutlineInputBorder(),
      isDense: true,
    ),
    items: opciones,
    // Sin opciones queda deshabilitado, no vacio y clickeable.
    onChanged: opciones.isEmpty ? null : onChanged,
  );
}
