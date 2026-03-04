import 'dart:typed_data';

import 'package:bosque_flutter/core/state/empleados_dependientes_provider.dart';
import 'package:bosque_flutter/core/state/registro_empleado_provider.dart';
import 'package:bosque_flutter/core/state/rrhh_provider.dart';
import 'package:bosque_flutter/core/utils/descargar_reportes_jasper.dart';
import 'package:bosque_flutter/presentation/screens/registro_empleado/detalle_empleado.dart';
import 'package:bosque_flutter/presentation/screens/registro_empleado/registro_empleado.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/responsive_utils_registro_empleado.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/registro_empleado_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/domain/entities/empleado_entity.dart';
import 'package:bosque_flutter/domain/entities/empresa_entity.dart';

class ListaEmpleados extends ConsumerStatefulWidget {
  const ListaEmpleados({Key? key}) : super(key: key);

  @override
  ConsumerState<ListaEmpleados> createState() => _ListaEmpleadosState();
}

class _ListaEmpleadosState extends ConsumerState<ListaEmpleados> {
  final TextEditingController _searchController = TextEditingController();
  int? _esActivo = 1;
  int? _codEmpresa ; // Valor por defecto
  String _searchTerm = '';

  int _pageNumber = 1;
  final int _pageSize = 15;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ========== MÉTODOS DE CONSTRUCCIÓN ==========

