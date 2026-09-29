import 'package:flutter/material.dart';

import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/grupo_fam_tipo_rango_gram_entity.dart';

/// Una asignacion de gramaje con sus tres descripciones ya resueltas.
///
/// La entity guarda ids -y ademas int, no BigInt, porque asi son las columnas
/// de tpr_grupoFamTipoRangoGram-, pero en pantalla nadie reconoce un id: el
/// cruce contra los catalogos se hace una sola vez, en la pantalla, y la tabla
/// recibe el texto listo para dibujar.
@immutable
class FilaParametroGramaje {
  const FilaParametroGramaje({
    required this.parametro,
    required this.grupo,
    required this.tipo,
    required this.rango,
  });

  /// La fila tal como vino del backend: es lo que se manda de vuelta al editar
  /// o al eliminar, porque la clave natural viaja adentro.
  final GrupoFamTipoRangoGramEntity parametro;

  final String grupo;
  final String tipo;
  final String rango;

  /// Busqueda de una sola caja sobre las tres descripciones. Sin acentos ni
  /// mayusculas: quien busca "carton" tiene que encontrar "Cartón".
  bool coincideCon(String texto) {
    final buscado = _plano(texto);
    if (buscado.isEmpty) return true;
    return _plano('$grupo $tipo $rango').contains(buscado);
  }

  static String _plano(String texto) {
    const conAcento = 'áàäâãéèëêíìïîóòöôõúùüûñç';
    const sinAcento = 'aaaaaeeeeiiiiooooouuuunc';
    final buffer = StringBuffer();
    for (final letra in texto.toLowerCase().trim().split('')) {
      final i = conAcento.indexOf(letra);
      buffer.write(i >= 0 ? sinAcento[i] : letra);
    }
    return buffer.toString();
  }
}

/// El listado de parametros de gramaje, en sus dos formas.
///
/// El layout NO es el mismo escalado: en escritorio es una tabla con columnas
/// y acciones en linea, y en movil son tarjetas con las acciones en un menu
/// contextual. El corte se decide con el [Aire] que mide la pantalla sobre el
/// ancho del cajon, no con `MediaQuery`: adentro del dashboard el sidebar se
/// come 260 px y la ventana miente.
///
/// Son cinco columnas, asi que reparten el ancho sin scroll horizontal. Si
/// algun dia se agregan mas, el patron correcto es el de TablaLotes -cabecera
/// fija y scroll horizontal controlado-, no apretar estas.
class TablaParametrosGramaje extends StatelessWidget {
  const TablaParametrosGramaje({
    super.key,
    required this.filas,
    required this.aire,
    required this.onEditar,
    required this.onEliminar,
  });

  final List<FilaParametroGramaje> filas;
  final Aire aire;
  final void Function(FilaParametroGramaje fila) onEditar;
  final void Function(FilaParametroGramaje fila) onEliminar;

  @override
  Widget build(BuildContext context) {
    if (aire.esChico) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final fila in filas)
            Padding(
              padding: const EdgeInsets.only(bottom: Esp.s),
              child: _Tarjeta(
                fila: fila,
                onEditar: () => onEditar(fila),
                onEliminar: () => onEliminar(fila),
              ),
            ),
        ],
      );
    }

    // La fecha de auditoria es la primera que se va cuando el cajon aprieta:
    // ayuda, pero no es por lo que alguien entra a esta pantalla.
    final conFecha = aire == Aire.amplio;
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Cabecera(conFecha: conFecha),
        for (var i = 0; i < filas.length; i++)
          Container(
            decoration: BoxDecoration(
              // Franjas alternadas con el contenedor mas bajo del tema: sigue
              // siendo el color del usuario, en claro y en oscuro.
              color: i.isEven ? null : cs.surfaceContainerLow,
              border: Border(
                bottom: BorderSide(color: cs.outlineVariant, width: 0.5),
              ),
            ),
            child: _Fila(
              fila: filas[i],
              conFecha: conFecha,
              onEditar: () => onEditar(filas[i]),
              onEliminar: () => onEliminar(filas[i]),
            ),
          ),
      ],
    );
  }
}

