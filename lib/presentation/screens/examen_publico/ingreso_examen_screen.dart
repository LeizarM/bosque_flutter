/// `/examen/ingreso`: el postulante externo entra con el usuario y la clave
/// temporal que le dio el evaluador, y ve sus exámenes. Pantalla pública: no
/// usa ni toca la sesión de empleado.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/dio_postulante.dart';
import 'package:bosque_flutter/core/state/examenes_provider.dart';
import 'package:bosque_flutter/core/state/postulante_examen_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/tcpe_config_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_estado_examen.dart';
import 'package:bosque_flutter/domain/entities/tcpe_estado_rendicion_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_sesion_postulante_entity.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/comun_examenes.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/lista_mis_examenes.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/marco_publico.dart';

/// La ruta de un examen con su código.
String rutaRendir(BigInt codExamen) => AppConstants.rutaTcpeRendir.replaceFirst(':codExamen', '$codExamen');
String rutaResultado(BigInt codExamen) => AppConstants.rutaTcpeResultado.replaceFirst(':codExamen', '$codExamen');

class IngresoExamenScreen extends ConsumerWidget {
  const IngresoExamenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sesion = ref.watch(sesionPostulanteProvider);
    return sesion.when(
      loading: () => const MarcoPublicoExamen(child: SizedBox(height: 240, child: EsqueletoLista(filas: 3))),
      error: (_, __) => const _FormIngreso(),
      data: (s) {
        if (s == null) return const _FormIngreso();
        if (!s.datosCompletos) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go(AppConstants.rutaTcpeRegistro);
          });
          return const MarcoPublicoExamen(child: SizedBox(height: 240, child: EsqueletoLista(filas: 3)));
        }
        return _MisExamenesPostulante(sesion: s);
      },
    );
  }
}

class _FormIngreso extends ConsumerStatefulWidget {
  const _FormIngreso();

  @override
  ConsumerState<_FormIngreso> createState() => _FormIngresoState();
}

class _FormIngresoState extends ConsumerState<_FormIngreso> {
  final _form = GlobalKey<FormState>();
  final _usuario = TextEditingController();
  final _clave = TextEditingController();
  bool _verClave = false;
  bool _entrando = false;
  // Si el backend cortó la sesión (credencial vencida), su motivo tal cual.
  String? _error = DioPostulante.tomarMotivo();

  @override
  void dispose() {
    _usuario.dispose();
    _clave.dispose();
    super.dispose();
  }

