import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/core/state/depositos_cheques_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';


class DepositoChequeIdentificarScreen extends ConsumerWidget {
  const DepositoChequeIdentificarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(depositosChequesProvider);
    final notifier = ref.read(depositosChequesProvider.notifier);
    final isMobile = ResponsiveUtilsBosque.isMobile(context);
    final horizontalPadding = ResponsiveUtilsBosque.getHorizontalPadding(context);
    final verticalPadding = ResponsiveUtilsBosque.getVerticalPadding(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Depósitos por Identificar'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.teal,
      ),
      body: state.cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(
                    ResponsiveUtilsBosque.getResponsiveValue(
                      context: context,
                      defaultValue: 16.0,
                      mobile: 12.0,
                      desktop: 20.0,
                    ),
                  ),
                ),
                padding: EdgeInsets.all(
                  ResponsiveUtilsBosque.getResponsiveValue(
                    context: context,
                    defaultValue: 24.0,
                    mobile: 16.0,
                    desktop: 32.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    isMobile
                        ? _buildMobileFields(context, state, notifier)
                        : _buildDesktopFields(context, state, notifier),
                    SizedBox(height: ResponsiveUtilsBosque.getVerticalPadding(context)),
                    isMobile
                        ? _buildMobileBancoFields(context, state, notifier)
                        : _buildDesktopBancoFields(context, state, notifier),
                    SizedBox(height: ResponsiveUtilsBosque.getVerticalPadding(context)),
                    isMobile
                        ? _buildMobileImporteFields(context, state, notifier)
                        : _buildDesktopImporteFields(context, state, notifier),
                    SizedBox(height: ResponsiveUtilsBosque.getVerticalPadding(context) * 1.5),
                    _buildObservacionesField(context, notifier),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Wrap(
                        spacing: 16,
                        runSpacing: 12,
                        alignment: WrapAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () {
                              notifier.limpiarFormulario();
                            },
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: ResponsiveUtilsBosque.getResponsiveValue(
                                  context: context,
                                  defaultValue: 16.0,
                                  mobile: 12.0,
                                  desktop: 24.0,
                                ),
                                vertical: ResponsiveUtilsBosque.getResponsiveValue(
                                  context: context,
                                  defaultValue: 12.0,
                                  mobile: 8.0,
                                  desktop: 16.0,
                                ),
                              ),
                            ),
                            child: const Text('Cancelar'),
                          ),
                          ElevatedButton.icon(
                            onPressed: _isGuardarEnabled(state)
                                ? () async {
                                    if (state.empresaSeleccionada == null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Debe seleccionar una empresa.')),
                                      );
                                      return;
                                    }
                                    if (state.bancoSeleccionado == null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Debe seleccionar un banco.')),
                                      );
                                      return;
                                    }
                                    if (state.monedaSeleccionada == null || state.monedaSeleccionada == '') {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Debe seleccionar una moneda.')),
                                      );
                                      return;
                                    }
                                    if (state.importeTotal <= 0) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('El importe total debe ser mayor a 0.')),
                                      );
                                      return;
                                    }
                                    try {
                                      final okDeposito = await notifier.registrarDeposito(null);
                                      if (!okDeposito) throw Exception('No se pudo registrar el depósito');
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Depósito registrado correctamente.')),
                                      );
                                      notifier.limpiarFormulario();
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error: ${e.toString()}')),
                                      );
                                    }
                                  }
                                : null,
                            icon: const Icon(Icons.save),
                            label: const Text('Guardar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: EdgeInsets.symmetric(
                                horizontal: ResponsiveUtilsBosque.getResponsiveValue(
                                  context: context,
                                  defaultValue: 16.0,
                                  mobile: 12.0,
                                  desktop: 24.0,
                                ),
                                vertical: ResponsiveUtilsBosque.getResponsiveValue(
                                  context: context,
                                  defaultValue: 12.0,
                                  mobile: 8.0,
                                  desktop: 16.0,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMobileFields(BuildContext context, dynamic state, dynamic notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildEmpresaField(context, state, notifier),
      ],
    );
  }

  Widget _buildDesktopFields(BuildContext context, dynamic state, dynamic notifier) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildEmpresaField(context, state, notifier)),
      ],
    );
  }

  Widget _buildMobileBancoFields(BuildContext context, dynamic state, dynamic notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBancoField(context, state, notifier),
      ],
    );
  }

  Widget _buildDesktopBancoFields(BuildContext context, dynamic state, dynamic notifier) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildBancoField(context, state, notifier)),
      ],
    );
  }

  Widget _buildMobileImporteFields(BuildContext context, dynamic state, dynamic notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildImporteTotalField(context, state, notifier),
        SizedBox(height: ResponsiveUtilsBosque.getVerticalPadding(context)),
        _buildMonedaField(context, state, notifier),
      ],
    );
  }

  Widget _buildDesktopImporteFields(BuildContext context, dynamic state, dynamic notifier) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildImporteTotalField(context, state, notifier)),
        SizedBox(width: ResponsiveUtilsBosque.getHorizontalPadding(context)),
        Expanded(child: _buildMonedaField(context, state, notifier)),
      ],
    );
  }

  Widget _buildEmpresaField(BuildContext context, dynamic state, dynamic notifier) {
    final empresaItems = state.empresas.map<DropdownMenuItem<dynamic>>((e) =>
      DropdownMenuItem<dynamic>(
        value: e,
        child: Text(e.nombre),
      )
    ).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Empresa',
          style: TextStyle(
            fontSize: ResponsiveUtilsBosque.getResponsiveValue(
              context: context,
              defaultValue: 14.0,
              mobile: 14.0,
              desktop: 16.0,
            ),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        DropdownButtonFormField<dynamic>(
          value: state.empresaSeleccionada,
          items: empresaItems,
          onChanged: (value) {
            notifier.seleccionarEmpresa(value);
          },
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Seleccione una empresa',
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          isExpanded: true,
        ),
      ],
    );
  }

  Widget _buildBancoField(BuildContext context, dynamic state, dynamic notifier) {
    // Si el banco seleccionado ya no está en la lista, lo limpiamos
    final bancos = state.bancos;
    final bancoSeleccionado = bancos.contains(state.bancoSeleccionado) ? state.bancoSeleccionado : null;
    final bancoItems = bancos.map<DropdownMenuItem<dynamic>>((b) =>
      DropdownMenuItem<dynamic>(
        value: b,
        child: Text(b.nombreBanco),
      )
    ).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Banco',
          style: TextStyle(
            fontSize: ResponsiveUtilsBosque.getResponsiveValue(
              context: context,
              defaultValue: 14.0,
              mobile: 14.0,
              desktop: 16.0,
            ),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        DropdownButtonFormField<dynamic>(
          value: bancoSeleccionado,
          items: bancoItems,
          onChanged: (value) => notifier.seleccionarBanco(value),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Seleccione un banco',
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          isExpanded: true,
        ),
      ],
    );
  }

  Widget _buildImporteTotalField(BuildContext context, dynamic state, dynamic notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Importe',
          style: TextStyle(
            fontSize: ResponsiveUtilsBosque.getResponsiveValue(
              context: context,
              defaultValue: 14.0,
              mobile: 14.0,
              desktop: 16.0,
            ),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          initialValue: state.importeTotal.toStringAsFixed(2),
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          onChanged: (v) => notifier.setImporteTotal(double.tryParse(v) ?? 0.0),
        ),
      ],
    );
  }

  Widget _buildMonedaField(BuildContext context, dynamic state, dynamic notifier) {
    final monedaOptions = const [
      {'label': 'Bolivianos', 'value': 'BS'},
      {'label': 'Dólares', 'value': 'USD'},
    ];
    final monedaItems = monedaOptions.map<DropdownMenuItem<String>>((m) =>
      DropdownMenuItem<String>(
        value: m['value']!,
        child: Text(m['label']!),
      )
    ).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Moneda',
          style: TextStyle(
            fontSize: ResponsiveUtilsBosque.getResponsiveValue(
              context: context,
              defaultValue: 14.0,
              mobile: 14.0,
              desktop: 16.0,
            ),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: state.monedaSeleccionada,
          items: monedaItems,
          onChanged: (value) => notifier.seleccionarMoneda(value),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          isExpanded: true,
        ),
      ],
    );
  }


  Widget _buildObservacionesField(BuildContext context, dynamic notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Observaciones (opcional)',
          style: TextStyle(
            fontSize: ResponsiveUtilsBosque.getResponsiveValue(
              context: context,
              defaultValue: 14.0,
              mobile: 14.0,
              desktop: 16.0,
            ),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          maxLines: 2,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Ingrese observaciones (opcional)',
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          onChanged: (v) => notifier.setObservaciones(v),
        ),
      ],
    );
  }

  bool _isGuardarEnabled(dynamic state) {
    final bancoSeleccionado = state.bancoSeleccionado != null;
    final importeValido = state.importeTotal > 0;
    final empresaSeleccionada = state.empresaSeleccionada != null;
    final monedaSeleccionada = state.monedaSeleccionada != null && state.monedaSeleccionada != '';
    return bancoSeleccionado && importeValido && empresaSeleccionada && monedaSeleccionada;
  }
}

//