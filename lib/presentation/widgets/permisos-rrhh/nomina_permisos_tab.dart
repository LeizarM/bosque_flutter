import 'package:bosque_flutter/core/state/permisos_rrhh_provider.dart';
import 'package:bosque_flutter/core/state/permisos_vacacion_provider.dart'
    show rptPermisoVacacionProvider;
import 'package:bosque_flutter/domain/entities/nomina_permiso_entity.dart';
import 'package:bosque_flutter/domain/entities/vacacion_asignada_entity.dart';
import 'package:bosque_flutter/presentation/widgets/permisos-rrhh/permiso_individual_sheet.dart';
import 'package:bosque_flutter/presentation/widgets/permisos-rrhh/permisos_rrhh_comunes.dart';
import 'package:bosque_flutter/presentation/widgets/permisos-rrhh/vacacion_pagada_sheet.dart';
import 'package:bosque_flutter/presentation/widgets/shared/permission_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

/// El **kardex de permisos** de una persona y las tres altas que lo alimentan:
/// programar un permiso, programar una vacación y pagar vacación.
///
/// ## Las dos columnas de Deuda no están
///
/// La grilla del sistema anterior muestra «Deuda En Día(s)» y «Deuda En Hr(s)»
/// desde `diasAdeudados`, que el SP calcula como
/// `SUM(trh_repper.cantidadDiasRepuestos) - cantidadDias` para los permisos de
/// tipo `'otro'` desde 2019. **`trh_repper` tiene 0 filas** (verificado contra
/// `BOSQUE-2_0`), así que esa resta no da cero: da **el negativo de los días**.
/// Portarla tal cual pintaría deudas de -0,25 a -2 días en 27 filas y 0 fijo en
/// las otras ~8.400. Vuelven el día que exista el módulo de reposición, que es
/// el que llena esa tabla.
///
/// ## Los dos botones de búsqueda son dos consultas distintas
///
/// «Buscar permisos» lee `trh_permiso` con los cuatro filtros; «Buscar vac
/// ganadas» lee `trh_vacacionAsignada` y **ignora el combo de tipo y la fecha
/// puntual** —en el sistema anterior sólo usa Fecha inicio y Fecha fin—. Son dos
/// grillas con columnas distintas, así que se muestra la última que se pidió en
/// vez de apilarlas: en un teléfono, dos grillas una debajo de la otra son dos
/// pantallas de scroll para leer una.
class NominaPermisosTab extends ConsumerStatefulWidget {
  const NominaPermisosTab({super.key, required this.codEmpleado});

  final int codEmpleado;

  @override
  ConsumerState<NominaPermisosTab> createState() => _NominaPermisosTabState();
}

enum _Consulta { permisos, vacGanadas }

class _NominaPermisosTabState extends ConsumerState<NominaPermisosTab> {
  _Consulta _mostrando = _Consulta.permisos;

  /// Las claves de las dos consultas, congeladas cuando se apretó el botón.
  ///
  /// **Los filtros no disparan la búsqueda solos**, igual que en el sistema
  /// anterior: elegir una fecha en el calendario pegaría un viaje al servidor
  /// por cada toque del selector.
  late FiltroNominaPermisos _clavePermisos = _armarClavePermisos();
  ClaveVacGanadas? _claveVac;

  /// Relación en 0 = «la vigente, la resuelve el servidor». El kardex es de la relación
  /// laboral, y cuál está activa lo sabe el servidor.
  static const int _relacionVigente = 0;

  FiltroNominaPermisos _armarClavePermisos() => (
    codEmpleado: widget.codEmpleado,
    codRelEmplEmpr: _relacionVigente,
    tipoPermiso: ref.read(filtroTipoPermisoProvider),
    desde: ref.read(filtroFechaInicioProvider),
    hasta: ref.read(filtroFechaFinProvider),
    fecRango: ref.read(filtroFechaRangoProvider),
  );

