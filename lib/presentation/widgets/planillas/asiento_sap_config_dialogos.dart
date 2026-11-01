import 'package:bosque_flutter/core/state/asiento_sap_provider.dart';
import 'package:bosque_flutter/core/state/rrhh_provider.dart'; // Para empresasProvider
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/asiento_sap_entity.dart';
import 'package:bosque_flutter/domain/entities/sap_conexion_entity.dart';
import 'package:bosque_flutter/presentation/widgets/sap/seccion_campos.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void _releer(WidgetRef ref) {
  ref.invalidate(asientoSapConfigProvider);
  ref.invalidate(asientoSapEmpresasProvider);
}

/// Alta ([actual] null) o cambio de la configuración de una empresa.
Future<void> editarAsientoSapConfig(
  BuildContext context,
  WidgetRef ref, {
  AsientoSapConfigEntity? actual,
  required Set<int> yaConfiguradas,
}) async {
  final mensaje = await showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _DialogoConfig(actual: actual, yaConfiguradas: yaConfiguradas),
  );
  if (mensaje == null || !context.mounted) return;
  avisar(context, mensaje);
  _releer(ref);
}

/// Inicia y cierra sesión con la conexión de la empresa, para comprobarla sin enviar un asiento.
Future<void> probarAsientoSap(BuildContext context, AsientoSapConfigEntity c) =>
    showDialog<void>(context: context, builder: (_) => _DialogoProbar(config: c));

Future<void> eliminarAsientoSapConfig(
  BuildContext context,
  WidgetRef ref,
  AsientoSapConfigEntity c,
) async {
  final ok = await confirmar(
    context,
    titulo: 'Quitar ${c.empresa}',
    detalle:
        'Se borra la configuración del asiento en SAP de ${c.empresa}. La conexión '
        '«${c.conexion}» no se toca. La planilla de esa empresa ya no se podrá enviar hasta '
        'que la vuelvas a configurar.',
    textoConfirmar: 'Quitar',
    destructiva: true,
  );
  if (!ok || !context.mounted) return;
  try {
    final mensaje = await ref.read(asientoSapRepoProvider).eliminarConfig(c.codEmpresa);
    if (!context.mounted) return;
    avisar(context, mensaje);
    _releer(ref);
  } catch (e) {
    if (context.mounted) avisar(context, mensajeAsientoSap(e), esError: true);
  }
}

// ── Editar ────────────────────────────────────────────────────────────────────────

class _DialogoConfig extends ConsumerStatefulWidget {
  const _DialogoConfig({required this.actual, required this.yaConfiguradas});

  final AsientoSapConfigEntity? actual;
  final Set<int> yaConfiguradas;

  @override
  ConsumerState<_DialogoConfig> createState() => _DialogoConfigState();
}

class _DialogoConfigState extends ConsumerState<_DialogoConfig> {
  final _form = GlobalKey<FormState>();
  late final AsientoSapConfigEntity _base =
      widget.actual ?? AsientoSapConfigEntity.plantilla(codEmpresa: 0);

  late int? _codEmpresa = widget.actual?.codEmpresa;
  late int? _idConexion = widget.actual?.idConexion;
  late bool _habilitado = _base.habilitado;
  late bool _evitarDuplicados = _base.evitarDuplicados;
  bool _guardando = false;
  String? _error;

  late final _esquema = TextEditingController(text: _base.esquema);
  late final _sp = TextEditingController(text: _base.sp);
  late final _paramAnio = TextEditingController(text: _base.paramAnio);
  late final _paramMes = TextEditingController(text: _base.paramMes);
  late final _colCodigo = TextEditingController(text: _base.colCodigo);
  late final _colNombre = TextEditingController(text: _base.colNombre);
  late final _colCuenta = TextEditingController(text: _base.colCuenta);
  late final _colDebito = TextEditingController(text: _base.colDebito);
  late final _colCredito = TextEditingController(text: _base.colCredito);
  late final _prefijos = TextEditingController(text: _base.prefijosSocio);
  late final _dia = TextEditingController(text: '${_base.diaDelMes}');
  late final _memo = TextEditingController(text: _base.memo);
  late final _referencia = TextEditingController(text: _base.referencia);
  late final _campoRef = TextEditingController(text: _base.campoReferencia);
  late final _tolerancia = TextEditingController(
    text: _base.tolerancia.toStringAsFixed(2),
  );

  List<TextEditingController> get _todos => [
    _esquema, _sp, _paramAnio, _paramMes, _colCodigo, _colNombre, _colCuenta, _colDebito,
    _colCredito, _prefijos, _dia, _memo, _referencia, _campoRef, _tolerancia,
  ];

  @override
  void dispose() {
    for (final c in _todos) {
      c.dispose();
    }
    super.dispose();
  }

  /// Al cambiar de empresa, la conexión anterior ya no sirve; si la nueva tiene una sola, se elige.
  void _elegirEmpresa(int? codEmpresa) {
    final propias =
        (ref.read(asientoSapConexionesProvider).valueOrNull ?? const <SapConexionEntity>[])
            .where((c) => c.codEmpresa == codEmpresa)
            .toList();
    setState(() {
      _codEmpresa = codEmpresa;
      _idConexion = propias.length == 1 ? propias.first.idConexion : null;
    });
  }

