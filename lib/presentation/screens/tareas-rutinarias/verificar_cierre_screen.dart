// Destino final: lib/presentation/screens/tareas-rutinarias/verificar_cierre_screen.dart
import 'package:bosque_flutter/core/state/verificar_cierre_provider.dart';
import 'package:bosque_flutter/core/ui/mensaje_error_tareas.dart';
import 'package:bosque_flutter/core/theme/tareas_colors.dart';
import 'package:bosque_flutter/core/theme/tareas_tema.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/cerrar_ruta.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/core/ui/visor_pdf.dart';
import 'package:bosque_flutter/core/utils/formatear_fecha.dart';
import 'package:bosque_flutter/domain/entities/cierre_operaciones_entity.dart';
import 'package:bosque_flutter/domain/entities/firma_cierre_entity.dart';
import 'package:bosque_flutter/presentation/widgets/tareas-rutinarias/pagina_tareas.dart';
import 'package:bosque_flutter/presentation/widgets/tareas-rutinarias/paneles_cierre.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Verificar Cierre de Operaciones (tarea 39) por responsables.
///
/// Marcelo (2026-10-07): la 39 es una sola tarea que hacen varias personas;
/// cada una revisa y firma solo las secciones y sucursales de su cargo. Qué le
/// toca, de qué día y cuándo puede firmar lo decide el servidor (archivo SQL
/// 81). Con la última firma, su tarea queda hecha sola: no hay botón de cerrar.
class VerificarCierreScreen extends ConsumerWidget {
  final int idBitTarea;
  final String nombreTarea;

  const VerificarCierreScreen({
    super.key,
    required this.idBitTarea,
    required this.nombreTarea,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prov = verificarCierreProvider(idBitTarea);
    final s = ref.watch(prov);
    final n = ref.read(prov.notifier);

    ref.listen(prov, (previo, actual) {
      if (actual.mensajeError != null &&
          actual.mensajeError != previo?.mensajeError) {
        HapticFeedback.lightImpact();
        mostrarAviso(context, actual.mensajeError!, tono: TonoAviso.error);
      }
      if (actual.aviso != null && actual.aviso != previo?.aviso) {
        mostrarAviso(context, actual.aviso!);
      }
      if (actual.completa &&
          previo != null &&
          !previo.completa &&
          previo.total > 0) {
        HapticFeedback.mediumImpact();
        mostrarAviso(context, 'Tu parte del cierre está completa.');
      }
    });

    return TareasScope(
      child: Scaffold(
        appBar: AppBarTareas(
          titulo: nombreTarea,
          subtitulo: _subtitulo(s),
          insignia: InsigniaTarea.deTipo(context, 5),
          acciones: [
            // El calendario del sistema anterior: mirar un día anterior.
            IconButton(
              tooltip: 'Revisar otro día',
              icon: const Icon(Icons.event_outlined),
              onPressed:
                  s.celdas.cargado && s.total > 0
                      ? () => _elegirDia(context, s, n)
                      : null,
            ),
            IconButton(
              tooltip: 'Tablero del cierre',
              icon: const Icon(Icons.insights_outlined),
              onPressed:
                  () => context.push('/dashboard/tacTareas/ControlCierre'),
            ),
            IconButton(
              tooltip: 'Volver a leer',
              icon: const Icon(Icons.refresh),
              onPressed: n.cargar,
            ),
          ],
        ),
        body: SafeArea(
          child: MargenPaginaTareas(
            abajo: false,
            child: _Cuerpo(state: s, notifier: n, idBitTarea: idBitTarea),
          ),
        ),
        bottomNavigationBar:
            s.celdas.cargado && s.total > 0
                ? BarraAccionTareas(resumen: _Avance(state: s))
                : null,
      ),
    );
  }

  Future<void> _elegirDia(
    BuildContext context,
    VerificarCierreState s,
    VerificarCierreNotifier n,
  ) async {
    final tarea = s.diasRevisados.last;
    final hoy = DateTime.now();
    final elegida = await showDatePicker(
      context: context,
      helpText: 'Revisar otro día',
      initialDate: s.diaConsulta ?? tarea,
      firstDate: DateTime(2020),
      // Hasta hoy: un día anterior se firma desde la tarea que lo revisa (SQL 108).
      lastDate: tarea.isAfter(hoy) ? tarea : hoy,
    );
    if (elegida == null) return;
    HapticFeedback.selectionClick();
    await n.consultarDia(elegida);
  }

  String _subtitulo(VerificarCierreState s) {
    final dias = s.diasRevisados;
    if (dias.isEmpty) return 'Tus secciones del cierre';
    final otro = s.diaConsulta;
    if (otro != null) return 'Miras el ${_conDiaSemana(otro)} · solo consulta';
    final dia = _conDiaSemana(dias.first);
    final otros = dias.length > 1 ? ' y otro día' : '';
    return 'Revisas el $dia$otros · ${s.firmadas} de ${s.total} firmadas';
  }
}

/// Un solo estado a la vez: leyendo, error, sin secciones o las secciones.
class _Cuerpo extends StatelessWidget {
  final VerificarCierreState state;
  final VerificarCierreNotifier notifier;
  final int idBitTarea;

