import 'dart:async';
import 'dart:math';

//import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/data/repositories/ficha_trabajador_impl.dart';
import 'package:bosque_flutter/presentation/widgets/shared/permission_widget.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/core/state/empleados_dependientes_provider.dart';
import 'package:bosque_flutter/domain/entities/empleado_entity.dart';
import 'package:bosque_flutter/presentation/screens/screens.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';

class EmpleadosDependientesView extends ConsumerStatefulWidget {
  const EmpleadosDependientesView({Key? key}) : super(key: key);

  @override
  ConsumerState<EmpleadosDependientesView> createState() =>
      _EmpleadosDependientesViewState();
}

class _EmpleadosDependientesViewState
    extends ConsumerState<EmpleadosDependientesView> {
      bool _isListenerAdded = false;
  Timer? _debounce;
  String _searchTerm = ""; 
  final ScrollController _scrollController = ScrollController();
  //checkpoint
  int _currentPage = 0;
  final int _itemsPerPage = 10;
    bool _didRefresh = false;
int _filtroActivo = 1;
int? _codEmpleadoUsuario;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didRefresh) {
      _didRefresh = true;
      Future.microtask(() {
        ref.refresh(empleadosDependientesProvider);
        ref.read(imageVersionProvider.notifier).state++;
      });
    }
  }
  @override
void initState() {
  super.initState();
  ref.read(userProvider.notifier).getCodEmpleado().then((cod) {
    setState(() {
      _codEmpleadoUsuario = cod;
    });
  });
   

}
 
  @override
  Widget build(BuildContext context) {
   
    final empleadosAsync = ref.watch(empleadosDependientesProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = ResponsiveUtilsBosque.isDesktop(context);
    final isTablet = ResponsiveUtilsBosque.isTablet(context);
    final isMobile = ResponsiveUtilsBosque.isMobile(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Lista de Empleados',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isDesktop ? 22 : (isMobile ? 18 : 20),
          ),
        ),
        centerTitle: true,
        elevation: 2,
        actions: [
  _buildNotificacionesDropdown(), 
  IconButton(
    icon: const Icon(Icons.refresh),
    tooltip: 'Refrescar',
    onPressed: () async{
      ref.invalidate(empleadosDependientesProvider);
      ref.read(imageVersionProvider.notifier).state++;
      ref.invalidate(documentosPendientesProvider);
     
    },
  ),
],
      ),
      body: Container(
        color: isDark ? Colors.grey[900] : Colors.grey[50],
        child: Column(
          children: [
            
            // Header section with search
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(
                isDesktop ? 24.0 : (isMobile ? 12.0 : 16.0),
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color:
                        isDark
                            ? Colors.black.withOpacity(0.2)
                            : Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: isDesktop ? screenWidth * 0.4 : double.infinity,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Buscar empleado',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: isDark ? Colors.teal[300] : Colors.teal,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color:
                                isDark ? Colors.grey[700]! : Colors.grey[300]!,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color:
                                isDark ? Colors.grey[700]! : Colors.grey[300]!,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: isDark ? Colors.teal[300]! : Colors.teal,
                          ),
                        ),
                        filled: true,
                        fillColor: isDark ? Colors.grey[850] : Colors.white,
                      ),
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      onChanged: (value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() => _searchTerm = value);
    });
  },
                      //onChanged: (value) => setState(() => _searchTerm = value),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildFiltroEmpleados(isWeb: isDesktop || isTablet),
