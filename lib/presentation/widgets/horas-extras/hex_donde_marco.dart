/// «Dónde marcó» (D30): el mapa y la leyenda de dónde marcó el empleado con la
/// app. Va en el detalle del reporte y en una hoja que abre la ficha del
/// origen «App · con ubicación». Solo en pantalla: el PDF no lo trae.
library;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/state/hex_mapa_provider.dart';
import 'package:bosque_flutter/core/state/hex_reporte_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/hex_reporte_entity.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_colores.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_escrituras.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_formatos.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_panel.dart';

/// Desde este ancho el mapa va al costado de la leyenda; por debajo, encima.
const double _anchoLado = 560;
const double _altoMapaAngosto = 220;
const double _altoMapaAncho = 260;

/// Cuánto se acerca el encuadre de dos puntos, y el zoom de uno solo.
const double _zoomMaximoEncuadre = 17;
const double _zoomUnPunto = 16;

/// Dos puntos a menos de esto (grados, ~1 m) se tratan como uno: encuadrar
/// un rectángulo sin tamaño no tiene sentido.
const double _separacionMinima = 0.00001;

/// El enlace que abre Google Maps con el punto marcado.
Uri urlGoogleMapsHex(double lat, double lon) => Uri.parse(
  'https://www.google.com/maps/search/?api=1'
  '&query=${lat.toStringAsFixed(6)},${lon.toStringAsFixed(6)}',
);

/// Una marca con ubicación: entrada o salida, con su precisión y su hora.
class _PuntoMarca {
  const _PuntoMarca({
    required this.esEntrada,
    required this.punto,
    this.precision,
    this.hora,
  });

  final bool esEntrada;
  final LatLng punto;
  final double? precision;
  final DateTime? hora;

  String get rotulo => esEntrada ? 'Entrada' : 'Salida';

  TonoHex get tono => esEntrada ? TonoHex.primario : TonoHex.terciario;

  IconData get icono => esEntrada ? Icons.login : Icons.logout;

  /// «Entrada · 07:02 · ±12 m»; lo que no se sabe se omite.
  String get leyenda => [
    rotulo,
    if (hora != null) relojHex(hora),
    if (precision != null) '±${numeroHex(precision)} m',
  ].join(' · ');

  String get coordenadas =>
      '${punto.latitude.toStringAsFixed(6)}, '
      '${punto.longitude.toStringAsFixed(6)}';
}

double? _precisionValida(double? p) =>
    (p != null && p.isFinite && p > 0) ? p : null;

/// Las marcas con ubicación del reporte. La hora es la de la marca por app
/// (D31), aunque la efectiva sea otra; sin ella solo vale la del reporte si es
/// de la app.
List<_PuntoMarca> _puntosDe(HexReporteEntity r) => [
  if (r.tieneUbicacionInicio)
    _PuntoMarca(
      esEntrada: true,
      punto: LatLng(r.latInicio!, r.lonInicio!),
      precision: _precisionValida(r.precisionInicio),
      hora: r.inicioApp ?? (r.origenInicio == 'APP' ? r.inicio : null),
    ),
  if (r.tieneUbicacionFin)
    _PuntoMarca(
      esEntrada: false,
      punto: LatLng(r.latFin!, r.lonFin!),
      precision: _precisionValida(r.precisionFin),
      hora: r.finApp ?? (r.origenFin == 'APP' ? r.fin : null),
    ),
];

/// La sección: título, mapa y leyenda con un botón por punto. No dibuja nada
/// si el reporte no tiene ninguna ubicación. [conTitulo] falso en la hoja.
class DondeMarcoHex extends StatelessWidget {
  const DondeMarcoHex(this.reporte, {super.key, this.conTitulo = true});

  final HexReporteEntity reporte;
  final bool conTitulo;

