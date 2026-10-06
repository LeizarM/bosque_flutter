/// Cuando vale la pena preguntarle al servidor por un par talonario / recibo
/// manual mientras el usuario escribe. Logica pura, sin Flutter ni Riverpod.
///
/// Es solo un aviso temprano: el servidor vuelve a validar al guardar y manda.
library;

import 'package:bosque_flutter/domain/utils/reglas_cheque.dart';

/// Cuanto se espera desde la ultima tecla antes de consultar al servidor.
const Duration esperaComprobarTalonario = Duration(milliseconds: 600);

/// `true` solo si hay algo que comprobar contra la numeracion de la empresa: los
/// dos textos, ya recortados, no estan vacios, ninguno es «0» y los dos cumplen
/// el formato que el propio formulario ya exige.
///
/// - Vacio o «0» (se compara exacto, como el legacy): no hay talonario o recibo
///   manual que mirar en la base. Las reglas que ligan el recibo con quien
///   entrego el cheque las cubre el formulario.
/// - Formato invalido: el campo ya muestra su propio error; consultar al servidor
///   mientras se escribe a medias solo ensuciaria la pantalla.
bool debeComprobarTalonario(String talonario, String recibo) {
  final t = talonario.trim();
  final r = recibo.trim();
  if (t.isEmpty || r.isEmpty) return false;
  if (t == '0' || r == '0') return false;
  return ReglasCheque.errorNroTalonario(t) == null &&
      ReglasCheque.errorReciboManual(r) == null;
}
