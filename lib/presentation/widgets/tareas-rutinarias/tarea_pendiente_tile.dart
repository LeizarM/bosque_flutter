// Destino final: lib/presentation/widgets/tareas-rutinarias/tarea_pendiente_tile.dart
import 'package:bosque_flutter/core/theme/tareas_colors.dart';
import 'package:bosque_flutter/core/utils/formatear_fecha.dart';
import 'package:bosque_flutter/domain/entities/bit_tarea_ruti_entity.dart';
import 'package:bosque_flutter/presentation/widgets/tareas-rutinarias/franja_acento.dart';
import 'package:bosque_flutter/presentation/widgets/tareas-rutinarias/pagina_tareas.dart';
import 'package:flutter/material.dart';

/// Una tarea rutinaria en la lista "Mis tareas rutinarias".
///
/// Hay dos clases de tarea y la tarjeta se comporta distinto en cada una,
/// porque el trabajo que piden es distinto:
///
///  * **Especiales** (`idATR` 2..11 — arqueo, caja chica, coches…): abren una
///    pantalla propia. La tarjeta es un enlace: ícono del flujo, nombre y
///    chevron.
///  * **Simples** (la enorme mayoría): la única respuesta posible es Sí / No /
///    No aplica. Antes eso costaba abrir un diálogo modal, elegir, esperar el
///    cierre y el toast — por tarea. Con 30 tareas vencidas eso son 30 modales
///    (Marcelo, 2026-09-07: "es muy lento para marcar"). Ahora los tres
///    botones viven EN la tarjeta: una sola pulsación, sin modal.
///
/// El título va a dos líneas a propósito. A una sola, con tres columnas en
/// pantalla, las descripciones reales del catálogo se cortaban todas alrededor
/// del carácter 35 y quedaban varias tarjetas idénticas ("Supervisar, y
/// proporcionar ma…" dos veces seguidas): el texto dejaba de identificar la
/// tarea, que es lo único que la tarjeta tiene que hacer.
class TareaPendienteTile extends StatelessWidget {
  final BitTareaRutiEntity tarea;

  /// Abrir el flujo especial. Solo se usa en tareas con [_tipoDeAccion].
  final VoidCallback onTap;

  /// Responder una tarea simple. Recibe el valor de `fueRealizado`:
  /// 13 = Sí, 0 = No, 14 = No aplica (los mismos que ya usaba el diálogo).
  /// `null` deja la tarjeta en modo solo lectura.
  final void Function(int fueRealizado)? onMarcar;

  /// Mientras el guardado viaja: los tres botones quedan inertes para que dos
  /// pulsaciones rápidas no manden dos escrituras de la misma tarea.
  final bool guardando;

  /// Densidad de escritorio. En un monitor la tarjeta pensada para el pulgar
  /// entra tres veces a lo ancho pero solo cinco a lo alto: se ve una lista de
  /// teléfono agrandada. En compacto se recorta el aire —no el contenido— y
  /// entran alrededor de un 40% más de tareas sin scrollear.
  final bool compacta;

  const TareaPendienteTile({
    super.key,
    required this.tarea,
    required this.onTap,
    this.onMarcar,
    this.guardando = false,
    this.compacta = false,
  });

  /// null cuando la tarea no tiene un flujo especial — el caso más común
  /// (respuesta simple Sí/No/No aplica).
  ///
  /// Estático y público porque la vista de tabla de "Mis tareas rutinarias"
  /// necesita la misma respuesta: si la tarea abre una pantalla propia, la
  /// fila muestra un botón "Abrir" en vez de los tres de Sí/No/No aplica.
  /// Duplicar este switch garantizaba que un día una pantalla conociera un
  /// idATR que la otra no.
  static ({IconData icono, String etiqueta})? tipoDeAccion(int? idATR) {
    switch (idATR) {
      case 2:
        return (icono: Icons.point_of_sale, etiqueta: 'Arqueo de caja');
      case 3:
        return (
          icono: Icons.fact_check_outlined,
          etiqueta: 'Cierre de operaciones',
        );
      case 4:
        return (icono: Icons.lock_outlined, etiqueta: 'Kardex caja fuerte');
      case 5:
        return (
          icono: Icons.rule_folder_outlined,
          etiqueta: 'Verificar cierre',
        );
      case 6:
        return (
          icono: Icons.directions_car_filled_outlined,
          etiqueta: 'Registrar coches',
        );
      case 7:
        return (icono: Icons.savings_outlined, etiqueta: 'Caja chica');
      case 11:
        // TesBase (tesoreria), no tac_traspasoMovCaja: la de Caja AXA es el 12.
        // Pantalla propia desde el archivo SQL 56.
        return (
          icono: Icons.currency_exchange,
          etiqueta: 'Traspaso de efectivo',
        );
      case 12:
        return (
          icono: Icons.compare_arrows,
          etiqueta: 'Traspaso Caja AXA',
        );
      default:
        return null;
    }
  }

