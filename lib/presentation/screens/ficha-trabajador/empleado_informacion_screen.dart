import 'package:bosque_flutter/core/state/empleados_dependientes_provider.dart';
import 'package:bosque_flutter/core/state/menu_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/ciExpedido_entity.dart';
import 'package:bosque_flutter/domain/entities/estado_civil_entity.dart';
import 'package:bosque_flutter/domain/entities/login_entity.dart';
import 'package:bosque_flutter/domain/entities/pais_entity.dart';
import 'package:bosque_flutter/domain/entities/sexo_entity.dart';
import 'package:bosque_flutter/presentation/widgets/dependientes/cronometro_bloqueo.dart';
import 'package:bosque_flutter/presentation/widgets/dependientes/email_seccion.dart';
import 'package:bosque_flutter/presentation/widgets/dependientes/experiencia_laboral_seccion.dart';
import 'package:bosque_flutter/presentation/widgets/dependientes/formacion_secccion.dart';
import 'package:bosque_flutter/presentation/widgets/dependientes/garante_referencia_seccion.dart';
import 'package:bosque_flutter/presentation/widgets/dependientes/persona_seccion.dart';
import 'package:bosque_flutter/presentation/widgets/dependientes/relacion_laboral_seccion.dart';
import 'package:bosque_flutter/presentation/widgets/dependientes/seccion_foto.dart';
import 'package:bosque_flutter/presentation/widgets/dependientes/telefono_secccion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

class InfoEmpleadoScreen extends ConsumerStatefulWidget {
  final int codEmpleado;
  const InfoEmpleadoScreen({Key? key, required this.codEmpleado})
    : super(key: key);

  @override
  ConsumerState<InfoEmpleadoScreen> createState() => _InfoEmpleadoScreenState();
}

class _InfoEmpleadoScreenState extends ConsumerState<InfoEmpleadoScreen> {
  final PageController _pageController = PageController();
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 0;
  int? _ultimoCodPersona;
  bool _mostrarHintPullToRefresh = true;
   int? _lastCodPersona; 

  Map<String, bool> estadoExpandido = {
    'empleado': true,
    'persona': true,
    'telefono': true,
    'correo': true,
    'formacionExp': true,
    'expLaboral': true,
    'garanteReferenciaExp': true,
    'relEmpExp': true,
    'foto': true,
  };

  Map<String, String?> selectedOperation = {
    'persona': null,
    'telefono': null,
    'email': null,
    'formacion': null,
    'experienciaLaboral': null,
    'garanteReferencia': null,
  };

  bool _habilitarEdicion = false;
  List<CiExpedidoEntity> listCiExpedido = [];
  List<EstadoCivilEntity> listEstCivil = [];
  List<PaisEntity> listPaises = [];
  List<SexoEntity> listGeneros = [];

