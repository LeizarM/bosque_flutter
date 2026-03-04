// lib/presentation/widgets/registro_empleado/detalle_informacion_laboral.dart

import 'package:bosque_flutter/core/state/empleados_dependientes_provider.dart';
import 'package:bosque_flutter/core/state/registro_empleado_provider.dart';
import 'package:bosque_flutter/core/state/rrhh_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/abm_service.dart';
import 'package:bosque_flutter/core/utils/console_log.dart';
import 'package:bosque_flutter/data/repositories/registro_empleado_impl.dart';
import 'package:bosque_flutter/domain/entities/empresa_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_relacion_laboral_entity.dart';
import 'package:bosque_flutter/domain/entities/cargo_sucursal_entity.dart';
import 'package:bosque_flutter/presentation/screens/estructura-organizacional/cargos_screen.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/detalle_haber_basico.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/form_relacion_cargo.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/registro_empleado_utils.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/responsive_utils_registro_empleado.dart';
import 'package:bosque_flutter/domain/entities/empleado_entity.dart';
import 'package:bosque_flutter/domain/entities/empleado_cargo_entity.dart';
import 'package:bosque_flutter/domain/entities/relacion_laboral_entity.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/form_relacion_laboral.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/validadores.dart';
import 'package:bosque_flutter/presentation/widgets/shared/permission_widget.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DetalleInformacionLaboral extends ConsumerStatefulWidget {
  final int codEmpleado;

  const DetalleInformacionLaboral({Key? key, required this.codEmpleado}) : super(key: key);

  @override
  ConsumerState<DetalleInformacionLaboral> createState() => _DetalleInformacionLaboralState();
}

class _DetalleInformacionLaboralState extends ConsumerState<DetalleInformacionLaboral> {
  bool _isEditing = false;
  bool _isAddingNewRelacion = false;
  bool _isAddingNewHistorial = false;
  bool _isEditingCargo = false;
  bool _isAddingNewCargo = false;

  String _str(String? s, [String fallback = 'N/A']) {
    if (s == null) return fallback;
    final t = s.trim();
    return t.isEmpty ? fallback : t;
  }

  Widget _sectionHeader(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: context.smallIconSize, color: Theme.of(context).primaryColor),
        SizedBox(width: context.smallSpacing),
        Text(title, style: context.subtitleStyle.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _rowLabelValue(BuildContext context, String label, Widget valueWidget) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.smallSpacing),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: context.isMobile ? 100 : 140,
            child: Text(
              label,
              style: context.bodyStyle.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          SizedBox(width: context.smallSpacing),
          Expanded(child: valueWidget),
        ],
      ),
    );
  }

  Widget _valueText(BuildContext context, String text, {Color? color}) {
    return Text(
      text,
      style: context.bodyStyle.copyWith(
        color: color ?? Colors.black87,
      ),
    );
  }

  Future<void> _saveToServer(
    RelacionLaboralEntity relacion, {
    bool validar = true,
    bool esHistorial = false,
  }) async {
    console('Guardando relación laboral...');

    await executeABM(
      ref: ref,
      context: context,
      operation: () async {
        if (esHistorial && validar) {
          await validarHistorialRelacion(
            fechaIni: relacion.fechaIni!,
            fechaFin: relacion.fechaFin ?? DateTime.now(),
            ref: ref,
            codEmpleado: widget.codEmpleado,
            codRelActual: null,
          );
        } else if (!esHistorial && validar) {
          await validarEdicionRelacionActiva(
            fechaIni: relacion.fechaIni!,
            ref: ref,
            codEmpleado: widget.codEmpleado,
            codRelEmplEmprEdicion: relacion.codRelEmplEmpr,
          );
        }

        final repo = RegistroEmpleadoImpl();
        await repo.registrarRelacionLaboral(
          relacion,
          validar: validar,
          esHistorico: esHistorial,
        );

        if (!esHistorial) {
          final empleadoAsync = ref.read(detalleEmpleadoProvider(widget.codEmpleado));
          final empleado = empleadoAsync.maybeWhen(
            data: (d) => d,
            orElse: () => throw Exception('No se pudo cargar el empleado'),
          );

          final empleadoActualizado = empleado.copyWith(
            codRelBeneficios: relacion.codRelEmplEmpr,
            codRelPlanilla: relacion.codRelEmplEmpr,
          );

          await ref.read(registrarEmpleadoProvider(empleadoActualizado).future);
        }
      },
      providersToInvalidate: [
        relacionLaboralProvider(widget.codEmpleado),
        detalleEmpleadoProvider(widget.codEmpleado),
        cargoActualEmpleadoProvider(widget.codEmpleado),
        getHistorialRelLabEmpleado(widget.codEmpleado),
        getListaEmpleados
      ],
      successMessage: esHistorial
          ? 'Registro histórico añadido correctamente'
          : 'Relación laboral actualizada',
    );

    if (mounted) {
      setState(() {
        _isEditing = false;
        _isAddingNewRelacion = false;
        _isAddingNewHistorial = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final empleadoAsync = ref.watch(detalleEmpleadoProvider(widget.codEmpleado));
    final cargoActualAsync = ref.watch(cargoActualEmpleadoProvider(widget.codEmpleado));
    final historialCargosAsync = ref.watch(getHistorialCargosEmpleado(widget.codEmpleado));
    final historialRelLabAsync = ref.watch(getHistorialRelLabEmpleado(widget.codEmpleado));
    final user = ref.watch(userProvider);
    final audUsuario = user?.codUsuario ?? 0;

    return cargoActualAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
      data: (cargoActualEmpleado) {
        return empleadoAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text('Error: $e')),
          data: (empleadoDetalle) {
            return _buildInformacionLaboralUI(
              context,
              empleadoDetalle,
              cargoActualEmpleado,
              audUsuario,
              historialCargosAsync,
              historialRelLabAsync,
            );
          },
        );
      },
    );
  }

  Widget _buildInformacionLaboralUI(
    BuildContext context,
    EmpleadoEntity empleadoDetalle,
    EmpleadoEntity? cargoActualEmpleado,
    int audUsuario,
    AsyncValue<List<EmpleadoEntity>> historialCargosAsync,
    AsyncValue<List<RelacionLaboralEntity>> historialRelLabAsync,
  ) {
    final EmpleadoCargoEntity? empleadoCargoActual = cargoActualEmpleado?.empleadoCargo;
    final EmpleadoCargoEntity empleadoCargoDetalle = empleadoDetalle.empleadoCargo;
    final cargoFromActual = empleadoCargoActual?.cargoSucursal?.cargo ??
        empleadoCargoDetalle.cargoSucursal?.cargo;

    final nombreEmpresa = _str(
      empleadoCargoActual?.cargoSucursal?.sucursal?.empresa.nombre ??
          cargoFromActual?.nombreEmpresa,
      'N/A',
    );
    final nombreSucursal = _str(
      empleadoCargoActual?.cargoSucursal?.sucursal?.nombre ??
          cargoFromActual?.sucursal,
      'N/A',
    );

    final nombreEmpresaPlanilla =
        _str(cargoFromActual?.nombreEmpresaPlanilla ?? '', nombreEmpresa);
    final nombreSucursalPlanilla = _str(
      empleadoCargoActual?.cargoSucursal?.sucursal?.nombrePlanilla ??
          cargoFromActual?.sucursalPlanilla,
      'N/A',
    );

    final cargoDescripcion =
        _str(cargoFromActual?.descripcion ?? '', 'N/A');
    final cargoPlanillaDescripcion = _str(
      (empleadoCargoActual?.cargoPlanilla != null &&
              (empleadoCargoActual!.cargoPlanilla).trim().isNotEmpty)
          ? empleadoCargoActual.cargoPlanilla
          : (cargoFromActual?.descripcionPlanilla ?? ''),
      'N/A',
    );

    final DateTime? fechaInicioDate = empleadoCargoActual?.fechaInicio ??
        empleadoCargoDetalle.fechaInicio;
    final bool fechaInicioMissing = fechaInicioDate == null;
    final String fechaInicioStr =
        fechaInicioMissing ? 'Sin registros' : FechaUtils.formatDate(fechaInicioDate);

    final relacion = empleadoDetalle.relEmpEmpr;
    final estado = relacion.esActivo == 1 ? 'Activo' : 'Inactivo';
    final bool empleadoActivo = relacion.esActivo == 1;

    final bool fechaIniMissing = relacion.fechaIni == null;
    final String fechaIniStr = fechaIniMissing
        ? 'Sin registros'
        : FechaUtils.formatDate(relacion.fechaIni!);

    final bool fechaInicioBeneficioMissing = relacion.fechaInicioBeneficio == null;
    final String fechaInicioBeneficioStr = fechaInicioBeneficioMissing
        ? 'Sin registros'
        : FechaUtils.formatDate(relacion.fechaInicioBeneficio!);

    final bool fechaInicioPlanillaMissing = relacion.fechaInicioPlanilla == null;
    final String fechaInicioPlanillaStr = fechaInicioPlanillaMissing
        ? 'Sin registros'
        : FechaUtils.formatDate(relacion.fechaInicioPlanilla!);

    return context.isMobile
        ? _buildMobileLayout(
            context,
            empleadoCargoDetalle,
            nombreEmpresa,
            nombreSucursal,
            nombreEmpresaPlanilla,
            nombreSucursalPlanilla,
            cargoDescripcion,
            cargoPlanillaDescripcion,
            fechaInicioStr,
            fechaInicioMissing,
            estado,
            fechaIniStr,
            fechaIniMissing,
            fechaInicioBeneficioStr,
            fechaInicioBeneficioMissing,
            fechaInicioPlanillaStr,
            fechaInicioPlanillaMissing,
            relacion,
            empleadoActivo,
            historialCargosAsync,
            historialRelLabAsync,
            audUsuario,
            fechaInicioDate,
          )
        : _buildWebLayout(
            context,
            empleadoCargoDetalle,
            nombreEmpresa,
            nombreSucursal,
            nombreEmpresaPlanilla,
            nombreSucursalPlanilla,
            cargoDescripcion,
            cargoPlanillaDescripcion,
            fechaInicioStr,
            fechaInicioMissing,
            estado,
            fechaIniStr,
            fechaIniMissing,
            fechaInicioBeneficioStr,
            fechaInicioBeneficioMissing,
            fechaInicioPlanillaStr,
            fechaInicioPlanillaMissing,
            relacion,
            empleadoActivo,
            historialCargosAsync,
            historialRelLabAsync,
            audUsuario,
            fechaInicioDate,
          );
  }

  // ╔════════════════════════════════════════════════════════════════╗
