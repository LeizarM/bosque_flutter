import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/core/state/control_combustible_maquina_montacarga_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:intl/intl.dart';

class ControlCombustibleMaquinaMontaCargaViewScreen extends ConsumerStatefulWidget {
  const ControlCombustibleMaquinaMontaCargaViewScreen({super.key});

  @override
  ConsumerState<ControlCombustibleMaquinaMontaCargaViewScreen> createState() => 
      _ControlCombustibleMaquinaMontaCargaViewScreenState();
}

class _ControlCombustibleMaquinaMontaCargaViewScreenState 
    extends ConsumerState<ControlCombustibleMaquinaMontaCargaViewScreen> {
  
  int? _selectedMaquinaId;
  
  @override
  void initState() {
    super.initState();
    // Cargar datos iniciales al iniciar la pantalla
    Future.microtask(() => 
        ref.read(controlCombustibleMaquinaMontacargaNotifierProvider.notifier)
            .cargarDatosIniciales()
    );
  }
  
  void _cargarBidonesPorMaquina() {
    if (_selectedMaquinaId != null) {
      ref.read(controlCombustibleMaquinaMontacargaNotifierProvider.notifier)
         .cargarBidonesPorMaquina(_selectedMaquinaId!);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Observar el estado
    final state = ref.watch(controlCombustibleMaquinaMontacargaNotifierProvider);
    final maquinas = state.maquinasMontacarga;
    final bidones = state.bidones;
    
    // Obtener dimensiones responsivas
    final horizontalPadding = ResponsiveUtilsBosque.getHorizontalPadding(context);
    final verticalPadding = ResponsiveUtilsBosque.getVerticalPadding(context);
    final isDesktop = ResponsiveUtilsBosque.isDesktop(context);
    final isTablet = ResponsiveUtilsBosque.isTablet(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Control de Combustible Máquina/Montacarga'),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Seleccionar Máquina',
                      style: ResponsiveUtilsBosque.getTitleStyle(context),
                    ),
                    SizedBox(height: verticalPadding),
                    
                    // Mostrar mensajes de error con un mensaje más amigable
                    if (state.maquinasStatus == FetchStatus.error)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'No se pudieron cargar las máquinas. Por favor, intente nuevamente.',
                                style: TextStyle(color: Colors.orange[800]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    SizedBox(height: verticalPadding),
                    
                    // Dropdown para selección de máquina
                    DropdownButtonFormField<int>(
                      decoration: InputDecoration(
                        labelText: 'Máquina/Montacarga',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.engineering),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding * 0.75,
                          vertical: 16,
                        ),
                      ),
                      value: _selectedMaquinaId,
                      items: maquinas.map((maquina) {
                        return DropdownMenuItem<int>(
                          value: maquina.idMaquina,
                          child: Text('${maquina.idMaquina} - ${maquina.whsCode} (${maquina.whsName})'),
                        );
                      }).toList(),
                      onChanged: state.maquinasStatus == FetchStatus.loading 
                        ? null 
                        : (value) {
                            setState(() {
                              _selectedMaquinaId = value;
                            });
                            // Cargar bidones al seleccionar una máquina
                            if (value != null) {
                              _cargarBidonesPorMaquina();
                            }
                          },
                      isExpanded: true,
                      hint: const Text('Seleccione una máquina'),
                    ),
                    
                    SizedBox(height: verticalPadding),
                    
                    // Botón para cargar bidones
                    SizedBox(
                      width: double.infinity,
                      height: isDesktop ? 48 : 44,
                      child: ElevatedButton(
                        onPressed: _selectedMaquinaId == null || 
                                   state.bidonesStatus == FetchStatus.loading 
                          ? null 
                          : _cargarBidonesPorMaquina,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: state.bidonesStatus == FetchStatus.loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'CARGAR CONTROLES DE COMBUSTIBLE',
                              style: TextStyle(
                                fontSize: ResponsiveUtilsBosque.getResponsiveValue<double>(
                                  context: context,
                                  defaultValue: 14.0,
                                  mobile: 13.0,
                                  desktop: 15.0,
                                ),
                              ),
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: verticalPadding * 1.5),
            
            // Título de la sección de bidones
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Controles de combustible registrados',
                  style: ResponsiveUtilsBosque.getTitleStyle(context),
                ),
                
                // Indicador de carga de bidones
                if (state.bidonesStatus == FetchStatus.loading)
                  const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            
            SizedBox(height: verticalPadding * 0.5),
            
            // Lista de bidones
            Expanded(
              child: state.bidonesStatus == FetchStatus.loading
                ? const Center(child: CircularProgressIndicator())
                : bidones.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay controles de combustible registrados para esta máquina',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[700],
                            ),
                          ),
                          if (_selectedMaquinaId != null) const SizedBox(height: 24),
                          if (_selectedMaquinaId != null)
                            OutlinedButton.icon(
                              icon: const Icon(Icons.refresh),
                              label: const Text('Intentar nuevamente'),
                              onPressed: _cargarBidonesPorMaquina,
                            ),
                        ],
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final showFullWidth = isDesktop;
                        // Para tablet y resoluciones menores, forzar un ancho mínimo grande para habilitar scroll
                        final minTableWidth = isDesktop ? constraints.maxWidth : 1200.0;
                        return Container(
                          width: showFullWidth ? constraints.maxWidth : null,
                          child: Card(
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(minWidth: minTableWidth),
                                  child: DataTable(
                                    columnSpacing: isDesktop ? 40.0 : (isTablet ? 28.0 : 20.0),
                                    columns: const [
                                      DataColumn(label: Text('Máquina')),
                                      DataColumn(label: Text('Fecha')),
                                      DataColumn(label: Text('Litros Ingreso')),
                                      DataColumn(label: Text('Litros Salida')),
                                      DataColumn(label: Text('Saldo Litros')),
                                      DataColumn(label: Text('Horas Uso')),
                                      DataColumn(label: Text('Horómetro')),
                                      DataColumn(label: Text('Nombre Completo')),
                                      DataColumn(label: Text('Almacén')),
                                      DataColumn(label: Text('Obs')),
                                    ],
                                    rows: bidones.map((bidon) {
                                      return DataRow(
                                        cells: [
                                          DataCell(Text(bidon.maquina ?? '')),
                                          DataCell(Text(DateFormat('yyyy-MM-dd').format(bidon.fecha)) ),
                                          DataCell(Text(bidon.litrosIngreso.toStringAsFixed(3))),
                                          DataCell(Text(bidon.litrosSalida.toStringAsFixed(3))),
                                          DataCell(Text(bidon.saldoLitros.toStringAsFixed(3))),
                                          DataCell(Text(bidon.horasUso.toStringAsFixed(3))),
                                          DataCell(Text(bidon.horometro.toStringAsFixed(3))),
                                          DataCell(Text(bidon.nombreCompleto ?? '')),
                                          DataCell(Text(bidon.whsName ?? '')),
                                          DataCell(Text(bidon.obs ?? '')),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ),
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
}