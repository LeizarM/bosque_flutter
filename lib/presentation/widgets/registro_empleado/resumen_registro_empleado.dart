// lib/presentation/widgets/registro_empleado/resumen_registro_empleado.dart

import 'package:bosque_flutter/core/state/empleados_dependientes_provider.dart';
import 'package:bosque_flutter/core/state/registro_empleado_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/abm_service.dart';
import 'package:bosque_flutter/domain/entities/banco_entity.dart';
import 'package:bosque_flutter/domain/entities/cargo_sucursal_entity.dart';
import 'package:bosque_flutter/domain/entities/educacion_entity.dart';
import 'package:bosque_flutter/domain/entities/email_entity.dart';
import 'package:bosque_flutter/domain/entities/empleado_cargo_entity.dart';
import 'package:bosque_flutter/domain/entities/empleado_entity.dart';
import 'package:bosque_flutter/domain/entities/empresa_entity.dart';
import 'package:bosque_flutter/domain/entities/experiencia_laboral_entity.dart';
import 'package:bosque_flutter/domain/entities/formacion_entity.dart';
import 'package:bosque_flutter/domain/entities/nro_cuenta_bancaria_entity.dart';
import 'package:bosque_flutter/domain/entities/persona_entity.dart';
import 'package:bosque_flutter/domain/entities/relacion_laboral_entity.dart';
import 'package:bosque_flutter/domain/entities/sucursal_entity.dart';
import 'package:bosque_flutter/domain/entities/telefono_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_duracion_formacion_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_educacion_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_formacion_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_relacion_laboral_entity.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/detalle_persona.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/registro_empleado_utils.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/responsive_utils_registro_empleado.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ResumenRegistroEmpleado extends ConsumerStatefulWidget {
  final PersonaEntity selectedPersona;

  const ResumenRegistroEmpleado({
    Key? key,
    required this.selectedPersona,
  }) : super(key: key);

  @override
  ConsumerState<ResumenRegistroEmpleado> createState() =>
      _ResumenRegistroEmpleadoState();
}