  Future<void> _guardar() async {
    if (_codEmpresa == null) {
      setState(() => _error = 'Elige la empresa.');
      return;
    }
    if (_idConexion == null) {
      setState(() => _error = 'Elige la conexión de SAP.');
      return;
    }
    if (!(_form.currentState?.validate() ?? false)) return;
    final config = AsientoSapConfigEntity(
      codEmpresa: _codEmpresa!,
      habilitado: _habilitado,
      idConexion: _idConexion,
      esquema: _esquema.text.trim(),
      sp: _sp.text.trim(),
      paramAnio: _paramAnio.text.trim(),
      paramMes: _paramMes.text.trim(),
      colCodigo: _colCodigo.text.trim(),
      colNombre: _colNombre.text.trim(),
      colCuenta: _colCuenta.text.trim(),
      colDebito: _colDebito.text.trim(),
      colCredito: _colCredito.text.trim(),
      prefijosSocio: _prefijos.text.replaceAll(' ', ''),
      diaDelMes: int.tryParse(_dia.text.trim()) ?? 0,
      memo: _memo.text.trim(),
      referencia: _referencia.text.trim(),
      campoReferencia: _campoRef.text.trim(),
      evitarDuplicados: _evitarDuplicados,
      tolerancia: double.tryParse(_tolerancia.text.trim().replaceAll(',', '.')) ?? 0,
    );
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      final mensaje = await ref.read(asientoSapRepoProvider).guardarConfig(config);
      if (mounted) Navigator.of(context).pop(mensaje);
    } catch (e) {
      if (mounted) {
        setState(() {
          _guardando = false;
          _error = mensajeAsientoSap(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final compacto = ResponsiveUtilsBosque.isMobile(context);
    final esAlta = widget.actual == null;

    return Dialog(
      insetPadding:
          compacto
              ? const EdgeInsets.all(Esp.m)
              : const EdgeInsets.symmetric(horizontal: Esp.xxl, vertical: Esp.xl),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 820,
          maxHeight: MediaQuery.sizeOf(context).height * 0.92,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Esp.xl, Esp.l, Esp.s, Esp.s),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      esAlta ? 'Agregar empresa' : 'Configuración de ${widget.actual!.empresa}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar',
                    onPressed: _guardando ? null : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(Esp.xl),
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _empresa(esAlta),
                      const SizedBox(height: Esp.l),
                      _conexion(),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Habilitada'),
                        subtitle: const Text('Deshabilitada, no aparece al enviar el asiento.'),
                        value: _habilitado,
                        onChanged: _guardando ? null : (v) => setState(() => _habilitado = v),
                      ),
                      SeccionCampos(
                        titulo: 'El SP que arma el asiento',
                        ayuda: 'Corre en la base de SAP de la conexión elegida.',
                        compacto: compacto,
                        campos: [
                          CampoSeccion(_esquema, 'Esquema'),
                          CampoSeccion(_sp, 'SP'),
                          CampoSeccion(_paramAnio, 'Parámetro del año', ayuda: 'Sin la @, por ejemplo Añio.'),
                          CampoSeccion(_paramMes, 'Parámetro del mes', ayuda: 'Sin la @.'),
                        ],
                      ),
                      SeccionCampos(
                        titulo: 'Columnas que devuelve el SP',
                        compacto: compacto,
                        campos: [
                          CampoSeccion(_colCodigo, 'Código (cuenta o socio)'),
                          CampoSeccion(_colNombre, 'Nombre'),
                          CampoSeccion(_colCuenta, 'Cuenta asociada del socio'),
                          CampoSeccion(_colDebito, 'Débito'),
                          CampoSeccion(_colCredito, 'Crédito'),
                        ],
                      ),
                      SeccionCampos(
                        titulo: 'El asiento',
                        ayuda: 'El memo y la referencia aceptan {anio}, {mes} y {mes2} (mes con dos dígitos).',
                        compacto: compacto,
                        campos: [
                          CampoSeccion(_memo, 'Memo'),
                          CampoSeccion(_referencia, 'Referencia'),
                          CampoSeccion(
                            _campoRef,
                            'Campo de la referencia en SAP',
                            obligatorio: false,
                            ayuda: 'Por ejemplo Reference3.',
                          ),
                          CampoSeccion(
                            _prefijos,
                            'Prefijos de socio de negocio',
                            obligatorio: false,
                            ayuda: 'Separados por coma: SU,CO,AFT.',
                          ),
                          CampoSeccion(
                            _dia,
                            'Día del mes',
                            ayuda: '0 = el día en que se envía. 31 = el último día.',
                            teclado: TextInputType.number,
                            formatos: [FilteringTextInputFormatter.digitsOnly],
                          ),
                          CampoSeccion(
                            _tolerancia,
                            'Tolerancia del cuadre',
                            teclado: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ],
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Evitar duplicados'),
                        subtitle: const Text(
                          'Antes de crear, busca en SAP un asiento con la misma referencia y no envía otro.',
                        ),
                        value: _evitarDuplicados,
                        onChanged:
                            _guardando ? null : (v) => setState(() => _evitarDuplicados = v),
                      ),
                      if (_error != null) NotaDelDato(tono: TonoNota.error, texto: _error!),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Esp.xl, vertical: Esp.m),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _guardando ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: Esp.s),
                  BotonAccion(
                    etiqueta: 'Guardar',
                    etiquetaOcupado: 'Guardando',
                    icono: Icons.save_outlined,
                    ocupado: _guardando,
                    onPressed: _guardar,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _empresa(bool esAlta) {
    if (!esAlta) {
      return InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Empresa',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.business_outlined),
        ),
        child: Text(widget.actual!.empresa),
      );
    }
    final empresas = ref.watch(empresasProvider);
    return empresas.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => MensajeError(error: e, compacto: true),
      data: (lista) {
        final libres = lista.where((e) => !widget.yaConfiguradas.contains(e.codEmpresa)).toList();
        if (libres.isEmpty) {
          return const NotaDelDato(texto: 'Todas las empresas ya están configuradas.');
        }
        return DropdownButtonFormField<int>(
          decoration: const InputDecoration(
            labelText: 'Empresa',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.business_outlined),
          ),
          isExpanded: true,
          value: _codEmpresa,
          hint: const Text('Elige la empresa'),
          items: [
            for (final e in libres) DropdownMenuItem(value: e.codEmpresa, child: Text(e.nombre)),
          ],
          onChanged: _guardando ? null : _elegirEmpresa,
        );
      },
    );
  }

