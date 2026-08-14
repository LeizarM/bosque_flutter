import 'package:bosque_flutter/core/state/permisos_rrhh_provider.dart';
import 'package:bosque_flutter/core/state/permisos_vacacion_provider.dart'
    show rptPermisoVacacionProvider;
import 'package:bosque_flutter/core/utils/descargar_archivo.dart';
import 'package:bosque_flutter/domain/entities/nomina_permiso_entity.dart';
import 'package:bosque_flutter/presentation/widgets/permisos-rrhh/permisos_rrhh_comunes.dart';
// `Border` y `BorderStyle` existen en `excel` y en `material`, y el archivo
// necesita los dos paquetes. Se ocultan los de `excel` —que sólo servían para
// dibujarle un filete a las celdas— y quedan los de Flutter, que sí se usan
// para el borde de las tarjetas.
import 'package:excel/excel.dart' hide Border, BorderStyle;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

/// **Reporte de boletas entre fechas**, de toda la empresa.
///
/// Es el «Reporte de Boletas entre Fechas» del sistema anterior. Sirve para dos
/// preguntas distintas que la pantalla vieja mezclaba:
///
/// 1. **«¿Dónde está la boleta de fulano?»** — alguien pide una copia y no se
///    sabe de quién era. En el kardex hay que elegir la persona primero, y ésta
///    es justo la búsqueda que se hace cuando esa parte no se sabe.
/// 2. **«¿Cuánto se fue en permisos este mes?»** — la que el reporte viejo no
///    contestaba: había que exportar a Excel y sumar a mano. Por eso el total
///    está arriba y no al final de 200 filas.
///
/// **Origen:** `p_list_Permiso 'W'` vía `POST /permiso-rrhh/permisos/boletas`.
/// Acota por permisos **contenidos** en la ventana (`desde >= X AND hasta <= Y`),
/// no por los que la cruzan: una vacación del 28/07 al 03/08 no aparece buscando
/// boletas de agosto, porque empezó en julio. Es distinto de «quién está fuera»,
/// que sí pregunta por los que cruzan un día. Se dice en pantalla porque es la
/// causa número uno de «faltan boletas».
///
/// ## Por qué no es sólo una hoja modal
///
/// Es una tabla de seis columnas con exportación: en una hoja de 600 px el
/// motivo queda cortado en la primera palabra y el total no entra en la misma
/// pantalla que las filas. Con ancho se abre como diálogo y usa el espacio; en
/// un teléfono sigue siendo la hoja de siempre, con tarjetas en vez de tabla.
Future<void> mostrarReporteBoletas(BuildContext context) {
  const contenido = _ReporteBoletas();

  // El corte es el de la ventana y no el del cajón: acá todavía no hay cajón,
  // se está decidiendo qué contenedor abrir.
  if (Aire.de(MediaQuery.sizeOf(context).width) == Aire.justo) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      // Sin esto la hoja sube hasta el borde de la pantalla y la manija de
      // arrastre queda debajo del reloj y de la muesca: `isScrollControlled` le
      // permite ocupar TODO el alto, y el `SafeArea` de adentro sólo protege al
      // contenido, no al fondo de la hoja.
      useSafeArea: true,
      showDragHandle: true,
      // Un tope, para que abrir el reporte no tape la pantalla entera: se ve de
      // dónde salió y se cierra tocando afuera.
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      builder: (_) => contenido,
    );
  }

  return showDialog<void>(
    context: context,
    builder:
        (_) => Dialog(
          insetPadding: const EdgeInsets.all(Esp.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100, maxHeight: 820),
            child: contenido,
          ),
        ),
  );
}