const SizedBox(height: 8),
                ],
              ),
            ),
           
            // Main content
            Expanded(
              child: empleadosAsync.when(
                loading:
                    () => const Center(
                      child: CircularProgressIndicator(color: Colors.teal),
                    ),
                error:
                    (err, _) => Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error: $err',
                            style: TextStyle(color: Colors.red[300]),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                data: (empleados) {
                  final filtered = _filterEmpleados(empleados, _searchTerm);

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.group_off,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay empleados para mostrar',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: isDesktop ? 16 : 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (isDesktop || isTablet) {
                    return Column(
                      children: [
                        Expanded(
                          child: Scrollbar(
                            controller: _scrollController,
                            thumbVisibility: true,
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(16),
                              controller: _scrollController,
                              child: Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    Theme(
                                      data: Theme.of(context).copyWith(
                                        dataTableTheme: DataTableThemeData(
                                          headingRowColor:
                                              MaterialStateProperty.all(
                                                Colors.teal.shade50,
                                              ),
                                          headingRowHeight: 50,
                                          dataRowHeight: 60,
                                          dividerThickness: 1,
                                        ),
                                      ),
                                      child: DataTable(
                                        columnSpacing: 24,
                                        horizontalMargin: 16,
                                        columns: const [
                                          DataColumn(
                                            label: Text(
                                              '#',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              'Foto',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.teal,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              'Nombre',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.teal,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              'Cargo',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.teal,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              'Empresa',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.teal,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              'Sucursal',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.teal,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              'Activo',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.teal,
                                              ),
                                            ),
                                          ),
                                         
                                          DataColumn(
                                            label: Text(
                                              'Acciones',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.teal,
                                              ),
                                            ),
                                          ),
                                        ],
                                        rows: (
    _searchTerm.isEmpty
      ? filtered.skip(_currentPage * _itemsPerPage).take(_itemsPerPage).toList()
      : filtered
  )
      .asMap()
      .entries
      .map((entry) {
        final index = entry.key;
        final empleado = entry.value;
        final numeroFila = _searchTerm.isEmpty
            ? (_currentPage * _itemsPerPage) + index + 1
            : index + 1;
            //comprobar si el empleado es el usuario logueado
        final esUsuarioLogeado = empleado.codEmpleado == _codEmpleadoUsuario;

        return DataRow(
          //resaltar fila si es el usuario logueado
          color: esUsuarioLogeado
  ? WidgetStateProperty.all(
      Colors.blueAccent.withAlpha(25), // Sutil, no llamativo
    )
  : null,//fin resaltar fila
          cells: [
            DataCell(
              Text(
                numeroFila.toString(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            DataCell(
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.teal.shade100,
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: _buildEmpleadoAvatar(empleado.codEmpleado),
                ),
              ),
            ),
            DataCell(
              Text(
                empleado.persona.datoPersona ?? 'N/A',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            DataCell(
              Text(
                empleado.empleadoCargo.cargoSucursal.cargo.descripcion ?? 'N/A',
              ),
            ),
            DataCell(
              Text(
                empleado.empresa.nombre ?? 'N/A',
              ),
            ),
            DataCell(
              Text(
                (empleado.sucursal.nombre ?? 'N/A').toUpperCase(),
              ),
            ),
            DataCell(
              Text(
                (empleado.relEmpEmpr.esActivo == 1
                    ? 'Activo'
                    : 'Inactivo'),
                    //cambiar a color rojo si es inactivo
                    style: TextStyle(
                      color: empleado.relEmpEmpr.esActivo == 1
                          ? Colors.green
                          : Colors.red,
                    ),
              ),
            ),
            DataCell(
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildReferenciasButton(empleado.codEmpleado, empleado.dependiente.codEmpleado ?? 0),
                    const SizedBox(width: 8),
                    TextButton.icon(
  onPressed: () => _navigateToDetails(empleado.codEmpleado),
  icon: const Icon(Icons.info_outline, color: Colors.teal),
  label: const Text('Ver detalles'),
  style: TextButton.styleFrom(
    foregroundColor: Colors.teal,
    backgroundColor: Colors.teal.withOpacity(0.08),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
    textStyle: const TextStyle(fontWeight: FontWeight.w600),
  ),
),
                  ],
                ),
              ),
            ),
          ],
        );
      })
      .toList(),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.surface,
                                        border: Border(
                                          top: BorderSide(
                                            color:
                                                Theme.of(context).dividerColor,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Mostrando ${_currentPage * _itemsPerPage + 1} - ${min((_currentPage + 1) * _itemsPerPage, filtered.length)} de ${filtered.length}',
                                            style:
                                                Theme.of(
                                                  context,
                                                ).textTheme.bodyMedium,
                                          ),
                                          Row(
                                            children: [
                                              _buildPageButton(
                                                icon: Icons.first_page,
                                                onPressed:
                                                    _currentPage > 0
                                                        ? () => setState(
                                                          () =>
                                                              _currentPage = 0,
                                                        )
                                                        : null,
                                              ),
                                              _buildPageButton(
                                                icon: Icons.chevron_left,
                                                onPressed:
                                                    _currentPage > 0
                                                        ? () => setState(
                                                          () => _currentPage--,
                                                        )
                                                        : null,
                                              ),
                                              const SizedBox(width: 16),
                                               
          
          // ...List.generate(
          //   (filtered.length / _itemsPerPage).ceil(),
          //   (index) => _buildNumberButton(index, filtered.length),
          // ),
          
          ...(() {
            int totalPages = (filtered.length / _itemsPerPage).ceil();
            int start = (_currentPage - 2).clamp(0, totalPages - 1);
            int end = (_currentPage + 2).clamp(0, totalPages - 1);

            List<Widget> pageButtons = [];
            if (start > 0) {
              pageButtons.add(_buildNumberButton(0, filtered.length));
              if (start > 1) pageButtons.add(const Text('...'));
            }
            for (int i = start; i <= end; i++) {
              pageButtons.add(_buildNumberButton(i, filtered.length));
            }
            if (end < totalPages - 1) {
              if (end < totalPages - 2) pageButtons.add(const Text('...'));
              pageButtons.add(_buildNumberButton(totalPages - 1, filtered.length));
            }
            return pageButtons;
          })(),
         
                                              const SizedBox(width: 16),
                                              _buildPageButton(
                                                icon: Icons.chevron_right,
                                                onPressed:
                                                    (_currentPage + 1) *
                                                                _itemsPerPage <
                                                            filtered.length
                                                        ? () => setState(
                                                          () => _currentPage++,
                                                        )
                                                        : null,
                                              ),
                                              _buildPageButton(
                                                icon: Icons.last_page,
                                                onPressed:
                                                    (_currentPage + 1) *
                                                                _itemsPerPage <
                                                            filtered.length
                                                        ? () => setState(
                                                          () =>
                                                              _currentPage =
                                                                  (filtered.length /
                                                                          _itemsPerPage)
                                                                      .ceil() -
                                                                  1,
                                                        )
                                                        : null,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  // Mobile View with reorganized content
                 return RefreshIndicator(
  onRefresh: () async {
  ref.invalidate(empleadosDependientesProvider);
  ref.read(imageVersionProvider.notifier).state++;
  await Future.delayed(const Duration(milliseconds: 500));
},
  child: ListView.builder(
    padding: const EdgeInsets.symmetric(
      vertical: 8,
      horizontal: 12,
    ),
    itemCount: filtered.length,
    itemBuilder: (context, index) {
      final empleado = filtered[index];
      final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;

      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with avatar and name
            ListTile(
              contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              leading: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? Colors.teal.shade700 : Colors.teal.shade100,
                  ),
                ),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: isDark ? Colors.teal.shade900 : Colors.teal.shade50,
                  child: _buildEmpleadoAvatar(empleado.codEmpleado),
                ),
              ),
              title: Text(
                empleado.persona.datoPersona ?? '',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                overflow: TextOverflow.visible,
                softWrap: true,
                maxLines: 2,
              ),
              subtitle: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(
      empleado.empleadoCargo.cargoSucursal.cargo.descripcion ?? '-',
      style: theme.textTheme.bodySmall?.copyWith(
        fontSize: 13,
        color: isDark ? Colors.grey[300] : Colors.grey[700],
      ),
      overflow: TextOverflow.visible,
      softWrap: true,
      maxLines: 2,
    ),
    const SizedBox(height: 2),
    Row(
      children: [
        Icon(
          empleado.relEmpEmpr.esActivo == 1 ? Icons.check_circle : Icons.cancel,
          color: empleado.relEmpEmpr.esActivo == 1 ? Colors.green : Colors.red,
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          empleado.relEmpEmpr.esActivo == 1 ? 'Activo' : 'Inactivo',
          style: TextStyle(
            color: empleado.relEmpEmpr.esActivo == 1 ? Colors.green : Colors.red,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    ),
  ],
),
            ),
            // Two-column info grid
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildCompactInfo(
                          context,
                          icon: Icons.business_outlined,
                          label: 'Empresa',
                          value: empleado.empresa.nombre ?? '-',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildCompactInfo(
                          context,
                          icon: Icons.location_on_outlined,
                          label: 'Sucursal',
                          value: (empleado.sucursal.nombre ?? '-').toUpperCase(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          child: _buildReferenciasButton(empleado.codEmpleado, empleado.dependiente.codEmpleado ?? 0),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(left: 6),
                          child: TextButton.icon(
  onPressed: () => _navigateToDetails(empleado.codEmpleado),
  icon: const Icon(Icons.info_outline, color: Colors.teal),
  label: const Text('Ver detalles'),
  style: TextButton.styleFrom(
    foregroundColor: Colors.teal,
    backgroundColor: Colors.teal.withOpacity(0.08),
    textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  ),
);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageButton({required IconData icon, VoidCallback? onPressed}) {
    return IconButton(
      icon: Icon(icon),
      onPressed: onPressed,
      style: IconButton.styleFrom(
        foregroundColor:
            onPressed != null
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).disabledColor,
        backgroundColor:
            onPressed != null
                ? Theme.of(context).colorScheme.surface
                : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.1),
        padding: const EdgeInsets.all(8),
      ),
    );
  }

  Widget _buildNumberButton(int index, int totalItems) {
    final isSelected = index == _currentPage;
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: MaterialButton(
        onPressed: () => setState(() => _currentPage = index),
        color:
            isSelected ? theme.colorScheme.primary : theme.colorScheme.surface,
        elevation: 0,
        hoverElevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(
            color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
          ),
        ),
        minWidth: 40,
        height: 40,
        child: Text(
          '${index + 1}',
          style: TextStyle(
            color:
                isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }


  Widget _buildCompactInfo(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool isHighlighted = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color:
            isHighlighted
                ? (isDark ? Colors.teal.shade900 : Colors.teal.shade50)
                : (isDark ? theme.cardColor : Colors.grey[50]),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              isHighlighted
                  ? (isDark ? Colors.teal.shade700 : Colors.teal.shade200)
                  : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color:
                isHighlighted
                    ? Colors.teal
                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color:
                        isHighlighted
                            ? Colors.teal
                            : theme.textTheme.bodyMedium?.color,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
Widget _buildReferenciasButton(int codEmpleado, int totalReferencias) {
  return TextButton.icon(
    onPressed: () => _navigateToDependientes(codEmpleado),
    icon: const Icon(Icons.people, color: Colors.teal),
    label: Text(
      'Referencias: $totalReferencias',
      style: const TextStyle(
        color: Colors.teal,
        fontWeight: FontWeight.bold,
      ),
    ),
    style: TextButton.styleFrom(
      foregroundColor: Colors.teal,
      backgroundColor: Colors.teal.withOpacity(0.08),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      textStyle: const TextStyle(fontWeight: FontWeight.w600),
    ),
  );
}
 

   Widget _buildDependientesCount(int codEmpleado, bool isDesktop) {
  return Consumer(
    builder: (context, ref, _) {
      final user = ref.watch(userProvider);
      final codEmpleadoActual = user?.codEmpleado;
      final dependientesAsync = ref.watch(dependientesProvider(codEmpleado));
      final garantesRefAsync = ref.watch(obtenerGaranteReferenciaProvider(codEmpleado));

      // Espera ambos providers
      return dependientesAsync.when(
        data: (dependientes) {
          return garantesRefAsync.when(
            data: (garantesReferencias) {
              final total = dependientes.length + garantesReferencias.length;
              final tieneDatos = total > 0;
              final esUsuarioActual = codEmpleadoActual != null && codEmpleado == codEmpleadoActual;
              final bool habilitado = tieneDatos || esUsuarioActual;
              final Color textoColor = habilitado ? Colors.teal : Colors.grey;

              return TextButton.icon(
                onPressed: habilitado
                    ? () => _navigateToDependientes(codEmpleado)
                    : null,
                icon: Icon(Icons.people, color: textoColor),
                label: Text(
                  'Referencias: $total',
                  style: TextStyle(
                    color: textoColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: textoColor,
                  backgroundColor: Colors.teal.withOpacity(0.08),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
              );
            },
            loading: () => const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (_, __) => const Icon(Icons.error, color: Colors.red),
          );
        },
        loading: () => const SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        error: (_, __) => const Icon(Icons.error, color: Colors.red),
      );
    },
  );
}

  // Navigation methods
 void _navigateToDetails(int codEmpleado) async {
  if (!mounted) return;
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => InfoEmpleadoScreen(codEmpleado: codEmpleado),
    ),
  );
  // Al volver, refresca empleados y la imagen
  ref.refresh(empleadosDependientesProvider);
  ref.read(imageVersionProvider.notifier).state++;
}

  void _navigateToDependientes(int codEmpleado) {
  if (!mounted) return;
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => DependienteScreen(codEmpleado: codEmpleado),
    ),
  );
}

  // Existing methods remain unchanged
 List<EmpleadoEntity> _filterEmpleados(
  List<EmpleadoEntity> empleados,
  String searchTerm,
) {
  List<EmpleadoEntity> filtrados = empleados;
  if (_filtroActivo == 1) {
    filtrados = filtrados.where((e) => e.relEmpEmpr.esActivo == 1).toList();
  } else if (_filtroActivo == 2) {
    filtrados = filtrados.where((e) => e.relEmpEmpr.esActivo != 1).toList();
  }
  if (searchTerm.isNotEmpty) {
    filtrados = filtrados.where((empleado) {
      final nombre = empleado.persona.datoPersona!.toLowerCase();
      return nombre.contains(searchTerm.toLowerCase());
    }).toList();
  }

  // Mover el usuario logueado al primer lugar SIN ordenar la lista completa
  if (_codEmpleadoUsuario != null) {
    final idx = filtrados.indexWhere((e) => e.codEmpleado == _codEmpleadoUsuario);
    if (idx > 0) {
      final usuario = filtrados.removeAt(idx);
      filtrados.insert(0, usuario);
    }
  }

  return filtrados;
}

  Widget _buildEmpleadoAvatar(int codEmpleado) {
  return Hero(
    tag: 'empleado-imagen-$codEmpleado',
    child: GestureDetector(
      onTap: () => _mostrarImagenCompleta(context, codEmpleado),
      child: ClipOval(
        child: Image.network(
          getImageUrl(codEmpleado),
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          // Placeholder mientras carga
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: 40,
              height: 40,
              color: Colors.grey[200],
              child: const Center(
                child: Icon(Icons.person, color: Colors.grey, size: 28),
              ),
            );
          },
          // Imagen de error si falla la carga
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 40,
              height: 40,
              color: Colors.grey[200],
              child: const Center(
                child: Icon(Icons.person_off, color: Colors.red, size: 28),
              ),
            );
          },
        ),
      ),
    ),
  );
}

  String getImageUrl(int codEmpleado) {
    final imageVersion = ref.watch(imageVersionProvider);
    return AppConstants.baseUrl +
        AppConstants.getImageUrl +
        '/$codEmpleado.jpg?v=$imageVersion';
    //return AppConstants.baseUrl + AppConstants.getImageUrl + '/$codEmpleado.jpg?timestamp=${DateTime.now().millisecondsSinceEpoch}';
    //return "http://localhost:9223/fichaTrabajador/uploads/img/$codEmpleado.jpg?timestamp=${DateTime.now().millisecondsSinceEpoch}";
  }

  void _mostrarImagenCompleta(BuildContext context, int codEmpleado) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black87,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.all(16),
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
                maxWidth: MediaQuery.of(context).size.width * 0.9,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: InteractiveViewer(
                panEnabled: true,
                boundaryMargin: const EdgeInsets.all(20),
                minScale: 0.5,
                maxScale: 4,
                child: Hero(
                  tag: 'empleado-imagen-$codEmpleado',
                  child: Image.network(
                    getImageUrl(codEmpleado),
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.black54,
                        child: Center(
                          child: CircularProgressIndicator(
                            value:
                                loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                            strokeWidth: 3,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.black54,
                        child: const Center(
                          child: Text(
                            'Error al cargar la imagen',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  Widget _buildFiltroEmpleados({required bool isWeb}) {
  if (isWeb) {
    // Web/desktop: horizontal
    return Row(
      children: [
        const Text('Ver empleados: ', style: TextStyle(fontWeight: FontWeight.w600)),
        ChoiceChip(
          label: const Text('Todos'),
          selected: _filtroActivo == 0,
          onSelected: (_) => setState(() => _filtroActivo = 0),
        ),
        const SizedBox(width: 8),
        ChoiceChip(
          label: const Text('Activos'),
          selected: _filtroActivo == 1,
          onSelected: (_) => setState(() => _filtroActivo = 1),
        ),
        const SizedBox(width: 8),
        ChoiceChip(
          label: const Text('Inactivos'),
          selected: _filtroActivo == 2,
          onSelected: (_) => setState(() => _filtroActivo = 2),
        ),
      ],
    );
  } else {
    // Móvil: vertical y más amigable
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Ver empleados:', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Todos'),
              selected: _filtroActivo == 0,
              onSelected: (_) => setState(() => _filtroActivo = 0),
            ),
            ChoiceChip(
              label: const Text('Activos'),
              selected: _filtroActivo == 1,
              onSelected: (_) => setState(() => _filtroActivo = 1),
            ),
            ChoiceChip(
              label: const Text('Inactivos'),
              selected: _filtroActivo == 2,
              onSelected: (_) => setState(() => _filtroActivo = 2),
            ),
          ],
        ),
      ],
    );
  }
}

  @override
  void dispose() {
    _didRefresh = false;
    _scrollController.dispose();
    super.dispose();
  }
  Widget _buildNotificacionesDropdown() {
  final pendientesAsync = ref.watch(documentosPendientesProvider);
  final repo = FichaTrabajadorImpl();

  return PermissionWidget(
    buttonName: 'btnDocumentosPendientes',
    child: pendientesAsync.when(
      loading: () => IconButton(
        icon: const Icon(Icons.notifications, color: Colors.orange),
        onPressed: null,
      ),
      error: (e, _) => IconButton(
        icon: const Icon(Icons.notifications_off, color: Colors.red),
        onPressed: null,
      ),
      data: (docs) => IconButton(
        icon: Stack(
          children: [
            const Icon(Icons.notifications, color: Colors.orange, size: 28),
            if (docs.isNotEmpty)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  child: Text(
                    '${docs.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        tooltip: 'Documentos pendientes',
        onPressed: docs.isEmpty
            ? null
            : () {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (ctx) {
                    return Consumer(
                      builder: (context, ref, _) {
                        final docs = ref.watch(documentosPendientesProvider).maybeWhen(
                          data: (d) => d,
                          orElse: () => [],
                        );
                        return AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          title: Row(
                            children: [
                              const Icon(Icons.notifications_active, color: Colors.orange, size: 22),
                              const SizedBox(width: 10),
                              Text(
                                'Documentos pendientes',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.orange.shade800,
                                ),
                              ),
                            ],
                          ),
                          content: SizedBox(
                            width: 380,
                            height: 420,
                            child: docs.isEmpty
                                ? const Center(child: Text('No hay documentos pendientes'))
                                : Scrollbar(
                                    thumbVisibility: true,
                                    radius: const Radius.circular(8),
                                    thickness: 6,
                                    child: ListView.separated(
                                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                                      itemCount: docs.length,
                                      separatorBuilder: (_, __) => Divider(height: 18, color: Colors.grey[200]),
                                      itemBuilder: (context, i) {
                                        final doc = docs[i];
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                                          child: Material(
                                            color: Colors.transparent,
                                            borderRadius: BorderRadius.circular(10),
                                            child: InkWell(
                                              borderRadius: BorderRadius.circular(10),
                                              onTap: () {},
                                              child: Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  GestureDetector(
                                                    onTap: () {
                                                      showDialog(
                                                        context: context,
                                                        builder: (ctx) => Dialog(
                                                          backgroundColor: Colors.transparent,
                                                          child: InteractiveViewer(
                                                            child: Image.network(
                                                              '${AppConstants.baseUrl}${AppConstants.getDocPendienteImageUrl}${doc['codEmpleado']}/${doc['tipoDocumento']}/${doc['nombreArchivo']}',
                                                              fit: BoxFit.contain,
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                    child: ClipRRect(
                                                      borderRadius: BorderRadius.circular(8),
                                                      child: Image.network(
                                                        '${AppConstants.baseUrl}${AppConstants.getDocPendienteImageUrl}${doc['codEmpleado']}/${doc['tipoDocumento']}/${doc['nombreArchivo']}',
                                                        width: 54,
                                                        height: 54,
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 14),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          doc['nombreCompleto'] ?? 'Empleado ${doc['codEmpleado']}',
                                                          style: const TextStyle(
                                                            fontWeight: FontWeight.w700,
                                                            fontSize: 14,
                                                            color: Colors.black87,
                                                          ),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                        const SizedBox(height: 2),
                                                        Text(
                                                          '${doc['tipoDocumento']} - ${doc['nombreArchivo']}',
                                                          style: const TextStyle(
                                                            fontSize: 12,
                                                            color: Colors.black54,
                                                          ),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                        const SizedBox(height: 4),
                                                        Row(
                                                          children: [
                                                            Tooltip(
                                                              message: 'Aprobar',
                                                              child: IconButton(
                                                                icon: const Icon(Icons.check_circle, color: Colors.green, size: 22),
                                                                onPressed: () async {
                                                                  await repo.aprobarDocumentoPendiente(doc);
                                                                  ref.invalidate(documentosPendientesProvider);
                                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                                    const SnackBar(content: Text('Documento aprobado')),
                                                                  );
                                                                },
                                                              ),
                                                            ),
                                                            Tooltip(
                                                              message: 'Rechazar',
                                                              child: IconButton(
                                                                icon: const Icon(Icons.cancel, color: Colors.red, size: 22),
                                                                onPressed: () async {
                                                                  final confirm = await showDialog<bool>(
                                                                    context: context,
                                                                    builder: (ctx) => AlertDialog(
                                                                      title: const Text('Rechazar documento'),
                                                                      content: const Text('¿Estás seguro de rechazar este documento?'),
                                                                      actions: [
                                                                        TextButton(
                                                                          child: const Text('Cancelar'),
                                                                          onPressed: () => Navigator.pop(ctx, false),
                                                                        ),
                                                                        ElevatedButton(
                                                                          child: const Text('Rechazar'),
                                                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                                                          onPressed: () => Navigator.pop(ctx, true),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  );
                                                                  if (confirm == true) {
                                                                    await repo.rechazarDocumentoPendiente(doc);
                                                                    ref.invalidate(documentosPendientesProvider);
                                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                                      const SnackBar(content: Text('Documento rechazado')),
                                                                    );
                                                                  }
                                                                },
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                          ),
                          actions: [
                            TextButton(
                              child: const Text('Cerrar'),
                              onPressed: () => Navigator.pop(ctx),
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
  );
}

}
