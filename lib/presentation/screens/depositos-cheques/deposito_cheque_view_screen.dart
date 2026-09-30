import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/core/utils/formatear_fecha.dart';
import 'package:bosque_flutter/core/utils/formato_moneda.dart';
import 'package:bosque_flutter/core/utils/pdf_service.dart';
import 'package:bosque_flutter/domain/entities/banco_cuenta_entity.dart';
import 'package:bosque_flutter/domain/entities/deposito_cheque_entity.dart';
import 'package:bosque_flutter/domain/entities/socio_negocio_entity.dart';
import 'package:bosque_flutter/presentation/widgets/shared/permission_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/state/depositos_cheques_provider.dart';
import 'lista_depositos.dart';

// autoDispose: cada visita empieza con estado fresco (sin lista ni filtros
// de la visita anterior). Se mantiene viva mientras la pantalla la observa.
final depositosChequesViewProvider = StateNotifierProvider.autoDispose<
  DepositosChequesNotifier,
  DepositosChequesState
>((ref) => DepositosChequesNotifier(ref));

class DepositoChequeViewScreen extends ConsumerStatefulWidget {
  const DepositoChequeViewScreen({super.key});

  @override
  ConsumerState<DepositoChequeViewScreen> createState() =>
      _DepositoChequeViewScreenState();
}