  const _Cuerpo({
    required this.state,
    required this.notifier,
    required this.idBitTarea,
  });

  @override
  Widget build(BuildContext context) {
    final celdas = state.celdas;
    if (celdas.error != null) {
      return _Mensaje(
        icono: Icons.cloud_off_outlined,
        titulo: 'No se pudo leer tus secciones',
        texto: mensajeError(celdas.error),
        accion: FilledButton.tonalIcon(
          onPressed: notifier.cargar,
          icon: const Icon(Icons.refresh),
          label: const Text('Reintentar'),
        ),
      );
    }
    if (!celdas.cargado) {
      return const Center(child: CircularProgressIndicator());
    }
    if (celdas.filas.isEmpty) {
      return const _Mensaje(
        icono: Icons.assignment_ind_outlined,
        titulo: 'No tienes secciones en esta tarea',
        texto:
            'Tu cargo no tiene ninguna sección asignada para este día. Si '
            'te toca revisar alguna, pide que te agreguen en la matriz de '
            'responsables.',
      );
    }
    return RefreshIndicator(
      onRefresh: notifier.cargar,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: Esp.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (state.consultando) ...[
              _FranjaOtroDia(
                dia: state.diaConsulta!,
                diaTarea: state.diasRevisados.first,
                paraFirmar: state.paraFirmarDesdeOtra(idBitTarea),
                onVolver: () {
                  HapticFeedback.selectionClick();
                  notifier.consultarDia(null);
                },
              ),
              const SizedBox(height: Esp.m),
            ],
            // En el orden del catálogo; las secciones nuevas (archivo SQL
            // 86) no tienen panel programado y usan el de filas genérico.
            for (final b in state.bloques) ...[
              _Seccion(
                codigo: b,
                panel: state.celdasDeCodigo(b).first.seccion,
                state: state,
                notifier: notifier,
              ),
              if (b != state.bloques.last) const SizedBox(height: Esp.l),
            ],
          ],
        ),
      ),
    );
  }
}

/// Una sección con sus filas y, abajo, las firmas de sus celdas.
class _Seccion extends StatelessWidget {
  final String codigo;

  /// Null: una sección con fuente, sin panel programado.
  final PanelCierre? panel;
  final VerificarCierreState state;
  final VerificarCierreNotifier notifier;

