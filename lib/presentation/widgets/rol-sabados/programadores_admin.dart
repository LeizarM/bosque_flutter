/// Quiénes pueden programar a su equipo: el ABM de `trs_Programador`.
///
/// **Por qué existe esta pantalla.** El permiso para usar «Su Equipo» no sale de
/// un rol de Spring ni de un cargo: sale de una fila en `trs_Programador`. Sin
/// una pantalla para escribir esa fila, cada alta y cada baja de un jefe es un
/// ticket a Sistemas y un `INSERT` a mano en el SSMS —para siempre—. Hoy la
/// tabla tiene **una sola fila**: la pestaña la ven exactamente dos personas.
///
/// **Lo que esta pantalla NO hace, a propósito.** No arma el equipo. El equipo
/// lo devuelve el organigrama (`fn_trs_ProgramadorDependiente`) y acá sólo se
/// decide *quién es jefe* y *hasta dónde llega*: sus directos, o todo el árbol
/// debajo suyo. Por eso la columna que más importa de la lista no es el nombre
/// sino el contador de dependientes: es lo único que confirma que el permiso
/// sirve de algo.
library;

import 'package:bosque_flutter/core/state/rol_sabados_provider.dart';
import 'package:bosque_flutter/domain/entities/participante_turno_entity.dart';
import 'package:bosque_flutter/domain/entities/programador_entity.dart';
import 'package:bosque_flutter/presentation/widgets/rol-sabados/estilo_modulo.dart';
import 'package:bosque_flutter/presentation/widgets/rol-sabados/mensajes_usuario.dart';
import 'package:bosque_flutter/presentation/widgets/rol-sabados/rol_sabados_comunes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Abre el ABM de programadores.
///
/// Va en una hoja y no en una pestaña más porque esto lo tocan seis personas de
/// la empresa dos veces al año: no se gana nada ocupando lugar permanente en la
/// barra. El ancho se topea en 720 px — en un monitor, una hoja de 1.900 px deja
/// las tarjetas convertidas en renglones sueltos y perdidos.
Future<void> mostrarAdminProgramadores(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 720),
      builder: (_) => const _PanelProgramadores(),
    );

class _PanelProgramadores extends ConsumerWidget {
  const _PanelProgramadores();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final programadores = ref.watch(programadoresProvider);