class _Cabecera extends StatelessWidget {
  const _Cabecera({required this.conFecha});

  final bool conFecha;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final estilo = Theme.of(context).textTheme.labelSmall?.copyWith(
      fontWeight: Peso.titulo,
      color: cs.onSurfaceVariant,
      letterSpacing: 0.4,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Esp.m, vertical: Esp.s),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(Esquina.chica),
        ),
      ),
      child: Row(
        children: [
          Expanded(flex: 5, child: Text('GRUPO DE FAMILIA', style: estilo)),
          Expanded(flex: 3, child: Text('TIPO', style: estilo)),
          Expanded(flex: 3, child: Text('RANGO DE GRAMAJE', style: estilo)),
          if (conFecha)
            Expanded(
              flex: 3,
              child: Text('ÚLTIMA MODIFICACIÓN', style: estilo),
            ),
          SizedBox(
            width: _anchoAcciones,
            child: Text('ACCIONES', style: estilo, textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila({
    required this.fila,
    required this.conFecha,
    required this.onEditar,
    required this.onEliminar,
  });

  final FilaParametroGramaje fila;
  final bool conFecha;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final parametro = fila.parametro;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Esp.m, vertical: Esp.s),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              fila.grupo,
              style: tt.bodyMedium?.copyWith(fontWeight: Peso.titulo),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Etiqueta(texto: fila.tipo),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              parametro.tieneRangoAsignado ? fila.rango : 'Sin rango asignado',
              style: context.numero(fuerte: parametro.tieneRangoAsignado),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (conFecha)
            Expanded(
              flex: 3,
              child: Text(
                parametro.audFechaLegible,
                style: context.apagado(),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          SizedBox(
            width: _anchoAcciones,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: onEditar,
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  tooltip: 'Editar rango',
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  onPressed: onEliminar,
                  icon: const Icon(Icons.delete_outline, size: 20),
                  tooltip: 'Eliminar parámetro',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// La misma fila en un telefono: tarjeta, sin columnas y con las acciones en un
/// menu contextual, que es lo unico que entra sin scroll horizontal.
class _Tarjeta extends StatelessWidget {
  const _Tarjeta({
    required this.fila,
    required this.onEditar,
    required this.onEliminar,
  });

  final FilaParametroGramaje fila;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final parametro = fila.parametro;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEditar,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Esp.l, Esp.m, Esp.s, Esp.m),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fila.grupo,
                      style: tt.bodyLarge?.copyWith(fontWeight: Peso.titulo),
                    ),
                    const SizedBox(height: Esp.s),
                    Wrap(
                      spacing: Esp.s,
                      runSpacing: Esp.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Etiqueta(texto: fila.tipo),
                        Text(
                          parametro.tieneRangoAsignado
                              ? fila.rango
                              : 'Sin rango asignado',
                          style: context.numero(
                            fuerte: parametro.tieneRangoAsignado,
                          ),
                        ),
                      ],
                    ),
                    if (parametro.audFecha != null) ...[
                      const SizedBox(height: Esp.xs),
                      Text(
                        'Modificado el ${parametro.audFechaLegible}',
                        style: context.apagado(),
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<_AccionFila>(
                tooltip: 'Acciones',
                onSelected: (accion) {
                  switch (accion) {
                    case _AccionFila.editar:
                      onEditar();
                    case _AccionFila.eliminar:
                      onEliminar();
                  }
                },
                itemBuilder:
                    (_) => const [
                      PopupMenuItem(
                        value: _AccionFila.editar,
                        child: ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.edit_outlined),
                          title: Text('Editar rango'),
                        ),
                      ),
                      PopupMenuItem(
                        value: _AccionFila.eliminar,
                        child: ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.delete_outline),
                          title: Text('Eliminar'),
                        ),
                      ),
                    ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _AccionFila { editar, eliminar }

/// Los dos botones de accion mas su respiro. Es fijo a proposito: si fuera
/// `Expanded` los iconos se moverian de lugar segun el largo del nombre del
/// grupo, y el ojo los busca siempre en el mismo borde.
const double _anchoAcciones = 96;
