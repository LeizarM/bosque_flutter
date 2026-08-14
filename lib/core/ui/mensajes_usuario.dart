/// Traduce lo que devuelve el backend a algo que entienda quien usa la app.
///
/// **Por qué hace falta.** Los mensajes los escriben los procedimientos
/// almacenados y viajan tal cual hasta la pantalla. Ahí adentro son útiles —
/// nombran columnas, procedimientos y acciones— pero eso es vocabulario de
/// quien construyó el sistema, no de quien lo usa. «El campo idParticipante es
/// obligatorio» no le dice a nadie de RR.HH. qué hacer.
///
/// **La distinción que ordena todo esto:** hay dos clases de mensaje y merecen
/// tratos opuestos.
///
/// 1. **Reglas del negocio** — «el rol está cerrado», «esa persona ya no
///    participa». Le pasaron a la persona correcta y tiene que entenderlos: se
///    reescriben en su idioma y se muestran completos.
///
/// 2. **Errores de programación** — «falta el campo X», «ACCION no reconocida»,
///    un error de SQL con número de línea. Significan que la app mandó mal la
///    llamada. **No son culpa de quien usa la app y no puede hacer nada con
///    ellos**, así que se reemplazan por un aviso corto… pero el texto original
///    se imprime en la consola. Traducirlos a lenguaje amable sin más los
///    escondería, y un bug escondido no se arregla.
///
/// **Lo que hace difícil separarlos:** los `p_abm_` envuelven en su `CATCH`
/// todo lo que sale del procedimiento de adentro, y lo envuelven igual venga de
/// donde venga: `'Error al programar: ' + ERROR_MESSAGE() + ' | Linea: 991'`.
/// Por ese caño salen las dos clases de mensaje —la regla del negocio que
/// levantó un `RAISERROR` y el error de verdad del motor— con el mismo
/// disfraz. Así que el disfraz **no** sirve para clasificar: hay que sacarlo
/// primero y mirar el texto de adentro. Es lo que hace `_pelar`, y por eso
/// corre antes que todo lo demás.
///
/// **Nació en el módulo del Rol de Sábados y se mudó acá sin cambiar una
/// letra**: las reglas están escritas mirando los `RAISERROR` de los `trs_sp_`,
/// pero el envoltorio del `CATCH`, los errores del motor y los cortes de red
/// son los mismos para todos los `p_` del ERP, así que el segundo módulo que
/// muestra mensajes del backend —`permisos-rrhh`— usa esto mismo en vez de
/// escribir su propia versión. `rol-sabados/mensajes_usuario.dart` quedó como
/// re-export.
library;

import 'package:bosque_flutter/core/utils/console_log.dart';

/// Cómo mostrar un mensaje del backend.
class MensajeUsuario {
  /// El texto que ve la persona.
  final String texto;

  /// true si es un fallo técnico. La pantalla puede tratarlo distinto —por
  /// ejemplo sugerir avisar a sistemas en vez de invitar a corregir el dato.
  final bool esFalloTecnico;

  const MensajeUsuario(this.texto, {this.esFalloTecnico = false});
}

