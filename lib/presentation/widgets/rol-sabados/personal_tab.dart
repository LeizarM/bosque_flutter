import 'package:bosque_flutter/core/state/rol_sabados_provider.dart';
import 'package:bosque_flutter/domain/entities/participante_turno_entity.dart';
import 'package:bosque_flutter/domain/entities/sabado_entity.dart';
import 'package:bosque_flutter/presentation/widgets/rol-sabados/filtros_grilla.dart';
import 'package:bosque_flutter/presentation/widgets/rol-sabados/rol_sabados_comunes.dart';
import 'package:bosque_flutter/presentation/widgets/rol-sabados/estilo_modulo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Armar los grupos A y B a mano, persona por persona.
///
/// El reparto automático (sucursal, cargo, apellido, A/B alternado) es ciego al
/// oficio; el cambio manual sobrevive a las regeneraciones (`trs_sp_generarRol`
/// asigna grupo sólo a quien entra por primera vez). Aquí también se cierra y
/// abre la ventana de participación (NO es dar de baja al empleado; el backend
/// borra sólo celdas futuras y de la rotación). Sólo Sistemas o RR.HH. editan.
class PersonalTab extends ConsumerWidget {
  const PersonalTab({super.key, required this.idRol});

  final int idRol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grilla = ref.watch(grillaRolProvider(idRol));

    return grilla.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (e, _) => MensajeVacio(
            icono: Icons.error_outline,
            titulo: 'No se pudo cargar el personal',
            detalle: '$e',
          ),
      data: (g) {
        final busqueda = ref.watch(busquedaPersonaProvider);
        final grupo = ref.watch(filtroGrupoProvider);

        // Quién hace sábados HOY y quién no: la separación manda en todo lo de abajo.
        // Los contadores de A y B (y el aviso de «desparejo») hablan del reparto real
        // de este sábado, no de la nómina.
        final vigentes = <ParticipanteTurnoEntity>[];
        final afuera = <ParticipanteTurnoEntity>[];
        for (final p in g.participantes) {
          (p.haceSabados ? vigentes : afuera).add(p);
        }

        // Los dos filtros se encadenan: primero la letra (más barata), después el
        // texto, así el `contains` corre sobre menos.
        final base =
            grupo == filtroSinSabados
                ? afuera
                : grupo.isEmpty
                ? vigentes
                : vigentes.where((p) => p.grupoRotacion == grupo).toList();
        final personas = filtrarPersonas(base, busqueda);

        final enA = vigentes.where((p) => p.grupoRotacion == 'A').length;
        final enB = vigentes.where((p) => p.grupoRotacion == 'B').length;

        // El ABM de la ventana es de RR.HH.: decide quién viene a trabajar y no se
        // delega en quien va a venir; un jefe ve la lista (también los excluidos) sin
        // tocarla. Sale de [administraRolProvider] y no de `tipoUsuario == 'ROLE_ADM'`
        // (esa copia le escondía el menú a RR.HH.).
        final administra = ref.watch(administraRolProvider);

        // Una vez para las 85 filas: es un recorrido de 52 sábados con la misma
        // respuesta para todos.
        final quedanSabados = sabadosQueVienen(g).isNotEmpty;

        return Column(
          children: [
            _Balance(
              enA: enA,
              enB: enB,
              sinSabados: afuera.length,
              filtro: grupo,
            ),
            const Divider(height: 1),
            _Buscador(total: g.participantes.length, visibles: personas.length),
            const Divider(height: 1),
            Expanded(
              child:
                  personas.isEmpty
                      ? _NadaQueMostrar(filtro: grupo, busqueda: busqueda)
                      : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 96),
                        itemCount: personas.length,
                        itemBuilder:
                            (_, i) => _FilaPersona(
                              idRol: idRol,
                              persona: personas[i],
                              grilla: g,
                              administra: administra,
                              quedanSabados: quedanSabados,
                            ),
                      ),
            ),
          ],
        );
      },
    );
  }
}