// ║ 3. WEB LAYOUT MEJORADO - Equilibrado lado a lado
// ╚════════════════════════════════════════════════════════════════╝

Widget _buildWebLayout(
  BuildContext context,
  EmpleadoCargoEntity empleadoCargoDetalle,
  String nombreEmpresa,
  String nombreSucursal,
  String nombreEmpresaPlanilla,
  String nombreSucursalPlanilla,
  String cargoDescripcion,
  String cargoPlanillaDescripcion,
  String fechaInicioStr,
  bool fechaInicioMissing,
  String estado,
  String fechaIniStr,
  bool fechaIniMissing,
  String fechaInicioBeneficioStr,
  bool fechaInicioBeneficioMissing,
  String fechaInicioPlanillaStr,
  bool fechaInicioPlanillaMissing,
  RelacionLaboralEntity relacion,
  bool empleadoActivo,
  AsyncValue<List<EmpleadoEntity>> historialCargosAsync,
  AsyncValue<List<RelacionLaboralEntity>> historialRelLabAsync,
  int audUsuario,
  DateTime? fechaInicioDate,
) {
  return SingleChildScrollView(
    padding: EdgeInsets.all(context.spacing),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
                  // ✅ HABER BÁSICO ARRIBA DE TODO
          DetalleHaberBasico(codEmpleado: widget.codEmpleado),
          SizedBox(height: context.largeSpacing * 1),
        // ════════ SECCIÓN 1: CARGO ACTUAL + HISTORIAL CARGOS ════════
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cargo Actual (izquierda)
            Expanded(
              flex: 1,
              child: _buildLastCargoCard(
                context,
                empleadoCargoDetalle,
                nombreEmpresa,
                nombreSucursal,
                nombreEmpresaPlanilla,
                nombreSucursalPlanilla,
                cargoDescripcion,
                cargoPlanillaDescripcion,
                fechaInicioStr,
                fechaInicioMissing,
                empleadoActivo,
                audUsuario,
                fechaInicioDate,
                historialCargosAsync,
                false,
              ),
            ),
            SizedBox(width: context.largeSpacing * 1),
            // Historial Cargos (derecha)
            Expanded(
              flex: 1,
              child: _buildHistorialCargosCard(
                context,
                historialCargosAsync,
                false,
              ),
            ),
          ],
        ),
        
        SizedBox(height: context.largeSpacing * 1),

        // ════════ SECCIÓN 2: RELACIÓN + HISTORIAL RELACIONES ════════
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Relación Laboral (izquierda)
            Expanded(
              flex: 1,
              child: _buildRelacionLaboralCard(
                context,
                estado,
                fechaIniStr,
                fechaIniMissing,
                fechaInicioBeneficioStr,
                fechaInicioBeneficioMissing,
                fechaInicioPlanillaStr,
                fechaInicioPlanillaMissing,
                relacion,
                empleadoActivo,
                audUsuario,
                historialRelLabAsync,
                false,
              ),
            ),
            SizedBox(width: context.largeSpacing * 1),
            // Historial Relaciones (derecha)
            Expanded(
              flex: 1,
              child: _buildHistorialRelacionesCard(
                context,
                historialRelLabAsync,
                relacion,
                audUsuario,
                false,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

  // ╔════════════════════════════════════════════════════════════════╗
  // ║ MOBILE LAYOUT
  // ╚════════════════════════════════════════════════════════════════╝

  Widget _buildMobileLayout(
    BuildContext context,
    EmpleadoCargoEntity empleadoCargoDetalle,
    String nombreEmpresa,
    String nombreSucursal,
    String nombreEmpresaPlanilla,
    String nombreSucursalPlanilla,
    String cargoDescripcion,
    String cargoPlanillaDescripcion,
    String fechaInicioStr,
    bool fechaInicioMissing,
    String estado,
    String fechaIniStr,
    bool fechaIniMissing,
    String fechaInicioBeneficioStr,
    bool fechaInicioBeneficioMissing,
    String fechaInicioPlanillaStr,
    bool fechaInicioPlanillaMissing,
    RelacionLaboralEntity relacion,
    bool empleadoActivo,
    AsyncValue<List<EmpleadoEntity>> historialCargosAsync,
    AsyncValue<List<RelacionLaboralEntity>> historialRelLabAsync,
    int audUsuario,
    DateTime? fechaInicioDate,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(context.spacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
                    // ✅ HABER BÁSICO ARRIBA DE TODO
          DetalleHaberBasico(codEmpleado: widget.codEmpleado),
          SizedBox(height: context.largeSpacing * 1),
          _buildLastCargoCard(
            context,
            empleadoCargoDetalle,
            nombreEmpresa,
            nombreSucursal,
            nombreEmpresaPlanilla,
            nombreSucursalPlanilla,
            cargoDescripcion,
            cargoPlanillaDescripcion,
            fechaInicioStr,
            fechaInicioMissing,
            empleadoActivo,
            audUsuario,
            fechaInicioDate,
            historialCargosAsync,
            true,
          ),
          SizedBox(height: context.largeSpacing),
          _buildRelacionLaboralCard(
            context,
            estado,
            fechaIniStr,
            fechaIniMissing,
            fechaInicioBeneficioStr,
            fechaInicioBeneficioMissing,
            fechaInicioPlanillaStr,
            fechaInicioPlanillaMissing,
            relacion,
            empleadoActivo,
            audUsuario,
            historialRelLabAsync,
            true,
          ),
        ],
      ),
    );
  }

  // ╔════════════════════════════════════════════════════════════════╗
  // ║ CARD: ÚLTIMO CARGO (CON AGRUPACIÓN Y FOOTER)
  // ╚════════════════════════════════════════════════════════════════╝

  Widget _buildLastCargoCard(
    BuildContext context,
    EmpleadoCargoEntity empleadoCargoDetalle,
    String nombreEmpresa,
    String nombreSucursal,
    String nombreEmpresaPlanilla,
    String nombreSucursalPlanilla,
    String cargoDescripcion,
    String cargoPlanillaDescripcion,
    String fechaInicioStr,
    bool fechaInicioMissing,
    bool empleadoActivo,
    int audUsuario,
    DateTime? fechaInicioDate,
    AsyncValue<List<EmpleadoEntity>> historialCargosAsync,
    bool isMobile,
  ) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: context.borderRadius),
      margin: EdgeInsets.symmetric(vertical: context.spacing),
      child: Padding(
        padding: EdgeInsets.all(context.spacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _sectionHeader(context, 'Último Cargo', Icons.work),
                ),
                if (empleadoActivo)
                  IconButton(
                    icon: Icon(
                      _isEditingCargo ? Icons.close : Icons.edit_outlined,
                      color: Colors.blueGrey,
                    ),
                    onPressed: _isAddingNewCargo
                        ? null
                        : () => setState(() => _isEditingCargo = !_isEditingCargo),
                  ),
                _buildAddCargoButton(context, empleadoActivo),
              ],
            ),
            SizedBox(height: context.spacing),
            if (_isEditingCargo)
              _FormCargoEdit(
                codEmpleado: widget.codEmpleado,
                audUsuario: audUsuario,
                fechaInicio: fechaInicioDate,
                onCancel: () => setState(() => _isEditingCargo = false),
              ),
            if (_isAddingNewCargo && empleadoActivo)
              _FormCargoAdd(
                codEmpleado: widget.codEmpleado,
                audUsuario: audUsuario,
                onCancel: () => setState(() => _isAddingNewCargo = false),
              ),
            if (!_isEditingCargo && !_isAddingNewCargo) ...[
              // GRUPO: CARGO INTERNO
              Container(
                decoration: BoxDecoration(
                  border: Border(left: BorderSide(color: Colors.blue.shade600, width: 4)),
                  color: Colors.blue.shade50,
                ),
                padding: EdgeInsets.all(context.spacing),
                margin: EdgeInsets.only(bottom: context.spacing),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cargo Interno',
                      style: context.bodyStyle.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    SizedBox(height: context.smallSpacing),
                    _rowLabelValue(context, 'Empresa:', _valueText(context, nombreEmpresa)),
                    _rowLabelValue(context, 'Sucursal:', _valueText(context, nombreSucursal)),
                    _rowLabelValue(context, 'Cargo:', _valueText(context, cargoDescripcion)),
                  ],
                ),
              ),
              // GRUPO: CARGO PLANILLA
              Container(
                decoration: BoxDecoration(
                  border: Border(left: BorderSide(color: Colors.orange.shade600, width: 4)),
                  color: Colors.orange.shade50,
                ),
                padding: EdgeInsets.all(context.spacing),
                margin: EdgeInsets.only(bottom: context.spacing),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cargo Planilla',
                      style: context.bodyStyle.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    ),
                    SizedBox(height: context.smallSpacing),
                    _rowLabelValue(
                      context,
                      'Empresa:',
                      _valueText(context, nombreEmpresaPlanilla),
                    ),
                    _rowLabelValue(
                      context,
                      'Sucursal:',
                      _valueText(context, nombreSucursalPlanilla),
                    ),
                    _rowLabelValue(
                      context,
                      'Cargo:',
                      _valueText(context, cargoPlanillaDescripcion),
                    ),
                  ],
                ),
              ),
              // GRUPO: FECHA
              Container(
                decoration: BoxDecoration(
                  border: Border(left: BorderSide(color: Colors.grey.shade600, width: 4)),
                  color: Colors.grey.shade100,
                ),
                padding: EdgeInsets.all(context.spacing),
                child: _rowLabelValue(
                  context,
                  'A Partir de:',
                  _valueText(
                    context,
                    empleadoCargoDetalle.fechaInicio != null
                        ? FechaUtils.formatDate(empleadoCargoDetalle.fechaInicio!)
                        : 'Sin registros',
                    color: empleadoCargoDetalle.fechaInicio == null ? Colors.red : null,
                  ),
                ),
              ),
            ],
            // FOOTER CON BOTÓN PARA VER HISTORIAL (SOLO MOBILE)
            if (isMobile && !_isEditingCargo && !_isAddingNewCargo) ...[
              SizedBox(height: context.spacing),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.history),
                  label: const Text('Ver Historial'),
                  onPressed: () => _showHistorialCargosDialog(context, historialCargosAsync),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Cambios principales para detalle_informacion_laboral.dart

