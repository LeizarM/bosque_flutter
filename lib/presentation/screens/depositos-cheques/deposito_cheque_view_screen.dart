import 'package:bosque_flutter/core/utils/pdf_service.dart';
import 'package:bosque_flutter/domain/entities/banco_cuenta_entity.dart';
import 'package:bosque_flutter/presentation/widgets/shared/permission_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/state/depositos_cheques_provider.dart';
import '../../../core/utils/responsive_utils_bosque.dart';

class DepositoChequeViewScreen extends ConsumerWidget {
  const DepositoChequeViewScreen({super.key});

  static final estadosDeposito = const [
    {'label': 'Todos', 'value': 'Todos'},
    {'label': 'Verificado', 'value': 'Verificado'},
    {'label': 'Pendiente', 'value': 'Pendiente'},
    {'label': 'Rechazado', 'value': 'Rechazado'},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(depositosChequesProvider);
    final notifier = ref.read(depositosChequesProvider.notifier);

    // Valores responsive
    final isDesktop = ResponsiveUtilsBosque.isDesktop(context); // Used below
    final isTablet = ResponsiveUtilsBosque.isTablet(context);
    final isMobile = ResponsiveUtilsBosque.isMobile(context);

    return Stack(
      children: [
        Opacity(
          opacity: state.cargando ? 0.5 : 1.0,
          child: IgnorePointer(
            ignoring: state.cargando,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isDesktop ? 32 : (isMobile ? 16 : 24)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Encabezado
                  Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        size: isDesktop ? 32 : 28,
                        color: Colors.black54,
                      ),
                      SizedBox(width: isDesktop ? 12 : 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Consulta de Depósitos',
                              style: TextStyle(
                                fontSize: isDesktop ? 22 : (isMobile ? 18 : 20),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Busque y visualice los depósitos registrados',
                              style: TextStyle(
                                fontSize: isDesktop ? 15 : (isMobile ? 13 : 14),
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isDesktop ? 24 : 16),
                  Divider(),
                  SizedBox(height: isDesktop ? 12 : 8),

                  // Criterios de búsqueda
                  Text(
                    'Criterios de Búsqueda',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: isDesktop ? 16 : 14,
                    ),
                  ),
                  SizedBox(height: isDesktop ? 16 : 12),

                  // Primera fila de filtros (o columna en móvil)
                  if (isDesktop || isTablet)
                    _buildDesktopFiltersRow1(context, state, notifier)
                  else
                    _buildMobileFilters1(context, state, notifier),

                  SizedBox(height: isDesktop ? 16 : 12),

                  // Segunda fila de filtros (o columna en móvil)
                  if (isDesktop || isTablet)
                    _buildDesktopFiltersRow2(context, state, notifier)
                  else
                    _buildMobileFilters2(context, state, notifier),

                  SizedBox(height: isDesktop ? 32 : 24),

                  // Resultados
                  _buildResultsHeader(context, state),

                  SizedBox(height: isDesktop ? 12 : 8),

                  // Tabla
                  _DepositosTable(),
                ],
              ),
            ),
          ),
        ),
        if (state.cargando)
          Positioned.fill(child: Center(child: CircularProgressIndicator())),
      ],
    );
  }

  // Métodos para construir la UI según el tipo de dispositivo

  Widget _buildDesktopFiltersRow1(
    BuildContext context,
    DepositosChequesState state,
    DepositosChequesNotifier notifier,
  ) {
    return Row(
      children: [
        // Empresa - Usamos IDs en lugar de objetos
        Expanded(child: _buildEmpresaDropdown(context, state, notifier)),
        const SizedBox(width: 16),
        // Banco
        Expanded(child: _buildBancoDropdown(context, state, notifier)),
        const SizedBox(width: 16),
        // Desde
        Expanded(
          child: _DatePickerField(
            label: 'Desde',
            date: state.fechaDesde,
            onChanged: notifier.setFechaDesde,
          ),
        ),
        const SizedBox(width: 16),
        // Hasta
        Expanded(
          child: _DatePickerField(
            label: 'Hasta',
            date: state.fechaHasta,
            onChanged: notifier.setFechaHasta,
          ),
        ),
      ],
    );
  }

  Widget _buildEmpresaDropdown(
    BuildContext context,
    DepositosChequesState state,
    DepositosChequesNotifier notifier,
  ) {
    // Si empresas aún no se ha cargado, mostrar un placeholder
    if (state.empresas.isEmpty) {
      return InputDecorator(
        decoration: const InputDecoration(labelText: 'Empresa'),
        child: const Text('Cargando...', style: TextStyle(color: Colors.grey)),
      );
    }

    // Usamos int (codEmpresa) como valor del dropdown en lugar del objeto completo
    int? currentValue = state.empresaSeleccionada?.codEmpresa;
    final dropdownKey =
        '${state.empresaSeleccionada?.codEmpresa ?? 0}_${state.empresas.length}_${state.clientes.length}_${state.bancos.length}_${state.selectedEstado}';
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

  Widget _buildMobileFilters1(
    BuildContext context,
    DepositosChequesState state,
    DepositosChequesNotifier notifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Empresa
        _buildEmpresaDropdown(context, state, notifier),
        const SizedBox(height: 12),
        // Banco
        _buildBancoDropdown(context, state, notifier),
        const SizedBox(height: 12),
        // Desde y Hasta en una fila
        Row(
          children: [
            Expanded(
              child: _DatePickerField(
                label: 'Desde',
                date: state.fechaDesde,
                onChanged: notifier.setFechaDesde,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DatePickerField(
                label: 'Hasta',
                date: state.fechaHasta,
                onChanged: notifier.setFechaHasta,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopFiltersRow2(
    BuildContext context,
    DepositosChequesState state,
    DepositosChequesNotifier notifier,
  ) {
    return Row(
      children: [
        // Cliente
        Expanded(
          flex: 2,
          child: _buildClienteDropdown(context, state, notifier),
        ),
        const SizedBox(width: 16),
        // Estado
        Expanded(
          child: DropdownButtonFormField<String>(
            value: state.selectedEstado ?? 'Todos',
            decoration: const InputDecoration(labelText: 'Estado'),
            items:
                estadosDeposito
                    .map(
                      (e) => DropdownMenuItem<String>(
                        value: e['value'],
                        child: Text(e['label']!),
                      ),
                    )
                    .toList(),
            onChanged: notifier.setEstado,
            isExpanded: true,
          ),
        ),
        const SizedBox(width: 16),
        // Botón Buscar
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6C63FF),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          ),
          onPressed: notifier.buscarDepositos,
          icon: const Icon(Icons.search, color: Colors.white),
          label: const Text(
            'Buscar/Actualizar',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildClienteDropdown(
    BuildContext context,
    DepositosChequesState state,
    DepositosChequesNotifier notifier,
  ) {
    final clienteSeleccionado = state.clienteSeleccionado;
    return GestureDetector(
      onTap: () async {
        final seleccionado = await _showClienteSearchDialog(context, state.clientes, clienteSeleccionado);
        if (seleccionado != null) {
          notifier.seleccionarCliente(seleccionado);
        }
      },
      child: AbsorbPointer(
        child: TextFormField(
          decoration: const InputDecoration(
            labelText: 'Cliente',
            suffixIcon: Icon(Icons.search),
          ),
          controller: TextEditingController(
            text: clienteSeleccionado?.nombreCompleto ?? 'Todos',
          ),
          readOnly: true,
        ),
      ),
    );
  }

  Future<dynamic> _showClienteSearchDialog(BuildContext context, List<dynamic> clientes, dynamic clienteSeleccionado) async {
    TextEditingController searchController = TextEditingController();
    List<dynamic> filtered = List.from(clientes);
    return await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Buscar cliente'),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        labelText: 'Buscar por nombre...',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        setState(() {
                          filtered = clientes.where((c) => (c.nombreCompleto ?? '').toLowerCase().contains(value.toLowerCase())).toList();
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final c = filtered[index];
                          return ListTile(
                            title: Text(c.nombreCompleto ?? ''),
                            selected: clienteSeleccionado?.codCliente == c.codCliente,
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
                TextButton(
                  onPressed: () => Navigator.of(context).pop(clientes.first),
                  child: const Text('Todos'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMobileFilters2(
    BuildContext context,
    DepositosChequesState state,
    DepositosChequesNotifier notifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Cliente
        _buildClienteDropdown(context, state, notifier),
        const SizedBox(height: 12),
        // Estado
        DropdownButtonFormField<String>(
          value: state.selectedEstado ?? 'Todos',
          decoration: const InputDecoration(labelText: 'Estado'),
          items:
              estadosDeposito
                  .map(
                    (e) => DropdownMenuItem<String>(
                      value: e['value'],
                      child: Text(e['label']!),
                    ),
                  )
                  .toList(),
          onChanged: notifier.setEstado,
          isExpanded: true,
        ),
        const SizedBox(height: 16),
        // Botón Buscar
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6C63FF),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          onPressed: notifier.buscarDepositos,
          icon: const Icon(Icons.search, color: Colors.white),
          label: const Text(
            'Buscar/Actualizar',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildResultsHeader(
    BuildContext context,
    DepositosChequesState state,
  ) {
    final isDesktop = ResponsiveUtilsBosque.isDesktop(context);
    final isMobile = ResponsiveUtilsBosque.isMobile(context);

    if (isDesktop) {
      return Row(
        children: [
          Text(
            'Resultados',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const Spacer(),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF6C63FF),
              side: const BorderSide(color: Color(0xFF6C63FF)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            ),
            onPressed:
                state.depositos.isEmpty
                    ? null // Deshabilitar si no hay datos
                    : () {
                      // Crear mapa de filtros aplicados
                      final filtros = {
                        'Empresa': state.empresaSeleccionada?.nombre ?? 'Todos',
                        'Cliente':
                            state.clienteSeleccionado?.nombreCompleto ??
                            'Todos',
                        'Banco':
                            state.bancoSeleccionado?.nombreBanco ?? 'Todos',
                        'Estado': state.selectedEstado ?? 'Todos',
                        'Desde': state.fechaDesde,
                        'Hasta': state.fechaHasta,
                      };

                      // Llamar al servicio PDF
                      PdfService.generateAndViewDepositosPdf(
                        context: context,
                        title: 'Consulta de Depósitos',
                        depositos: state.depositos,
                        filtros: filtros,
                      );
                    },
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Exportar PDF'),
          ),
          const SizedBox(width: 16),
          Text(
            '${state.totalRegistros} registros encontrados',
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      );
    } else {
      // Similar para móvil
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Resultados',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: isMobile ? 14 : 16,
                ),
              ),
              const Spacer(),
              Text(
                '${state.totalRegistros} registros',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: isMobile ? 13 : 14,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF6C63FF),
                side: const BorderSide(color: Color(0xFF6C63FF)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              onPressed:
                  state.depositos.isEmpty
                      ? null // Deshabilitar si no hay datos
                      : () {
                        // Crear mapa de filtros aplicados
                        final filtros = {
                          'Empresa':
                              state.empresaSeleccionada?.nombre ?? 'Todos',
                          'Cliente':
                              state.clienteSeleccionado?.nombreCompleto ??
                              'Todos',
                          'Banco':
                              state.bancoSeleccionado?.nombreBanco ?? 'Todos',
                          'Estado': state.selectedEstado ?? 'Todos',
                          'Desde': state.fechaDesde,
                          'Hasta': state.fechaHasta,
                        };

                        // Llamar al servicio PDF
                        PdfService.generateAndViewDepositosPdf(
                          context: context,
                          title: 'Consulta de Depósitos',
                          depositos: state.depositos,
                          filtros: filtros,
                        );
                      },
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
              label: const Text('Exportar PDF'),
            ),
          ),
        ],
      );
    }
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

  String _getDateText(DateTime? date) {
    if (date == null) return '';
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  void _clearDate() {
    _controller.clear();
    widget.onChanged(null);
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtilsBosque.isMobile(context);

    return TextFormField(
      readOnly: true,
      controller: _controller,
      style: TextStyle(fontSize: isMobile ? 13 : null),
      decoration: InputDecoration(
        labelText: widget.label,
        labelStyle: TextStyle(fontSize: isMobile ? 13 : null),
        contentPadding: EdgeInsets.symmetric(
          vertical: isMobile ? 10 : 12,
          horizontal: isMobile ? 10 : 12,
        ),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.date != null)
              IconButton(
                icon: Icon(
                  Icons.clear,
                  color: Colors.redAccent,
                  size: isMobile ? 18 : 20,
                ),
                tooltip: 'Borrar fecha',
                onPressed: _clearDate,
                padding: EdgeInsets.all(isMobile ? 4 : 8),
                constraints: BoxConstraints(),
              ),
            IconButton(
              icon: Icon(
                Icons.calendar_month,
                color: Color(0xFF6C63FF),
                size: isMobile ? 18 : 20,
              ),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: widget.date ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                  builder: (context, child) {
                    // Hacemos el DatePicker responsive
                    return Theme(
                      data: Theme.of(context).copyWith(
                        dialogTheme: DialogTheme(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  _controller.text = _getDateText(picked);
                  widget.onChanged(picked);
                }
              },
              padding: EdgeInsets.all(isMobile ? 4 : 8),
              constraints: BoxConstraints(),
            ),
          ],
        ),
      ),
      onTap: () async {
        // Si ya hay una fecha, mostrar el date picker
        final picked = await showDatePicker(
          context: context,
          initialDate: widget.date ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          builder: (context, child) {
            // Hacemos el DatePicker responsive
            return Theme(
              data: Theme.of(context).copyWith(
                dialogTheme: DialogTheme(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          _controller.text = _getDateText(picked);
          widget.onChanged(picked);
        }
      },
    );
  }
}

class _DepositosTable extends ConsumerStatefulWidget {
  @override
  _DepositosTableState createState() => _DepositosTableState();
}

class _DepositosTableState extends ConsumerState<_DepositosTable> {
  late ScrollController horizontalController;

  @override
  void initState() {
    super.initState();
    horizontalController = ScrollController();
    
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = ref.read(depositosChequesProvider.notifier);
      // Solo limpiar si hay datos
      if (ref.read(depositosChequesProvider).depositos.isNotEmpty) {
        provider.clearState();
      }
    });
  }

  @override
  void dispose() {
    horizontalController.dispose();
    super.dispose();
  }

  Widget _emptyTablePlaceholder() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.search_off, size: 48, color: Colors.black26),
          SizedBox(height: 8),
          Text(
            'No se encontraron depósitos',
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(depositosChequesProvider);
    final columns = const [
      'ID',
      'Cliente',
      'Banco',
      'Empresa',
      'Importe',
      'Moneda',
      'Fecha Ingreso',
      'Num. Transaccion',
      'Estado',
      'Acciones',
    ];
    final page = state.page;
    final rowsPerPage = state.rowsPerPage;
    final depositos = state.depositos;
    final total = state.totalRegistros;
    final start = total == 0 ? 0 : (page * rowsPerPage) + 1;
    final end = ((page + 1) * rowsPerPage).clamp(0, total);
    final paged = depositos.skip(page * rowsPerPage).take(rowsPerPage).toList();

    // Valores responsive
    final isDesktop = ResponsiveUtilsBosque.isDesktop(context);
    final isMobile = ResponsiveUtilsBosque.isMobile(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tabla con scroll horizontal y vertical
          if (paged.isEmpty)
            _emptyTablePlaceholder()
          else
            SizedBox(
              height: isDesktop ? 400 : (isMobile ? 350 : 380),
              child: RawScrollbar(
                thumbVisibility: true,
                controller: horizontalController,
                thickness: isDesktop ? 8 : 6,
                radius: const Radius.circular(5),
                thumbColor: Colors.grey.shade400,
                child: SingleChildScrollView(
                  controller: horizontalController,
                  scrollDirection: Axis.horizontal,
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: MediaQuery.of(context).size.width,
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: DataTable(
                        columnSpacing: isDesktop ? 20 : (isMobile ? 12 : 16),
                        horizontalMargin: isDesktop ? 20 : (isMobile ? 12 : 16),
                        headingRowHeight: isDesktop ? 50 : 45,
                        // ignore: deprecated_member_use
                        dataRowHeight: isDesktop ? 60 : 55,
                        dividerThickness: 1,
                        columns:
                            columns
                                .map(
                                  (col) => DataColumn(
                                    label: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isDesktop ? 8.0 : 4.0,
                                      ),
                                      child: Text(
                                        col,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize:
                                              isDesktop
                                                  ? 14
                                                  : (isMobile ? 12 : 13),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                        rows:
                            paged
                                .map(
                                  (d) => DataRow(
                                    cells: [
                                      DataCell(
                                        Text(
                                          d.idDeposito.toString(),
                                          style: TextStyle(
                                            fontSize: isMobile ? 12 : null,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          d.codCliente,
                                          style: TextStyle(
                                            fontSize: isMobile ? 12 : null,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          d.nombreBanco,
                                          style: TextStyle(
                                            fontSize: isMobile ? 12 : null,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          d.nombreEmpresa,
                                          style: TextStyle(
                                            fontSize: isMobile ? 12 : null,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          d.importe.toStringAsFixed(2),
                                          style: TextStyle(
                                            fontSize: isMobile ? 12 : null,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          d.moneda,
                                          style: TextStyle(
                                            fontSize: isMobile ? 12 : null,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          d.fechaI != null
                                              ? "${d.fechaI!.day.toString().padLeft(2, '0')}/${d.fechaI!.month.toString().padLeft(2, '0')}/${d.fechaI!.year}"
                                              : '',
                                          style: TextStyle(
                                            fontSize: isMobile ? 12 : null,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          d.nroTransaccion,
                                          style: TextStyle(
                                            fontSize: isMobile ? 12 : null,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          d.esPendiente,
                                          style: TextStyle(
                                            fontSize: isMobile ? 12 : null,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Container(
                                          constraints: const BoxConstraints(
                                            minWidth: 160,
                                          ),
                                          child:
                                              d.esPendiente == "Rechazado"
                                                  ? Text(
                                                    "No disponible",
                                                    style: TextStyle(
                                                      fontStyle:
                                                          FontStyle.italic,
                                                      color: Colors.grey,
                                                      fontSize:
                                                          isMobile ? 12 : null,
                                                    ),
                                                  )
                                                  : Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      IconButton(
                                                        icon: Icon(
                                                          Icons.image,
                                                          color: Colors.indigo,
                                                          size: 20,
                                                        ),
                                                        tooltip: 'Ver imagen',
                                                        onPressed: () {
                                                          try {
                                                            ref
                                                                .read(
                                                                  depositosChequesProvider
                                                                      .notifier,
                                                                )
                                                                .descargarImagenDeposito(
                                                                  d.idDeposito,
                                                                  context,
                                                                );
                                                          } catch (e) {
                                                            ScaffoldMessenger.of(
                                                              context,
                                                            ).showSnackBar(
                                                              SnackBar(
                                                                content: Text(
                                                                  'Error al descargar imagen: $e',
                                                                ),
                                                              ),
                                                            );
                                                          }
                                                        },
                                                      ),
                                                      IconButton(
                                                        icon: Icon(
                                                          Icons.description,
                                                          color: Colors.blue,
                                                          size: 20,
                                                        ),
                                                        tooltip:
                                                            'Ver documento',
                                                        onPressed: () {
                                                          try {
                                                            // Llamar al método que descarga el PDF específico
                                                            ref
                                                                .read(
                                                                  depositosChequesProvider
                                                                      .notifier,
                                                                )
                                                                .descargarPdfDeposito(
                                                                  d.idDeposito,
                                                                  context,
                                                                );
                                                          } catch (e) {
                                                            // Mostrar un mensaje de error
                                                            ScaffoldMessenger.of(
                                                              context,
                                                            ).showSnackBar(
                                                              SnackBar(
                                                                content: Text(
                                                                  'Error al descargar el PDF: $e',
                                                                ),
                                                              ),
                                                            );
                                                          }
                                                        },
                                                      ),

                                                      PermissionWidget(
                                                        buttonName:
                                                            'btnNroTransac',
                                                        child: IconButton(
                                                          icon: Icon(
                                                            Icons.edit,
                                                            color:
                                                                Colors
                                                                    .deepPurple,
                                                            size: 20,
                                                          ),
                                                          tooltip: 'Editar',
                                                          onPressed: () async {
                                                            final notifier = ref
                                                                .read(
                                                                  depositosChequesProvider
                                                                      .notifier,
                                                                );
                                                            // Cargar bancos para la empresa del depósito seleccionado
                                                            final bancos =
                                                                await notifier
                                                                    .repo
                                                                    .getBancos(
                                                                      d.codEmpresa,
                                                                    );

                                                            // Valor inicial para el dropdown
                                                            BancoXCuentaEntity?
                                                            bancoSeleccionado;
                                                            try {
                                                              bancoSeleccionado =
                                                                  bancos.firstWhere(
                                                                    (b) =>
                                                                        b.idBxC ==
                                                                        d.idBxC,
                                                                  );
                                                            } catch (e) {
                                                              bancoSeleccionado =
                                                                  bancos.isNotEmpty
                                                                      ? bancos
                                                                          .first
                                                                      : null;
                                                            }

                                                            if (bancos
                                                                .isEmpty) {
                                                              ScaffoldMessenger.of(
                                                                context,
                                                              ).showSnackBar(
                                                                SnackBar(
                                                                  content: Text(
                                                                    'No hay bancos disponibles para esta empresa',
                                                                  ),
                                                                  backgroundColor:
                                                                      Colors
                                                                          .orange,
                                                                ),
                                                              );
                                                              return;
                                                            }

                                                            // Mostrar diálogo para editar
                                                            await showDialog(
                                                              context: context,
                                                              builder: (
                                                                dialogContext,
                                                              ) {
                                                                // Controlador para el campo de texto
                                                                final controller =
                                                                    TextEditingController(
                                                                      text:
                                                                          d.nroTransaccion,
                                                                    );

                                                                // Variable local para el banco seleccionado en el diálogo
                                                                BancoXCuentaEntity?
                                                                localBancoSeleccionado =
                                                                    bancoSeleccionado;

                                                                // Usamos StatefulBuilder para manejar estado local del diálogo
                                                                return StatefulBuilder(
                                                                  builder: (
                                                                    context,
                                                                    setState,
                                                                  ) {
                                                                    return AlertDialog(
                                                                      title: Text(
                                                                        'Editar depósito',
                                                                      ),
                                                                      content: Column(
                                                                        mainAxisSize:
                                                                            MainAxisSize.min,
                                                                        children: [
                                                                          TextField(
                                                                            decoration: InputDecoration(
                                                                              labelText:
                                                                                  'Nro. Transacción',
                                                                              border:
                                                                                  OutlineInputBorder(),
                                                                            ),
                                                                            controller:
                                                                                controller,
                                                                          ),
                                                                          SizedBox(
                                                                            height:
                                                                                16,
                                                                          ),
                                                                          DropdownButtonFormField<
                                                                            BancoXCuentaEntity
                                                                          >(
                                                                            decoration: InputDecoration(
                                                                              labelText:
                                                                                  'Banco',
                                                                              border:
                                                                                  OutlineInputBorder(),
                                                                            ),
                                                                            value:
                                                                                localBancoSeleccionado,
                                                                            isExpanded:
                                                                                true,
                                                                            items:
                                                                                bancos.map((
                                                                                  banco,
                                                                                ) {
                                                                                  return DropdownMenuItem(
                                                                                    value:
                                                                                        banco,
                                                                                    child: Text(
                                                                                      banco.nombreBanco,
                                                                                    ),
                                                                                  );
                                                                                }).toList(),
                                                                            onChanged: (
                                                                              value,
                                                                            ) {
                                                                              setState(
                                                                                () =>
                                                                                    localBancoSeleccionado =
                                                                                        value,
                                                                              );
                                                                            },
                                                                          ),
                                                                        ],
                                                                      ),
                                                                      actions: [
                                                                        TextButton(
                                                                          onPressed:
                                                                              () => Navigator.pop(
                                                                                dialogContext,
                                                                              ),
                                                                          child: Text(
                                                                            'Cancelar',
                                                                          ),
                                                                        ),
                                                                        ElevatedButton(
                                                                          style: ElevatedButton.styleFrom(
                                                                            backgroundColor:
                                                                                Theme.of(
                                                                                  context,
                                                                                ).primaryColor,
                                                                            foregroundColor:
                                                                                Colors.white,
                                                                          ),
                                                                          onPressed: () async {
                                                                            if (localBancoSeleccionado !=
                                                                                null) {
                                                                              await notifier.actualizarDepositoTransaccionYBanco(
                                                                                deposito:
                                                                                    d,
                                                                                nuevoNroTransaccion:
                                                                                    controller.text,
                                                                                nuevoBanco:
                                                                                    localBancoSeleccionado!,
                                                                                context:
                                                                                    context,
                                                                              );
                                                                              Navigator.pop(
                                                                                dialogContext,
                                                                              );
                                                                            } else {
                                                                              ScaffoldMessenger.of(
                                                                                context,
                                                                              ).showSnackBar(
                                                                                SnackBar(
                                                                                  content: Text(
                                                                                    'Debe seleccionar un banco',
                                                                                  ),
                                                                                  backgroundColor:
                                                                                      Colors.orange,
                                                                                ),
                                                                              );
                                                                            }
                                                                          },
                                                                          child: Text(
                                                                            'Guardar',
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    );
                                                                  },
                                                                );
                                                              },
                                                            );
                                                          },
                                                        ),
                                                      ),

                                                      IconButton(
                                                        icon: Icon(
                                                          Icons.close,
                                                          color: Colors.red,
                                                          size: 20,
                                                        ),
                                                        tooltip: 'Rechazar',
                                                        onPressed: () async {
                                                          // Mostrar diálogo de confirmación
                                                          final confirmar = await showDialog<
                                                            bool
                                                          >(
                                                            context: context,
                                                            builder:
                                                                (
                                                                  context,
                                                                ) => AlertDialog(
                                                                  title: Text(
                                                                    'Confirmar rechazo',
                                                                  ),
                                                                  content: Text(
                                                                    '¿Está seguro que desea rechazar este depósito?',
                                                                  ),
                                                                  actions: [
                                                                    TextButton(
                                                                      onPressed:
                                                                          () => Navigator.pop(
                                                                            context,
                                                                            false,
                                                                          ),
                                                                      child: Text(
                                                                        'Cancelar',
                                                                      ),
                                                                    ),
                                                                    ElevatedButton(
                                                                      style: ElevatedButton.styleFrom(
                                                                        backgroundColor:
                                                                            Colors.red,
                                                                        foregroundColor:
                                                                            Colors.white,
                                                                      ),
                                                                      onPressed:
                                                                          () => Navigator.pop(
                                                                            context,
                                                                            true,
                                                                          ),
                                                                      child: Text(
                                                                        'Rechazar',
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                          );

                                                          // Si el usuario confirma, rechazar el depósito
                                                          if (confirmar ==
                                                              true) {
                                                            final notifier = ref
                                                                .read(
                                                                  depositosChequesProvider
                                                                      .notifier,
                                                                );
                                                            await notifier
                                                                .rechazarDepositoCheque(
                                                                  deposito: d,
                                                                  context:
                                                                      context,
                                                                );
                                                          }
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                .toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Paginación - adaptada para móvil y desktop
          _buildPagination(context, state, start, end, total),
        ],
      ),
    );
  }

  Widget _buildPagination(
    BuildContext context,
    DepositosChequesState state,
    int start,
    int end,
    int total,
  ) {
    final isDesktop = ResponsiveUtilsBosque.isDesktop(context);
    final isMobile = ResponsiveUtilsBosque.isMobile(context);

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
            child: Text(
              'Mostrando $start a $end de $total depósitos',
              style: TextStyle(fontSize: 13),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.first_page, size: 20),
                  onPressed:
                      state.page > 0
                          ? () => ref
                              .read(depositosChequesProvider.notifier)
                              .setPage(0)
                          : null,
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_left, size: 20),
                  onPressed:
                      state.page > 0
                          ? () => ref
                              .read(depositosChequesProvider.notifier)
                              .setPage(state.page - 1)
                          : null,
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
                SizedBox(width: 8),
                DropdownButton<int>(
                  value: state.rowsPerPage,
                  isDense: true,
                  items:
                      const [10, 20, 50]
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(e.toString()),
                            ),
                          )
                          .toList(),
                  onChanged:
                      (v) => ref
                          .read(depositosChequesProvider.notifier)
                          .setRowsPerPage(v),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.chevron_right, size: 20),
                  onPressed:
                      end < total
                          ? () => ref
                              .read(depositosChequesProvider.notifier)
                              .setPage(state.page + 1)
                          : null,
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
                IconButton(
                  icon: const Icon(Icons.last_page, size: 20),
                  onPressed:
                      end < total
                          ? () => ref
                              .read(depositosChequesProvider.notifier)
                              .setPage((total / state.rowsPerPage).ceil() - 1)
                          : null,
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Row(
          children: [
            Text('Mostrando $start a $end de $total depósitos'),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.first_page),
              onPressed:
                  state.page > 0
                      ? () =>
                          ref.read(depositosChequesProvider.notifier).setPage(0)
                      : null,
            ),
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed:
                  state.page > 0
                      ? () => ref
                          .read(depositosChequesProvider.notifier)
                          .setPage(state.page - 1)
                      : null,
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed:
                  end < total
                      ? () => ref
                          .read(depositosChequesProvider.notifier)
                          .setPage(state.page + 1)
                      : null,
            ),
            IconButton(
              icon: const Icon(Icons.last_page),
              onPressed:
                  end < total
                      ? () => ref
                          .read(depositosChequesProvider.notifier)
                          .setPage((total / state.rowsPerPage).ceil() - 1)
                      : null,
            ),
            const SizedBox(width: 16),
            DropdownButton<int>(
              value: state.rowsPerPage,
              items:
                  const [10, 20, 50]
                      .map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text(e.toString()),
                        ),
                      )
                      .toList(),
              onChanged:
                  (v) => ref
                      .read(depositosChequesProvider.notifier)
                      .setRowsPerPage(v),
            ),
          ],
        ),
      );
    }
  }
}
