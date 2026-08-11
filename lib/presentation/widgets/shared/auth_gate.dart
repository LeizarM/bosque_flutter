import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/console_log.dart';

/// Deja pasar al dashboard sólo si hay un usuario válido.
///
/// <h3>Dos fuentes para el mismo hecho, y una llega tarde</h3>
/// El usuario vive en dos lados:
///
/// - `userProvider` — un `StateNotifier` que `setUser()` actualiza **en el acto**
///   al iniciar sesión;
/// - `asyncUserProvider` — un `FutureProvider` **sin `autoDispose`** que lee
///   `user_data` del storage y **se queda con ese valor**.
///
/// El segundo es el que este gate miraba, y ahí estaba el problema: después de
/// cerrar sesión queda cacheado en `null`, y al volver a entrar sigue
/// entregando ese `null` viejo durante uno o dos frames — el `invalidate()` del
/// login recién resuelve después. La secuencia real, sacada del log:
///
/// ```
/// 🔑 Token expira el: 2026-08-12 00:55:30.000     ← login OK, token nuevo
/// 🔐 AuthGate: usuario = NULL (sesión rota)       ← null viejo, todavía cacheado
/// 🔐 AuthGate: usuario = rramos                   ← el valor bueno, un frame después
/// ```
///
/// Una versión anterior de este gate, al ver ese `null`, borraba la sesión
/// entera para romper un ping-pong con el `redirect` del router. El efecto fue
/// destruir el token recién emitido: el primer login siempre fallaba y había que
/// escribir las credenciales dos veces.
///
/// <h3>La regla que quedó</h3>
/// **No se actúa destructivamente sobre un dato que puede estar viejo.** Cuando
/// `asyncUserProvider` dice `null`, se consulta `userProvider`, que es sincrónico
/// y no puede quedar atrasado respecto del login. Sólo si los dos coinciden en
/// que no hay nadie se navega a `/login` — y ni siquiera entonces se toca el
/// storage: cerrar sesión es responsabilidad de quien cierra sesión.
class AuthGate extends ConsumerWidget {
  final Widget child;
  const AuthGate({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncUser = ref.watch(asyncUserProvider);

    // Fuente sincrónica: `setUser()` la deja lista antes de navegar, así que
    // nunca va atrasada respecto del login.
    final userEnMemoria = ref.watch(userProvider);

    return asyncUser.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No se pudo validar tu sesión. Inicia sesión nuevamente.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      data: (user) {
        // El de memoria manda cuando el del storage viene vacío: ese `null`
        // puede ser el residuo del cierre de sesión anterior.
        final efectivo = user ?? userEnMemoria;

        if (efectivo == null) {
          // Ahora sí: las dos fuentes coinciden en que no hay sesión.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/login');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (user == null) {
          console(
            '🔐 AuthGate: asyncUserProvider venía vacío pero hay sesión en memoria '
            '(${efectivo.login}); se usa esa. El caché se pone al día solo.',
          );
        }

        return child;
      },
    );
  }
}