  Widget _buildPaginator(List<EmpleadoEntity>? empleados) {
    if (empleados == null || empleados.isEmpty) {
      return const SizedBox.shrink();
    }

    final bool isLastPage = empleados.length < _pageSize;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing * 1.5,
        vertical: context.spacing * 1.5,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _pageNumber > 1
                ? () => setState(() => _pageNumber--)
                : null,
          ),
          Text(
            'Página $_pageNumber',
            style: context.bodyStyle,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: isLastPage
                ? null
                : () => setState(() => _pageNumber++),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      constraints: BoxConstraints(
        maxWidth: context.isMobile ? double.infinity : 600,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade50.withOpacity(0.6),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing,
        vertical: context.smallSpacing,
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: Colors.green,
            size: context.iconSize,
          ),
          SizedBox(width: context.smallSpacing),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() {
                _searchTerm = value;
                _pageNumber = 1;
              }),
              textInputAction: TextInputAction.search,
              style: context.bodyStyle,
              decoration: InputDecoration(
                hintText: 'Buscar empleado',
                hintStyle: context.bodyLightStyle,
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  vertical: context.smallSpacing,
                ),
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            GestureDetector(
              onTap: () => setState(() {
                _searchController.clear();
                _searchTerm = '';
                _pageNumber = 1;
              }),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.smallSpacing,
                ),
                child: Icon(
                  Icons.close,
                  size: context.smallIconSize,
                  color: Colors.black45,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
    IconData? icon,
    required Color selectedColor,
    required Color textColor,
  }) {
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14),
            SizedBox(width: context.smallSpacing * 0.5),
          ],
          Text(
            label,
            style: TextStyle(fontSize: context.bodyFontSize),
          ),
        ],
      ),
      selected: selected,
      onSelected: (_) => onSelected(),
      backgroundColor: Colors.grey.shade100,
      selectedColor: selectedColor,
      labelStyle: TextStyle(
        color: selected ? textColor : Colors.black87,
      ),
      elevation: 0,
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing * 0.75,
        vertical: context.smallSpacing * 0.5,
      ),
    );
  }

 Widget _buildStatusFilters(BuildContext context, bool isMobile) {
    if (isMobile) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildStatusChip(
              label: 'Todos',
              selected: _esActivo == null,
              onSelected: () => setState(() {
                _esActivo = null;
                _pageNumber = 1;
              }),
              icon: null,
              selectedColor: Colors.blue.shade100,
              textColor: Colors.blue.shade800,
            ),
            SizedBox(width: context.smallSpacing),
            _buildStatusChip(
              label: 'Activos',
              selected: _esActivo == 1,
              onSelected: () => setState(() {
                _esActivo = 1;
                _pageNumber = 1;
              }),
              icon: Icons.check_circle,
              selectedColor: Colors.green.shade100,
              textColor: Colors.green.shade800,
            ),
            SizedBox(width: context.smallSpacing),
            _buildStatusChip(
              label: 'Inactivos',
              selected: _esActivo == 0,
              onSelected: () => setState(() {
                _esActivo = 0;
                _pageNumber = 1;
              }),
              icon: Icons.cancel,
              selectedColor: Colors.red.shade100,
              textColor: Colors.red.shade800,
            ),
          ],
        ),
      );
    } else {
      // ✅ EN DESKTOP: SOLO LOS CHIPS, SIN ETIQUETA
      return Wrap(
        spacing: context.spacing,
        children: [
          _buildStatusChip(
            label: 'Todos',
            selected: _esActivo == null,
            onSelected: () => setState(() {
              _esActivo = null;
              _pageNumber = 1;
            }),
            icon: null,
            selectedColor: Colors.blue.shade100,
            textColor: Colors.blue.shade800,
          ),
          _buildStatusChip(
            label: 'Activos',
            selected: _esActivo == 1,
            onSelected: () => setState(() {
              _esActivo = 1;
              _pageNumber = 1;
            }),
            icon: Icons.check_circle,
            selectedColor: Colors.green.shade100,
            textColor: Colors.green.shade800,
          ),
          _buildStatusChip(
            label: 'Inactivos',
            selected: _esActivo == 0,
            onSelected: () => setState(() {
              _esActivo = 0;
              _pageNumber = 1;
            }),
            icon: Icons.cancel,
            selectedColor: Colors.red.shade100,
            textColor: Colors.red.shade800,
          ),
        ],
      );
    }
  }

  Widget _buildEmpresaFilter(BuildContext context, bool isMobile) {
    final empresasAsync = ref.watch(empresasProvider);

    return empresasAsync.when(
      loading: () => SizedBox(
        height: 45,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (empresas) {
        final empresasFiltradas = (empresas as List?)
                ?.where((e) => (e as dynamic).codEmpresa != -1)
                .cast<EmpresaEntity>()
                .toList() ??
            [];

        if (empresasFiltradas.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Etiqueta solo en desktop
            if (!isMobile)
              Padding(
                padding: EdgeInsets.only(bottom: context.smallSpacing),
                child: Row(
                  children: [
                    /*Icon(
                      Icons.business,
                      color: Colors.blue.shade600,
                      size: context.iconSize,
                    ),*/
                    SizedBox(width: context.smallSpacing),
                    Text(
                      'Ver por empresa:',
                      style: context.bodyStyle.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            // Chips scrollable
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // "Todas las empresas" chip
                  _buildEmpresaChip(
                    label: 'Todas las empresas',
                    selected: _codEmpresa == null,
                    onSelected: () => setState(() {
                      _codEmpresa = null;
                      _pageNumber = 1;
                    }),
                    selectedColor: Colors.purple.shade100,
                    textColor: Colors.purple.shade800,
                  ),
                  SizedBox(width: context.smallSpacing),
                  // Chips de empresas
                  ...empresasFiltradas.map((empresa) {
                    return Padding(
                      padding: EdgeInsets.only(right: context.smallSpacing),
                      child: _buildEmpresaChip(
                        label: empresa.nombre,
                        selected: _codEmpresa == empresa.codEmpresa,
                        onSelected: () => setState(() {
                          _codEmpresa = empresa.codEmpresa; // ✅ Asignar el int correctamente
                          _pageNumber = 1;
                        }),
                        selectedColor: Colors.blue.shade100,
                        textColor: Colors.blue.shade800,
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmpresaChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
    required Color selectedColor,
    required Color textColor,
  }) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: context.bodyFontSize,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      selected: selected,
      onSelected: (_) => onSelected(),
      backgroundColor: Colors.grey.shade100,
      selectedColor: selectedColor,
      labelStyle: TextStyle(
        color: selected ? textColor : Colors.black87,
      ),
      elevation: 0,
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing * 0.75,
        vertical: context.smallSpacing * 0.5,
      ),
      side: BorderSide(
        color: selected ? textColor : Colors.grey.shade300,
        width: selected ? 1.5 : 1,
      ),
    );
  }

  Widget _buildFiltersSection() {
    final isMobile = context.isMobile;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? context.spacing : context.spacing * 1.5,
        vertical: context.spacing,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Buscador
          _buildSearchBar(),
          SizedBox(height: context.spacing),

          // Filtro de Empresa
          _buildEmpresaFilter(context, isMobile),
          SizedBox(height: context.spacing),

          // ✅ ETIQUETA SOLO AQUÍ (no duplicada)
          if (!isMobile)
            Text(
              'Ver empleados:',
              style: context.bodyStyle.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          if (!isMobile) SizedBox(height: context.smallSpacing),
          
          // Filtro de Estado
          _buildStatusFilters(context, isMobile),
        ],
      ),
    );
  }

  Widget _buildContent(List<EmpleadoEntity> empleados) {
    if (context.isMobile) {
      return _buildMobileList(empleados);
    } else {
      return _buildDesktopTable(empleados);
    }
  }

  Widget _buildMobileList(List<EmpleadoEntity> empleados) {
    return ListView.builder(
      padding: EdgeInsets.all(context.spacing),
      itemCount: empleados.length,
      itemBuilder: (context, index) {
        final empleado = empleados[index];
        final isActive = empleado.relEmpEmpr.esActivo == 1;

        return Card(
          elevation: 1,
          margin: EdgeInsets.only(bottom: context.spacing),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    DetalleEmpleado(codEmpleado: empleado.codEmpleado),
              ),
            ),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: EdgeInsets.all(context.spacing),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Foto + Nombre + Estado
                  Row(
                    children: [
                      // Foto
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 56,
                          height: 56,
                          child: EmployeeImageCell(
                            codEmpleado: empleado.codEmpleado,
                          ),
                        ),
                      ),
                      SizedBox(width: context.spacing),
                      // Nombre
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              empleado.persona.datoPersona ?? '',
                              style: context.subtitleStyle.copyWith(
                                fontSize: context.bodyFontSize + 1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: context.smallSpacing * 0.5),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: context.smallSpacing,
                                vertical: context.smallSpacing * 0.25,
                              ),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? Colors.green.shade50
                                    : Colors.red.shade50,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: isActive
                                      ? Colors.green.shade200
                                      : Colors.red.shade200,
                                ),
                              ),
                              child: Text(
                                isActive ? 'Activo' : 'Inactivo',
                                style: TextStyle(
                                  fontSize: context.smallFontSize,
                                  fontWeight: FontWeight.w600,
                                  color: isActive
                                      ? Colors.green.shade700
                                      : Colors.red.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: context.spacing),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: context.smallIconSize,
                        color: Colors.grey.shade400,
                      ),
                    ],
                  ),

                  // Detalles: Cargo, Empresas
                  SizedBox(height: context.spacing),
                  Divider(height: context.spacing, color: Colors.grey.shade200),
                  SizedBox(height: context.spacing),
                  _buildDetailRow(
                    context,
                    Icons.work_outline,
                    'Cargo:',
                    empleado.empleadoCargo.cargoSucursal?.cargo?.descripcionPlanilla ?? 'N/A',
                  ),
                  SizedBox(height: context.smallSpacing),
                  _buildDetailRow(
                    context,
                    Icons.home_work,
                    'Empresa Interna:',
                    empleado.empleadoCargo.cargoSucursal?.cargo?.nombreEmpresa ?? 'N/A',
                  ),
                  SizedBox(height: context.smallSpacing),
                  _buildDetailRow(
                    context,
                    Icons.apartment,
                    'Empresa Fiscal:',
                    empleado.empleadoCargo.cargoSucursal?.cargo?.nombreEmpresaPlanilla ?? 'N/A',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.blue.shade600,
        ),
        SizedBox(width: context.smallSpacing),
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: context.bodyStyle.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: context.bodyStyle.copyWith(
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopTable(List<EmpleadoEntity> empleados) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            const DataColumn(label: Text('#')),
            const DataColumn(label: Text('Foto')),
            const DataColumn(label: Text('Nombre Completo')),
            const DataColumn(label: Text('Estado')),
            const DataColumn(label: Text('Cargo')),
            const DataColumn(label: Text('Empresa Interna')),
            const DataColumn(label: Text('Empresa Fiscal')),
            const DataColumn(label: Text('Acciones')),
          ],
          rows: List<DataRow>.generate(
            empleados.length,
            (index) {
              final empleado = empleados[index];
              return DataRow(
                cells: [
                  DataCell(Text('${empleado.fila}')),
                  DataCell(
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: EmployeeImageCell(
                          codEmpleado: empleado.codEmpleado,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      empleado.persona.datoPersona ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: empleado.relEmpEmpr.esActivo == 1
                            ? Colors.green.shade50
                            : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: empleado.relEmpEmpr.esActivo == 1
                              ? Colors.green.shade200
                              : Colors.red.shade200,
                        ),
                      ),
                      child: Text(
                        empleado.relEmpEmpr.esActivo == 1
                            ? 'Activo'
                            : 'Inactivo',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: empleado.relEmpEmpr.esActivo == 1
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      empleado.empleadoCargo.cargoSucursal?.cargo?.descripcionPlanilla ?? 'N/A',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DataCell(
                    Text(
                      empleado.empleadoCargo.cargoSucursal?.cargo?.nombreEmpresa ?? 'N/A',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DataCell(
                    Text(
                      empleado.empleadoCargo.cargoSucursal?.cargo?.nombreEmpresaPlanilla ?? 'N/A',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DataCell(
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetalleEmpleado(
                              codEmpleado: empleado.codEmpleado,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.info, size: 16),
                      label: const Text('Ver Detalles'),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<Uint8List> downloadFunction() async {
    ref.invalidate(rptNominaEmpleados);
    return ref.read(rptNominaEmpleados.future);
  }

  @override
  Widget build(BuildContext context) {
    final String? search =
        _searchTerm.trim().isEmpty ? null : _searchTerm.trim();
    final isMobile = context.isMobile;

    final empleadosAsync = ref.watch(
      getListaEmpleados(
        (search, _esActivo, _pageNumber, _pageSize, _codEmpresa),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Empleados'),
        elevation: 0,
        backgroundColor: Colors.blue.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Generar Reporte de Empleados',
            onPressed: () async {
              await mostrarReportePdf(
                context: context,
                downloadFunction: downloadFunction,
                filename: 'RptNominaEmpleados.pdf',
              );
            },
          ),
          refreshButton(),
          SizedBox(width: context.spacing),
        ],
      ),
      body: Column(
        children: [
          _buildFiltersSection(),
          Expanded(
            child: empleadosAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) =>
                  Center(child: Text('Error: $error')),
              data: (empleados) {
                if (empleados.isEmpty) {
                  return Center(
                    child: Text(
                      'No hay empleados disponibles',
                      style: context.bodyStyle,
                    ),
                  );
                }

                return Column(
                  children: [
                    Expanded(
                      child: _buildContent(empleados),
                    ),
                    _buildPaginator(empleados),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: isMobile
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RegistroEmpleado(),
                  ),
                );
              },
              tooltip: 'Nuevo Empleado',
              backgroundColor: Colors.green,
              child: const Icon(Icons.person_add),
            )
          : FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RegistroEmpleado(),
                  ),
                );
              },
              label: const Text('Nuevo Empleado'),
              icon: const Icon(Icons.person_add),
              backgroundColor: Colors.green,
            ),
    );
  }

  Widget refreshButton() {
    return IconButton(
      icon: const Icon(Icons.refresh),
      tooltip: 'Refrescar',
      onPressed: () {
        ref.invalidate(getListaEmpleados);
      },
    );
  }
}