/// Los sábados del rol a los que todavía se llega, en orden.
///
/// La ventana mira de hoy en adelante: el pasado no se toca, ofrecer un sábado
/// de marzo no cambiaría nada.
List<SabadoEntity> sabadosQueVienen(GrillaRol g) {
  final hoy = DateTime.now();
  final desde = DateTime(hoy.year, hoy.month, hoy.day);
  final futuros =
      g.sabados
          .where(
            (s) =>
                s.activo == 1 && s.fecha != null && !s.fecha!.isBefore(desde),
          )
          .toList();
  futuros.sort((a, b) => a.fecha!.compareTo(b.fecha!));
  return futuros;
}

/// Cuántos quedaron en cada grupo, qué significa que estén desparejos y el
/// filtro de la lista de abajo.
///
/// **Los contadores SON el filtro** (`ChoiceChip`, como en «Cambios» y «Su
/// equipo»). No son del resultado de la búsqueda: de esa cuenta sale el aviso de
/// «desparejo». A y B cuentan sólo a quien hace sábados; el excluido conserva
/// su letra y se cuenta aparte en su propio chip.
class _Balance extends ConsumerWidget {
  const _Balance({
    required this.enA,
    required this.enB,
    required this.sinSabados,
    required this.filtro,
  });

  final int enA;
  final int enB;

  /// Cuántos quedaron fuera de los sábados. Su chip **sólo aparece si hay
  /// alguien**: en la mayoría de los roles no hay ninguno.
  final int sinSabados;

  /// `'A'`, `'B'`, [filtroSinSabados] o `''` para todos los que hacen sábados.
  final String filtro;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final total = enA + enB;
    final diferencia = (enA - enB).abs();
    // Con un total impar la diferencia de 1 es inevitable, no un problema.
    final desparejo = diferencia > (total.isOdd ? 1 : 0);

    void mostrar(String grupo) =>
        ref.read(filtroGrupoProvider.notifier).state = grupo;

    return Padding(
      padding: const EdgeInsets.all(Esp.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Wrap y no Row: en 360 px quedan 336 útiles y los tres chips miden ~380 (~95
          // «Todos», ~143 cada grupo por la insignia), más el aviso «Diferencia de N».
          Wrap(
            spacing: Esp.m,
            runSpacing: Esp.s,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _ChipGrupo(
                etiqueta: 'Todos',
                cantidad: total,
                elegido: filtro.isEmpty,
                onElegir: () => mostrar(''),
              ),
              _ChipGrupo(
                etiqueta: 'Grupo A',
                grupo: 'A',
                cantidad: enA,
                elegido: filtro == 'A',
                onElegir: () => mostrar('A'),
              ),
              _ChipGrupo(
                etiqueta: 'Grupo B',
                grupo: 'B',
                cantidad: enB,
                elegido: filtro == 'B',
                onElegir: () => mostrar('B'),
              ),
              // Cuarto chip y no un switch aparte: es otra vista de la misma lista y reusa el
              // mismo estado. Apagados pero detrás de un chip, no escondidos: si el excluido
              // no aparece en ningún lado, nadie lo puede devolver a los sábados.
              if (sinSabados > 0)
                _ChipGrupo(
                  etiqueta: 'Sin sábados',
                  icono: Icons.event_busy_outlined,
                  cantidad: sinSabados,
                  elegido: filtro == filtroSinSabados,
                  onElegir: () => mostrar(filtroSinSabados),
                ),
              if (desparejo)
                Text(
                  'Diferencia de $diferencia',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: cs.error,
                    fontWeight: Peso.titulo,
                  ),
                ),
            ],
          ),
          const SizedBox(height: Esp.s),
          Text(
            filtro == filtroSinSabados
                ? 'Estas personas no entran en el reparto de los sábados. Lo que '
                    'ya trabajaron sigue en la grilla; desde su fecha no se les '
                    'genera ningún sábado más.'
                : desparejo
                ? 'Los grupos están desparejos: el sábado del grupo más chico va '
                    'a tener menos gente que el otro.'
                : 'El grupo A trabaja los sábados impares del año y el B los '
                    'pares. Cambiar a alguien de grupo le cambia todos sus '
                    'sábados.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Theme.of(context).hintColor),
          ),
        ],
      ),
    );
  }
}

/// Un contador que además filtra.
///
/// La insignia es la misma [InsigniaGrupo] de la matriz y la agenda (el color
/// del grupo significa lo mismo en las tres vistas). Elegido, Material pone su
/// tilde en lugar de la insignia; la letra sigue en el rótulo.
class _ChipGrupo extends StatelessWidget {
  const _ChipGrupo({
    required this.etiqueta,
    required this.cantidad,
    required this.elegido,
    required this.onElegir,
    this.grupo,
    this.icono,
  });