    return SizedBox(
      // Alto fijo y no `MainAxisSize.min`: la lista puede tener 1 fila o 40, y
      // una hoja que salta de tamaño cada vez que se da un alta se lee como un
      // error.
      height: MediaQuery.sizeOf(context).height * 0.85,
      child: Column(
        children: [
          const _Encabezado(),
          const Divider(height: 1),
          Expanded(
            child: programadores.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error:
                  (e, _) => MensajeVacio(
                    icono: Icons.error_outline,
                    titulo: 'No se pudo cargar la lista',
                    detalle: textoParaUsuario(e),
                  ),
              data: (lista) {
                if (lista.isEmpty) {
                  return const MensajeVacio(
                    icono: Icons.manage_accounts_outlined,
                    titulo: 'Todavía no hay ningún jefe cargado',
                    detalle:
                        'Nadie ve la pestaña «Su Equipo». Mientras no haya '
                        'nadie aquí, los sábados se arman sólo con la rotación '
                        'A/B y las correcciones de RR.HH.',
                  );
                }

                // La misma persona puede entrar dos veces porque el UNIQUE es
                // (codEmpleado, codSucursal): dos sucursales, dos filas. El SP
                // resuelve con TOP 1, así que la segunda fila no da error —
                // simplemente hace que el organigrama se valide contra un
                // subárbol elegido al azar. Se marca en la lista.
                final repetidos = <int>{};
                final vistos = <int>{};
                for (final p in lista) {
                  if (!vistos.add(p.codEmpleado)) repetidos.add(p.codEmpleado);
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: Esp.s),
                  itemCount: lista.length,
                  separatorBuilder: (_, __) => const SizedBox(height: Esp.xs),
                  itemBuilder:
                      (_, i) => _Tarjeta(
                        programador: lista[i],
                        repetido: repetidos.contains(lista[i].codEmpleado),
                      ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Esp.l, Esp.m, Esp.l, Esp.m),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _abrirAlta(context),
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Dar de alta a un jefe'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _abrirAlta(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: 720),
    builder: (_) => const _AltaProgramadorSheet(),
  );
}

class _Encabezado extends StatelessWidget {
  const _Encabezado();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(Esp.l, 0, Esp.l, Esp.m),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quién programa a su equipo',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: Esp.xs),
        Text(
          'Estas personas ven la pestaña «Su Equipo» y deciden quién de su '
          'gente viene cada sábado. El equipo lo arma el organigrama, no esta '
          'lista.',
          style: context.apagado(),
        ),
        const SizedBox(height: Esp.xs),
        Text(
          'Mira el número de la derecha: es cuánta gente le da el organigrama '
          'HOY. Si dice 0, el jefe abre «Su Equipo» y no ve a nadie.',
          style: context.apagado(),
        ),
      ],
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// LISTADO
// ═══════════════════════════════════════════════════════════════════════════

class _Tarjeta extends ConsumerStatefulWidget {
  const _Tarjeta({required this.programador, required this.repetido});

  final ProgramadorEntity programador;
  final bool repetido;

  @override
  ConsumerState<_Tarjeta> createState() => _TarjetaState();
}

class _TarjetaState extends ConsumerState<_Tarjeta> {
  bool _ocupado = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.programador;
    final nombre = p.jefe.isEmpty ? 'Empleado #${p.codEmpleado}' : p.jefe;
    final sinGente = p.dependientes == 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: Esp.m, vertical: 2),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Esp.l, Esp.m, Esp.s, Esp.m),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Wrap y no Row: nombre + dos o tres etiquetas no entran en
                  // los ~250 px que quedan libres en un teléfono de 360.
                  Wrap(
                    spacing: Esp.s,
                    runSpacing: Esp.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        nombre,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Etiqueta(texto: _textoAlcance(p.alcance)),
                      if (sinGente)
                        const Etiqueta(
                          texto: 'SIN GENTE',
                          tono: TonoEtiqueta.aviso,
                        ),
                      if (widget.repetido)
                        const Etiqueta(
                          texto: 'FILA REPETIDA',
                          tono: TonoEtiqueta.error,
                        ),
                      if (!p.activo)
                        const Etiqueta(
                          texto: 'DE BAJA',
                          tono: TonoEtiqueta.error,
                        ),
                    ],
                  ),
                  const SizedBox(height: Esp.xs),
                  // Tres casos distintos y hay que distinguirlos: sin sucursal
                  // el permiso alcanza a TODAS —no es un dato faltante, es el
                  // alcance más ancho que existe—; con nombre se muestra el
                  // nombre; y si el backend todavía no lo manda queda el código,
                  // que al menos no miente.
                  Dato(
                    '#${p.codEmpleado} · '
                    '${p.codSucursal == 0 ? 'todas las sucursales' : (p.sucursal.isEmpty ? 'sucursal ${p.codSucursal}' : p.sucursal)}',
                  ),
                  Dato(
                    p.codEmpleadoReemplazo == 0
                        ? 'Sin reemplazo: si el jefe no está, nadie programa '
                            'por él.'
                        : 'Lo reemplaza: '
                            '${p.reemplazo.isEmpty ? '#${p.codEmpleadoReemplazo}' : p.reemplazo}',
                  ),
                  if (sinGente) ...[
                    const SizedBox(height: Esp.xs),
                    _Aviso(
                      'El organigrama no le devuelve a nadie, así que este '
                      'permiso no sirve para nada todavía. Suele ser que el '
                      'nombre del jefe está escrito distinto en la ficha de su '
                      'gente: el organigrama se une por texto y una rama mal '
                      'cargada no da error, deja al jefe sin equipo.',
                    ),
                  ],
                  if (widget.repetido) ...[
                    const SizedBox(height: Esp.xs),
                    _Aviso(
                      'Esta persona tiene más de una fila. El sistema usa una '
                      'sola —la primera que encuentra— y valida el organigrama '
                      'contra ese alcance. Deja una y da de baja la otra.',
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: Esp.s),
            _Dependientes(cantidad: p.dependientes),
            _ocupado
                ? const Padding(
                  padding: EdgeInsets.all(Esp.m),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
                : IconButton(
                  tooltip: 'Dar de baja',
                  icon: const Icon(Icons.person_remove_outlined),
                  onPressed: _confirmarBaja,
                ),
          ],
        ),
      ),
    );
  }

  String _textoAlcance(String alcance) =>
      alcance == 'SUBARBOL' ? 'Todo su árbol' : 'Sólo sus directos';

  Future<void> _confirmarBaja() async {
    final p = widget.programador;
    final nombre = p.jefe.isEmpty ? 'Empleado #${p.codEmpleado}' : p.jefe;

    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text('¿Dar de baja a $nombre?'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Deja de ver la pestaña «Su Equipo» y no puede programar a '
                    'nadie más.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: Esp.m),
                  Text(
                    'Es una baja lógica: la fila no se borra, queda inactiva. '
                    'Los sábados que este jefe ya programó NO se tocan — la '
                    'grilla queda igual y el historial también.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: Esp.s),
                  Text(
                    'Si más adelante hay que devolverle el permiso, se lo da de '
                    'alta de nuevo desde esta misma pantalla.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Dar de baja'),
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
          .eliminarProgramador(idProgramador: p.idProgramador),
      exito: '$nombre ya no programa a su equipo.',
    );
    if (mounted) setState(() => _ocupado = false);
  }
}