  const _Seccion({
    required this.codigo,
    required this.panel,
    required this.state,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    final s = state;
    final n = notifier;
    // Otro día: cómo quedaron sus firmas, sin botones (archivo SQL 92).
    final Widget pie =
        s.consultando
            ? _FirmasDelDia(celdas: s.celdasDeCodigo(codigo), state: s)
            : _Firmas(
              celdas: s.celdasDeCodigo(codigo),
              firmando: (c) => s.guardando.contains('firma:${c.clave}'),
              onFirmar: (c) => _firmar(context, c),
              onAnular: (c) => _anular(context, c),
            );

    final panel = this.panel;
    if (panel == null) return _conFuente(context, pie);
    return switch (panel) {
      PanelCierre.arqueos => PanelCierreCard(
        titulo: 'Arqueos de caja',
        detalle: 'Lo que cerró cada cajero, con su diferencia, y quién no lo hizo.',
        icono: Icons.point_of_sale,
        color: TareasColors.tipoTareaTexto(context, 2),
        datos: s.arqueos,
        vacio: 'No hubo arqueos de caja ese día.',
        tituloError: 'No se pudo leer los arqueos',
        onReintentar: () => n.recargar(panel),
        revisada: s.seccionFirmada(panel),
        contador: contadorArqueos(s.arqueos.filas),
        contenido:
            (_) => ContenidoArqueos(
              filas: s.arqueos.filas,
              guardando: (id) => s.guardando.contains('arqueo:$id'),
              onRevisar: (id) {
                HapticFeedback.selectionClick();
                n.marcarArqueoRevisado(id);
              },
              onQuitarRevisado: (id) {
                HapticFeedback.selectionClick();
                n.marcarArqueoRevisado(id, revisado: false);
              },
              onPdf: (id) => _verPdfArqueo(context, id),
              soloLectura: s.consultando,
            ),
        pie: pie,
      ),
      PanelCierre.cajaFuerte => PanelCierreCard(
        titulo: 'Caja fuerte',
        detalle: 'Lo que llegó a la caja fuerte ese día.',
        icono: Icons.lock_outlined,
        color: TareasColors.tipoTareaTexto(context, 4),
        datos: s.cajaFuerte,
        vacio: 'No hubo llegadas a caja fuerte ese día.',
        tituloError: 'No se pudo leer las llegadas',
        onReintentar: () => n.recargar(panel),
        revisada: s.seccionFirmada(panel),
        contador:
            s.cajaFuerte.filas.isEmpty
                ? null
                : ContadorPanel.avance(
                  s.llegadasVerificadas,
                  s.cajaFuerte.filas.length,
                  'verificadas',
                ),
        contenido:
            (_) => ContenidoCajaFuerte(
              filas: s.cajaFuerte.filas,
              guardando: (id) => s.guardando.contains('llegada:$id'),
              onVerificar: (id) {
                HapticFeedback.selectionClick();
                n.marcarLlegadaVerificada(id);
              },
              onQuitarVerificada: (id) {
                HapticFeedback.selectionClick();
                n.marcarLlegadaVerificada(id, verificada: false);
              },
              soloLectura: s.consultando,
            ),
        pie: pie,
      ),
      PanelCierre.traspasos => PanelCierreCard(
        titulo: 'Traspaso de Caja AXA contra movimiento de caja',
        detalle: 'Cómo quedó lo que marcó el cajero en su tarea.',
        icono: Icons.compare_arrows,
        color: TareasColors.tipoTareaTexto(context, 12),
        datos: s.traspasos,
        vacio: 'El sistema no devolvió traspasos para ese día.',
        tituloError: 'No se pudo leer los traspasos',
        onReintentar: () => n.recargar(panel),
        revisada: s.seccionFirmada(panel),
        contador:
            s.traspasos.filas.isEmpty
                ? null
                : ContadorPanel.avance(
                  s.traspasosRevisados,
                  s.traspasos.filas.length,
                  'revisados',
                ),
        contenido: (_) => ContenidoTraspasos(filas: s.traspasos.filas),
        pie: pie,
      ),
      PanelCierre.cheques => PanelCierreCard(
        titulo: 'Cheques',
        detalle: 'Los cheques en custodia contra lo que SAP cobró ese día.',
        icono: Icons.receipt_long_outlined,
        color: TareasColors.valesTexto(context),
        datos: s.cheques,
        vacio: 'No hubo cheques ese día.',
        tituloError: 'No se pudo leer los cheques',
        onReintentar: () => n.recargar(panel),
        revisada: s.seccionFirmada(panel),
        contador:
            s.cheques.filas.isEmpty
                ? null
                : ContadorPanel(
                  texto:
                      s.chequesParaRevisar == 0
                          ? 'Todos cobrados'
                          : '${s.chequesParaRevisar} para revisar',
                  completo: s.chequesParaRevisar == 0,
                ),
        contenido: (_) => ContenidoCheques(filas: s.cheques.filas),
        pie: pie,
      ),
      PanelCierre.tareas => PanelCierreCard(
        titulo: 'Tareas rutinarias del día',
        detalle:
            'Lo que el Job les generó ese día a los demás, en toda la empresa.',
        icono: Icons.fact_check_outlined,
        color: TareasColors.tipoTareaTexto(context, 1),
        datos: s.tareas,
        vacio: 'Ese día no hubo tareas de otras personas.',
        tituloError: 'No se pudo leer las tareas del día',
        onReintentar: () => n.recargar(panel),
        revisada: s.seccionFirmada(panel),
        contador:
            s.tareas.filas.isEmpty
                ? null
                : ContadorPanel(
                  texto:
                      s.tareasSinHacer == 0
                          ? 'Todas respondidas'
                          : '${s.tareasSinHacer} sin hacer',
                  completo: s.tareasSinHacer == 0,
                ),
        contenido: (_) => ContenidoTareas(filas: s.tareas.filas),
        pie: pie,
      ),
    };
  }

  /// Una sección nueva: sus filas vienen de la consulta de otro módulo.
  Widget _conFuente(BuildContext context, Widget pie) {
    final s = state;
    final celdas = s.celdasDeCodigo(codigo);
    final primera = celdas.first;
    final datos = s.general(codigo);
    final revisadas = datos.filas.where((f) => f.revisada).length;
    final hallazgos = datos.filas.where((f) => f.hallazgo).length;
    CeldaCierre celdaDe(FilaSeccion f) => celdas.firstWhere(
      (c) => c.codSucursal == f.codSucursalCelda,
      orElse: () => primera,
    );
    return PanelCierreCard(
      titulo: primera.nombreSeccion,
      detalle: primera.queRevisar ?? 'Revisa cada fila y firma la sección.',
      icono: Icons.playlist_add_check,
      color: TareasColors.tipoTareaTexto(context, 5),
      datos: datos,
      vacio: 'No hubo nada que revisar ese día.',
      tituloError: 'No se pudo leer ${primera.nombreSeccion.toLowerCase()}',
      onReintentar: () => notifier.recargarGeneral(codigo),
      revisada: s.codigoFirmado(codigo),
      contador:
          datos.filas.isEmpty
              ? null
              : primera.marcaPorFila
              ? ContadorPanel.avance(revisadas, datos.filas.length, 'revisadas')
              : ContadorPanel(
                texto:
                    hallazgos == 0
                        ? 'Sin hallazgos'
                        : '$hallazgos con hallazgo',
                completo: hallazgos == 0,
              ),
      contenido:
          (_) => ContenidoFilasSeccion(
            filas: datos.filas,
            marcaPorFila: primera.marcaPorFila,
            guardando: (f) => s.guardando.contains('fila:$codigo:${f.id}'),
            onRevisar: (f) {
              HapticFeedback.selectionClick();
              notifier.marcarFila(celdaDe(f), f);
            },
            onQuitarRevisado: (f) {
              HapticFeedback.selectionClick();
              notifier.marcarFila(celdaDe(f), f, revisada: false);
            },
            soloLectura: s.consultando,
          ),
      pie: pie,
    );
  }

  Future<void> _firmar(BuildContext context, CeldaCierre celda) async {
    HapticFeedback.selectionClick();
    // Null = se cerró sin firmar: no pasa nada.
    await showDialog<bool>(
      context: context,
      builder: (_) => _DialogoFirma(celda: celda, notifier: notifier),
    );
  }

  Future<void> _anular(BuildContext context, CeldaCierre celda) async {
    HapticFeedback.selectionClick();
    await showDialog<bool>(
      context: context,
      builder: (_) => _DialogoAnular(celda: celda, notifier: notifier),
    );
  }

  Future<void> _verPdfArqueo(BuildContext context, int idAC) async {
    HapticFeedback.selectionClick();
    final bytes = await notifier.pdfArqueo(idAC);
    if (bytes == null || !context.mounted) return;
    await mostrarPdf(
      context,
      bytes: bytes,
      titulo: 'Arqueo de caja',
      nombreArchivo: 'arqueo_de_caja_$idAC.pdf',
    );
  }
}

/// Las firmas de una sección: una fila por celda (sucursal, o toda la empresa).
class _Firmas extends StatelessWidget {
  final List<CeldaCierre> celdas;
  final bool Function(CeldaCierre) firmando;
  final void Function(CeldaCierre) onFirmar;
  final void Function(CeldaCierre) onAnular;

