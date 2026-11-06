/// Lo que bloquea una planilla (D39): los reportes del mes que aún esperan
/// el visto bueno o la aprobación, con quién debe firmar cada uno. Los textos
/// los redacta el SP; la planilla se vuelve a validar al ejecutar.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/core/utils/tablas_utils.dart';
import 'package:bosque_flutter/domain/entities/hex_planilla_previa_entity.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_comun.dart';

/// Desde este ancho la lista de pendientes va en tabla.
const double _anchoTablaFirmas = 900;

/// La sección «Falta firmar»: nada mientras llega o si no falta ninguno; un
/// error no bloquea (el SP vuelve a validar al ejecutar).
class SeccionFirmasHex extends StatelessWidget {
  const SeccionFirmasHex({
    super.key,
    required this.firmas,
    required this.reintentar,
    required this.altoMaximo,
  });

  final AsyncValue<List<HexPlanillaFirmaEntity>> firmas;
  final VoidCallback reintentar;
  final double altoMaximo;

  @override
  Widget build(BuildContext context) => firmas.when(
    skipLoadingOnReload: true,
    loading: () => const LinearProgressIndicator(minHeight: 2),
    error:
        (e, _) => NotaDelDato(
          texto: textoErrorHex(e),
          tono: TonoNota.error,
          accion: TextButton(
            onPressed: reintentar,
            child: const Text('Reintentar'),
          ),
        ),
    data:
        (filas) =>
            filas.isEmpty
                ? const SizedBox.shrink()
                : _ListaFirmasHex(filas: filas, altoMaximo: altoMaximo),
  );
}

class _ListaFirmasHex extends StatelessWidget {
  const _ListaFirmasHex({required this.filas, required this.altoMaximo});

  final List<HexPlanillaFirmaEntity> filas;
  final double altoMaximo;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final tabla = usaTablaHex(c.maxWidth, _anchoTablaFirmas);
      final t = Theme.of(context).textTheme;
      final lista = ListadoHex<HexPlanillaFirmaEntity>(
        filas: filas,
        anchoMinimoTabla: _anchoTablaFirmas,
        desplazamientoExterno: !tabla,
        cabeceraAntesDe: cabeceraPorGrupoHex(
          filas,
          (f) => f.codSucursal,
          (f) => FranjaGrupoHex(
            titulo: sucursalHex(f.nombreSucursal, f.codSucursal),
            enTabla: tabla,
          ),
        ),
        columnas: [
          BosqueColumn(
            label: 'Empleado',
            flex: 4,
            cellBuilder:
                (f) => Text(
                  oGuionHex(f.nombreEmpleado),
                  style: t.bodyMedium?.copyWith(fontWeight: Peso.titulo),
                ),
          ),
          BosqueColumn(
            label: 'Jornada',
            flex: 3,
            cellBuilder:
                (f) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      fechaHex(f.fechaJornada),
                      style: estiloCifrasHex(t.bodyMedium, fuerte: true),
                    ),
                    if (f.tipoTexto.isNotEmpty)
                      Text(f.tipoTexto, style: context.apagado()),
                  ],
                ),
          ),
          BosqueColumn(
            label: 'Estado',
            flex: 3,
            cellBuilder: (f) => EtiquetaEstadoHex(f.estado, f.estadoTexto),
          ),
          BosqueColumn(
            label: 'Falta',
            flex: 6,
            cellBuilder: (f) => _FaltaHex(f),
          ),
        ],
        tarjeta:
            (f) => TarjetaHex(
              titulo: oGuionHex(f.nombreEmpleado),
              subtitulo: [
                'Jornada ${fechaHex(f.fechaJornada)}',
                f.tipoTexto,
              ].where((p) => p.isNotEmpty).join(' · '),
              estado: EtiquetaEstadoHex(f.estado, f.estadoTexto),
              contenido: _FaltaHex(f),
            ),
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Falta firmar', style: context.tituloSeccion()),
          const SizedBox(height: Esp.xs),
          AvisoHex(
            tono: TonoHex.error,
            icono: Icons.draw_outlined,
            texto:
                '${cuentaHex(filas.length, 'reporte espera', 'reportes esperan')} '
                'su firma: la planilla se ejecuta cuando cada uno tenga su '
                'firma o su rechazo.',
          ),
          const SizedBox(height: Esp.s),
          cajaTablaHex(
            tabla: tabla,
            filas: filas.length + gruposHex(filas, (f) => f.codSucursal),
            maximo: altoMaximo,
            lista: lista,
          ),
        ],
      );
    },
  );
}

/// Qué espera el reporte y quién debe firmar, en palabras del SP.
class _FaltaHex extends StatelessWidget {
  const _FaltaHex(this.f);

  final HexPlanillaFirmaEntity f;

  @override
  Widget build(BuildContext context) {
    final quien = f.debeFirmar?.trim() ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(oGuionHex(f.textoPendiente)),
        if (quien.isNotEmpty)
          Text('Debe firmar: $quien', style: context.apagado()),
      ],
    );
  }
}
