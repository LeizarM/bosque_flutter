/// La fila del listado de propuestas, ya convertida en entities: el DTO de
/// despliegue del backend (tpr_propuesta, tpr_autorizacion y nombres por
/// subconsulta a tb_usuario) llega como `Map<String, dynamic>` y aquí se parte en
/// las DOS entities.
///
/// NO sirve para escribir: la grilla no trae `obs`, `codEmpresa` ni ids de
/// usuario y un UPDATE de cabecera grabaría `obs = NULL` (p_abm_propuesta escribe
/// todas las columnas en la acción 'U'). Solo se usan las tres escrituras del
/// circuito de autorización, que reciben el id.
library;

import 'package:flutter/material.dart';

import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/domain/entities/autorizacion_precio_entity.dart';
import 'package:bosque_flutter/domain/entities/propuesta_precio_entity.dart';

// El estado, de texto a código

/// Traduce la descripción del estado al código del dominio (v_tipos grupo 38).
///
/// El listado trae "Pendiente", "Aprobada", "No Aprobada" o "En Espera". "No
/// Aprobada" se revisa ANTES que "Aprobada" (la contiene: al revés pintaba de
/// verde un rechazo). Devuelve -1 si no es ninguna: la entity lo muestra
/// "Desconocido" y así se nota que el catálogo cambió.
int codigoDeEstadoPropuesta(Object? descripcion) {
  final t = (descripcion ?? '').toString().trim().toLowerCase();
  if (t.isEmpty) return -1;
  if (t.contains('no aprob')) return 2;
  if (t.contains('aprob')) return 1;
  if (t.contains('espera')) return 3;
  if (t.contains('pend')) return 0;
  return -1;
}

// La fila

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

  /// Arma la fila desde el DTO del listado. Las fechas llegan como milisegundos
  /// desde epoch (`java.util.Date` sin formato), pero se acepta también texto ISO
  /// por si el DTO agrega un `@JsonFormat`.
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
        // El DTO trae el NOMBRE de quien decidió, no su código: el id queda en cero y
        // se pregunta [tieneResolucion], no el `tieneAuditoria` de la entity (pide un
        // id que esta consulta nunca devuelve).
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

  /// Qué se está repreciando. El tipo decidía qué diálogo abría el sistema anterior
  /// y explica por qué dos propuestas del mismo día se ven distintas.
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

  /// Lo que muestra la grilla, para el buscador: número, título y las tres
  /// personas. Se arma por fila y tecla; con ~100 filas (TOP del SP) no se nota.
  bool coincideCon(String consulta) {
    final q = consulta.trim().toLowerCase();
    if (q.isEmpty) return true;
    return '${propuesta.idPropuesta} ${propuesta.titulo} $propuestoPor '
            '$resueltoPor $generadoPor ${autorizacion.etiquetaEstado}'
        .toLowerCase()
        .contains(q);
  }
}

// Lectura defensiva del DTO

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

// Qué se puede hacer con una propuesta

/// Las acciones habilitadas sobre una fila, con el motivo cuando no lo están.
/// Es un objeto y no `if` repartidos: tabla y tarjeta deben decir lo mismo. Se
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

  /// Seguir armando la propuesta en el asistente (el "Editar" del sistema anterior
  /// abría la vista preliminar con "Agregar Más Familias" y "Enviar a autorizar").
  /// Pide btnPen, como entonces.
  final bool puedeEditar;

  /// **Visible** = el usuario tiene el botón asignado; el motivo dice si además se
  /// puede usar ahora. Separados a propósito: un control que desaparece no se puede
  /// explicar y uno deshabilitado sin motivo parece una falla. Sin permiso no se
  /// ve nada (como el `rendered` del XHTML).
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

/// Qué puede hacer este usuario con esta propuesta. Reglas de estado del sistema
/// anterior (el `rendered` de cada botón del XHTML):
///
/// * **Resolver** (aprobar o rechazar): solo En Espera; una Pendiente aún se arma.
/// * **Enviar a autorizar**: mientras no esté Aprobada ni En Espera.
/// * **Generar**: solo Aprobada (exportar precios que aún no son precios).
/// * **Editar**: solo Pendiente.
///
/// Los permisos llegan ya resueltos para que la función sea pura y se pruebe
/// sin Riverpod ni contexto.
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
    // Solo desde Pendiente: el rechazo es definitivo (el sistema anterior dejaba
    // reenviar una rechazada y volvía a En Espera).
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

// El chip de estado

/// El estado de una propuesta, con el color puesto por lo que significa. Usa
/// [Etiqueta] (colores del ColorScheme): con nueve semillas de tema y modo
/// oscuro, un verde fijo (el `forestgreen` del XHTML) desentona.
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