  /// Solo las conexiones de la empresa elegida: el asiento de una empresa no puede ir a la base
  /// de SAP de otra.
  Widget _conexion() {
    final conexiones = ref.watch(asientoSapConexionesProvider);
    return conexiones.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => MensajeError(error: e, compacto: true),
      data: (lista) {
        if (_codEmpresa == null) {
          return const NotaDelDato(texto: 'Elige la empresa para ver sus conexiones a SAP.');
        }
        final propias = lista.where((c) => c.codEmpresa == _codEmpresa).toList();
        if (propias.isEmpty) {
          return const NotaDelDato(
            tono: TonoNota.aviso,
            texto:
                'Esta empresa no tiene conexiones a SAP. Pide que la agreguen en '
                'Administración > Conexiones SAP.',
          );
        }
        return DropdownButtonFormField<int>(
          decoration: const InputDecoration(
            labelText: 'Conexión a SAP',
            helperText: 'La base y el usuario del Service Layer: se administran en Administración > Conexiones SAP.',
            helperMaxLines: 2,
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.hub_outlined),
          ),
          isExpanded: true,
          value: propias.any((c) => c.idConexion == _idConexion) ? _idConexion : null,
          hint: const Text('Elige la conexión'),
          items: [
            for (final c in propias)
              DropdownMenuItem(
                value: c.idConexion,
                child: Text(_textoConexion(c), overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: _guardando ? null : (v) => setState(() => _idConexion = v),
        );
      },
    );
  }

  static String _textoConexion(SapConexionEntity c) =>
      '${c.nombre} · ${c.esPrueba ? 'Prueba' : 'Producción'}'
      '${c.habilitada ? '' : ' (deshabilitada)'}'
      '${c.claveCargada ? '' : ' (sin contraseña)'}';
}

// ── Probar ────────────────────────────────────────────────────────────────────────

class _DialogoProbar extends ConsumerStatefulWidget {
  const _DialogoProbar({required this.config});

  final AsientoSapConfigEntity config;

  @override
  ConsumerState<_DialogoProbar> createState() => _DialogoProbarState();
}

class _DialogoProbarState extends ConsumerState<_DialogoProbar> {
  bool _probando = false;
  String? _resultado;
  bool _ok = false;

  Future<void> _probar() async {
    setState(() {
      _probando = true;
      _resultado = null;
    });
    try {
      final mensaje = await ref.read(asientoSapRepoProvider).probar(widget.config.codEmpresa);
      if (mounted) {
        setState(() {
          _probando = false;
          _ok = true;
          _resultado = mensaje;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _probando = false;
          _ok = false;
          _resultado = mensajeAsientoSap(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.config;
    return AlertDialog(
      title: Text('Probar conexión de ${c.empresa}'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Inicia y cierra sesión en ${c.baseSap} con la conexión «${c.conexion}» y su contraseña '
              'guardada. Comprueba el usuario, la contraseña y el certificado sin enviar ningún asiento.',
              style: context.apagado(),
            ),
            if (_resultado != null)
              NotaDelDato(
                tono: _ok ? TonoNota.exito : TonoNota.error,
                texto: _resultado!,
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _probando ? null : () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
        BotonAccion(
          etiqueta: _resultado == null ? 'Probar' : 'Probar otra vez',
          etiquetaOcupado: 'Probando',
          icono: Icons.wifi_tethering,
          ocupado: _probando,
          onPressed: _probar,
        ),
      ],
    );
  }
}