class _ResumenRegistroEmpleadoState
    extends ConsumerState<ResumenRegistroEmpleado> {
  bool _isLoading = false;

  // ========== MÉTODOS DE CONSTRUCCIÓN ==========

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blue.shade600),
        SizedBox(width: context.smallSpacing),
        Text(
          title,
          style: context.subtitleStyle.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: EdgeInsets.all(context.spacing),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: context.borderRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(context, title, icon),
          SizedBox(height: context.spacing),
          ...children,
        ],
      ),
    );
  }

  Widget _buildRowResumen(BuildContext context, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.smallSpacing),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: context.isMobile ? 120 : 140,
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRowResumenWithWidget(
    BuildContext context,
    String label,
    Widget value,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.smallSpacing),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: context.isMobile ? 120 : 140,
            child: Text(
              label,
              style: context.bodyStyle.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(child: value),
        ],
      ),
    );
  }

  // ========== HEADER ==========

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.spacing),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: context.borderRadius,
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen de Registro',
            style: context.titleStyle.copyWith(
              color: Colors.black87,
            ),
          ),
          SizedBox(height: context.smallSpacing),
          Text(
            'Verifica que toda la información sea correcta antes de guardar',
            style: context.bodyStyle.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // ========== SECCIONES ==========

  Widget _buildContactosSection(
    BuildContext context,
    List<EmailEntity> tempEmails,
    AsyncValue<List<EmailEntity>> emailsAsync,
    List<TelefonoEntity> tempTelefonos,
    AsyncValue<List<TelefonoEntity>> telefonosAsync,
  ) {
    final hasEmails = tempEmails.isNotEmpty;
    final hasTelefonos = tempTelefonos.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Emails
        if (hasEmails)
          _buildSection(
            context: context,
            title: 'Contacto - Email',
            icon: Icons.email,
            children: [
              ...tempEmails.map((email) {
                return _buildRowResumen(context, 'Email:', email.email);
              }),
            ],
          )
        else
          emailsAsync.when(
            data: (emails) {
              if (emails.isNotEmpty) {
                return _buildSection(
                  context: context,
                  title: 'Contacto - Email',
                  icon: Icons.email,
                  children: [
                    ...emails.map((email) {
                      return _buildRowResumen(context, 'Email:', email.email);
                    }),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => Padding(
              padding: EdgeInsets.symmetric(vertical: context.smallSpacing),
              child: const CircularProgressIndicator(),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),
        if (hasEmails) SizedBox(height: context.largeSpacing),

        // Teléfonos
        if (hasTelefonos)
          _buildSection(
            context: context,
            title: 'Contacto - Teléfono',
            icon: Icons.phone,
            children: [
              ...tempTelefonos.map((tel) {
                return _buildRowResumen(context, 'Teléfono:', tel.telefono);
              }),
            ],
          )
        else
          telefonosAsync.when(
            data: (telefonos) {
              if (telefonos.isNotEmpty) {
                return _buildSection(
                  context: context,
                  title: 'Contacto - Teléfono',
                  icon: Icons.phone,
                  children: [
                    ...telefonos.map((tel) {
                      return _buildRowResumen(context, 'Teléfono:', tel.telefono);
                    }),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => Padding(
              padding: EdgeInsets.symmetric(vertical: context.smallSpacing),
              child: const CircularProgressIndicator(),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),
      ],
    );
  }

  Widget _buildCargosSection(BuildContext context, List<dynamic> areaCargoList) {
    if (areaCargoList.isEmpty) return const SizedBox.shrink();

    return _buildSection(
      context: context,
      title: 'Área y Cargo',
      icon: Icons.work,
      children: [
        context.isMobile
            ? _buildCargosMobileView(context, areaCargoList)
            : _buildCargosWebView(context, areaCargoList),
      ],
    );
  }

  Widget _buildCargosMobileView(
    BuildContext context,
    List<dynamic> areaCargoList,
  ) {
    return Column(
      children: [
        _buildCargoCard(
          context: context,
          titulo: 'Cargo Interno (Operativo)',
          cargoSucursal: areaCargoList[0]['cargoSucursal'],
          colorPrimario: Colors.blue,
        ),
        SizedBox(height: context.largeSpacing),
        _buildCargoCard(
          context: context,
          titulo: 'Cargo Planilla (RRHH)',
          cargoNombre: areaCargoList[0]['cargoPlanilla'],
          cargoSucursal: areaCargoList[0]['cargoSucursalPlanilla'] ?? areaCargoList[0]['cargoSucursal'],
          colorPrimario: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildCargosWebView(
    BuildContext context,
    List<dynamic> areaCargoList,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildCargoCard(
            context: context,
            titulo: 'Cargo Interno (Operativo)',
            cargoSucursal: areaCargoList[0]['cargoSucursal'],
            colorPrimario: Colors.blue,
          ),
        ),
        SizedBox(width: context.largeSpacing * 2),
        Expanded(
          child: _buildCargoCard(
            context: context,
            titulo: 'Cargo Planilla (RRHH)',
            cargoNombre: areaCargoList[0]['cargoPlanilla'],
            cargoSucursal: areaCargoList[0]['cargoSucursalPlanilla'] ?? areaCargoList[0]['cargoSucursal'],
            colorPrimario: Colors.orange,
          ),
        ),
      ],
    );
  }

 Widget _buildCargoCard({
  required BuildContext context,
  required String titulo,
  required Color colorPrimario,
  CargoSucursalEntity? cargoSucursal,
  String? cargoNombre,
}) {
  final tieneData = cargoSucursal != null || (cargoNombre != null && cargoNombre.isNotEmpty);

  // ✅ MAPEO CORRECTO desde cargoSucursal.cargo (no desde sucursal)
  final empresa = cargoSucursal?.cargo?.nombreEmpresa ?? 
                  cargoSucursal?.sucursal?.empresa?.nombre ?? 
                  'N/A';
  final sucursal = cargoSucursal?.cargo?.sucursal ?? 
                   cargoSucursal?.sucursal?.nombre ?? 
                   'N/A';
  final cargoDesc = cargoSucursal?.cargo?.descripcion ?? 
                    cargoSucursal?.datoCargo ?? 
                    'N/A';

  return Card(
    margin: EdgeInsets.zero,
    elevation: 0,
    shape: RoundedRectangleBorder(
      side: BorderSide(color: colorPrimario.withOpacity(0.3)),
      borderRadius: context.borderRadius,
    ),
    child: Padding(
      padding: EdgeInsets.all(context.spacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.work_outline, size: 16, color: colorPrimario),
              SizedBox(width: context.smallSpacing),
              Expanded(
                child: Text(
                  titulo,
                  style: context.bodyStyle.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorPrimario,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: context.spacing),

          // Datos
          if (tieneData)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Empresa
                Text(
                  'Empresa',
                  style: context.bodyLightStyle.copyWith(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: context.smallSpacing * 0.5),
                Text(
                  empresa,
                  style: context.bodyStyle.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: context.spacing),
                
                // Sucursal
                Text(
                  'Sucursal',
                  style: context.bodyLightStyle.copyWith(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: context.smallSpacing * 0.5),
                Text(
                  sucursal,
                  style: context.bodyStyle.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: context.spacing),
                
                // Cargo
                Text(
                  titulo.contains('Interno') ? 'Cargo Interno' : 'Cargo Planilla',
                  style: context.bodyLightStyle.copyWith(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: context.smallSpacing * 0.5),
                Text(
                  cargoNombre ?? cargoDesc,
                  style: context.bodyStyle.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            )
          else
            Text(
              'No especificado',
              style: context.bodyStyle.copyWith(
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    )
  );
}

  Widget _buildRelacionLaboralSection(
    BuildContext context,
    List<RelacionLaboralEntity> relacionLaboral,
  ) {
    if (relacionLaboral.isEmpty) return const SizedBox.shrink();

    final tiposRelacionAsync = ref.watch(getTipoRelacionLaboral);

    return _buildSection(
      context: context,
      title: 'Relación Laboral',
      icon: Icons.assignment,
      children: [
        tiposRelacionAsync.when(
          loading: () => const CircularProgressIndicator(),
          error: (_, __) => const SizedBox.shrink(),
          data: (tipos) {
            return Column(
              children: [
                _buildRowResumenWithWidget(
                  context,
                  'Tipo:',
                  DisplayValue<TipoRelacionLaboralEntity>(
                    code: relacionLaboral.first.tipoRel,
                    provider: getTipoRelacionLaboral,
                    getCode: (tipo) => tipo.codTipos,
                    getDescription: (tipo) => tipo.nombre,
                    fallback: relacionLaboral.first.tipoRel,
                    style: context.bodyStyle,
                  ),
                ),
                _buildRowResumen(
                  context,
                  'Fecha de Inicio:',
                  FechaUtils.formatDate(relacionLaboral.first.fechaIni!),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildCuentasBancariasSection(
    BuildContext context,
    List<NroCuentaBancariaEntity> cuentasBancarias,
  ) {
    if (cuentasBancarias.isEmpty) return const SizedBox.shrink();

    final bancosAsync = ref.watch(obtenerBancos);

    return bancosAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
      data: (bancos) {
        return _buildSection(
          context: context,
          title: 'Información Bancaria',
          icon: Icons.account_balance,
          children: [
            ...cuentasBancarias.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final cuenta = entry.value;
              final banco = bancos.firstWhere(
                (b) => b.codBanco == cuenta.codBanco,
                orElse: () => BancoEntity(
                  codBanco: 0,
                  nombre: 'Banco desconocido',
                  audUsuario: 0,
                  fila: 0,
                ),
              );
              final estadoText = cuenta.estado == 1 ? 'Activa' : 'Inactiva';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (index > 1) Divider(height: context.spacing * 1.5),
                  _buildRowResumen(context, 'Banco $index:', banco.nombre),
                  _buildRowResumen(context, 'Nro. Cuenta:', cuenta.nroCuentaBancaria),
                  _buildRowResumen(context, 'Estado:', estadoText),
                ],
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildEducacionCard(BuildContext context, EducacionEntity educacion) {
    final tiposEducacionAsync = ref.watch(obtenerTipoEducacion);

    return Card(
      margin: EdgeInsets.symmetric(vertical: context.smallSpacing),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade300),
        borderRadius: context.borderRadius,
      ),
      child: Padding(
        padding: EdgeInsets.all(context.spacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            tiposEducacionAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => Text(
                'Tipo: ${educacion.tipoEducacion}',
                style: context.bodyStyle.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              data: (tipos) {
                return DisplayValue<TipoEducacionEntity>(
                  code: educacion.tipoEducacion,
                  provider: obtenerTipoEducacion,
                  getCode: (tipo) => tipo.codTipos,
                  getDescription: (tipo) => tipo.nombre,
                  fallback: educacion.tipoEducacion,
                  style: context.bodyStyle.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                );
              },
            ),
            SizedBox(height: context.spacing),
            _buildRowResumen(
              context,
              'Institución:',
              educacion.descripcion,
            ),
            _buildRowResumen(
              context,
              'Fecha:',
              FechaUtils.formatDate(educacion.fecha),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEducacionSection(
    BuildContext context,
    List<EducacionEntity> listaEducacion,
  ) {
    if (listaEducacion.isEmpty) return const SizedBox.shrink();

    return _buildSection(
      context: context,
      title: 'Historial Educativo',
      icon: Icons.school,
      children: [
        ...listaEducacion.map((edu) {
          return _buildEducacionCard(context, edu);
        }),
      ],
    );
  }

  Widget _buildFormacionCard(BuildContext context, FormacionEntity formacion) {
    final tiposFormacionAsync = ref.watch(obtenerTipoFormacionProvider);
    final tiposDuracionAsync = ref.watch(obtenerTipoDuracionFormacionProvider);

    return Card(
      margin: EdgeInsets.symmetric(vertical: context.smallSpacing),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade300),
        borderRadius: context.borderRadius,
      ),
      child: Padding(
        padding: EdgeInsets.all(context.spacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            tiposFormacionAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => Text(
                'Tipo: ${formacion.tipoFormacion}',
                style: context.bodyStyle.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              data: (_) {
                return DisplayValue<TipoFormacionEntity>(
                  code: formacion.tipoFormacion,
                  provider: obtenerTipoFormacionProvider,
                  getCode: (tipo) => (tipo as dynamic).codTipos,
                  getDescription: (tipo) => (tipo as dynamic).nombre,
                  fallback: formacion.tipoFormacion,
                  style: context.bodyStyle.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                );
              },
            ),
            _buildRowResumen(context, 'Institución:', formacion.institucion), // ✅ AGREGAR
            SizedBox(height: context.spacing),
            _buildRowResumen(context, 'Descripción:', formacion.descripcion),
            _buildRowResumenWithWidget(
              context,
              'Duración:',
              Row(
                children: [
                  Text(
                    formacion.duracion.toString(),
                    style: context.bodyStyle,
                  ),
                  SizedBox(width: context.smallSpacing),
                  Expanded(
                    child: tiposDuracionAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => Text(
                        formacion.tipoDuracion,
                        style: context.bodyStyle,
                      ),
                      data: (_) {
                        return DisplayValue<TipoDuracionFormacionEntity>(
                          code: formacion.tipoDuracion,
                          provider: obtenerTipoDuracionFormacionProvider,
                          getCode: (tipo) => (tipo as dynamic).codTipos,
                          getDescription: (tipo) => (tipo as dynamic).nombre,
                          fallback: formacion.tipoDuracion,
                          style: context.bodyStyle,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            _buildRowResumen(
              context,
              'Fecha:',
              FechaUtils.formatDate(formacion.fechaFormacion),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormacionSection(
    BuildContext context,
    List<FormacionEntity> listaFormacion,
  ) {
    if (listaFormacion.isEmpty) return const SizedBox.shrink();

    return _buildSection(
      context: context,
      title: 'Formación / Cursos',
      icon: Icons.class_,
      children: [
        ...listaFormacion.map((frm) {
          return _buildFormacionCard(context, frm);
        }),
      ],
    );
  }

  Widget _buildExperienciaCard(
    BuildContext context,
    ExperienciaLaboralEntity experiencia,
  ) {
    final formattedFechaInicio = FechaUtils.formatDate(experiencia.fechaInicio);
    final formattedFechaFin = FechaUtils.formatDate(experiencia.fechaFin);

    return Card(
      margin: EdgeInsets.symmetric(vertical: context.smallSpacing),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade300),
        borderRadius: context.borderRadius,
      ),
      child: Padding(
        padding: EdgeInsets.all(context.spacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cargo: ${experiencia.cargo}',
              style: context.bodyStyle.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: context.spacing),
            _buildRowResumen(context, 'Empresa:', experiencia.nombreEmpresa),
            _buildRowResumen(context, 'Descripción:', experiencia.descripcion),
            _buildRowResumen(
              context,
              'Período:',
              '$formattedFechaInicio - $formattedFechaFin',
            ),
            if ((experiencia.nroReferencia ?? '').isNotEmpty)
              _buildRowResumen(context, 'Referencia:', experiencia.nroReferencia ?? ''),
          ],
        ),
      ),
    );
  }

  Widget _buildExperienciaSection(
    BuildContext context,
    List<ExperienciaLaboralEntity> listaExperiencia,
  ) {
    if (listaExperiencia.isEmpty) return const SizedBox.shrink();

    return _buildSection(
      context: context,
      title: 'Experiencia Laboral',
      icon: Icons.work_history,
      children: [
        ...listaExperiencia.map((exp) {
          return _buildExperienciaCard(context, exp);
        }),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    if (context.isMobile) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Volver'),
            ),
          ),
          SizedBox(width: context.spacing),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : () {
                final tempPersona = ref.read(tempPersonaProvider);
                if (tempPersona != null) {
                  _registrarEmpleado(tempPersona);
                }
              },
              icon: _isLoading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(
                _isLoading ? 'Guardando...' : 'Confirmar y Guardar',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton.icon(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Volver'),
        ),
        SizedBox(width: context.spacing),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : () {
            final tempPersona = ref.read(tempPersonaProvider);
            if (tempPersona != null) {
              _registrarEmpleado(tempPersona);
            }
          },
          icon: _isLoading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.save),
          label: Text(
            _isLoading ? 'Guardando...' : 'Confirmar y Guardar',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade600,
          ),
        ),
      ],
    );
  }

  // ========== MÉTODO PRINCIPAL ==========

  @override
  Widget build(BuildContext context) {
    final tempPersona = ref.watch(tempPersonaProvider);

    final personaCompletaAsync = tempPersona == null
        ? ref.watch(obtenerPersonaProvider(widget.selectedPersona.codPersona))
        : AsyncValue.data(tempPersona);

    final areaCargoList = ref.watch(tempRegistroFuncionesListProvider);
    final relacionLaboral = ref.watch(tempRelacionLaboralListProvider);
    final cuentasBancarias = ref.watch(tempCuentasBancariasProvider);
    final listaEducacion = ref.watch(tempEducacionListProvider);
    final listaFormacion = ref.watch(tempFormacionListProvider);
    final listaExperiencia = ref.watch(tempExperienciaListProvider);
    final tempTelefonos = ref.watch(tempTelefonoListProvider);
    final tempEmails = ref.watch(tempEmailListProvider);
    final emailsAsync = ref.watch(emailProvider(widget.selectedPersona.codPersona));
    final telefonosAsync = ref.watch(telefonoProvider(widget.selectedPersona.codPersona));

    return personaCompletaAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Text('Error al cargar datos: $err'),
      ),
      data: (personaCompleta) {
        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(context.spacing),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(context),
                SizedBox(height: context.largeSpacing),

                // Datos Personales
                _buildSection(
                  context: context,
                  title: 'Datos Personales',
                  icon: Icons.person,
                  children: [
                    DetallePersona(persona: personaCompleta),
                  ],
                ),
                SizedBox(height: context.largeSpacing),

                // Contactos
                _buildContactosSection(
                  context,
                  tempEmails,
                  emailsAsync,
                  tempTelefonos,
                  telefonosAsync,
                ),
                if (tempEmails.isNotEmpty || tempTelefonos.isNotEmpty)
                  SizedBox(height: context.largeSpacing),

                // Cargos
                _buildCargosSection(context, areaCargoList),
                if (areaCargoList.isNotEmpty) SizedBox(height: context.largeSpacing),

                // Relación Laboral
                _buildRelacionLaboralSection(context, relacionLaboral),
                if (relacionLaboral.isNotEmpty) SizedBox(height: context.largeSpacing),

                // Cuentas Bancarias
                _buildCuentasBancariasSection(context, cuentasBancarias),
                if (cuentasBancarias.isNotEmpty) SizedBox(height: context.largeSpacing),

                // Educación
                _buildEducacionSection(context, listaEducacion),
                if (listaEducacion.isNotEmpty) SizedBox(height: context.largeSpacing),

                // Formación
                _buildFormacionSection(context, listaFormacion),
                if (listaFormacion.isNotEmpty) SizedBox(height: context.largeSpacing),

                // Experiencia
                _buildExperienciaSection(context, listaExperiencia),
                if (listaExperiencia.isNotEmpty) SizedBox(height: context.largeSpacing),

                // Botones
               // _buildActionButtons(context),
              ],
            ),
          ),
        );
      },
    );
  }

  // ========== REGISTRAR EMPLEADO ==========

  Future<void> _registrarEmpleado(PersonaEntity personaCompleta) async {
    debugPrint('💾 [ResumenRegistroEmpleado] Iniciando registro en cascada');

    setState(() => _isLoading = true);

    try {
      final user = ref.read(userProvider);
      int codPersona = personaCompleta.codPersona;
      int codEmpleado = 0;

      // ========== PASO 1: REGISTRAR/ACTUALIZAR PERSONA ==========
      debugPrint('➡️ [1. Registrar/Actualizar Persona] codPersona: $codPersona');
      try {
        final personaRegistrada = await ref.read(registrarPersonaProvider(personaCompleta).future);
        codPersona = personaRegistrada.codPersona;
        debugPrint('✅ [1. Persona] codPersona obtenido: $codPersona');
      } catch (e) {
        debugPrint('❌ [1. Persona] Error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error en persona: $e'), backgroundColor: Colors.red),
          );
        }
        return;
      }

      // ========== PASO 2: REGISTRAR EMPLEADO ==========
      final empleadoEntity = EmpleadoEntity(
        fila: null,
        codPersona: codPersona,
        codZona: personaCompleta.codZona,
        nombres: personaCompleta.nombres,
        apPaterno: personaCompleta.apPaterno,
        apMaterno: personaCompleta.apMaterno,
        ciExpedido: personaCompleta.ciExpedido,
        ciFechaVencimiento: personaCompleta.ciFechaVencimiento ?? DateTime.now(),
        ciNumero: personaCompleta.ciNumero,
        direccion: personaCompleta.direccion,
        estadoCivil: personaCompleta.estadoCivil,
        fechaNacimiento: personaCompleta.fechaNacimiento ?? DateTime.now(),
        lugarNacimiento: personaCompleta.lugarNacimiento,
        nacionalidad: personaCompleta.nacionalidad,
        sexo: personaCompleta.sexo,
        lat: personaCompleta.lat ?? 0,
        lng: personaCompleta.lng ?? 0,
        audUsuarioI: user?.codUsuario ?? 0,
        datoPersona: personaCompleta.datoPersona ?? '',
        codEmpleado: 0,
        numCuenta: '',
        codRelBeneficios: 0,
        codRelPlanilla: 0,
        codDependiente: 0,
        esActivoString: null,
        persona: personaCompleta,
        empleadoCargo: EmpleadoCargoEntity(
          codCargoSucursal: 0,
          codCargoSucPlanilla: 0,
          fechaInicio: DateTime.now(),
          cargoSucursal: CargoSucursalEntity(
            codCargoSucursal: 0,
            codSucursal: 0,
            codCargo: 0,
            audUsuario: 0,
            datoCargo: '',
          ),
          cargoPlanilla: '',
          existe: 0,
          audUsuario: 0,
          codEmpleado: 0,
        ),
        dependiente: null,
        empresa: EmpresaEntity(
          codEmpresa: 0,
          nombre: '',
          codPadre: 0,
          sigla: '',
          audUsuario: 0,
        ),
        sucursal: SucursalEntity(
          codSucursal: 0,
          nombre: '',
          codEmpresa: 0,
          codCiudad: 0,
          audUsuarioI: 0,
          empresa: EmpresaEntity(
            codEmpresa: 0,
            nombre: '',
            codPadre: 0,
            sigla: '',
            audUsuario: 0,
          ),
          nombreCiudad: '',
          codSucursalPlanilla: 0,
          nombrePlanilla: '',
        ),
        relEmpEmpr: RelacionLaboralEntity(
          codRelEmplEmpr: 0,
          codEmpleado: 0,
          esActivo: 1,
          tipoRel: '',
          nombreFileContrato: '',
          fechaIni: DateTime.now(),
          fechaFin: DateTime.now(),
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
      );

      debugPrint('➡️ [2. Registrar Empleado]');
      try {
        final empleadoRegistrado = await ref.read(registrarEmpleadoProvider(empleadoEntity).future);
        codEmpleado = empleadoRegistrado.codEmpleado;
        debugPrint('✅ [2. Empleado] codEmpleado obtenido: $codEmpleado');
      } catch (e) {
        debugPrint('❌ [2. Empleado] Error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error en empleado: $e'), backgroundColor: Colors.red),
          );
        }
        return;
      }

      // ========== PASO 3: REGISTRAR EMPLEADO CARGO ==========
      final areaCargoList = ref.read(tempRegistroFuncionesListProvider);
      final relacionList = ref.read(tempRelacionLaboralListProvider);
      final fechaInicioDelCargo = relacionList.isNotEmpty ? relacionList[0].fechaIni : DateTime.now();

      for (var i = 0; i < areaCargoList.length; i++) {
        final area = areaCargoList[i];
        debugPrint('➡️ [3. Registrar EmpleadoCargo #${i + 1}]');
        try {
          final cargEntity = EmpleadoCargoEntity(
            codCargoSucursal: (area['codCargoSucursal'] as int?) ?? 0,
            codCargoSucPlanilla: (area['codCargoSucPlanilla'] as int?) ?? 0,
            fechaInicio: fechaInicioDelCargo,
            cargoSucursal: area['cargoSucursal'] as CargoSucursalEntity? ??
                CargoSucursalEntity(codCargoSucursal: 0, codSucursal: 0, codCargo: 0, audUsuario: 0, datoCargo: ''),
            cargoPlanilla: (area['cargoPlanilla'] as String?) ?? '',
            existe: (area['existe'] as int?) ?? 0,
            audUsuario: user?.codUsuario ?? 0,
            codEmpleado: codEmpleado,
          );
          await ref.read(registrarEmpleadoCargoProvider(cargEntity).future);
          debugPrint('✅ [3. EmpleadoCargo #${i + 1}] OK');
        } catch (e) {
          debugPrint('⚠️ [3. EmpleadoCargo #${i + 1}] Error: $e');
        }
      }

      // ========== PASO 4: REGISTRAR RELACIÓN LABORAL ==========
      for (var i = 0; i < relacionList.length; i++) {
        final rel = relacionList[i];
        debugPrint('➡️ [4. Registrar Relación Laboral #${i + 1}]');
        try {
          final relEntity = RelacionLaboralEntity(
            codRelEmplEmpr: 0,
            codEmpleado: codEmpleado,
            esActivo: rel.esActivo,
            tipoRel: rel.tipoRel,
            nombreFileContrato: rel.nombreFileContrato,
            fechaIni: rel.fechaIni,
            fechaFin: rel.fechaFin,
            motivoFin: rel.motivoFin,
            audUsuario: user?.codUsuario ?? 0,
            fechaInicioBeneficio: rel.fechaInicioBeneficio,
            fechaInicioPlanilla: rel.fechaInicioPlanilla,
            datoFechasBeneficio: rel.datoFechasBeneficio,
            cargo: rel.cargo,
            sucursal: rel.sucursal,
            empresaFiscal: rel.empresaFiscal,
            empresaInterna: rel.empresaInterna,
          );
          await ref.read(registrarRelacionLaboral(relEntity).future);
          debugPrint('✅ [4. Relación Laboral #${i + 1}] OK');
        } catch (e) {
          debugPrint('⚠️ [4. Relación Laboral #${i + 1}] Error: $e');
        }
      }

      // ========== PASO 5: REGISTRAR CUENTAS BANCARIAS ==========
      final cuentas = ref.read(tempCuentasBancariasProvider);
      for (var i = 0; i < cuentas.length; i++) {
        final cuenta = cuentas[i];
        debugPrint('➡️ [5. Registrar Cuenta Bancaria #${i + 1}]');
        try {
          final cuentaEntity = NroCuentaBancariaEntity(
            codCuenta: 0,
            codBanco: cuenta.codBanco,
            nroCuentaBancaria: cuenta.nroCuentaBancaria,
            codEmpleado: codEmpleado,
            estado: cuenta.estado,
            audUsuarioI: user?.codUsuario ?? 0,
          );
          await ref.read(registroCuentaBancaria(cuentaEntity).future);
          debugPrint('✅ [5. Cuenta Bancaria #${i + 1}] OK');
        } catch (e) {
          debugPrint('⚠️ [5. Cuenta Bancaria #${i + 1}] Error: $e');
        }
      }

      // ========== PASO 6: REGISTRAR EDUCACIÓN ==========
      final educaciones = ref.read(tempEducacionListProvider);
      for (var i = 0; i < educaciones.length; i++) {
        final edu = educaciones[i];
        debugPrint('➡️ [6. Registrar Educación #${i + 1}]');
        try {
          final eduEntity = EducacionEntity(
            codEducacion: edu.codEducacion,
            codEmpleado: codEmpleado,
            tipoEducacion: edu.tipoEducacion,
            descripcion: edu.descripcion,
            fecha: edu.fecha,
            audUsuario: user?.codUsuario ?? 0,
          );
          await ref.read(registrarEducacionProvider(eduEntity).future);
          debugPrint('✅ [6. Educación #${i + 1}] OK');
        } catch (e) {
          debugPrint('⚠️ [6. Educación #${i + 1}] Error: $e');
        }
      }

      // ========== PASO 7: REGISTRAR FORMACIÓN ==========
      final formaciones = ref.read(tempFormacionListProvider);
      for (var i = 0; i < formaciones.length; i++) {
        final frm = formaciones[i];
        debugPrint('➡️ [7. Registrar Formación #${i + 1}]');
        try {
          final frmEntity = FormacionEntity(
            codFormacion: frm.codFormacion,
            codEmpleado: codEmpleado,
            tipoFormacion: frm.tipoFormacion,
            descripcion: frm.descripcion,
            institucion: frm.institucion,
            duracion: frm.duracion,
            tipoDuracion: frm.tipoDuracion,
            fechaFormacion: frm.fechaFormacion,
            audUsuario: user?.codUsuario ?? 0,
          );
          await ref.read(registrarFormacionProvider(frmEntity).future);
          debugPrint('✅ [7. Formación #${i + 1}] OK');
        } catch (e) {
          debugPrint('⚠️ [7. Formación #${i + 1}] Error: $e');
        }
      }

      // ========== PASO 8: REGISTRAR EXPERIENCIA LABORAL ==========
      final experiencias = ref.read(tempExperienciaListProvider);
      for (var i = 0; i < experiencias.length; i++) {
        final exp = experiencias[i];
        debugPrint('➡️ [8. Registrar Experiencia #${i + 1}]');
        try {
          final expEntity = ExperienciaLaboralEntity(
            codExperienciaLaboral: exp.codExperienciaLaboral,
            codEmpleado: codEmpleado,
            cargo: exp.cargo,
            nombreEmpresa: exp.nombreEmpresa,
            descripcion: exp.descripcion,
            fechaInicio: exp.fechaInicio,
            fechaFin: exp.fechaFin,
            nroReferencia: exp.nroReferencia,
            audUsuario: user?.codUsuario ?? 0,
          );
          await ref.read(registrarExperienciaLaboralProvider(expEntity).future);
          debugPrint('✅ [8. Experiencia #${i + 1}] OK');
        } catch (e) {
          debugPrint('⚠️ [8. Experiencia #${i + 1}] Error: $e');
        }
      }

      // ========== PASO 9: REGISTRAR TELÉFONOS ==========
      final telefonos = ref.read(tempTelefonoListProvider);
      for (var i = 0; i < telefonos.length; i++) {
        final tel = telefonos[i];
        debugPrint('➡️ [9. Registrar Teléfono #${i + 1}]');
        try {
          final telEntity = TelefonoEntity(
            codTelefono: tel.codTelefono,
            codPersona: codPersona,
            codTipoTel: tel.codTipoTel,
            telefono: tel.telefono,
            audUsuario: user?.codUsuario ?? 0,
          );
          await ref.read(registrarTelefonoProvider(telEntity).future);
          debugPrint('✅ [9. Teléfono #${i + 1}] OK');
        } catch (e) {
          debugPrint('⚠️ [9. Teléfono #${i + 1}] Error: $e');
        }
      }

      // ========== PASO 10: REGISTRAR EMAILS ==========
      final emails = ref.read(tempEmailListProvider);
      for (var i = 0; i < emails.length; i++) {
        final mail = emails[i];
        debugPrint('➡️ [10. Registrar Email #${i + 1}]');
        try {
          final mailEntity = EmailEntity(
            codEmail: mail.codEmail,
            codPersona: codPersona,
            email: mail.email,
            audUsuario: user?.codUsuario ?? 0,
          );
          await ref.read(registrarEmailProvider(mailEntity).future);
          debugPrint('✅ [10. Email #${i + 1}] OK');
        } catch (e) {
          debugPrint('⚠️ [10. Email #${i + 1}] Error: $e');
        }
      }

      // ========== FIN ==========
      debugPrint('✅ [Fin] Registro completado exitosamente');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Registro completado'),
            backgroundColor: Colors.green,
          ),
        );
        ref.read(tempRegistroFuncionesListProvider.notifier).state = [];
        ref.read(tempRelacionLaboralListProvider.notifier).state = [];
        ref.read(tempCuentasBancariasProvider.notifier).state = [];
        ref.read(tempEducacionListProvider.notifier).state = [];
        ref.read(tempFormacionListProvider.notifier).state = [];
        ref.read(tempExperienciaListProvider.notifier).state = [];
        ref.read(tempEmailListProvider.notifier).state = [];
        ref.read(tempTelefonoListProvider.notifier).state = [];
        ref.read(tempPersonaProvider.notifier).state = null;
         ref.invalidate(getListaEmpleados);
          ref.invalidate(detalleEmpleadoProvider);
          ref.invalidate(cargoActualEmpleadoProvider);
          ref.invalidate(getHistorialCargosEmpleado);
          ref.invalidate(getHistorialRelLabEmpleado);
          ref.invalidate(empObtenerDatosEmpleado);
          ref.invalidate(empObtenerDatosEmpleados);
        Navigator.of(context).pop(true);
      }
    } catch (e, st) {
      debugPrint('❌ [Error general] $e');
      debugPrint(st.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}