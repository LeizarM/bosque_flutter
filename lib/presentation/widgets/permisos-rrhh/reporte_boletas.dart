import 'dart:math' as math;

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

/// Un mes del cronograma, ya resuelto: cuántos días tiene y quiénes aparecen.
class _Mes {
  const _Mes({
    required this.primerDia,
    required this.dias,
    required this.filas,
    required this.boletas,
  });

  /// El día 1 del mes. Sólo se usan año y mes.
  final DateTime primerDia;

  /// 28, 29, 30 o 31. Se calcula una vez y no en cada celda.
  final int dias;

  final List<_FilaEmpleado> filas;

  /// Cuántas boletas caen en este mes, contando las que lo cruzan.
  final int boletas;
}

/// Una persona en un mes, con sus permisos ya repartidos en carriles.
class _FilaEmpleado {
  const _FilaEmpleado(this.nombre, this.carriles);

  final String nombre;

  /// Un carril por cada grupo de permisos que no se pisan entre sí. Casi
  /// siempre es uno solo; hay más cuando la persona tiene permisos solapados.
  final List<List<NominaPermisoEntity>> carriles;
}

/// Las dos formas de mirar las mismas boletas.
enum _Vista {
  lista('Lista', Icons.format_list_bulleted),
  cronograma('Cronograma', Icons.calendar_view_month_outlined);

  const _Vista(this.rotulo, this.icono);
  final String rotulo;
  final IconData icono;
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

  /// Qué se está mirando. **Las dos vistas contestan preguntas distintas y por
  /// eso conviven en vez de reemplazarse:** la lista contesta «¿dónde está la
  /// boleta de fulano?» —tiene el motivo completo, el número y el Excel—; el
  /// cronograma contesta «¿quién falta cuándo, y se pisan?», que en una lista
  /// ordenada por fecha no se ve por más que se mire.
  _Vista _vista = _Vista.lista;

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
    final esCronograma = _vista == _Vista.cronograma;