/// El contador de dependientes: el dato que dice si el permiso sirve.
///
/// Va en un bloque propio y con cifras tabulares porque es lo único de la
/// tarjeta que se compara entre filas — 20 contra 0 se tiene que ver de un
/// vistazo, sin leer.
class _Dependientes extends StatelessWidget {
  const _Dependientes({required this.cantidad});
  final int cantidad;

  @override
  Widget build(BuildContext context) {
    final vacio = cantidad == 0;
    return SizedBox(
      width: 62,
      child: Column(
        children: [
          Text(
            '$cantidad',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: Peso.dato,
              fontFeatures: cifrasTabulares,
              color: vacio ? context.cs.error : null,
            ),
          ),
          Text(
            'a cargo',
            textAlign: TextAlign.center,
            style: context.apagado(),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ALTA
// ═══════════════════════════════════════════════════════════════════════════

/// Formulario de alta de un jefe programador.
///
/// La lista de gente sale de los **participantes del rol** y no del padrón de
/// empleados: programar a alguien que no está en el rol no tiene sentido —no
/// tiene celdas que escribir— y de paso evita ofrecer 1.200 nombres para elegir
/// uno.
class _AltaProgramadorSheet extends ConsumerStatefulWidget {
  const _AltaProgramadorSheet();

  @override
  ConsumerState<_AltaProgramadorSheet> createState() => _AltaState();
}

class _AltaState extends ConsumerState<_AltaProgramadorSheet> {
  int? _codEmpleado;

  /// 0 = sin reemplazo. Se usa el 0 y no null porque el combo necesita una
  /// opción concreta para poder *sacar* al reemplazo una vez elegido.
  int _codReemplazo = 0;

  String _alcance = 'DIRECTOS';

  /// `true` guarda `codSucursal` en NULL, que en `fn_trs_DependientePorCargo`
  /// apaga el filtro de sucursal. Arranca en `false` porque el caso normal es
  /// el jefe cuya gente está donde él, y el permiso más angosto es el que
  /// conviene por defecto.
  bool _todasLasSucursales = false;

  final _observacion = TextEditingController();
  bool _guardando = false;

  /// Lo que se va a guardar en `codSucursal`. **0 significa TODAS**, igual que
  /// el NULL de la tabla — el repositorio hace la conversión.
  int _sucursalAGuardar(ParticipanteTurnoEntity elegido) =>
      _todasLasSucursales ? 0 : elegido.codSucursal;

  @override
  void dispose() {
    _observacion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final idRol = ref.watch(rolSeleccionadoProvider);

    // Alto fijo en los estados que no son el formulario: `MensajeVacio` y el
    // spinner son `Center`, y un Center suelto adentro de una hoja
    // `isScrollControlled` la estira a pantalla completa para mostrar dos
    // renglones.
    if (idRol == null) {
      return const SizedBox(
        height: 240,
        child: MensajeVacio(
          icono: Icons.calendar_month_outlined,
          titulo: 'Elige un rol primero',
          detalle:
              'La lista de gente sale de los participantes del rol. '
              'Selecciona el año arriba y vuelve a abrir esta pantalla.',
        ),
      );
    }

    final grilla = ref.watch(grillaRolProvider(idRol));

    return Padding(
      padding: EdgeInsets.only(
        left: Esp.xl,
        right: Esp.xl,
        top: Esp.s,
        bottom: MediaQuery.of(context).viewInsets.bottom + Esp.xl,
      ),
      child: grilla.when(
        loading:
            () => const SizedBox(
              height: 240,
              child: Center(child: CircularProgressIndicator()),
            ),
        error:
            (e, _) => SizedBox(
              height: 240,
              child: MensajeVacio(
                icono: Icons.error_outline,
                titulo: 'No se pudo cargar el personal',
                detalle: textoParaUsuario(e),
              ),
            ),
        data: (g) => _formulario(context, idRol, g.participantes),
      ),
    );
  }

  Widget _formulario(
    BuildContext context,
    // Viene por parámetro y no se vuelve a leer del provider: acá arriba ya se
    // comprobó que no es null, y volver a pedirlo obligaría a comprobarlo otra
    // vez o a poner un `!` que el día que cambie el flujo revienta en pantalla.
    int idRol,
    List<ParticipanteTurnoEntity> gente,
  ) {
    final elegido = _buscar(gente, _codEmpleado);

    // Los que ya están cargados: se necesita para avisar del duplicado ANTES de
    // guardar, que es cuando todavía se puede evitar.
    final yaCargados =
        ref.watch(programadoresProvider).valueOrNull ??
        const <ProgramadorEntity>[];
    final repetido = _yaFigura(yaCargados, _codEmpleado);

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nuevo jefe programador',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(
            'Desde que se guarda, esa persona ve la pestaña «Su Equipo» y puede '
            'poner o sacar del sábado a su gente.',
            style: context.apagado(),
          ),
          const SizedBox(height: Esp.l),

          ComboBuscable<int>(
            etiqueta: 'Quién va a programar',
            valor: _codEmpleado,
            ayuda: '${gente.length} personas del rol',
            opciones: entradasDePersonas(gente, mostrarGrupo: false),
            onElegir:
                (v) => setState(() {
                  _codEmpleado = v;
                  // Nadie se reemplaza a sí mismo.
                  if (_codReemplazo == v) _codReemplazo = 0;
                }),
          ),
          // Sin sucursal cargada no se puede elegir «sólo la suya»: no sabemos
          // cuál es. Con «Todas» sí se puede guardar, porque ahí la sucursal
          // deja de importar.
          if (elegido != null && elegido.codSucursal == 0 && !_todasLasSucursales)
            _Aviso(
              'Esa persona no tiene sucursal en la foto de este rol, así que no '
              'se puede limitar el permiso a la suya. Elige «Todas» aquí abajo, o '
              'pídele a RR.HH. que le cargue el cargo con su sucursal y regenera '
              'el rol para que entre en la foto.',
            ),
          if (repetido != null)
            _Aviso(
              '${repetido.jefe.isEmpty ? 'Esa persona' : repetido.jefe} ya está '
              'en la lista, con alcance ${_alcanceLegible(repetido.alcance)}. '
              'Una segunda fila no da error pero deja al sistema eligiendo una '
              'de las dos: si lo que quieres es cambiarle el alcance o el '
              'reemplazo, dale de baja y créala de nuevo.',
            ),

          // ── DOS controles y no uno de tres opciones ──────────────────────
          //
          // Profundidad y sucursal son dos dimensiones independientes en
          // `trs_Programador` (`alcance` y `codSucursal`), y colapsarlas en un
          // solo selector deja combinaciones sin representar. No es teórico: el
          // JEFE COMERCIAL Y DE PRODUCCIÓN tiene a su RESPONSABLE DE PRODUCCIÓN
          // colgando DIRECTO, pero en la planta de ACHOCALLA — con la sucursal
          // fija no le aparecía ni con «Sus directos» ni con «Todo su árbol»,
          // porque la sucursal corta ANTES que la profundidad.
          const SizedBox(height: Esp.l),
          Text('Hasta dónde baja', style: context.tituloSeccion()),
          const SizedBox(height: Esp.s),
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 'DIRECTOS', label: Text('Sus directos')),
              ButtonSegment(value: 'SUBARBOL', label: Text('Todo su árbol')),
            ],
            selected: {_alcance},
            onSelectionChanged: (v) => setState(() => _alcance = v.first),
          ),
          const SizedBox(height: Esp.s),
          Text(
            _alcance == 'SUBARBOL'
                ? 'Todo su árbol: además de sus directos, la gente de sus jefes '
                    'intermedios.'
                : 'Sus directos: sólo quienes le reportan directo. Si un '
                    'supervisor suyo tiene gente, esa gente no le aparece.',
            style: context.apagado(),
          ),

          const SizedBox(height: Esp.l),
          Text('En qué sucursales', style: context.tituloSeccion()),
          const SizedBox(height: Esp.s),
          SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: false,
                label: Text(
                  elegido == null || elegido.sucursal.isEmpty
                      ? 'Sólo la suya'
                      : 'Sólo ${elegido.sucursal}',
                ),
              ),
              const ButtonSegment(value: true, label: Text('Todas')),
            ],
            selected: {_todasLasSucursales},
            onSelectionChanged:
                (v) => setState(() => _todasLasSucursales = v.first),
          ),
          const SizedBox(height: Esp.s),
          Text(
            _todasLasSucursales
                ? 'Todas: le llega su gente esté en la sucursal que esté. Es lo '
                    'que necesita un jefe cuya planta o depósito están en otra '
                    'sucursal que su oficina.'
                : 'Sólo la suya: se le esconde la gente que le reporta desde '
                    'otra sucursal, aunque le cuelgue directo en el organigrama.',
            style: context.apagado(),
          ),

          if (elegido != null &&
              (_todasLasSucursales || elegido.codSucursal != 0)) ...[
            const SizedBox(height: Esp.m),
            _PreviaDependientes(
              clave: (
                codEmpleado: elegido.codEmpleado,
                codSucursal: _sucursalAGuardar(elegido),
                alcance: _alcance,
                idRol: idRol,
              ),
            ),
          ],

          const SizedBox(height: Esp.l),
          ComboBuscable<int>(
            etiqueta: 'Quién programa cuando el jefe no está',
            valor: _codReemplazo,
            ayuda: 'Opcional. Vaciarlo después no borra el que ya tenga.',
            opciones: [
              const DropdownMenuEntry(value: 0, label: 'Sin reemplazo'),
              ...entradasDePersonas(
                gente.where((p) => p.codEmpleado != _codEmpleado).toList(),
                mostrarGrupo: false,
              ),
            ],
            onElegir: (v) => setState(() => _codReemplazo = v ?? 0),
          ),
          const _Nota(
            'El reemplazo ve el mismo equipo y programa igual, pero queda '
            'registrado que apretó él. Ten en cuenta una cosa: si mañana se vuelve a '
            'guardar esta fila con el reemplazo vacío, el que estaba NO se '
            'borra. Para sacarlo hay que dar de baja al jefe y crearlo de nuevo.',
          ),

          const SizedBox(height: Esp.l),
          TextField(
            controller: _observacion,
            maxLength: 200,
            decoration: const InputDecoration(
              labelText: 'Observación',
              helperText: 'Por qué se le da el permiso. Queda en la ficha.',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),

          const SizedBox(height: Esp.s),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              // Se apaga sólo cuando se pidió «sólo la suya» y no sabemos cuál
              // es: ahí guardar crearía en silencio un permiso para TODAS, más
              // ancho del que se pidió — el tipo de error que nadie sale a
              // buscar porque no falla nada, sólo aparece gente de más.
              // Con «Todas» elegido a mano no hay ambigüedad y se puede guardar.
              onPressed:
                  (_guardando ||
                          elegido == null ||
                          (elegido.codSucursal == 0 && !_todasLasSucursales))
                      ? null
                      : () => _guardar(elegido, repetido),
              icon:
                  _guardando
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.save_outlined),
              label: const Text('Dar de alta'),
            ),
          ),
        ],
      ),
    );
  }

  ParticipanteTurnoEntity? _buscar(
    List<ParticipanteTurnoEntity> gente,
    int? codEmpleado,
  ) {
    if (codEmpleado == null) return null;
    for (final p in gente) {
      if (p.codEmpleado == codEmpleado) return p;
    }
    return null;
  }

  ProgramadorEntity? _yaFigura(
    List<ProgramadorEntity> lista,
    int? codEmpleado,
  ) {
    if (codEmpleado == null) return null;
    for (final p in lista) {
      if (p.codEmpleado == codEmpleado && p.activo) return p;
    }
    return null;
  }

  String _alcanceLegible(String alcance) =>
      alcance == 'SUBARBOL' ? 'todo su árbol' : 'sólo sus directos';

  Future<void> _guardar(
    ParticipanteTurnoEntity elegido,
    ProgramadorEntity? repetido,
  ) async {
    // Segunda barrera para el duplicado: el aviso de arriba se puede pasar por
    // alto, y la fila de más no falla en el momento sino la semana que viene,
    // cuando el jefe abre «Su Equipo» y ve gente que no es suya.
    if (repetido != null) {
      final seguir = await showDialog<bool>(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: const Text('Ya está cargado'),
              content: Text(
                '${elegido.nombreRol} ya figura como programador con alcance '
                '${_alcanceLegible(repetido.alcance)}.\n\n'
                'Guardar de nuevo puede crear una segunda fila (el sistema '
                'admite una por sucursal) y a partir de ahí elige una sola de '
                'las dos, sin avisar.\n\n'
                'Lo recomendable es cancelar, darlo de baja y crearlo con los '
                'datos nuevos.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Guardar igual'),
                ),
              ],
            ),
      );
      if (seguir != true) return;
    }

    setState(() => _guardando = true);
    final ok = await ejecutarAccion(
      context,
      () => ref
          .read(rolSabadosAccionesProvider)
          .registrarProgramador(
            // 0 = alta. Con un id > 0 el SP actualiza la fila existente.
            idProgramador: 0,
            codEmpleado: elegido.codEmpleado,
            // 0 = todas, que es como el repositorio expresa el NULL de la
            // tabla. Cuál sucursal concreta no se pregunta —siempre es la de la
            // persona— pero SÍ se pregunta si limita o no, que es otra cosa.
            codSucursal: _sucursalAGuardar(elegido),
            alcance: _alcance,
            codEmpleadoReemplazo: _codReemplazo,
            observacion: _observacion.text.trim(),
          ),
      exito:
          '${elegido.nombreRol} ya puede programar a su equipo. '
          'Si le figura 0 a cargo, hay que revisar el organigrama.',
      cerrar: true,
    );
    if (mounted && !ok) setState(() => _guardando = false);
  }
}

