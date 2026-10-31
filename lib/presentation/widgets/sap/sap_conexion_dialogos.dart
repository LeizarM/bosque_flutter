import 'package:bosque_flutter/core/state/rrhh_provider.dart'; // Para empresasProvider
import 'package:bosque_flutter/core/state/sap_conexion_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/sap_conexion_entity.dart';
import 'package:bosque_flutter/presentation/widgets/sap/seccion_campos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void _releer(WidgetRef ref) => ref.invalidate(sapConexionesProvider);

/// Alta ([actual] null) o cambio de una conexión a SAP.
Future<void> editarSapConexion(
  BuildContext context,
  WidgetRef ref, {
  SapConexionEntity? actual,
}) async {
  final mensaje = await showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _DialogoConexion(actual: actual),
  );
  if (mensaje == null || !context.mounted) return;
  avisar(context, mensaje);
  _releer(ref);
}

/// La contraseña del Service Layer de una conexión. Se escribe y se va: no vuelve nunca a la app.
Future<void> cargarClaveSapConexion(
  BuildContext context,
  WidgetRef ref,
  SapConexionEntity c,
) async {
  final mensaje = await showDialog<String>(
    context: context,
    builder: (_) => _DialogoClave(conexion: c),
  );
  if (mensaje == null || !context.mounted) return;
  avisar(context, mensaje);
  _releer(ref);
}

/// Inicia y cierra sesión en SAP con lo guardado, para comprobarlo sin enviar nada.
Future<void> probarSapConexion(BuildContext context, SapConexionEntity c) =>
    showDialog<void>(context: context, builder: (_) => _DialogoProbar(conexion: c));

Future<void> eliminarSapConexion(
  BuildContext context,
  WidgetRef ref,
  SapConexionEntity c,
) async {
  final ok = await confirmar(
    context,
    titulo: 'Quitar ${c.nombre}',
    detalle:
        'Se borra la conexión, con su contraseña. Ningún módulo la usa: si alguno la '
        'necesitara después, habría que volver a crearla.',
    textoConfirmar: 'Quitar',
    destructiva: true,
  );
  if (!ok || !context.mounted) return;
  try {
    final mensaje = await ref.read(sapConexionRepoProvider).eliminar(c.idConexion!);
    if (!context.mounted) return;
    avisar(context, mensaje);
    _releer(ref);
  } catch (e) {
    if (context.mounted) avisar(context, mensajeSapConexion(e), esError: true);
  }
}

// ── Editar ────────────────────────────────────────────────────────────────────────

class _DialogoConexion extends ConsumerStatefulWidget {
  const _DialogoConexion({required this.actual});

  final SapConexionEntity? actual;

  @override
  ConsumerState<_DialogoConexion> createState() => _DialogoConexionState();
}

class _DialogoConexionState extends ConsumerState<_DialogoConexion> {
  final _form = GlobalKey<FormState>();
  late final SapConexionEntity _base = widget.actual ?? SapConexionEntity.plantilla();

  late int? _codEmpresa = widget.actual?.codEmpresa;
  late String _ambiente = _base.ambiente;
  late bool _habilitada = _base.habilitada;
  bool _guardando = false;
  String? _error;

  late final _nombre = TextEditingController(text: _base.nombre);
  late final _linked = TextEditingController(text: _base.linkedServer);
  late final _baseSap = TextEditingController(text: _base.baseSap);
  late final _slUrl = TextEditingController(text: _base.slUrl);
  late final _slUsuario = TextEditingController(text: _base.slUsuario);

  /// Si un módulo la usa, la empresa no se puede cambiar: el asiento de una empresa terminaría
  /// en la base de SAP de otra.
  bool get _empresaFija => (widget.actual?.enUso ?? 0) > 0;