/// Un estado que ocupa lo que sobra de la pantalla.
///
/// `Cargando`, `ErrorDelDato` y `MensajeVacio` se centran y traen su propio
/// scroll adentro, así que necesitan un alto acotado: adentro de un
/// `SliverToBoxAdapter` —que da alto infinito— revientan. `SliverFillRemaining`
/// con `hasScrollBody: false` les da justo el hueco que queda y, si no alcanza,
/// deja que el scroll de afuera se encargue.
class _Relleno extends StatelessWidget {
  const _Relleno({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      SliverFillRemaining(hasScrollBody: false, child: child);
}

class _ReporteBoletas extends ConsumerStatefulWidget {
  const _ReporteBoletas();

  @override
  ConsumerState<_ReporteBoletas> createState() => _ReporteBoletasState();
}

class _ReporteBoletasState extends ConsumerState<_ReporteBoletas> {
  /// Arranca en el mes en curso: es la ventana que se pide casi siempre, y
  /// abrir con los dos campos vacíos deja una pantalla que no muestra nada
  /// hasta que alguien adivine qué tocar.
  late DateTime _desde = DateTime(DateTime.now().year, DateTime.now().month, 1);
  late DateTime _hasta = DateTime.now();

  /// Cadena vacía = «Todos», que el repositorio traduce a NULL. Es lo que el SP
  /// entiende por «no filtres».
  String _tipo = '';

  /// Lo que se tipeó en el buscador. **Filtra en el cliente, no en el
  /// servidor**: los otros tres filtros son parámetros del SP y cada cambio es
  /// un viaje; éste recorta lo que ya está en pantalla, así que responde por
  /// letra sin pegarle a la base. Con un mes de boletas son cientos de filas,
  /// no cientos de miles.
  String _buscado = '';
  final _buscador = TextEditingController();

  int? _bajando;
  bool _exportando = false;

  @override
  void dispose() {
    _buscador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtro = (desde: _desde, hasta: _hasta, tipoPermiso: _tipo);
    final boletas = ref.watch(boletasProvider(filtro));

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, cajon) {
          final aire = Aire.de(cajon.maxWidth);
          final margen = EdgeInsets.symmetric(
            horizontal: aire.esChico ? Esp.m : Esp.l,
          );

          // **Slivers y no un `Column` con la cabecera fija.** Con la cabecera
          // fuera del scroll, cuando el alto disponible no alcanzaba para
          // filtros + resumen, la parte fija no tenía a dónde ceder y salía la
          // franja amarilla y negra: pasaba con el teléfono en horizontal (412
          // px de alto), en una ventana baja, y en escritorio con el texto al
          // 200%. No es un caso raro: el sistema operativo sube la escala de
          // letra y el reporte se rompía entero.
          //
          // Acá todo vive en el mismo scroll, así que **no hay alto que no
          // alcance**: si no entra, se scrollea. Y la lista sigue siendo
          // perezosa —`SliverList.builder`—, que es lo que se perdería metiendo
          // todo dentro de un `SingleChildScrollView`.
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: margen.copyWith(top: aire.esChico ? 0 : Esp.l),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _cabecera(aire),
                      const SizedBox(height: Esp.m),
                      _filtros(aire),
                      const SizedBox(height: Esp.m),
                    ],
                  ),
                ),
              ),
              ...boletas.when(
                loading: () => const [_Relleno(child: Cargando())],
                error:
                    (e, _) => [
                      _Relleno(
                        child: ErrorDelDato(
                          error: e,
                          onReintentar:
                              () => ref.invalidate(boletasProvider(filtro)),
                        ),
                      ),
                    ],
                data:
                    (lista) => _resultado(lista, aire, margen, cajon.maxWidth),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── CABECERA ──────────────────────────────────────────────────────────────

  Widget _cabecera(Aire aire) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reporte de boletas', style: context.tituloSeccion()),
            const SizedBox(height: 2),
            Text(
              'Las boletas emitidas en toda la empresa dentro del rango. Trae '
              'los permisos que empiezan y terminan adentro: uno que arranca '
              'antes del «desde» no entra.',
              style: context.apagado(),
            ),
          ],
        ),
      ),
      // El diálogo de escritorio no trae la manija de arrastre que cierra la
      // hoja del teléfono, así que necesita su propia salida.
      if (!aire.esChico)
        IconButton(
          tooltip: 'Cerrar',
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
    ],
  );

  // ── FILTROS ───────────────────────────────────────────────────────────────

  Widget _filtros(Aire aire) {
    final tipos =
        ref.watch(tiposPermisoRrhhProvider(true)).valueOrNull ?? const [];

    final combo = DropdownButtonFormField<String>(
      // El valor tiene que existir entre las opciones o el `Dropdown` revienta
      // con un assert. Mientras la lista viaja sólo está «Todos».
      value: tipos.any((t) => t.codTipos == _tipo) ? _tipo : '',
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Permiso',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      items: [
        const DropdownMenuItem(value: '', child: Text('Todos')),
        for (final t in tipos)
          DropdownMenuItem(
            value: t.codTipos,
            child: Text(t.nombre, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (v) => setState(() => _tipo = v ?? ''),
    );

    final desde = _campoFecha('Desde', _desde, esDesde: true);
    final hasta = _campoFecha('Hasta', _hasta, esDesde: false);

    final campos = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (aire.esChico) ...[
          combo,
          const SizedBox(height: Esp.m),
          Row(
            children: [
              Expanded(child: desde),
              const SizedBox(width: Esp.m),
              Expanded(child: hasta),
            ],
          ),
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: combo),
              const SizedBox(width: Esp.m),
              Expanded(child: desde),
              const SizedBox(width: Esp.m),
              Expanded(child: hasta),
            ],
          ),
      ],
    );

    // Los tres rangos que se piden de verdad. Sin esto, «el mes pasado» son
    // cuatro toques en dos calendarios.
    final atajos = Wrap(
      spacing: Esp.s,
      runSpacing: Esp.s,
      children: [
        _atajo('Este mes', _mesDe(DateTime.now())),
        _atajo(
          'Mes pasado',
          _mesDe(DateTime(DateTime.now().year, DateTime.now().month - 1)),
        ),
        _atajo('Este año', (
          DateTime(DateTime.now().year, 1, 1),
          DateTime(DateTime.now().year, 12, 31),
        )),
      ],
    );

    // **El buscador va separado de los otros tres y no en la misma fila.** Los
    // de arriba son parámetros de la consulta —cambiarlos vuelve a pedirle al
    // servidor—; éste recorta lo que ya llegó. Ponerlos juntos sugeriría que
    // hacen lo mismo, y después alguien no entiende por qué uno tarda y el
    // otro no.
    final buscador = TextField(
      controller: _buscador,
      onChanged: (v) => setState(() => _buscado = v),
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Buscar empleado o N.º',
        prefixIcon: const Icon(Icons.search, size: 20),
        border: const OutlineInputBorder(),
        isDense: true,
        suffixIcon:
            _buscado.isEmpty
                ? null
                : IconButton(
                  tooltip: 'Limpiar',
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    _buscador.clear();
                    setState(() => _buscado = '');
                  },
                ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        campos,
        const SizedBox(height: Esp.s),
        if (aire.esChico) ...[
          atajos,
          const SizedBox(height: Esp.s),
          buscador,
        ] else
          Row(
            children: [
              Expanded(child: atajos),
              const SizedBox(width: Esp.m),
              SizedBox(width: 280, child: buscador),
            ],
          ),
      ],
    );
  }

  /// Primer y último día del mes de [f]. El día 0 del mes siguiente es el
  /// último del actual, y así no hay que saber cuál tiene 31 ni si es bisiesto.
  (DateTime, DateTime) _mesDe(DateTime f) => (
    DateTime(f.year, f.month, 1),
    DateTime(f.year, f.month + 1, 0),
  );

  Widget _atajo(String rotulo, (DateTime, DateTime) rango) {
    final puesto = _mismoDia(_desde, rango.$1) && _mismoDia(_hasta, rango.$2);
    return ChoiceChip(
      label: Text(rotulo),
      selected: puesto,
      onSelected:
          (_) => setState(() {
            _desde = rango.$1;
            _hasta = rango.$2;
          }),
    );
  }

  bool _mismoDia(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _campoFecha(String rotulo, DateTime valor, {required bool esDesde}) =>
      CampoElegido(
        etiqueta: rotulo,
        texto: fechaCorta(valor),
        onTap: () => _elegirFecha(esDesde: esDesde),
      );

  Future<void> _elegirFecha({required bool esDesde}) async {
    final hoy = DateTime.now();
    final elegida = await showDatePicker(
      context: context,
      initialDate: esDesde ? _desde : _hasta,
      firstDate: DateTime(hoy.year - 5),
      lastDate: DateTime(hoy.year + 2, 12, 31),
      helpText: esDesde ? 'Desde' : 'Hasta',
    );
    if (elegida == null || !mounted) return;
    setState(() {
      if (esDesde) {
        _desde = elegida;
        // Un «desde» posterior al «hasta» devuelve siempre vacío y parece que
        // no hay boletas. Se corrige en vez de dejar buscar en un rango nulo.
        if (_hasta.isBefore(_desde)) _hasta = _desde;
      } else {
        _hasta = elegida;
        if (_hasta.isBefore(_desde)) _desde = _hasta;
      }
    });
  }

  // ── RESULTADO ─────────────────────────────────────────────────────────────

  /// Los slivers del resultado: el resumen y después las filas.
  ///
  /// Devuelve una lista y no un widget porque el resumen y las filas son dos
  /// slivers distintos: la lista tiene que quedar perezosa (`SliverList.builder`)
  /// y el resumen no, y meterlos en un solo `SliverToBoxAdapter` obligaría a
  /// construir las 200 filas de una.
  List<Widget> _resultado(
    List<NominaPermisoEntity> todas,
    Aire aire,
    EdgeInsets margen,
    double cajon,
  ) {
    if (todas.isEmpty) {
      return const [
        _Relleno(
          child: MensajeVacio(
            icono: Icons.receipt_long_outlined,
            titulo: 'Sin boletas en ese rango',
            detalle:
                'No hay permisos que empiecen y terminen dentro de esas '
                'fechas. Pruebe abriendo el rango: un permiso que arranca '
                'antes del «desde» no entra.',
          ),
        ),
      ];
    }

    // **El recorte se aplica ANTES del resumen y del Excel**, no sólo a la
    // tabla: si el total siguiera contando las boletas escondidas, la cifra de
    // arriba no sería la de lo que se está mirando, y el archivo exportado no
    // sería el que se ve. Buscar a una persona es justamente preguntar cuánto
    // se tomó ELLA.
    final lista = _filtrar(todas);

    if (lista.isEmpty) {
      // Motivo distinto del de arriba, así que mensaje distinto: acá sí hay
      // boletas en el rango, lo que no hay es coincidencia.
      return [
        _Relleno(
          child: MensajeVacio(
            icono: Icons.person_search_outlined,
            titulo: 'Nadie coincide con «$_buscado»',
            detalle:
                'Hay ${todas.length} boleta(s) en el rango, pero ninguna es de '
                'un empleado con ese nombre ni tiene ese número. Se busca sin '
                'importar tildes ni mayúsculas.',
          ),
        ),
      ];
    }

    final comoTabla = cajon >= _cajonMinimoTabla;

    return [
      SliverPadding(
        padding: margen,
        sliver: SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _resumen(lista, aire),
              const Divider(height: Esp.xl),
              if (comoTabla) ...[
                _cabeceraTabla(),
                const Divider(height: Esp.s),
              ],
            ],
          ),
        ),
      ),
      SliverPadding(
        padding: margen.copyWith(bottom: Esp.l),
        sliver: SliverList.builder(
          itemCount: lista.length,
          itemBuilder:
              (_, i) => comoTabla ? _renglon(lista[i]) : _tarjeta(lista[i]),
        ),
      ),
    ];
  }

  /// **El total, arriba.** Es lo que el reporte viejo no contestaba: para saber
  /// cuántos días se fueron en el mes había que apretar «Exportar Excel» y
  /// sumar la columna a mano. El desglose por tipo aparece sólo cuando el
  /// filtro está en «Todos», porque con un tipo elegido repetiría el filtro.
  Widget _resumen(List<NominaPermisoEntity> lista, Aire aire) {
    final dias = lista.fold<double>(0, (a, b) => a + b.dias);
    final horas = lista.fold<double>(0, (a, b) => a + b.horas);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Wrap(
                spacing: Esp.xl,
                runSpacing: Esp.s,
                children: [
                  Metrica(
                    // Con el buscador puesto se dice «de cuántas», porque si no
                    // el número se lee como el total del mes y no lo es.
                    rotulo:
                        _buscado.isEmpty ? 'Boletas' : 'Boletas (filtradas)',
                    texto: '${lista.length}',
                    destacada: true,
                  ),
                  Metrica(
                    rotulo: 'Días',
                    texto: numeroDeDias(dias),
                    destacada: true,
                  ),
                  Metrica(rotulo: 'Horas', texto: numeroDeDias(horas)),
                ],
              ),
            ),
            _botonExcel(lista, aire),
          ],
        ),
        if (_tipo.isEmpty && _porTipo(lista).length > 1) ...[
          const SizedBox(height: Esp.m),
          Wrap(
            spacing: Esp.s,
            runSpacing: Esp.xs,
            children: [
              for (final e in _porTipo(lista).entries)
                Etiqueta(
                  texto: '${e.key} · ${numeroDeDias(e.value)} d',
                  tono: TonoEtiqueta.neutro,
                ),
            ],
          ),
        ],
      ],
    );
  }

  /// Las boletas que coinciden con lo tipeado, por nombre o por número.
  ///
  /// El número entra en el mismo campo porque es la otra mitad de la misma
  /// pregunta: a esta pantalla se llega para encontrar «la boleta de fulano» o
  /// «la boleta 8135», y obligar a elegir dos buscadores para eso es hacer
  /// trabajar a quien busca.
  List<NominaPermisoEntity> _filtrar(List<NominaPermisoEntity> lista) {
    final aguja = _plano(_buscado);
    if (aguja.isEmpty) return lista;
    return lista
        .where(
          (p) =>
              _plano(p.datoEmpleado).contains(aguja) ||
              '${p.codPermiso}'.contains(aguja),
        )
        .toList();
  }

  /// Minúsculas y sin tildes, para comparar.
  ///
  /// **Sin esto el buscador no sirve para media planilla.** Los nombres vienen
  /// del padrón en mayúsculas y con tilde —«TEÓFILO», «PATIÑO», «JOSÉ»—, y
  /// quien busca escribe «teofilo» en un teclado sin acentos. `toLowerCase()`
  /// solo no alcanza: «Ó» en minúscula sigue siendo «ó», que no es «o».
  ///
  /// La ñ **no** se pisa a propósito: es una letra distinta en español, no una
  /// n con adorno, y confundir «PEÑA» con «PENA» sería un error, no una ayuda.
  static String _plano(String texto) {
    const conTilde = 'áàäâãéèëêíìïîóòöôõúùüûÁÀÄÂÃÉÈËÊÍÌÏÎÓÒÖÔÕÚÙÜÛ';
    const sinTilde = 'aaaaaeeeeiiiiooooouuuuAAAAAEEEEIIIIOOOOOUUUU';
    final salida = StringBuffer();
    for (final letra in texto.trim().toLowerCase().split('')) {
      final i = conTilde.indexOf(letra);
      salida.write(i < 0 ? letra : sinTilde[i].toLowerCase());
    }
    return salida.toString();
  }

  /// Días por tipo de permiso, del que más pesa al que menos. Ordenado por
  /// magnitud y no alfabéticamente: la pregunta es «en qué se fueron los días».
  Map<String, double> _porTipo(List<NominaPermisoEntity> lista) {
    final acumulado = <String, double>{};
    for (final p in lista) {
      acumulado.update(
        _nombreDelTipo(p),
        (v) => v + p.dias,
        ifAbsent: () => p.dias,
      );
    }
    final ordenado =
        acumulado.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return {for (final e in ordenado) e.key: e.value};
  }

  Widget _botonExcel(List<NominaPermisoEntity> lista, Aire aire) {
    final icono = const Icon(Icons.table_view_outlined, size: 18);
    if (_exportando) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: Esp.m),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    return aire.esChico
        ? IconButton(
          tooltip: 'Exportar a Excel',
          icon: icono,
          onPressed: () => _exportar(lista),
        )
        : FilledButton.tonalIcon(
          onPressed: () => _exportar(lista),
          icon: icono,
          label: const Text('Exportar a Excel'),
        );
  }

  // ── LA TABLA (ESCRITORIO) ─────────────────────────────────────────────────

  /// **Cuándo la tabla deja de ser una tabla.**
  ///
  /// Las columnas fijas suman 566 px (78 + 150 + 74 + 12 + 210 + 12 + 48), más
  /// 16 del relleno del renglón y 32 del margen del contenido: con menos de
  /// **614 px de cajón** el `Expanded` del detalle vale cero y la fila desborda.
  /// El corte por [Aire] es en 600, o sea que quedaba una franja —una ventana de
  /// escritorio entre 648 y 662 px— donde se dibujaba la tabla sin lugar y salía
  /// la franja amarilla y negra en TODOS los renglones.
  ///
  /// Y no alcanza con evitar el desborde: a 662 el detalle mide 0 px y el motivo
  /// se parte en una tira de una letra por renglón. Los ~250 px de más son para
  /// que el motivo —que del SP llega hasta 100 caracteres— se lea en una o dos
  /// líneas. Debajo de eso, la tarjeta es mejor tabla que la tabla.
  ///
  /// Se mide el **cajón** y no [Aire]: `Aire` contesta «qué tan chica es la
  /// pantalla» y sirve para el relleno y los filtros; esto contesta «¿entra esta
  /// tabla?», que depende de estos siete números y de nada más.
  static const double _cajonMinimoTabla = 864;

  static const double _anchoBoleta = 78;
  static const double _anchoCuando = 150;
  static const double _anchoDuracion = 74;
  static const double _anchoEmpleado = 210;
  static const double _anchoPdf = 48;

  Widget _cabeceraTabla() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: Esp.s),
    child: Row(
      children: [
        SizedBox(width: _anchoBoleta, child: _th('N.º')),
        SizedBox(width: _anchoCuando, child: _th('Cuándo')),
        SizedBox(width: _anchoDuracion, child: _th('Duración', aDerecha: true)),
        const SizedBox(width: Esp.m),
        SizedBox(width: _anchoEmpleado, child: _th('Empleado')),
        const SizedBox(width: Esp.m),
        Expanded(child: _th('Detalle')),
        const SizedBox(width: _anchoPdf),
      ],
    ),
  );

  Widget _th(String texto, {bool aDerecha = false}) => Text(
    texto,
    textAlign: aDerecha ? TextAlign.right : TextAlign.left,
    style: context.tituloSeccion(),
  );

  Widget _renglon(NominaPermisoEntity p) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: Esp.s, vertical: Esp.xs),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: _anchoBoleta,
          child: Text(
            '${p.codPermiso}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontFeatures: cifrasTabulares,
              fontWeight: Peso.titulo,
            ),
          ),
        ),
        SizedBox(
          width: _anchoCuando,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _cuando(p),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontFeatures: cifrasTabulares),
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
        SizedBox(
          width: _anchoDuracion,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${numeroDeDias(p.dias)} d',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
        ),
        const SizedBox(width: Esp.m),
        SizedBox(
          width: _anchoEmpleado,
          child: Text(
            _nombreDelEmpleado(p),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        const SizedBox(width: Esp.m),
        Expanded(child: _detalle(p)),
        SizedBox(width: _anchoPdf, child: _botonPdf(p)),
      ],
    ),
  );

  /// El tipo y el motivo. **La etiqueta del tipo sale sólo con el filtro en
  /// «Todos»**: con un tipo elegido, todas las filas son ése y repetirlo en
  /// cada renglón es marcar ninguna.
  Widget _detalle(NominaPermisoEntity p) => Wrap(
    spacing: Esp.s,
    runSpacing: Esp.xs,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      if (_tipo.isEmpty)
        Etiqueta(
          texto: _nombreDelTipo(p),
          // El único tipo que lleva color es la vacación pagada: es dinero.
          tono:
              p.tipoPermiso.trim().toLowerCase() == 'pva'
                  ? TonoEtiqueta.aviso
                  : TonoEtiqueta.neutro,
        ),
      if (p.motivo.trim().isNotEmpty)
        Text(
          enOracion(p.motivo),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
    ],
  );

  // ── LAS TARJETAS (TELÉFONO) ───────────────────────────────────────────────

  Widget _tarjeta(NominaPermisoEntity p) => Padding(
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    _nombreDelEmpleado(p),
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(fontWeight: Peso.titulo),
                  ),
                ),
                Text(
                  'N.º ${p.codPermiso}',
                  style: context.apagado()?.copyWith(
                    fontFeatures: cifrasTabulares,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Esp.xs),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cuandoLargo(p.desde, p.hasta),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                _botonPdf(p),
              ],
            ),
            const SizedBox(height: Esp.xs),
            _detalle(p),
          ],
        ),
      ),
    ),
  );

  // ── ACCIONES ──────────────────────────────────────────────────────────────

  Widget _botonPdf(NominaPermisoEntity p) => IconButton(
    tooltip: 'Bajar la boleta en PDF',
    icon: const Icon(Icons.picture_as_pdf_outlined),
    iconSize: 20,
    onPressed: _bajando == p.codPermiso ? null : () => _bajar(p),
  );

  Future<void> _bajar(NominaPermisoEntity p) async {
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

  /// El `.xlsx` con las mismas columnas que exportaba el sistema anterior.
  ///
  /// **Los números van como números y no como texto.** El botón existe para que
  /// alguien sume, filtre y arme una tabla dinámica; con las cantidades en texto
  /// —que es como salía del `dataExporter` viejo— Excel no suma nada y el
  /// archivo sirve sólo para mirar. La fila de totales al final es la misma
  /// cuenta que muestra la pantalla, para que el archivo y la pantalla no
  /// puedan discrepar.
  Future<void> _exportar(List<NominaPermisoEntity> lista) async {
    setState(() => _exportando = true);
    try {
      final libro = Excel.createExcel();
      final hoja = libro['Boletas'];
      if (libro.tables.containsKey('Sheet1')) libro.delete('Sheet1');

      const columnas = [
        'N.º Boleta',
        'Permiso',
        'Empleado',
        'Desde',
        'Hasta',
        'En día(s)',
        'En hr(s)',
        'Motivo',
      ];
      final anchos = [12.0, 18.0, 34.0, 18.0, 18.0, 11.0, 11.0, 42.0];
      for (var c = 0; c < anchos.length; c++) {
        hoja.setColumnWidth(c, anchos[c]);
      }

      final estiloCabecera = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#D9D9D9'),
      );

      // **Cuatro decimales, no los dos del formato por defecto.**
      // `trh_permiso.cantidadDias` es un float y viene en fracciones de jornada:
      // 0,125 es una hora y 0,4375 son tres horas y media. Con «0.00» —el
      // formato que `excel` le pone solo a un número— la celda MUESTRA 0,13 y
      // 0,44 aunque adentro guarde el valor entero, así que la columna deja de
      // sumar a ojo lo que dice la fila de totales: dos boletas de una hora se
      // leen «0,13 + 0,13» y el total dice 0,25. Quien audita concluye que el
      // total está mal, y el total es lo único que estaba bien.
      final estiloFraccion = CellStyle(
        numberFormat: CustomNumericNumFormat(formatCode: '0.####'),
      );
      for (var c = 0; c < columnas.length; c++) {
        hoja.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0))
          ..value = TextCellValue(columnas[c])
          ..cellStyle = estiloCabecera;
      }

      for (var f = 0; f < lista.length; f++) {
        final p = lista[f];
        final valores = <CellValue>[
          IntCellValue(p.codPermiso),
          TextCellValue(_nombreDelTipo(p)),
          TextCellValue(_nombreDelEmpleado(p)),
          TextCellValue(_fechaHora(p.desde)),
          TextCellValue(_fechaHora(p.hasta)),
          DoubleCellValue(p.dias),
          DoubleCellValue(p.horas),
          TextCellValue(p.motivo.trim()),
        ];
        for (var c = 0; c < valores.length; c++) {
          final celda = hoja.cell(
            CellIndex.indexByColumnRow(columnIndex: c, rowIndex: f + 1),
          );
          celda.value = valores[c];
          // Los días y las horas son las dos columnas con fracciones.
          if (c == 5 || c == 6) celda.cellStyle = estiloFraccion;
        }
      }

      final filaTotal = lista.length + 1;
      final estiloTotal = CellStyle(
        bold: true,
        numberFormat: CustomNumericNumFormat(formatCode: '0.####'),
      );
      hoja.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: filaTotal))
        ..value = TextCellValue('Total (${lista.length} boletas)')
        ..cellStyle = estiloTotal;
      hoja.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: filaTotal))
        ..value = DoubleCellValue(lista.fold<double>(0, (a, b) => a + b.dias))
        ..cellStyle = estiloTotal;
      hoja.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: filaTotal))
        ..value = DoubleCellValue(lista.fold<double>(0, (a, b) => a + b.horas))
        ..cellStyle = estiloTotal;

      final bytes = libro.encode();
      if (bytes == null) throw Exception('No se pudo armar el archivo.');

      await descargarBytes(
        bytes,
        'Boletas_${_paraNombre(_desde)}_a_${_paraNombre(_hasta)}.xlsx',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
      if (mounted) avisar(context, 'Archivo generado.');
    } catch (e) {
      if (mounted) avisarError(context, e);
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  // ── TEXTOS ────────────────────────────────────────────────────────────────

  /// `03 ago`, o `03 ago → 10 ago 2025` cuando el rango buscado cruza años.
  ///
  /// **El año no es opcional acá.** En el kardex de una persona lo dice el
  /// encabezado del tramo; este reporte no agrupa por año y se puede pedir
  /// «01/01/2024 a 31/12/2025», donde dos filas «03 ago» del mismo empleado y
  /// con el mismo motivo son indistinguibles. El sistema anterior mostraba la
  /// fecha completa siempre; acá sale sólo cuando hace falta, para no pagar el
  /// ancho en el caso normal, que es pedir un mes. La tarjeta del teléfono usa
  /// `cuandoLargo`, que ya trae el año.
  String _cuando(NominaPermisoEntity p) {
    final compacto = cuandoCompacto(p.desde, p.hasta);
    if (_desde.year == _hasta.year || p.desde == null) return compacto;
    return '$compacto ${(p.hasta ?? p.desde)!.year}';
  }

  String _horarioDe(NominaPermisoEntity p) =>
      '${horaCorta(p.desde)} – ${horaCorta(p.hasta)}';

  String _fechaHora(DateTime? f) =>
      f == null ? '' : '${fechaCorta(f)} ${horaCorta(f)}';

  String _paraNombre(DateTime f) =>
      '${f.year}-${f.month.toString().padLeft(2, '0')}-'
      '${f.day.toString().padLeft(2, '0')}';

  /// Hay 28 filas históricas con el tipo vacío —residuo de un flujo que el
  /// sistema anterior dejó muerto— y ahí no se inventa nada.
  String _nombreDelTipo(NominaPermisoEntity p) =>
      p.datoTipoPermiso.trim().isNotEmpty
          ? p.datoTipoPermiso.trim()
          : (p.tipoPermiso.trim().isEmpty ? 'Sin tipo' : p.tipoPermiso.trim());

  String _nombreDelEmpleado(NominaPermisoEntity p) =>
      p.datoEmpleado.trim().isEmpty
          ? 'Empleado ${p.codEmpleado}'
          : p.datoEmpleado.trim();
}
