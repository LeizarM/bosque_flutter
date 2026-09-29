/// La fila del listado de propuestas, ya convertida en entities.
///
/// El backend devuelve esta grilla como un DTO de despliegue —mezcla columnas
/// de tpr_propuesta con columnas de tpr_autorizacion y con nombres resueltos
/// por subconsulta a tb_usuario— y por eso el repositorio la entrega como
/// `Map<String, dynamic>`. Aca ese mapa se parte en las DOS entities que le
/// corresponden, para que la pantalla nunca lea una clave suelta ni decida el
/// estado comparando cadenas.
///
/// **Lo que este objeto NO es.** No sirve para escribir. La grilla no trae
/// `obs`, `codEmpresa` ni los ids de usuario, asi que la [PropuestaPrecioEntity]
/// que se arma aca tiene esos campos en su valor vacio. Usarla para una
/// modificacion de la cabecera haria un UPDATE que graba `obs = NULL` y
/// borraria la observacion real: p_abm_propuesta escribe todas las columnas en
/// la accion 'U', no solo las que cambiaron. Esta pantalla solo llama a las tres
/// escrituras del circuito de autorizacion, que reciben el id y nada mas.
library;

import 'package:flutter/material.dart';

import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/domain/entities/autorizacion_precio_entity.dart';
import 'package:bosque_flutter/domain/entities/propuesta_precio_entity.dart';

// ═══════════════════════════════════════════════════════════════════════════
// EL ESTADO, DE TEXTO A CODIGO
// ═══════════════════════════════════════════════════════════════════════════

/// Traduce la descripcion del estado al codigo del dominio (v_tipos grupo 38).
///
/// El listado principal no trae `esAprobada`: el procedimiento ya lo resolvio
/// contra v_tipos y devuelve "Pendiente", "Aprobada", "No Aprobada" o
/// "En Espera". Se vuelve al codigo porque el color, los permisos y las
/// acciones se deciden con [AutorizacionPrecioEntity] y sus getters, no
/// comparando cadenas por la pantalla.
///
/// "No Aprobada" se revisa ANTES que "Aprobada": la segunda esta contenida en
/// la primera y el orden inverso pintaba de verde una propuesta rechazada.
///
/// Devuelve -1 si la descripcion no es ninguna de las cuatro. No es un error
/// que se tape: la entity lo muestra como "Desconocido" y asi se ve que el
/// catalogo cambio, en vez de caer en "Pendiente" y parecer normal.
int codigoDeEstadoPropuesta(Object? descripcion) {
  final t = (descripcion ?? '').toString().trim().toLowerCase();
  if (t.isEmpty) return -1;
  if (t.contains('no aprob')) return 2;
  if (t.contains('aprob')) return 1;
  if (t.contains('espera')) return 3;
  if (t.contains('pend')) return 0;
  return -1;
}

// ═══════════════════════════════════════════════════════════════════════════
// LA FILA
// ═══════════════════════════════════════════════════════════════════════════

/// Una propuesta del listado con su autorizacion y los nombres que se muestran.
@immutable
class PropuestaEnAutorizacion {
  const PropuestaEnAutorizacion({
    required this.propuesta,
    required this.autorizacion,
    required this.propuestoPor,
    required this.resueltoPor,
    required this.generadoPor,
  });

  /// La cabecera, solo para mostrar. Ver la nota de la cabecera del archivo.
  final PropuestaPrecioEntity propuesta;

  /// El estado del circuito. Es la unica fuente del estado en esta pantalla.
  final AutorizacionPrecioEntity autorizacion;

  /// Quien creo la propuesta, ya resuelto a nombre completo por el backend.
  final String propuestoPor;

  /// Quien aprobo o rechazo. Vacio mientras no hubo decision.
  final String resueltoPor;

  /// Quien genero (exporto) la propuesta. Vacio mientras no se genero.
  final String generadoPor;

