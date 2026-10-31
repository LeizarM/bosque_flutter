import 'package:bosque_flutter/core/state/asiento_sap_provider.dart';
import 'package:bosque_flutter/core/state/rrhh_provider.dart'; // Para empresasProvider
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/asiento_sap_entity.dart';
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

/// La contraseña del Service Layer de una empresa. Se escribe y se va: no vuelve nunca a la app.
Future<void> cargarClaveAsientoSap(
  BuildContext context,
  WidgetRef ref,
  AsientoSapConfigEntity c,
) async {
  final mensaje = await showDialog<String>(
    context: context,
    builder: (_) => _DialogoClave(config: c),
  );
  if (mensaje == null || !context.mounted) return;
  avisar(context, mensaje);
  _releer(ref);
}

/// Inicia y cierra sesión en SAP con lo guardado, para comprobarlo sin enviar un asiento.
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
        'Se borra la configuración del asiento en SAP de ${c.empresa}, con su contraseña. '
        'La planilla de esa empresa ya no se podrá enviar hasta que la vuelvas a configurar.',
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
  late bool _habilitado = _base.habilitado;
  late bool _evitarDuplicados = _base.evitarDuplicados;
  bool _guardando = false;
  String? _error;

  late final _baseSap = TextEditingController(text: _base.baseSap);
  late final _linked = TextEditingController(text: _base.linkedServer);
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
  late final _slUrl = TextEditingController(text: _base.slUrl);
  late final _slUsuario = TextEditingController(text: _base.slUsuario);

  List<TextEditingController> get _todos => [
    _baseSap, _linked, _esquema, _sp, _paramAnio, _paramMes, _colCodigo, _colNombre,
    _colCuenta, _colDebito, _colCredito, _prefijos, _dia, _memo, _referencia, _campoRef,
    _tolerancia, _slUrl, _slUsuario,
  ];

  @override
  void dispose() {
    for (final c in _todos) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_codEmpresa == null) {
      setState(() => _error = 'Elige la empresa.');
      return;
    }
    if (!(_form.currentState?.validate() ?? false)) return;
    final config = AsientoSapConfigEntity(
      codEmpresa: _codEmpresa!,
      habilitado: _habilitado,
      baseSap: _baseSap.text.trim(),
      linkedServer: _linked.text.trim(),
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
      diaDelMes: int.tryParse(_dia.text.trim()) ?? 30,
      memo: _memo.text.trim(),
      referencia: _referencia.text.trim(),
      campoReferencia: _campoRef.text.trim(),
      evitarDuplicados: _evitarDuplicados,
      tolerancia: double.tryParse(_tolerancia.text.trim().replaceAll(',', '.')) ?? 0,
      slUrl: _slUrl.text.trim(),
      slUsuario: _slUsuario.text.trim(),
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
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Habilitada'),
                        subtitle: const Text('Deshabilitada, no aparece al enviar el asiento.'),
                        value: _habilitado,
                        onChanged: _guardando ? null : (v) => setState(() => _habilitado = v),
                      ),
                      _Seccion(
                        titulo: 'El SP que arma el asiento',
                        ayuda:
                            'Corre en la base de SAP de la empresa. Sin linked server, en la misma instancia que BOSQUE.',
                        compacto: compacto,
                        campos: [
                          _Campo(_baseSap, 'Base de SAP (CompanyDB)'),
                          _Campo(_linked, 'Linked server', obligatorio: false, ayuda: 'Necesita RPC Out.'),
                          _Campo(_esquema, 'Esquema'),
                          _Campo(_sp, 'SP'),
                          _Campo(_paramAnio, 'Parámetro del año', ayuda: 'Sin la @, por ejemplo Añio.'),
                          _Campo(_paramMes, 'Parámetro del mes', ayuda: 'Sin la @.'),
                        ],
                      ),
                      _Seccion(
                        titulo: 'Columnas que devuelve el SP',
                        compacto: compacto,
                        campos: [
                          _Campo(_colCodigo, 'Código (cuenta o socio)'),
                          _Campo(_colNombre, 'Nombre'),
                          _Campo(_colCuenta, 'Cuenta asociada del socio'),
                          _Campo(_colDebito, 'Débito'),
                          _Campo(_colCredito, 'Crédito'),
                        ],
                      ),
                      _Seccion(
                        titulo: 'El asiento',
                        ayuda: 'El memo y la referencia aceptan {anio}, {mes} y {mes2} (mes con dos dígitos).',
                        compacto: compacto,
                        campos: [
                          _Campo(_memo, 'Memo'),
                          _Campo(_referencia, 'Referencia'),
                          _Campo(
                            _campoRef,
                            'Campo de la referencia en SAP',
                            obligatorio: false,
                            ayuda: 'Por ejemplo Reference3.',
                          ),
                          _Campo(
                            _prefijos,
                            'Prefijos de socio de negocio',
                            obligatorio: false,
                            ayuda: 'Separados por coma: SU,CO,AFT.',
                          ),
                          _Campo(
                            _dia,
                            'Día del mes',
                            ayuda: '0 = el último día.',
                            teclado: TextInputType.number,
                            formatos: [FilteringTextInputFormatter.digitsOnly],
                          ),
                          _Campo(
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
                      _Seccion(
                        titulo: 'Service Layer',
                        ayuda: 'La contraseña se carga aparte, con «Contraseña», y se guarda cifrada.',
                        compacto: compacto,
                        campos: [
                          _Campo(_slUrl, 'URL', ayuda: 'Por ejemplo https://sequoia:50000/b1s/v1/'),
                          _Campo(_slUsuario, 'Usuario'),
                        ],
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
          onChanged: _guardando ? null : (v) => setState(() => _codEmpresa = v),
        );
      },
    );
  }
}

