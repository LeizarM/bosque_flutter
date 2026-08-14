import 'package:bosque_flutter/core/state/permisos_rrhh_provider.dart';
import 'package:bosque_flutter/domain/entities/simulacion_colectiva_entity.dart';
import 'package:bosque_flutter/presentation/widgets/permisos-rrhh/permisos_rrhh_comunes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Las dos cargas que escriben **una fila por persona**: el abono de días
/// grupal y la vacación colectiva.
///
/// **Son la misma hoja porque son el mismo trámite**: elegir gente, decir qué se
/// les carga, mirar el resultado y recién ahí aplicar. Lo único que cambia es el
/// cabezal —una fecha y unos días contra un rango de fechas y horas— y en qué
/// tabla cae: el abono va a `trh_abonoDias` y la vacación colectiva a
/// `trh_permiso` con `tipoPermiso = 'vac'`. Ojo con eso último: la vacación
/// colectiva **descuenta** saldo, no lo da.
enum TipoCargaColectiva {
  /// Los mismos días acreditados a varias personas. Uno solo para todos —pero
  /// **a quiénes** les entra lo decide el servidor: quien no tenga relación
  /// laboral activa, tenga más de una o ya haya cobrado un abono ese día queda
  /// afuera, y eso no se sabe desde acá. Por eso el paso 2 también simula.
  abonoDias,

  /// Un rango de fechas cargado como vacación gozada. **Los días NO son un
  /// número único**: se recalculan por persona según los feriados de su
  /// sucursal, así que «5 días a 40 personas» puede terminar siendo 4,5 para
  /// los de una sucursal. Por eso el paso 2 pide la simulación al servidor.
  vacacion,
}