    // **El catálogo manda el color, no una lista escrita acá.** Los tipos son
    // los de `v_tipos` grupo 13, que llegan por el mismo provider que llena el
    // combo; el color de cada barra sale de la posición que ocupa el tipo en
    // esa lista. Agregar un tipo en la base le da color solo.
    final catalogo = _ordenDelCatalogo();
    // Se arman una sola vez y no dentro del `itemBuilder`: agrupar 358 boletas
    // por mes y por empleado en cada scroll sería rehacer el trabajo por cuadro.
    final meses = esCronograma ? _porMes(lista) : const <_Mes>[];

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
              if (esCronograma) _leyenda(lista, catalogo),
              if (!esCronograma && comoTabla) ...[
                _cabeceraTabla(),
                const Divider(height: Esp.s),
              ],
            ],
          ),
        ),
      ),
      if (esCronograma)
        SliverPadding(
          padding: margen.copyWith(bottom: Esp.l),
          sliver: SliverList.builder(
            itemCount: meses.length,
            itemBuilder: (_, i) => _bloqueDelMes(meses[i], aire, catalogo),
          ),
        )
      else
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
        // **Un `Wrap` y no un `Row` con `Expanded`.** Las métricas se encogen,
        // pero el conmutador y el botón de Excel tienen ancho propio: con el
        // texto al 200 %, o en una ventana de 760 px, los dos juntos no entran
        // y el `Row` desbordaba 9,6 px. Acá el grupo de acciones se baja solo a
        // la línea de abajo en vez de reventar.
        Wrap(
          spacing: Esp.xl,
          runSpacing: Esp.m,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            Wrap(
              spacing: Esp.xl,
              runSpacing: Esp.s,
              children: [
                Metrica(
                  // Con el buscador puesto se dice «de cuántas», porque si no
                  // el número se lee como el total del mes y no lo es.
                  rotulo: _buscado.isEmpty ? 'Boletas' : 'Boletas (filtradas)',
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
            // También `Wrap`, no `Row`: con el texto al 200 % el conmutador
            // rotulado y el botón de Excel piden 1122 px y el diálogo da 1068.
            // Así el Excel se baja solo en vez de desbordar 54 px.
            Wrap(
              spacing: Esp.s,
              runSpacing: Esp.s,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [_conmutador(aire), _botonExcel(lista, aire)],
            ),
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

  /// Lista o cronograma.
  ///
  /// **Los rótulos salen sólo con `amplio`**, no con todo lo que no sea un
  /// teléfono. Entre 600 y 1000 px los dos segmentos rotulados más el botón de
  /// Excel empujaban las métricas —que son la respuesta principal de la
  /// pantalla— hasta desbordar. El ícono con su tooltip dice lo mismo y no
  /// compite por el ancho.
  Widget _conmutador(Aire aire) => SegmentedButton<_Vista>(
    segments: [
      for (final v in _Vista.values)
        ButtonSegment(
          value: v,
          icon: Icon(v.icono, size: 18),
          label: aire == Aire.amplio ? Text(v.rotulo) : null,
          tooltip: v.rotulo,
        ),
    ],
    selected: {_vista},
    showSelectedIcon: false,
    style: const ButtonStyle(
      visualDensity: VisualDensity.compact,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    onSelectionChanged: (s) => setState(() => _vista = s.first),
  );

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

  // ── EL CRONOGRAMA ─────────────────────────────────────────────────────────

  /// Alto de una barra, y de la fila cuando el empleado tiene un solo carril.
  static const double _altoBarra = 18;

  /// Alto de la banda con los números del día.
  static const double _altoEje = 22;

  /// **Lo que hace que un permiso de cuatro horas se vea.** El 39 % de las
  /// boletas medidas dura menos de un día; con la grilla estirada a la pantalla
  /// esa barra mediría dos píxeles y la vista mentiría por omisión. Por debajo
  /// de esto la grilla deja de encogerse y aparece el scroll horizontal.
  static const double _diaMinimo = 11;

  /// Debajo de este ancho de día, los números no entran y el eje muestra sólo
  /// las bandas de fin de semana y una marca por semana.
  static const double _diaConNumero = 17;

  /// Las boletas por mes y, adentro, por empleado.
  ///
  /// **Por mes y no en un eje continuo del rango entero.** Con «Este año» un
  /// eje corrido son 365 columnas: o se scrollea un kilómetro, o cada día mide
  /// tres píxeles. Y el encabezado con las fechas queda arriba de todo, así que
  /// a la fila 40 ya no se sabe qué columna es qué. Partido por mes, el eje
  /// entra siempre en el ancho disponible y se repite en cada bloque.
  ///
  /// Lo permite la forma de los datos: el permiso promedio dura 1,84 días y el
  /// más largo 15, así que casi ninguno cruza de mes. El que cruza aparece en
  /// los dos, recortado, con el borde recto del lado por el que sigue.
  ///
  /// Meses **de más antiguo a más reciente**, o sea el tiempo corriendo hacia
  /// abajo igual que corre hacia la derecha adentro de cada mes. Es al revés
  /// que la lista, y a propósito: un cronograma se lee como una línea de
  /// tiempo, y una línea de tiempo que va para atrás obliga a releerla.
  List<_Mes> _porMes(List<NominaPermisoEntity> lista) {
    // **Por `codEmpleado` y no por el nombre.** Con el nombre como clave, dos
    // homónimos —que en un padrón de 76 personas pasa— se funden en una sola
    // fila, y de paso sus permisos se ven como si se solaparan entre sí: el
    // reparto en carriles los separaría inventando un cruce que no existe.
    final porMes = <DateTime, Map<int, List<NominaPermisoEntity>>>{};

    for (final p in lista) {
      final d = p.desde;
      final h = p.hasta ?? d;
      // Sin fechas no hay barra que dibujar. La fila igual existe en la lista.
      if (d == null || h == null) continue;

      var cursor = DateTime(d.year, d.month);
      // **El mes final nunca puede quedar antes del inicial.** Con `hasta`
      // anterior a `desde` y en otro mes —las hay en el histórico— el `while`
      // no daba ni una vuelta y la boleta no entraba en NINGÚN bloque: ni
      // dibujada, ni contada, ni avisada. El resumen decía una cosa y el
      // cronograma otra, en silencio. Acotado acá, la fila cae en el mes del
      // `desde` y `_tramo` le da su día de ancho.
      final mesDeHasta = DateTime(h.year, h.month);
      final ultimo = mesDeHasta.isBefore(cursor) ? cursor : mesDeHasta;
      // Tope de vueltas: una fila con las fechas al revés o con un año absurdo
      // —los hay en el histórico— no puede colgar la pantalla.
      var vueltas = 0;
      while (!cursor.isAfter(ultimo) && vueltas < 24) {
        porMes
            .putIfAbsent(cursor, () => {})
            .putIfAbsent(p.codEmpleado, () => [])
            .add(p);
        cursor = DateTime(cursor.year, cursor.month + 1);
        vueltas++;
      }
    }

    final claves = porMes.keys.toList()..sort();

    return [
      for (final mes in claves)
        () {
          final porEmpleado = porMes[mes]!;
          final dias = DateTime(mes.year, mes.month + 1, 0).day;
          // Alfabético por el nombre que se muestra: a un cronograma se viene
          // con un nombre en la cabeza, no con un código.
          final codigos =
              porEmpleado.keys.toList()..sort(
                (a, b) => _nombreDelEmpleado(porEmpleado[a]!.first).compareTo(
                  _nombreDelEmpleado(porEmpleado[b]!.first),
                ),
              );
          final filas = [
            for (final cod in codigos)
              _FilaEmpleado(
                _nombreDelEmpleado(porEmpleado[cod]!.first),
                _carriles(porEmpleado[cod]!, mes, dias),
              ),
          ];
          return _Mes(
            primerDia: mes,
            dias: dias,
            filas: filas,
            boletas: porEmpleado.values.fold(0, (a, b) => a + b.length),
          );
        }(),
    ];
  }

  /// Reparte los permisos de una persona en carriles que no se pisen.
  ///
  /// **No es un lujo.** Dos permisos solapados de la misma persona no deberían
  /// existir, pero en `trh_permiso` hay 291 pares así —el alta vieja no
  /// validaba cruces—. Dibujados en un solo carril, el segundo tapa al primero
  /// y el cronograma esconde justo el dato que haría notar el problema.
  List<List<NominaPermisoEntity>> _carriles(
    List<NominaPermisoEntity> permisos,
    DateTime mes,
    int diasDelMes,
  ) {
    final ordenados = [...permisos]..sort((a, b) {
      final ka = _tramo(a, mes, diasDelMes);
      final kb = _tramo(b, mes, diasDelMes);
      final porInicio = ka.$1.compareTo(kb.$1);
      return porInicio != 0 ? porInicio : ka.$2.compareTo(kb.$2);
    });

    final carriles = <List<NominaPermisoEntity>>[];
    final finDeCarril = <int>[];

    for (final p in ordenados) {
      final (inicio, fin) = _tramo(p, mes, diasDelMes);
      var puesto = false;
      for (var c = 0; c < carriles.length; c++) {
        if (finDeCarril[c] <= inicio) {
          carriles[c].add(p);
          finDeCarril[c] = fin;
          puesto = true;
          break;
        }
      }
      if (!puesto) {
        carriles.add([p]);
        finDeCarril.add(fin);
      }
    }
    return carriles;
  }

  /// El tramo `[inicio, fin)` que ocupa el permiso DENTRO de ese mes, en días
  /// de base cero. Lo que sobresale por cualquiera de los dos lados se recorta:
  /// esa parte se dibuja en el bloque del mes que le toca.
  (int, int) _tramo(NominaPermisoEntity p, DateTime mes, int diasDelMes) {
    final d = p.desde;
    final h = p.hasta ?? d;
    if (d == null || h == null) return (0, 1);

    final empiezaAntes = d.year < mes.year || (d.year == mes.year && d.month < mes.month);
    final terminaDespues = h.year > mes.year || (h.year == mes.year && h.month > mes.month);

    final inicio = empiezaAntes ? 0 : (d.day - 1).clamp(0, diasDelMes - 1);
    final fin = terminaDespues ? diasDelMes : h.day.clamp(1, diasDelMes);
    // Un `hasta` anterior al `desde` —lo hay en el histórico— daría ancho cero
    // o negativo. Se le da un día para que la fila exista y se pueda ver.
    return (inicio, fin > inicio ? fin : inicio + 1);
  }

  /// Qué significa cada color. Sólo los tipos que están en pantalla: una
  /// leyenda con los nueve del catálogo obliga a descartar siete a ojo.
  Widget _leyenda(List<NominaPermisoEntity> lista, Map<String, int> catalogo) {
    final vistos = <String, String>{};
    for (final p in lista) {
      vistos.putIfAbsent(p.tipoPermiso.trim().toLowerCase(), () => _nombreDelTipo(p));
    }
    // **Las que no se pueden dibujar se dicen, no se descartan en silencio.**
    // Una boleta sin fecha no tiene dónde ir en la grilla, pero la lista sí la
    // muestra: si el cronograma la omitiera callado, las dos vistas contarían
    // distinto y la gráfica sería la que miente.
    final sinFecha = lista.where((p) => p.desde == null).length;

    if (vistos.length < 2 && sinFecha == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: Esp.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (vistos.length > 1)
            Wrap(
              spacing: Esp.m,
              runSpacing: Esp.xs,
              children: [
                for (final e in vistos.entries)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color:
                            colorDeTipoPermiso(
                              context.cs,
                              catalogo[e.key] ?? -1,
                            ).fondo,
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(color: context.cs.outline),
                        ),
                      ),
                      const SizedBox(width: Esp.xs),
                      Text(e.value, style: context.apagado()),
                    ],
                  ),
              ],
            ),
          if (sinFecha > 0)
            Padding(
              padding: const EdgeInsets.only(top: Esp.xs),
              child: Text(
                '$sinFecha boleta(s) sin fecha no se pueden ubicar en el '
                'cronograma. Están en la lista.',
                style: context.apagado()?.copyWith(color: context.cs.error),
              ),
            ),
        ],
      ),
    );
  }

  Widget _bloqueDelMes(_Mes mes, Aire aire, Map<String, int> catalogo) {
    final cs = context.cs;
    // El nombre necesita lo suyo o la columna es una tira de puntos suspensivos.
    final anchoNombre = aire.esChico ? 108.0 : 176.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: Esp.xl),
      child: LayoutBuilder(
        builder: (context, cajon) {
          final disponible = (cajon.maxWidth - anchoNombre).clamp(
            _diaMinimo * 7,
            double.infinity,
          );
          final anchoDia = math.max(_diaMinimo, disponible / mes.dias);
          final anchoGrilla = anchoDia * mes.dias;
          // Medio píxel de margen: comparar dobles exactos hace aparecer un
          // scroll de una fracción de píxel que igual muestra la barra.
          final conScroll = anchoGrilla > disponible + 0.5;

          final grilla = SizedBox(
            width: anchoGrilla,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _eje(mes, anchoDia),
                for (final f in mes.filas)
                  _barras(mes, f, anchoDia, catalogo),
              ],
            ),
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _tituloDelMes(mes),
              const SizedBox(height: Esp.xs),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: anchoNombre,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: _altoEje),
                        for (final f in mes.filas)
                          SizedBox(
                            height: _altoDeFila(f),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: const EdgeInsets.only(right: Esp.s),
                                child: Text(
                                  f.nombre,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(color: cs.outlineVariant),
                        ),
                      ),
                      child:
                          conScroll
                              ? SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: grilla,
                              )
                              : grilla,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  double _altoDeFila(_FilaEmpleado f) => _altoBarra * f.carriles.length + Esp.xs;

  Widget _tituloDelMes(_Mes mes) {
    // **Sólo los que EMPIEZAN en este mes.** Un permiso que cruza aparece en
    // los dos bloques, y sumando sus días completos en cada uno el total de
    // los meses daba más que el resumen de arriba. Repartirlo en proporción
    // sería inventar un número: `cantidadDias` son días hábiles que calcula el
    // SP, no días de calendario. Contarlo donde arranca es exacto y la suma de
    // los meses vuelve a dar el total.
    final dias = mes.filas
        .expand((f) => f.carriles)
        .expand((c) => c)
        .toSet()
        .where(
          (p) =>
              p.desde != null &&
              p.desde!.year == mes.primerDia.year &&
              p.desde!.month == mes.primerDia.month,
        )
        .fold<double>(0, (a, b) => a + b.dias);

    // `Wrap` y no `Row`: con la letra al 200 % «Septiembre 2026» más el
    // renglón de cifras no entran en una línea y el `Row` desbordaba.
    return Wrap(
      spacing: Esp.s,
      runSpacing: Esp.xs,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        Text(
          '${mesesLargos[mes.primerDia.month - 1]} ${mes.primerDia.year}',
          style: context.tituloSeccion(),
        ),
        Text(
          '${mes.boletas} boleta(s) · ${numeroDeDias(dias)} d · '
          '${mes.filas.length} persona(s)',
          style: context.apagado(),
        ),
      ],
    );
  }

  /// La banda de los días. Fin de semana y hoy se tiñen; el número aparece sólo
  /// si entra.
  Widget _eje(_Mes mes, double anchoDia) {
    final conNumero = anchoDia >= _diaConNumero;
    return SizedBox(
      height: _altoEje,
      child: Row(
        children: [
          for (var d = 1; d <= mes.dias; d++)
            _celda(
              mes,
              d,
              anchoDia,
              hijo:
                  conNumero
                      ? Center(
                        child: Text(
                          '$d',
                          maxLines: 1,
                          style: context.numero(
                            fuerte: _esHoy(mes, d),
                            color:
                                _esHoy(mes, d)
                                    ? context.cs.primary
                                    : Theme.of(context).hintColor,
                          ),
                        ),
                      )
                      // Sin lugar para el número: una marca cada lunes alcanza
                      // para no perderse, y no puede desbordar.
                      : (_diaDeSemana(mes, d) == DateTime.monday
                          ? Center(
                            child: Container(
                              width: 2,
                              height: 6,
                              color: context.cs.outlineVariant,
                            ),
                          )
                          : null),
            ),
        ],
      ),
    );
  }

  Widget _barras(
    _Mes mes,
    _FilaEmpleado fila,
    double anchoDia,
    Map<String, int> catalogo,
  ) {
    final alto = _altoDeFila(fila);
    return SizedBox(
      height: alto,
      child: Stack(
        children: [
          // El fondo: las mismas bandas del eje, para que la vista tenga
          // referencia de dónde cae cada día sin dibujar 31 líneas.
          //
          // **`Positioned.fill` y no un `Row` suelto.** Las celdas son
          // `SizedBox` con ancho y sin alto; como hijo no posicionado de un
          // `Stack` el `Row` se medía en 0 px de alto y no se dibujaba NADA:
          // ni las bandas de fin de semana, ni el tinte de hoy, ni los
          // separadores de día. La franja del eje sí se veía —tiene su propio
          // `SizedBox(height: _altoEje)`— así que parecía que estaba puesto.
          Positioned.fill(
            child: Row(
              children: [
                for (var d = 1; d <= mes.dias; d++) _celda(mes, d, anchoDia),
              ],
            ),
          ),
          for (var c = 0; c < fila.carriles.length; c++)
            for (final p in fila.carriles[c])
              _barra(mes, p, anchoDia, c, catalogo),
        ],
      ),
    );
  }

  Widget _barra(
    _Mes mes,
    NominaPermisoEntity p,
    double anchoDia,
    int carril,
    Map<String, int> catalogo,
  ) {
    final (inicio, fin) = _tramo(p, mes.primerDia, mes.dias);
    final color = colorDeTipoPermiso(context.cs, _indice(p, catalogo));

    final sigueAntes = inicio == 0 && (p.desde?.day ?? 1) > 1;
    final sigueDespues =
        fin == mes.dias &&
        (p.hasta != null && p.hasta!.month != mes.primerDia.month);

    // Menos de un día: la barra ocupa la celda igual —si no, no se ve— pero más
    // finita. La diferencia de grosor dice «esto no fue una jornada entera»
    // sin depender del color, que ya está usado para el tipo.
    final parcial = p.dias > 0 && p.dias < 1;
    final grosor = parcial ? _altoBarra - 9 : _altoBarra - 5;
    const radio = Radius.circular(3);

    return Positioned(
      left: inicio * anchoDia,
      width: (fin - inicio) * anchoDia,
      top: carril * _altoBarra + (_altoBarra - grosor) / 2,
      height: grosor,
      child: Tooltip(
        message: _tooltip(p),
        waitDuration: const Duration(milliseconds: 300),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: _bajando == p.codPermiso ? null : () => _bajar(p),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 0.5),
              decoration: BoxDecoration(
                color: color.fondo,
                // Borde recto del lado por el que el permiso sigue en otro mes:
                // dice «esto continúa» sin agregar una flecha que a 11 px no se
                // vería.
                borderRadius: BorderRadius.horizontal(
                  left: sigueAntes ? Radius.zero : radio,
                  right: sigueDespues ? Radius.zero : radio,
                ),
                // **El borde es lo que garantiza que la barra se vea**, no el
                // relleno. Nueve rellenos que sean a la vez distintos entre sí
                // y visibles contra el fondo no entran en las 18 combinaciones
                // de tema: el escalón más pálido queda a 1,12 del fondo, o sea
                // invisible. Con un borde firme el relleno sólo tiene que
                // DIFERENCIAR, que sí se puede.
                border: Border.all(color: context.cs.outline, width: 1),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Una celda de día: el fondo teñido de sábado, domingo y hoy.
  Widget _celda(_Mes mes, int dia, double anchoDia, {Widget? hijo}) {
    final finde = _diaDeSemana(mes, dia) >= DateTime.saturday;
    final hoy = _esHoy(mes, dia);
    final cs = context.cs;

    return SizedBox(
      width: anchoDia,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color:
              hoy
                  ? cs.primary.withValues(alpha: 0.10)
                  : (finde ? cs.surfaceContainerHighest : null),
          border: Border(right: BorderSide(color: cs.outlineVariant, width: 0.5)),
        ),
        child: hijo,
      ),
    );
  }

  int _diaDeSemana(_Mes mes, int dia) =>
      DateTime(mes.primerDia.year, mes.primerDia.month, dia).weekday;

  bool _esHoy(_Mes mes, int dia) {
    final hoy = DateTime.now();
    return hoy.year == mes.primerDia.year &&
        hoy.month == mes.primerDia.month &&
        hoy.day == dia;
  }

  String _tooltip(NominaPermisoEntity p) {
    final motivo = p.motivo.trim();
    return [
      'N.º ${p.codPermiso} · ${_nombreDelTipo(p)}',
      '${cuandoLargo(p.desde, p.hasta)}  ${_horarioDe(p)}',
      '${numeroDeDias(p.dias)} d · ${numeroDeDias(p.horas)} h',
      if (motivo.isNotEmpty) enOracion(motivo),
      'Tocar para bajar la boleta',
    ].join('\n');
  }

  /// Los tipos de permiso como los devuelve la base, en un mapa
  /// `código → posición`.
  ///
  /// La lista sale de `v_tipos` grupo 13 por `p_list_Permiso @ACCION='T1'`, que
  /// es la misma que llena el combo de arriba. Mientras viaja, el mapa está
  /// vacío y todas las barras salen del color neutro: la vista no inventa un
  /// catálogo propio para tapar el hueco.
  Map<String, int> _ordenDelCatalogo() {
    final tipos =
        ref.watch(tiposPermisoRrhhProvider(true)).valueOrNull ?? const [];
    return {
      for (var i = 0; i < tipos.length; i++)
        tipos[i].codTipos.trim().toLowerCase(): i,
    };
  }

  /// Dónde cae este permiso en el catálogo, o `-1` si su código no está.
  ///
  /// Pasa con los 28 registros históricos que tienen el tipo vacío, y pasaría
  /// con un código que alguien saque de `v_tipos` dejando las filas viejas.
  int _indice(NominaPermisoEntity p, Map<String, int> catalogo) =>
      catalogo[p.tipoPermiso.trim().toLowerCase()] ?? -1;

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
