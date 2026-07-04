import 'package:bosque_flutter/core/state/permisos_vacacion_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/domain/entities/solicitud_permiso_entity.dart';
import 'package:intl/intl.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/registro_empleado_utils.dart';
import 'package:bosque_flutter/domain/entities/tipo_permiso_vacacion_entity.dart';
import 'package:bosque_flutter/presentation/widgets/permisos-vacaciones/custom_range_picker_dialog.dart';

class SolicitudPermisoForm extends ConsumerStatefulWidget {
  final int codEmpleado;
  final int codRelEmplEmpr;
  final int audUsuarioI;
  final SolicitudPermisoEntity? solicitudAEditar;

  const SolicitudPermisoForm({
    super.key,
    required this.codEmpleado,
    required this.codRelEmplEmpr,
    required this.audUsuarioI,
    this.solicitudAEditar,
  });

  /// Método estático de ayuda para invocar el modal fácilmente desde cualquier pantalla
  static void mostrar(
    BuildContext context, {
    required int codEmpleado,
    required int codRelEmplEmpr,
    required int audUsuarioI,
    SolicitudPermisoEntity? solicitudAEditar,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => SolicitudPermisoForm(
            codEmpleado: codEmpleado,
            codRelEmplEmpr: codRelEmplEmpr,
            audUsuarioI: audUsuarioI,
            solicitudAEditar: solicitudAEditar,
          ),
    );
  }

  @override
  ConsumerState<SolicitudPermisoForm> createState() =>
      _SolicitudPermisoFormState();
}

class _SolicitudPermisoFormState extends ConsumerState<SolicitudPermisoForm> {
  final _formKey = GlobalKey<FormState>();
  final _motivoController = TextEditingController();

  String _tipoPermiso = 'vac'; // Valor por defecto

  // ── Previsualización On-The-Fly ──
  SolicitudPermisoEntity? _previewResult;
  bool _isLoadingPreview = false;