/// Reescribe [crudo] para mostrarlo en pantalla.
MensajeUsuario humanizar(Object? crudo) {
  var t = '$crudo'.trim();

  // Dio y el propio Flutter agregan estos prefijos; no aportan nada.
  for (final ruido in ['Exception: ', 'DioException: ', 'Error: ']) {
    while (t.startsWith(ruido)) {
      t = t.substring(ruido.length).trim();
    }
  }

  if (t.isEmpty) {
    return const MensajeUsuario(
      'No se pudo completar la operación.',
      esFalloTecnico: true,
    );
  }

  // ── 0. Fuera el envoltorio del CATCH, antes de clasificar nada ───────
  final sobre = _pelar(t);
  final cuerpo = sobre.cuerpo;

  // ── 1. Fallos técnicos ───────────────────────────────────────────────
  if (_esFalloTecnico(cuerpo)) return _tecnico(t);

  // ── 2. Problemas de conexión ─────────────────────────────────────────
  final conexion = _deConexion(cuerpo);
  if (conexion != null) return MensajeUsuario(conexion, esFalloTecnico: true);

  // ── 3. Reglas del negocio ────────────────────────────────────────────
  for (final regla in _reglas) {
    if (regla.$1.hasMatch(cuerpo)) return MensajeUsuario(regla.$2);
  }

  // ── 4. Venía envuelto y nadie lo reconoció ───────────────────────────
  // Por el `CATCH` sólo pasan dos cosas: reglas del negocio —que están en la
  // tabla de arriba— y excepciones del motor. Si llegó hasta acá es lo
  // segundo, o un mensaje nuevo del SQL que este archivo todavía no conoce.
  // En los dos casos mostrarlo crudo sería pegarle en la cara a quien usa la
  // app un texto que habla de tablas y líneas; se va al log, que es donde
  // sirve. (`test/mensajes_usuario_test.dart` existe justamente para que ese
  // segundo caso se note antes de que lo note un usuario.)
  if (sobre.envuelto) return _tecnico(t);

  // ── 5. Lo que no está en la tabla: se limpia y pasa ───────────────────
  return MensajeUsuario(_limpiar(cuerpo));
}

/// Atajo para cuando sólo se necesita el texto.
String textoParaUsuario(Object? crudo) => humanizar(crudo).texto;

// ═══════════════════════════════════════════════════════════════════════════

/// El aviso corto, con el original al log para que se pueda arreglar de verdad.
MensajeUsuario _tecnico(String original) {
  console('⚠️ Fallo técnico del backend: $original');
  return const MensajeUsuario(
    'No se pudo completar la operación por un problema del sistema. '
    'Vuelve a intentar; si sigue pasando, avisa a Sistemas.',
    esFalloTecnico: true,
  );
}

/// El prefijo que el `CATCH` de cada `p_abm_` le pone a lo que sea que falló:
/// «Error al programar:», «Error al dar de baja:», «Error al escribir la
/// celda:». El verbo cambia en cada procedimiento, así que se acepta cualquiera.
final _prefijoDelCatch = RegExp(
  r'^Error (al|en) [^:]{1,40}:\s*',
  caseSensitive: false,
);

/// Y el sufijo con la línea del SQL. Sin ancla al final a propósito: si algún
/// procedimiento le agrega algo después, igual hay que sacarlo — es lo único
/// del mensaje que no se le puede mostrar a nadie.
final _lineaDelSql = RegExp(
  r'\s*\|\s*Linea\s*:\s*\d+\.?',
  caseSensitive: false,
);

/// Saca el envoltorio del `CATCH` y avisa si lo había.
///
/// El «lo había» importa tanto como el texto: un mensaje que salió por un
/// `CATCH` y no coincide con ninguna regla conocida es sospechoso, mientras
/// que el mismo texto sin envoltorio es simplemente un mensaje que el
/// procedimiento devolvió a propósito.
({String cuerpo, bool envuelto}) _pelar(String t) {
  var pelado = t.replaceFirst(_prefijoDelCatch, '');
  pelado = pelado.replaceAll(_lineaDelSql, '').trim();
  if (pelado.isEmpty || pelado == t) return (cuerpo: t, envuelto: false);
  return (cuerpo: pelado, envuelto: true);
}

/// Qué delata a un fallo técnico, mirando el mensaje **ya sin envoltorio**.
///
/// La marca vieja era `| Linea:`, y era la equivocada: el `CATCH` la agrega
/// igual cuando revienta el motor que cuando el procedimiento de adentro
/// rechaza por una regla («esa persona no es tu dependiente»). Lo que sí
/// distingue es de dónde salió el texto: las reglas las escribimos nosotros,
/// en castellano y hablando de gente; lo del motor viene en inglés y hablando
/// de claves, tipos y transacciones.
bool _esFalloTecnico(String t) {
  final b = t.toLowerCase();
  return
  // Lo que contesta el backend cuando algo se rompió de verdad: «Error interno
  // del servidor.» es el cuerpo fijo de todo 500, y «Ocurrió un error en el
  // servidor» lo pone Dio cuando ni eso vino.
  //
  // Hace falta desde que los `trs_sp_` distinguen: el rechazo del negocio baja
  // como 400 con el texto del procedimiento adentro —y `BaseApiRepository`
  // sólo lee el `message` del cuerpo en los 400—, así que un 500 ya no puede
  // ser «el procedimiento dijo que no». Es algo roto, y sin esto la pantalla
  // lo mostraba como un aviso común: sin invitar a avisar a Sistemas y sin
  // dejar rastro en el log.
  b.contains('error interno del servidor') ||
      b.contains('error en el servidor') ||
      b.contains('es obligatorio') ||
      b.contains('accion no reconocida') ||
      b.contains('no existe el rol con') ||
      b.contains('sqlserver') ||
      b.contains('jdbc') ||
      b.contains('nullpointer') ||
      b.contains('sintaxis en la base') ||
      _delMotor.hasMatch(b);
}