  @override
  void dispose() {
    for (final c in [_nombre, _linked, _baseSap, _slUrl, _slUsuario]) {
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
    final conexion = SapConexionEntity(
      idConexion: widget.actual?.idConexion,
      nombre: _nombre.text.trim(),
      codEmpresa: _codEmpresa!,
      ambiente: _ambiente,
      linkedServer: _linked.text.trim(),
      baseSap: _baseSap.text.trim(),
      slUrl: _slUrl.text.trim(),
      slUsuario: _slUsuario.text.trim(),
      habilitada: _habilitada,
    );
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      final mensaje = await ref.read(sapConexionRepoProvider).guardar(conexion);
      if (mounted) Navigator.of(context).pop(mensaje);
    } catch (e) {
      if (mounted) {
        setState(() {
          _guardando = false;
          _error = mensajeSapConexion(e);
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
          maxWidth: 760,
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
                      esAlta ? 'Agregar conexión' : 'Conexión ${widget.actual!.nombre}',
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
                      TextFormField(
                        controller: _nombre,
                        decoration: const InputDecoration(
                          labelText: 'Nombre',
                          helperText: 'Es lo que eligen los módulos: por ejemplo «IMPEXPAP - Producción».',
                          helperMaxLines: 2,
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.hub_outlined),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Obligatorio' : null,
                      ),
                      const SizedBox(height: Esp.l),
                      _empresa(),
                      const SizedBox(height: Esp.l),
                      Text('Ambiente', style: context.apagado()),
                      const SizedBox(height: Esp.xs),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: SapConexionEntity.produccion,
                            label: Text('Producción'),
                            icon: Icon(Icons.verified_outlined),
                          ),
                          ButtonSegment(
                            value: SapConexionEntity.prueba,
                            label: Text('Prueba'),
                            icon: Icon(Icons.science_outlined),
                          ),
                        ],
                        selected: {_ambiente},
                        onSelectionChanged:
                            _guardando ? null : (s) => setState(() => _ambiente = s.first),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Habilitada'),
                        subtitle: const Text('Deshabilitada, ningún módulo la usa.'),
                        value: _habilitada,
                        onChanged: _guardando ? null : (v) => setState(() => _habilitada = v),
                      ),
                      SeccionCampos(
                        titulo: 'Dónde corren los SP',
                        ayuda: 'La base de SAP de la empresa. Sin linked server, en la misma instancia que BOSQUE.',
                        compacto: compacto,
                        campos: [
                          CampoSeccion(_baseSap, 'Base de SAP (CompanyDB)'),
                          CampoSeccion(
                            _linked,
                            'Linked server',
                            obligatorio: false,
                            ayuda: 'Necesita RPC Out.',
                          ),
                        ],
                      ),
                      SeccionCampos(
                        titulo: 'Service Layer',
                        ayuda: 'La contraseña se carga aparte, con «Contraseña», y se guarda cifrada.',
                        compacto: compacto,
                        campos: [
                          CampoSeccion(_slUrl, 'URL', ayuda: 'Por ejemplo https://sequoia:50000/b1s/v1/'),
                          CampoSeccion(_slUsuario, 'Usuario'),
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

  Widget _empresa() {
    final empresas = ref.watch(empresasProvider);
    return empresas.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => MensajeError(error: e, compacto: true),
      data:
          (lista) => DropdownButtonFormField<int>(
            decoration: InputDecoration(
              labelText: 'Empresa',
              helperText: _empresaFija ? 'La usan módulos de esta empresa: no se puede cambiar.' : null,
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.business_outlined),
            ),
            isExpanded: true,
            value: lista.any((e) => e.codEmpresa == _codEmpresa) ? _codEmpresa : null,
            hint: const Text('Elige la empresa'),
            items: [
              for (final e in lista) DropdownMenuItem(value: e.codEmpresa, child: Text(e.nombre)),
            ],
            onChanged:
                _guardando || _empresaFija ? null : (v) => setState(() => _codEmpresa = v),
          ),
    );
  }
}

// ── Contraseña ────────────────────────────────────────────────────────────────────

class _DialogoClave extends ConsumerStatefulWidget {
  const _DialogoClave({required this.conexion});

  final SapConexionEntity conexion;

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
          .read(sapConexionRepoProvider)
          .guardarClave(idConexion: widget.conexion.idConexion!, clave: _clave.text);
      if (mounted) Navigator.of(context).pop(mensaje);
    } catch (e) {
      if (mounted) {
        setState(() {
          _guardando = false;
          _error = mensajeSapConexion(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.conexion;
    return AlertDialog(
      title: Text('Contraseña de ${c.nombre}'),
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
  const _DialogoProbar({required this.conexion});

  final SapConexionEntity conexion;

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
      final mensaje = await ref.read(sapConexionRepoProvider).probar(widget.conexion.idConexion!);
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
          _resultado = mensajeSapConexion(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.conexion;
    return AlertDialog(
      title: Text('Probar ${c.nombre}'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Inicia y cierra sesión en ${c.baseSap} como ${c.slUsuario}, con la contraseña guardada. '
              'Comprueba el usuario, la contraseña y el certificado sin enviar nada.',
              style: context.apagado(),
            ),
            if (_resultado != null)
              NotaDelDato(tono: _ok ? TonoNota.exito : TonoNota.error, texto: _resultado!),
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
