import 'dart:async';

import 'package:bosque_flutter/core/state/cartas_cite_provider.dart';
import 'package:bosque_flutter/core/state/rrhh_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/carta_cite_entity.dart';
import 'package:bosque_flutter/domain/entities/empresa_entity.dart';
import 'package:bosque_flutter/presentation/screens/cartas-cite/carta_cite_editor_screen.dart';
import 'package:bosque_flutter/presentation/widgets/cartas-cite/dialogos_cite.dart';
import 'package:bosque_flutter/presentation/widgets/cartas-cite/identidad_cite.dart';
import 'package:bosque_flutter/presentation/widgets/cartas-cite/lista_cartas_cite.dart';
import 'package:bosque_flutter/presentation/widgets/cartas-cite/visor_pdf_cite.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Cartas CITE — pantalla principal.
///
/// Es la correspondencia numerada de la empresa: se redacta acá, se archiva
/// con su correlativo y se imprime con el mismo formato de siempre.
///
/// Reemplaza `web/Bosque/tcrDocumento/Documento.xhtml` del sistema JSF. Dos
/// cosas cambian a propósito respecto de aquella pantalla:
///
/// - **Se entra por el listado, no por el formulario.** El módulo viejo abría
///   con dos combos y un botón "Desplegar Formulario", y las cartas ya escritas
///   quedaban en una pestaña de abajo. Lo que se hace casi siempre es buscar
///   una carta anterior —para reimprimirla o para copiarla—, así que eso es lo
///   que está primero.
///
/// - **La línea de tiempo no se migró.** Era un gráfico de PrimeFaces que
///   mostraba los mismos documentos que la grilla, ordenados por fecha, sin
///   ninguna acción encima. La grilla ya viene ordenada por fecha.
class CartasCiteScreen extends ConsumerStatefulWidget {
  const CartasCiteScreen({super.key});

  @override
  ConsumerState<CartasCiteScreen> createState() => _CartasCiteScreenState();
}

class _CartasCiteScreenState extends ConsumerState<CartasCiteScreen> {
  final _buscarCtrl = TextEditingController();
  Timer? _debounce;
  bool _inicializado = false;