  final String etiqueta;

  /// `null` en el chip de «Todos», que no es de ningún grupo.
  final String? grupo;

  /// Para el chip sin grupo que necesita marca propia («Sin sábados»). Se ignora
  /// si viene [grupo].
  final IconData? icono;

  final int cantidad;
  final bool elegido;
  final VoidCallback onElegir;

  @override
  Widget build(BuildContext context) {
    final g = grupo;
    final i = icono;
    return ChoiceChip(
      avatar:
          g != null
              ? InsigniaGrupo(grupo: g)
              : (i == null ? null : Icon(i, size: 18)),
      label: Text('$etiqueta · $cantidad'),
      selected: elegido,
      // Volver a tocar el elegido no lo apaga: siempre hay uno prendido y «Todos» es
      // el único camino de vuelta (con toggle, «ninguno» y «Todos» serían dos
      // estados que muestran la misma lista).
      onSelected: (_) => onElegir(),
    );
  }
}

/// Por qué la lista quedó vacía y cómo salir.
///
/// Con dos filtros encimados, un «no hay nadie» no dice cuál sacar, y el del
/// grupo no tiene una ✕ para deshacerlo de un toque.
class _NadaQueMostrar extends StatelessWidget {
  const _NadaQueMostrar({required this.filtro, required this.busqueda});

  final String filtro;
  final String busqueda;

  @override
  Widget build(BuildContext context) {
    if (filtro.isEmpty) {
      return const MensajeVacio(
        icono: Icons.person_search,
        titulo: 'Nadie coincide con la búsqueda',
        detalle: 'Prueba con parte del apellido o el código.',
      );
    }
    if (filtro == filtroSinSabados) {
      return MensajeVacio(
        icono: Icons.event_busy_outlined,
        titulo:
            busqueda.isEmpty
                ? 'Todos hacen sábados'
                : 'Nadie sin sábados coincide con la búsqueda',
        detalle:
            'Estás viendo a quienes quedaron fuera de los sábados. Toca '
            '«Todos» arriba para volver al rol.',
      );
    }
    return MensajeVacio(
      icono: Icons.filter_alt_off_outlined,
      titulo:
          busqueda.isEmpty
              ? 'No hay nadie en el grupo $filtro'
              : 'Nadie del grupo $filtro coincide con la búsqueda',
      detalle:
          busqueda.isEmpty
              ? 'Estás viendo sólo el grupo $filtro y quedó sin gente. Toca '
                  '«Todos» arriba para ver el rol entero.'
              : 'Están puestos los dos filtros. Toca «Todos» arriba para buscar '
                  'en los dos grupos, o limpia la búsqueda con la ✕.',
    );
  }
}

class _Buscador extends ConsumerStatefulWidget {
  const _Buscador({required this.total, required this.visibles});
  final int total;
  final int visibles;

  @override
  ConsumerState<_Buscador> createState() => _BuscadorState();
}

class _BuscadorState extends ConsumerState<_Buscador> {
  late final TextEditingController _texto;

  @override
  void initState() {
    super.initState();
    _texto = TextEditingController(text: ref.read(busquedaPersonaProvider));
  }

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final busqueda = ref.watch(busquedaPersonaProvider);
    return Padding(
      padding: const EdgeInsets.all(Esp.m),
      child: TextField(
        controller: _texto,
        decoration: InputDecoration(
          hintText: 'Buscar por apellido o código…',
          // El rótulo mira cuánto quedó, NO si hay texto: el filtro de grupo achica la
          // lista sin tocar el buscador y con «¿hay búsqueda?» decía «85 personas» sobre
          // 43 filas. Así es cierto con cualquiera de los filtros, ambos o ninguno.
          labelText:
              widget.visibles == widget.total
                  ? '${widget.total} personas'
                  : '${widget.visibles} de ${widget.total} personas',
          border: const OutlineInputBorder(),
          isDense: true,
          prefixIcon: const Icon(Icons.search, size: 18),
          suffixIcon:
              busqueda.isEmpty
                  ? null
                  : IconButton(
                    tooltip: 'Limpiar',
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      _texto.clear();
                      ref.read(busquedaPersonaProvider.notifier).state = '';
                    },
                  ),
        ),
        onChanged: (v) => ref.read(busquedaPersonaProvider.notifier).state = v,
      ),
    );
  }
}

