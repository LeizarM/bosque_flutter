/// El formato real de una imagen por sus primeros bytes, no por el nombre: en
/// la web el selector devuelve `scaled_<nombre>` y en el teléfono una ruta
/// temporal, así que la extensión no es confiable.
library;

import 'dart:typed_data';

/// Los formatos que acepta el servidor para las fotos de las cajas.
enum TipoImagen {
  jpeg('jpg', 'jpeg'),
  png('png', 'png'),
  webp('webp', 'webp');

  const TipoImagen(this.extension, this.subtipo);

  final String extension;

  /// Lo que va después de `image/` en el Content-Type.
  final String subtipo;
}

/// Null si no es JPG, PNG ni WEBP (HEIC, GIF, un PDF renombrado...).
TipoImagen? tipoDeImagen(Uint8List b) {
  if (b.length >= 3 && b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF) {
    return TipoImagen.jpeg;
  }
  if (b.length >= 8 &&
      b[0] == 0x89 &&
      b[1] == 0x50 &&
      b[2] == 0x4E &&
      b[3] == 0x47 &&
      b[4] == 0x0D &&
      b[5] == 0x0A &&
      b[6] == 0x1A &&
      b[7] == 0x0A) {
    return TipoImagen.png;
  }
  // RIFF....WEBP
  if (b.length >= 12 &&
      b[0] == 0x52 &&
      b[1] == 0x49 &&
      b[2] == 0x46 &&
      b[3] == 0x46 &&
      b[8] == 0x57 &&
      b[9] == 0x45 &&
      b[10] == 0x42 &&
      b[11] == 0x50) {
    return TipoImagen.webp;
  }
  return null;
}
