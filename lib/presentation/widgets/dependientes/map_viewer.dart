import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:bosque_flutter/core/constants/app_constants.dart';

class MapViewer extends StatelessWidget {
  final double latitude;
  final double longitude;
  final double height;
  final bool isInteractive;
  final bool canChangeLocation; // Nueva propiedad
  final void Function(LatLng)? onTap;
  final double zoom;
  final MapController mapController;

  const MapViewer({
    Key? key,
    required this.latitude,
    required this.longitude,
    this.height = 200,
    this.isInteractive = false,
    this.canChangeLocation = false, // Por defecto no se puede cambiar la ubicación
    this.onTap,
    this.zoom = 13.0,
    required this.mapController, // Requerido
  }) : super(key: key);

 @override
Widget build(BuildContext context) {
  return SizedBox(
    height: height,
    child: FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: LatLng(latitude, longitude),
        initialZoom: zoom,
        onTap: canChangeLocation && onTap != null 
            ? (tapPosition, point) => onTap!(point)
            : null,
        interactionOptions: InteractionOptions(
          flags: isInteractive 
              ? InteractiveFlag.all 
              : InteractiveFlag.none,
        ),
        minZoom: 4.0,
        maxZoom: 18.0,
        cameraConstraint: CameraConstraint.contain(
          bounds: LatLngBounds(
            LatLng(-90, -180),
            LatLng(90, 180),
          ),
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: AppConstants.googleMapsOpenStreetMaps,
          userAgentPackageName: 'bosque_flutter',
          tileProvider: CancellableNetworkTileProvider(),
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: LatLng(latitude, longitude),
              width: 40.0,
              height: 40.0,
              child: const Icon(
                Icons.location_pin,
                color: Colors.red,
                size: 40,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
}