  @override
  Widget build(BuildContext context) {
    final puntos = _puntosDe(reporte);
    if (puntos.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, c) {
        final ancho = c.maxWidth >= _anchoLado;
        final mapa = _MapaMarcas(
          puntos: puntos,
          alto: ancho ? _altoMapaAncho : _altoMapaAngosto,
        );
        final leyenda = _LeyendaMarcas(puntos);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (conTitulo) ...[
              const TituloSeccionHex(
                'Dónde marcó',
                icono: Icons.location_on_outlined,
              ),
              const SizedBox(height: Esp.s),
            ],
            if (ancho)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: mapa),
                  const SizedBox(width: Esp.l),
                  Expanded(flex: 4, child: leyenda),
                ],
              )
            else ...[
              mapa,
              const SizedBox(height: Esp.m),
              leyenda,
            ],
          ],
        );
      },
    );
  }
}

/// El mapa con las teselas del visor de la app, un marcador por punto y, si
/// hay precisión, su círculo en metros. Se encuadra solo para que entren los dos.
class _MapaMarcas extends ConsumerStatefulWidget {
  const _MapaMarcas({required this.puntos, required this.alto});

  final List<_PuntoMarca> puntos;
  final double alto;

  @override
  ConsumerState<_MapaMarcas> createState() => _MapaMarcasState();
}

class _MapaMarcasState extends ConsumerState<_MapaMarcas> {
  // El TileLayer lo desecha al cerrarse: no se comparte entre mapas.
  late final TileProvider _teselas = ref.read(hexTeselasProvider)();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final puntos = widget.puntos;
    final coordenadas = [for (final p in puntos) p.punto];
    final encuadrar =
        coordenadas.length > 1 &&
        ((coordenadas[0].latitude - coordenadas[1].latitude).abs() >
                _separacionMinima ||
            (coordenadas[0].longitude - coordenadas[1].longitude).abs() >
                _separacionMinima);
    return Semantics(
      container: true,
      label: 'Mapa de dónde marcó',
      child: Container(
        height: widget.alto,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Esquina.media),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: FlutterMap(
          // Si cambian los puntos, el mapa se arma de nuevo con su encuadre.
          key: ValueKey(Object.hashAll(coordenadas)),
          options: MapOptions(
            initialCenter: coordenadas.first,
            initialZoom: _zoomUnPunto,
            initialCameraFit:
                encuadrar
                    ? CameraFit.coordinates(
                      coordinates: coordenadas,
                      padding: const EdgeInsets.all(56),
                      maxZoom: _zoomMaximoEncuadre,
                    )
                    : null,
            minZoom: 3,
            maxZoom: 19,
            interactionOptions: const InteractionOptions(
              flags:
                  InteractiveFlag.drag |
                  InteractiveFlag.pinchMove |
                  InteractiveFlag.pinchZoom |
                  InteractiveFlag.doubleTapZoom |
                  InteractiveFlag.scrollWheelZoom,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: AppConstants.googleMapsOpenStreetMaps,
              userAgentPackageName: 'bosque_flutter',
              tileProvider: _teselas,
            ),
            CircleLayer(
              circles: [
                for (final p in puntos)
                  if (p.precision != null)
                    CircleMarker(
                      point: p.punto,
                      radius: p.precision!,
                      useRadiusInMeter: true,
                      color: acentoTonoHex(
                        context,
                        p.tono,
                      ).withValues(alpha: 0.16),
                      borderColor: acentoTonoHex(
                        context,
                        p.tono,
                      ).withValues(alpha: 0.6),
                      borderStrokeWidth: 1.5,
                    ),
              ],
            ),
            MarkerLayer(
              markers: [
                for (final p in puntos)
                  Marker(
                    point: p.punto,
                    width: 40,
                    height: 40,
                    child: _FichaMarca(p),
                  ),
              ],
            ),
            const SimpleAttributionWidget(source: Text('OpenStreetMap')),
          ],
        ),
      ),
    );
  }
}

/// El marcador: un círculo claro con el ícono de entrada o de salida.
class _FichaMarca extends StatelessWidget {
  const _FichaMarca(this.p);

  final _PuntoMarca p;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = acentoTonoHex(context, p.tono);
    return Semantics(
      label: p.rotulo,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: cs.surface,
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Center(child: Icon(p.icono, color: color, size: 22)),
      ),
    );
  }
}