  int get _uid => ref.read(userProvider)?.codUsuario ?? 0;
  int get _empresaDelUsuario => ref.read(userProvider)?.codEmpresa ?? 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _inicializar());
  }

  @override
  void dispose() {
    _buscarCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  /// Arranca por la empresa del usuario si la tiene; si no, por todas.
  Future<void> _inicializar() async {
    if (_inicializado || !mounted) return;
    _inicializado = true;
    await ref
        .read(cartasCiteProvider(_uid).notifier)
        .inicializar(codEmpresa: _empresaDelUsuario);
  }

  void _buscar(String texto) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(cartasCiteProvider(_uid).notifier).filtrar(buscar: texto);
    });
  }

  /// Vuelve al estado con el que abre el módulo. Es la salida del callejón:
  /// después de tres filtros encadenados nadie se acuerda de cuál dejó puesto.
  Future<void> _limpiarFiltros() async {
    _debounce?.cancel();
    _buscarCtrl.clear();
    final rango = RangoCite.tresMeses.calcular();
    await ref.read(cartasCiteProvider(_uid).notifier).filtrar(
          buscar: '',
          idTipoDoc: 0,
          codEmpresa: _empresaDelUsuario,
          fechaDesde: rango.$1,
          fechaHasta: rango.$2,
        );
  }

  // ── acciones ────────────────────────────────────────────────────────────

  Future<void> _nuevo() async {
    final eleccion = await mostrarDialogoNuevoCite(context, ref);
    if (eleccion == null || !mounted) return;

    final tipos = ref.read(tiposDocumentoCiteProvider).valueOrNull ?? [];
    final empresas = ref.read(empresasProvider).valueOrNull ?? [];

    final doc = CartaCiteEntity.nuevo(
      idTipoDoc: eleccion.idTipoDoc,
      codEmpresa: eleccion.codEmpresa,
      codUsuario: _uid,
    )
      ..tipo = tipos
              .where((t) => t.idTipoDoc.toInt() == eleccion.idTipoDoc)
              .map((t) => t.tipo)
              .firstOrNull ??
          ''
      ..empresa = empresas
              .where((e) => e.codEmpresa == eleccion.codEmpresa)
              .map((e) => e.nombre)
              .firstOrNull ??
          '';

    await _abrirEditor(doc);
  }

  Future<void> _abrirEditor(CartaCiteEntity doc, {bool soloLectura = false}) async {
    final mensaje = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => CartaCiteEditorScreen(original: doc, soloLectura: soloLectura),
      ),
    );
    if (mensaje != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensaje), backgroundColor: Colors.green),
      );
    }
  }

  /// Trae el documento completo antes de abrir: la grilla sólo tiene la
  /// cabecera, y el formulario necesita cuerpo, remitentes y destinatarios.
  Future<CartaCiteEntity?> _cargarCompleto(CartaCiteEntity fila) async {
    try {
      return await ref.read(cartasCiteRepositoryProvider).obtener(fila.idDocumento);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '')),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
      return null;
    }
  }

  Future<void> _editar(CartaCiteEntity fila, {bool soloLectura = false}) async {
    final completo = await _cargarCompleto(fila);
    if (completo == null || !mounted) return;
    await _abrirEditor(completo, soloLectura: soloLectura);
  }

  Future<void> _duplicar(CartaCiteEntity fila) async {
    final completo = await _cargarCompleto(fila);
    if (completo == null || !mounted) return;
    await _abrirEditor(completo.duplicar());
  }

  Future<void> _imprimir(CartaCiteEntity fila) async {
    // Sólo la carta se imprime con o sin membrete; el resto va siempre con logo.
    bool conLogo = true;
    if (fila.tipoDoc == TipoCite.carta) {
      final elegido = await mostrarDialogoLogo(context);
      if (elegido == null || !mounted) return;
      conLogo = elegido;
    }

    final cerrar = _mostrarCargando('Generando el PDF…');
    try {
      final bytes = await ref.read(cartasCiteRepositoryProvider).generarPdf(
            idDocumento: fila.idDocumento,
            conLogo: conLogo,
            audUsuario: _uid,
          );
      cerrar();
      if (!mounted) return;
      await mostrarPdfCite(
        context,
        bytes: bytes,
        titulo: '${fila.tipo} ${fila.cite}',
        nombreArchivo: '${fila.tipo.replaceAll(' ', '_')}_${fila.nroCite}.pdf',
      );
      // Refresca para que la fila muestre que ya fue exportada.
      await ref.read(cartasCiteProvider(_uid).notifier).cargar();
    } catch (e) {
      cerrar();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '')),
        backgroundColor: Theme.of(context).colorScheme.error,
      ));
    }
  }

  Future<void> _anular(CartaCiteEntity fila) async {
    final motivo = await mostrarDialogoAnular(
      context,
      descripcionDocumento: '${fila.tipo} ${fila.cite}',
    );
    if (motivo == null || !mounted) return;
    await ref
        .read(cartasCiteProvider(_uid).notifier)
        .anular(fila.idDocumento, motivo: motivo);
  }

  Future<void> _reporteMensual() async {
    final params = await mostrarDialogoReporteMensual(context, ref);
    if (params == null || !mounted) return;

    final cerrar = _mostrarCargando('Generando el reporte…');
    try {
      final bytes = await ref.read(cartasCiteRepositoryProvider).reporteMensual(
            mes: params.mes,
            anio: params.anio,
            idTipoDoc: params.idTipoDoc,
            codEmpresa: params.codEmpresa,
          );
      cerrar();
      if (!mounted) return;
      await mostrarPdfCite(
        context,
        bytes: bytes,
        titulo: 'Reporte mensual ${params.anio}',
        nombreArchivo: 'REPORTE_MENSUAL_${params.mes}_${params.anio}.pdf',
      );
    } catch (e) {
      cerrar();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '')),
        backgroundColor: Theme.of(context).colorScheme.error,
      ));
    }
  }

  VoidCallback _mostrarCargando(String texto) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            const SizedBox(
                width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: Esp.l),
            Expanded(child: Text(texto)),
          ],
        ),
      ),
    );
    var cerrado = false;
    return () {
      if (cerrado || !mounted) return;
      cerrado = true;
      Navigator.of(context, rootNavigator: true).pop();
    };
  }

  // ── UI ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(cartasCiteProvider(_uid));
    final notifier = ref.read(cartasCiteProvider(_uid).notifier);
    final cs = Theme.of(context).colorScheme;

    ref.listen<CartasCiteState>(cartasCiteProvider(_uid), (prev, next) {
      if (!mounted) return;
      if (next.mensajeExito != null && prev?.mensajeExito != next.mensajeExito) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.mensajeExito!), backgroundColor: Colors.green),
        );
        notifier.limpiarMensajes();
      }
      if (next.mensajeError != null && prev?.mensajeError != next.mensajeError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.mensajeError!), backgroundColor: cs.error),
        );
        notifier.limpiarMensajes();
      }
    });

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, cons) {
          final aire = Aire.de(cons.maxWidth);
          return Column(
            children: [
              _Cabecera(
                aire: aire,
                onNuevo: _nuevo,
                onReporte: _reporteMensual,
              ),
              _BarraFiltros(
                aire: aire,
                estado: estado,
                buscarCtrl: _buscarCtrl,
                empresaDelUsuario: _empresaDelUsuario,
                onBuscar: _buscar,
                onFiltrar: notifier.filtrar,
                onLimpiar: _limpiarFiltros,
              ),
              Expanded(
                child: ListaCartasCite(
                  aire: aire,
                  estado: estado,
                  codUsuario: _uid,
                  onVer: (f) => _editar(f, soloLectura: true),
                  onEditar: _editar,
                  onDuplicar: _duplicar,
                  onImprimir: _imprimir,
                  onAnular: _anular,
                  onNuevo: _nuevo,
                  onLimpiarFiltros: _limpiarFiltros,
                ),
              ),
              if (estado.totalRegistros > 0)
                _Paginacion(estado: estado, notifier: notifier, aire: aire),
            ],
          );
        },
      ),
      floatingActionButton: Aire.de(MediaQuery.of(context).size.width).esChico
          ? FloatingActionButton.extended(
              onPressed: _nuevo,
              icon: const Icon(Icons.add),
              label: const Text('Redactar'),
            )
          : null,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CABECERA
