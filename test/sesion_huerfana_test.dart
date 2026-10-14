import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/secure_storage.dart';
import 'package:bosque_flutter/domain/entities/login_entity.dart';
import 'package:bosque_flutter/presentation/widgets/shared/auth_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Android, 14/10/2026: la app quedaba con la ruedita para siempre después de entrar.
/// Un token vigente sin `user_data` hacía rebotar /login → /dashboard sin fin, y la carga
/// inicial del usuario pisaba al que acababa de entrar con lo que había de una sesión vieja.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final vence = DateTime.now().add(const Duration(hours: 8)).millisecondsSinceEpoch.toString();

  LoginEntity usuario(int cod, String login) => LoginEntity.fromJson({
    'token': 'token-$login',
    'login': login,
    'codUsuario': cod,
    'versionApp': '1.0.1',
  });

  testWidgets('token vigente sin usuario guardado: va al login en vez de girar sin fin', (tester) async {
    FlutterSecureStorage.setMockInitialValues({'auth_token': 'huerfano', 'token_expiry': vence});
    final router = GoRouter(
      initialLocation: '/dashboard',
      // Lo esencial del redirect real: con token vigente, /login vuelve al dashboard.
      redirect: (context, state) async {
        final vencido = await SecureStorage().isTokenExpired();
        return !vencido && state.matchedLocation == '/login' ? '/dashboard' : null;
      },
      routes: [
        GoRoute(path: '/login', builder: (_, __) => const Text('login')),
        GoRoute(path: '/dashboard', builder: (_, __) => const AuthGate(child: Text('panel'))),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          asyncUserProvider.overrideWith((ref) async => null),
          userProvider.overrideWith((ref) => UserStateNotifier.sinStorage(null)),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.text('login'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  test('la carga inicial no pisa al usuario que acaba de entrar', () async {
    FlutterSecureStorage.setMockInitialValues({
      'user_data': '{"login":"otro","codUsuario":34,"versionApp":"1.0.1","token":"viejo"}',
    });
    final notifier = UserStateNotifier();

    expect(await notifier.setUser(usuario(7, 'nuevo')), isTrue);
    await pumpEventQueue();

    expect(notifier.state?.codUsuario, 7);
  });

  test('un user_data ilegible de antes no borra la sesión recién guardada', () async {
    FlutterSecureStorage.setMockInitialValues({'user_data': 'Data has been reset'});
    final notifier = UserStateNotifier();

    expect(await notifier.setUser(usuario(7, 'nuevo')), isTrue);
    await pumpEventQueue();

    expect(notifier.state?.codUsuario, 7);
    expect(await SecureStorage().getToken(), 'token-nuevo');
    expect(await SecureStorage().getUserData(), contains('"codUsuario":7'));
  });
}