class _DepositoChequeViewScreenState
    extends ConsumerState<DepositoChequeViewScreen> {
  static final estadosDeposito = const [
    {'label': 'Todos', 'value': 'Todos'},
    {'label': 'Verificado', 'value': 'Verificado'},
    {'label': 'Pendiente', 'value': 'Pendiente'},
    {'label': 'Rechazado', 'value': 'Rechazado'},
  ];

  bool _yaBusco = false;
  bool _empresasPedidas = false;

  @override
  void initState() {
    super.initState();
    // Sin red en el constructor del notifier: las empresas se piden aquí. El
    // rango de 30 días evita que Buscar traiga todo el historial.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final notifier = ref.read(depositosChequesViewProvider.notifier);
      _empresasPedidas = true;
      notifier.cargarEmpresasSiFalta();
      notifier.aplicarRangoPorDefecto(dias: 30);
    });
  }

  void _buscar() {
    setState(() => _yaBusco = true);
    ref.read(depositosChequesViewProvider.notifier).buscarDepositos();
  }

  // Repite justo la carga que falló (empresas, bancos o clientes).
  void _reintentarFiltros() =>
      ref.read(depositosChequesViewProvider.notifier).reintentarUltimaCarga();

  // Tope de ancho del contenido: en pantallas muy grandes las filas dejan de
  // estirarse y se pierde el hilo entre un extremo y otro.
  static const double _anchoMaximo = 1680;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(depositosChequesViewProvider);
    final notifier = ref.read(depositosChequesViewProvider.notifier);

    // Fallo de empresas/bancos/clientes: se muestra junto a los filtros.
    final errorFiltros =
        (state.error != null &&
                state.errorEn != null &&
                state.errorEn != OperacionCarga.listado)
            ? state.error
            : null;

    // Se mide el ancho disponible y no el de la ventana: dentro del dashboard
    // el menú lateral se come su parte. Sin bloqueo global: los filtros y las
    // acciones por fila siguen usables mientras algo carga.
    return LayoutBuilder(
      builder: (context, constraints) {
        final ancho = constraints.maxWidth;
        final relleno =
            ancho >= 1000 ? Esp.xxl : (ancho >= 600 ? Esp.xl : Esp.l);
        return SingleChildScrollView(
          padding: EdgeInsets.all(relleno),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _anchoMaximo),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildEncabezado(context),
                  const SizedBox(height: Esp.xl),
                  _buildFiltros(context, state, notifier, errorFiltros),
                  const SizedBox(height: Esp.xl),
                  _buildResultsHeader(context, state),
                  // Barra de la búsqueda en curso; el alto queda reservado
                  // para que el contenido no salte al aparecer.
                  SizedBox(
                    height: 4,
                    child:
                        state.buscando ? const LinearProgressIndicator() : null,
                  ),
                  const SizedBox(height: Esp.s),
                  _DepositosTable(yaBusco: _yaBusco, onReintentar: _buscar),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEncabezado(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(Esquina.media),
          ),
          child: Padding(
            padding: const EdgeInsets.all(Esp.m),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              color: cs.onPrimaryContainer,
            ),
          ),
        ),
        const SizedBox(width: Esp.m),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Consulta de Depósitos',
                style: t.titleLarge?.copyWith(fontWeight: Peso.dato),
              ),
              Text(
                'Busque y visualice los depósitos registrados',
                style: t.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFiltros(
    BuildContext context,
    DepositosChequesState state,
    DepositosChequesNotifier notifier,
    Object? errorFiltros,
  ) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: contornoSuperficie(cs),
      child: Padding(
        padding: const EdgeInsets.all(Esp.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.tune, size: 20, color: cs.primary),
                const SizedBox(width: Esp.s),
                Text(
                  'Criterios de búsqueda',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(fontWeight: Peso.titulo),
                ),
              ],
            ),
            const SizedBox(height: Esp.l),
            LayoutBuilder(
              builder:
                  (context, c) =>
                      _buildCampos(context, c.maxWidth, state, notifier),
            ),
            if (errorFiltros != null) ...[
              const SizedBox(height: Esp.m),
              MensajeError(
                error: errorFiltros,
                compacto: true,
                onReintentar: _reintentarFiltros,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Los campos en una rejilla de 12 columnas: cada uno ocupa `span`. Con
  /// espacio amplio o medio van cuatro por fila; en tablet, dos; en móvil,
  /// uno (las fechas, de a dos).
  Widget _buildCampos(
    BuildContext context,
    double ancho,
    DepositosChequesState state,
    DepositosChequesNotifier notifier,
  ) {
    // Hacia abajo: la suma de una fila nunca pasa del ancho, así no salta de
    // línea por un error de redondeo.
    double de(int span) {
      final columna = (ancho - Esp.m * 11) / 12;
      return (columna * span + Esp.m * (span - 1)).floorToDouble();
    }

    final movil = ancho < 600;
    // Desde 680 (media pantalla de escritorio) van cuatro por fila y dos filas
    // en total: deja más lugar a los resultados.
    final (empresa, banco, fecha, cliente, estado, buscar) =
        ancho >= 1000
            ? (3, 3, 3, 5, 3, 4)
            : ancho >= 680
            ? (3, 3, 3, 3, 3, 6)
            : (ancho >= 600 ? (6, 6, 6, 6, 6, 12) : (12, 12, 6, 12, 12, 12));

    final botonBuscar = FilledButton.icon(
      style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
      onPressed: _buscar,
      icon: const Icon(Icons.search),
      label: const Text('Buscar/Actualizar'),
    );

    return Wrap(
      spacing: Esp.m,
      runSpacing: Esp.m,
      children: [
        SizedBox(
          width: de(empresa),
          child: _buildEmpresaDropdown(context, state, notifier),
        ),
        SizedBox(
          width: de(banco),
          child: _buildBancoDropdown(context, state, notifier),
        ),
        SizedBox(
          width: de(fecha),
          child: _DatePickerField(
            label: 'Desde',
            date: state.fechaDesde,
            onChanged: notifier.setFechaDesde,
          ),
        ),
        SizedBox(
          width: de(fecha),
          child: _DatePickerField(
            label: 'Hasta',
            date: state.fechaHasta,
            onChanged: notifier.setFechaHasta,
          ),
        ),
        SizedBox(
          width: de(cliente),
          child: _buildClienteDropdown(context, state, notifier),
        ),
        SizedBox(width: de(estado), child: _buildEstadoDropdown(state, notifier)),
        // Alto de un campo, para que el botón quede alineado con ellos.
        SizedBox(
          width: de(buscar),
          height: 56,
          child:
              movil
                  ? botonBuscar
                  : Align(alignment: Alignment.centerRight, child: botonBuscar),
        ),
      ],
    );
  }

  Widget _buildEstadoDropdown(
    DepositosChequesState state,
    DepositosChequesNotifier notifier,
  ) {
    return DropdownButtonFormField<String>(
      value: state.selectedEstado ?? 'Todos',
      decoration: const InputDecoration(labelText: 'Estado'),
      items: [
        for (final e in estadosDeposito)
          DropdownMenuItem<String>(value: e['value'], child: Text(e['label']!)),
      ],
      onChanged: notifier.setEstado,
      isExpanded: true,
    );
  }

  Widget _buildEmpresaDropdown(
    BuildContext context,
    DepositosChequesState state,
    DepositosChequesNotifier notifier,
  ) {
    // Si empresas aún no se ha cargado, mostrar un placeholder. Si falló, no
    // dejar «Cargando...» para siempre: el campo mismo permite reintentar
    // (el aviso de error se pierde si luego se hace otra búsqueda).
    if (state.empresas.isEmpty) {
      final fallo = _empresasPedidas && !state.cargandoEmpresas;
      return InkWell(
        onTap: fallo ? notifier.cargarEmpresas : null,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Empresa',
            suffixIcon: fallo ? const Icon(Icons.refresh) : null,
          ),
          child: Text(
            fallo ? 'No disponible. Toque para reintentar' : 'Cargando...',
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    // Usamos int (codEmpresa) como valor del dropdown en lugar del objeto completo
    int? currentValue = state.empresaSeleccionada?.codEmpresa;
    final dropdownKey =
        '${state.empresaSeleccionada?.codEmpresa ?? 0}_${state.empresas.length}';
    // Los items ya incluyen "Todos" desde el provider
    final empresaItems =
        state.empresas
            .map(
              (e) => DropdownMenuItem<int?>(
                value: e.codEmpresa,
                child: Text(
                  e.nombre,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            )
            .toList();
    // Si la empresa seleccionada no está en la lista, o es null, usar 0 ("Todos")
    if (state.empresaSeleccionada == null ||
        !state.empresas.any((e) => e.codEmpresa == currentValue)) {
      currentValue = 0;
    }
    return DropdownButtonFormField<int?>(
      key: ValueKey('empresa-dropdown-$dropdownKey'),
      value: currentValue,
      decoration: const InputDecoration(labelText: 'Empresa'),
      isExpanded: true,
      items: empresaItems,
      onChanged: (int? codEmpresa) {
        if (codEmpresa == null || codEmpresa == 0) {
          notifier.seleccionarEmpresa(null);
        } else {
          final empresa = state.empresas.firstWhere(
            (e) => e.codEmpresa == codEmpresa,
            orElse: () => state.empresas.first,
          );
          notifier.seleccionarEmpresa(empresa);
        }
      },
    );
  }

  Widget _buildBancoDropdown(
    BuildContext context,
    DepositosChequesState state,
    DepositosChequesNotifier notifier,
  ) {
    // Usamos int (idBxC) como valor del dropdown
    int? currentValue = state.bancoSeleccionado?.idBxC;

    return DropdownButtonFormField<int?>(
      key: ValueKey(
        'banco-dropdown-${state.empresaSeleccionada?.codEmpresa ?? 0}_${state.bancos.length}',
      ),
      value: currentValue,
      decoration: const InputDecoration(labelText: 'Banco'),

      isExpanded: true,
      items: [
        DropdownMenuItem<int?>(value: null, child: const Text('Todos')),
        ...state.bancos.map(
          (b) => DropdownMenuItem<int?>(
            value: b.idBxC,
            child: Text(
              b.nombreBanco,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ),
      ],
      onChanged: (int? idBxC) {
        if (idBxC == null) {
          notifier.seleccionarBanco(null);
        } else {
          // Encontrar el banco con ese ID
          final banco = state.bancos.firstWhere((b) => b.idBxC == idBxC);
          notifier.seleccionarBanco(banco);
        }
      },
    );
  }

  Widget _buildClienteDropdown(
    BuildContext context,
    DepositosChequesState state,
    DepositosChequesNotifier notifier,
  ) {
    final clienteSeleccionado = state.clienteSeleccionado;
    final nombre = clienteSeleccionado?.nombreCompleto ?? 'Todos';
    return InkWell(
      borderRadius: BorderRadius.circular(Esquina.chica),
      onTap: () async {
        // Sin empresa elegida (o con los clientes aún en camino) la lista está
        // vacía: no tiene sentido abrir el diálogo.
        if (state.clientes.isEmpty) {
          mostrarAviso(
            context,
            state.cargandoClientes
                ? 'Cargando clientes...'
                : 'Elija una empresa para filtrar por cliente.',
            tono: TonoAviso.aviso,
          );
          return;
        }
        final seleccionado = await showDialog<SocioNegocioEntity>(
          context: context,
          builder:
              (_) => _ClienteFiltroDialog(
                clientes: state.clientes,
                seleccionado: clienteSeleccionado,
              ),
        );
        if (seleccionado != null) {
          // Aquí el cliente es solo un filtro: las notas de remisión solo
          // sirven al registro, no hace falta pedirlas.
          notifier.seleccionarCliente(seleccionado, cargarNotas: false);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Cliente',
          suffixIcon:
              state.cargandoClientes
                  ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                  : const Icon(Icons.search),
        ),
        child: Text(
          nombre,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }

  Widget _buildResultsHeader(
    BuildContext context,
    DepositosChequesState state,
  ) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final total = state.totalRegistros;
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: Esp.m,
      runSpacing: Esp.s,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Resultados',
              style: t.titleMedium?.copyWith(fontWeight: Peso.titulo),
            ),
            const SizedBox(width: Esp.s),
            DecoratedBox(
              decoration: BoxDecoration(
                color: cs.secondaryContainer,
                borderRadius: BorderRadius.circular(Esquina.pastilla),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Esp.m,
                  vertical: Esp.xs,
                ),
                child: Text(
                  total == 1
                      ? '1 registro'
                      : '${FormatoMoneda.entero.format(total)} registros',
                  style: t.labelMedium?.copyWith(
                    fontWeight: Peso.titulo,
                    color: cs.onSecondaryContainer,
                  ),
                ),
              ),
            ),
          ],
        ),
        // Sin datos no hay qué exportar.
        OutlinedButton.icon(
          onPressed:
              state.depositos.isEmpty ? null : () => _exportarPdf(state),
          icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
          label: const Text('Exportar PDF'),
        ),
      ],
    );
  }

  void _exportarPdf(DepositosChequesState state) {
    final filtros = {
      'Empresa': state.empresaSeleccionada?.nombre ?? 'Todos',
      'Cliente': state.clienteSeleccionado?.nombreCompleto ?? 'Todos',
      'Banco': state.bancoSeleccionado?.nombreBanco ?? 'Todos',
      'Estado': state.selectedEstado ?? 'Todos',
      'Desde': state.fechaDesde,
      'Hasta': state.fechaHasta,
    };
    PdfService.generateAndViewDepositosPdf(
      context: context,
      title: 'Consulta de Depósitos',
      depositos: state.depositos,
      filtros: filtros,
    );
  }
}

/// Diálogo para elegir el cliente-filtro. Es un widget propio (y no un
/// `StatefulBuilder` con el controller creado fuera) para que el controller
/// del buscador se libere con el diálogo.
class _ClienteFiltroDialog extends StatefulWidget {
  const _ClienteFiltroDialog({
    required this.clientes,
    required this.seleccionado,
  });

  final List<SocioNegocioEntity> clientes;
  final SocioNegocioEntity? seleccionado;

  @override
  State<_ClienteFiltroDialog> createState() => _ClienteFiltroDialogState();
}

class _ClienteFiltroDialogState extends State<_ClienteFiltroDialog> {
  final TextEditingController _busqueda = TextEditingController();
  late List<SocioNegocioEntity> _filtrados = widget.clientes;

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  void _filtrar(String texto) {
    final q = texto.toLowerCase();
    setState(() {
      _filtrados =
          widget.clientes
              .where((c) => c.nombreCompleto.toLowerCase().contains(q))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final clientes = widget.clientes;
    return AlertDialog(
      title: const Text('Buscar cliente'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _busqueda,
              decoration: const InputDecoration(
                labelText: 'Buscar por nombre...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _filtrar,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _filtrados.length,
                itemBuilder: (context, index) {
                  final c = _filtrados[index];
                  return ListTile(
                    title: Text(c.nombreCompleto),
                    selected: widget.seleccionado?.codCliente == c.codCliente,
                    onTap: () => Navigator.of(context).pop(c),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        // `first` es la opción «Todos»; con la lista vacía no hay qué elegir.
        TextButton(
          onPressed:
              clientes.isEmpty
                  ? null
                  : () => Navigator.of(context).pop(clientes.first),
          child: const Text('Todos'),
        ),
      ],
    );
  }
}

class _DatePickerField extends StatefulWidget {
  final String label;
  final DateTime? date;
  final ValueChanged<DateTime?> onChanged;
  const _DatePickerField({
    required this.label,
    required this.date,
    required this.onChanged,
  });

  @override
  State<_DatePickerField> createState() => _DatePickerFieldState();
}

class _DatePickerFieldState extends State<_DatePickerField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _getDateText(widget.date));
  }

  @override
  void didUpdateWidget(covariant _DatePickerField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.date != widget.date) {
      _controller.text = _getDateText(widget.date);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getDateText(DateTime? date) =>
      date == null ? '' : FormatearFecha.formatearFecha(date);

  void _clearDate() {
    _controller.clear();
    widget.onChanged(null);
    FocusScope.of(context).unfocus();
  }

  Future<void> _elegir() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.date ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    // Puede haberse salido de la pantalla con el selector abierto.
    if (picked == null || !mounted) return;
    _controller.text = _getDateText(picked);
    widget.onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    // Un solo ícono a la derecha: con fecha, borrarla; sin fecha, el
    // calendario. Volver a elegir es tocar el campo.
    return TextFormField(
      readOnly: true,
      controller: _controller,
      decoration: InputDecoration(
        labelText: widget.label,
        suffixIcon:
            widget.date != null
                ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  tooltip: 'Borrar fecha',
                  onPressed: _clearDate,
                )
                : const Icon(Icons.calendar_month_outlined, size: 20),
      ),
      onTap: _elegir,
    );
  }
}

class _DepositosTable extends ConsumerStatefulWidget {
  const _DepositosTable({
    required this.yaBusco,
    required this.onReintentar,
  });

  /// La persona ya pidió una búsqueda (antes de eso no hay «sin resultados»).
  final bool yaBusco;

  /// El último fallo fue del listado y no de un filtro.
  final VoidCallback onReintentar;

  @override
  _DepositosTableState createState() => _DepositosTableState();
}

class _DepositosTableState extends ConsumerState<_DepositosTable> {
  // Depósitos cuyo diálogo de edición se está preparando (carga de bancos):
  // evita abrir dos diálogos con un doble clic.
  final Set<int> _editando = {};

  Widget _spinnerPequeno() => const SizedBox(
    width: 18,
    height: 18,
    child: CircularProgressIndicator(strokeWidth: 2),
  );

  Widget _emptyTablePlaceholder(DepositosChequesState state, Object? error) {
    final cs = Theme.of(context).colorScheme;
    final Widget contenido;
    if (state.buscando) {
      // Buscando y aún sin datos: un esqueleto del alto de unas filas reserva
      // el lugar y la página no salta cuando llegan.
      contenido = const SizedBox(
        height: 312,
        child: EsqueletoLista(filas: 4, altoFila: 64),
      );
    } else if (error != null) {
      // Un fallo del listado no se disfraza de «sin depósitos».
      contenido = SizedBox(
        height: 280,
        child: MensajeError(error: error, onReintentar: widget.onReintentar),
      );
    } else {
      contenido = Padding(
        padding: const EdgeInsets.symmetric(
          vertical: Esp.xxl,
          horizontal: Esp.l,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.yaBusco ? Icons.search_off : Icons.manage_search,
              size: 48,
              color: cs.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            const SizedBox(height: Esp.s),
            Text(
              widget.yaBusco
                  ? 'No se encontraron depósitos'
                  : 'Use los filtros y pulse «Buscar/Actualizar» para consultar depósitos.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: Peso.titulo,
                color: cs.onSurfaceVariant,
              ),
            ),
            if (widget.yaBusco) ...[
              const SizedBox(height: Esp.xs),
              Text(
                'Pruebe con otro rango de fechas o quite algún filtro.',
                textAlign: TextAlign.center,
                style: context.apagado(),
              ),
            ],
          ],
        ),
      );
    }
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: contornoSuperficie(cs),
      child: contenido,
    );
  }

  /// Abre el diálogo de edición: primero los bancos de la empresa del depósito
  /// (con caché en el notifier), con guarda contra doble clic.
  Future<void> _editarDeposito(DepositoChequeEntity d) async {
    if (!_editando.add(d.idDeposito)) return;
    setState(() {});
    final notifier = ref.read(depositosChequesViewProvider.notifier);
    final List<BancoXCuentaEntity> bancos;
    try {
      bancos = await notifier.bancosDeEmpresa(d.codEmpresa);
    } catch (e) {
      if (mounted) {
        mostrarAviso(
          context,
          'No se pudieron cargar los bancos: ${textoParaUsuario(e)}',
          tono: TonoAviso.error,
        );
      }
      return;
    } finally {
      _editando.remove(d.idDeposito);
      if (mounted) setState(() {});
    }
    if (!mounted) return;

    if (bancos.isEmpty) {
      mostrarAviso(
        context,
        'No hay bancos disponibles para esta empresa',
        tono: TonoAviso.aviso,
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder:
          (_) => _EditarDepositoDialog(
            deposito: d,
            bancos: bancos,
            onGuardar:
                (nroTransaccion, banco) =>
                    notifier.actualizarDepositoTransaccionYBanco(
                      deposito: d,
                      nuevoNroTransaccion: nroTransaccion,
                      nuevoBanco: banco,
                      context: context,
                    ),
          ),
    );
  }

  Future<void> _rechazarDeposito(DepositoChequeEntity d) async {
    // Mostrar diálogo de confirmación
    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Confirmar rechazo'),
            content: const Text(
              '¿Está seguro que desea rechazar este depósito?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(dialogContext).colorScheme.error,
                  foregroundColor: Theme.of(dialogContext).colorScheme.onError,
                ),
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Rechazar'),
              ),
            ],
          ),
    );

    // Si el usuario confirma, rechazar el depósito. El notifier marca la fila
    // como ocupada y avisa el resultado.
    if (confirmar != true || !mounted) return;
    await ref
        .read(depositosChequesViewProvider.notifier)
        .rechazarDepositoCheque(deposito: d, context: context);
  }

  /// Acciones de una fila. Cada botón se deshabilita y muestra su spinner
  /// mientras su operación corre; ya no hay bloqueo global de la pantalla. El
  /// color queda para lo que advierte: solo «Rechazar» lo lleva.
  Widget _accionesFila(
    DepositoChequeEntity d,
    DepositosChequesState state,
    ColorScheme colorScheme, {
    required bool compacto,
  }) {
    final notifier = ref.read(depositosChequesViewProvider.notifier);
    final id = d.idDeposito;
    // Editar y rechazar comparten la marca por fila del notifier; `_editando`
    // cubre además la carga de bancos previa al diálogo.
    final filaOcupada =
        state.filasOcupadas.contains(id) || _editando.contains(id);

    Widget boton({
      required IconData icono,
      required String tooltip,
      required bool ocupado,
      required VoidCallback accion,
      Color? color,
    }) => IconButton(
      visualDensity: compacto ? VisualDensity.compact : VisualDensity.standard,
      icon:
          ocupado
              ? _spinnerPequeno()
              : Icon(icono, size: 20, color: color ?? colorScheme.onSurfaceVariant),
      tooltip: tooltip,
      onPressed: ocupado ? null : accion,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        boton(
          icono: Icons.image_outlined,
          tooltip: 'Ver imagen',
          ocupado: state.imagenesEnCurso.contains(id),
          accion: () => notifier.descargarImagenDeposito(id, context),
        ),
        boton(
          icono: Icons.description_outlined,
          tooltip: 'Ver documento',
          ocupado: state.pdfsEnCurso.contains(id),
          accion: () => notifier.descargarPdfDeposito(id, context),
        ),
        PermissionWidget(
          buttonName: 'btnNroTransac',
          child: boton(
            icono: Icons.edit_outlined,
            tooltip: 'Editar',
            ocupado: filaOcupada,
            accion: () => _editarDeposito(d),
          ),
        ),
        boton(
          icono: Icons.close,
          tooltip: 'Rechazar',
          ocupado: filaOcupada,
          accion: () => _rechazarDeposito(d),
          color: colorScheme.error,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(depositosChequesViewProvider);
    final notifier = ref.read(depositosChequesViewProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;
    final page = state.page;
    final rowsPerPage = state.rowsPerPage;
    final total = state.totalRegistros;
    final paged =
        state.depositos.skip(page * rowsPerPage).take(rowsPerPage).toList();
    // Fallo del listado (no de un filtro), ya sin búsqueda en curso.
    final errorBusqueda =
        (state.error != null && state.errorEn == OperacionCarga.listado)
            ? state.error
            : null;

    final paginacion = PaginacionDepositos(
      pagina: page,
      filasPorPagina: rowsPerPage,
      total: total,
      onPagina: notifier.setPage,
      onFilasPorPagina: notifier.setRowsPerPage,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Con datos previos, el fallo se avisa sin ocultarlos.
        if (errorBusqueda != null && paged.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: Esp.s),
            child: MensajeError(
              error: errorBusqueda,
              compacto: true,
              onReintentar: widget.onReintentar,
            ),
          ),
        if (paged.isEmpty) ...[
          _emptyTablePlaceholder(state, errorBusqueda),
          // Página fuera de rango con datos: hay que poder volver.
          if (total > 0) ...[const SizedBox(height: Esp.s), paginacion],
        ] else
          ListaDepositos(
            depositos: paged,
            acciones:
                (d, {required compacto}) =>
                    _accionesFila(d, state, colorScheme, compacto: compacto),
            pie: paginacion,
          ),
      ],
    );
  }
}