class _FilaPersona extends ConsumerStatefulWidget {
  const _FilaPersona({
    required this.idRol,
    required this.persona,
    required this.grilla,
    required this.administra,
    required this.quedanSabados,
  });

  final int idRol;
  final ParticipanteTurnoEntity persona;

  /// La grilla entera y no sólo el contador de turnos: los diálogos de la
  /// ventana necesitan los sábados que vienen y las celdas de esta persona.
  final GrillaRol grilla;

  /// Sistemas o RR.HH.: los dos únicos que mueven la ventana de sábados.
  final bool administra;

  /// Si el rol todavía tiene algún sábado por delante.
  final bool quedanSabados;

  int get turnos => grilla.turnosDe(persona.idParticipante);
  bool get bloqueado => grilla.rol.estaCerrado;

  @override
  ConsumerState<_FilaPersona> createState() => _FilaPersonaState();
}

class _FilaPersonaState extends ConsumerState<_FilaPersona> {
  bool _guardando = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.persona;
    final hayContexto = p.cargo.isNotEmpty || p.sucursal.isNotEmpty;
    final fuera = !p.haceSabados;

    // El menú pregunta por la DECISIÓN, no por si ya rige: quien sale en diciembre
    // sigue viniendo hasta entonces (no es `fuera`) pero ya se lo sacó, y debe
    // poder devolvérselo hoy.
    final decidido = p.salidaDecidida;

    // El menú necesita un sábado al que llegar: en un rol del año pasado no se
    // ofrece (nada que liberar ni agregar). Tampoco a quien ya no figura en la
    // relación laboral: esa columna la reconcilia la regeneración contra RR.HH. y
    // devolverlo con un clic omitiría el alta que todavía no existe.
    final puedeMoverVentana =
        widget.administra &&
        !widget.bloqueado &&
        widget.quedanSabados &&
        !p.fueraDeLaEmpresa;

    final rotulo = _rotuloDeSituacion(p);