  Future<void> _ingresar() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _entrando = true;
      _error = null;
    });
    try {
      final s = await ref.read(postulanteExamenRepositoryProvider).ingresar(_usuario.text, _clave.text);
      if (!mounted) return;
      if (!s.datosCompletos) {
        context.go(AppConstants.rutaTcpeRegistro);
        return;
      }
      ref.invalidate(sesionPostulanteProvider);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _entrando = false;
        _error = textoParaUsuario(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cfg =
        ref.watch(configExamenesProvider(OrigenRendicion.postulante)).valueOrNull ?? TcpeConfiguracion.respaldo;
    return MarcoPublicoExamen(
      child: Form(
        key: _form,
        child: TarjetaPublica(
          icono: Icons.key_outlined,
          children: [
            Text(
              'EXAMEN DE EVALUACIÓN',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontFamily: fuenteFija,
                color: cs.primary,
                letterSpacing: 1.4,
                fontWeight: Peso.titulo,
              ),
            ),
            const SizedBox(height: Esp.xs),
            Text(
              'Ingresa a tu examen',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: Peso.titulo),
            ),
            const SizedBox(height: Esp.s),
            Text(cfg.ayudaIngreso, style: context.apagado()),
            const SizedBox(height: Esp.xl),
            TextFormField(
              controller: _usuario,
              autofocus: true,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.username],
              inputFormatters: [LengthLimitingTextInputFormatter(50), FilteringTextInputFormatter.deny(RegExp(r'\s'))],
              style: const TextStyle(fontFamily: fuenteFija),
              decoration: const InputDecoration(
                labelText: 'Usuario',
                hintText: 'IPX-56',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Escribe tu usuario' : null,
            ),
            const SizedBox(height: Esp.m),
            TextFormField(
              controller: _clave,
              obscureText: !_verClave,
              // TcpeLoginPostulanteDto.password2: @Size(max = 100).
              inputFormatters: [LengthLimitingTextInputFormatter(100)],
              autofillHints: const [AutofillHints.password],
              style: const TextStyle(fontFamily: fuenteFija),
              decoration: InputDecoration(
                labelText: 'Clave',
                prefixIcon: const Icon(Icons.lock_outline),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: _verClave ? 'Ocultar clave' : 'Mostrar clave',
                  icon: Icon(_verClave ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                  onPressed: () => setState(() => _verClave = !_verClave),
                ),
              ),
              validator: (v) => (v ?? '').isEmpty ? 'Escribe tu clave' : null,
              onFieldSubmitted: (_) => _ingresar(),
            ),
            // El motivo del backend tal cual (clave mala o credencial vencida).
            if (_error != null) NotaDelDato(texto: _error!, tono: TonoNota.error),
            const SizedBox(height: Esp.xl),
            SizedBox(
              height: 48,
              child: BotonAccion(
                etiqueta: 'Ingresar',
                etiquetaOcupado: 'Ingresando…',
                icono: Icons.login,
                ocupado: _entrando,
                onPressed: _ingresar,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MisExamenesPostulante extends ConsumerWidget {
  const _MisExamenesPostulante({required this.sesion});

  final TcpeSesionPostulanteEntity sesion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examenes = ref.watch(examenesPostulanteProvider);
    final nombre = (sesion.nombres ?? '').trim().isNotEmpty ? sesion.nombres!.trim() : (sesion.login ?? '');
    return MarcoPublicoExamen(
      centrado: false,
      acciones: [
        TextButton.icon(
          onPressed: () async {
            final ok = await confirmar(
              context,
              titulo: 'Salir',
              detalle: 'Para volver a entrar necesitarás tu usuario y tu clave temporal.',
              textoConfirmar: 'Salir',
            );
            if (!ok) return;
            await ref.read(postulanteExamenRepositoryProvider).salir();
            ref.invalidate(sesionPostulanteProvider);
          },
          icon: const Icon(Icons.logout, size: 18),
          label: const Text('Salir'),
        ),
      ],
      child: LayoutBuilder(
        builder: (context, r) {
          final margen = r.maxWidth < anchoTablaExamenes ? Esp.l : Esp.xl;
          return Padding(
            padding: EdgeInsets.fromLTRB(margen, Esp.l, margen, Esp.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                EncabezadoExamenes(
                  ceja: 'Tus evaluaciones',
                  titulo: 'Hola, $nombre',
                  icono: Icons.assignment_outlined,
                  detalle: 'Estos son tus exámenes. Al empezar uno, el tiempo corre aunque cierres la ventana.',
                  compacto: r.maxWidth < anchoTablaExamenes,
                  acciones: [
                    IconButton(
                      tooltip: 'Actualizar',
                      onPressed: () => ref.invalidate(examenesPostulanteProvider),
                      color: Theme.of(context).colorScheme.primary,
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                const SizedBox(height: Esp.l),
                Expanded(
                  child: examenes.when(
                    skipLoadingOnReload: true,
                    loading: () => const EsqueletoLista(),
                    error: (e, _) => MensajeError(error: e, onReintentar: () => ref.invalidate(examenesPostulanteProvider)),
                    data: (lista) => ListaMisExamenes(examenes: lista, onAbrir: (e) => _abrir(context, e)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _abrir(BuildContext context, TcpeEstadoRendicionEntity e) {
    final estado = EstadoExamenTcpe.desde(e.estado);
    if (estado == EstadoExamenTcpe.sinIniciar || estado == EstadoExamenTcpe.enCurso) {
      context.go(rutaRendir(e.codExamen));
    } else {
      context.go(rutaResultado(e.codExamen));
    }
  }
}
