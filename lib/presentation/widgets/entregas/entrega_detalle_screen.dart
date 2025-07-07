import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bosque_flutter/domain/entities/entregas_entity.dart';

class EntregaDetalleScreen extends StatelessWidget {
  final EntregaEntity entrega;

  const EntregaDetalleScreen({super.key, required this.entrega});

  @override
  Widget build(BuildContext context) {
    final bool tieneUbicacion = entrega.latitud != 0 && entrega.longitud != 0;
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalles de ${entrega.tipo}'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (entrega.cardName.isNotEmpty)
            _buildDetailItem('Cliente', entrega.cardName),
          if (entrega.factura > 0)
            _buildDetailItem('Factura', '${entrega.factura}'),
          if (entrega.fechaNota != null)
            _buildDetailItem('Fecha Nota', entrega.fechaNota.toString()),
          _buildDetailItem('Fecha Entrega', entrega.fechaEntrega.toString()),
          if ((entrega.direccionEntrega != null && entrega.direccionEntrega.isNotEmpty) ||
              (entrega.addressEntregaFac.isNotEmpty))
            _buildDetailItem(
              'Dirección',
              entrega.direccionEntrega != null && entrega.direccionEntrega.isNotEmpty
                  ? entrega.direccionEntrega
                  : entrega.addressEntregaFac,
            ),
          if (entrega.obs != null && entrega.obs.isNotEmpty)
            _buildDetailItem('Observaciones', entrega.obs),
          if (entrega.vendedor.isNotEmpty)
            _buildDetailItem('Vendedor', entrega.vendedor),
          if (entrega.peso > 0)
            _buildDetailItem('Peso', '${entrega.peso.toStringAsFixed(2)} kg'),
          if (tieneUbicacion) ...[
            const Divider(height: 24),
            const Text(
              'Ubicación de entrega',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Latitud: ${entrega.latitud.toStringAsFixed(6)}\nLongitud: ${entrega.longitud.toStringAsFixed(6)}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(entrega.latitud, entrega.longitud),
                    initialZoom: 16,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: AppConstants.googleMapsOpenStreetMaps,
                      userAgentPackageName: 'bosque_flutter',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          width: 40,
                          height: 40,
                          point: LatLng(entrega.latitud, entrega.longitud),
                          child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () async {
                final Uri uri = Uri.parse(
                  '${AppConstants.googleMapsSearchBaseUrl}=${entrega.latitud},${entrega.longitud}',
                );
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: const Text('Ver en Google Maps'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 14)),
          const Divider(),
        ],
      ),
    );
  }
}