    return ListTile(
      // El nombre y su estado en el mismo renglón: quien recorre 85 filas mira los
      // nombres, no el tercer renglón gris. Wrap y no Row: «ALMENDRAS ROCHA ERICK
      // ALBERTO» más la etiqueta no entran juntos en 360 px y la etiqueta baja de
      // renglón en vez de recortar el apellido.
      title: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: Esp.s,
        runSpacing: Esp.xs,
        children: [
          Text(
            p.nombreRol,
            overflow: TextOverflow.ellipsis,
            // Apagado y no tachado: sigue siendo empleado, lo que se cerró es su
            // participación. Sólo el color, para que la fila no cambie de altura.
            style: fuera ? TextStyle(color: Theme.of(context).hintColor) : null,
          ),
          if (rotulo != null) Etiqueta(texto: rotulo.$1, tono: rotulo.$2),
        ],
      ),
      isThreeLine: hayContexto || decidido || fuera,
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // El cargo va primero; la sucursal, pegada y APAGADA (contexto, no estado).
          // **Se muestra siempre, también la mayoritaria:** los JOIN de sucursal son LEFT
          // (vacía sería ambiguo: «es de CENTRAL» o «no sabemos») y «la mayoritaria»
          // cambia según la lista, así que la misma persona saldría con sucursal en una
          // pestaña y sin ella en otra. El CONTEO va en el encabezado; la empresa no va
          // por fila (las 85 son de GENERAL).
          if (hayContexto)
            Text.rich(
              TextSpan(
                style: Theme.of(context).textTheme.bodySmall,
                children: [
                  if (p.cargo.isNotEmpty) TextSpan(text: p.cargo),
                  if (p.cargo.isNotEmpty && p.sucursal.isNotEmpty)
                    const TextSpan(text: ' · '),
                  if (p.sucursal.isNotEmpty)
                    TextSpan(text: p.sucursal, style: context.apagado()),
                ],
              ),
            ),
          // El contador sale de la misma función que el de la grilla (mismo dato, mismo
          // texto). Dice «en todo el año» porque esta lista no se filtra por mes y la
          // grilla sí.
          Text(
            '#${p.codEmpleado} · '
            '${sabadosDelAnio(turnos: widget.turnos, meta: p.turnosObjetivo)}'
            '${p.esProgramador == 1 ? ' · programa a otros' : ''}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Theme.of(context).hintColor),
          ),
          // POR QUÉ no viene y DESDE CUÁNDO, en el mismo renglón. Son dos situaciones
          // distintas («RR.HH. lo sacó de los sábados» y «ya no figura en la relación
          // laboral»): una se deshace con un toque aquí y la otra la reconcilia la
          // regeneración. También para la salida agendada: la etiqueta dice «SALE 07/08»
          // recortado y aquí va la fecha entera.
          if (decidido || fuera)
            Text(
              _porQueNoViene(p),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                // Rojo sólo si ya rige: una salida agendada es un aviso, no un problema.
                color:
                    fuera
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).hintColor,
                fontWeight: Peso.titulo,
              ),
            ),
        ],
      ),
      trailing:
          _guardando
              ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
              : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Ancho fijo y no SegmentedButton: el de Material pide el ancho que necesita y
                  // en 360 px empuja el nombre fuera. Apagado para quien no hace sábados
                  // (cambiarle el grupo no cambia ningún día).
                  _SelectorGrupo(
                    grupo: p.grupoRotacion,
                    habilitado: !widget.bloqueado && !fuera,
                    onElegir: _cambiar,
                  ),
                  // Menú de tres puntos y no un tercer botón: el selector ya mide 76 px y en
                  // 360 px cada píxel del trailing se lo saca al apellido; además abren un
                  // diálogo, no son un interruptor.
                  if (puedeMoverVentana)
                    PopupMenuButton<bool>(
                      tooltip: 'Sábados de esta persona',
                      icon: const Icon(Icons.more_vert, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 220),
                      onSelected: (sacar) => sacar ? _sacar() : _devolver(),
                      // Una sola acción, la que corresponde: quien está adentro se saca y quien está
                      // afuera vuelve (un menú con media opción gris hace pensar que falta un
                      // permiso). Manda `decidido` y no `fuera`: quien sale en diciembre sigue
                      // viniendo, pero ofrecerle «Sacar» otra vez dejaría la decisión sin forma de
                      // deshacerse hasta que llegue la fecha.
                      itemBuilder:
                          (_) => [
                            PopupMenuItem(
                              value: !decidido,
                              child: Text(
                                decidido
                                    ? 'Devolver a los sábados…'
                                    : 'Sacar de los sábados…',
                              ),
                            ),
                          ],
                    ),
                ],
              ),
    );
  }

  Future<void> _cambiar(String grupo) async {
    if (grupo == widget.persona.grupoRotacion) return;

    // Si el filtro muestra el grupo que esta persona está dejando, su fila se va de
    // la lista apenas vuelve la grilla.
    //
    // **Decisión: se avisa, no se retiene.** Retenerla exige una lista de
    // «excepciones al filtro» y el chip diría 42 con 43 filas debajo; la lista debe
    // mostrar SIEMPRE lo que el filtro dice.
    final filtro = ref.read(filtroGrupoProvider);
    final adondeSeFue =
        (filtro.isNotEmpty && filtro != grupo)
            ? 'Sale de la lista porque estás viendo sólo el grupo $filtro. '
            : '';

    setState(() => _guardando = true);
    await ejecutarAccion(
      context,
      () => ref
          .read(rolSabadosAccionesProvider)
          .asignarGrupo(
            idRol: widget.idRol,
            idParticipante: widget.persona.idParticipante,
            grupoRotacion: grupo,
          ),
      exito:
          '${widget.persona.nombreRol} pasa al grupo $grupo. '
          '${adondeSeFue}Regenera para que la grilla lo tome.',
    );
    if (mounted) setState(() => _guardando = false);
  }

  // La ventana de sábados

  Future<void> _sacar() async {
    final desde = await _preguntar(salida: true);
    if (desde == null || !mounted) return;

    // El backend guarda el ÚLTIMO día que cuenta como suyo y lo elegido es el
    // primer sábado que ya no viene: se manda el día anterior. `DateTime(y, m,
    // d - 1)` deja el cambio de mes a Dart; restar 24 horas se rompería con
    // cualquier corrimiento de reloj.
    final fecha = DateTime(desde.year, desde.month, desde.day - 1);

    setState(() => _guardando = true);
    await ejecutarAccion(
      context,
      () => ref
          .read(rolSabadosAccionesProvider)
          .sacarDeSabados(
            idRol: widget.idRol,
            idParticipante: widget.persona.idParticipante,
            fechaBaja: fecha,
          ),
      // El detalle del backend (celdas liberadas y sobrevivientes por venir de un
      // jefe o corrección) gana a éste, que sólo se ve si el SP no dice nada.
      exito:
          '${widget.persona.nombreRol} deja de hacer sábados desde el '
          '${fechaCorta(desde)}. Lo que ya trabajó queda en la grilla.',
    );
    if (mounted) setState(() => _guardando = false);
  }

  Future<void> _devolver() async {
    final desde = await _preguntar(salida: false);
    if (desde == null || !mounted) return;

    setState(() => _guardando = true);
    await ejecutarAccion(
      context,
      () => ref
          .read(rolSabadosAccionesProvider)
          .reincorporar(
            idRol: widget.idRol,
            idParticipante: widget.persona.idParticipante,
            fechaAlta: desde,
          ),
      exito:
          '${widget.persona.nombreRol} vuelve a los sábados desde el '
          '${fechaCorta(desde)}.',
    );
    if (mounted) setState(() => _guardando = false);
  }

  /// Abre el diálogo y devuelve el sábado elegido, o null si se canceló.
  Future<DateTime?> _preguntar({required bool salida}) => showDialog<DateTime>(
    context: context,
    builder:
        (_) => _DialogoVentana(
          persona: widget.persona,
          grilla: widget.grilla,
          salida: salida,
        ),
  );
}