/// Lo que dice SQL Server cuando el que se equivocó fue el sistema, no la
/// persona. El `Err 1205 (linea 30):` es el envoltorio propio de los `trs_sp_`,
/// que sí es marca de excepción de verdad: ahí adentro no viaja ninguna regla.
final _delMotor = RegExp(
  r'\berr \d+ \(linea|duplicate key|constraint|conversion failed|'
  r'arithmetic overflow|string or binary|incorrect syntax|deadlock|'
  r'invalid (object|column) name',
  caseSensitive: false,
);

String? _deConexion(String t) {
  final b = t.toLowerCase();
  if (b.contains('connection') ||
      b.contains('socket') ||
      b.contains('timeout') ||
      b.contains('tiempo de espera') ||
      b.contains('failed host lookup')) {
    return 'No se pudo conectar con el servidor. Revisa la conexión y vuelve a '
        'intentar.';
  }

  // Los números sueltos son ambiguos desde que los mensajes del SQL nombran al
  // empleado por su código: «El empleado 403 no es dependiente…» no es un
  // Forbidden. Cuentan como código HTTP sólo si abren el mensaje o vienen con
  // el vocabulario de la red.
  bool codigo(String n) =>
      b.startsWith(n) ||
      (b.contains(n) &&
          (b.contains('http') ||
              b.contains('status') ||
              b.contains('dioexception')));

  if (b.contains('unauthorized') || codigo('401')) {
    return 'Tu sesión venció. Vuelve a iniciar sesión.';
  }
  // Ojo: acá NO va la palabra «permisos». El módulo tiene una acción que se
  // llama «refrescar permisos» y un estado 'P' de permiso de RR.HH.; con
  // aquella condición, cualquier mensaje sobre las vacaciones de la gente
  // terminaba convertido en «no tenés permiso para hacer este cambio».
  if (b.contains('forbidden') || codigo('403')) {
    return 'No tienes permiso para hacer este cambio.';
  }
  return null;
}

