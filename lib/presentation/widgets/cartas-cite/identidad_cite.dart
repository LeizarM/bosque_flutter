import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/carta_cite_entity.dart';
import 'package:flutter/material.dart';

export 'package:bosque_flutter/core/ui/piezas_bosque.dart' show ArrastreLateral;
export 'package:bosque_flutter/core/ui/tokens_bosque.dart' show Esquina;

/// La identidad visual de un tipo de documento: su ícono, su color y una línea
/// que dice para qué sirve.
///
/// ## Por qué el tipo tiene que verse y no sólo leerse
///
/// En el listado conviven seis tipos y todos pesaban igual: una palabra, en la
/// misma tipografía, en la misma columna. Encontrar «la carta de la semana
/// pasada» entre veinte memorandos obligaba a leer fila por fila. Un ícono y un
/// color se reconocen antes de leer, y es lo único que hace falta para saltar
/// directo al bloque correcto.
///
/// ## De dónde sale el color
///
/// De la misma rampa medida que usa el cronograma de permisos: familia + tono,
/// y sólo las familias que se separan con las nueve semillas del tema. Acá no
/// hay ningún hex propio a propósito — un violeta elegido a mano se vería roto
/// en cuanto alguien ponga el tema en rojo.
///
/// ## Por qué una posición y no el id
///
/// Los ids de `tcr_tipoDocumento` son 1, 2, 6, 7, 8 y 9. Usarlos como posición
/// en la rampa dejaría tres escalones muertos y haría que dos tipos cayeran en
/// el mismo color. La posición de acá es el orden en que se muestran: estable,
/// y sobre todo **disponible sin el catálogo**. Una fila de la grilla sabe su
/// color mirando su `idTipoDoc`, sin esperar a que llegue `tiposDocumento`.
///
/// El texto del tipo, en cambio, **siempre viene de la base**: acá no se copia
/// ningún nombre. Si mañana renombran «COM. CI», la pantalla se entera sola.
class IdentidadCite {
  final IconData icono;

  /// Para qué sirve este tipo, en una línea. Sale de las reglas reales de
  /// [TipoCite], no de una descripción inventada.
  final String paraQue;

  /// Posición en la rampa de color. -1 para un tipo que no está en el mapa.
  final int _posicion;

  const IdentidadCite._(this.icono, this.paraQue, this._posicion);

  ColorDeEstado color(ColorScheme cs) => _colorDeCategoria(cs, _posicion);
}

const _sinIdentidad = IdentidadCite._(
  Icons.description_outlined,
  'Tipo de documento nuevo, todavía sin ficha acá.',
  -1,
);

const _identidades = <int, IdentidadCite>{
  TipoCite.carta: IdentidadCite._(
    Icons.mail_outline,
    'Va a alguien de afuera. Lleva ciudad y referencia, y se puede imprimir '
        'con membrete o sin él.',
    0,
  ),
  TipoCite.memorando: IdentidadCite._(
    Icons.assignment_outlined,
    'Interno. El destinatario sale de la planilla y el cargo se completa solo.',
    1,
  ),
  TipoCite.certificadoTrabajo: IdentidadCite._(
    Icons.workspace_premium_outlined,
    'Acredita la relación laboral. No lleva destinatario y el área la fija el '
        'sistema.',
    2,
  ),
  TipoCite.comunicacionInterna: IdentidadCite._(
    Icons.campaign_outlined,
    'Interna, a una persona de la planilla. Lleva asunto.',
    3,
  ),
  TipoCite.informeControlInterno: IdentidadCite._(
    Icons.fact_check_outlined,
    'Lleva «Vía:» además del destinatario, para que pase por quien corresponde.',
    4,
  ),
  TipoCite.comunicacionCi: IdentidadCite._(
    Icons.forum_outlined,
    'El destinatario se imprime como «DE:». Lleva ciudad y referencia.',
    5,
  ),
};

IdentidadCite identidadCite(int idTipoDoc) =>
    _identidades[idTipoDoc] ?? _sinIdentidad;