/// La etiqueta que va al lado del nombre, o null si no hay nada que decir.
///
/// Sólo cuando hay algo que decir: 84 etiquetas «VIGENTE» ocultarían la fila que
/// importa. Es corta («SALE 07/08») porque compite con el nombre por el ancho;
/// la fecha completa está en [_porQueNoViene].
(String, TonoEtiqueta)? _rotuloDeSituacion(ParticipanteTurnoEntity p) {
  String corta(DateTime? f) {
    final t = fechaCorta(f); // dd/MM/yyyy
    return t.length >= 5 ? t.substring(0, 5) : t;
  }

  // Aviso y no error para las dos con fecha: hay algo agendado, nada está mal. El
  // rojo se reserva para lo que ya rige y saca a alguien de la grilla.
  if (p.fueraDeLaEmpresa) return ('FUERA DE LA EMPRESA', TonoEtiqueta.error);
  if (p.sinSabados) return ('SIN SÁBADOS', TonoEtiqueta.error);
  if (p.saleDespues)
    return ('SALE ${corta(p.fechaSituacion)}', TonoEtiqueta.aviso);
  if (p.vuelveDespues) {
    return ('VUELVE ${corta(p.fechaSituacion)}', TonoEtiqueta.aviso);
  }
  return null;
}

/// Por qué esta persona no aparece en ningún sábado, y desde cuándo.
String _porQueNoViene(ParticipanteTurnoEntity p) {
  if (p.fueraDeLaEmpresa) return 'Ya no figura en la relación laboral';
  if (p.vuelveDespues) {
    return 'Vuelve a los sábados el ${fechaCorta(p.fechaSituacion)}';
  }
  // Ya está sacado aunque la fecha no haya llegado: sus sábados de aquí en
  // adelante ya se liberaron. Se dice en futuro y con la fecha, porque todavía
  // puede venir el sábado que viene y es lo primero que se pregunta.
  if (p.saleDespues) {
    return 'Sale de los sábados el ${fechaCorta(p.fechaSituacion)}';
  }
  return p.fechaSituacion == null
      ? 'Sin sábados'
      : 'Sin sábados desde el ${fechaCorta(p.fechaSituacion)}';
}

/// Elegir desde qué sábado alguien deja de venir, o vuelve, con el efecto
/// escrito antes de apretar.
///
/// Se elige un SÁBADO y no una fecha (sólo los del rol cambian algo) y dice
/// cuántos mueve («Se le liberan 12»): es lo que RR.HH. verá cambiar en la cobertura.
class _DialogoVentana extends StatefulWidget {
  const _DialogoVentana({
    required this.persona,
    required this.grilla,
    required this.salida,
  });