/// Las reglas del negocio, en el idioma de quien usa la app.
///
/// Cada una explica **qué pasó y qué hacer**, que es lo que el mensaje original
/// no siempre dice. El orden importa: gana la primera que coincide, así que las
/// más específicas van arriba.
final _reglas = <(RegExp, String)>[
  // ── el rol ──────────────────────────────────────────────────────────
  //
  // **El `%s` parte la frase, y por eso los patrones de acá tienen un comodín
  // en el medio.** `trs_sp_generarRol` arma sus rechazos con
  // `RAISERROR('El rol %s esta CERRADO...', 16, 1, @nombre)`, y `@nombre` es
  // `'ROL ' + el año`. Lo que llega es «El rol ROL 2026 esta CERRADO», no «El
  // rol esta CERRADO»: cualquier patrón que pegue las dos palabras falla
  // contra el mensaje de verdad. Y fallar acá no se ve como una regla que
  // falta —el fail-closed de más arriba lo convierte en «problema del
  // sistema»—, así que el usuario terminaba creyendo que rompió algo cuando en
  // realidad el SP le estaba explicando qué hacer.
  //
  // El comodín es `[^.;]` a propósito: se queda dentro de la primera oración.
  // Con `.` un mensaje largo que nombre un rol al principio y diga «esta
  // CERRADO» tres frases después también entraría.
  (
    RegExp(r'rol[^.;]{0,40}esta PUBLICADO', caseSensitive: false),
    'El rol de este año ya está publicado: la rotación de sábados ya se '
        'repartió y no se vuelve a repartir sola. Si de verdad hay que '
        'rehacerla, toca el estado «PUBLICADO» en el encabezado, elige '
        '«Reabrir» y sólo entonces regenera. Programar desde «Su equipo», '
        'corregir una celda, declarar un evento y convocar siguen funcionando '
        'sin reabrir nada.',
  ),
  (
    RegExp(r'rol[^.;]{0,40}esta CERRADO', caseSensitive: false),
    'El rol de este año está cerrado y ya no admite cambios. Si hay que '
        'corregir algo, RR.HH. tiene que reabrirlo.',
  ),
  (
    // Las dos formas del mismo rechazo: la del SP («El rol ROL 2026 ya
    // existe…») y la que usan los ABM («Ya existe el rol…»).
    RegExp(
      r'(ya existe el rol|rol[^.;]{0,40}ya existe)',
      caseSensitive: false,
    ),
    'Ya hay un rol generado para ese año. Si quieres actualizarlo con el '
        'personal de hoy, usa «Regenerar» en vez de «Crear».',
  ),
  (
    RegExp(r'Anio fuera de rango', caseSensitive: false),
    'El año no parece válido. Escribe un año entre 2000 y 2100.',
  ),

  // ── participantes ───────────────────────────────────────────────────
  (
    RegExp(r'ya es participante de ese rol', caseSensitive: false),
    'Esa persona ya está en el rol.',
  ),
  (
    RegExp(
      r'(titular|reemplazo).*no es participante activo',
      caseSensitive: false,
    ),
    'Esa persona ya no figura activa en el rol. Puede haberse dado de baja '
        'después de que se registró el pedido.',
  ),
  (
    RegExp(r'no es participante activo del rol', caseSensitive: false),
    'Esa persona no está en el rol de este año, así que no se le puede marcar '
        'el sábado. Si tendría que estar, avisa a RR.HH. para que la agregue.',
  ),
  (
    RegExp(r'participante no pertenece a ese rol', caseSensitive: false),
    'Esa persona no pertenece a este rol.',
  ),
  (
    RegExp(
      r'reemplazo no puede ser (el mismo titular|la misma persona)',
      caseSensitive: false,
    ),
    'Quien cubre tiene que ser otra persona, no la misma que no viene.',
  ),
  (
    RegExp(r'ya esta registrado como programador', caseSensitive: false),
    'Esa persona ya tiene permiso para programar en esa sucursal.',
  ),

  // ── sábados y eventos ───────────────────────────────────────────────
  (
    RegExp(r'sabado inexistente', caseSensitive: false),
    'Ese sábado ya no está en el rol. Actualiza la pantalla y vuelve a '
        'elegirlo.',
  ),
  (
    RegExp(r'sabado no pertenece', caseSensitive: false),
    'Ese sábado no es de este rol.',
  ),
  (
    RegExp(r'sabado esta desactivado', caseSensitive: false),
    'Ese sábado está desactivado y no admite cambios.',
  ),
  (
    // «Ese sabado ya paso.» Programar es decidir a futuro; para arreglar algo
    // de un sábado que ya fue, la corrección la hace RR.HH. sobre la celda.
    RegExp(r'ya paso', caseSensitive: false),
    'Ese sábado ya pasó. Desde aquí se programa para adelante; si hay que '
        'corregir un sábado que ya fue, pedíselo a RR.HH.',
  ),
  (
    RegExp(r'no tiene evento', caseSensitive: false),
    'Ese sábado todavía no tiene un evento declarado. Márcalo primero como '
        'jornada TOTAL o SELECTIVA, y después convoca a la gente.',
  ),

  // ── cambios ─────────────────────────────────────────────────────────
  (
    RegExp(r'ya (esta|estaba) APROBADO', caseSensitive: false),
    'Ese cambio ya fue aprobado y sus horarios están aplicados. Para corregir '
        'algo, hay que editar las celdas una por una en la grilla.',
  ),
  (
    RegExp(r'PERMUTA necesita', caseSensitive: false),
    'Una permuta necesita el sábado que se le devuelve a quien cubre. '
        'Elígelo, o regístralo como cobertura.',
  ),
  (
    RegExp(r'cambio esta (RECHAZADO|ANULADO)', caseSensitive: false),
    'Ese cambio ya fue rechazado o anulado, así que no se puede aprobar.',
  ),
  (
    RegExp(r'No existe el cambio', caseSensitive: false),
    'No se encontró ese cambio. Actualiza la lista.',
  ),

  // ── celdas y estados ────────────────────────────────────────────────
  (
    RegExp(r'Codigo de estado invalido', caseSensitive: false),
    'Ese estado no existe o está inactivo en el catálogo.',
  ),
  (
    RegExp(r'estado esta en uso por celdas', caseSensitive: false),
    'Ese estado se está usando en la grilla, así que no se borró: quedó '
        'inactivo para que no se pueda elegir de nuevo.',
  ),

  // ── programación ────────────────────────────────────────────────────
  (
    RegExp(
      r'no (es|figura como|esta registrado como) programador',
      caseSensitive: false,
    ),
    'Esa persona no tiene permiso para programar a otros.',
  ),
  (
    RegExp(r'no es dependiente del programador', caseSensitive: false),
    'Esa persona no está a tu cargo según el organigrama, así que no la puedes '
        'programar. Si igual depende de ti, el organigrama lo corrige RR.HH.',
  ),
  (
    RegExp(r'no (cuelga|depende) de', caseSensitive: false),
    'Esa persona no está a cargo de quien se quiere programar, según el '
        'organigrama.',
  ),
  (
    RegExp(r'solo se puede marcar', caseSensitive: false),
    'Desde «Su Equipo» sólo puedes marcar si esa persona viene o no viene. '
        'Vacaciones, permisos y feriados los carga RR.HH.',
  ),
  (
    // El sábado ya lo tocó otro jefe. Pisarlo sería borrarle la decisión sin
    // que se entere, así que se rebota y se avisa quién la tomó.
    RegExp(r'otro jefe', caseSensitive: false),
    'Esa programación la hizo otro jefe. Hablalo con él; si igual hay que '
        'cambiarla, RR.HH. la puede anular.',
  ),
  (
    // Va última a propósito: es la más ancha de la tabla. Hoy el único mensaje
    // del SQL que nombra a RR.HH. es el que frena al jefe cuando la celda ya
    // tiene una vacación, una baja, un feriado o un permiso cargado. Si mañana
    // aparece otro, tiene que ir ARRIBA de ésta.
    RegExp(
      r'^(?=.*(RR\.?\s*HH|RRHH|recursos humanos))'
      r'(?=.*(celda|vacacion|permiso|feriado|baja|licencia))',
      caseSensitive: false,
    ),
    'RR.HH. ya cargó una vacación, un permiso o un feriado para esa persona '
        'ese día, así que ese sábado no viene. Si eso cambió, la corrección la '
        'hace RR.HH.',
  ),
];

/// Saca de un mensaje que sí se muestra los rastros de cómo está hecho el
/// sistema: nombres de procedimientos, `@ACCION='X'` y comillas dobles sueltas.
String _limpiar(String t) {
  var r =
      t
          .replaceAll(
            RegExp(
              r"""\s*Use\s+@ACCION\s*=\s*'?\w+'?\.?""",
              caseSensitive: false,
            ),
            '',
          )
          .replaceAll(
            RegExp(
              r"\s*use\s+(p_abm_|p_list_|trs_sp_)\w+[^.]*\.?",
              caseSensitive: false,
            ),
            '',
          )
          .replaceAll(RegExp(r'\b(p_abm_|p_list_|trs_sp_)\w+'), 'el sistema')
          .replaceAll(RegExp(r"@ACCION\s*=\s*'?\w+'?"), '')
          .replaceAll(RegExp(r'\s{2,}'), ' ')
          .trim();

  if (r.isEmpty) return t;
  if (!r.endsWith('.') && !r.endsWith('!') && !r.endsWith('?')) r = '$r.';
  return r;
}