  /// Arma la fila desde el DTO del listado.
  ///
  /// Las fechas llegan como milisegundos desde epoch —el backend serializa
  /// `java.util.Date` sin formato declarado— pero se acepta tambien el texto
  /// ISO: un `@JsonFormat` agregado manana en el DTO no debe romper la grilla.
  factory PropuestaEnAutorizacion.desdeFila(Map<String, dynamic> fila) {
    return PropuestaEnAutorizacion(
      propuesta: PropuestaPrecioEntity(
        idPropuesta: _entero(fila['idPropuesta']),
        // El listado no trae empresa, observacion ni ids de usuario: quedan en
        // su valor vacio y no se muestran ni se mandan a ninguna escritura.
        codEmpresa: BigInt.zero,
        tipo: _int(fila['tipo']),
        titulo: _texto(fila['titulo']),
        obs: '',
        estado: 0,
        audUsGenerado: BigInt.zero,
        audFecGenerado: _fecha(fila['audFecGenerado']),
        audUsuario: BigInt.zero,
        audFecha: _fecha(fila['audFechaPropuesta']),
      ),
      autorizacion: AutorizacionPrecioEntity(
        idAutorizacion: _entero(fila['idAutorizacion']),
        idPropuesta: _entero(fila['idPropuesta']),
        esAprobada: codigoDeEstadoPropuesta(fila['estado']),
        // El DTO trae el NOMBRE de quien decidio, no su codigo de usuario. El
        // id queda en cero y quien pregunte si hay auditoria mira
        // [tieneResolucion], no el `tieneAuditoria` de la entity: ese pide un
        // id que esta consulta nunca devuelve.
        audUsuario: BigInt.zero,
        audFecha: _fecha(fila['audFechaAutorizacion']),
      ),
      propuestoPor: _texto(fila['datoPersonaP']),
      resueltoPor: _texto(fila['datoPersonaA']),
      generadoPor: _texto(fila['datoPersonaG']),
    );
  }

  BigInt get idPropuesta => propuesta.idPropuesta;

  /// "#1234", que es como se nombra una propuesta al hablar de ella.
  String get numero => '#${propuesta.idPropuesta}';

  String get titulo => propuesta.tituloLegible;

  /// Que se esta repreciando. El tipo decide que dialogo abria el sistema
  /// anterior y sigue siendo el dato que explica por que dos propuestas del
  /// mismo dia se ven distintas.
  String get etiquetaTipo => switch (propuesta.tipo) {
    1 => 'Por familia',
    2 => 'Por artículo',
    final otro => 'Tipo $otro',
  };

  /// Ya hubo decision y hay a quien atribuirsela.
  bool get tieneResolucion =>
      autorizacion.fueDecidida || resueltoPor.trim().isNotEmpty;

  String get fechaPropuesta => fechaCorta(propuesta.audFecha);
  String get fechaResolucion => fechaCorta(autorizacion.audFecha);
  String get fechaGeneracion => fechaCorta(propuesta.audFecGenerado);

  /// Lo mismo que muestra la grilla, para el buscador: numero, titulo y las
  /// tres personas. Se arma una vez por fila y por tecla, que a cien filas
  /// —el TOP que devuelve el procedimiento— no se nota.
  bool coincideCon(String consulta) {
    final q = consulta.trim().toLowerCase();
    if (q.isEmpty) return true;
    return '${propuesta.idPropuesta} ${propuesta.titulo} $propuestoPor '
            '$resueltoPor $generadoPor ${autorizacion.etiquetaEstado}'
        .toLowerCase()
        .contains(q);
  }
}

// ── Lectura defensiva del DTO ───────────────────────────────────────────────

String _texto(Object? v) => (v ?? '').toString().trim();

int _int(Object? v) => switch (v) {
  final int n => n,
  final num n => n.toInt(),
  final String s => int.tryParse(s.trim()) ?? 0,
  _ => 0,
};

BigInt _entero(Object? v) => switch (v) {
  final int n => BigInt.from(n),
  final num n => BigInt.from(n.toInt()),
  final String s => BigInt.tryParse(s.trim()) ?? BigInt.zero,
  _ => BigInt.zero,
};

DateTime? _fecha(Object? v) => switch (v) {
  final int ms => DateTime.fromMillisecondsSinceEpoch(ms),
  final num ms => DateTime.fromMillisecondsSinceEpoch(ms.toInt()),
  final String s when s.trim().isNotEmpty => DateTime.tryParse(s.trim()),
  _ => null,
};

// ═══════════════════════════════════════════════════════════════════════════
// QUE SE PUEDE HACER CON UNA PROPUESTA
// ═══════════════════════════════════════════════════════════════════════════

/// Las acciones habilitadas sobre una fila, con el motivo cuando no lo estan.
///
/// Es un objeto y no cinco `if` repartidos por la tabla y la tarjeta: las dos
/// superficies muestran las mismas acciones y tienen que decir lo mismo. Se
/// calcula con [accionesDe], que es pura.
@immutable
class AccionesPropuesta {
  const AccionesPropuesta({
    required this.puedeEditar,
    required this.muestraResolver,
    required this.motivoResolver,
    required this.muestraEnviarAEspera,
    required this.motivoEnviarAEspera,
    required this.muestraGenerar,
    required this.motivoGenerar,
  });

  /// Seguir armando la propuesta en el asistente. En el sistema anterior el
  /// boton "Editar" abria la vista preliminar con "Agregar Mas Familias" y
  /// "Enviar a autorizar": el asistente tiene las tres cosas. Pide btnPen, como
  /// entonces.
  final bool puedeEditar;