/// Una fila por punto: su leyenda, las coordenadas y el botón de Google Maps.
class _LeyendaMarcas extends StatelessWidget {
  const _LeyendaMarcas(this.puntos);

  final List<_PuntoMarca> puntos;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (var i = 0; i < puntos.length; i++) ...[
        if (i > 0) const SizedBox(height: Esp.m),
        _FilaMarca(puntos[i]),
      ],
    ],
  );
}

class _FilaMarca extends ConsumerWidget {
  const _FilaMarca(this.p);

  final _PuntoMarca p;

  Future<void> _abrir(BuildContext context, WidgetRef ref) async {
    var abierto = false;
    try {
      abierto = await ref.read(hexAbrirUrlProvider)(
        urlGoogleMapsHex(p.punto.latitude, p.punto.longitude),
      );
    } catch (_) {
      abierto = false;
    }
    if (!abierto && context.mounted) {
      mostrarAviso(
        context,
        'No se pudo abrir Google Maps en este dispositivo.',
        tono: TonoAviso.error,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = acentoTonoHex(context, p.tono);
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(p.icono, size: 18, color: color),
            ),
            const SizedBox(width: Esp.s),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.leyenda,
                    style: t.bodyMedium?.copyWith(fontWeight: Peso.titulo),
                  ),
                  Text(
                    p.coordenadas,
                    style: estiloCifrasHex(context.apagado()),
                  ),
                ],
              ),
            ),
          ],
        ),
        TextButton.icon(
          style: TextButton.styleFrom(
            minimumSize: const Size(48, 48),
            visualDensity: VisualDensity.standard,
          ),
          onPressed: () => _abrir(context, ref),
          icon: const Icon(Icons.open_in_new, size: 18),
          label: const Text('Abrir en Google Maps'),
        ),
      ],
    );
  }
}

/// Abre la hoja (o el diálogo en el ancho) con solo «Dónde marcó» del reporte
/// [idReporte]. Lee el mismo detalle que la pantalla del reporte.
Future<void> mostrarDondeMarcoHex(BuildContext context, BigInt idReporte) =>
    mostrarPanelHex(
      context,
      panel:
          (control) =>
              _PanelDondeMarcoHex(idReporte: idReporte, control: control),
    );

class _PanelDondeMarcoHex extends ConsumerWidget {
  const _PanelDondeMarcoHex({required this.idReporte, required this.control});

  final BigInt idReporte;
  final ScrollController? control;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hijos = ref
        .watch(hexDetalleReporteProvider(idReporte))
        .when(
          skipLoadingOnReload: true,
          loading:
              () => [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: Esp.m),
                  child: LinearProgressIndicator(minHeight: 2),
                ),
              ],
          error:
              (e, _) => [
                SizedBox(
                  height: hexAltoEstado,
                  child: vistaErrorHex(
                    e,
                    reintentar:
                        () => ref.invalidate(
                          hexDetalleReporteProvider(idReporte),
                        ),
                  ),
                ),
              ],
          data: (r) {
            if (r == null || !r.tieneUbicacion) {
              return [
                SizedBox(
                  height: hexAltoEstado,
                  child: MensajeVacio(
                    icono: Icons.location_off_outlined,
                    titulo:
                        r == null
                            ? 'No se encontró el reporte'
                            : 'Sin ubicación guardada',
                    detalle:
                        r == null
                            ? 'Ya no existe o no tienes acceso a él.'
                            : 'Este reporte no tiene una marca de la app con ubicación.',
                  ),
                ),
              ];
            }
            return [
              Text(
                oGuionHex(r.nombreEmpleado),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: Peso.titulo),
              ),
              Text(
                'Jornada ${fechaHex(r.fechaJornada)}',
                style: context.apagado(),
              ),
              const SizedBox(height: Esp.l),
              DondeMarcoHex(r, conTitulo: false),
            ];
          },
        );
    return PanelHex(
      control: control,
      cabecera: Text('Dónde marcó', style: context.tituloSeccion()),
      hijos: hijos,
    );
  }
}