/// Diálogo de edición de nro. de transacción y banco. Es un widget propio para
/// que el controller y el estado «guardando» vivan (y se liberen) con el
/// diálogo.
class _EditarDepositoDialog extends StatefulWidget {
  const _EditarDepositoDialog({
    required this.deposito,
    required this.bancos,
    required this.onGuardar,
  });

  final DepositoChequeEntity deposito;
  final List<BancoXCuentaEntity> bancos;

  /// Devuelve `true` si el cambio se aplicó (entonces el diálogo se cierra).
  final Future<bool> Function(String nroTransaccion, BancoXCuentaEntity banco)
  onGuardar;

  @override
  State<_EditarDepositoDialog> createState() => _EditarDepositoDialogState();
}

class _EditarDepositoDialogState extends State<_EditarDepositoDialog> {
  late final TextEditingController _nroController = TextEditingController(
    text: widget.deposito.nroTransaccion,
  );
  late BancoXCuentaEntity? _banco = _bancoInicial();
  bool _guardando = false;

  // El banco actual del depósito; si ya no está en la lista, el primero.
  BancoXCuentaEntity? _bancoInicial() {
    for (final b in widget.bancos) {
      if (b.idBxC == widget.deposito.idBxC) return b;
    }
    return widget.bancos.isNotEmpty ? widget.bancos.first : null;
  }

