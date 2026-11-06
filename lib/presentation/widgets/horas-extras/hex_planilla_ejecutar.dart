/// Ejecutar una planilla de horas extra: la confirmación con lo que se
/// congela (la vista previa recién pedida: empresa, sucursal, período,
/// empleados, reportes y montos) y una observación opcional; después, el PDF.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/hex_planilla_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/ofrecer_pdf.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/repositories/hex_errores.dart';
import 'package:bosque_flutter/domain/repositories/hex_planilla_repository.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_comun.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_planilla_previa.dart';

/// Vuelve a pedir P, W y lo que falta firmar en paralelo: entre la vista
/// previa y la confirmación pudieron aprobarse o anularse reportes. Nulo si la
/// recarga falló (se avisa), si falta firmar o si ya no hay nada que ejecutar
/// (la vista previa lo dice); el lote vacío sigue, para que hable el SP.
Future<ResumenPreviaHex?> resumenAlDiaHex(
  BuildContext context,
  WidgetRef ref,
  ResumenPreviaHex previa,
) async {
  final c = previa.combinacion;
  try {
    final previaNueva = ref.refresh(hexVistaPreviaProvider(c).future);
    final avisosNuevos = ref.refresh(hexAvisosProvider(c).future);
    final firmasNuevas = ref.refresh(hexPendientesFirmaProvider(c).future);
    // Espera las tres; si alguna falla, el primer error sale aquí.
    await Future.wait([previaNueva, avisosNuevos, firmasNuevas]);
    final filas = await previaNueva;
    if ((await firmasNuevas).isNotEmpty) return null;
    if (filas.isEmpty && !esLoteHex(c)) return null;
    return ResumenPreviaHex.de(
      combinacion: c,
      sucursal: previa.sucursal,
      empresa: previa.empresa,
      filas: filas,
      avisos: await avisosNuevos,
    );
  } catch (e) {
    if (context.mounted) {
      mostrarAviso(context, textoErrorHex(e), tono: TonoAviso.error);
    }
    return null;
  }
}

/// Confirma [resumen] (recién pedido con [resumenAlDiaHex]) y ejecuta. Si
/// sale y hay botón de PDF, el mensaje del SP va en el diálogo que lo ofrece
/// (un aviso quedaría tapado). [refrescar] corre al ejecutar o ante un 409.
Future<void> ejecutarPlanillaHex(
  BuildContext context,
  WidgetRef ref,
  ResumenPreviaHex resumen, {
  required bool conPdf,
  required VoidCallback refrescar,
}) async {
  final repo = ref.read(hexPlanillaRepositoryProvider);
  final c = resumen.combinacion;
  final lote = esLoteHex(c);
  HexRespuesta? hecha;
  await abrirDialogoHex(
    context,
    refrescar: refrescar,
    dialogo:
        (recargar) => _DialogoEjecutarHex(
          resumen: resumen,
          refrescar: recargar,
          ejecutar: (observacion) async {
            final r =
                lote
                    ? await _ejecutarLote(repo, resumen, observacion)
                    : await repo.ejecutar(c, observacion: observacion);
            hecha = r;
            return conPdf ? (id: r.id, mensaje: '') : r;
          },
        ),
  );
  final r = hecha;
  if (r == null || !conPdf || !context.mounted) return;
  await ofrecerPdf(
    context,
    tituloDialogo: lote ? 'Lote ejecutado' : 'Planilla ejecutada',
    titulo:
        lote ? 'Lote de planillas de horas extra' : 'Planilla de horas extra',
    nombreArchivo:
        lote
            ? 'lote_horas_extra_${r.id}.pdf'
            : 'planilla_horas_extra_${r.id}.pdf',
    mensaje:
        r.mensaje.isNotEmpty
            ? r.mensaje
            : lote
            ? 'El lote quedó ejecutado.'
            : 'La planilla quedó ejecutada.',
    generar: () => lote ? repo.pdfLote(r.id) : repo.pdf(r.id),
  );
}

/// El lote del mes (D39). Si la vista previa no traía nada, el 400 del SP es
/// su texto de «mes sin horas extra»: se muestra como aviso, no como falla.
Future<HexRespuesta> _ejecutarLote(
  HexPlanillaRepository repo,
  ResumenPreviaHex resumen,
  String? observacion,
) async {
  final c = resumen.combinacion;
  try {
    return await repo.ejecutarLote(c.anio, c.mes, observacion: observacion);
  } on NegocioHex catch (e) {
    if (resumen.reportes == 0) throw SinDatosHex(e.mensaje);
    rethrow;
  }
}

