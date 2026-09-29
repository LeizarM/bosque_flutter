import 'package:bosque_flutter/core/state/rol_sabados_provider.dart';
import 'package:bosque_flutter/domain/entities/participante_turno_entity.dart';
import 'package:bosque_flutter/domain/entities/sabado_entity.dart';
import 'package:bosque_flutter/presentation/widgets/rol-sabados/agenda_sabado.dart';
import 'package:bosque_flutter/presentation/widgets/rol-sabados/editor_celda.dart';
import 'package:bosque_flutter/presentation/widgets/rol-sabados/estilo_modulo.dart';
import 'package:bosque_flutter/presentation/widgets/rol-sabados/evento_sheet.dart';
import 'package:bosque_flutter/presentation/widgets/rol-sabados/exportar_sabado.dart';
import 'package:bosque_flutter/presentation/widgets/rol-sabados/filtros_grilla.dart';
import 'package:bosque_flutter/presentation/widgets/rol-sabados/mensajes_usuario.dart';
import 'package:bosque_flutter/presentation/widgets/rol-sabados/puente_sheet.dart';
import 'package:bosque_flutter/presentation/widgets/rol-sabados/rol_sabados_comunes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// La pestaña de la grilla: filtros arriba y, debajo, la matriz o la agenda
/// según el ancho.
///
/// Dos vistas y no una que se encoge: la matriz son 87 personas × 52 sábados y
/// en 360 px quedan 3 columnas. El corte usa el ancho **real del panel**
/// (`LayoutBuilder`, no la pantalla: el dashboard tiene sidebar).
class GrillaTab extends ConsumerWidget {
  const GrillaTab({
    super.key,
    required this.idRol,
    required this.hCuerpo,
    required this.hCabecera,
    required this.vCuerpo,
    required this.vNombres,
  });

  final int idRol;
  final ScrollController hCuerpo;
  final ScrollController hCabecera;
  final ScrollController vCuerpo;
  final ScrollController vNombres;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grilla = ref.watch(grillaRolProvider(idRol));