  const _Firmas({
    required this.celdas,
    required this.firmando,
    required this.onFirmar,
    required this.onAnular,
  });

  @override
  Widget build(BuildContext context) {
    final linea = context.cs.outlineVariant.withValues(alpha: 0.6);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(Esquina.media),
        border: Border.all(color: linea),
      ),
      child: Column(
        children: [
          for (var i = 0; i < celdas.length; i++) ...[
            if (i > 0) Divider(height: 1, color: linea),
            _FilaFirma(
              celda: celdas[i],
              firmando: firmando(celdas[i]),
              onFirmar: () => onFirmar(celdas[i]),
              onAnular: () => onAnular(celdas[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilaFirma extends StatelessWidget {
  final CeldaCierre celda;
  final bool firmando;
  final VoidCallback onFirmar;
  final VoidCallback onAnular;

  const _FilaFirma({
    required this.celda,
    required this.firmando,
    required this.onFirmar,
    required this.onAnular,
  });

  @override
  Widget build(BuildContext context) {
    final firmada = celda.firmada;
    final tono =
        firmada
            ? TareasColors.realizadoTexto(context)
            : TareasColors.pendienteTexto(context);
    final hora =
        celda.fechaFirma == null
            ? ''
            : ' a las ${FormatearFecha.formatearHora(celda.fechaFirma!)}';
    final detalle =
        firmada
            ? 'Firmó ${celda.firmadoPor ?? '—'}$hora'
            : 'Revisa el ${_conDiaSemana(celda.fechaRevisada)}';

    final texto = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          celda.nombreSucursal,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        Text(detalle, style: context.apagado()),
        // En qué está y qué falta: lo dice el servidor.
        if (!firmada && celda.detalle != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              celda.detalle!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: tono),
            ),
          ),
        if (firmada && celda.obs != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              celda.obs!,
              style: context.apagado()?.copyWith(fontStyle: FontStyle.italic),
            ),
          ),
      ],
    );

    // Arqueos y caja fuerte se firman solos con la última marca: sin botón
    // mientras falte revisar algo.
    final Widget? boton =
        !firmada && !celda.conBoton
            ? null
            : firmada
            ? TextButton.icon(
              onPressed: firmando ? null : onAnular,
              icon: const Icon(Icons.undo, size: 18),
              label: const Text('Anular'),
            )
            : FilledButton.tonalIcon(
              onPressed: firmando ? null : onFirmar,
              icon:
                  firmando
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.draw_outlined, size: 18),
              label: const Text('Firmar'),
            );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Esp.m, vertical: Esp.s),
      child: Row(
        children: [
          Icon(
            firmada ? Icons.check_circle : Icons.radio_button_unchecked,
            color: tono,
            size: 20,
          ),
          const SizedBox(width: Esp.m),
          Expanded(child: texto),
          if (boton != null) ...[const SizedBox(width: Esp.s), boton],
        ],
      ),
    );
  }
}

