import 'package:bosque_flutter/presentation/widgets/registro_empleado/detalle_afiliacion_seguro.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/empleados_dependientes_provider.dart';
import 'package:bosque_flutter/domain/entities/empleado_entity.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/detalle_informacion_bancaria.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/detalle_licencia_conducir.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/detalle_persona.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/detalle_email.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/detalle_telefono.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/detalle_educacion.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/detalle_formacion.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/detalle_exp_lab.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/detalle_informacion_laboral.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/foto_perfil_empleado.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/responsive_utils_registro_empleado.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/seccion_fotos.dart';

class DetalleEmpleado extends ConsumerStatefulWidget {
  final int codEmpleado;
  const DetalleEmpleado({Key? key, required this.codEmpleado})
    : super(key: key);

  @override
  ConsumerState<DetalleEmpleado> createState() => _DetalleEmpleadoState();
}

class _DetalleEmpleadoState extends ConsumerState<DetalleEmpleado> {
  static const String mode = 'edicion';

  @override
  Widget build(BuildContext context) {
    final empleadoAsync = ref.watch(
      empObtenerDatosEmpleado(widget.codEmpleado),
    );

    return empleadoAsync.when(
      loading:
          () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(body: Center(child: Text('Error: $err'))),
      data: (empleado) {
        return DefaultTabController(
          length: 6,
          child: Scaffold(
            backgroundColor: const Color(0xFFF8F9FA),
            appBar: AppBar(
              title: Text(
                '${empleado.persona.nombres} ${empleado.persona.apPaterno}',
              ),
              bottom: TabBar(
                isScrollable: context.isMobile, // Hacer scrollable en móvil
                tabs: const [
                  Tab(text: 'Perfil', icon: Icon(Icons.person)),
                  Tab(text: 'Laboral', icon: Icon(Icons.work)),
                  Tab(text: 'Formación', icon: Icon(Icons.school)),
                  Tab(text: 'Experiencia', icon: Icon(Icons.history_edu)),
                  Tab(text: 'Bancario', icon: Icon(Icons.account_balance)),
                  Tab(
                    text: 'Seguros',
                    icon: Icon(Icons.medical_services_outlined),
                  ),
                ],
              ),
            ),
            body: _buildBody(empleado),
          ),
        );
      },
    );
  }

  Widget _buildBody(EmpleadoEntity empleado) {
    final personaAsync = ref.watch(obtenerPersonaProvider(empleado.codPersona));

    return personaAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (persona) {
        return Column(
          children: [
            _buildHeaderCompacto(empleado, persona),
            Expanded(
              child: TabBarView(
                children: [
                  _tabPerfil(empleado, persona),
                  _tabWrap(
                    DetalleInformacionLaboral(
                      codEmpleado: empleado.codEmpleado,
                    ),
                  ),
                  _tabWrap(
                    Column(
                      children: [
                        DetalleEducacion(
                          codEmpleado: empleado.codEmpleado,
                          mode: mode,
                        ),
                        SizedBox(
                          height: context.spacing,
                        ), // Usar context.spacing
                        DetalleFormacion(
                          codEmpleado: empleado.codEmpleado,
                          mode: mode,
                        ),
                      ],
                    ),
                  ),
                  _tabWrap(
                    DetalleExperienciaLaboral(
                      codEmpleado: empleado.codEmpleado,
                      mode: mode,
                    ),
                  ),
                  _tabWrap(
                    DetalleInformacionBancaria(
                      codEmpleado: empleado.codEmpleado,
                      mode: mode,
                    ),
                  ),
                  _tabWrap(
                    DetalleAfiliacionSeguro(codEmpleado: empleado.codEmpleado),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _tabPerfil(EmpleadoEntity empleado, dynamic persona) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(context.spacing), // Usar context.spacing
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 800;

          // Columnas para layout web (sin cambios)
          final columnLeft = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCardSimple(
                SeccionFotoEmpleado(codEmpleado: empleado.codEmpleado),
              ),
              SizedBox(height: context.spacing),
              DetalleDocumentosEmpleado(codEmpleado: empleado.codEmpleado),
              SizedBox(height: context.spacing),
              _buildCardSimple(
                Column(
                  children: [
                    DetalleEmail(codPersona: empleado.codPersona, mode: mode),
                    Divider(height: context.largeSpacing),
                    DetalleTelefono(
                      codPersona: empleado.codPersona,
                      mode: mode,
                    ),
                  ],
                ),
              ),
            ],
          );

          final columnRight = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCardSimple(DetallePersona(persona: persona, mode: mode)),
              SizedBox(height: context.spacing),
              _buildCardSimple(
                DetalleLicenciaConducir(codPersona: empleado.codPersona),
              ),
            ],
          );

          if (wide) {
            // Layout web
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 380, child: columnLeft),
                SizedBox(width: context.spacing),
                Expanded(child: columnRight),
              ],
            );
          } else {
            // Layout móvil con el nuevo orden
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildCardSimple(
                  SeccionFotoEmpleado(codEmpleado: empleado.codEmpleado),
                ),
                SizedBox(height: context.spacing),
                DetalleDocumentosEmpleado(codEmpleado: empleado.codEmpleado),
                SizedBox(height: context.spacing),
                _buildCardSimple(DetallePersona(persona: persona, mode: mode)),
                SizedBox(height: context.spacing),
                _buildCardSimple(
                  DetalleTelefono(codPersona: empleado.codPersona, mode: mode),
                ),
                SizedBox(height: context.spacing),
                _buildCardSimple(
                  DetalleEmail(codPersona: empleado.codPersona, mode: mode),
                ),
                SizedBox(height: context.spacing),
                _buildCardSimple(
                  DetalleLicenciaConducir(codPersona: empleado.codPersona),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildHeaderCompacto(EmpleadoEntity empleado, dynamic persona) {
    return Container(
      padding: EdgeInsets.all(
        context.smallSpacing,
      ), // Usar context.smallSpacing
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.badge,
            color: Theme.of(context).primaryColor,
            size: context.iconSize,
          ), // Usar Theme.of(context).primaryColor y context.iconSize
          SizedBox(width: context.spacing), // Usar context.spacing
          Text(
            'ID: ${empleado.codEmpleado}',
            style: context.bodyStyle.copyWith(fontWeight: FontWeight.bold),
          ), // Usar context.bodyStyle
          const Spacer(),
          Text(
            '${empleado.persona.datoPersona}',
            style: context.bodyLightStyle,
          ), // Usar context.bodyLightStyle
        ],
      ),
    );
  }

  Widget _buildCardSimple(Widget child) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: context.borderRadius, // Usar context.borderRadius
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: EdgeInsets.all(context.spacing),
        child: child,
      ), // Usar context.spacing
    );
  }

  Widget _tabWrap(Widget child) => SingleChildScrollView(
    padding: EdgeInsets.all(context.spacing),
    child: child,
  ); // Usar context.spacing
}