/// La confirmación de «Ejecutar planilla»: qué se congela, la empresa que
/// paga, los montos y la observación. Un 400 lo deja abierto con el texto
/// del SP; al ejecutar o ante un 409 recarga y se cierra.
class _DialogoEjecutarHex extends StatefulWidget {
  const _DialogoEjecutarHex({
    required this.resumen,
    required this.refrescar,
    required this.ejecutar,
  });

  final ResumenPreviaHex resumen;
  final VoidCallback refrescar;
  final Future<HexRespuesta> Function(String? observacion) ejecutar;

  @override
  State<_DialogoEjecutarHex> createState() => _DialogoEjecutarHexState();
}

class _DialogoEjecutarHexState extends State<_DialogoEjecutarHex>
    with EscrituraEnDialogoHex {
  final TextEditingController _observacion = TextEditingController();

  /// Con avisos, «Ejecutar planilla» espera a que se marque «Revisé los avisos».
  bool _reviso = false;

  @override
  VoidCallback get refrescarLista => widget.refrescar;

  @override
  void dispose() {
    _observacion.dispose();
    super.dispose();
  }

  void _ejecutar() {
    FocusManager.instance.primaryFocus?.unfocus();
    final texto = _observacion.text.trim();
    escribir((_) => widget.ejecutar(texto.isEmpty ? null : texto));
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.resumen;
    final t = Theme.of(context).textTheme;
    Widget dato(
      String rotulo,
      String valor, {
      bool cifra = true,
      bool fuerte = false,
    }) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text(rotulo, style: context.apagado())),
          const SizedBox(width: Esp.s),
          Expanded(
            flex: 3,
            child: Text(
              valor,
              textAlign: TextAlign.right,
              style:
                  cifra
                      ? estiloCifrasHex(t.bodyMedium, fuerte: fuerte)
                      : t.bodyMedium?.copyWith(fontWeight: Peso.titulo),
            ),
          ),
        ],
      ),
    );
    final hayAvisos = r.avisos > 0;
    final accion = r.esLote ? 'Ejecutar lote' : 'Ejecutar planilla';
    return DialogoHex(
      titulo: accion,
      icono: Icons.lock_outline,
      ocupado: ocupado,
      accion: accion,
      alAceptar: _ejecutar,
      aceptarHabilitado: !hayAvisos || _reviso,
      contenido:
          (enCurso) => [
            Text(r.detalle, style: t.bodyMedium),
            const SizedBox(height: Esp.m),
            const AvisoHex(
              tono: TonoHex.pendiente,
              icono: Icons.warning_amber_rounded,
              texto: ResumenPreviaHex.advertencia,
            ),
            const SizedBox(height: Esp.m),
            dato('Empresa que paga', r.empresa, cifra: false),
            if (r.reportes > 0) ...[
              const SizedBox(height: Esp.s),
              CifrasHex(
                compacto: true,
                tonoTotal: TonoHex.exito,
                principal: (rotulo: 'Total en dinero', valor: bsHex(r.total)),
                cifras: [
                  (rotulo: 'Horas (Bs)', valor: bsHex(r.montoHoras)),
                  (rotulo: 'Comidas (Bs)', valor: bsHex(r.montoComidas)),
                ],
              ),
            ],
            if (r.fuera > 0) ...[
              const SizedBox(height: Esp.s),
              AvisoHex(
                tono: TonoHex.pendiente,
                icono: Icons.block,
                texto:
                    '${cuentaHex(r.fuera, 'reporte queda', 'reportes quedan')} '
                    'fuera de la planilla; ver avisos.',
              ),
            ],
            if (hayAvisos) ...[
              const SizedBox(height: Esp.s),
              AvisoHex(
                tono: TonoHex.pendiente,
                icono: Icons.notifications_active_outlined,
                texto:
                    'La vista previa tiene '
                    '${cuentaHex(r.avisos, 'aviso', 'avisos')}: revísalos '
                    'antes de ejecutar.',
              ),
              CheckboxListTile(
                value: _reviso,
                onChanged:
                    enCurso
                        ? null
                        : (v) {
                          HapticaHex.seleccion();
                          setState(() => _reviso = v ?? false);
                        },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: const Text('Revisé los avisos'),
              ),
            ],
            const SizedBox(height: Esp.l),
            TextoLargoHex(
              control: _observacion,
              etiqueta: 'Observación (opcional)',
              habilitado: !enCurso,
              pista: 'Por ejemplo: horas extra de ${r.periodo}',
            ),
          ],
    );
  }
}