  /// Nombre de la frecuencia. Los ids salen de `tac_frecuencia` (verificado
  /// contra la tabla real): 1 Mensual, 2 Semanal, 3 Anual, 4 Bimestral —
  /// dada de baja, `estado=0`, pero puede quedar en filas viejas—, 5
  /// Semestral, 6 Diario.
  /// Público a propósito: "Mis tareas rutinarias" arma con esto los chips
  /// del filtro por frecuencia. Si cada pantalla tuviera su copia, un día la
  /// píldora diría "Bimestral" y el filtro otra cosa.
  static const nombreFrecuencia = {
    1: 'Mensual',
    2: 'Semanal',
    3: 'Anual',
    4: 'Bimestral',
    5: 'Semestral',
    6: 'Diario',
  };

  /// Estado visible de la ocurrencia.
  ///
  /// Los cuatro valores de `fueRealizado` que escribe esta pantalla:
  /// 12 (o null) pendiente, 13 sí, 0 no, 14 no aplica. `0` importa: el
  /// diálogo viejo guardaba "No" como 0, así que una tarea respondida que no
  /// se hizo NO es lo mismo que una sin responder, aunque durante un tiempo
  /// el filtro las mezcló.
  ({Color fondo, Color texto, String etiqueta, bool respondida}) _estado(
    BuildContext context,
  ) {
    switch (tarea.fueRealizado) {
      case 13:
        return (
          fondo: TareasColors.realizado(context),
          texto: TareasColors.realizadoTexto(context),
          etiqueta: 'Realizada',
          respondida: true,
        );
      case 14:
        return (
          fondo: TareasColors.noAplica(context),
          texto: TareasColors.noAplicaTexto(context),
          etiqueta: 'No aplica',
          respondida: true,
        );
      case 0:
        return (
          fondo: TareasColors.vencido(context),
          texto: TareasColors.vencidoTexto(context),
          etiqueta: 'No se hizo',
          respondida: true,
        );
      default:
        // El criterio de "vencida" ya no vive aquí. Lo calcula la base
        // (fn_tac_fechaLimite, archivo SQL 65) y lo resuelve la entidad en un
        // solo lugar: antes estaba copiado en tres, cada copia con un
        // comentario avisando que tenían que quedar idénticas.
        final vencida = tarea.fueraDePlazo(DateTime.now());
        return vencida
            ? (
              fondo: TareasColors.vencido(context),
              texto: TareasColors.vencidoTexto(context),
              etiqueta: 'Vencida',
              respondida: false,
            )
            : (
              fondo: TareasColors.pendiente(context),
              texto: TareasColors.pendienteTexto(context),
              etiqueta: 'Pendiente',
              respondida: false,
            );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tipo = tipoDeAccion(tarea.idATR);
    final estado = _estado(context);
    final esEspecial = tipo != null;
    final puedeMarcar = !esEspecial && onMarcar != null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      // Franja de estado: lo primero que el ojo agarra bajando por la lista.
      // Vía FranjaAcento y no IntrinsicHeight — ver el doc de ese widget.
      child: FranjaAcento(
        color: estado.texto,
        child: InkWell(
          // Solo las especiales navegan. En una tarea simple el tap en la
          // tarjeta no hace nada: la acción está en los tres botones, y un
          // InkWell que abre un modal era justamente lo lento.
          onTap: esEspecial ? onTap : null,
          child: Padding(
            padding:
                compacta
                    ? const EdgeInsets.fromLTRB(12, 8, 8, 8)
                    : const EdgeInsets.fromLTRB(14, 12, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (esEspecial) ...[
                      Container(
                        width: compacta ? 30 : 38,
                        height: compacta ? 30 : 38,
                        alignment: Alignment.center,
                        // El tono del tipo de tarea: el mismo que encabeza la
                        // pantalla a la que lleva esta tarjeta.
                        decoration: BoxDecoration(
                          color: TareasColors.tipoTarea(context, tarea.idATR),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          tipo.icono,
                          color: TareasColors.tipoTareaTexto(
                            context,
                            tarea.idATR,
                          ),
                          size: 20,
                        ),
                      ),
                      SizedBox(width: compacta ? 9 : 12),
                    ],
                    Expanded(
                      child: Text(
                        tarea.nombreTareaRutinaria ?? 'Tarea rutinaria',
                        maxLines: compacta ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                          decoration:
                              tarea.fueRealizado == 13
                                  ? TextDecoration.lineThrough
                                  : null,
                          decorationColor: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    if (esEspecial)
                      Icon(Icons.chevron_right, color: scheme.outline),
                  ],
                ),
                SizedBox(height: compacta ? 6 : 8),
                // Metadatos: fecha, frecuencia y —solo si ya fue respondida—
                // la respuesta. Mientras está pendiente la respuesta no se
                // muestra como píldora: el encabezado del grupo ("Vencidas
                // (30)") ya lo dice y repetirlo en las 30 tarjetas era la
                // misma palabra treinta veces, sin distinguir ninguna.
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (tarea.fechaPresentacion != null)
                      _Meta(
                        icono: Icons.event_outlined,
                        texto: FormatearFecha.formatearFecha(
                          tarea.fechaPresentacion!,
                        ),
                      ),
                    if (nombreFrecuencia[tarea.idFrec] != null)
                      PildoraTareas.frecuencia(
                        context,
                        tarea.idFrec!,
                        nombreFrecuencia[tarea.idFrec]!,
                      ),
                    if (esEspecial)
                      _Meta(
                        icono: Icons.category_outlined,
                        texto: tipo.etiqueta,
                      ),
                    if (estado.respondida)
                      PildoraTareas(
                        texto: estado.etiqueta,
                        fondo: estado.fondo,
                        color: estado.texto,
                      ),
                  ],
                ),
                if (puedeMarcar) ...[
                  SizedBox(height: compacta ? 8 : 10),
                  RespuestaTarea(
                    seleccion: tarea.fueRealizado,
                    habilitado: !guardando,
                    onElegir: onMarcar!,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Ícono + texto chico, para un dato de contexto que no es accionable.
class _Meta extends StatelessWidget {
  final IconData icono;
  final String texto;

  const _Meta({required this.icono, required this.texto});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 13, color: color),
        const SizedBox(width: 4),
        Text(
          texto,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
        ),
      ],
    );
  }
}

/// Los tres botones de respuesta, en la tarjeta.
///
/// Reemplaza el `AlertDialog` que había que abrir y cerrar por cada tarea. Se
/// muestran siempre (no aparecen al hacer hover) porque en una lista de 30 la
/// pregunta es la misma en todas y esconder la acción obliga a descubrirla
/// tarjeta por tarjeta.
///
/// El botón ya elegido queda relleno: la tarjeta sigue mostrando qué se
/// respondió y permite corregirlo con una sola pulsación, sin volver a abrir
/// nada.
/// Los tres botones de respuesta (Sí / No / No aplica).
///
/// Pública porque la vista de tabla de "Mis tareas rutinarias" usa exactamente
/// los mismos: los valores 13/0/14 y su aspecto tienen que ser idénticos en las
/// dos vistas o la misma tarea se respondería distinto según el ancho de la
/// ventana.
class RespuestaTarea extends StatelessWidget {
  final int? seleccion;
  final bool habilitado;
  final void Function(int) onElegir;

  const RespuestaTarea({
    super.key,
    required this.seleccion,
    required this.habilitado,
    required this.onElegir,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget boton(int valor, String etiqueta, IconData icono, Color tono) =>
        BotonRespuestaTareas(
          etiqueta: etiqueta,
          icono: icono,
          tono: tono,
          elegido: seleccion == valor,
          onPressed: habilitado ? () => onElegir(valor) : null,
        );

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        boton(
          13,
          'Sí',
          Icons.check_rounded,
          TareasColors.realizadoTexto(context),
        ),
        boton(0, 'No', Icons.close_rounded, TareasColors.vencidoTexto(context)),
        boton(14, 'No aplica', Icons.remove_rounded, scheme.onSurfaceVariant),
      ],
    );
  }
}