// ═══════════════════════════════════════════════════════════════════════════

class _Cabecera extends StatelessWidget {
  final Aire aire;
  final VoidCallback onNuevo;
  final VoidCallback onReporte;

  const _Cabecera({required this.aire, required this.onNuevo, required this.onReporte});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        aire.esChico ? Esp.m : Esp.xl,
        Esp.l,
        aire.esChico ? Esp.m : Esp.xl,
        Esp.m,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(Esquina.chica),
            ),
            child: Icon(Icons.mail_outline, size: 20, color: cs.onPrimaryContainer),
          ),
          SizedBox(width: Esp.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cartas CITE',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: Peso.titulo,
                        )),
                if (!aire.esChico)
                  Text('Correspondencia numerada de la empresa',
                      style: context.apagado()),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Reporte mensual',
            onPressed: onReporte,
            icon: const Icon(Icons.summarize_outlined),
          ),
          if (!aire.esChico) ...[
            SizedBox(width: Esp.s),
            FilledButton.icon(
              onPressed: onNuevo,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Redactar'),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// FILTROS
// ═══════════════════════════════════════════════════════════════════════════

/// Los períodos que se piden de verdad.
///
/// Antes había dos selectores de fecha siempre abiertos, y para ver «lo de este
/// mes» había que abrir dos calendarios y acertar dos veces. Los tres botones
/// cubren lo que se consulta el 90% de las veces; el calendario queda para el
/// resto, y con un solo selector de rango en lugar de dos.
enum RangoCite {
  esteMes('Este mes'),
  tresMeses('3 meses'),
  esteAnio('Este año');

  final String etiqueta;
  const RangoCite(this.etiqueta);

  /// (desde, hasta). El «hasta» es siempre hoy: no hay documentos futuros.
  (DateTime, DateTime) calcular() {
    final hoy = DateTime.now();
    return switch (this) {
      RangoCite.esteMes => (DateTime(hoy.year, hoy.month, 1), hoy),
      RangoCite.tresMeses => (DateTime(hoy.year, hoy.month - 3, 1), hoy),
      RangoCite.esteAnio => (DateTime(hoy.year, 1, 1), hoy),
    };
  }

  bool coincideCon(DateTime desde, DateTime hasta) {
    final (d, h) = calcular();
    return _mismoDia(d, desde) && _mismoDia(h, hasta);
  }
}

bool _mismoDia(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

class _BarraFiltros extends ConsumerWidget {
  final Aire aire;
  final CartasCiteState estado;
  final TextEditingController buscarCtrl;
  final int empresaDelUsuario;
  final void Function(String) onBuscar;
  final Future<void> Function({
    DateTime? fechaDesde,
    DateTime? fechaHasta,
    int? idTipoDoc,
    int? codEmpresa,
    String? buscar,
  }) onFiltrar;
  final VoidCallback onLimpiar;

  const _BarraFiltros({
    required this.aire,
    required this.estado,
    required this.buscarCtrl,
    required this.empresaDelUsuario,
    required this.onBuscar,
    required this.onFiltrar,
    required this.onLimpiar,
  });

  bool get _hayAlgoPuesto =>
      estado.hayFiltroTexto ||
      estado.idTipoDoc != 0 ||
      estado.codEmpresa != empresaDelUsuario ||
      !RangoCite.tresMeses.coincideCon(estado.fechaDesde, estado.fechaHasta);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tipos = ref.watch(tiposDocumentoCiteProvider).valueOrNull ?? [];
    final empresas = ref.watch(empresasProvider).valueOrNull ?? [];

    final padding = EdgeInsets.fromLTRB(
      aire.esChico ? Esp.m : Esp.xl,
      0,
      aire.esChico ? Esp.m : Esp.xl,
      Esp.m,
    );

    final buscar = TextField(
      controller: buscarCtrl,
      onChanged: onBuscar,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: aire.esChico
            ? 'Buscar documento…'
            : 'Buscar por destinatario, referencia, asunto o Nº',
        prefixIcon: const Icon(Icons.search, size: 20),
        isDense: true,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Esquina.chica),
        ),
        suffixIcon: estado.hayFiltroTexto
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                tooltip: 'Borrar la búsqueda',
                onPressed: () {
                  buscarCtrl.clear();
                  onFiltrar(buscar: '');
                },
              )
            : null,
      ),
    );

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          buscar,
          SizedBox(height: Esp.s),
          // Empresa, período y tipo, en una sola tira. Cómo se acomoda cuando
          // no entra lo decide [_Pastillas], que es donde está el porqué.
          _Pastillas(
            aire: aire,
            children: [
              _ChipEmpresa(
                codEmpresa: estado.codEmpresa,
                empresas: empresas,
                onElegir: (v) => onFiltrar(codEmpresa: v),
              ),
              const _SeparadorChips(),
              for (final r in RangoCite.values)
                Padding(
                  padding: EdgeInsets.only(right: Esp.xs),
                  child: ChoiceChip(
                    label: Text(r.etiqueta),
                    selected: r.coincideCon(estado.fechaDesde, estado.fechaHasta),
                    visualDensity: VisualDensity.compact,
                    onSelected: (_) {
                      final (d, h) = r.calcular();
                      onFiltrar(fechaDesde: d, fechaHasta: h);
                    },
                  ),
                ),
              _ChipRangoPropio(
                estado: estado,
                onElegir: (d, h) => onFiltrar(fechaDesde: d, fechaHasta: h),
              ),
              if (tipos.isNotEmpty) ...[
                const _SeparadorChips(),
                Padding(
                  padding: EdgeInsets.only(right: Esp.xs),
                  child: FilterChip(
                    label: const Text('Todos'),
                    selected: estado.idTipoDoc == 0,
                    visualDensity: VisualDensity.compact,
                    onSelected: (_) => onFiltrar(idTipoDoc: 0),
                  ),
                ),
                for (final t in tipos)
                  _ChipTipo(
                    idTipoDoc: t.idTipoDoc.toInt(),
                    etiqueta: t.tipo,
                    seleccionado: estado.idTipoDoc == t.idTipoDoc.toInt(),
                    onElegir: () => onFiltrar(
                      idTipoDoc:
                          estado.idTipoDoc == t.idTipoDoc.toInt() ? 0 : t.idTipoDoc.toInt(),
                    ),
                  ),
              ],
              if (_hayAlgoPuesto) ...[
                const _SeparadorChips(),
                ActionChip(
                  avatar: const Icon(Icons.filter_alt_off_outlined, size: 16),
                  label: const Text('Limpiar'),
                  visualDensity: VisualDensity.compact,
                  onPressed: onLimpiar,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// La tira de filtros, acomodada según el ancho.
///
/// ## El bug que arregla
///
/// La primera versión era siempre un `ListView` horizontal: una sola barra que
/// scrollea de costado, «el mismo diseño en un teléfono y en una ventana
/// ancha». En el teléfono funcionaba. **En web y escritorio no**, y no por
/// poco: la mitad de los tipos de documento quedaba fuera del borde derecho,
/// sin barra de scroll, sin poder arrastrarla con el mouse y con la rueda
/// scrolleando el eje equivocado. Filtrar por «INF. CONTROL INTERNO» era
/// literalmente imposible.
///
/// ## Qué hace ahora
///
/// - **Con ancho de sobra** (≥ 600 px) las pastillas **envuelven** a la línea
///   siguiente. No hay scroll que descubrir: lo que existe, se ve. Cuesta una
///   segunda fila de 40 px, que es barato al lado de un filtro inalcanzable.
/// - **En pantalla angosta** sigue siendo una tira que scrollea —doce
///   pastillas envueltas se comerían media pantalla de teléfono—, pero con
///   [ArrastreLateral], así que también se arrastra con el mouse en una
///   ventana angosta de escritorio.
class _Pastillas extends StatelessWidget {
  final Aire aire;
  final List<Widget> children;

  const _Pastillas({required this.aire, required this.children});

  @override
  Widget build(BuildContext context) {
    if (aire.esChico) {
      return SizedBox(
        height: 40,
        child: ScrollConfiguration(
          behavior: const ArrastreLateral(),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: children,
          ),
        ),
      );
    }

    // El aire entre pastillas ya lo pone cada una con su padding derecho, así
    // que acá sólo hace falta separar las filas.
    return Wrap(
      runSpacing: Esp.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
    );
  }
}

/// La empresa, como pastilla con menú. Ocupa lo que mide su nombre en vez de
/// una columna fija, que es lo que hacía el combo aunque la lista tuviera dos.
class _ChipEmpresa extends StatelessWidget {
  final int codEmpresa;
  final List<EmpresaEntity> empresas;
  final void Function(int) onElegir;

  const _ChipEmpresa({
    required this.codEmpresa,
    required this.empresas,
    required this.onElegir,
  });

  @override
  Widget build(BuildContext context) {
    final nombre = empresas
            .where((e) => e.codEmpresa == codEmpresa)
            .map((e) => e.nombre)
            .firstOrNull ??
        'Todas las empresas';

    return Padding(
      padding: EdgeInsets.only(right: Esp.xs),
      child: PopupMenuButton<int>(
        tooltip: 'Filtrar por empresa',
        position: PopupMenuPosition.under,
        onSelected: onElegir,
        itemBuilder: (_) => [
          const PopupMenuItem(value: 0, child: Text('Todas las empresas')),
          for (final e in empresas)
            PopupMenuItem(value: e.codEmpresa, child: Text(e.nombre)),
        ],
        child: Chip(
          avatar: const Icon(Icons.business_outlined, size: 16),
          // La flecha va adentro de la etiqueta y no en `deleteIcon`: ese sólo
          // se dibuja si hay `onDeleted`, y acá no se borra nada, se despliega.
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 170),
                child: Text(nombre, overflow: TextOverflow.ellipsis),
              ),
              const Icon(Icons.arrow_drop_down, size: 18),
            ],
          ),
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}

/// El calendario, cuando ninguno de los tres períodos sirve.
///
/// Un solo selector de rango en lugar de dos de fecha: elegir «desde» sin ver
/// el «hasta» era la forma más común de terminar con un rango invertido y la
/// grilla vacía.
class _ChipRangoPropio extends StatelessWidget {
  final CartasCiteState estado;
  final void Function(DateTime, DateTime) onElegir;

  const _ChipRangoPropio({required this.estado, required this.onElegir});

  @override
  Widget build(BuildContext context) {
    final esPropio =
        !RangoCite.values.any((r) => r.coincideCon(estado.fechaDesde, estado.fechaHasta));
    final fmt = DateFormat('dd/MM/yy');

    return Padding(
      padding: EdgeInsets.only(right: Esp.xs),
      child: ChoiceChip(
        avatar: const Icon(Icons.event_outlined, size: 16),
        label: Text(esPropio
            ? '${fmt.format(estado.fechaDesde)} a ${fmt.format(estado.fechaHasta)}'
            : 'Otro período'),
        selected: esPropio,
        visualDensity: VisualDensity.compact,
        onSelected: (_) async {
          final rango = await showDateRangePicker(
            context: context,
            firstDate: DateTime(2018),
            lastDate: DateTime.now().add(const Duration(days: 365)),
            initialDateRange: DateTimeRange(
              start: estado.fechaDesde,
              end: estado.fechaHasta,
            ),
            helpText: 'Período a consultar',
            saveText: 'Aplicar',
          );
          if (rango != null) onElegir(rango.start, rango.end);
        },
      ),
    );
  }
}

/// Un tipo de documento, con su ícono y su color.
///
/// Estaba escondido en un combo: había que abrirlo para saber qué tipos
/// existen. Acá los seis están a la vista y cada uno se pinta con el mismo
/// color que después va a tener en la grilla, así que filtrar y buscar usan la
/// misma señal.
class _ChipTipo extends StatelessWidget {
  final int idTipoDoc;
  final String etiqueta;
  final bool seleccionado;
  final VoidCallback onElegir;

  const _ChipTipo({
    required this.idTipoDoc,
    required this.etiqueta,
    required this.seleccionado,
    required this.onElegir,
  });

  @override
  Widget build(BuildContext context) {
    final id = identidadCite(idTipoDoc);
    final c = id.color(context.cs);

    return Padding(
      padding: EdgeInsets.only(right: Esp.xs),
      child: FilterChip(
        avatar: Icon(
          id.icono,
          size: 16,
          color: seleccionado ? c.texto : context.cs.onSurfaceVariant,
        ),
        label: Text(etiqueta),
        selected: seleccionado,
        showCheckmark: false,
        selectedColor: c.fondo,
        labelStyle: seleccionado
            ? TextStyle(color: c.texto, fontWeight: Peso.titulo)
            : null,
        visualDensity: VisualDensity.compact,
        onSelected: (_) => onElegir(),
      ),
    );
  }
}

class _SeparadorChips extends StatelessWidget {
  const _SeparadorChips();

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.symmetric(horizontal: Esp.s),
        child: Center(
          child: SizedBox(
            height: 20,
            child: VerticalDivider(
              width: 1,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════════════
// PAGINACIÓN
// ═══════════════════════════════════════════════════════════════════════════

class _Paginacion extends StatelessWidget {
  final CartasCiteState estado;
  final CartasCiteNotifier notifier;
  final Aire aire;

  const _Paginacion({
    required this.estado,
    required this.notifier,
    required this.aire,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // «137 documentos» no dice cuáles se están viendo. El rango sí, y es lo
    // que hace falta para saber si hay que pasar de página o volver.
    final desde = (estado.pagina - 1) * estado.tamanoPagina + 1;
    final hasta = (estado.pagina * estado.tamanoPagina) > estado.totalRegistros
        ? estado.totalRegistros
        : estado.pagina * estado.tamanoPagina;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: aire.esChico ? Esp.m : Esp.xl,
        vertical: Esp.s,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(children: [
                TextSpan(
                  text: '$desde-$hasta',
                  style: context.numero(fuerte: true),
                ),
                TextSpan(
                  text: aire.esChico
                      ? ' de ${estado.totalRegistros}'
                      : ' de ${estado.totalRegistros} documento'
                          '${estado.totalRegistros == 1 ? "" : "s"}',
                  style: context.apagado(),
                ),
              ]),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Página anterior',
            onPressed:
                estado.pagina > 1 ? () => notifier.irAPagina(estado.pagina - 1) : null,
          ),
          Text('${estado.pagina} / ${estado.totalPaginas}',
              style: context.numero(fuerte: true)),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Página siguiente',
            onPressed: estado.pagina < estado.totalPaginas
                ? () => notifier.irAPagina(estado.pagina + 1)
                : null,
          ),
        ],
      ),
    );
  }
}