class _Campo {
  const _Campo(
    this.controlador,
    this.etiqueta, {
    this.obligatorio = true,
    this.ayuda,
    this.teclado,
    this.formatos,
  });

  final TextEditingController controlador;
  final String etiqueta;
  final bool obligatorio;
  final String? ayuda;
  final TextInputType? teclado;
  final List<TextInputFormatter>? formatos;
}

/// Un grupo de campos: dos por fila cuando hay lugar, uno debajo del otro en teléfono.
class _Seccion extends StatelessWidget {
  const _Seccion({
    required this.titulo,
    required this.campos,
    required this.compacto,
    this.ayuda,
  });

  final String titulo;
  final String? ayuda;
  final List<_Campo> campos;
  final bool compacto;

  Widget _campo(_Campo c) => TextFormField(
    controller: c.controlador,
    keyboardType: c.teclado,
    inputFormatters: c.formatos,
    decoration: InputDecoration(
      labelText: c.etiqueta,
      helperText: c.ayuda,
      border: const OutlineInputBorder(),
      isDense: true,
    ),
    validator:
        c.obligatorio ? (v) => v == null || v.trim().isEmpty ? 'Obligatorio' : null : null,
  );

  @override
  Widget build(BuildContext context) {
    final filas = <Widget>[];
    final porFila = compacto ? 1 : 2;
    for (var i = 0; i < campos.length; i += porFila) {
      final tramo = campos.sublist(i, (i + porFila).clamp(0, campos.length));
      filas.add(
        Padding(
          padding: const EdgeInsets.only(bottom: Esp.m),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var j = 0; j < porFila; j++) ...[
                if (j > 0) const SizedBox(width: Esp.m),
                Expanded(child: j < tramo.length ? _campo(tramo[j]) : const SizedBox.shrink()),
              ],
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: Esp.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(titulo, style: context.tituloSeccion()),
          if (ayuda != null) Text(ayuda!, style: context.apagado()),
          const SizedBox(height: Esp.m),
          ...filas,
        ],
      ),
    );
  }
}

// ── Contraseña ────────────────────────────────────────────────────────────────────

class _DialogoClave extends ConsumerStatefulWidget {
  const _DialogoClave({required this.config});

  final AsientoSapConfigEntity config;

  @override
  ConsumerState<_DialogoClave> createState() => _DialogoClaveState();
}

class _DialogoClaveState extends ConsumerState<_DialogoClave> {
  final _clave = TextEditingController();
  bool _oculto = true;
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _clave.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    // Una contraseña puede tener espacios: no se recorta.
    if (_clave.text.isEmpty) {
      setState(() => _error = 'Escribe la contraseña.');
      return;
    }
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      final mensaje = await ref
          .read(asientoSapRepoProvider)
          .guardarClave(codEmpresa: widget.config.codEmpresa, clave: _clave.text);
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
    final c = widget.config;
    return AlertDialog(
      title: Text('Contraseña de ${c.empresa}'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'La del usuario ${c.slUsuario} del Service Layer. Se guarda cifrada y no se vuelve a mostrar: '
              '${c.claveCargada ? 'la que escribas reemplaza a la actual.' : 'todavía no hay ninguna cargada.'}',
              style: context.apagado(),
            ),
            const SizedBox(height: Esp.l),
            TextField(
              controller: _clave,
              autofocus: true,
              readOnly: _guardando,
              obscureText: _oculto,
              keyboardType: TextInputType.visiblePassword,
              onSubmitted: (_) => _guardar(),
              decoration: InputDecoration(
                labelText: 'Contraseña',
                errorText: _error,
                errorMaxLines: 3,
                suffixIcon: IconButton(
                  tooltip: _oculto ? 'Mostrar contraseña' : 'Ocultar contraseña',
                  onPressed: () => setState(() => _oculto = !_oculto),
                  icon: Icon(_oculto ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _guardando ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        BotonAccion(
          etiqueta: 'Guardar',
          etiquetaOcupado: 'Guardando',
          ocupado: _guardando,
          onPressed: _guardar,
        ),
      ],
    );
  }
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
              'Inicia y cierra sesión en ${c.baseSap} como ${c.slUsuario}, con la contraseña guardada. '
              'Comprueba el usuario, la contraseña y el certificado sin enviar ningún asiento.',
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