  final ParticipanteTurnoEntity persona;
  final GrillaRol grilla;

  /// true = se va de los sábados · false = vuelve.
  final bool salida;

  @override
  State<_DialogoVentana> createState() => _DialogoVentanaState();
}

class _DialogoVentanaState extends State<_DialogoVentana> {
  late final List<SabadoEntity> _sabados = sabadosQueVienen(widget.grilla);

  /// El primero al que se llega: «desde el próximo sábado ya no viene» o «entra
  /// en el próximo» es lo que se quiere el 90% de las veces.
  late SabadoEntity _elegido = _sabados.first;

  @override
  Widget build(BuildContext context) {
    final p = widget.persona;
    final cs = Theme.of(context).colorScheme;
    final corte = _elegido.fecha!;

    // Una sola pasada por los sábados del rol: lo que quedó atrás, lo que se libera
    // y lo que sobrevive salen juntos.
    var yaTrabajo = 0;
    var libera = 0;
    var sobreviven = 0;
    var leTocan = 0;
    for (final s in widget.grilla.sabados) {
      final f = s.fecha;
      if (f == null) continue;
      final celda = widget.grilla.celda(p.idParticipante, s.idSabado);
      if (f.isBefore(corte)) {
        if (celda != null && celda.codigoExcel == '1') yaTrabajo++;
        continue;
      }
      if (s.activo != 1) continue;
      if (celda == null) {
        if (s.grupoQueRota == p.grupoRotacion) leTocan++;
      } else if (celda.esIntervencion) {
        sobreviven++;
      } else {
        libera++;
      }
    }

    final texto = Theme.of(context).textTheme;

    return AlertDialog(
      title: Text(
        widget.salida ? 'Sacar de los sábados' : 'Devolver a los sábados',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(p.nombreRol, style: texto.titleSmall),
            const SizedBox(height: Esp.m),
            DropdownButtonFormField<int>(
              value: _elegido.idSabado,
              isExpanded: true,
              decoration: InputDecoration(
                labelText:
                    widget.salida ? 'Ya no viene desde' : 'Vuelve a venir el',
                border: const OutlineInputBorder(),
                isDense: true,
                prefixIcon: const Icon(Icons.event_outlined, size: 18),
              ),
              items: [
                for (final s in _sabados)
                  DropdownMenuItem(
                    value: s.idSabado,
                    child: Text(
                      'sábado ${fechaCorta(s.fecha)} · grupo ${s.grupoQueRota}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _elegido = _sabados.firstWhere((s) => s.idSabado == v);
                });
              },
            ),
            const SizedBox(height: Esp.m),
            if (widget.salida) ...[
              // Lo primero que hay que leer: el pasado no se toca («¿pierdo lo que ya
              // trabajó?» no).
              Text(
                yaTrabajo == 0
                    ? 'Los sábados anteriores no se tocan: quedan en la grilla '
                        'como están.'
                    : 'Los $yaTrabajo sábados que ya trabajó no se tocan: '
                        'quedan en la grilla como están.',
                style: texto.bodyMedium,
              ),
              const SizedBox(height: Esp.s),
              Text(
                libera == 0
                    ? 'De aquí en adelante no tiene ningún sábado generado, así '
                        'que no se libera ninguno.'
                    : 'Se le liberan $libera sábados, desde el '
                        '${fechaCorta(corte)}.',
                style: texto.bodyMedium,
              ),
              if (sobreviven > 0) ...[
                const SizedBox(height: Esp.s),
                Text(
                  'Atención: $sobreviven de esos días los decidió una persona —los '
                  'programó un jefe o los corrigió RR.HH.— y por eso NO se '
                  'borran. Si tampoco viene esos días, hay que liberarlos uno '
                  'por uno desde la grilla.',
                  style: texto.bodySmall?.copyWith(color: cs.error),
                ),
              ],
            ] else ...[
              Text(
                leTocan == 0
                    ? 'Entra de nuevo en la rotación del grupo '
                        '${p.grupoRotacion}. De aquí a fin de año no le queda '
                        'ningún sábado de su grupo.'
                    : 'Entra de nuevo en la rotación del grupo '
                        '${p.grupoRotacion}: le tocan $leTocan sábados desde el '
                        '${fechaCorta(corte)}.',
                style: texto.bodyMedium,
              ),
              const SizedBox(height: Esp.s),
              Text(
                'Los sábados anteriores no cambian.',
                style: texto.bodyMedium,
              ),
            ],
            const SizedBox(height: Esp.s),
            // La meta de cobertura es un REQUISITO (cuánta gente hace falta ese día), no un
            // promedio: bajarla sola haría desaparecer el faltante justo cuando aparece. Se
            // avisa y la mueve RR.HH. si decide que bajó.
            Text(
              'La meta de cobertura del rol sigue en '
              '${widget.grilla.rol.coberturaObjetivo}: no se ajusta sola.',
              style: context.apagado(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, corte),
          child: Text(widget.salida ? 'Sacar' : 'Devolver'),
        ),
      ],
    );
  }
}