// ╔════════════════════════════════════════════════════════════════╗
// ║ 1. DIALOG ADAPTATIVO - Historial Cargos
// ╚════════════════════════════════════════════════════════════════╝

void _showHistorialCargosDialog(
  BuildContext context,
  AsyncValue<List<EmpleadoEntity>> historialCargosAsync,
) {
  showDialog(
    context: context,
    builder: (dialogContext) {
      return historialCargosAsync.when(
        loading: () => Dialog(
          shape: RoundedRectangleBorder(borderRadius: context.borderRadius),
          child: Padding(
            padding: EdgeInsets.all(context.spacing),
            child: const CircularProgressIndicator(),
          ),
        ),
        error: (err, _) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: context.borderRadius),
          child: Padding(
            padding: EdgeInsets.all(context.spacing),
            child: Text('Error: $err'),
          ),
        ),
        data: (cargosHistorial) {
          // Calcular altura dinámica: base 100 + 180 por cada registro
          final dynamicHeight = cargosHistorial.isEmpty
              ? 150.0
              : 180.0 + (cargosHistorial.length * 200.0);
          final constrainedHeight =
              dynamicHeight > MediaQuery.of(context).size.height * 0.8
                  ? MediaQuery.of(context).size.height * 0.8
                  : dynamicHeight;

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: context.borderRadius),
            child: SizedBox(
              height: constrainedHeight,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.all(context.spacing),
                    child: Row(
                      children: [
                        Expanded(
                          child: _sectionHeader(
                            context,
                            'Historial de Cargos',
                            Icons.history,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(dialogContext),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1),
                  Expanded(
                    child: cargosHistorial.isEmpty
                        ? Center(
                            child: Padding(
                              padding: EdgeInsets.all(context.spacing),
                              child: Text(
                                'Sin historial de cargos',
                                style: TextStyle(color: Colors.grey.shade500),
                              ),
                            ),
                          )
                        : SingleChildScrollView(
                            padding: EdgeInsets.all(context.spacing),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ...cargosHistorial.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final empleadoEntity = entry.value;
                                  final empleadoCargo = empleadoEntity.empleadoCargo;
                                  final cargo = empleadoCargo.cargoSucursal?.cargo;

                                  final descripcionCargoInterno =
                                      cargo?.descripcion ?? 'N/A';
                                  final empresaInterno =
                                      empleadoCargo.cargoSucursal?.sucursal?.empresa.nombre ??
                                          'N/A';
                                  final sucursalInterno =
                                      empleadoCargo.cargoSucursal?.sucursal?.nombre ?? 'N/A';

                                  final cargoPlanilla =
                                      empleadoCargo.cargoPlanilla?.isNotEmpty == true
                                          ? empleadoCargo.cargoPlanilla
                                          : cargo?.descripcionPlanilla ?? 'N/A';
                                  final empresaPlanilla =
                                      cargo?.nombreEmpresaPlanilla ?? 'N/A';
                                  final sucursalPlanilla = empleadoCargo
                                          .cargoSucursal?.sucursal?.nombrePlanilla ??
                                      'N/A';

                                  final fechaInicio = empleadoCargo.fechaInicio != null
                                      ? FechaUtils.formatDate(empleadoCargo.fechaInicio!)
                                      : 'Sin registros';

                                  return Card(
                                    margin:
                                        EdgeInsets.only(bottom: context.spacing),
                                    child: Padding(
                                      padding: EdgeInsets.all(context.spacing),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            fechaInicio,
                                            style: context.bodyStyle.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: Colors.blue.shade700,
                                            ),
                                          ),
                                          SizedBox(height: context.smallSpacing),
                                          Container(
                                            decoration: BoxDecoration(
                                              border: Border(
                                                left: BorderSide(
                                                  color: Colors.blue.shade600,
                                                  width: 3,
                                                ),
                                              ),
                                              color: Colors.blue.shade50,
                                            ),
                                            padding: EdgeInsets.all(
                                              context.smallSpacing,
                                            ),
                                            margin: EdgeInsets.only(
                                              bottom: context.smallSpacing,
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Cargo Interno',
                                                  style: context.bodyStyle.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 11,
                                                    color: Colors.blue.shade700,
                                                  ),
                                                ),
                                                Text(
                                                  descripcionCargoInterno,
                                                  style: context.bodyStyle.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                Text(
                                                  '$empresaInterno • $sucursalInterno',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            decoration: BoxDecoration(
                                              border: Border(
                                                left: BorderSide(
                                                  color: Colors.orange.shade600,
                                                  width: 3,
                                                ),
                                              ),
                                              color: Colors.orange.shade50,
                                            ),
                                            padding: EdgeInsets.all(
                                              context.smallSpacing,
                                            ),
                                            margin: EdgeInsets.only(
                                              bottom: context.smallSpacing,
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Cargo Planilla',
                                                  style: context.bodyStyle.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 11,
                                                    color: Colors.orange.shade700,
                                                  ),
                                                ),
                                                Text(
                                                  cargoPlanilla,
                                                  style: context.bodyStyle.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                Text(
                                                  '$empresaPlanilla • $sucursalPlanilla',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(height: context.smallSpacing),
                                         SizedBox(
  width: double.infinity,
  child: PermissionWidget(
    buttonName: 'btnEliminarCargoHistorial',
    child: TextButton.icon(
      icon: const Icon(Icons.delete_outline),
      label: const Text('Eliminar'),
      onPressed: () async {
        Navigator.pop(dialogContext);
        await _deleteEmpleadoCargo(
          widget.codEmpleado,
          empleadoCargo.codCargoSucursal,
          empleadoCargo.codCargoSucPlanilla,
          empleadoCargo.fechaInicio ?? DateTime.now(),
        );
        // Volver a abrir dialog después de eliminar
        if (mounted) {
          final updatedAsync = ref.watch(
            getHistorialCargosEmpleado(
              widget.codEmpleado,
            ),
          );
          _showHistorialCargosDialog(
            context,
            updatedAsync,
          );
        }
      },
      style: TextButton.styleFrom(
        foregroundColor: Colors.red,
      ),
    ),
  ),
),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

  // ╔════════════════════════════════════════════════════════════════╗
  // ║ CARD: RELACIÓN LABORAL (CON AGRUPACIÓN Y FOOTER)
  // ╚════════════════════════════════════════════════════════════════╝

  Widget _buildRelacionLaboralCard(
    BuildContext context,
    String estado,
    String fechaIniStr,
    bool fechaIniMissing,
    String fechaInicioBeneficioStr,
    bool fechaInicioBeneficioMissing,
    String fechaInicioPlanillaStr,
    bool fechaInicioPlanillaMissing,
    RelacionLaboralEntity relacion,
    bool empleadoActivo,
    int audUsuario,
    AsyncValue<List<RelacionLaboralEntity>> historialRelLabAsync,
    bool isMobile,
  ) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: context.borderRadius),
      margin: EdgeInsets.symmetric(vertical: context.spacing),
      child: Padding(
        padding: EdgeInsets.all(context.spacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _sectionHeader(context, 'Relación Laboral', Icons.link),
                ),
                if (empleadoActivo)
                  IconButton(
                    icon: Icon(
                      _isEditing ? Icons.close : Icons.edit_outlined,
                      color: Colors.blueGrey,
                    ),
                    onPressed: (!empleadoActivo || _isAddingNewRelacion || _isAddingNewHistorial)
                        ? null
                        : () => setState(() => _isEditing = !_isEditing),
                  ),
                if (!empleadoActivo)
                  TextButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar'),
                    onPressed: _isAddingNewRelacion
                        ? null
                        : () => setState(() => _isAddingNewRelacion = true),
                  ),
              ],
            ),
            SizedBox(height: context.spacing),
            if (_isEditing)
              FormRelacionLaboral(
                relacionInicial: relacion,
                codEmpleado: widget.codEmpleado,
                audUsuario: audUsuario,
                onSave: (rel) => _saveToServer(rel, validar: true, esHistorial: false),
                onCancel: () => setState(() => _isEditing = false),
              ),
            if (_isAddingNewRelacion && !empleadoActivo)
              _buildAgregarRelacionForm(context, relacion, audUsuario),
            if (!_isEditing && !_isAddingNewRelacion) ...[
              // GRUPO: INFORMACIÓN GENERAL
              Container(
                decoration: BoxDecoration(
                  border: Border(left: BorderSide(color: Colors.indigo.shade600, width: 4)),
                  color: Colors.indigo.shade50,
                ),
                padding: EdgeInsets.all(context.spacing),
                margin: EdgeInsets.only(bottom: context.spacing),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Información General',
                      style: context.bodyStyle.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo.shade700,
                      ),
                    ),
                    SizedBox(height: context.smallSpacing),
                    _rowLabelValue(context, 'Estado:', _valueText(context, estado)),
                    _rowLabelValue(
                      context,
                      'Tipo Relación:',
                      DisplayValue<TipoRelacionLaboralEntity>(
                        code: relacion.tipoRel,
                        provider: getTipoRelacionLaboral,
                        getCode: (tipo) => tipo.codTipos,
                        getDescription: (tipo) => tipo.nombre,
                        fallback: relacion.tipoRel,
                      ),
                    ),
                    _rowLabelValue(
                      context,
                      'Inicio Funciones:',
                      _valueText(
                        context,
                        fechaIniStr,
                        color: fechaIniMissing ? Colors.red : null,
                      ),
                    ),
                    if (relacion.esActivo == 0) ...[
                      _rowLabelValue(
                        context,
                        'Fin Funciones:',
                        _valueText(
                          context,
                          relacion.fechaFin != null
                              ? FechaUtils.formatDate(relacion.fechaFin!)
                              : '',
                        ),
                      ),
                      _rowLabelValue(
                        context,
                        'Motivo:',
                        _valueText(context, relacion.motivoFin),
                      ),
                    ],
                  ],
                ),
              ),
              // GRUPO: FECHAS DE BENEFICIOS Y NÓMINA
              Container(
                decoration: BoxDecoration(
                  border: Border(left: BorderSide(color: Colors.teal.shade600, width: 4)),
                  color: Colors.teal.shade50,
                ),
                padding: EdgeInsets.all(context.spacing),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fecha inicio beneficio',
                      style: context.bodyStyle.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade700,
                      ),
                    ),
                    SizedBox(height: context.smallSpacing),
                    _rowLabelValue(
                      context,
                      'Inicio Beneficio:',
                      _valueText(
                        context,
                        fechaInicioBeneficioStr,
                        color: fechaInicioBeneficioMissing ? Colors.red : null,
                      ),
                    ),
                    _rowLabelValue(
                      context,
                      'Inicio Planilla:',
                      _valueText(
                        context,
                        fechaInicioPlanillaStr,
                        color: fechaInicioPlanillaMissing ? Colors.red : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // FOOTER CON BOTÓN PARA VER HISTORIAL (SOLO MOBILE)
            if (isMobile && !_isEditing && !_isAddingNewRelacion) ...[
              SizedBox(height: context.spacing),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.history),
                  label: const Text('Ver Historial'),
                  onPressed: () =>
                      _showHistorialRelacionesDialog(context, historialRelLabAsync, relacion),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ╔════════════════════════════════════════════════════════════════╗
// ║ 2. DIALOG ADAPTATIVO - Historial Relaciones (MISMO PATRÓN)
// ╚════════════════════════════════════════════════════════════════╝

void _showHistorialRelacionesDialog(
  BuildContext context,
  AsyncValue<List<RelacionLaboralEntity>> historialRelLabAsync,
  RelacionLaboralEntity relacion,
) {
  showDialog(
    context: context,
    builder: (dialogContext) {
      return historialRelLabAsync.when(
        loading: () => Dialog(
          shape: RoundedRectangleBorder(borderRadius: context.borderRadius),
          child: Padding(
            padding: EdgeInsets.all(context.spacing),
            child: const CircularProgressIndicator(),
          ),
        ),
        error: (err, _) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: context.borderRadius),
          child: Padding(
            padding: EdgeInsets.all(context.spacing),
            child: Text('Error: $err'),
          ),
        ),
        data: (historialRelLab) {
          // Calcular altura dinámica
          final dynamicHeight = historialRelLab.isEmpty
              ? 150.0
              : 180.0 + (historialRelLab.length * 150.0);
          final constrainedHeight =
              dynamicHeight > MediaQuery.of(context).size.height * 0.8
                  ? MediaQuery.of(context).size.height * 0.8
                  : dynamicHeight;

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: context.borderRadius),
            child: SizedBox(
              height: constrainedHeight,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.all(context.spacing),
                    child: Row(
                      children: [
                        Expanded(
                          child: _sectionHeader(
                            context,
                            'Historial de Relaciones',
                            Icons.history,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(dialogContext),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1),
                  Expanded(
                    child: historialRelLab.isEmpty
                        ? Center(
                            child: Padding(
                              padding: EdgeInsets.all(context.spacing),
                              child: Text(
                                'Sin historial de relaciones',
                                style: TextStyle(color: Colors.grey.shade500),
                              ),
                            ),
                          )
                        : SingleChildScrollView(
                            padding: EdgeInsets.all(context.spacing),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ...historialRelLab.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final rel = entry.value;

                                  final fechaIni = rel.fechaIni != null
                                      ? FechaUtils.formatDate(rel.fechaIni!)
                                      : 'Sin registros';
                                  final fechaFin = rel.fechaFin != null
                                      ? FechaUtils.formatDate(rel.fechaFin!)
                                      : '-';
                                  final estado =
                                      rel.esActivo == 1 ? 'Activo' : 'Inactivo';
                                  final motivoFin = _str(rel.motivoFin, '-');

                                  return Card(
                                    margin:
                                        EdgeInsets.only(bottom: context.spacing),
                                    child: Padding(
                                      padding: EdgeInsets.all(context.spacing),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Inicio',
                                                      style: context.bodyStyle
                                                          .copyWith(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 10,
                                                        color: Colors
                                                            .grey.shade600,
                                                      ),
                                                    ),
                                                    Text(
                                                      fechaIni,
                                                      style: context.bodyStyle
                                                          .copyWith(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: Colors
                                                            .blue.shade700,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Fin',
                                                      style: context.bodyStyle
                                                          .copyWith(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 10,
                                                        color: Colors
                                                            .grey.shade600,
                                                      ),
                                                    ),
                                                    Text(
                                                      fechaFin,
                                                      style: context.bodyStyle
                                                          .copyWith(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(
                                            height: context.smallSpacing,
                                          ),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Estado',
                                                      style: context.bodyStyle
                                                          .copyWith(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 10,
                                                        color: Colors
                                                            .grey.shade600,
                                                      ),
                                                    ),
                                                    Text(
                                                      estado,
                                                      style: context.bodyStyle
                                                          .copyWith(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: rel.esActivo == 1
                                                            ? Colors.green
                                                                .shade700
                                                            : Colors.orange
                                                                .shade700,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Motivo',
                                                      style: context.bodyStyle
                                                          .copyWith(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 10,
                                                        color: Colors
                                                            .grey.shade600,
                                                      ),
                                                    ),
                                                    Text(
                                                      motivoFin,
                                                      style: context.bodyStyle
                                                          .copyWith(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 10,
                                                      ),
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(
                                            height: context.smallSpacing,
                                          ),
SizedBox(
  width: double.infinity,
  child: PermissionWidget(
    buttonName: 'btnEliminarRelLabHistorial',
    child: TextButton.icon(
      icon: const Icon(Icons.delete_outline),
      label: const Text('Eliminar'),
      onPressed: () async {
        Navigator.pop(dialogContext);
        await _deleteRelacion(
          rel.codRelEmplEmpr,
        );
        // Volver a abrir dialog después de eliminar
        if (mounted) {
          final updatedAsync = ref.watch(
            getHistorialRelLabEmpleado(
              widget.codEmpleado,
            ),
          );
          _showHistorialRelacionesDialog(
            context,
            updatedAsync,
            relacion,
          );
        }
      },
      style: TextButton.styleFrom(
        foregroundColor: Colors.red,
      ),
    ),
  ),
),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

  // ╔════════════════════════════════════════════════════════════════╗
  // ║ CARD: HISTORIAL CARGOS (WEB ONLY)
  // ╚════════════════════════════════════════════════════════════════╝

  Widget _buildHistorialCargosCard(
    BuildContext context,
    AsyncValue<List<EmpleadoEntity>> historialCargosAsync,
    bool isMobile,
  ) {
    if (isMobile) return const SizedBox.shrink();

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: context.borderRadius),
      margin: EdgeInsets.symmetric(vertical: context.spacing),
      child: Padding(
        padding: EdgeInsets.all(context.spacing),
        child: historialCargosAsync.when(
          loading: () => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader(context, 'Historial de Cargos', Icons.history),
              SizedBox(height: context.spacing),
              const LinearProgressIndicator(minHeight: 2),
            ],
          ),
          error: (err, stack) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader(context, 'Historial de Cargos', Icons.history),
              SizedBox(height: context.spacing),
              Text(
                'Error al cargar',
                style: TextStyle(color: Colors.red.shade300, fontSize: 12),
              ),
            ],
          ),
          data: (cargosHistorial) {
            if (cargosHistorial.isEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader(context, 'Historial de Cargos', Icons.history),
                  SizedBox(height: context.spacing),
                  Text(
                    'Sin historial',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _sectionHeader(context, 'Historial de Cargos', Icons.history),
                SizedBox(height: context.spacing),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 400),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildTableHeader(
                          context,
                          ['Fecha', 'Cargo Interno', 'Cargo Planilla', ''],
                          [1, 2, 2, 0.5],
                        ),
                        ...cargosHistorial.asMap().entries.map((entry) {
                          final index = entry.key;
                          final empleadoEntity = entry.value;
                          final empleadoCargo = empleadoEntity.empleadoCargo;
                          final cargo = empleadoCargo.cargoSucursal?.cargo;

                          final descripcionCargoInterno = cargo?.descripcion ?? 'N/A';
                          final empresaInterno =
                              empleadoCargo.cargoSucursal?.sucursal?.empresa.nombre ?? 'N/A';
                          final sucursalInterno =
                              empleadoCargo.cargoSucursal?.sucursal?.nombre ?? 'N/A';

                          final cargoPlanilla = empleadoCargo.cargoPlanilla?.isNotEmpty == true
                              ? empleadoCargo.cargoPlanilla
                              : cargo?.descripcionPlanilla ?? 'N/A';
                          final empresaPlanilla = cargo?.nombreEmpresaPlanilla ?? 'N/A';
                          final sucursalPlanilla =
                              empleadoCargo.cargoSucursal?.sucursal?.nombrePlanilla ?? 'N/A';

                          final fechaInicio = empleadoCargo.fechaInicio != null
                              ? FechaUtils.formatDate(empleadoCargo.fechaInicio!)
                              : 'Sin registros';

                          final isLast = index == cargosHistorial.length - 1;

                          return _buildTableRow(
                            context,
                            isLast,
                            [
                              Text(
                                fechaInicio,
                                style: context.bodyStyle.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    descripcionCargoInterno,
                                    style: context.bodyStyle.copyWith(fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '$empresaInterno • $sucursalInterno',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cargoPlanilla,
                                    style: context.bodyStyle.copyWith(fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '$empresaPlanilla • $sucursalPlanilla',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
PermissionWidget(
  buttonName: 'btnEliminarCargoHistorial',
  child: GestureDetector(
    onTap: () => _deleteEmpleadoCargo(
      widget.codEmpleado,
      empleadoCargo.codCargoSucursal,
      empleadoCargo.codCargoSucPlanilla,
      empleadoCargo.fechaInicio ?? DateTime.now(),
    ),
    child: Icon(
      Icons.delete_outline,
      size: context.smallIconSize,
      color: Colors.red.shade600,
    ),
  ),
),
                            ],
                            [1, 2, 2, 0.5],
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ╔════════════════════════════════════════════════════════════════╗
  // ║ CARD: HISTORIAL RELACIONES (WEB ONLY)
  // ╚════════════════════════════════════════════════════════════════╝

  Widget _buildHistorialRelacionesCard(
    BuildContext context,
    AsyncValue<List<RelacionLaboralEntity>> historialRelLabAsync,
    RelacionLaboralEntity relacion,
    int audUsuario,
    bool isMobile,
  ) {
    if (isMobile) return const SizedBox.shrink();

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: context.borderRadius),
      margin: EdgeInsets.symmetric(vertical: context.spacing),
      child: Padding(
        padding: EdgeInsets.all(context.spacing),
        child: historialRelLabAsync.when(
          loading: () => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader(context, 'Historial de Relaciones', Icons.history),
              SizedBox(height: context.spacing),
              const LinearProgressIndicator(minHeight: 2),
            ],
          ),
          error: (err, stack) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader(context, 'Historial de Relaciones', Icons.history),
              SizedBox(height: context.spacing),
              Text(
                'Error al cargar',
                style: TextStyle(color: Colors.red.shade300, fontSize: 12),
              ),
            ],
          ),
          data: (historialRelLab) {
            if (historialRelLab.isEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader(context, 'Historial de Relaciones', Icons.history),
                  SizedBox(height: context.spacing),
                  Text(
                    'Sin historial',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _sectionHeader(context, 'Historial de Relaciones', Icons.history),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar'),
                      onPressed: () => setState(() => _isAddingNewHistorial = true),
                    ),
                  ],
                ),
                SizedBox(height: context.spacing),
                if (_isAddingNewHistorial)
                  Padding(
                    padding: EdgeInsets.only(bottom: context.spacing),
                    child: FormRelacionLaboral(
                      relacionInicial: RelacionLaboralEntity(
                        codRelEmplEmpr: 0,
                        codEmpleado: widget.codEmpleado,
                        esActivo: 0,
                        tipoRel: '',
                        nombreFileContrato: '',
                        fechaIni: relacion.fechaIni ?? DateTime.now(),
                        fechaFin: relacion.fechaFin,
                        motivoFin: '',
                        audUsuario: 0,
                        fechaInicioBeneficio: null,
                        fechaInicioPlanilla: null,
                        datoFechasBeneficio: null,
                        cargo: '',
                        sucursal: '',
                        empresaFiscal: '',
                        empresaInterna: '',
                      ),
                      codEmpleado: widget.codEmpleado,
                      audUsuario: 0,
                      forceInactivo: true,
                      onSave: (rel) => _saveToServer(rel, validar: true, esHistorial: true),
                      onCancel: () => setState(() => _isAddingNewHistorial = false),
                    ),
                  ),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 400),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildTableHeader(
                          context,
                          ['Fecha Ini', 'Fecha Fin', 'Estado', 'Motivo', ''],
                          [1, 1, 0.8, 1.5, 0.5],
                        ),
                        ...historialRelLab.asMap().entries.map((entry) {
                          final index = entry.key;
                          final rel = entry.value;

                          final fechaIni = rel.fechaIni != null
                              ? FechaUtils.formatDate(rel.fechaIni!)
                              : 'Sin registros';
                          final fechaFin =
                              rel.fechaFin != null ? FechaUtils.formatDate(rel.fechaFin!) : '-';
                          final estado = rel.esActivo == 1 ? 'Activo' : 'Inactivo';
                          final motivoFin = _str(rel.motivoFin, '-');

                          final isLast = index == historialRelLab.length - 1;

                          return _buildTableRow(
                            context,
                            isLast,
                            [
                              Text(
                                fechaIni,
                                style: context.bodyStyle.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                              Text(
                                fechaFin,
                                style: context.bodyStyle.copyWith(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                estado,
                                style: context.bodyStyle.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: rel.esActivo == 1
                                      ? Colors.green.shade700
                                      : Colors.orange.shade700,
                                ),
                              ),
                              Text(
                                motivoFin,
                                style: context.bodyStyle.copyWith(fontSize: 10),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
PermissionWidget(
  buttonName: 'btnEliminarRelLabHistorial',
  child: GestureDetector(
    onTap: () => _deleteRelacion(rel.codRelEmplEmpr),
    child: Icon(
      Icons.delete_outline,
      size: context.smallIconSize,
      color: Colors.red.shade600,
    ),
  ),
),
                            ],
                            [1, 1, 0.8, 1.5, 0.5],
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAgregarRelacionForm(
    BuildContext context,
    RelacionLaboralEntity relacion,
    int audUsuario,
  ) {
    return FormRelacionConCargo(
      codEmpleado: widget.codEmpleado,
      audUsuario: audUsuario,
      onSave: (rel, cargoInterno, cargoPlanilla) async {
        await executeABM(
          ref: ref,
          context: context,
          successMessage: 'Relación y cargo guardados',
          providersToInvalidate: [
            getHistorialCargosEmpleado(widget.codEmpleado),
            cargoActualEmpleadoProvider(widget.codEmpleado),
            getHistorialRelLabEmpleado(widget.codEmpleado),
            detalleEmpleadoProvider(widget.codEmpleado),
            obtenerUltimaRelacionLaboralProvider(widget.codEmpleado),
            getListaEmpleados
          ],
          operation: () async {
            await validarFechaRelacionYCargo(
              fechaRelacionText: FechaUtils.formatDate(rel.fechaIni!),
              fechaCargoText: FechaUtils.formatDate(rel.fechaIni!),
              ref: ref,
              codEmpleado: widget.codEmpleado,
            );
            final repo = RegistroEmpleadoImpl();
            await repo.registrarRelacionLaboral(rel, validar: true);
            ref.invalidate(obtenerUltimaRelacionLaboralProvider(widget.codEmpleado));

            final relacionGuardada =
                await ref.read(obtenerUltimaRelacionLaboralProvider(widget.codEmpleado).future);
            final int codRelEmplEmprGuardado = relacionGuardada.codRelEmplEmpr;

            await ref.read(
              registrarEmpleadoCargoProvider(
                EmpleadoCargoEntity(
                  codEmpleado: widget.codEmpleado,
                  codCargoSucursal: cargoInterno.codCargoSucursal,
                  codCargoSucPlanilla: cargoPlanilla.codCargoSucursal,
                  fechaInicio: rel.fechaIni,
                  audUsuario: audUsuario,
                  cargoPlanilla: '',
                  existe: 0,
                ),
              ).future,
            );

            final empleado = ref.read(detalleEmpleadoProvider(widget.codEmpleado)).value;
            if (empleado == null) throw Exception('No se pudo obtener el empleado');

            final empleadoActualizado = empleado.copyWith(
              codRelBeneficios: codRelEmplEmprGuardado,
              codRelPlanilla: codRelEmplEmprGuardado,
            );

            await ref.read(registrarEmpleadoProvider(empleadoActualizado).future);
          },
        );

        if (mounted) setState(() => _isAddingNewRelacion = false);
      },
      onCancel: () => setState(() => _isAddingNewRelacion = false),
    );
  }

  Widget _buildTableHeader(BuildContext context, List<String> labels, List<double> flexes) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: context.spacing, vertical: context.smallSpacing),
      child: Row(
        children: [
          for (int i = 0; i < labels.length; i++)
            Expanded(
              flex: (flexes[i] * 10).toInt(),
              child: Text(
                labels[i],
                style: context.bodyStyle.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTableRow(
    BuildContext context,
    bool isLast,
    List<Widget> cells,
    List<double> flexes,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        borderRadius: isLast
            ? BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              )
            : BorderRadius.zero,
      ),
      padding: EdgeInsets.symmetric(horizontal: context.spacing, vertical: context.smallSpacing),
      child: Row(
        children: [
          for (int i = 0; i < cells.length; i++)
            Expanded(
              flex: (flexes[i] * 10).toInt(),
              child: cells[i],
            ),
        ],
      ),
    );
  }

  Future<void> _deleteEmpleadoCargo(
    int codEmpleado,
    int codCargoSucursal,
    int codCargoSucPlanilla,
    DateTime fechaInicio,
  ) async {
    await executeABM(
      ref: ref,
      context: context,
      requireConfirmation: true,
      confirmationTitle: 'Eliminar',
      confirmationMessage: 'Está seguro de eliminar este cargo?',
      operation: () => ref.read(
        eliminarEmpleadoCargo((
          codEmpleado,
          codCargoSucursal,
          fechaInicio,
          codCargoSucPlanilla,
        )).future,
      ),
      providersToInvalidate: [
        relacionLaboralProvider(widget.codEmpleado),
        detalleEmpleadoProvider(widget.codEmpleado),
        cargoActualEmpleadoProvider(widget.codEmpleado),
        getHistorialCargosEmpleado(widget.codEmpleado),
        getHistorialRelLabEmpleado(widget.codEmpleado),
      ],
      successMessage: 'Cargo eliminado',
    );
  }

  Future<void> _deleteRelacion(int codRelEmplEmpr) async {
    await executeABM(
      ref: ref,
      context: context,
      requireConfirmation: true,
      confirmationTitle: 'Eliminar',
      confirmationMessage: 'Está seguro? No se puede deshacer.',
      operation: () => ref.read(eliminarRelacionLaboral(codRelEmplEmpr).future),
      providersToInvalidate: [
        relacionLaboralProvider(widget.codEmpleado),
        detalleEmpleadoProvider(widget.codEmpleado),
        cargoActualEmpleadoProvider(widget.codEmpleado),
        getHistorialRelLabEmpleado(widget.codEmpleado),
      ],
      successMessage: 'Relación eliminada',
    );
  }

  Widget _buildAddCargoButton(BuildContext context, bool empleadoActivo) {
    if (!empleadoActivo) {
      return PermissionWidget(
        buttonName: 'btnEditarCargoEmpleado',
        placeholder: const SizedBox.shrink(),
        child: IconButton(
          icon: Icon(
            _isEditingCargo ? Icons.close : Icons.edit_outlined,
            color: Colors.blueGrey,
          ),
          onPressed: _isAddingNewCargo
              ? null
              : () => setState(() => _isEditingCargo = !_isEditingCargo),
        ),
      );
    }

    return TextButton.icon(
      icon: const Icon(Icons.add),
      label: const Text('Agregar'),
      onPressed: (_isAddingNewCargo || _isEditingCargo)
          ? null
          : () => setState(() => _isAddingNewCargo = true),
    );
  }
}

// ╔════════════════════════════════════════════════════════════════╗
// ║ FORMULARIO EDIT CARGO - DISEÑO UNIFICADO
// ╚════════════════════════════════════════════════════════════════╝

class _FormCargoEdit extends ConsumerStatefulWidget {
  final int codEmpleado;
  final int audUsuario;
  final DateTime? fechaInicio;
  final VoidCallback onCancel;

  const _FormCargoEdit({
    required this.codEmpleado,
    required this.audUsuario,
    required this.fechaInicio,
    required this.onCancel,
  });

  @override
  ConsumerState<_FormCargoEdit> createState() => _FormCargoEditState();
}

class _FormCargoEditState extends ConsumerState<_FormCargoEdit> {
  int? _codCargoInternoId;
  int? _codCargoPlanillaId;
  int? _codEmpresaPlanilla;
  
  EmpleadoEntity? _selectedInterno;
  EmpleadoEntity? _selectedPlanilla;

  DateTime? _fechaInicioSelected;
  DateTime? _fechaInicioOriginal;
  late TextEditingController _fechaController;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _fechaController = TextEditingController();
  }

  @override
  void dispose() {
    _fechaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detalleAsync = ref.watch(detalleEmpleadoProvider(widget.codEmpleado));

    return detalleAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error: $e'),
      data: (empleado) {
        if (!_initialized) _precargarDatos(empleado);
        final esEmpleadoActivo = empleado.relEmpEmpr.esActivo == 1;
        
        return Form(
          child: Container(
            margin: EdgeInsets.only(bottom: context.smallSpacing),
            padding: EdgeInsets.all(context.spacing),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.03),
              borderRadius: context.borderRadius,
              border: Border.all(
                color: Theme.of(context).primaryColor.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: context.isMobile
                ? _buildMobileLayout(context, esEmpleadoActivo)
                : _buildWebLayout(context, esEmpleadoActivo),
          ),
        );
      },
    );
  }

  void _precargarDatos(EmpleadoEntity empleado) {
    final ec = empleado.empleadoCargo;
    final cargoSuc = ec.cargoSucursal;
    final cargo = cargoSuc?.cargo;

    _codCargoInternoId = cargoSuc?.codCargo;
    _codCargoPlanillaId = cargoSuc?.codCargoSucursal;
    _codEmpresaPlanilla = cargo?.codEmpresaPlanilla;

    _selectedInterno = empleado;
    _selectedPlanilla = empleado;

    _fechaInicioSelected = widget.fechaInicio ?? ec.fechaInicio;
    _fechaInicioOriginal = widget.fechaInicio ?? ec.fechaInicio;
    if (_fechaInicioSelected != null) {
      _fechaController.text = FechaUtils.formatDate(_fechaInicioSelected!);
    }

    console('📌 PRELOAD SEPARADO:');
    console('   INTERNO - codCargoSucursal: $_codCargoInternoId');
    console('   PLANILLA - codCargoSucursal: $_codCargoPlanillaId');
    console('   Empresa Planilla: $_codEmpresaPlanilla');
    _initialized = true;
  }

  Widget _buildMobileLayout(BuildContext context, bool esEmpleadoActivo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildCargoInternoDropdown(),
        SizedBox(height: context.spacing),
        _buildEmpresaPlanillaDropdown(),
        SizedBox(height: context.spacing),
        _buildCargoPlanillaDropdown(),
        SizedBox(height: context.spacing),
        _buildFechaSection(context, esEmpleadoActivo),
        SizedBox(height: context.largeSpacing),
        _buildActionButtons(context),
      ],
    );
  }

  Widget _buildWebLayout(BuildContext context, bool esEmpleadoActivo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Fila 1: Cargo Interno
        _buildCargoInternoDropdown(),
        SizedBox(height: context.spacing),
        // Fila 2: Empresa y Cargo Planilla
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildEmpresaPlanillaDropdown()),
            SizedBox(width: context.spacing),
            Expanded(child: _buildCargoPlanillaDropdown()),
          ],
        ),
        SizedBox(height: context.spacing),
        // Fila 3: Fecha y Botones
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildFechaSection(context, esEmpleadoActivo)),
            SizedBox(width: context.spacing),
            SizedBox(
              width: 240,
              child: _buildActionButtonsHorizontal(context),
            ),
          ],
        ),
      ],
    );
  }

Widget _buildCargoInternoDropdown() {
  return Row(
    children: [
      Expanded(
        child: DropdownSearch<EmpleadoEntity>(
          asyncItems: (text) async {
            final items = await ref.read(getCargoXEmpresa((text, 6)).future);
            // final seen = <int>{};
            // final deduplicated = items.where((e) {
            //   final codCargo = e.empleadoCargo.cargoSucursal?.codCargo;
            //   if (codCargo == null) return false;
            //   return seen.add(codCargo);
            // }).toList();
            // console('📊 ADD INTERNO - Items: ${items.length} → ${deduplicated.length}');
            // return deduplicated;
            return items;
          },
          selectedItem: _selectedInterno,
          itemAsString: (e) => _formatCargoLabel(e, tipo: 'interno'),
          dropdownDecoratorProps: DropDownDecoratorProps(
            dropdownSearchDecoration: InputDecoration(
              labelText: 'Cargo Interno *',
              hintText: 'Seleccione cargo',
              labelStyle: TextStyle(fontSize: context.bodyFontSize),
              hintStyle: context.bodyLightStyle,
              border: OutlineInputBorder(borderRadius: context.borderRadius),
              contentPadding: EdgeInsets.symmetric(
                horizontal: context.smallSpacing,
                vertical: context.spacing,
              ),
              isDense: true,
            ),
          ),
          onChanged: (val) {
            final newId = val?.empleadoCargo.cargoSucursal?.codCargoSucursal;
            console('🔵 INTERNO CHANGED: $_codCargoInternoId → $newId');
            setState(() {
              _codCargoInternoId = newId;
              _selectedInterno = val;
            });
          },
          popupProps: const PopupProps.menu(showSearchBox: true, searchDelay: Duration(milliseconds: 300)),
          validator: (val) => val == null ? 'Requerido' : null,
        ),
      ),
      SizedBox(width: context.smallSpacing),
      CargoNavigationButton(
        empresaId: _selectedInterno?.empleadoCargo.cargoSucursal?.cargo?.codEmpresa,
        empresaNombre: _selectedInterno?.empleadoCargo.cargoSucursal?.sucursal?.empresa.nombre,
          ref: ref, // ✅ AGREGAR
      ),
    ],
  );
}

  Widget _buildEmpresaPlanillaDropdown() {
    final empresasAsync = ref.watch(empresasProvider);
    return empresasAsync.when(
      loading: () => const LinearProgressIndicator(minHeight: 2),
      error: (e, _) => Text('Error: $e', style: context.bodyLightStyle),
      data: (empresas) {
        final filtered = empresas.where((e) => e.codEmpresa != -1).toList();
        return DropdownButtonFormField<int>(
          value: _codEmpresaPlanilla,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Empresa Planilla *',
            hintText: 'Seleccione empresa',
            labelStyle: TextStyle(fontSize: context.bodyFontSize),
            border: OutlineInputBorder(borderRadius: context.borderRadius),
            contentPadding: EdgeInsets.symmetric(
              horizontal: context.smallSpacing,
              vertical: context.spacing,
            ),
            isDense: true,
            filled: true,
            fillColor: Colors.white,
          ),
          items: filtered.map((e) => DropdownMenuItem(value: e.codEmpresa, child: Text(e.nombre))).toList(),
          onChanged: (val) {
            console('🟡 EMPRESA PLANILLA CHANGED: $_codEmpresaPlanilla → $val');
            setState(() {
              _codEmpresaPlanilla = val;
              _codCargoPlanillaId = null;
              _selectedPlanilla = null;
            });
          },
          validator: (val) => val == null ? 'Requerido' : null,
        );
      },
    );
  }

Widget _buildCargoPlanillaDropdown() {
  // Obtener el nombre de la empresa seleccionada
  final empresasAsync = ref.watch(empresasProvider);
  
  return empresasAsync.when(
    loading: () => const LinearProgressIndicator(minHeight: 2),
    error: (e, _) => Text('Error: $e', style: context.bodyLightStyle),
    data: (empresas) {
      final empresaSeleccionada = empresas.firstWhere(
        (e) => e.codEmpresa == _codEmpresaPlanilla,
        orElse: () => empresas.first,
      );

      return Row(
        children: [
          Expanded(
            child: DropdownSearch<EmpleadoEntity>(
              enabled: _codEmpresaPlanilla != null,
              asyncItems: (text) => ref.read(getCargoXEmpresa((text, _codEmpresaPlanilla)).future),
              selectedItem: _selectedPlanilla,
              itemAsString: (e) => _formatCargoLabel(e, tipo: 'planilla'),
              dropdownDecoratorProps: DropDownDecoratorProps(
                dropdownSearchDecoration: InputDecoration(
                  labelText: 'Cargo Planilla *',
                  hintText: _codEmpresaPlanilla == null ? 'Primero empresa' : 'Seleccione cargo',
                  labelStyle: TextStyle(fontSize: context.bodyFontSize),
                  hintStyle: context.bodyLightStyle,
                  border: OutlineInputBorder(borderRadius: context.borderRadius),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: context.smallSpacing,
                    vertical: context.spacing,
                  ),
                  isDense: true,
                ),
              ),
              onChanged: (val) {
                final newId = val?.empleadoCargo.cargoSucursal?.codCargoSucursal;
                console('🟠 PLANILLA CHANGED: $_codCargoPlanillaId → $newId');
                setState(() {
                  _codCargoPlanillaId = newId;
                  _selectedPlanilla = val;
                });
              },
              popupProps: const PopupProps.menu(showSearchBox: true),
              validator: (val) => val == null ? 'Requerido' : null,
            ),
          ),
          SizedBox(width: context.smallSpacing),
          CargoNavigationButton(
            empresaId: _codEmpresaPlanilla,
            empresaNombre: empresaSeleccionada.nombre,
              ref: ref, // ✅ AGREGAR
          ),
        ],
      );
    },
  );
}

  String _formatCargoLabel(EmpleadoEntity e, {required String tipo}) {
    final cargo = e.empleadoCargo.cargoSucursal?.cargo;
    final cargoSuc = e.empleadoCargo.cargoSucursal;

    if (tipo == 'interno') {
      final desc = cargo?.descripcion ?? cargoSuc?.datoCargo ?? 'N/A';
      final suc = cargo?.sucursal ?? 'N/A';
      return "$desc — $suc";
    } else {
      final desc = cargo?.descripcionPlanilla?.isNotEmpty == true
          ? cargo!.descripcionPlanilla
          : (cargo?.descripcion ?? cargoSuc?.datoCargo ?? 'N/A');
      final suc = cargo?.sucursalPlanilla?.isNotEmpty == true
          ? cargo!.sucursalPlanilla
          : (cargo?.sucursal ?? 'N/A');
      return "$desc — $suc";
    }
  }

  Widget _buildFechaSection(BuildContext context, bool esEmpleadoActivo) {
    final picker = CustomDatePicker(
      controller: _fechaController,
      label: 'A Partir de *',
      onDateSelected: (date) => setState(() => _fechaInicioSelected = date),
      validator: (val) => (val == null || val.isEmpty) ? 'Requerido' : null,
    );

    return esEmpleadoActivo
        ? picker
        : PermissionWidget(
            buttonName: 'btnEditarFechaInicioCargo',
            placeholder: IgnorePointer(child: Opacity(opacity: 0.6, child: picker)),
            child: picker,
          );
  }

  Widget _buildActionButtons(BuildContext context) {
    final canSave = _codCargoInternoId != null && _codCargoPlanillaId != null;
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: widget.onCancel,
          child: Text('Cancelar', style: context.bodyStyle),
        ),
        SizedBox(width: context.spacing),
        ElevatedButton.icon(
          icon: const Icon(Icons.save, size: 18),
          label: const Text('Guardar'),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(
              horizontal: context.spacing * 1.5,
              vertical: context.smallSpacing,
            ),
          ),
          onPressed: canSave ? () => _handleSave(context) : null,
        ),
      ],
    );
  }

  Widget _buildActionButtonsHorizontal(BuildContext context) {
    final canSave = _codCargoInternoId != null && _codCargoPlanillaId != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.save, size: 18),
          label: const Text('Guardar'),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: context.spacing),
          ),
          onPressed: canSave ? () => _handleSave(context) : null,
        ),
        SizedBox(height: context.smallSpacing),
        TextButton(
          onPressed: widget.onCancel,
          child: Text('Cancelar', style: context.bodyStyle),
        ),
      ],
    );
  }

  Future<void> _handleSave(BuildContext context) async {
    console('🔐 VALIDACIÓN FINAL ANTES DE GUARDAR:');
    console('   INTERNO - codCargoSucursal: $_codCargoInternoId');
    console('   PLANILLA - codCargoSucursal: $_codCargoPlanillaId');

    final payload = EmpleadoCargoEntity(
      codEmpleado: widget.codEmpleado,
      codCargoSucursal: _codCargoInternoId!,
      codCargoSucPlanilla: _codCargoPlanillaId!,
      fechaInicio: _fechaInicioSelected ?? DateTime.now(),
      fechaInicioOriginal: _fechaInicioOriginal,
      audUsuario: widget.audUsuario,
      cargoPlanilla: '',
      existe: 1,
    );

    console('✅ PAYLOAD FINAL: codCargoSucursal=$_codCargoInternoId, codCargoSucPlanilla=$_codCargoPlanillaId');

    final success= await executeABM(
      ref: ref,
      context: context,
      successMessage: 'Cargo actualizado correctamente',
      providersToInvalidate: [
        detalleEmpleadoProvider(widget.codEmpleado),
        getHistorialCargosEmpleado(widget.codEmpleado),
        cargoActualEmpleadoProvider(widget.codEmpleado),
        getListaEmpleados
      ],
      operation: () async {
        await validarCronologiaCargoUltimoRegistro(
          fechaCargoText: _fechaController.text,
          ref: ref,
          codEmpleado: widget.codEmpleado,
          fechaInicioOriginal: _fechaInicioOriginal,
        );
        await ref.read(registrarEmpleadoCargoProvider(payload).future);
      },
    );
    // ✅ Solo cierra si fue exitoso
    if (mounted && success) widget.onCancel();
  }
}

// ╔════════════════════════════════════════════════════════════════╗
// ║ FORMULARIO ADD CARGO - DISEÑO UNIFICADO + LÓGICA COMPLETA
// ╚════════════════════════════════════════════════════════════════╝

class _FormCargoAdd extends ConsumerStatefulWidget {
  final int codEmpleado;
  final int audUsuario;
  final VoidCallback onCancel;

  const _FormCargoAdd({
    required this.codEmpleado,
    required this.audUsuario,
    required this.onCancel,
  });

  @override
  ConsumerState<_FormCargoAdd> createState() => _FormCargoAddState();
}

class _FormCargoAddState extends ConsumerState<_FormCargoAdd> {
  int? _codCargoInternoId;
  int? _codCargoPlanillaId;
  int? _codEmpresaPlanilla;
  
  EmpleadoEntity? _selectedInterno;
  EmpleadoEntity? _selectedPlanilla;
  
  DateTime? _fechaInicioSelected = DateTime.now();
  late TextEditingController _fechaController;

  @override
  void initState() {
    super.initState();
    _fechaController = TextEditingController(text: FechaUtils.formatDate(DateTime.now()));
  }

  @override
  void dispose() {
    _fechaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      child: Container(
        margin: EdgeInsets.only(bottom: context.smallSpacing),
        padding: EdgeInsets.all(context.spacing),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.03),
          borderRadius: context.borderRadius,
          border: Border.all(
            color: Theme.of(context).primaryColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: context.isMobile
            ? _buildMobileLayout(context)
            : _buildWebLayout(context),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildCargoInternoDropdown(),
        SizedBox(height: context.spacing),
        _buildEmpresaPlanillaDropdown(),
        SizedBox(height: context.spacing),
        _buildCargoPlanillaDropdown(),
        SizedBox(height: context.spacing),
        _buildFechaSection(context),
        SizedBox(height: context.largeSpacing),
        _buildActionButtons(context),
      ],
    );
  }

  Widget _buildWebLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Fila 1: Cargo Interno
        _buildCargoInternoDropdown(),
        SizedBox(height: context.spacing),
        // Fila 2: Empresa y Cargo Planilla
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildEmpresaPlanillaDropdown()),
            SizedBox(width: context.spacing),
            Expanded(child: _buildCargoPlanillaDropdown()),
          ],
        ),
        SizedBox(height: context.spacing),
        // Fila 3: Fecha y Botones
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildFechaSection(context)),
            SizedBox(width: context.spacing),
            SizedBox(
              width: 240,
              child: _buildActionButtonsHorizontal(context),
            ),
          ],
        ),
      ],
    );
  }

