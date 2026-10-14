import 'dart:convert';

import 'package:bosque_flutter/core/network/dio_client.dart';
import 'package:bosque_flutter/core/theme/app_theme.dart';
import 'package:bosque_flutter/core/utils/secure_storage.dart';
import 'package:bosque_flutter/presentation/screens/login/login_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sesión cerrada por el backend (JwtTokenFilter): un 401 con `error: SESION_CERRADA`
/// trae el motivo, y el login lo muestra una sola vez al abrirse.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const inactivo = 'Usuario inactivo. Si crees que es un error, comunícate con Recursos Humanos.';
  const cuerpoCierre = {'ok': false, 'error': 'SESION_CERRADA', 'mensaje': inactivo};

  setUpAll(() => dotenv.testLoad(fileInput: ''));
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    DioClient.tomarMotivoCierre();
  });

  DioException error401(Object? cuerpo) {
    final pedido = RequestOptions(path: '/ventas/listar');
    return DioException(
      requestOptions: pedido,
      type: DioExceptionType.badResponse,
      response: Response(requestOptions: pedido, statusCode: 401, data: cuerpo),
    );
  }

  test('solo el 401 de sesión cerrada trae motivo', () {
    expect(DioClient.motivoSesionCerrada(cuerpoCierre), inactivo);
    expect(DioClient.motivoSesionCerrada({'error': 'No autorizado', 'ok': false}), isNull);
    expect(DioClient.motivoSesionCerrada('No autorizado'), isNull);
    expect(DioClient.motivoSesionCerrada(null), isNull);
  });

  test('el motivo también se lee cuando el pedido era de un PDF (bytes) o de texto', () {
    final json = jsonEncode(cuerpoCierre);

    expect(DioClient.motivoSesionCerrada(utf8.encode(json)), inactivo);
    expect(DioClient.motivoSesionCerrada(json), inactivo);
    expect(DioClient.motivoSesionCerrada(utf8.encode('%PDF-1.4')), isNull);
    expect(DioClient.motivoSesionCerrada('{roto'), isNull);
  });

  test('un token rechazado cuenta como ausente aunque no se haya podido borrar', () async {
    final vence = DateTime.now().add(const Duration(hours: 8)).millisecondsSinceEpoch.toString();
    FlutterSecureStorage.setMockInitialValues({'auth_token': 'viejo', 'token_expiry': vence});
    final almacen = SecureStorage();
    expect(await almacen.isTokenExpired(), isFalse);

    SecureStorage.anularToken('viejo');

    expect(await almacen.isTokenExpired(), isTrue);
    expect((await almacen.readTokenDetailed()).status, TokenReadStatus.absent);

    // Un login nuevo trae otro token y vuelve a valer.
    await almacen.saveToken('nuevo');
    expect((await almacen.readTokenDetailed()).status, TokenReadStatus.ok);
  });

  test('el mensaje de error de la pantalla usa el motivo; otro 401 sigue diciendo que expiró', () {
    expect(DioClient.handleDioError(error401(cuerpoCierre), 'x'), inactivo);
    expect(DioClient.handleDioError(error401({'error': 'No autorizado'}), 'x'), kSesionInvalidaMsg);
  });

  test('el motivo se entrega una sola vez', () {
    DioClient.registrarSesionCerrada(cuerpoCierre);

    expect(DioClient.tomarMotivoCierre(), inactivo);
    expect(DioClient.tomarMotivoCierre(), isNull);
  });

  testWidgets('el login muestra por qué se cerró la sesión', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    DioClient.registrarSesionCerrada(cuerpoCierre);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(theme: AppTheme().getTheme(), home: const LoginScreen()),
      ),
    );
    // pump con tiempo y no pumpAndSettle: el halo del logo respira sin parar.
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));

    expect(find.text(inactivo), findsOneWidget);
    expect(DioClient.tomarMotivoCierre(), isNull);
  });
}