/// Dos botones de 34 px: A y B. Alcanza para el pulgar y entra en cualquier
/// pantalla.
class _SelectorGrupo extends StatelessWidget {
  const _SelectorGrupo({
    required this.grupo,
    required this.habilitado,
    required this.onElegir,
  });

  final String grupo;
  final bool habilitado;
  final ValueChanged<String> onElegir;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 76,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Boton(
          letra: 'A',
          activo: grupo == 'A',
          habilitado: habilitado,
          onTap: onElegir,
        ),
        const SizedBox(width: Esp.xs),
        _Boton(
          letra: 'B',
          activo: grupo == 'B',
          habilitado: habilitado,
          onTap: onElegir,
        ),
      ],
    ),
  );
}

class _Boton extends StatelessWidget {
  const _Boton({
    required this.letra,
    required this.activo,
    required this.habilitado,
    required this.onTap,
  });

  final String letra;
  final bool activo;
  final bool habilitado;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: activo ? cs.primary : cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: habilitado ? () => onTap(letra) : null,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 34,
          height: 34,
          child: Center(
            child: Text(
              letra,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: Peso.dato,
                color: activo ? cs.onPrimary : cs.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// El botón que aplica los cambios de grupo a la grilla.
///
/// Va aparte de cada fila: cambiar el grupo es barato pero regenerar rehace
/// **todas** las celdas del año (por persona serían 87 regeneraciones).
class BotonRegenerar extends ConsumerStatefulWidget {
  const BotonRegenerar({super.key, required this.grilla});
  final GrillaRol grilla;

  @override
  ConsumerState<BotonRegenerar> createState() => _BotonRegenerarState();
}

class _BotonRegenerarState extends ConsumerState<BotonRegenerar> {
  bool _trabajando = false;

  @override
  Widget build(BuildContext context) => FloatingActionButton.extended(
    onPressed: _trabajando ? null : _confirmar,
    icon:
        _trabajando
            ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
            : const Icon(Icons.refresh),
    label: const Text('Regenerar con estos grupos'),
  );

  Future<void> _confirmar() async {
    final g = widget.grilla;
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('¿Regenerar el rol?'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Se rehacen las celdas de los sábados que faltan de '
                    '${g.rol.anio} con los grupos de ahora.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: Esp.m),
                  Text(
                    'Se conservan: las correcciones manuales, lo que programó un '
                    'jefe, las convocatorias y los eventos. Las vacaciones se '
                    'vuelven a cruzar solas.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: Esp.s),
                  // Debe coincidir con lo que hace la regeneración (no toca el pasado): un aviso
                  // en rojo que miente enseña a ignorar los rojos.
                  Text(
                    'Los sábados que ya pasaron quedan como están: no se '
                    'recalculan ni se borran. Si alguien cambió de grupo, el '
                    'cambio se ve de hoy en adelante.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
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
                child: const Text('Regenerar'),
              ),
            ],
          ),
    );
    if (ok != true) return;

    setState(() => _trabajando = true);
    await ejecutarAccion(
      context,
      () => ref
          .read(rolSabadosAccionesProvider)
          .generarRol(anio: g.rol.anio, modo: 'REGENERAR'),
      exito: 'Rol regenerado con los grupos nuevos.',
    );
    if (mounted) setState(() => _trabajando = false);
  }
}
