import 'dart:async';
import 'package:bosque_flutter/core/state/consumo_tigo_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/cambio_tigo_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FormularioCambioLinea extends ConsumerStatefulWidget {
  final String periodoCobrado;
  final CambiosTigoEntity? origenItem;
  final CambiosTigoEntity? cambioEditar;
  final Function(CambiosTigoEntity) onSave;
  final VoidCallback onCancel;

  const FormularioCambioLinea({
    super.key,
    required this.periodoCobrado,
    this.origenItem,
    this.cambioEditar,
    required this.onSave,
    required this.onCancel,
  });

  @override
  ConsumerState<FormularioCambioLinea> createState() =>
      _FormularioCambioLineaState();
}

class _FormularioCambioLineaState extends ConsumerState<FormularioCambioLinea> {
  final _formKey = GlobalKey<FormState>();

  final _telefonoController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _buscadorDestinoController = TextEditingController();
  final _nuevoExternoController = TextEditingController();

  String? _periodoSeleccionado;

  CambiosTigoEntity? _destinoSeleccionado;
  Timer? _debounceDestino;
  bool _isEditing = false;
  bool _modoNuevoExterno = false;

  // ── FIX Bug 1: guardar tipoSocio del ORIGEN por separado ──
  // En modo edición el cambioEditar.tipoSocio es del destino, no del origen.
  // Necesitamos saber el tipo de origen para enviar codTelefono o codCuenta.
  late String _tipoSocioOrigen;
  late int _codTelefonoOrigen;
  late int _codCuentaOrigen;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.cambioEditar != null;