// ═══════════════════════════════════════════════════════════════════════════

/// Aclaración bajo un campo: explica POR QUÉ, no qué.
/// Quiénes le van a quedar a cargo, **antes** de apretar «Dar de alta».
///
/// **Por qué existe.** El alcance no se puede razonar mirando la pantalla: sale
/// de recorrer `trh_cargo.codCargoPadre` hasta doce niveles, filtrando por
/// sucursal y por empresa. Antes de esto, la única forma de saber a quién le
/// habías dado el permiso era guardarlo y leer el conteo que devolvía el SP —o
/// sea, enterarte después—. Con dos opciones de alcance que se parecen en el
/// nombre, eso es exactamente donde se elige mal.
///
/// **Sale del mismo árbol que valida `trs_sp_programar`**
/// (`fn_trs_DependientePorCargo`). Si fuera una consulta propia, esta lista y lo
/// que el sistema después acepta podrían separarse, y una previsualización que
/// miente es peor que no tenerla.
class _PreviaDependientes extends ConsumerWidget {
  const _PreviaDependientes({required this.clave});

  final PreviaDePermiso clave;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final previa = ref.watch(previaDependientesProvider(clave));

    return previa.when(
      // Sin alto fijo: son dos renglones dentro de un formulario que ya
      // scrollea, y reservarles espacio haría saltar todo lo de abajo cada vez
      // que se toca el alcance.
      loading:
          () => const Padding(
            padding: EdgeInsets.symmetric(vertical: Esp.s),
            child: Row(
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: Esp.s),
                Text('Buscando en el organigrama…'),
              ],
            ),
          ),
      error:
          (e, _) => _Aviso(
            'No se pudo calcular a quiénes alcanzaría. ${textoParaUsuario(e)}',
          ),
      data: (lista) {
        if (lista.isEmpty) {
          return const _Aviso(
            'Con ese alcance el organigrama no le da NINGÚN dependiente, así que '
            'el permiso no le serviría de nada: vería la pestaña «Su Equipo» '
            'vacía. Prueba con «Todo su árbol», o revisa que su cargo tenga gente '
            'colgando en el organigrama de RR.HH.',
          );
        }

        final fuera = lista.where((d) => !d.participaDelRol).length;
        final directos = lista.where((d) => d.esDirecto).length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Le quedarían ${lista.length} a cargo'
              '${clave.alcance == 'SUBARBOL' && directos != lista.length ? ' · $directos directos y ${lista.length - directos} más abajo' : ''}',
              style: context.tituloSeccion(),
            ),
            if (fuera > 0)
              _Nota(
                fuera == 1
                    ? '1 de ellos no participa del rol de este año, así que no '
                        'va a poder moverle el sábado hasta que entre.'
                    : '$fuera de ellos no participan del rol de este año, así '
                        'que no va a poder moverles el sábado hasta que entren.',
              ),
            const SizedBox(height: Esp.s),
            // Alto acotado a propósito: un `ListView` suelto adentro del
            // `SingleChildScrollView` del formulario no tiene altura definida y
            // revienta. 168 px son cuatro filas — suficiente para ver que la
            // lista es la esperada, y el resto se scrollea acá adentro sin
            // empujar el botón de guardar fuera de la pantalla.
            Container(
              constraints: const BoxConstraints(maxHeight: 168),
              decoration: BoxDecoration(
                border: Border.all(color: context.cs.outlineVariant),
                borderRadius: BorderRadius.circular(Esp.xs),
              ),
              child: Scrollbar(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: Esp.xs),
                  itemCount: lista.length,
                  itemBuilder: (_, i) {
                    final d = lista[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Esp.s,
                        vertical: 3,
                      ),
                      child: Row(
                        children: [
                          // La profundidad importa: «1» es su gente, «3» es
                          // gente que probablemente ni sepa que le cuelga.
                          SizedBox(
                            width: 22,
                            child: Text(
                              d.esDirecto ? '·' : '${d.profundidad}',
                              textAlign: TextAlign.center,
                              style: context.apagado(),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              d.nombreDependiente,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  d.participaDelRol
                                      ? null
                                      : TextStyle(color: context.cs.error),
                            ),
                          ),
                          if (!d.participaDelRol)
                            Text('fuera del rol', style: context.apagado()),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Nota extends StatelessWidget {
  const _Nota(this.texto);
  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: Esp.xs, left: 2),
    child: Text(texto, style: context.apagado()),
  );
}

/// Lo mismo, pero cuando el dato está mal y alguien tiene que hacer algo.
class _Aviso extends StatelessWidget {
  const _Aviso(this.texto);
  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: Esp.xs, left: 2),
    child: Text(
      texto,
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: context.cs.error),
    ),
  );
}