Widget _buildCargoInternoDropdown() {
  return Row(
    children: [
      Expanded(
        child: DropdownSearch<EmpleadoEntity>(
          asyncItems: (text) async {
            final items = await ref.read(getCargoXEmpresa((text, 6)).future);
            // final seen = <int>{};
            // final deduplicated = items.where((e) {
            //   final codCargo = e.empleadoCargo.cargoSucursal?.codCargo;
            //   if (codCargo == null) return false;
            //   return seen.add(codCargo);
            // }).toList();
            // console('📊 ADD INTERNO - Items: ${items.length} → ${deduplicated.length}');
            // return deduplicated;
            return items;
          },
          selectedItem: _selectedInterno,
          itemAsString: (e) => _formatCargoLabel(e, tipo: 'interno'),
          dropdownDecoratorProps: DropDownDecoratorProps(
            dropdownSearchDecoration: InputDecoration(
              labelText: 'Cargo Interno *',
              hintText: 'Seleccione cargo',
              labelStyle: TextStyle(fontSize: context.bodyFontSize),
              hintStyle: context.bodyLightStyle,
              border: OutlineInputBorder(borderRadius: context.borderRadius),
              contentPadding: EdgeInsets.symmetric(
                horizontal: context.smallSpacing,
                vertical: context.spacing,
              ),
              isDense: true,
            ),
          ),
          onChanged: (val) {
            final newId = val?.empleadoCargo.cargoSucursal?.codCargoSucursal;
            console('🔵 ADD INTERNO CHANGED: $_codCargoInternoId → $newId');
            setState(() {
              _codCargoInternoId = newId;
              _selectedInterno = val;
            });
          },
          popupProps: const PopupProps.menu(showSearchBox: true, searchDelay: Duration(milliseconds: 300)),
          validator: (val) => val == null ? 'Requerido' : null,
        ),
      ),
      SizedBox(width: context.smallSpacing),
      CargoNavigationButton(
        empresaId: _selectedInterno?.empleadoCargo.cargoSucursal?.cargo?.codEmpresa??6,
        empresaNombre: _selectedInterno?.empleadoCargo.cargoSucursal?.sucursal?.empresa.nombre,
          ref: ref, // ✅ AGREGAR
      ),
    ],
  );
}

  Widget _buildEmpresaPlanillaDropdown() {
    final empresasAsync = ref.watch(empresasProvider);
    return empresasAsync.when(
      loading: () => const LinearProgressIndicator(minHeight: 2),
      error: (e, _) => Text('Error: $e', style: context.bodyLightStyle),
      data: (empresas) {
        final filtered = empresas.where((e) => e.codEmpresa != -1).toList();
        return DropdownButtonFormField<int>(
          value: _codEmpresaPlanilla,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Empresa Planilla *',
            hintText: 'Seleccione empresa',
            labelStyle: TextStyle(fontSize: context.bodyFontSize),
            border: OutlineInputBorder(borderRadius: context.borderRadius),
            contentPadding: EdgeInsets.symmetric(
              horizontal: context.smallSpacing,
              vertical: context.spacing,
            ),
            isDense: true,
            filled: true,
            fillColor: Colors.white,
          ),
          items: filtered.map((e) => DropdownMenuItem(value: e.codEmpresa, child: Text(e.nombre))).toList(),
          onChanged: (val) {
            console('🟡 ADD EMPRESA PLANILLA CHANGED: $_codEmpresaPlanilla → $val');
            setState(() {
              _codEmpresaPlanilla = val;
              // 🔴 IMPORTANTE: Reset SOLO planilla, NO interno
              _codCargoPlanillaId = null;
              _selectedPlanilla = null;
            });
          },
          validator: (val) => val == null ? 'Requerido' : null,
        );
      },
    );
  }