  @override
  void initState() {
    super.initState();
    _verificarPermisosEdicion();
    Future.delayed(const Duration(seconds: 3), () {
    if (mounted) {
      setState(() {
        _mostrarHintPullToRefresh = false;
      });
    }
  });
   WidgetsBinding.instance.addPostFrameCallback((_) {
    ref.refresh(empObtenerDatosEmpleados(widget.codEmpleado));
    ref.refresh(formacionProvider(widget.codEmpleado));
    ref.refresh(experienciaLaboralProvider(widget.codEmpleado));
    ref.refresh(obtenerGaranteReferenciaProvider(widget.codEmpleado));
    ref.refresh(relacionLaboralProvider(widget.codEmpleado));
    ref.refresh(todosLosDocumentosProvider(widget.codEmpleado));
    ref.invalidate(documentosPendientesProvider);
  });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _verificarPermisosEdicion() async {
    try {
      final permissionService = ref.read(permissionServiceProvider);
      final hasPermission = await permissionService.verificarPermisosEdicion(
        widget.codEmpleado,
      );
      if (mounted) {
        setState(() {
          _habilitarEdicion = hasPermission;
        });
      }
    } catch (e) {
      debugPrint('Error al verificar permisos: $e');
      if (mounted) {
        setState(() {
          _habilitarEdicion = false;
        });
      }
    }
  }

  void toggleSeccion(String seccion) {
    setState(() {
      estadoExpandido[seccion] = !estadoExpandido[seccion]!;
    });
  }

  void activarEdicion(String seccion) {
    setState(() {
      _habilitarEdicion = true;
      selectedOperation[seccion] = 'editar';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtilsBosque.isDesktop(context);
    ref.listen<int>(warningCounterProvider, (prev, next) async {
    final user = ref.read(userProvider);
    if (user != null && user.codEmpleado == widget.codEmpleado) {
      if ((prev == null || prev == 0) && next == 1) {
        final codUsuario = await ref.read(userProvider.notifier).getCodUsuario();
        final now = DateTime.now();
        final fechaLimite = now.add(const Duration(minutes: 1));
        ref.read(registrarBloqueoUsuarioProvider({
          'codUsuario': codUsuario,
          'fechaAdvertencia': now,
          'fechaLimite': fechaLimite,
          'bloqueado': 0,
          'audUsuario': codUsuario,
        }));
      }
    }
  });
    return isDesktop ? _buildDesktopLayout() : _buildMobileLayout();
  }

 Widget _buildDesktopLayout() {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final size = MediaQuery.of(context).size;

  return Scaffold(
    backgroundColor: isDark ? Colors.grey[900] : Colors.grey[100],
    appBar: AppBar(
      title: const Text('Información del Empleado'),
    ),
    body: ref.watch(empObtenerDatosEmpleados(widget.codEmpleado)).when(
      data: (codPersona) {
        // Refresca los providers dependientes de codPersona solo si cambió
        if (_lastCodPersona != codPersona) {
          _lastCodPersona = codPersona;
          ref.refresh(obtenerPersonaProvider(codPersona));
          ref.refresh(telefonoProvider(codPersona));
          ref.refresh(emailProvider(codPersona));
        }
        return Column(
          children: [
            // Desktop navigation tabs
            Container(
              color: theme.primaryColor,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  _buildDesktopTab('Información', 0, Icons.person, codPersona),
                  const SizedBox(width: 12),
                  _buildDesktopTab('Formación', 1, Icons.school, codPersona),
                  const SizedBox(width: 12),
                  _buildDesktopTab('Experiencia', 2, Icons.work, codPersona),
                  const SizedBox(width: 12),
                //  _buildDesktopTab('Referencias', 3, Icons.people, codPersona),
                  // ...agrega más tabs si tienes...
                  const Spacer(),
                  if (_habilitarEdicion)
                  IconButton(
  icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
  tooltip: 'Exportar PDF',
  onPressed: () async {
    ref.invalidate(jasperPdfProvider(widget.codEmpleado));
    try {
      final pdfBytes = await ref.read(jasperPdfProvider(widget.codEmpleado).future);
      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
         name: 'RptFichaTrabajador', // ← nombre corregido
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo descargar el reporte PDF')),
      );
    }
  },
),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    tooltip: 'Refrescar',
                    onPressed: () {
                      ref.invalidate(empObtenerDatosEmpleados(widget.codEmpleado));
                      ref.invalidate(obtenerPersonaProvider(codPersona));
                      ref.invalidate(telefonoProvider(codPersona));
                      ref.invalidate(emailProvider(codPersona));
                      ref.invalidate(formacionProvider(widget.codEmpleado));
                      ref.invalidate(experienciaLaboralProvider(widget.codEmpleado));
                      ref.invalidate(obtenerGaranteReferenciaProvider(widget.codEmpleado));
                      ref.invalidate(relacionLaboralProvider(widget.codEmpleado));
                      ref.read(imageVersionProvider.notifier).state++;
                      ref.invalidate(todosLosDocumentosProvider(widget.codEmpleado));
                    },
                  ),
                  FutureBuilder<String>(
  future: ref.read(userProvider.notifier).getTipoUsuario(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const SizedBox.shrink();
    }
    if (snapshot.hasData && snapshot.data!.toUpperCase() == 'ROLE_ADM') {
      return Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: ElevatedButton.icon(
          icon: const Icon(Icons.warning_amber),
          label: const Text('Desbloquear Usuario'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
          ),
          /*onPressed: () async {
            await ref.read(warningCounterProvider.notifier).reset();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Contador de advertencias reseteado'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          },*/ // Lógica de reseteo aquí
          onPressed: () async {
  final usersAsync = ref.read(usersListProvider);
  usersAsync.when(
    data: (users) async {
      LoginEntity? user;
      try {
        user = users.firstWhere((u) => u.codEmpleado == widget.codEmpleado);
      } catch (e) {
        user = null;
      }
      if (user != null && user.codUsuario != null) {
        final result = await ref.read(desbloquearUsuarioProvider(user.codUsuario).future);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result
                  ? 'Usuario desbloqueado correctamente'
                  : 'No se pudo desbloquear el usuario'),
              backgroundColor: result ? Colors.green : Colors.red,
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se encontró el usuario para este empleado'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    },
    loading: () {
      // Puedes mostrar un loader si quieres
    },
    error: (e, _) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al obtener usuarios: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    },
  );
},
        ),
      );
    }
    return const SizedBox.shrink();
  },
),
                ],
              ),
            ),
            // Content area
            Expanded(
              child: SingleChildScrollView(
                key: ValueKey(_currentPage),
                padding: EdgeInsets.symmetric(
                  horizontal: size.width * 0.1,
                  vertical: 24,
                ),
                child: _buildDesktopPageContent(codPersona),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: Colors.teal),
      ),
      error: _buildErrorWidget,
    ),
  );
}
Widget _buildDesktopTab(String title, int page, IconData icon, int codPersona) {
  final isSelected = _currentPage == page;
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: InkWell(
      onTap: () {
  setState(() => _currentPage = page);
  _invalidateProvidersForTab(page, codPersona);
},
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Theme.of(context).primaryColor : Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Theme.of(context).primaryColor : Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
void _invalidateProvidersForTab(int page, int? codPersona) {
  switch (page) {
    case 0: // Información
      ref.invalidate(empObtenerDatosEmpleados(widget.codEmpleado));
      if (codPersona != null) {
        ref.invalidate(obtenerPersonaProvider(codPersona));
      }
      break;
    case 1: // Contacto
      if (codPersona != null) {
        ref.invalidate(telefonoProvider(codPersona));
        ref.invalidate(emailProvider(codPersona));
      }
      break;
    case 2: // Formación
      ref.invalidate(formacionProvider(widget.codEmpleado));
      break;
    case 3: // Experiencia
      ref.invalidate(experienciaLaboralProvider(widget.codEmpleado));
      break;
    case 4: // Referencias
      ref.invalidate(obtenerGaranteReferenciaProvider(widget.codEmpleado));
      break;
    case 5: // Laboral
      ref.invalidate(relacionLaboralProvider(widget.codEmpleado));
      break;
  }
}
Widget _buildDesktopPageContent(int codPersona) {
  switch (_currentPage) {
    case 0:
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left column with Photo and Relación Laboral
          Expanded(
            flex: 1,
            child: Column(
              children: [
                _buildSection(
                  child: SeccionFoto(
                    codEmpleado: widget.codEmpleado,
                    habilitarEdicion: _habilitarEdicion,
                    estadoExpandido: estadoExpandido,
                    onToggleSeccion: toggleSeccion,
                  ),
                ),
                const SizedBox(height: 24),
                _buildSection(
                  child: RelacionLaboralSeccion(
                    codEmpleado: widget.codEmpleado,
                    habilitarEdicion: _habilitarEdicion,
                    estadoExpandido: estadoExpandido,
                    onToggleSeccion: toggleSeccion,
                  ),
                ),
                const SizedBox(height: 24),
                _buildSection(
              child: TelefonoSection(
                codPersona: codPersona,
                habilitarEdicion: _habilitarEdicion,
                estadoExpandido: estadoExpandido,
                selectedOperation: selectedOperation,
                onToggleSeccion: toggleSeccion,
                onUpdateOperation: (op) =>
                    setState(() => selectedOperation['telefono'] = op),
                onEditar: () => activarEdicion('telefono'),
                onAgregar: () => (),
                onEliminar: () => (),
              ),
              
              
              
            ),
                const SizedBox(height: 24),
            _buildSection(
              child: EmailSeccion(
                codPersona: codPersona,
                habilitarEdicion: _habilitarEdicion,
                estadoExpandido: estadoExpandido,
                selectedOperation: selectedOperation,
                onToggleSeccion: toggleSeccion,
                onUpdateOperation: (op) =>
                    setState(() => selectedOperation['email'] = op),
                onEditar: () => activarEdicion('email'),
                onAgregar: () => (),
                onEliminar: () => (),
              ),
            ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          // Right column with Personal Info
          Expanded(
        flex: 2,
        child: Column(
          children: [
            if(_habilitarEdicion)
            Consumer(
        builder: (context, ref, _) {
          final usersAsync = ref.watch(usersListProvider);
          return usersAsync.when(
            data: (users) {
              LoginEntity? user;
try {
  user = users.firstWhere((u) => u.codEmpleado == widget.codEmpleado);
} catch (e) {
  user = null;
}
              if (user == null || user.codUsuario == null) return const SizedBox.shrink();

              final usuarioBloqueadoAsync = ref.watch(usuarioBloqueadoProvider(user.codUsuario!));
              final warningCount = ref.watch(warningCounterProvider);
              return usuarioBloqueadoAsync.when(
                data: (usuarioBloqueado) {
                  if (usuarioBloqueado == null) return const SizedBox.shrink();
                  // SOLO muestra el cronómetro si está bloqueado o hay advertencias activas
            if ((usuarioBloqueado.bloqueado != 1) && warningCount == 0) {
              return const SizedBox.shrink();
            }
                  return CronometroBloqueo(
                    fechaLimite: usuarioBloqueado.fechaLimite,
                    estaBloqueado: usuarioBloqueado.bloqueado == 1,
                    onFinalizado: () async {
  print('Cronómetro finalizado, intentando bloquear usuario...');
  final audUsuario = await ref.read(userProvider.notifier).getCodUsuario();
  final codUsuario = await ref.read(userProvider.notifier).getCodUsuario();
final now = DateTime.now();
await ref.read(registrarBloqueoUsuarioProvider({
  'codUsuario': codUsuario,
  'fechaAdvertencia': now,
  'fechaLimite': now,
  'bloqueado': 1,
  'audUsuario': codUsuario,
}).future);
await ref.read(menuProvider.notifier).fetchAndSaveMenu(codUsuario);
ref.invalidate(usuarioBloqueadoProvider(codUsuario));
},
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => Text('Error: $e'),
              );
            },
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => Text('Error: $e'),
          );
        },
      ),
            _buildSection(
              child: PersonaSection(
                codPersona: codPersona,
                codEmpleado: widget.codEmpleado,
                habilitarEdicion: _habilitarEdicion,
                estadoExpandido: estadoExpandido,
                selectedOperation: selectedOperation,
                onToggleSeccion: toggleSeccion,
                onUpdateOperation: (op) =>
                    setState(() => selectedOperation['persona'] = op),
                onEditar: () => activarEdicion('persona'),
              ),
            ),
          ],
        ),
      ),
        ],
      );
    case 1:

      return _buildSection(
        child: FormacionSecccion(
          codEmpleado: widget.codEmpleado,
          habilitarEdicion: _habilitarEdicion,
          estadoExpandido: estadoExpandido,
          selectedOperation: selectedOperation,
          onToggleSeccion: toggleSeccion,
          onUpdateOperation: (op) =>
              setState(() => selectedOperation['formacion'] = op),
          onEditar: () => activarEdicion('formacion'),
          onAgregar: () => (),
          onEliminar: () => (),
        ),
      );
      case 2:
      return _buildSection(
        child: ExperienciaLaboralSeccion(
          codEmpleado: widget.codEmpleado,
          habilitarEdicion: _habilitarEdicion,
          estadoExpandido: estadoExpandido,
          selectedOperation: selectedOperation,
          onToggleSeccion: toggleSeccion,
          onUpdateOperation: (op) =>
              setState(() => selectedOperation['experienciaLaboral'] = op),
          onEditar: () => activarEdicion('experienciaLaboral'),
          onAgregar: () => (),
          onEliminar: () => (),
        ),
      );

   /* case 3:
      return _buildSection(
        child: GaranteReferenciaSeccion(
          codEmpleado: widget.codEmpleado,
          habilitarEdicion: _habilitarEdicion,
          estadoExpandido: estadoExpandido,
          selectedOperation: selectedOperation,
          onToggleSeccion: toggleSeccion,
          onUpdateOperation: (op) =>
              setState(() => selectedOperation['garanteReferencia'] = op),
          onEditar: () => activarEdicion('garanteReferencia'),
          onAgregar: () => (),
          onEliminar: () => (),
          filtroTipo: 'todos',
        ),
      );*/

    // ... Add remaining cases for other sections ...
    default:
      return const Center(child: Text('Sección no implementada'));
  }
}
  Widget _buildMobileLayout() {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  return Scaffold(
    backgroundColor: isDark ? Colors.grey[900] : Colors.grey[100],
    appBar: AppBar(
      elevation: 4,
      backgroundColor: theme.primaryColor,
      title: Text(
        'Información del Empleado',
        style: TextStyle(
          color: isDark ? Colors.white : Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        if (_habilitarEdicion)
        IconButton(
    icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
    tooltip: 'Exportar PDF Jasper',
    onPressed: () async {
      ref.invalidate(jasperPdfProvider(widget.codEmpleado));
      try {
        final pdfBytes = await ref.read(jasperPdfProvider(widget.codEmpleado).future);
        await Printing.layoutPdf(
          onLayout: (format) async => pdfBytes,
          name: 'RptFichaTrabajador',
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo descargar el reporte PDF')),
        );
      }
    },
  ),
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          tooltip: 'Refrescar',
          onPressed: () {
            ref.invalidate(empObtenerDatosEmpleados(widget.codEmpleado));
            ref.invalidate(formacionProvider(widget.codEmpleado));
            ref.invalidate(experienciaLaboralProvider(widget.codEmpleado));
            ref.invalidate(obtenerGaranteReferenciaProvider(widget.codEmpleado));
            ref.invalidate(relacionLaboralProvider(widget.codEmpleado));
             ref.invalidate(todosLosDocumentosProvider(widget.codEmpleado));
            if (_ultimoCodPersona != null) {
              ref.invalidate(obtenerPersonaProvider(_ultimoCodPersona!));
              ref.invalidate(telefonoProvider(_ultimoCodPersona!));
              ref.invalidate(emailProvider(_ultimoCodPersona!));
            }
          },
        ),
       /* FutureBuilder<String>(
  future: ref.read(userProvider.notifier).getTipoUsuario(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const SizedBox.shrink();
    }
    if (snapshot.hasData && snapshot.data!.toUpperCase() == 'ROLE_ADM') {
      return IconButton(
        icon: const Icon(Icons.warning_amber, color: Colors.orange),
        tooltip: 'Resetear advertencias',
        onPressed: () async {
          await ref.read(warningCounterProvider.notifier).reset();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Contador de advertencias reseteado'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
      );
    }
    return const SizedBox.shrink();
  },
),*/ // Lógica de reseteo aquí
FutureBuilder<String>(
  future: ref.read(userProvider.notifier).getTipoUsuario(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const SizedBox.shrink();
    }
    if (snapshot.hasData && snapshot.data!.toUpperCase() == 'ROLE_ADM') {
      return IconButton(
        icon: const Icon(Icons.warning_amber, color: Colors.orange),
        tooltip: 'Desbloquear usuario',
        onPressed: () async {
          final usersAsync = ref.read(usersListProvider);
          usersAsync.when(
            data: (users) async {
              LoginEntity? user;
              try {
                user = users.firstWhere((u) => u.codEmpleado == widget.codEmpleado);
              } catch (e) {
                user = null;
              }
              if (user != null && user.codUsuario != null) {
                final result = await ref.read(desbloquearUsuarioProvider(user.codUsuario).future);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result
                          ? 'Usuario desbloqueado correctamente'
                          : 'No se pudo desbloquear el usuario'),
                      backgroundColor: result ? Colors.green : Colors.red,
                    ),
                  );
                }
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No se encontró el usuario para este empleado'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            loading: () {
              // Puedes mostrar un loader si quieres
            },
            error: (e, _) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al obtener usuarios: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          );
        },
      );
    }
    return const SizedBox.shrink();
  },
),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: ref.watch(empObtenerDatosEmpleados(widget.codEmpleado)).when(
          data: (codPersona) {
            _ultimoCodPersona = codPersona;
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _buildMobileNavButton('Info', 0, Icons.person, codPersona),
                  _buildMobileNavButton('Contacto', 1, Icons.contact_phone, codPersona),
                  _buildMobileNavButton('Formación', 2, Icons.school, codPersona),
                  _buildMobileNavButton('Experiencia', 3, Icons.work, codPersona),
                 // _buildMobileNavButton('Referencias', 4, Icons.people, codPersona),
                  _buildMobileNavButton('Laboral', 4, Icons.business, codPersona),
                ],
              ),
            );
          },
          loading: () => const SizedBox(height: 48),
          error: (error, stack) => const SizedBox(height: 48),
        ),
      ),
    ),
    body: ref.watch(empObtenerDatosEmpleados(widget.codEmpleado)).when(
      data: (codPersona) {
        _ultimoCodPersona = codPersona;
         Future.microtask(() {
      ref.refresh(obtenerPersonaProvider(codPersona));
      ref.refresh(telefonoProvider(codPersona));
      ref.refresh(emailProvider(codPersona));
    });
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(empObtenerDatosEmpleados(widget.codEmpleado));
            ref.invalidate(obtenerPersonaProvider(codPersona));
            ref.invalidate(telefonoProvider(codPersona));
            ref.invalidate(emailProvider(codPersona));
            ref.invalidate(formacionProvider(widget.codEmpleado));
            ref.invalidate(experienciaLaboralProvider(widget.codEmpleado));
            ref.invalidate(obtenerGaranteReferenciaProvider(widget.codEmpleado));
            ref.invalidate(relacionLaboralProvider(widget.codEmpleado));
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              if (_currentPage == 0) _buildInfoPage(codPersona),
              if (_currentPage == 1) _buildContactPage(codPersona),
              if (_currentPage == 2) _buildFormacionPage(),
              if (_currentPage == 3) _buildExperienciaPage(),
            //  if (_currentPage == 4) _buildReferenciasPage(),
              if (_currentPage == 4) _buildLaboralPage(),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: Colors.teal),
      ),
      error: _buildErrorWidget,
    ),
  );
}

  Widget _buildInfoPage(int codPersona) {
    return SingleChildScrollView(
      key: ValueKey(codPersona),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (_mostrarHintPullToRefresh)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.swipe_down, size: 18, color: Colors.grey),
                SizedBox(width: 6),
                Text(
                  'Desliza hacia abajo para actualizar',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),
          Consumer(
          builder: (context, ref, _) {
            final usersAsync = ref.watch(usersListProvider);
            return usersAsync.when(
              data: (users) {
                LoginEntity? user;
                try {
                  user = users.firstWhere((u) => u.codEmpleado == widget.codEmpleado);
                } catch (e) {
                  user = null;
                }
                if (user == null || user.codUsuario == null) return const SizedBox.shrink();

                final usuarioBloqueadoAsync = ref.watch(usuarioBloqueadoProvider(user.codUsuario!));
                final warningCount = ref.watch(warningCounterProvider);
                return usuarioBloqueadoAsync.when(
                  data: (usuarioBloqueado) {
                    if (usuarioBloqueado == null) return const SizedBox.shrink();
                    if ((usuarioBloqueado.bloqueado != 1) && warningCount == 0) {
                      return const SizedBox.shrink();
                    }
                    return CronometroBloqueo(
                      fechaLimite: usuarioBloqueado.fechaLimite,
                      estaBloqueado: usuarioBloqueado.bloqueado == 1,
                      onFinalizado: () async {
                        print('Cronómetro finalizado, intentando bloquear usuario...');
                        final codUsuario = await ref.read(userProvider.notifier).getCodUsuario();
                        final now = DateTime.now();
                        await ref.read(registrarBloqueoUsuarioProvider({
                          'codUsuario': codUsuario,
                          'fechaAdvertencia': now,
                          'fechaLimite': now,
                          'bloqueado': 1,
                          'audUsuario': codUsuario,
                        }).future);
                        await ref.read(menuProvider.notifier).fetchAndSaveMenu(codUsuario);
                        ref.invalidate(usuarioBloqueadoProvider(codUsuario));
                      },
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (e, _) => Text('Error: $e'),
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Error: $e'),
            );
          },
        ),
          _buildSection(
            child: SeccionFoto(
              codEmpleado: widget.codEmpleado,
              habilitarEdicion: _habilitarEdicion,
              estadoExpandido: estadoExpandido,
              onToggleSeccion: toggleSeccion,
            ),
          ),
          const SizedBox(height: 16),
          _buildSection(
            child: PersonaSection(
              codPersona: codPersona,
              codEmpleado: widget.codEmpleado,
              habilitarEdicion: _habilitarEdicion,
              estadoExpandido: estadoExpandido,
              selectedOperation: selectedOperation,
              onToggleSeccion: toggleSeccion,
              onUpdateOperation: (op) =>
                  setState(() => selectedOperation['persona'] = op),
              onEditar: () => activarEdicion('persona'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactPage(int codPersona) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSection(
            child: TelefonoSection(
              codPersona: codPersona,
              habilitarEdicion: _habilitarEdicion,
              estadoExpandido: estadoExpandido,
              selectedOperation: selectedOperation,
              onToggleSeccion: toggleSeccion,
              onUpdateOperation: (op) =>
                  setState(() => selectedOperation['telefono'] = op),
              onEditar: () => activarEdicion('telefono'),
              onAgregar: () => (),
              onEliminar: () => (),
            ),
          ),
          const SizedBox(height: 16),
          _buildSection(
            child: EmailSeccion(
              codPersona: codPersona,
              habilitarEdicion: _habilitarEdicion,
              estadoExpandido: estadoExpandido,
              selectedOperation: selectedOperation,
              onToggleSeccion: toggleSeccion,
              onUpdateOperation: (op) =>
                  setState(() => selectedOperation['email'] = op),
              onEditar: () => activarEdicion('email'),
              onAgregar: () => (),
              onEliminar: () => (),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormacionPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _buildSection(
        child: FormacionSecccion(
          codEmpleado: widget.codEmpleado,
          habilitarEdicion: _habilitarEdicion,
          estadoExpandido: estadoExpandido,
          selectedOperation: selectedOperation,
          onToggleSeccion: toggleSeccion,
          onUpdateOperation: (op) =>
              setState(() => selectedOperation['formacion'] = op),
          onEditar: () => activarEdicion('formacion'),
          onAgregar: () => (),
          onEliminar: () => (),
        ),
      ),
    );
  }

  Widget _buildExperienciaPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _buildSection(
        child: ExperienciaLaboralSeccion(
          codEmpleado: widget.codEmpleado,
          habilitarEdicion: _habilitarEdicion,
          estadoExpandido: estadoExpandido,
          selectedOperation: selectedOperation,
          onToggleSeccion: toggleSeccion,
          onUpdateOperation: (op) =>
              setState(() => selectedOperation['experienciaLaboral'] = op),
          onEditar: () => activarEdicion('experienciaLaboral'),
          onAgregar: () => (),
          onEliminar: () => (),
        ),
      ),
    );
  }

  Widget _buildReferenciasPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _buildSection(
        child: GaranteReferenciaSeccion(
          codEmpleado: widget.codEmpleado,
          habilitarEdicion: _habilitarEdicion,
          estadoExpandido: estadoExpandido,
          selectedOperation: selectedOperation,
          onToggleSeccion: toggleSeccion,
          onUpdateOperation: (op) =>
              setState(() => selectedOperation['garanteReferencia'] = op),
          onEditar: () => activarEdicion('garanteReferencia'),
          onAgregar: () => (),
          onEliminar: () => (),
          filtroTipo: 'todos',
        ),
      ),
    );
  }

  Widget _buildLaboralPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _buildSection(
        child: RelacionLaboralSeccion(
          codEmpleado: widget.codEmpleado,
          habilitarEdicion: _habilitarEdicion,
          estadoExpandido: estadoExpandido,
          onToggleSeccion: toggleSeccion,
        ),
      ),
    );
  }
//checkpoint 2
 Widget _buildMobileNavButton(String title, int page, IconData icon,int codPersona) {
  final isSelected = _currentPage == page;
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  return Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ElevatedButton.icon(
      icon: Icon(
        icon,
        size: 18,
        color: isSelected
            ? theme.primaryColor
            : isDark ? Colors.white : Colors.white,
      ),
      label: Text(
        title,
        style: TextStyle(
          color: isSelected
              ? theme.primaryColor
              : isDark ? Colors.white : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
     onPressed: () {
  setState(() => _currentPage = page);
  _invalidateProvidersForTab(page, codPersona);
},
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected
            ? (isDark ? Colors.white : Colors.white)
            : Colors.transparent,
        elevation: isSelected ? 4 : 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isDark ? Colors.white70 : Colors.white,
            width: isSelected ? 2 : 1,
          ),
        ),
      ),
    ),
  );
}

  Widget _buildSection({required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: child,
      ),
    );
  }

  Widget _buildErrorWidget(Object error, StackTrace stack) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red[400], size: 48),
            const SizedBox(height: 16),
            Text(
              'Error al cargar los datos',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