/// El asistente de dos pasos: elegir y confirmar.
///
/// **Los dos pasos son la única barrera que hay hoy antes de escribir N filas**
/// —el legacy también los tiene (`subVista = 1` y `= 2`)— y acá valen todavía
/// más, porque del otro lado la carga va en una sola transacción: si algo falla,
/// no se guarda ninguna.
///
/// **No se ofrece en pantalla chica.** El motivo no es el ancho: es que en un
/// teléfono la selección múltiple se dispara de un roce, y acá cada roce es una
/// persona más cobrando días. El legacy tenía además un «invertir selección» que
/// en móvil es una trampa; acá no está ni en escritorio: marcar y desmarcar son
/// dos botones distintos, cada uno diciendo a cuántos alcanza.
Future<void> mostrarCargaColectivaSheet({
  required BuildContext context,
  required TipoCargaColectiva tipo,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  constraints: const BoxConstraints(maxWidth: 900),
  builder: (_) => _CargaColectivaSheet(tipo: tipo),
);

class _CargaColectivaSheet extends ConsumerStatefulWidget {
  const _CargaColectivaSheet({required this.tipo});

  final TipoCargaColectiva tipo;

  @override
  ConsumerState<_CargaColectivaSheet> createState() =>
      _CargaColectivaSheetState();
}

class _CargaColectivaSheetState extends ConsumerState<_CargaColectivaSheet> {
  final _dias = TextEditingController();
  final _motivo = TextEditingController();
  final _filtro = TextEditingController();

  DateTime _fecha = DateTime.now();
  late DateTime _desde = _aLaHora(DateTime.now(), 8, 30);
  late DateTime _hasta = _aLaHora(DateTime.now(), 18, 30);

  /// Quiénes están marcados. Un `Set` de códigos y no la lista de entidades: el
  /// padrón se rearma en cada rebuild y comparar objetos no serviría.
  final _marcados = <int>{};

  bool _confirmando = false;
  bool _aplicando = false;

  /// Lo que se va a escribir, **ya resuelto por el servidor**, para las dos
  /// cargas.
  ///
  /// El abono también lo necesita aunque los días sean uno solo para todos: lo
  /// que el cliente no sabe es quién tiene relación laboral activa, quién tiene
  /// más de una y quién ya cobró un abono ese día. Armar esta pantalla con la
  /// selección local era decir «3 días a 40 empleados» sin saber a cuántos
  /// alcanzaba.
  List<SimulacionColectivaEntity>? _previa;
  Object? _errorPrevia;
  bool _simulando = false;

  bool get _esAbono => widget.tipo == TipoCargaColectiva.abonoDias;

  @override
  void dispose() {
    _dias.dispose();
    _motivo.dispose();
    _filtro.dispose();
    super.dispose();
  }

  static DateTime _aLaHora(DateTime d, int hora, int minuto) =>
      DateTime(d.year, d.month, d.day, hora, minuto);

  @override
  Widget build(BuildContext context) {
    // El padrón sale de la empresa que el módulo tiene filtrada, no de todas:
    // es el mismo `filtroEmpresaProvider` que usa el buscador, así que la lista
    // para tildar y la lista donde se busca gente hablan del mismo universo.
    // 0 = todas.
    final empresa = ref.watch(filtroEmpresaProvider);
    final padron = ref.watch(empleadosColectivaProvider(empresa));

    return SizedBox(
      // Alto fijo y no `min`: la lista de gente tiene que tener dónde caer y
      // scrollear adentro, no empujar el botón de aplicar fuera de la pantalla.
      height: MediaQuery.of(context).size.height * 0.85,
      child: Padding(
        padding: EdgeInsets.only(
          left: Esp.xl,
          right: Esp.xl,
          top: Esp.s,
          bottom: MediaQuery.of(context).viewInsets.bottom + Esp.l,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _esAbono ? 'Abono de días a varias personas' : 'Vacación colectiva',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              _esAbono
                  ? 'Acredita los mismos días a todos los que marques. Se '
                      'guarda todo o no se guarda nada.'
                  : 'Carga un permiso de vacación a todos los que marques y les '
                      'descuenta el saldo. Se guarda todo o no se guarda nada.',
              style: context.apagado(),
            ),
            const SizedBox(height: Esp.m),

            Expanded(
              child: padron.when(
                loading: () => const Cargando(),
                error:
                    (e, _) => ErrorDelDato(
                      error: e,
                      onReintentar:
                          () =>
                              ref.invalidate(empleadosColectivaProvider(empresa)),
                    ),
                data:
                    (gente) =>
                        _confirmando ? _confirmacion(gente) : _seleccion(gente),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── PASO 1: qué se carga y a quiénes ──────────────────────────────────────

  Widget _seleccion(List<SimulacionColectivaEntity> gente) {
    final visibles = _visibles(gente);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_esAbono) _cabezalAbono() else _cabezalVacacion(),

        const SizedBox(height: Esp.m),
        TextField(
          controller: _motivo,
          // 50 en el abono es el largo de la columna; 100 en el permiso.
          maxLength: _esAbono ? 50 : 100,
          decoration: const InputDecoration(
            labelText: 'Motivo',
            border: OutlineInputBorder(),
            isDense: true,
            helperText: 'Queda en la fila de cada persona. Es obligatorio.',
          ),
          onChanged: (_) => setState(() {}),
        ),

        const SizedBox(height: Esp.s),
        TextField(
          controller: _filtro,
          decoration: const InputDecoration(
            labelText: 'Buscar en la lista',
            hintText: 'Nombre o empresa',
            prefixIcon: Icon(Icons.search, size: 18),
            border: OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: (_) => setState(() {}),
        ),

        const SizedBox(height: Esp.s),
        // **Marcar y desmarcar, no invertir.** El legacy invierte la selección
        // de toda la lista con un solo toque, que es cómo se termina cargando
        // días a quien no correspondía sin que nadie lo note.
        Wrap(
          spacing: Esp.s,
          runSpacing: Esp.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '${_marcados.length} de ${gente.length} marcados',
              style: context.tituloSeccion(),
            ),
            TextButton(
              onPressed:
                  visibles.isEmpty
                      ? null
                      : () => setState(
                        () => _marcados.addAll(visibles.map((e) => e.codEmpleado)),
                      ),
              child: Text('Marcar los ${visibles.length} de la lista'),
            ),
            TextButton(
              onPressed:
                  _marcados.isEmpty
                      ? null
                      : () => setState(_marcados.clear),
              child: const Text('Quitar todos'),
            ),
          ],
        ),

        const SizedBox(height: Esp.xs),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: context.cs.outlineVariant),
              borderRadius: BorderRadius.circular(Esp.xs),
            ),
            child:
                visibles.isEmpty
                    ? Center(
                      child: Text(
                        'Nadie coincide con la búsqueda.',
                        style: context.apagado(),
                      ),
                    )
                    : Scrollbar(
                      child: ListView.builder(
                        itemCount: visibles.length,
                        itemBuilder: (_, i) {
                          final e = visibles[i];
                          return CheckboxListTile(
                            dense: true,
                            value: _marcados.contains(e.codEmpleado),
                            onChanged:
                                (v) => setState(() {
                                  if (v == true) {
                                    _marcados.add(e.codEmpleado);
                                  } else {
                                    _marcados.remove(e.codEmpleado);
                                  }
                                }),
                            title: Text(
                              e.datoEmpleado,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              [
                                e.datoEmpresa,
                                e.datoSucursal,
                              ].where((s) => s.isNotEmpty).join(' · '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        },
                      ),
                    ),
          ),
        ),

        const SizedBox(height: Esp.m),
        FilledButton.icon(
          onPressed: _marcados.isEmpty ? null : () => _continuar(gente),
          icon: const Icon(Icons.arrow_forward),
          label: const Text('Revisar antes de guardar'),
        ),
      ],
    );
  }

  Widget _cabezalAbono() => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: TextField(
          controller: _dias,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          decoration: const InputDecoration(
            labelText: 'Días a abonar',
            border: OutlineInputBorder(),
            isDense: true,
            helperText: 'El mismo número para todos. Mayor a cero.',
          ),
          onChanged: (_) => setState(() {}),
        ),
      ),
      const SizedBox(width: Esp.m),
      Expanded(
        child: CampoElegido(
          etiqueta: 'Fecha del abono',
          texto: fechaCorta(_fecha),
          onTap: () async {
            final hoy = DateTime.now();
            final elegida = await showDatePicker(
              context: context,
              initialDate: _fecha,
              firstDate: DateTime(hoy.year - 1),
              lastDate: DateTime(hoy.year + 1, 12, 31),
              helpText: 'Fecha del abono',
            );
            if (!mounted || elegida == null) return;
            setState(() => _fecha = elegida);
          },
        ),
      ),
    ],
  );

  Widget _cabezalVacacion() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Expanded(child: _fechaHora(esDesde: true)),
          const SizedBox(width: Esp.m),
          Expanded(child: _fechaHora(esDesde: false)),
        ],
      ),
      const SizedBox(height: Esp.xs),
      Text(
        'La hora decide cuántos días se descuentan: el cálculo avanza de media '
        'hora en media hora entre las dos. Las cargas anteriores usaron 08:30 '
        'y 18:30. El total del rango es un estimado: cada persona termina con '
        'el suyo según los feriados de su sucursal, y el número exacto se ve en '
        'el paso siguiente.',
        style: context.apagado(),
      ),
    ],
  );

  /// Fecha y hora de un extremo del rango, en un solo campo.
  ///
  /// Dos toques y no dos campos: son un solo instante, y separarlos en cuatro
  /// controles deja la pantalla pidiendo cuatro cosas para decir dos.
  Widget _fechaHora({required bool esDesde}) {
    final valor = esDesde ? _desde : _hasta;
    return CampoElegido(
      etiqueta: esDesde ? 'Desde' : 'Hasta',
      texto: '${fechaCorta(valor)}  ${horaCorta(valor)}',
      icono: Icons.schedule_outlined,
      onTap: () async {
        final hoy = DateTime.now();
        final dia = await showDatePicker(
          context: context,
          initialDate: valor,
          firstDate: DateTime(hoy.year - 1),
          lastDate: DateTime(hoy.year + 1, 12, 31),
          helpText: esDesde ? 'La vacación empieza' : 'La vacación termina',
        );
        if (!mounted || dia == null) return;

        final hora = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(hour: valor.hour, minute: valor.minute),
          helpText: esDesde ? 'Hora de inicio' : 'Hora de fin',
        );
        if (!mounted) return;

        final elegido = _aLaHora(
          dia,
          hora?.hour ?? valor.hour,
          hora?.minute ?? valor.minute,
        );
        setState(() {
          if (esDesde) {
            _desde = elegido;
          } else {
            _hasta = elegido;
          }
        });
      },
    );
  }

  /// Valida el cabezal y pasa al paso 2. El orden y los cortes son los del
  /// legacy; los textos, no —los suyos no se entienden—.
  Future<void> _continuar(List<SimulacionColectivaEntity> gente) async {
    final problema = _problemaDelCabezal();
    if (problema != null) {
      avisarError(context, problema);
      return;
    }

    setState(() {
      _confirmando = true;
      _previa = null;
      _errorPrevia = null;
      _simulando = true;
    });

    // **Las dos cargas se simulan antes de mostrar nada.** En la vacación
    // porque el número del cabezal no es el que se graba —los feriados son por
    // sucursal y cada persona puede terminar con un total distinto—; en el
    // abono porque quién entra depende de la base: la relación activa, las
    // relaciones duplicadas, el abono que ya cobró ese día. En los dos casos
    // confirmar sobre lo que sabe el cliente es confirmar otra cosa que la que
    // se guarda.
    //
    // **Sólo los que están en el padrón cargado**: si el filtro de empresa
    // cambió, lo tildado en la lista anterior ya no se ve y no se manda.
    final codigos = [
      for (final e in gente)
        if (_marcados.contains(e.codEmpleado)) e.codEmpleado,
    ];
    final repo = ref.read(permisosRrhhRepositoryProvider);
    try {
      final filas =
          _esAbono
              ? await repo.simularAbonoColectivo(
                codEmpleados: codigos,
                dias: diasDeTexto(_dias.text) ?? 0,
                motivo: _motivo.text,
                fecha: _fecha,
              )
              : await repo.simularVacacionColectiva(
                codEmpleados: codigos,
                desde: _desde,
                hasta: _hasta,
                motivo: _motivo.text,
              );
      if (!mounted) return;
      setState(() {
        _previa = filas;
        _simulando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorPrevia = e;
        _simulando = false;
      });
    }
  }

  String? _problemaDelCabezal() {
    if (_esAbono) {
      final dias = diasDeTexto(_dias.text);
      if (dias == null || dias <= 0) {
        return 'Indique cuántos días se abonan. Tiene que ser mayor a cero.';
      }
    } else {
      // La regla del legacy, textual: «La Vacaciones deben iniciar y finalizar
      // en el mismo años». El SP no la valida, así que si pasa, pasa.
      if (_desde.year != _hasta.year) {
        return 'La vacación tiene que empezar y terminar en el mismo año.';
      }
      if (!_hasta.isAfter(_desde)) {
        return 'La fecha de fin tiene que ser posterior a la de inicio.';
      }
    }
    if (_motivo.text.trim().length < 2) return 'Indique el motivo de la carga.';
    if (_marcados.isEmpty) return 'Marcá por lo menos a una persona.';
    return null;
  }

  // ── PASO 2: qué va a pasar exactamente ────────────────────────────────────

  Widget _confirmacion(List<SimulacionColectivaEntity> gente) {
    if (_simulando) return const Cargando();
    if (_errorPrevia != null) {
      return ErrorDelDato(
        error: _errorPrevia!,
        onReintentar: () => _continuar(gente),
      );
    }

    // **La previa es la del servidor y punto.** Antes, cuando era un abono, se
    // armaba con la selección local: el diálogo decía «3 días a 40 empleados»
    // sin haberle preguntado a nadie a cuántos alcanzaba de verdad.
    final filas = _previa ?? const <SimulacionColectivaEntity>[];
    final entran = filas.where((e) => e.entra).toList();
    final fuera = filas.where((e) => !e.entra).toList();

    // Los días del abono son uno solo para todos, así que se leen de la primera
    // fila que entra —la que devolvió el servidor, no la que se tipeó—.
    final titulo =
        entran.isEmpty
            ? 'No queda nadie a quien cargarle'
            : _esAbono
            ? '${_diasDe(entran.first)} a ${entran.length} personas'
            : '${entran.length} personas, '
                '${numeroDeDias(entran.fold<double>(0, (a, e) => a + e.dias))} '
                'días en total';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          titulo,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: Peso.titulo,
            fontFeatures: cifrasTabulares,
          ),
        ),
        Text(
          _esAbono
              ? 'Con fecha ${fechaCorta(_fecha)}. Motivo: ${_motivo.text.trim()}'
              : 'Del ${fechaCorta(_desde)} al ${fechaCorta(_hasta)}. '
                  'Motivo: ${_motivo.text.trim()}',
          style: context.apagado(),
        ),

        if (!_esAbono) ...[
          const SizedBox(height: Esp.s),
          const AvisoDelDato(
            texto:
                'El total del rango es un estimado: lo que se graba es el '
                'número de cada persona, porque se le descuentan los feriados '
                'de SU sucursal. Los de la lista son los que se van a guardar.',
          ),
        ],

        if (fuera.isNotEmpty) ...[
          const SizedBox(height: Esp.s),
          AvisoDelDato(
            icono: Icons.person_off_outlined,
            texto:
                'Se saltean ${fuera.length}: ${fuera.map((e) => e.datoEmpleado).take(3).join(', ')}'
                '${fuera.length > 3 ? '…' : ''}. El motivo está en la lista.',
          ),
        ],

        const SizedBox(height: Esp.s),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: context.cs.outlineVariant),
              borderRadius: BorderRadius.circular(Esp.xs),
            ),
            child: Scrollbar(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: Esp.xs),
                itemCount: filas.length,
                itemBuilder: (_, i) {
                  final e = filas[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Esp.s,
                      vertical: 3,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 32,
                          child: Text('${i + 1}.', style: context.apagado()),
                        ),
                        Expanded(
                          child: Text(
                            e.datoEmpleado,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                e.entra
                                    ? null
                                    : TextStyle(color: context.cs.error),
                          ),
                        ),
                        // Los días de ESTA persona, calculados por el servidor,
                        // o el motivo por el que queda afuera.
                        Text(
                          e.entra ? _diasDe(e) : e.detalle,
                          style: context.apagado(),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),

        const SizedBox(height: Esp.m),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed:
                  _aplicando ? null : () => setState(() => _confirmando = false),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Volver'),
            ),
            const SizedBox(width: Esp.m),
            Expanded(
              child: FilledButton.icon(
                // Apagado sin nadie a quien cargarle: apretarlo devolvería el
                // error del servidor sin haber hecho nada. Y apagado mientras
                // la llamada está en vuelo, que es lo único que el cliente
                // puede aportar contra el doble toque.
                onPressed:
                    (_aplicando || entran.isEmpty) ? null : () => _aplicar(entran),
                icon:
                    _aplicando
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.check),
                label: Text(
                  _esAbono ? 'Abonar a todos' : 'Declarar la vacación',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Los días de una fila de la previa, tal como los devolvió el servidor.
  String _diasDe(SimulacionColectivaEntity e) =>
      e.diasTxt.isEmpty ? '${numeroDeDias(e.dias)} días' : e.diasTxt;

  Future<void> _aplicar(List<SimulacionColectivaEntity> entran) async {
    final dias = diasDeTexto(_dias.text) ?? 0;
    // **Los números que se dicen acá son los del servidor**, no los de la
    // selección: `entran` sale de la simulación, así que la cuenta es la de
    // quienes de verdad van a quedar cargados.
    final queVaAPasar =
        _esAbono
            ? 'Vas a abonar ${numeroDeDias(dias)} días a ${entran.length} '
                'empleados con fecha ${fechaCorta(_fecha)}. A cada uno se le '
                'suman al saldo.'
            : 'Vas a cargar ${entran.length} permisos de vacación del '
                '${fechaCorta(_desde)} al ${fechaCorta(_hasta)}, por '
                '${numeroDeDias(entran.fold<double>(0, (a, e) => a + e.dias))} '
                'días en total (el número exacto de cada uno está en la lista). '
                'A cada uno se le descuentan de su saldo.';
    final ok = await confirmar(
      context,
      titulo: _esAbono ? '¿Abonar a ${entran.length}?' : '¿Declarar la vacación?',
      mensaje:
          '$queVaAPasar\n\nMotivo: ${_motivo.text.trim()}\n\n'
          'Se guarda todo o no se guarda nada. Para revertirlo hay que borrar '
          'las filas una por una.',
      accion: _esAbono ? 'Abonar' : 'Declarar',
    );
    if (!ok || !mounted) return;

    setState(() => _aplicando = true);
    try {
      final acciones = ref.read(permisosRrhhAccionesProvider);
      final codigos = entran.map((e) => e.codEmpleado).toList();
      final msg =
          _esAbono
              ? await acciones.aplicarAbonoColectivo(
                codEmpleados: codigos,
                dias: dias,
                motivo: _motivo.text,
                fecha: _fecha,
              )
              : await acciones.aplicarVacacionColectiva(
                codEmpleados: codigos,
                desde: _desde,
                hasta: _hasta,
                motivo: _motivo.text,
              );
      if (!mounted) return;
      Navigator.of(context).pop();
      // El mensaje del servidor tal cual: dice cuántas filas quedaron, que es
      // más de lo que sabría decir un «Listo».
      avisar(context, msg.isEmpty ? 'La carga se guardó.' : msg);
    } catch (e) {
      // **Con la transacción del backend, un error significa que no se guardó
      // NINGUNA.** El legacy decía «Problema(s) al registrar N empleado(s)»
      // sobre un fondo de éxitos parciales; repetir ese texto con la semántica
      // nueva sería mentir.
      if (!mounted) return;
      setState(() => _aplicando = false);
      avisarError(context, e);
    }
  }

  /// Los que coinciden con la búsqueda. Sin rebote: es un filtro en memoria
  /// sobre una lista que ya está acá, no una consulta.
  List<SimulacionColectivaEntity> _visibles(
    List<SimulacionColectivaEntity> gente,
  ) {
    final texto = _filtro.text.trim().toLowerCase();
    if (texto.isEmpty) return gente;
    return gente
        .where(
          (e) =>
              e.datoEmpleado.toLowerCase().contains(texto) ||
              e.datoEmpresa.toLowerCase().contains(texto),
        )
        .toList();
  }
}