  ClaveVacGanadas _armarClaveVac() => (
    codEmpleado: widget.codEmpleado,
    codRelEmplEmpr: _relacionVigente,
    desde: ref.read(filtroFechaInicioProvider),
    hasta: ref.read(filtroFechaFinProvider),
  );

  /// **Cambiar de empleado tiene que rearmar las claves.**
  ///
  /// En el panel maestro de escritorio, elegir a otra persona no destruye esta
  /// pestaña: es el mismo tipo de widget en la misma posición del `TabBarView`,
  /// así que Flutter **reusa este `State`**. Y como `_clavePermisos` se congela
  /// una sola vez —el inicializador `late` corre en el primer build y de ahí en
  /// más solo lo pisa el botón «Buscar permisos»—, sin esto la pestaña se queda
  /// mostrando **el kardex de la persona anterior** mientras el resto de la
  /// pantalla ya cambió. Las otras pestañas no tienen el problema porque son
  /// `ConsumerWidget` y leen el provider `family` con el código nuevo.
  ///
  /// Se resetea también qué consulta se está mostrando: quedar en «vac ganadas»
  /// de otra persona, con los resultados viejos abajo, es peor que volver al
  /// kardex.
  @override
  void didUpdateWidget(NominaPermisosTab anterior) {
    super.didUpdateWidget(anterior);
    if (anterior.codEmpleado != widget.codEmpleado) {
      setState(() {
        _clavePermisos = _armarClavePermisos();
        _claveVac = null;
        _mostrando = _Consulta.permisos;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final datoEmpleado =
        ref
            .watch(fichaSaldoProvider(widget.codEmpleado))
            .valueOrNull
            ?.datoEmpleado ??
        '';

    // **Este aviso NO se guía por el cajón.** Quién decide si se ofrecen las
    // cargas colectivas es `permisos_rrhh_screen.dart`, con el ancho del cajón
    // de la pantalla; acá el cajón es el panel de detalle, que a 1280 px mide
    // 879 y no se distingue de una tablet a pantalla completa (800). Con el
    // cajón, en escritorio salían las dos cosas a la vez: los botones arriba y
    // el cartel diciendo que no están.
    //
    // El ancho del dispositivo sí distingue, y además es la pregunta de fondo
    // —«¿es un teléfono?»—, que es de lo que habla el aviso.
    //
    // ponytail: difieren sólo si la ventana pasa los 1000 px y el cajón no
    // (sidebar del dashboard); ahí no hay botón ni aviso. Si alguna vez
    // molesta, bajar `partido` desde la pantalla por un provider.
    final esChica = Aire.de(MediaQuery.sizeOf(context).width) != Aire.amplio;

    return LayoutBuilder(
      builder: (context, cajon) {
        final aire = Aire.de(cajon.maxWidth);
        return ListView(
          padding: EdgeInsets.all(aire.esChico ? Esp.m : Esp.l),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _acciones(datoEmpleado, esChica),
                    const SizedBox(height: Esp.m),
                    _filtros(aire),
                    const SizedBox(height: Esp.m),
                    _resultado(aire),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── LAS TRES ALTAS ────────────────────────────────────────────────────────

  /// **Un botón del ACL por operación, y no uno solo para las tres.**
  /// `btnProgramarPermiso` lo tienen 4 usuarios y los otros dos 5: esconderlas
  /// detrás de un mismo nombre le concedería a una persona una atribución que
  /// hoy no tiene. Esconder no es autorizar —el gate de verdad está en el
  /// backend—, esto sólo evita ofrecer un botón que va a devolver 403.
  /// Las colectivas no están acá: viven en la barra de arriba y sólo aparecen
  /// con pantalla ancha (ver `permisos_rrhh_screen.dart`). Un botón que falta
  /// sin decir por qué se lee como que el sistema está roto, así que el motivo
  /// se muestra al lado de las altas que sí están —y sólo cuando falta—.
  static const _porQueNoHayColectivas =
      ' Las cargas colectivas necesitan una tablet o una computadora: en un '
      'teléfono, marcar a mucha gente se dispara de un roce, y cada roce de '
      'más es una persona cobrando días.';

  Widget _acciones(String datoEmpleado, bool esChica) => Bloque(
    icono: Icons.playlist_add_outlined,
    titulo: 'Cargar a nombre de esta persona',
    explicacion:
        'Las tres escriben en el kardex de abajo. Si no ve un botón, le falta '
        'ese permiso.${esChica ? _porQueNoHayColectivas : ''}',
    hijo: Wrap(
      spacing: Esp.s,
      runSpacing: Esp.s,
      children: [
        PermissionWidget(
          buttonName: btnProgramarVacacion,
          child: FilledButton.tonalIcon(
            onPressed:
                () => mostrarProgramarVacacion(
                  context: context,
                  codEmpleado: widget.codEmpleado,
                  datoEmpleado: datoEmpleado,
                ),
            icon: const Icon(Icons.beach_access_outlined, size: 18),
            label: const Text('Programar vacación'),
          ),
        ),
        PermissionWidget(
          buttonName: btnProgramarPermiso,
          child: FilledButton.tonalIcon(
            onPressed:
                () => mostrarProgramarPermiso(
                  context: context,
                  codEmpleado: widget.codEmpleado,
                  datoEmpleado: datoEmpleado,
                ),
            icon: const Icon(Icons.event_note_outlined, size: 18),
            label: const Text('Programar permiso'),
          ),
        ),
        PermissionWidget(
          buttonName: btnVacacionPagada,
          child: OutlinedButton.icon(
            onPressed:
                () => mostrarVacacionPagada(
                  context: context,
                  codEmpleado: widget.codEmpleado,
                  datoEmpleado: datoEmpleado,
                ),
            icon: const Icon(Icons.payments_outlined, size: 18),
            label: const Text('Vacación pagada'),
          ),
        ),
      ],
    ),
  );

  // ── LOS FILTROS ───────────────────────────────────────────────────────────

  Widget _filtros(Aire aire) {
    final tipos = ref.watch(tiposPermisoRrhhProvider(true));
    final tipo = ref.watch(filtroTipoPermisoProvider);
    final inicio = ref.watch(filtroFechaInicioProvider);
    final fin = ref.watch(filtroFechaFinProvider);
    final rango = ref.watch(filtroFechaRangoProvider);

    final disponibles = tipos.valueOrNull ?? const [];

    final campos = <Widget>[
      DropdownButtonFormField<String>(
        // **El valor tiene que existir entre las opciones o el `Dropdown`
        // revienta con un assert.** Mientras la lista viaja sólo está «Todos»,
        // así que un filtro que sobrevivió de la visita anterior se muestra
        // como «Todos» hasta que llegue su opción.
        value: disponibles.any((t) => t.codTipos == tipo) ? tipo : '',
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Tipo de permiso',
          border: OutlineInputBorder(),
          isDense: true,
        ),
        items: [
          // «Todos» es la cadena vacía, que el repositorio traduce a NULL: es lo
          // que el SP entiende por «no filtres».
          const DropdownMenuItem(value: '', child: Text('Todos')),
          for (final t in disponibles)
            DropdownMenuItem(
              value: t.codTipos,
              child: Text(
                t.nombre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        onChanged:
            (v) => ref.read(filtroTipoPermisoProvider.notifier).state = v ?? '',
      ),
      _filtroFecha(
        etiqueta: 'Fecha inicio',
        valor: inicio,
        ayuda: 'Permisos que empiezan de esa fecha en adelante.',
        onElegir: (f) => ref.read(filtroFechaInicioProvider.notifier).state = f,
      ),
      _filtroFecha(
        etiqueta: 'Fecha fin',
        valor: fin,
        ayuda: 'Permisos que terminan hasta esa fecha.',
        onElegir: (f) => ref.read(filtroFechaFinProvider.notifier).state = f,
      ),
      _filtroFecha(
        etiqueta: 'Estaba de permiso el día',
        valor: rango,
        // El rótulo del sistema anterior es «Fecha Rango» y engaña: no es un
        // extremo de nada. El SP pregunta si esa fecha cae DENTRO del rango del
        // permiso.
        ayuda: 'Permisos cuyo rango atrapa esa fecha («Fecha Rango»).',
        onElegir: (f) => ref.read(filtroFechaRangoProvider.notifier).state = f,
      ),
    ];

    return Bloque(
      icono: Icons.filter_alt_outlined,
      titulo: 'Buscar en el kardex',
      explicacion:
          'Todos los filtros son opcionales y se combinan. La búsqueda sale '
          'cuando presiona un botón, no mientras elige.',
      hijo: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (aire.esChico)
            for (final c in campos) ...[c, const SizedBox(height: Esp.m)]
          else
            // Dos por fila: cuatro campos en una sola línea dejan cada uno con
            // 150 px y las etiquetas cortadas.
            for (var i = 0; i < campos.length; i += 2) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: campos[i]),
                  const SizedBox(width: Esp.m),
                  Expanded(child: campos[i + 1]),
                ],
              ),
              const SizedBox(height: Esp.m),
            ],

          Wrap(
            spacing: Esp.s,
            runSpacing: Esp.s,
            children: [
              FilledButton.icon(
                onPressed:
                    () => setState(() {
                      _clavePermisos = _armarClavePermisos();
                      _mostrando = _Consulta.permisos;
                    }),
                icon: const Icon(Icons.search, size: 18),
                label: const Text('Buscar permisos'),
              ),
              OutlinedButton.icon(
                onPressed:
                    () => setState(() {
                      _claveVac = _armarClaveVac();
                      _mostrando = _Consulta.vacGanadas;
                    }),
                icon: const Icon(Icons.event_available_outlined, size: 18),
                label: const Text('Buscar vac ganadas'),
              ),
              if (tipo.isNotEmpty ||
                  inicio != null ||
                  fin != null ||
                  rango != null)
                TextButton(
                  onPressed: () {
                    ref.read(filtroTipoPermisoProvider.notifier).state = '';
                    ref.read(filtroFechaInicioProvider.notifier).state = null;
                    ref.read(filtroFechaFinProvider.notifier).state = null;
                    ref.read(filtroFechaRangoProvider.notifier).state = null;
                    setState(() {
                      _clavePermisos = _armarClavePermisos();
                      _claveVac = null;
                      _mostrando = _Consulta.permisos;
                    });
                  },
                  child: const Text('Limpiar filtros'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filtroFecha({
    required String etiqueta,
    required DateTime? valor,
    required String ayuda,
    required ValueChanged<DateTime?> onElegir,
  }) => Row(
    children: [
      Expanded(
        child: CampoElegido(
          etiqueta: etiqueta,
          texto: valor == null ? null : fechaCorta(valor),
          pista: 'Sin filtrar',
          ayuda: ayuda,
          onTap: () async {
            final hoy = DateTime.now();
            final f = await showDatePicker(
              context: context,
              initialDate: valor ?? hoy,
              firstDate: DateTime(hoy.year - 5),
              lastDate: DateTime(hoy.year + 2, 12, 31),
              helpText: etiqueta,
            );
            if (!mounted || f == null) return;
            onElegir(f);
          },
        ),
      ),
      if (valor != null)
        IconButton(
          tooltip: 'Quitar $etiqueta',
          icon: const Icon(Icons.close, size: 18),
          onPressed: () => onElegir(null),
        ),
    ],
  );

  // ── LAS DOS GRILLAS ───────────────────────────────────────────────────────

  Widget _resultado(Aire aire) =>
      _mostrando == _Consulta.permisos
          ? _grillaPermisos(aire)
          : _grillaVacGanadas(aire);

  Widget _grillaPermisos(Aire aire) {
    final filas = ref.watch(nominaPermisosProvider(_clavePermisos));
    return Bloque(
      icono: Icons.event_note_outlined,
      titulo: 'Nómina de permisos',
      // Acá es donde alguien va a buscar el botón de editar o borrar, así que
      // acá se dice que no existe. Antes estaba en una cabecera fija arriba de
      // todo, que se lee una vez y después ocupa tres renglones para siempre.
      explicacion:
          'Todo lo que tiene cargado en el kardex, del más reciente al más '
          'viejo. Editar o borrar uno ya cargado y la reposición de horas '
          'siguen en el sistema anterior; por eso no hay columnas de deuda.',
      hijo: filas.when(
        loading: () => const Cargando(),
        error:
            (e, _) => ErrorDelDato(
              error: e,
              onReintentar:
                  () => ref.invalidate(nominaPermisosProvider(_clavePermisos)),
            ),
        data: (lista) {
          if (lista.isEmpty) {
            return const MensajeVacio(
              icono: Icons.event_busy_outlined,
              titulo: 'Sin permisos',
              detalle:
                  'No hay permisos cargados que cumplan con esos filtros. '
                  'Pruebe quitando alguno.',
            );
          }
          // El SP ordena por `tp.desde ASC` y se invierte acá, no en el DAO:
          // `releerUltimo` recorre esa misma lista para encontrar la fila que
          // acaba de grabarse y depende del orden que devuelve el servidor.
          // Lo que cambia es cómo se lee la nómina, no cómo se consulta.
          final recientes = lista.reversed.toList();
          return aire.esChico
              ? _tarjetasPermisos(recientes)
              : _tablaPermisos(recientes);
        },
      ),
    );
  }

  /// En un teléfono, una tabla de seis columnas deja cada una con 55 px y el
  /// motivo cortado en la primera palabra. Una tarjeta por permiso pone cada
  /// dato con su rótulo y el motivo entero.
  Widget _tarjetasPermisos(List<NominaPermisoEntity> lista) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final p in lista)
        Padding(
          padding: const EdgeInsets.only(bottom: Esp.s),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: context.cs.outlineVariant),
              borderRadius: BorderRadius.circular(Esp.s),
            ),
            child: Padding(
              padding: const EdgeInsets.all(Esp.m),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // La fecha manda y la duración la acompaña a la derecha:
                  // en el teléfono se busca «cuándo faltó», no «qué tipo era».
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cuandoLargo(p.desde, p.hasta),
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.copyWith(
                                fontWeight: Peso.titulo,
                                fontFeatures: cifrasTabulares,
                              ),
                            ),
                            Text(
                              _horarioDe(p),
                              style: context.apagado()?.copyWith(
                                fontFeatures: cifrasTabulares,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${numeroDeDias(p.dias)} d',
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(
                              fontWeight: p.dias >= 1 ? Peso.titulo : null,
                              fontFeatures: cifrasTabulares,
                            ),
                          ),
                          Text(
                            '${numeroDeDias(p.horas)} h',
                            style: context.apagado()?.copyWith(
                              fontFeatures: cifrasTabulares,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (_esExcepcion(p) || p.motivo.trim().isNotEmpty) ...[
                    const SizedBox(height: Esp.s),
                    Wrap(
                      spacing: Esp.s,
                      runSpacing: Esp.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (_esExcepcion(p))
                          Etiqueta(
                            texto: _nombreDelTipo(p),
                            tono: _tonoDelTipo(p),
                          ),
                        if (p.motivo.trim().isNotEmpty)
                          Text(
                            enOracion(p.motivo),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
    ],
  );

  /// La nómina en escritorio, como **línea de tiempo** y no como planilla.
  ///
  /// El kardex es una historia de ausencias que abarca años, y la tabla plana
  /// de seis columnas no dejaba verlo: repetía la fecha dos veces —el 90% de
  /// los permisos empieza y termina el mismo día—, repetía la duración dos
  /// veces —0,5 días *son* 4 horas— y ponía el tipo, que casi siempre dice
  /// «Vacación», en la columna que más se escanea.
  ///
  /// Acá cada columna hace un solo trabajo: el riel de la izquierda dice en
  /// qué año estás parado, «Cuándo» junta fecha y horario en una sola
  /// expresión, «Duración» pone los días al frente y las horas como respaldo,
  /// y «Detalle» es la columna humana. El tipo aparece sólo cuando **no** es
  /// el habitual: si todo dice «Vacación», lo que importa es lo que no lo dice.
  /// Un renglón por permiso, con la duración dibujada.
  ///
  /// El kardex son cientos de medias jornadas iguales entre las que hay que
  /// encontrar lo que no lo es. Con la duración sólo en números, «0,5 · 0,5 ·
  /// 0,5» no se distingue de un permiso de una semana hasta que se lee cada
  /// fila. La barra convierte esa repetición en textura y hace que la ausencia
  /// larga salte sin leer nada.
  ///
  /// La escala es relativa al máximo de lo que hay en pantalla: con puras
  /// medias jornadas todas las barras son cortas, y basta una vacación para
  /// que el resto se achique y ella mande. Las horas viven en el tooltip de la
  /// barra: son la misma magnitud que los días y no merecen una columna.
  Widget _tablaPermisos(List<NominaPermisoEntity> lista) {
    final tope = lista.fold<double>(0.5, (m, p) => p.dias > m ? p.dias : m);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _cabeceraNomina(),
        for (final (anio, filas) in agruparPorAnio(lista, (p) => p.desde)) ...[
          _tituloDelAnio(anio),
          for (final p in filas) _renglon(p, tope),
        ],
      ],
    );
  }

  static const double _anchoCuando = 140;
  static const double _anchoDias = 88;

  Widget _cabeceraNomina() => Padding(
    padding: const EdgeInsets.only(bottom: Esp.xs),
    child: Row(
      children: [
        SizedBox(width: _anchoCuando, child: _encabezado('Cuándo')),
        SizedBox(
          width: _anchoDias,
          child: _encabezado('Duración', aDerecha: true),
        ),
        const SizedBox(width: Esp.m),
        Expanded(child: _encabezado('Detalle')),
      ],
    ),
  );

  /// El año encabeza su tramo a lo ancho. El kardex va del más viejo al más
  /// nuevo y esto es lo único que ordena esa lectura.
  Widget _tituloDelAnio(String anio) => Padding(
    padding: const EdgeInsets.only(top: Esp.l, bottom: Esp.xs),
    child: Row(
      children: [
        Text(
          anio,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: Peso.titulo,
            fontFeatures: cifrasTabulares,
            color: context.cs.primary,
          ),
        ),
        const SizedBox(width: Esp.m),
        Expanded(child: Divider(height: 1, color: context.cs.outlineVariant)),
      ],
    ),
  );

  Widget _renglon(NominaPermisoEntity p, double tope) => Padding(
    padding: const EdgeInsets.symmetric(vertical: Esp.xs),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: _anchoCuando,
          child: Text(
            cuandoCompacto(p.desde, p.hasta),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontFeatures: cifrasTabulares),
          ),
        ),
        SizedBox(
          width: _anchoDias,
          child: Text(
            '${numeroDeDias(p.dias)} d',
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: p.dias >= 1 ? Peso.titulo : null,
              fontFeatures: cifrasTabulares,
            ),
          ),
        ),
        const SizedBox(width: Esp.m),
        Expanded(child: _barraConMotivo(p, tope)),
        _botonBoleta(p),
      ],
    ),
  );

  /// La boleta del permiso, en PDF.
  ///
  /// No hay endpoint nuevo: `/vacacion/RptPermisoVacacion` ya existía y el
  /// repositorio del flujo del empleado ya sabe pedirlo. Lo único que faltaba
  /// era el punto de entrada desde el kardex, que es donde RR.HH. la busca
  /// cuando alguien reclama.
  Widget _botonBoleta(NominaPermisoEntity p) => PermissionWidget(
    buttonName: btnBoleta,
    child: IconButton(
      icon: const Icon(Icons.picture_as_pdf_outlined),
      iconSize: 20,
      tooltip: 'Bajar la boleta en PDF',
      onPressed: _bajando == p.codPermiso ? null : () => _bajarBoleta(p),
    ),
  );

  int? _bajando;

  Future<void> _bajarBoleta(NominaPermisoEntity p) async {
    setState(() => _bajando = p.codPermiso);
    try {
      final pdf = await ref.read(
        rptPermisoVacacionProvider(p.codPermiso).future,
      );
      if (!mounted) return;
      await Printing.layoutPdf(
        onLayout: (_) async => pdf,
        name: 'Boleta_${p.codPermiso}',
      );
    } catch (e) {
      if (!mounted) return;
      avisarError(context, e);
    } finally {
      if (mounted) setState(() => _bajando = null);
    }
  }

  /// La barra ocupa el renglón entero y el motivo va encima.
  ///
  /// Con la barra en una columna angosta sobraba media fila vacía a la derecha
  /// y la magnitud quedaba dibujada en 88 px. Acá la barra **es** el renglón:
  /// crece sobre todo el ancho disponible, el texto la monta y el espacio
  /// muerto desaparece. El día completo o más va en el tono pleno y la
  /// fracción de jornada apagada: «faltó» y «salió un rato» se distinguen
  /// antes de leer el número.
  Widget _barraConMotivo(NominaPermisoEntity p, double tope) => Tooltip(
    message:
        '${numeroDeDias(p.dias)} día(s) · ${numeroDeDias(p.horas)} hr(s)\n'
        '${_horarioDe(p)}',
    child: Stack(
      children: [
        Positioned.fill(
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: (p.dias / tope).clamp(0.04, 1).toDouble(),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: context.cs.primary.withValues(
                  alpha: p.dias >= 1 ? 0.30 : 0.12,
                ),
                borderRadius: BorderRadius.circular(Esp.xs),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Esp.s,
            vertical: Esp.s,
          ),
          child: Wrap(
            spacing: Esp.s,
            runSpacing: Esp.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (_esExcepcion(p))
                Etiqueta(texto: _nombreDelTipo(p), tono: _tonoDelTipo(p)),
              if (p.motivo.trim().isNotEmpty)
                Text(
                  enOracion(p.motivo),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
            ],
          ),
        ),
      ],
    ),
  );

  String _horarioDe(NominaPermisoEntity p) =>
      '${horaCorta(p.desde)} – ${horaCorta(p.hasta)}';

  /// El 93% de `trh_permiso` es vacación. Marcar la etiqueta en todas las
  /// filas es marcar ninguna: se muestra sólo cuando el permiso **no** es una
  /// vacación, que es lo que hace levantar la vista.
  bool _esExcepcion(NominaPermisoEntity p) =>
      p.tipoPermiso.trim().toLowerCase() != 'vac';

  /// El único tipo que lleva color es la vacación pagada: es dinero.
  TonoEtiqueta _tonoDelTipo(NominaPermisoEntity p) =>
      p.tipoPermiso.trim().toLowerCase() == 'pva'
          ? TonoEtiqueta.aviso
          : TonoEtiqueta.neutro;

  /// El texto de la columna «Permiso». Hay 28 filas históricas con el tipo
  /// vacío —residuo de un flujo que el sistema anterior dejó muerto— y ahí no
  /// se inventa nada: se dice que no tiene tipo.
  String _nombreDelTipo(NominaPermisoEntity p) =>
      p.datoTipoPermiso.trim().isNotEmpty
          ? p.datoTipoPermiso
          : (p.tipoPermiso.trim().isEmpty ? 'Sin tipo' : p.tipoPermiso);

  Widget _grillaVacGanadas(Aire aire) {
    final clave = _claveVac;
    if (clave == null) return const SizedBox.shrink();
    final filas = ref.watch(vacGanadasProvider(clave));

    return Bloque(
      icono: Icons.event_available_outlined,
      titulo: 'Nómina de vacaciones asignadas',
      explicacion:
          'Los días que ganó por antigüedad en ese rango de fechas. Este botón '
          'ignora el tipo de permiso y la fecha puntual.',
      hijo: filas.when(
        loading: () => const Cargando(),
        error:
            (e, _) => ErrorDelDato(
              error: e,
              onReintentar: () => ref.invalidate(vacGanadasProvider(clave)),
            ),
        data:
            (lista) =>
                lista.isEmpty
                    ? const MensajeVacio(
                      icono: Icons.event_busy_outlined,
                      titulo: 'Sin vacaciones ganadas',
                      detalle:
                          'No hay asignaciones registradas en ese rango. Las '
                          'que todavía no existen se cargan desde la pestaña '
                          '«Asignada».',
                    )
                    : aire.esChico
                    ? _tarjetasVac(lista)
                    : _tablaVac(lista),
      ),
    );
  }

  Widget _tarjetasVac(List<VacacionAsignadaEntity> lista) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final v in lista)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: Esp.s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: Esp.m,
                runSpacing: Esp.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '${fechaCorta(v.fecha)} ${horaCorta(v.fecha)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: Peso.titulo,
                      fontFeatures: cifrasTabulares,
                    ),
                  ),
                  Text(_diasDe(v), style: context.numero(fuerte: true)),
                ],
              ),
              if (v.motivo.trim().isNotEmpty)
                Text(v.motivo, style: context.apagado()),
              const Divider(height: Esp.m),
            ],
          ),
        ),
    ],
  );

  Widget _tablaVac(List<VacacionAsignadaEntity> lista) => Table(
    columnWidths: const {
      0: IntrinsicColumnWidth(),
      1: IntrinsicColumnWidth(),
      2: IntrinsicColumnWidth(),
      3: FlexColumnWidth(),
    },
    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
    children: [
      TableRow(
        decoration: BoxDecoration(color: context.cs.surfaceContainerHighest),
        children: [
          _encabezado('#'),
          _encabezado('Fecha'),
          _encabezado('Día(s)', aDerecha: true),
          _encabezado('Motivo'),
        ],
      ),
      for (var i = 0; i < lista.length; i++)
        TableRow(
          children: [
            _celda('${i + 1}', numero: true),
            _celda(
              '${fechaCorta(lista[i].fecha)} ${horaCorta(lista[i].fecha)}',
              numero: true,
            ),
            _celda(_diasDe(lista[i]), numero: true, aDerecha: true),
            _celda(lista[i].motivo),
          ],
        ),
    ],
  );

  /// Los días como los formateó el backend; el número crudo es el respaldo.
  String _diasDe(VacacionAsignadaEntity v) =>
      v.diasAsignadosTxt.isEmpty
          ? numeroDeDias(v.diasAsignados)
          : v.diasAsignadosTxt;

  Widget _encabezado(String texto, {bool aDerecha = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: Esp.s, horizontal: Esp.s),
    child: Text(
      texto,
      textAlign: aDerecha ? TextAlign.right : TextAlign.left,
      style: context.tituloSeccion(),
    ),
  );

  Widget _celda(String texto, {bool numero = false, bool aDerecha = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: Esp.s, horizontal: Esp.s),
        child: Text(
          texto,
          textAlign: aDerecha ? TextAlign.right : TextAlign.left,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontFeatures: numero ? cifrasTabulares : null,
          ),
        ),
      );
}