    if (_isEditing) {
      final c = widget.cambioEditar!;
      _periodoSeleccionado = c.periodoCobrado;
      _telefonoController.text = c.telefono;
      _descripcionController.text = c.descripcion;

      // FIX Bug 1: en edición, detectar tipo de origen por codTelefono/codCuenta
      // Si tiene codTelefono → origen era EMPLEADO
      // Si tiene codCuenta   → origen era EXTERNO
      _codTelefonoOrigen = c.codTelefono;
      _codCuentaOrigen = c.codCuenta;
      _tipoSocioOrigen = c.codTelefono != 0 ? 'EMPLEADO' : 'EXTERNO';
    } else {
      // Intentamos usar el parametro o sino dejamos null para que sea asignado por defecto luego
      _periodoSeleccionado =
          widget.periodoCobrado.isNotEmpty && widget.periodoCobrado != 'TODOS'
              ? widget.periodoCobrado
              : null;
      if (widget.origenItem != null) {
        _telefonoController.text = widget.origenItem!.telefono;
      }
      // En modo nuevo, el origen viene de origenItem
      _tipoSocioOrigen = widget.origenItem?.tipoSocio ?? '';
      _codTelefonoOrigen = widget.origenItem?.codTelefono ?? 0;
      _codCuentaOrigen = widget.origenItem?.codCuenta ?? 0;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cambiosTigoProvider.notifier).cargarDestinos();
    });
  }

  @override
  void dispose() {
    _telefonoController.dispose();
    _descripcionController.dispose();
    _buscadorDestinoController.dispose();
    _nuevoExternoController.dispose();
    _debounceDestino?.cancel();
    super.dispose();
  }

  void _onBuscadorDestinoChanged(String valor) {
    _debounceDestino?.cancel();
    _debounceDestino = Timer(const Duration(milliseconds: 500), () {
      ref.read(cambiosTigoProvider.notifier).cargarDestinos(search: valor);
    });
  }

  void _handleSubmit() {
    FocusScope.of(
      context,
    ).unfocus(); // Ocultar teclado y quitar foco antes de dialog
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_destinoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe seleccionar un destino.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final destinoEsEmpleado = _destinoSeleccionado!.tipoSocio == 'EMPLEADO';
    final destinoTieneCorporativo =
        destinoEsEmpleado && _destinoSeleccionado!.telefono.isNotEmpty;

    if (destinoTieneCorporativo) {
      showDialog(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.swap_horiz, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  const Flexible(child: Text('¿Cómo desea reasignar?')),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_destinoSeleccionado!.nombreCompleto.trim()} '
                    'ya tiene el corporativo ${_destinoSeleccionado!.telefono}.',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  _opcionReasignacion(
                    ctx: ctx,
                    color: Colors.blue,
                    icon: Icons.swap_horiz,
                    titulo: 'Intercambio de corporativo',
                    subtitulo:
                        'El ${_telefonoController.text} pasará a '
                        '${_destinoSeleccionado!.nombreCompleto.trim()} como nuevo corporativo.',
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _guardarCambio(tipoSocioDestino: 'EMPLEADO');
                    },
                  ),
                  const SizedBox(height: 10),
                  _opcionReasignacion(
                    ctx: ctx,
                    color: Colors.green,
                    icon: Icons.person_outline,
                    titulo: 'Agregar como externo referente',
                    subtitulo:
                        'El ${_telefonoController.text} quedará como número '
                        'adicional referente a ${_destinoSeleccionado!.nombreCompleto.trim()}.',
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _guardarCambio(tipoSocioDestino: 'EXTERNO');
                    },
                  ),
                ],
              ),
              actions: [
                TextButton.icon(
                  onPressed: () => Navigator.of(ctx).pop(),
                  icon: const Icon(Icons.close, color: Colors.red),
                  label: const Text('Cancelar'),
                ),
              ],
            ),
      );
      return;
    }

    _guardarCambio(tipoSocioDestino: _destinoSeleccionado!.tipoSocio);
  }

  Widget _opcionReasignacion({
    required BuildContext ctx,
    required MaterialColor color,
    required IconData icon,
    required String titulo,
    required String subtitulo,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color[300]!),
        ),
        child: Row(
          children: [
            Icon(icon, color: color[700]),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color[800],
                    ),
                  ),
                  Text(
                    subtitulo,
                    style: TextStyle(fontSize: 12, color: color[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _guardarCambio({required String tipoSocioDestino}) {
    // FIX Bug 1: usar los valores de origen guardados en initState
    // NO usar widget.cambioEditar.tipoSocio porque ese es el tipoSocio del DESTINO
    final entity = CambiosTigoEntity(
      codCambio: _isEditing ? widget.cambioEditar!.codCambio : 0,
      telefono: _telefonoController.text.trim(),
      periodoCobrado: _periodoSeleccionado!,
      codEmpleado: _destinoSeleccionado!.codEmpleado,
      nombreCompleto: _destinoSeleccionado!.nombreCompleto,
      descripcion: _descripcionController.text.trim(),
      tipoSocio: tipoSocioDestino,
      // FIX: usar los valores guardados del origen, no calcularlos desde tipoSocio
      codCuenta: _tipoSocioOrigen == 'EXTERNO' ? _codCuentaOrigen : 0,
      codTelefono: _tipoSocioOrigen == 'EMPLEADO' ? _codTelefonoOrigen : 0,
    );

    widget.onSave(entity);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtilsBosque.isDesktop(context);

    // FIX Bug 4: reducir padding en web para que el formulario sea más compacto
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 24 : 16,
            vertical: 12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(context),
              const SizedBox(height: 10),
              _buildForm(context, isDesktop),
              const SizedBox(height: 12),
              _buildButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          _isEditing ? Icons.edit : Icons.swap_horiz,
          color: _isEditing ? Colors.orange[800] : Colors.blue[800],
          size: 26,
        ),
        const SizedBox(width: 10),
        Text(
          _isEditing ? 'Editar Cambio' : 'Registrar Cambio de Línea',
          style: ResponsiveUtilsBosque.getTitleStyle(context)?.copyWith(
            color: _isEditing ? Colors.orange[800] : Colors.blue[800],
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context, bool isDesktop) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Info origen nuevo
          if (widget.origenItem != null) ...[
            _buildInfoOrigen(),
            const SizedBox(height: 8),
          ],
          // Info origen permanente (edición)
          if (_isEditing && widget.cambioEditar!.nombreOrigen.isNotEmpty) ...[
            _buildInfoOrigenPermanente(),
            const SizedBox(height: 8),
          ],

          // FIX Bug 4: en desktop agrupar período + teléfono en una fila
          if (isDesktop)
            Row(
              children: [
                Expanded(child: _buildPeriodoInput()),
                const SizedBox(width: 12),
                Expanded(child: _buildTelefonoInput()),
              ],
            )
          else ...[
            _buildPeriodoInput(),
            const SizedBox(height: 8),
            _buildTelefonoInput(),
          ],

          const SizedBox(height: 8),
          _buildSelectorDestino(),
          const SizedBox(height: 8),
          _buildDescripcionInput(),
        ],
      ),
    );
  }

  Widget _buildInfoOrigen() {
    final origen = widget.origenItem!;
    final esEmpleado = origen.tipoSocio == 'EMPLEADO';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: esEmpleado ? Colors.blue[50] : Colors.green[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: esEmpleado ? Colors.blue[200]! : Colors.green[200]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            esEmpleado ? Icons.person : Icons.person_outline,
            color: esEmpleado ? Colors.blue[700] : Colors.green[700],
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Origen: ${origen.nombreCompleto.trim()}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '${origen.tipoSocio} | 📞 ${origen.telefono}',
                  style: TextStyle(
                    color: esEmpleado ? Colors.blue[700] : Colors.green[700],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoOrigenPermanente() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.grey[600], size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Origen original',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.cambioEditar!.nombreOrigen,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodoInput() {
    final periodosAsync = ref.watch(periodosFacturaProvider);

    return periodosAsync.when(
      data: (periodos) {
        // Asignar por defecto el más reciente si no hay nada seleccionado
        if (_periodoSeleccionado == null && periodos.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _periodoSeleccionado = periodos.first);
          });
        }

        return DropdownButtonFormField<String>(
          value:
              (_periodoSeleccionado != null &&
                      periodos.contains(_periodoSeleccionado))
                  ? _periodoSeleccionado
                  : (periodos.isNotEmpty ? periodos.first : null),
          decoration: InputDecoration(
            labelText: 'Período Cobrado',
            prefixIcon: const Icon(Icons.calendar_month, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            isDense: true,
            filled: true,
            fillColor: Colors.grey[50],
          ),
          items:
              periodos
                  .map(
                    (p) => DropdownMenuItem(
                      value: p,
                      child: Text(
                        p,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
                  .toList(),
          onChanged: (val) {
            setState(() {
              _periodoSeleccionado = val;
            });
          },
          validator:
              (value) =>
                  value == null || value.isEmpty
                      ? 'Seleccione un período'
                      : null,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (e, st) => TextFormField(
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Período Cobrado',
              hintText: 'Error al cargar periodos',
              prefixIcon: const Icon(Icons.error, color: Colors.red),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              isDense: true,
            ),
          ),
    );
  }

  Widget _buildTelefonoInput() {
    return TextFormField(
      controller: _telefonoController,
      readOnly: widget.origenItem != null || _isEditing,
      decoration: InputDecoration(
        labelText: 'Teléfono Origen',
        prefixIcon: const Icon(Icons.phone, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: widget.origenItem != null || _isEditing,
        fillColor:
            (widget.origenItem != null || _isEditing) ? Colors.grey[100] : null,
        isDense: true,
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'El teléfono es obligatorio.';
        }
        return null;
      },
    );
  }

  Widget _buildSelectorDestino() {
    final state = ref.watch(cambiosTigoProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ══════════════════════════════════════════════════════════════
        // SECCIÓN A: Búsqueda de destinatario existente
        // Solo visible cuando NO estamos registrando un nuevo externo
        // ══════════════════════════════════════════════════════════════
        if (!_modoNuevoExterno) ...[
          if (_destinoSeleccionado != null) ...[
            _buildDestinoSeleccionadoCard(),
            const SizedBox(height: 8),
          ] else ...[
            TextField(
              controller: _buscadorDestinoController,
              decoration: InputDecoration(
                labelText: 'Buscar destinatario existente',
                hintText: 'Nombre o teléfono...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon:
                    state.cargandoDestinos
                        ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                        : (_buscadorDestinoController.text.isNotEmpty
                            ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _buscadorDestinoController.clear();
                                ref
                                    .read(cambiosTigoProvider.notifier)
                                    .cargarDestinos();
                              },
                            )
                            : null),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                isDense: true,
              ),
              onChanged: _onBuscadorDestinoChanged,
            ),
            const SizedBox(height: 8),

            // Lista de resultados
            if (state.destinosDisponibles.isNotEmpty)
              Container(
                height: 170,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: state.destinosDisponibles.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final destino = state.destinosDisponibles[index];
                    final esEmpleado = destino.tipoSocio == 'EMPLEADO';
                    final sinNumero = destino.telefono.isEmpty;
                    final seleccionado =
                        _destinoSeleccionado?.codEmpleado ==
                            destino.codEmpleado &&
                        _destinoSeleccionado?.codCuenta == destino.codCuenta;

                    return ListTile(
                      dense: true,
                      selected: seleccionado,
                      selectedTileColor: Colors.blue[50],
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor:
                            esEmpleado ? Colors.blue[100] : Colors.green[100],
                        child: Icon(
                          esEmpleado ? Icons.person : Icons.person_outline,
                          size: 14,
                          color:
                              esEmpleado ? Colors.blue[700] : Colors.green[700],
                        ),
                      ),
                      title: Text(
                        destino.nombreCompleto.trim(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Row(
                        children: [
                          Text(
                            sinNumero
                                ? 'Sin corporativo'
                                : '📞 ${destino.telefono}',
                            style: TextStyle(
                              fontSize: 11,
                              color:
                                  sinNumero
                                      ? Colors.orange[700]
                                      : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  esEmpleado
                                      ? Colors.blue[50]
                                      : Colors.green[50],
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              destino.tipoSocio,
                              style: TextStyle(
                                fontSize: 9,
                                color:
                                    esEmpleado
                                        ? Colors.blue[700]
                                        : Colors.green[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      onTap:
                          () => setState(() {
                            _destinoSeleccionado = destino;
                            // _descripcionController.text = destino.descripcion.isNotEmpty
                            //     ? destino.descripcion
                            //     : destino.nombreCompleto.trim().split(' ').first;
                          }),
                    );
                  },
                ),
              ),

            const SizedBox(height: 12),

            // ── Separador y CTA hacia nuevo externo ──────────────────────
            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey[300])),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    '¿No está en la lista?',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ),
                Expanded(child: Divider(color: Colors.grey[300])),
              ],
            ),
            const SizedBox(height: 8),

            // ── Botón para cambiar a modo nuevo externo ───────────────────
            OutlinedButton.icon(
              onPressed:
                  () => setState(() {
                    _modoNuevoExterno = true;
                    _destinoSeleccionado = null; // limpia selección previa
                    _buscadorDestinoController.clear(); // limpia el buscador
                  }),
              icon: const Icon(Icons.person_add, size: 18),
              label: const Text('Registrar nuevo externo'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green[700],
                side: BorderSide(color: Colors.green[400]!),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ],

        // ══════════════════════════════════════════════════════════════
        // SECCIÓN B: Formulario de nuevo externo
        // Completamente independiente — sin buscador, sin lista
        // ══════════════════════════════════════════════════════════════
        if (_modoNuevoExterno)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.green[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Cabecera con botón de cierre integrado
                Row(
                  children: [
                    Icon(Icons.person_add, color: Colors.green[700], size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Registrar nuevo externo',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green[800],
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap:
                          () => setState(() {
                            _modoNuevoExterno = false;
                            _nuevoExternoController.clear();
                          }),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.close,
                          size: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Campo de nombre — autofocus para flujo ágil
                TextField(
                  controller: _nuevoExternoController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: 'Nombre completo',
                    hintText: 'Ej: JUAN CARLOS MIRANDA',
                    prefixIcon: const Icon(Icons.badge, size: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),

                ElevatedButton.icon(
                  onPressed: _confirmarNuevoExterno,
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Confirmar nuevo externo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Eliminamos el SizedBox() fantasma del destino seleccionado aquí
        // porque ahora se maneja arriba excluyendo el resto
      ],
    );
  }

  // ── Widget auxiliar extraído ──────────────────────────────────────────────
  Widget _buildDestinoSeleccionadoCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue[300]!),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.blue[700], size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _destinoSeleccionado!.nombreCompleto.trim(),
                  style: TextStyle(
                    color: Colors.blue[800],
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  _destinoSeleccionado!.telefono.isNotEmpty
                      ? '📞 ${_destinoSeleccionado!.telefono}'
                      : 'Nuevo externo (sin corporativo asignado aún)',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.blue[600],
                    fontStyle:
                        _destinoSeleccionado!.telefono.isEmpty
                            ? FontStyle.italic
                            : FontStyle.normal,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: () => setState(() => _destinoSeleccionado = null),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildDescripcionInput() {
    return TextFormField(
      controller: _descripcionController,
      decoration: InputDecoration(
        labelText: 'Descripción (opcional)',
        hintText: 'Ej: MARCELO JAVIER, COMEX, OFICINA...',
        prefixIcon: const Icon(Icons.description, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        isDense: true,
      ),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
      ],
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
            return 'Solo se permiten letras y espacios.';
          }
        }
        return null;
      },
    );
  }

  Widget _buildButtons(BuildContext context) {
    final state = ref.watch(cambiosTigoProvider);
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton.icon(
          onPressed: widget.onCancel,
          icon: const Icon(Icons.close, color: Colors.red, size: 18),
          label: const Text('Cancelar'),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton.icon(
          onPressed: state.guardando ? null : _handleSubmit,
          icon:
              state.guardando
                  ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                  : Icon(
                    _isEditing ? Icons.save : Icons.check,
                    color: Colors.white,
                    size: 18,
                  ),
          label: Text(_isEditing ? 'Actualizar' : 'Guardar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _isEditing ? Colors.orange[800] : Colors.blue[800],
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  void _confirmarNuevoExterno() {
    final nombre = _nuevoExternoController.text.trim();
    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingrese el nombre del nuevo externo.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _destinoSeleccionado = CambiosTigoEntity(
        codCambio: 0,
        codEmpleado: 0,
        codCuenta: 0,
        codTelefono: 0,
        telefono: '',
        tipoSocio: 'EXTERNO',
        nombreCompleto: nombre,
        descripcion: '',
        periodoCobrado: '',
        estado: '',
        nombreOrigen: '',
      );
      //_descripcionController.text = nombre.split(' ').first;
      _modoNuevoExterno = false; // regresa a sección de búsqueda
      _nuevoExternoController.clear();
      _buscadorDestinoController.clear(); // buscador limpio al volver
    });
  }
}