/// Firmar una celda. La observación es opcional; si hubo hallazgos, el
/// servidor la pide y su mensaje sale aquí mismo, sin perder lo escrito.
class _DialogoFirma extends StatefulWidget {
  final CeldaCierre celda;
  final VerificarCierreNotifier notifier;

  const _DialogoFirma({required this.celda, required this.notifier});

  @override
  State<_DialogoFirma> createState() => _DialogoFirmaState();
}

class _DialogoFirmaState extends State<_DialogoFirma> {
  final _obs = TextEditingController();
  bool _enviando = false;
  String? _error;

  @override
  void dispose() {
    _obs.dispose();
    super.dispose();
  }

  Future<void> _firmar() async {
    setState(() {
      _enviando = true;
      _error = null;
    });
    final motivo = await widget.notifier.firmar(widget.celda, obs: _obs.text);
    if (!mounted) return;
    if (motivo == null) {
      cerrarRuta(context, true);
      return;
    }
    HapticFeedback.lightImpact();
    setState(() {
      _enviando = false;
      _error = motivo;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.celda;
    return AlertDialog(
      title: Text('Firmar ${c.nombreSeccion.toLowerCase()}'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${c.nombreSucursal} · revisas el ${_conDiaSemana(c.fechaRevisada)}',
              style: context.apagado(),
            ),
            const SizedBox(height: Esp.m),
            TextField(
              controller: _obs,
              autofocus: true,
              enabled: !_enviando,
              minLines: 2,
              maxLines: 4,
              // 500 es el largo de la columna; las reglas son del servidor.
              maxLength: 500,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Observación',
                hintText:
                    'Lo que encontraste. Si hubo algún problema, explícalo.',
                border: const OutlineInputBorder(),
                errorText: _error,
                errorMaxLines: 4,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _enviando ? null : () => cerrarRuta(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _enviando ? null : _firmar,
          icon:
              _enviando
                  ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Icon(Icons.draw_outlined),
          label: const Text('Firmar'),
        ),
      ],
    );
  }
}

/// Anular una firma: deja la celda pendiente otra vez. El motivo lo pide el
/// servidor.
class _DialogoAnular extends StatefulWidget {
  final CeldaCierre celda;
  final VerificarCierreNotifier notifier;

  const _DialogoAnular({required this.celda, required this.notifier});

  @override
  State<_DialogoAnular> createState() => _DialogoAnularState();
}

class _DialogoAnularState extends State<_DialogoAnular> {
  final _motivo = TextEditingController();
  bool _enviando = false;
  String? _error;

  @override
  void dispose() {
    _motivo.dispose();
    super.dispose();
  }

  Future<void> _anular() async {
    setState(() {
      _enviando = true;
      _error = null;
    });
    final motivo = await widget.notifier.anular(
      widget.celda,
      motivo: _motivo.text,
    );
    if (!mounted) return;
    if (motivo == null) {
      cerrarRuta(context, true);
      return;
    }
    HapticFeedback.lightImpact();
    setState(() {
      _enviando = false;
      _error = motivo;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.celda;
    return AlertDialog(
      title: const Text('Anular la firma'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${c.nombreSeccion} · ${c.nombreSucursal}. La sección vuelve a '
              'quedar sin firmar y hay que firmarla de nuevo.',
              style: context.apagado(),
            ),
            const SizedBox(height: Esp.m),
            TextField(
              controller: _motivo,
              autofocus: true,
              enabled: !_enviando,
              minLines: 2,
              maxLines: 3,
              // 300 es el largo de la columna.
              maxLength: 300,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Por qué la anulas',
                border: const OutlineInputBorder(),
                errorText: _error,
                errorMaxLines: 3,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _enviando ? null : () => cerrarRuta(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _enviando ? null : _anular,
          child: Text(_enviando ? 'Anulando…' : 'Anular la firma'),
        ),
      ],
    );
  }
}

/// El avance de abajo: cuántas celdas firmó y cuántas le faltan.
class _Avance extends StatelessWidget {
  final VerificarCierreState state;

  const _Avance({required this.state});

  @override
  Widget build(BuildContext context) {
    final completa = state.completa;
    final tono =
        completa
            ? TareasColors.realizadoTexto(context)
            : TareasColors.pendienteTexto(context);
    return Semantics(
      liveRegion: true,
      child: Row(
        children: [
          Icon(completa ? Icons.task_alt : Icons.pending_actions, color: tono),
          const SizedBox(width: Esp.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  completa
                      ? 'Tu parte del cierre está completa'
                      : '${state.firmadas} de ${state.total} secciones firmadas',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: Esp.xs),
                LinearProgressIndicator(
                  value: state.total == 0 ? 0 : state.firmadas / state.total,
                  color: tono,
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Mensaje extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String texto;
  final Widget? accion;

  const _Mensaje({
    required this.icono,
    required this.titulo,
    required this.texto,
    this.accion,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 40, color: context.cs.onSurfaceVariant),
          const SizedBox(height: Esp.m),
          Text(
            titulo,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Esp.s),
          Text(texto, style: context.apagado(), textAlign: TextAlign.center),
          if (accion != null) ...[const SizedBox(height: Esp.l), accion!],
        ],
      ),
    ),
  );
}

const _diasDeLaSemana = [
  'lunes',
  'martes',
  'miércoles',
  'jueves',
  'viernes',
  'sábado',
  'domingo',
];

/// "lunes 06/10/2026".
String _conDiaSemana(DateTime d) =>
    '${_diasDeLaSemana[d.weekday - 1]} ${FormatearFecha.formatearFecha(d)}';

/// Se está mirando otro día (archivo SQL 92). Si lo revisa otra tarea tuya,
/// ofrece abrirla para firmar (108); si no, solo para consultar.
class _FranjaOtroDia extends StatelessWidget {
  final DateTime dia;
  final DateTime diaTarea;
  final VoidCallback onVolver;

  /// Tus tareas desde las que se firma lo que falta de ese día (SQL 108).
  final List<CeldaTablero> paraFirmar;

  const _FranjaOtroDia({
    required this.dia,
    required this.diaTarea,
    required this.onVolver,
    this.paraFirmar = const [],
  });

  @override
  Widget build(BuildContext context) {
    final color = TareasColors.pendienteTexto(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: TareasColors.pendiente(context),
        borderRadius: BorderRadius.circular(Esquina.chica),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Esp.m, vertical: Esp.s),
        child: Wrap(
          spacing: Esp.s,
          runSpacing: Esp.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Icon(Icons.history, size: 18, color: color),
            Text(
              paraFirmar.isEmpty
                  ? 'Estás mirando el ${_conDiaSemana(dia)}, solo para '
                      'consultar. Lo que marcas y firmas es del '
                      '${_conDiaSemana(diaTarea)}.'
                  : 'Estás mirando el ${_conDiaSemana(dia)}. Lo que falta de '
                      'ese día se firma desde tu tarea que lo revisa.',
              style: TextStyle(color: color),
            ),
            // Abre esa tarea en lugar de esta: ahí se marca y se firma.
            for (final t in paraFirmar)
              FilledButton.tonalIcon(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  context.pushReplacement(
                    '/dashboard/tacTareas/VerificarCierre',
                    extra: {
                      'idBitTarea': t.idBitTarea,
                      'fecha': t.fechaTarea,
                      'nombreTarea':
                          'Verificar Cierre del ${_conDiaSemana(t.fechaTarea)}',
                    },
                  );
                },
                icon: const Icon(Icons.draw_outlined, size: 18),
                label: Text(
                  'Firmar desde tu tarea del ${_conDiaSemana(t.fechaTarea)}',
                ),
              ),
            TextButton(
              onPressed: onVolver,
              child: Text(
                'Volver al ${FormatearFecha.formatearFecha(diaTarea)}',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Las firmas de un día que se mira: quién firmó cada celda y cuándo, o que
/// nadie lo hizo. Salen del tablero; sin botones.
class _FirmasDelDia extends StatelessWidget {
  final List<CeldaCierre> celdas;
  final VerificarCierreState state;

  const _FirmasDelDia({required this.celdas, required this.state});

  @override
  Widget build(BuildContext context) {
    final datos = state.firmasDelDia;
    if (datos.error != null) {
      return Text(
        'No se pudo leer las firmas de ese día: ${mensajeError(datos.error)}',
        style: context.apagado(),
      );
    }
    if (!datos.cargado) return const LinearProgressIndicator(minHeight: 2);
    final linea = context.cs.outlineVariant.withValues(alpha: 0.6);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(Esquina.media),
        border: Border.all(color: linea),
      ),
      child: Column(
        children: [
          for (var i = 0; i < celdas.length; i++) ...[
            if (i > 0) Divider(height: 1, color: linea),
            _FilaFirmaDelDia(
              celda: celdas[i],
              firma: state.firmaDelDia(celdas[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilaFirmaDelDia extends StatelessWidget {
  final CeldaCierre celda;
  final CeldaTablero? firma;

  const _FilaFirmaDelDia({required this.celda, required this.firma});

  String _detalle(CeldaTablero? f, bool firmada) {
    if (f == null) return 'No hay firma registrada de ese día.';
    if (!firmada) {
      return f.estado == EstadoCelda.sinFirmar
          ? 'Nadie la firmó.'
          : 'Todavía sin firmar.';
    }
    if (f.firmadoPor == 'Se cerró sola') {
      return 'Se cerró sola: no había nada que revisar.';
    }
    final cuando =
        f.fechaFirma == null
            ? ''
            : ' el ${FormatearFecha.formatearFecha(f.fechaFirma!)}'
                ' a las ${FormatearFecha.formatearHora(f.fechaFirma!)}';
    final tarde = f.estado == EstadoCelda.tarde ? ' (tarde)' : '';
    return 'Firmó ${f.firmadoPor ?? '—'}$cuando$tarde';
  }

  @override
  Widget build(BuildContext context) {
    final f = firma;
    final firmada =
        f != null &&
        (f.estado == EstadoCelda.aTiempo || f.estado == EstadoCelda.tarde);
    final tono =
        firmada
            ? TareasColors.realizadoTexto(context)
            : TareasColors.pendienteTexto(context);
    final obs = firmada ? f.obs : null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Esp.m, vertical: Esp.s),
      child: Row(
        children: [
          Icon(
            firmada ? Icons.check_circle : Icons.radio_button_unchecked,
            color: tono,
            size: 20,
          ),
          const SizedBox(width: Esp.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  celda.nombreSucursal,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(_detalle(f, firmada), style: context.apagado()),
                if (obs != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      obs,
                      style: context.apagado()?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