Widget _buildCargoPlanillaDropdown() {
  // Obtener el nombre de la empresa seleccionada
  final empresasAsync = ref.watch(empresasProvider);
  
  return empresasAsync.when(
    loading: () => const LinearProgressIndicator(minHeight: 2),
    error: (e, _) => Text('Error: $e', style: context.bodyLightStyle),
    data: (empresas) {
       final empresaSeleccionada = empresas.firstWhere(
        (e) => e.codEmpresa == _codEmpresaPlanilla,
        orElse: () => empresas.first,
      );

      return Row(
        children: [
          Expanded(
            child: DropdownSearch<EmpleadoEntity>(
              enabled: _codEmpresaPlanilla != null,
              asyncItems: (text) => ref.read(getCargoXEmpresa((text, _codEmpresaPlanilla)).future),
              selectedItem: _selectedPlanilla,
              itemAsString: (e) => _formatCargoLabel(e, tipo: 'planilla'),
              dropdownDecoratorProps: DropDownDecoratorProps(
                dropdownSearchDecoration: InputDecoration(
                  labelText: 'Cargo Planilla *',
                  hintText: _codEmpresaPlanilla == null ? 'Primero empresa' : 'Seleccione cargo',
                  labelStyle: TextStyle(fontSize: context.bodyFontSize),
                  hintStyle: context.bodyLightStyle,
                  border: OutlineInputBorder(borderRadius: context.borderRadius),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: context.smallSpacing,
                    vertical: context.spacing,
                  ),
                  isDense: true,
                ),
              ),
              onChanged: (val) {
                final newId = val?.empleadoCargo.cargoSucursal?.codCargoSucursal;
                console('🟠 ADD PLANILLA CHANGED: $_codCargoPlanillaId → $newId');
                setState(() {
                  _codCargoPlanillaId = newId;
                  _selectedPlanilla = val;
                });
              },
              popupProps: const PopupProps.menu(showSearchBox: true),
              validator: (val) => val == null ? 'Requerido' : null,
            ),
          ),
          SizedBox(width: context.smallSpacing),
          CargoNavigationButton(
            empresaId: _codEmpresaPlanilla,
            empresaNombre: empresaSeleccionada.nombre,
              ref: ref, // ✅ AGREGAR
          ),
        ],
      );
    },
  );
}

  String _formatCargoLabel(EmpleadoEntity e, {required String tipo}) {
    final cargo = e.empleadoCargo.cargoSucursal?.cargo;
    final cargoSuc = e.empleadoCargo.cargoSucursal;

    if (tipo == 'interno') {
      final desc = cargo?.descripcion ?? cargoSuc?.datoCargo ?? 'N/A';
      final suc = cargo?.sucursal ?? 'N/A';
      return "$desc — $suc";
    } else {
      final desc = cargo?.descripcionPlanilla.isNotEmpty == true
          ? cargo!.descripcionPlanilla
          : (cargo?.descripcion ?? cargoSuc?.datoCargo ?? 'N/A');
      final suc = cargo?.sucursalPlanilla.isNotEmpty == true
          ? cargo!.sucursalPlanilla
          : (cargo?.sucursal ?? 'N/A');
      return "$desc — $suc";
    }
  }

  Widget _buildFechaSection(BuildContext context) {
    return CustomDatePicker(
      controller: _fechaController,
      label: 'Fecha Inicio *',
      onDateSelected: (date) => setState(() => _fechaInicioSelected = date),
      validator: (val) => (val == null || val.isEmpty) ? 'Requerido' : null,
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final canSave = _codCargoInternoId != null && _codCargoPlanillaId != null;
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: widget.onCancel,
          child: Text('Cancelar', style: context.bodyStyle),
        ),
        SizedBox(width: context.spacing),
        ElevatedButton.icon(
          icon: const Icon(Icons.save, size: 18),
          label: const Text('Guardar'),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(
              horizontal: context.spacing * 1.5,
              vertical: context.smallSpacing,
            ),
          ),
          onPressed: canSave ? () => _handleSave(context) : null,
        ),
      ],
    );
  }

  Widget _buildActionButtonsHorizontal(BuildContext context) {
    final canSave = _codCargoInternoId != null && _codCargoPlanillaId != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.save, size: 18),
          label: const Text('Guardar'),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: context.spacing),
          ),
          onPressed: canSave ? () => _handleSave(context) : null,
        ),
        SizedBox(height: context.smallSpacing),
        TextButton(
          onPressed: widget.onCancel,
          child: Text('Cancelar', style: context.bodyStyle),
        ),
      ],
    );
  }

  Future<void> _handleSave(BuildContext context) async {
    console('🔐 ADD VALIDACIÓN FINAL ANTES DE GUARDAR:');
    console('   INTERNO - codCargoSucursal: $_codCargoInternoId (ENVIARÁ ESTO)');
    console('   PLANILLA - codCargoSucursal: $_codCargoPlanillaId (ENVIARÁ ESTO)');
    console('   Empresa Planilla: $_codEmpresaPlanilla');

    final payload = EmpleadoCargoEntity(
      codEmpleado: widget.codEmpleado,
      codCargoSucursal: _codCargoInternoId!,    // ✅ CORRECTO: codCargoSucursal
      codCargoSucPlanilla: _codCargoPlanillaId!, // ✅ CORRECTO: codCargoSucursal
      fechaInicio: _fechaInicioSelected ?? DateTime.now(),
      audUsuario: widget.audUsuario,
      cargoPlanilla: '',
      existe: 0,
    );

    console('✅ ADD PAYLOAD FINAL: codCargoSucursal=$_codCargoInternoId, codCargoSucPlanilla=$_codCargoPlanillaId');

   final success= await executeABM(
      ref: ref,
      context: context,
      successMessage: 'Cargo asignado correctamente',
      providersToInvalidate: [
        detalleEmpleadoProvider(widget.codEmpleado),
        getHistorialCargosEmpleado(widget.codEmpleado),
        cargoActualEmpleadoProvider(widget.codEmpleado),
        getListaEmpleados
      ],
      operation: () async {
        await validarCronologiaCargoUltimoRegistro(
          fechaCargoText: _fechaController.text,
          ref: ref,
          codEmpleado: widget.codEmpleado,
        );
        await ref.read(registrarEmpleadoCargoProvider(payload).future);
      },
    );
    // ✅ Solo cierra si fue exitoso
    if (mounted && success) widget.onCancel();
  }
}
// ╔════════════════════════════════════════════════════════════════╗
// ║ WIDGET AUXILIAR: Botón de Redirección a CargosScreen
// ╚════════════════════════════════════════════════════════════════╝

class CargoNavigationButton extends StatelessWidget {
  final int? empresaId;
  final String? empresaNombre;
  final VoidCallback? onNavigate;
    final WidgetRef? ref; // ✅ AGREGAR

  const CargoNavigationButton({
    Key? key,
    required this.empresaId,
    required this.empresaNombre,
    this.onNavigate,
        this.ref, // ✅ AGREGAR
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Ver/Crear cargos',
      child: IconButton(
        icon: const Icon(Icons.open_in_new, size: 20),
        onPressed: ()async {
          final id = empresaId ?? 0;
          final nombre = empresaNombre ?? 'Empresa';

          if (id != 0) {
            onNavigate?.call();
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => CargosScreen(
                  codEmpresa: id,
                  nombreEmpresa: nombre,
                ),
              ),
            );
            // ✅ AL VOLVER: Invalidar el provider de cargos
            if (ref != null) {
              ref!.invalidate(getCargoXEmpresa);
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('❌ Selecciona una empresa primero'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        },
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      ),
    );
  }
}