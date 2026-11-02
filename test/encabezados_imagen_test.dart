import 'package:bosque_flutter/core/network/dio_client.dart';
import 'package:flutter_test/flutter_test.dart';

/// Las fotos y los documentos del backend se cargan con `Image.network`, que no
/// pasa por Dio: el token lo pone `DioClient.encabezadosImagen()`. Sin token se
/// piden igual, como antes, para no dejar de mostrarlas.
void main() {
  tearDown(() => DioClient.fijarTokenImagenes(null));

  test('sin token: sin encabezados (la imagen se pide igual)', () {
    DioClient.fijarTokenImagenes(null);
    expect(DioClient.encabezadosImagen(), isEmpty);

    DioClient.fijarTokenImagenes('');
    expect(DioClient.encabezadosImagen(), isEmpty);
  });

  test('con token: el mismo Bearer que pone el interceptor', () {
    DioClient.fijarTokenImagenes('abc.def.ghi');
    expect(DioClient.encabezadosImagen(), {'Authorization': 'Bearer abc.def.ghi'});
  });
}