    return grilla.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (e, _) => MensajeVacio(
            icono: Icons.error_outline,
            titulo: 'No se pudo cargar la grilla',
            detalle: textoParaUsuario(e),
          ),
      data: (g) {
        if (g.participantes.isEmpty || g.sabados.isEmpty) {
          return const MensajeVacio(
            icono: Icons.grid_off,
            titulo: 'El rol está vacío',
            detalle:
                'No tiene participantes o no tiene sábados. Regenéralo para que '
                'se armen las celdas.',
          );
        }

        final sabados = filtrarSabados(g.sabados, ref.watch(filtroMesProvider));
        final personas = filtrarPersonas(
          g.participantes,
          ref.watch(busquedaPersonaProvider),
        );

        return Column(
          children: [
            FiltrosGrilla(grilla: g),
            const Divider(height: 1),
            Expanded(
              child: LayoutBuilder(
                builder: (context, cajon) {
                  if (sabados.isEmpty || personas.isEmpty) {
                    return MensajeVacio(
                      icono: Icons.filter_alt_off_outlined,
                      titulo:
                          sabados.isEmpty
                              ? 'Ese mes no tiene sábados en este rol'
                              : 'Nadie coincide con la búsqueda',
                      detalle:
                          sabados.isEmpty
                              ? 'Elige otro mes o «Todo el año».'
                              : 'Prueba con parte del apellido o el código de '
                                  'empleado.',
                    );
                  }
                  if (Aire.de(cajon.maxWidth).esChico) {
                    return AgendaSabado(
                      grilla: g,
                      sabados: sabados,
                      participantes: personas,
                    );
                  }
                  return Matriz(
                    grilla: g,
                    sabados: sabados,
                    participantes: personas,
                    medidas: MedidasGrilla.para(cajon.maxWidth),
                    anchoDisponible: cajon.maxWidth,
                    hCuerpo: hCuerpo,
                    hCabecera: hCabecera,
                    vCuerpo: vCuerpo,
                    vNombres: vNombres,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

/// La tabla con primera columna y encabezado congelados.
///
/// Los cuatro `ScrollController` vienen **atados entre sí** desde la pantalla.
/// Es `ConsumerWidget` sólo por el permiso de edición: se observa aquí una vez y
/// baja como `bool` (en `CeldaMatriz` serían 4.420 suscripciones).
class Matriz extends ConsumerWidget {
  const Matriz({
    super.key,
    required this.grilla,
    required this.sabados,
    required this.participantes,
    required this.medidas,
    required this.anchoDisponible,
    required this.hCuerpo,
    required this.hCabecera,
    required this.vCuerpo,
    required this.vNombres,
  });

  final GrillaRol grilla;

  /// Ya filtrados por mes y búsqueda. La grilla completa sigue en [grilla]:
  /// cobertura del día y turnos del año se calculan sobre el rol entero.
  final List<SabadoEntity> sabados;
  final List<ParticipanteTurnoEntity> participantes;

  final MedidasGrilla medidas;

  /// Lo que mide el panel: con un mes filtrado (4 o 5 columnas) en un monitor
  /// sobra medio metro de blanco; de aquí sale cuánto puede crecer cada columna.
  final double anchoDisponible;

  final ScrollController hCuerpo;
  final ScrollController hCabecera;
  final ScrollController vCuerpo;
  final ScrollController vNombres;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final g = grilla;
    final m = medidas;
    final permiso = ref.watch(permisoDeCeldaProvider);

    /* Qué se hace con el ancho que sobra. Con un mes filtrado son cuatro o
       cinco columnas: en un monitor de 1900 px la tabla se dibujaba en sus
       medidas mínimas —unos 550 px— y quedaba flotando en el medio con
       setecientos pixeles de blanco a cada lado.

       El sobrante no se reparte parejo: primero se estiran los NOMBRES hasta
       que entren enteros —cortar «BALDERRAMA CRISTHIAN...» es la pérdida más
       cara— y recién después engordan las celdas, hasta el tope de
       `anchoCeldaMax`. El porqué del tope y del orden está en
       `MedidasGrilla.repartir`; aquí alcanza con saber que con «Todo el año»
       —52 columnas— no sobra nada y todo vuelve a los mínimos. */
    final reparto = m.repartir(
      disponible: anchoDisponible,
      columnas: sabados.length,
      idealNombre: anchoParaNombres(
        context,
        participantes,
        minimo: m.anchoNombre,
      ),
    );
    final anchoNombre = reparto.nombre;
    final anchoCelda = reparto.celda;

    final anchoTabla = sabados.length * anchoCelda;
    final anchoTotal = anchoNombre + anchoTabla;

    final tabla = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Encabezado: esquina fija + fechas que scrollean
        SizedBox(
          height: m.altoCabecera,
          child: Row(
            children: [
              _Esquina(ancho: anchoNombre),
              Expanded(
                child: SingleChildScrollView(
                  controller: hCabecera,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: anchoTabla,
                    child: Row(
                      children: [
                        for (final s in sabados)
                          CabeceraSabado(
                            grilla: g,
                            sabado: s,
                            ancho: anchoCelda,
                            cobertura: g.coberturaDe(s.idSabado),
                            objetivo: g.rol.coberturaObjetivo,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Cuerpo: nombres fijos + celdas
        Expanded(
          child: Row(
            children: [
              SizedBox(
                width: anchoNombre,
                child: ListView.builder(
                  controller: vNombres,
                  itemCount: participantes.length,
                  itemExtent: m.altoFila,
                  itemBuilder:
                      (_, i) => FilaNombre(
                        participante: participantes[i],
                        turnos: g.turnosDe(participantes[i].idParticipante),
                        alto: m.altoFila,
                      ),
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: SingleChildScrollView(
                  controller: hCuerpo,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: anchoTabla,
                    child: ListView.builder(
                      controller: vCuerpo,
                      itemCount: participantes.length,
                      itemExtent: m.altoFila,
                      itemBuilder: (_, i) {
                        final p = participantes[i];
                        return Row(
                          children: [
                            for (final s in sabados)
                              CeldaMatriz(
                                grilla: g,
                                participante: p,
                                sabado: s,
                                ancho: anchoCelda,
                                alto: m.altoFila,
                                // Se resuelve por FILA y no por celda: el permiso depende de la persona.
                                puedeEditar: permiso.puedeCon(p.codEmpleado),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    /* Lo que sigue sobrando después del reparto ya no compra legibilidad, así
       que se convierte en margen y se centra la TABLA, no la pantalla. Cinco
       columnas no llenan 1900 px de ninguna manera razonable, y un bloque
       pegado al borde izquierdo con todo el blanco junto a la derecha se lee
       roto, no lleno.

       La leyenda va aparte y a lo ancho: metida adentro del bloque centrado
       quedaba encerrada en el ancho de la tabla y se cortaba a mitad de
       palabra. */
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child:
              anchoTotal < anchoDisponible
                  ? Center(child: SizedBox(width: anchoTotal, child: tabla))
                  : tabla,
        ),
        const Divider(height: 1),
        LeyendaDeEstados(grilla: g),
      ],
    );
  }
}

/// La esquina fija de arriba a la izquierda; mide lo mismo que la columna de
/// nombres, así que sirve para verificarla.
///
/// Dos rótulos abreviados: el «26/26» final necesita título (filtrada por
/// agosto, nada dice que es del año entero). Con «Todo el año» la columna vuelve
/// a 150 px en tablet, así que el texto completo y el criterio del rojo van al
/// tooltip.
class _Esquina extends StatelessWidget {
  const _Esquina({required this.ancho});
  final double ancho;

  /// Para los tests: el ancho de esta caja ES el de la columna de nombres.
  static const claveEsquina = Key('trs-esquina-personal');

  @override
  Widget build(BuildContext context) => Tooltip(
    message:
        'Sáb. año: cuántos sábados trabaja cada persona en todo el año, sobre '
        'su meta del año.\n'
        'Cuenta el año completo, aunque estés viendo un mes solo.\n'
        'En rojo, quien se aparta de su meta por más de un sábado, de más o de '
        'menos.',
    child: Container(
      key: claveEsquina,
      width: ancho,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: Esp.m),
      child: Row(
        children: [
          // Expanded + ellipsis: si el rótulo de la derecha no entra, se corta el título
          // y no se desborda la fila.
          Expanded(
            child: Text(
              'Personal',
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: Peso.titulo),
            ),
          ),
          const SizedBox(width: Esp.s),
          // Apagado y no en negrita: titula una columna de apoyo y no compite con el
          // nombre, que es lo que se escanea.
          Text('Sáb. año', style: context.apagado()),
        ],
      ),
    ),
  );
}

/// Lo que se puede hacer con una columna. Ver [CabeceraSabado].
enum _AccionColumna { exportar, evento, puente }

/// Una columna: el día, el mes y cuánta gente viene.
///
/// **Tocarla abre un menú de dos entradas, por espacio:** la celda (42 a 64 px)
/// ya lleva tres renglones y un ícono de 12 px no sería un objetivo táctil
/// válido. Un menú no paga ancho y, a diferencia de un toque largo, se
/// descubre; sigue vivo con el rol CERRADO (el PDF se sigue necesitando).
class CabeceraSabado extends ConsumerStatefulWidget {
  const CabeceraSabado({
    super.key,
    required this.grilla,
    required this.sabado,
    required this.ancho,
    required this.cobertura,
    required this.objetivo,
  });

  final GrillaRol grilla;
  final SabadoEntity sabado;
  final double ancho;
  final int cobertura;
  final int objetivo;

  @override
  ConsumerState<CabeceraSabado> createState() => _CabeceraSabadoState();
}

class _CabeceraSabadoState extends ConsumerState<CabeceraSabado> {
  /// Mientras el PDF se arma. **Vive aquí y no en el menú**: el menú se cierra al
  /// elegir y el segundo toque encontraría el ítem habilitado (dos PDF del mismo
  /// día).
  bool _ocupado = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = widget.sabado;
    final f = s.fecha;
    final dia = f == null ? '--' : f.day.toString().padLeft(2, '0');

    // El sábado corto es el que hay que mirar: falta gente ese día.
    final corto = widget.objetivo > 0 && widget.cobertura < widget.objetivo;

    // `PopupMenuButton` con `child` es `Tooltip > InkWell > child` sin relleno ni
    // tamaño mínimo, sin mover un pixel de la columna (con `icon` impondría 48 px).
    return PopupMenuButton<_AccionColumna>(
      tooltip: '${_tooltip()}\nToca para exportar el PDF o marcar el evento.',
      onSelected: (a) {
        switch (a) {
          case _AccionColumna.exportar:
            _exportar();
          case _AccionColumna.evento:
            _abrirEvento();
          case _AccionColumna.puente:
            _abrirPuente();
        }
      },
      itemBuilder:
          (_) => [
            PopupMenuItem<_AccionColumna>(
              value: _AccionColumna.exportar,
              enabled: !_ocupado,
              child: _ItemMenu(
                icono: Icons.picture_as_pdf_outlined,
                texto:
                    _ocupado
                        ? 'Generando el PDF…'
                        : 'Exportar el PDF de este sábado',
              ),
            ),
            // Sobre un rol cerrado no se declara nada; la cabecera sigue sirviendo para lo
            // otro.
            if (!widget.grilla.rol.estaCerrado)
              const PopupMenuItem<_AccionColumna>(
                value: _AccionColumna.evento,
                child: _ItemMenu(
                  icono: Icons.event_available_outlined,
                  texto: 'Declarar el evento del día',
                ),
              ),
            // El puente cuelga de aquí y no de un botón propio: es de la misma familia que
            // «declarar el evento» (decisiones sobre ESE día). Quién puede lo decide el
            // servidor con el token; se ofrece igual para que RR.HH. no busque dónde está.
            if (!widget.grilla.rol.estaCerrado)
              const PopupMenuItem<_AccionColumna>(
                value: _AccionColumna.puente,
                child: _ItemMenu(
                  icono: Icons.beach_access_outlined,
                  texto: 'Puente a cuenta de vacación',
                ),
              ),
          ],
      child: Container(
        width: widget.ancho,
        padding: const EdgeInsets.symmetric(vertical: Esp.xs),
        decoration: BoxDecoration(
          color:
              s.esFeriadoBool
                  ? cs.errorContainer.withValues(alpha: 0.45)
                  : s.tieneEvento
                  ? cs.tertiaryContainer.withValues(alpha: 0.45)
                  : null,
          border: Border(
            right: BorderSide(color: cs.outlineVariant, width: .5),
          ),
        ),
        // Tres renglones en 48 px: con el interlineado por defecto (~1.45) se pasan por
        // 4 px; se compacta a 1.1, propio de un dato tabular de una línea.
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(dia, style: context.numero(fuerte: true)),
            Text(
              f == null ? '' : mesCorto(f.month),
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(height: 1.1),
            ),
            // La ruedita ocupa el lugar de la cobertura mientras dura (el menú ya se
            // cerró y sin esto nada indica que algo pasa). Mide 12 px, menos que el
            // renglón que reemplaza, así que la cabecera no crece.
            if (_ocupado)
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Text(
                '${widget.cobertura}',
                style: context.numero(
                  fuerte: corto,
                  color: corto ? cs.error : Theme.of(context).hintColor,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportar() async {
    if (_ocupado) return;
    setState(() => _ocupado = true);
    await exportarSabadoPdf(context: context, ref: ref, sabado: widget.sabado);
    if (mounted) setState(() => _ocupado = false);
  }

  void _abrirEvento() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder:
        (_) => EventoSheet(
          idRol: widget.grilla.rol.idRol,
          sabado: widget.sabado,
          participantes: widget.grilla.participantes,
        ),
  );

  void _abrirPuente() => mostrarPuenteSheet(
    context: context,
    idRol: widget.grilla.rol.idRol,
    sabado: widget.sabado,
  );

  String _tooltip() {
    final s = widget.sabado;
    final partes = <String>[
      fechaCorta(s.fecha),
      'rota el grupo ${s.grupoQueRota}',
      'vienen ${widget.cobertura} de ${widget.objetivo}',
    ];
    if (s.esFeriadoBool) partes.add('FERIADO');
    if (s.tieneEvento) {
      partes.add(
        'evento ${s.alcanceEvento}'
        '${s.motivoEspecial.isEmpty ? '' : ': ${s.motivoEspecial}'}',
      );
    }
    return partes.join(' · ');
  }
}

/// Una línea del menú de la cabecera: ícono y texto.
class _ItemMenu extends StatelessWidget {
  const _ItemMenu({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      // El color sale del estilo del propio `PopupMenuItem`, que sabe si está
      // deshabilitado; si no, el ícono queda a full color junto a un texto gris y
      // el ítem parece apretable mientras el PDF se genera.
      Icon(icono, size: 18, color: DefaultTextStyle.of(context).style.color),
      const SizedBox(width: Esp.m),
      // **Flexible y no `Text` suelto:** el menú de Material se dibuja en pasos fijos
      // de ancho (aquí 256 px) y «Exportar el PDF de este sábado» con el ícono
      // desbordaba de verdad (lo detectó el test); así se parte en dos sin perder texto.
      Flexible(child: Text(texto)),
    ],
  );
}

/// Una fila de la columna congelada: grupo, nombre y turnos contra la meta.
class FilaNombre extends StatelessWidget {
  const FilaNombre({
    super.key,
    required this.participante,
    required this.turnos,
    required this.alto,
  });

  final ParticipanteTurnoEntity participante;
  final int turnos;
  final double alto;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final meta = participante.turnosObjetivo;
    // Una diferencia de 1 es normal si el año tiene 53 sábados; de 2 en adelante
    // hay un desequilibrio que mirar.
    final desviado = meta > 0 && (turnos - meta).abs() > 1;

    // Para qué lado y por cuánto: sin esto el rojo es una alarma sin causa (con
    // 28/26, que también se pinta, la lectura intuitiva sería la contraria).
    // `desviado` exige más de 1, así que aquí la diferencia es 2 o más y el plural
    // siempre cae bien.
    final diferencia = turnos - meta;

    // **La sucursal va al tooltip (decisión):** `anchoParaNombres` pide 18 (insignia)
    // + 8 + apellido MEDIDO + 8 + 46 (contador) + 24, ni un pixel de sobra. Con
    // «Todo el año» la columna vuelve a su mínimo de 210 px y al nombre le quedan
    // 106 (104 tomados): «BALDERRAMA CRISTHIAN ALEJANDRO» ya se corta. Un segundo
    // renglón duplicaría la fila de 34 px (87 filas) y esta vista responde «¿cómo
    // quedó el año?», no «¿de dónde es?» (eso lo contesta el hover).

    // El contador se escribe con la misma función que «Grupos» (mismo número, misma
    // lectura). El tooltip es el único lugar donde el «26/26» se explica entero,
    // con una línea sobre qué significa el color, o su ausencia.
    return Tooltip(
      message: [
        participante.nombreRol,
        if (participante.puesto.isNotEmpty) participante.puesto,
        'Grupo ${participante.grupoRotacion}',
        sabadosDelAnio(turnos: turnos, meta: meta),
        if (desviado)
          diferencia < 0
              ? 'Le faltan ${-diferencia} para su meta: por eso el número va '
                  'en rojo'
              : 'Trabaja $diferencia de más que su meta: por eso el número va '
                  'en rojo'
        else if (meta > 0)
          'Dentro de su meta: hasta 1 sábado de diferencia no se marca',
      ].join('\n'),
      child: Container(
        height: alto,
        padding: const EdgeInsets.symmetric(horizontal: Esp.m),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: cs.outlineVariant, width: .5),
          ),
        ),
        child: Row(
          children: [
            InsigniaGrupo(grupo: participante.grupoRotacion),
            const SizedBox(width: Esp.s),
            Expanded(
              child: Text(
                participante.nombreRol,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            Text(
              meta > 0 ? '$turnos/$meta' : '$turnos',
              style: context.numero(
                fuerte: desviado,
                color: desviado ? cs.error : Theme.of(context).hintColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Un cruce persona × sábado. Sin celda, esa persona está LIBRE y el cuadrito
/// va vacío: ese vacío es un dato, no un «todavía no cargó».
class CeldaMatriz extends StatelessWidget {
  const CeldaMatriz({
    super.key,
    required this.grilla,
    required this.participante,
    required this.sabado,
    required this.ancho,
    required this.alto,
    this.puedeEditar = true,
  });

  final GrillaRol grilla;
  final ParticipanteTurnoEntity participante;
  final SabadoEntity sabado;
  final double ancho;
  final double alto;

  /// Si esta persona está dentro de lo que el usuario puede tocar. Lo resuelve
  /// [Matriz] una vez por fila; aquí sólo se obedece.
  final bool puedeEditar;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final celda = grilla.celda(participante.idParticipante, sabado.idSabado);

    final cuadro = InkWell(
      // Sin permiso la celda queda muerta, como con el rol cerrado. El servidor
      // rechaza igual (error 29 de p_abm_trs_Asignacion); esto evita abrir la hoja,
      // elegir una letra y enterarse recién ahí.
      onTap:
          (grilla.rol.estaCerrado || !puedeEditar)
              ? null
              : () => mostrarEditorDeCelda(
                context: context,
                grilla: grilla,
                participante: participante,
                sabado: sabado,
                celda: celda,
              ),
      child: Container(
        width: ancho,
        height: alto,
        decoration: BoxDecoration(
          color: fondoDeCelda(context, celda),
          border: Border(
            right: BorderSide(color: cs.outlineVariant, width: .5),
            bottom: BorderSide(color: cs.outlineVariant, width: .5),
          ),
        ),
        // Sin `alignment` en el Container: con él, el hijo recibe restricciones sueltas
        // y el Stack se encoge a la letra (el punto terminaba sobre el glifo). Así el
        // Stack ocupa la celda entera y la esquinita cae donde no hay nada.
        child: Stack(
          children: [
            Center(child: LetraDeCelda(celda: celda)),
            if (celda?.esIntervencion == true)
              Positioned(
                top: 0,
                right: 0,
                child: MarcaDeIntervencion(color: cs.primary),
              ),
            // Esquina opuesta a la de intervención: una celda de cambio lleva las dos marcas
            // siempre (la escribe trs_sp_corregirCelda).
            if (celda?.hayCambio == true)
              Positioned(
                bottom: 0,
                left: 0,
                child: MarcaDeCambio(color: cs.tertiary),
              ),
          ],
        ),
      ),
    );

    // El `Tooltip` sólo se construye si hay algo que decir (envolver las 4.420
    // celdas es pagar el árbol entero); es para el mouse, porque en teléfono no se
    // dibuja la grilla. Muestra `observacion` (`trs_sp_corregirCelda`, origen='M')
    // para que RR.HH. vea POR QUÉ quedó excusada una celda sin abrir el editor.
    final texto = [
      if (celda?.hayCambio == true) celda!.cambioTexto,
      if ((celda?.observacion ?? '').isNotEmpty) celda!.observacion,
    ].join('\n');
    if (texto.isEmpty) return cuadro;
    return Tooltip(message: texto, child: cuadro);
  }
}

/// Qué significa cada letra, con su color. Incluye el vacío, el estado más
/// frecuente y el único sin letra.
class LeyendaDeEstados extends StatelessWidget {
  const LeyendaDeEstados({super.key, required this.grilla});
  final GrillaRol grilla;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final estados =
        grilla.estados.values.where((e) => e.estado == 'A').toList()
          ..sort((a, b) => a.codigoExcel.compareTo(b.codigoExcel));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Esp.l, vertical: Esp.s),
        child: Row(
          children: [
            for (final e in estados) ...[
              Container(
                width: 16,
                height: 16,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colorDeEstado(cs, e.codigoExcel).fondo,
                  borderRadius: BorderRadius.circular(Esp.xs),
                  border: Border.all(color: cs.outlineVariant),
                ),
                // La letra dentro de su color, igual que la grilla: se aprende mirando una sola
                // cosa.
                child: Text(
                  e.codigoExcel,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 9,
                    fontWeight: Peso.dato,
                    color: colorDeEstado(cs, e.codigoExcel).texto,
                  ),
                ),
              ),
              const SizedBox(width: Esp.xs),
              Text(e.nombre, style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(width: Esp.l),
            ],
            Text(
              'vacío = libre',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(width: Esp.l),
            // La esquinita es una convención más: sin explicarla parece un defecto.
            SizedBox(
              width: 16,
              height: 16,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(Esp.xs),
                      border: Border.all(color: cs.outlineVariant),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: MarcaDeIntervencion(color: cs.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Esp.xs),
            Text(
              'la escribió alguien: regenerar no la pisa',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(width: Esp.l),
            // La segunda esquinita: las dos aparecen JUNTAS en toda celda de cambio (una
            // arriba y otra abajo); sin esta entrada la otra explica sólo la mitad.
            SizedBox(
              width: 16,
              height: 16,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(Esp.xs),
                      border: Border.all(color: cs.outlineVariant),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: MarcaDeCambio(color: cs.tertiary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Esp.xs),
            Text(
              'hubo un cambio: toca la celda para ver con quién',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}