  /// **Visible** quiere decir "el usuario tiene el boton asignado"; el motivo
  /// dice si ademas se puede usar ahora. Se separan a proposito: un control que
  /// desaparece no se puede preguntar por que no esta, y uno que aparece
  /// deshabilitado sin explicacion se lee como una falla del sistema. Quien no
  /// tiene el permiso no ve nada, que es lo que hacia el `rendered` del XHTML.
  final bool muestraResolver;

  /// Por que no se puede resolver todavia. Null cuando si se puede.
  final String? motivoResolver;

  /// Mandarla a autorizar (estado En Espera). Boton btnPen.
  final bool muestraEnviarAEspera;
  final String? motivoEnviarAEspera;

  /// Marcarla como generada. Boton btnGen.
  final bool muestraGenerar;
  final String? motivoGenerar;

  /// Habilitadas de verdad: hay permiso y el estado lo permite.
  bool get resolverHabilitado => muestraResolver && motivoResolver == null;
  bool get enviarAEsperaHabilitado =>
      muestraEnviarAEspera && motivoEnviarAEspera == null;
  bool get generarHabilitado => muestraGenerar && motivoGenerar == null;
}

/// Que puede hacer este usuario con esta propuesta.
///
/// Las reglas de estado son las del sistema anterior, donde vivian dentro del
/// `rendered` de cada boton del XHTML:
///
/// * **Resolver** (aprobar o rechazar) solo cuando la propuesta esta En Espera.
///   Es el circuito: primero alguien la manda a autorizar y recien ahi el
///   autorizador decide. Una propuesta Pendiente todavia se esta armando.
/// * **Enviar a autorizar** mientras no este Aprobada ni ya En Espera.
/// * **Generar** solo cuando esta Aprobada: generar es exportar precios que
///   todavia no son precios.
/// * **Editar** solo mientras esta Pendiente.
///
/// Los permisos se pasan ya resueltos —no se leen aca— para que la funcion
/// quede pura y se pueda probar sin Riverpod ni contexto.
AccionesPropuesta accionesDe({
  required AutorizacionPrecioEntity autorizacion,
  required bool tieneBtnAprobar,
  required bool tieneBtnPen,
  required bool tieneBtnGen,
}) {
  final estado = autorizacion.etiquetaEstado;

  return AccionesPropuesta(
    puedeEditar: tieneBtnPen && autorizacion.esPendiente,
    muestraResolver: tieneBtnAprobar,
    motivoResolver:
        autorizacion.estaEnEspera
            ? null
            : 'Solo se aprueba o rechaza una propuesta En Espera. '
                'Esta está $estado.',
    muestraEnviarAEspera: tieneBtnPen,
    // Solo desde Pendiente: el rechazo es definitivo (2026-09-28). El sistema
    // anterior dejaba reenviar una rechazada y volvia a quedar En Espera.
    motivoEnviarAEspera:
        autorizacion.esPendiente
            ? null
            : autorizacion.estaEnEspera
            ? 'Ya está En Espera de autorización.'
            : autorizacion.fueRechazada
            ? 'Fue rechazada: no vuelve al circuito. Arme una propuesta nueva.'
            : 'Una propuesta aprobada ya no vuelve al circuito.',
    muestraGenerar: tieneBtnGen,
    motivoGenerar:
        autorizacion.estaAprobada
            ? null
            : 'Solo se genera una propuesta aprobada. Esta está $estado.',
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// EL CHIP DE ESTADO
// ═══════════════════════════════════════════════════════════════════════════

/// El estado de una propuesta, con el color puesto por lo que significa.
///
/// Se apoya en [Etiqueta], que toma los colores del ColorScheme: el usuario
/// elige la semilla del tema entre nueve y hay modo oscuro, asi que un verde
/// fijo —el `forestgreen` del XHTML anterior— se ve de otra aplicacion en la
/// mayoria de las combinaciones.
class ChipEstadoPropuesta extends StatelessWidget {
  const ChipEstadoPropuesta({super.key, required this.autorizacion});

  final AutorizacionPrecioEntity autorizacion;

  @override
  Widget build(BuildContext context) => Etiqueta(
    texto: autorizacion.etiquetaEstado,
    tono: switch (autorizacion.esAprobada) {
      1 => TonoEtiqueta.exito,
      2 => TonoEtiqueta.error,
      // En Espera no es un fracaso, es "le toca a usted": el tono de aviso es el
      // unico que se separa del principal con las nueve semillas.
      3 => TonoEtiqueta.aviso,
      _ => TonoEtiqueta.neutro,
    },
  );
}