/// La rampa de [colorDeTipoPermiso], con el nombre que corresponde acá.
///
/// Aquella función quedó bautizada por el módulo donde nació, pero lo que hace
/// es genérico: «dame el color número N de una escala que aguanta las nueve
/// semillas». Se envuelve en vez de duplicarse para que las dos pantallas
/// hereden cualquier ajuste futuro de la escala.
ColorDeEstado _colorDeCategoria(ColorScheme cs, int posicion) =>
    colorDeTipoPermiso(cs, posicion);

// ═══════════════════════════════════════════════════════════════════════════
// PIEZAS QUE USAN LA IDENTIDAD
// ═══════════════════════════════════════════════════════════════════════════

/// El cuadrado con el ícono del tipo. Es el ancla visual de la fila, de la
/// tarjeta y del encabezado del formulario: siempre el mismo color para el
/// mismo tipo, en los tres lugares.
class SelloTipoCite extends StatelessWidget {
  final int idTipoDoc;

  /// Nombre del tipo tal como lo devuelve la base. Va al tooltip, porque el
  /// color solo no alcanza: seis categorías no entran del todo en el canal
  /// color, y quien no las distinga tiene que poder preguntarle al ícono.
  final String tipo;

  final double lado;

  const SelloTipoCite({
    super.key,
    required this.idTipoDoc,
    required this.tipo,
    this.lado = 40,
  });

  @override
  Widget build(BuildContext context) {
    final id = identidadCite(idTipoDoc);
    final c = id.color(context.cs);

    return Tooltip(
      message: tipo.isEmpty ? 'Documento' : tipo,
      waitDuration: const Duration(milliseconds: 600),
      child: Container(
        width: lado,
        height: lado,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.fondo,
          borderRadius: BorderRadius.circular(Esquina.chica),
        ),
        child: Icon(id.icono, size: lado * 0.5, color: c.texto),
      ),
    );
  }
}

/// Si el documento ya salió en papel.
///
/// Antes era un ícono de 16 px sin rótulo, y su ausencia no decía nada: podía
/// significar «no impreso» o «esta versión todavía no lo muestra». Ahora los
/// dos estados están escritos, que es la única forma de que la ausencia de
/// marca sea información.
///
/// No es decorativo: quien archiva necesita saber si una carta ya salió antes
/// de corregirla o de volver a numerarla.
class EstadoImpresionCite extends StatelessWidget {
  final bool impreso;

  /// En la tarjeta hay lugar para la palabra; en la grilla, a veces no.
  final bool soloIcono;

  const EstadoImpresionCite({
    super.key,
    required this.impreso,
    this.soloIcono = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final icono = impreso ? Icons.task_alt : Icons.schedule_outlined;
    final texto = impreso ? 'Impreso' : 'Sin imprimir';
    final color = impreso ? cs.primary : cs.onSurfaceVariant;

    return Tooltip(
      message: impreso
          ? 'Ya se generó el PDF de este documento'
          : 'Todavía no se generó el PDF',
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: soloIcono ? Esp.xs : Esp.s,
          vertical: 3,
        ),
        decoration: BoxDecoration(
          color: impreso
              ? cs.primary.withValues(alpha: 0.10)
              : Colors.transparent,
          border: Border.all(
            color: impreso
                ? cs.primary.withValues(alpha: 0.35)
                : cs.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(Esquina.pastilla),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 13, color: color),
            if (!soloIcono) ...[
              const SizedBox(width: 4),
              Text(
                texto,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: color, fontWeight: Peso.titulo),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Un dato suelto con su ícono: la fecha, la empresa, quién redactó.
///
/// Es la pieza que arma el pie de las tarjetas. Sin fondo y sin borde: son
/// cuatro o cinco por tarjeta, y encajonar cada uno convertía la tarjeta en una
/// bolsa de cajitas.
class DatoCite extends StatelessWidget {
  final IconData icono;
  final String texto;
  final bool destacado;

  const DatoCite({
    super.key,
    required this.icono,
    required this.texto,
    this.destacado = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final color = destacado ? cs.onSurface : cs.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 14, color: cs.onSurfaceVariant),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            texto,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: destacado ? Peso.titulo : Peso.normal,
                ),
          ),
        ),
      ],
    );
  }
}

// `Esquina` y `ArrastreLateral` se mudaron a `core/ui/`: los necesitaba tambien
// el modulo de produccion y con eso iban a ser dos copias. El codigo no cambio;
// se re-exportan desde aqui para no tocar los importadores de este archivo.