  // Rango de fechas
  DateTime _fechaDesde = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );
  DateTime _fechaHasta = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  // Rango de horas (strings fijos cada 30 min)
  String _horaInicio = '08:00';
  String _horaFin = '16:30';

  // 🌟 Se incorporan las franjas de 08:00, 13:00, 13:30, 14:00 e intermedia de salida.
  final List<String> _horariosPermitidos = [
    '08:00',
    '08:30',
    '09:00',
    '09:30',
    '10:00',
    '10:30',
    '11:00',
    '11:30',
    '12:00',
    '12:30',
    '13:00',
    '13:30',
    '14:00',
    '14:30',
    '15:00',
    '15:30',
    '16:00',
    '16:30',
    '17:00',
    '17:30',
    '18:00',
    '18:30',
    '19:00',
  ];

  void _actualizarHoraFin(String nuevaHoraInicio) {
    setState(() {
      _horaInicio = nuevaHoraInicio;

      final hhMmIni = nuevaHoraInicio.split(':');
      final iniDateTime = DateTime(
        2000,
        1,
        1,
        int.parse(hhMmIni[0]),
        int.parse(hhMmIni[1]),
      );

      // Añadimos 8 horas y 30 minutos por defecto (jornada de 8h + 30m de almuerzo)
      DateTime finDateTime = iniDateTime.add(
        const Duration(hours: 8, minutes: 30),
      );

      // Si la hora de fin supera las 19:00, la limitamos a las 19:00
      if (finDateTime.hour > 19 ||
          (finDateTime.hour == 19 && finDateTime.minute > 0)) {
        finDateTime = DateTime(2000, 1, 1, 19, 0);
      }

      String formattedFin = DateFormat('HH:mm').format(finDateTime);
      if (_horariosPermitidos.contains(formattedFin)) {
        _horaFin = formattedFin;
      } else {
        _horaFin = '19:00';
      }
    });
    _calcularOnTheFly();
  }

  void _calcularOnTheFly() async {
    if (!mounted) return;
    setState(() {
      _isLoadingPreview = true;
    });
    try {
      final hhMmIni = _horaInicio.split(':');
      final hhMmFin = _horaFin.split(':');
      final desde = DateTime(
        _fechaDesde.year,
        _fechaDesde.month,
        _fechaDesde.day,
        int.parse(hhMmIni[0]),
        int.parse(hhMmIni[1]),
      );
      final hasta = DateTime(
        _fechaHasta.year,
        _fechaHasta.month,
        _fechaHasta.day,
        int.parse(hhMmFin[0]),
        int.parse(hhMmFin[1]),
      );

      final filtro = SolicitudPermisoEntity(
        codEmpleado: widget.codEmpleado,
        codRelEmplEmpr: widget.codRelEmplEmpr,
        tipoPermiso: _tipoPermiso,
        desde: desde,
        hasta: hasta,
        motivo: '',
        cantidadDias: 0.0,
        estado: 1,
        audUsuarioI: widget.audUsuarioI,
      );

      final result = await ref
          .read(permisosVacacionRepositoryProvider)
          .previsualizarSaldo(filtro);
      if (mounted) {
        setState(() {
          _previewResult = result;
          _isLoadingPreview = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _previewResult = null;
          _isLoadingPreview = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _motivoController.dispose();
    super.dispose();
  }

  String _formatearDiasYHoras(double? dias) {
    if (dias == null) return '0 días';
    final bool esNegativo = dias < 0;
    final double valorAbs = dias.abs();

    final int diasEnteros = valorAbs.floor();
    final double fraccionDia = valorAbs - diasEnteros;
    // Asumiendo jornada laboral de 8 horas
    final double horas = fraccionDia * 8;
    // Redondeamos al 0.5 más cercano
    final double horasRedondeadas = (horas * 2).round() / 2;

    int diasFinales = diasEnteros;
    double horasFinales = horasRedondeadas;
    if (horasRedondeadas >= 8.0) {
      diasFinales += 1;
      horasFinales = 0.0;
    }

    final List<String> partes = [];
    if (diasFinales > 0) {
      partes.add('$diasFinales ${diasFinales == 1 ? "día" : "días"}');
    }
    if (horasFinales > 0) {
      if (horasFinales % 1 == 0) {
        partes.add(
          '${horasFinales.toInt()} ${horasFinales.toInt() == 1 ? "hr" : "hrs"}',
        );
      } else {
        partes.add('${horasFinales.toStringAsFixed(1)} hrs');
      }
    }

    if (partes.isEmpty) {
      return '0 días';
    }

    final String prefijo = esNegativo ? '-' : '';
    return '$prefijo${partes.join(" y ")}';
  }

  @override
  void initState() {
    super.initState();
    if (widget.solicitudAEditar != null) {
      final s = widget.solicitudAEditar!;
      _tipoPermiso = s.tipoPermiso;
      _motivoController.text = s.motivo;
      _fechaDesde = s.desde;
      _fechaHasta = s.hasta;

      // Formateamos las horas para que coincidan con el Dropdown (HH:mm)
      String formattedInicio = DateFormat('HH:mm').format(s.desde);
      if (_horariosPermitidos.contains(formattedInicio)) {
        _horaInicio = formattedInicio;
      }

      String formattedFin = DateFormat('HH:mm').format(s.hasta);
      if (_horariosPermitidos.contains(formattedFin)) {
        _horaFin = formattedFin;
      }
    }

    // Calculamos el saldo on-the-fly al inicio
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calcularOnTheFly();
    });
  }

  // Eliminado: lógica de switch _porHoras

  void _enviarSolicitud() {
    if (!_formKey.currentState!.validate()) return;

    // Ocultar teclado
    FocusScope.of(context).unfocus();

    final hhMmIni = _horaInicio.split(':');
    final hhMmFin = _horaFin.split(':');

    final DateTime fechaDesdeFinal = DateTime(
      _fechaDesde.year,
      _fechaDesde.month,
      _fechaDesde.day,
      int.parse(hhMmIni[0]),
      int.parse(hhMmIni[1]),
    );

    final DateTime fechaHastaFinal = DateTime(
      _fechaHasta.year,
      _fechaHasta.month,
      _fechaHasta.day,
      int.parse(hhMmFin[0]),
      int.parse(hhMmFin[1]),
    );

    final solicitud = SolicitudPermisoEntity(
      codSolicitud: widget.solicitudAEditar?.codSolicitud ?? 0,
      codEmpleado: widget.codEmpleado,
      codRelEmplEmpr: widget.codRelEmplEmpr,
      tipoPermiso: _tipoPermiso,
      desde: fechaDesdeFinal,
      hasta: fechaHastaFinal,
      motivo: _motivoController.text,
      cantidadDias:
          0.0, // Deja en 0, tu backend calculará los decimales (ej. 0.5 o 0.25)
      estado: 1,
      audUsuarioI: widget.audUsuarioI,
    );

    final saldoRestante = _previewResult?.saldoRestante ?? 0.0;
    if (saldoRestante < 0) {
      final saldoFaltanteTexto = _formatearDiasYHoras(saldoRestante.abs());
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(child: Text('Solicitud de permiso')),
                ],
              ),
              content: Text(
                'Estás solicitando más días de los que tienes disponibles.\n\n'
                'Quedarás con un saldo de -$saldoFaltanteTexto, los cuales se descontarán automáticamente de tus próximas vacaciones cuando te sean asignadas.\n\n'
                '¿Deseas confirmar esta solicitud?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _procesarEnvio(solicitud);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Confirmar y Enviar'),
                ),
              ],
            ),
      );
    } else {
      _procesarEnvio(solicitud);
    }
  }

  void _procesarEnvio(SolicitudPermisoEntity solicitud) {
    ref
        .read(enviarSolicitudPermisoProvider.notifier)
        .ejecutar(
          solicitud,
          onSuccess: (mensaje) {
            // Invalidamos los providers para que se recarguen las listas
            ref.invalidate(misSolicitudesProvider);
            ref.invalidate(solicitudesPendientesProvider);

            Navigator.pop(context); // Cierra el modal
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(mensaje), backgroundColor: Colors.green),
            );
          },
          onError: (error) {
            // Muestra el mensaje de error que viene directo desde SQL
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error), backgroundColor: Colors.red),
            );
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    // Obtenemos el estado para deshabilitar el botón si está cargando
    final estadoEnvio = ref.watch(enviarSolicitudPermisoProvider);
    final isLoading = estadoEnvio is AsyncLoading;

    // Obtenemos la lista de feriados
    final asyncFeriados = ref.watch(feriadosProvider(widget.codEmpleado));
    final feriados = asyncFeriados.value ?? [];

    final hPadding = ResponsiveUtilsBosque.getHorizontalPadding(context);
    final vPadding = ResponsiveUtilsBosque.getVerticalPadding(context);

    return Padding(
      // Padding dinámico para que el teclado no tape el formulario
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: hPadding,
        right: hPadding,
        top: vPadding,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Solicitar Permiso / Vacación',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // TIPO DE PERMISO
              CustomDropdown<TipoPermisoVacacionEntity>(
                asyncValue: ref.watch(tiposPermisoProvider),
                label: 'Tipo de Permiso',
                currentValue: _tipoPermiso,
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _tipoPermiso = val);
                    _calcularOnTheFly();
                  }
                },
                getName: (e) => e.nombre,
                getCode: (e) => e.codTipos,
              ),
              const SizedBox(height: 16),

              // FECHAS (Rango unificado en un diálogo dialog compactado)
              _buildFechaSelector(
                label: 'Rango de Días',
                texto:
                    '${DateFormat('dd/MM/yyyy').format(_fechaDesde)}  →  ${DateFormat('dd/MM/yyyy').format(_fechaHasta)}',
                onTap: () async {
                  final range = await showCustomRangePickerDialog(
                    context: context,
                    initialStartDate: _fechaDesde,
                    initialEndDate: _fechaHasta,
                    feriados: feriados,
                  );
                  if (range != null && range.isNotEmpty) {
                    setState(() {
                      _fechaDesde = range.first ?? _fechaDesde;
                      _fechaHasta = range.last ?? _fechaHasta;
                    });
                    _calcularOnTheFly();
                  }
                },
              ),
              const SizedBox(height: 16),

              // HORAS (Dropdowns limitados a rangos específicos de 30 mins)
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _horaInicio,
                      isDense: true,
                      menuMaxHeight: 250,
                      decoration: const InputDecoration(
                        labelText: 'Hora Inicio',
                        prefixIcon: Icon(Icons.access_time, size: 18),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                      ),
                      items:
                          _horariosPermitidos
                              .map(
                                (h) =>
                                    DropdownMenuItem(value: h, child: Text(h)),
                              )
                              .toList(),
                      onChanged: (val) {
                        if (val != null) _actualizarHoraFin(val);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _horaFin,
                      isDense: true,
                      menuMaxHeight: 250,
                      decoration: const InputDecoration(
                        labelText: 'Hora Fin',
                        prefixIcon: Icon(Icons.access_time, size: 18),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                      ),
                      items:
                          _horariosPermitidos
                              .map(
                                (h) =>
                                    DropdownMenuItem(value: h, child: Text(h)),
                              )
                              .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _horaFin = val);
                          _calcularOnTheFly();
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // MOTIVO
              TextFormField(
                controller: _motivoController,
                decoration: const InputDecoration(
                  labelText: 'Motivo / Justificación',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                maxLines: 2,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'El motivo es obligatorio';
                  }
                  // Permite letras (con tildes y ñ), números, espacios y puntuación básica (. , - ( ) / :)
                  final regex = RegExp(
                    r'^[a-zA-Z0-9áéíóúüñÁÉÍÓÚÜÑ\s.,()\-/:#]+$',
                  );
                  if (!regex.hasMatch(val)) {
                    return 'El motivo contiene caracteres especiales no permitidos';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ── TARJETA DE PREVISUALIZACIÓN DE SALDO ──
              if (_isLoadingPreview)
                const Center(child: CircularProgressIndicator())
              else if (_previewResult != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Previsualización de Días',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Días a solicitar:'),
                          Text(
                            _formatearDiasYHoras(
                              _previewResult!.diasSolicitados,
                            ),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      if (_tipoPermiso == 'vac' || _tipoPermiso == 'pva') ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Saldo actual:'),
                            Text(
                              _formatearDiasYHoras(
                                _previewResult!.saldoActualBase,
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Saldo restante (proyectado):'),
                            Text(
                              _formatearDiasYHoras(
                                _previewResult!.saldoRestante,
                              ),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color:
                                    (_previewResult!.saldoRestante ?? 0.0) < 0
                                        ? Colors.orange[800]
                                        : Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if ((_previewResult!.saldoRestante ?? 0.0) < 0 &&
                          (_tipoPermiso == 'vac' || _tipoPermiso == 'pva')) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.orange.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: Colors.orange,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Solicitarás vacación de ${_formatearDiasYHoras(_previewResult!.saldoRestante!.abs())}, que se descontarán de tus futuras asignaciones de vacación.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange[800],
                                    fontWeight: FontWeight.w500,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else if (_tipoPermiso != 'vac' &&
                          _tipoPermiso != 'pva' &&
                          _tipoPermiso != '') ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.blue.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: Colors.blue,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Nota: Este tipo de permiso no descuenta los dias disponibles.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue[800],
                                    fontWeight: FontWeight.w500,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 24),

              // BOTÓN DE ENVÍO
              ElevatedButton(
                onPressed:
                    (isLoading || _isLoadingPreview) ? null : _enviarSolicitud,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child:
                    (isLoading || _isLoadingPreview)
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : Text(
                          widget.solicitudAEditar != null
                              ? 'Modificar solicitud'
                              : 'Enviar Solicitud',
                          style: const TextStyle(fontSize: 16),
                        ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFechaSelector({
    required String label,
    required String texto,
    required VoidCallback onTap,
  }) {
    return TextFormField(
      readOnly: true,
      onTap: onTap,
      controller: TextEditingController(text: texto),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.calendar_today, size: 18),
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ),
      ),
    );
  }
}
