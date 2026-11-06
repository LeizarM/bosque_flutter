import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Abre [url] fuera de la app; falso si el dispositivo no pudo hacerlo.
typedef AbrirUrlHex = Future<bool> Function(Uri url);

/// Fábrica de las teselas del mapa de «Dónde marcó». Es una fábrica y no una
/// instancia porque el mapa la desecha al cerrarse. Las pruebas la cambian por
/// una sin red.
final hexTeselasProvider = Provider<TileProvider Function()>(
  (ref) => () => CancellableNetworkTileProvider(),
);

/// Cómo se abre Google Maps desde un punto. Las pruebas lo cambian por uno
/// que solo anota la dirección.
final hexAbrirUrlProvider = Provider<AbrirUrlHex>((ref) => _abrirFuera);

Future<bool> _abrirFuera(Uri url) async {
  try {
    return await launchUrl(url, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