  @override
  void dispose() {
    _nroController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final banco = _banco;
    if (banco == null) {
      mostrarAviso(context, 'Debe seleccionar un banco', tono: TonoAviso.aviso);
      return;
    }
    setState(() => _guardando = true);
    final ok = await widget.onGuardar(_nroController.text.trim(), banco);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      // El notifier ya avisó el motivo; el diálogo queda abierto.
      setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Mientras guarda no se puede cerrar (ni con el fondo ni con Cancelar):
    // el resultado se decide con el `bool` de la operación.
    return PopScope(
      canPop: !_guardando,
      child: AlertDialog(
        title: const Text('Editar depósito'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Nro. Transacción',
                border: OutlineInputBorder(),
              ),
              controller: _nroController,
              enabled: !_guardando,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<BancoXCuentaEntity>(
              decoration: const InputDecoration(
                labelText: 'Banco',
                border: OutlineInputBorder(),
              ),
              value: _banco,
              isExpanded: true,
              items:
                  widget.bancos
                      .map(
                        (banco) => DropdownMenuItem(
                          value: banco,
                          child: Text(banco.nombreBanco),
                        ),
                      )
                      .toList(),
              onChanged:
                  _guardando ? null : (value) => setState(() => _banco = value),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _guardando ? null : () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
            onPressed: _guardando ? null : _guardar,
            child:
                _guardando
                    ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
