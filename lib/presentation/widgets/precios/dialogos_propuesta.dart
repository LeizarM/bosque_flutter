/// Los diálogos del circuito de autorización de precios: cuatro confirmaciones
/// y la puerta al detalle. Van juntos por el encabezado común (la propuesta de
/// la que se habla) y para que digan lo mismo con el mismo tono.
///
/// Aprobar lleva diálogo propio y no el [confirmar] compartido: es la escritura
/// más sensible (los precios propuestos pasan a ser los de venta vigentes de
/// toda la empresa y la app no puede revertirlo), así que además de los dos
/// botones pide una casilla explícita que frene al apurado.
library;

import 'package:flutter/material.dart';

import 'package:bosque_flutter/presentation/widgets/precios/ancho_dialogo.dart';
import 'package:bosque_flutter/presentation/widgets/precios/generacion_propuesta.dart';
import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/presentation/widgets/precios/propuesta_en_autorizacion.dart';
import 'package:bosque_flutter/presentation/widgets/precios/vista_preliminar_propuesta.dart';

// Confirmaciones

/// Aprobar: el dialogo que dice, sin rodeos, que cambia en la empresa.
///
/// Devuelve true solo si la persona marco la casilla y toco Aprobar.
Future<bool> confirmarAprobacion(
  BuildContext context,
  PropuestaEnAutorizacion fila,
) async {
  final r = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _DialogoAprobar(fila: fila),
  );
  return r ?? false;
}

/// Rechazar. Tambien cierra el circuito —la propuesta queda No Aprobada— pero
/// no toca ningun precio, asi que alcanza con la confirmacion compartida.
Future<bool> confirmarRechazo(
  BuildContext context,
  PropuestaEnAutorizacion fila,
) => confirmar(
  context,
  titulo: 'Rechazar la propuesta ${fila.numero}',
  detalle:
      '«${fila.titulo}», propuesta por ${_persona(fila.propuestoPor)}.\n\n'
      'Queda como No Aprobada y ningún precio de venta cambia. '
      'Quien la propuso tendrá que armar una nueva para volver a intentarlo.',
  textoConfirmar: 'Rechazar',
  destructiva: true,
);

/// Mandar a autorizar. Es el paso que saca la propuesta de las manos de quien
/// la armo, por eso se confirma aunque no sea destructivo.
Future<bool> confirmarEnviarAEspera(
  BuildContext context,
  PropuestaEnAutorizacion fila,
) => confirmar(
  context,
  titulo: 'Enviar a autorizar la propuesta ${fila.numero}',
  detalle:
      '«${fila.titulo}» pasa al estado En Espera y queda a la vista de '
      'quien autoriza.\n\n'
      'Mientras esté En Espera no se puede seguir editando.',
  textoConfirmar: 'Enviar a autorizar',
);

/// Generar: baja el archivo para SAP y deja constancia de quien lo genero.
/// Si ya se habia generado lo dice: se puede volver a generar, como en el
/// sistema anterior, pero la constancia pasa a ser la de esta vez.
Future<bool> confirmarGeneracion(
  BuildContext context,
  PropuestaEnAutorizacion fila,
) {
  final yaGenerada =
      fila.propuesta.fueGenerada || fila.generadoPor.trim().isNotEmpty;
  final antes =
      yaGenerada
          ? '\n\nYa la generó ${_persona(fila.generadoPor)} el '
              '${fila.fechaGeneracion}: esta generación reemplaza esa '
              'constancia.'
          : '';
  return confirmar(
    context,
    titulo: 'Generar la propuesta ${fila.numero}',
    detalle:
        'Se descarga el archivo ${nombreArchivoGeneracion(fila)} con el '
        'precio unitario de cada artículo en cada lista de precios de SAP, '
        'para cargarlo en las empresas.\n\n'
        '«${fila.titulo}» queda registrada como generada, con su nombre y la '
        'fecha de hoy. No vuelve a calcular ningún precio.$antes',
    textoConfirmar: 'Generar y descargar',
  );
}

String _persona(String nombre) =>
    nombre.trim().isEmpty ? 'un usuario que ya no figura' : nombre.trim();

// Aprobar

class _DialogoAprobar extends StatefulWidget {
  const _DialogoAprobar({required this.fila});

  final PropuestaEnAutorizacion fila;

  @override
  State<_DialogoAprobar> createState() => _DialogoAprobarState();
}

class _DialogoAprobarState extends State<_DialogoAprobar> {
  bool _entendido = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fila = widget.fila;
    // Por articulo no cambia ningun precio: los articulos toman el vigente de
    // su familia y la aprobacion solo lo deja registrado (tpr_bitArticulo).
    final porArticulo = fila.propuesta.tipo == 2;

    return AlertDialog(
      icon: Icon(Icons.gavel_outlined, color: cs.primary),
      title: Text('Aprobar la propuesta ${fila.numero}'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: anchoDialogo(context, 460),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '«${fila.titulo}»',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: Peso.titulo),
              ),
              SizedBox(height: Esp.xs),
              Text(
                '${fila.etiquetaTipo} · propuesta por '
                '${_persona(fila.propuestoPor)} el ${fila.fechaPropuesta}',
                style: context.apagado(),
              ),
              SizedBox(height: Esp.l),
              NotaDelDato(
                tono: TonoNota.aviso,
                texto:
                    porArticulo
                        ? 'Al aprobar, los artículos de esta propuesta quedan '
                            'registrados con los precios vigentes de su familia, '
                            'listos para generarse y cargarse en SAP. No cambia '
                            'ningún precio de venta.'
                        : 'Al aprobar, los precios propuestos pasan a ser los '
                            'precios de venta vigentes de toda la empresa: todas '
                            'las sucursales y todas las listas de precios '
                            'afectadas por esta propuesta. El cambio es inmediato '
                            'y no se deshace desde el sistema.',
              ),
              SizedBox(height: Esp.m),
              Text(
                porArticulo
                    ? 'Antes de aprobar conviene abrir «Ver» y revisar los '
                        'artículos con el precio que van a tomar.'
                    : 'Antes de aprobar conviene abrir «Ver» y revisar los '
                        'artículos afectados con su precio nuevo.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              SizedBox(height: Esp.s),
              // La casilla es el freno: no pide escribir (eso lo vuelve trámite y se copia y
              // pega) pero sí obliga a un segundo gesto consciente.
              CheckboxListTile(
                value: _entendido,
                onChanged: (v) => setState(() => _entendido = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  porArticulo
                      ? 'Entiendo que los artículos quedan con los precios de '
                          'su familia'
                      : 'Entiendo que esto cambia los precios de venta vigentes',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _entendido ? () => Navigator.pop(context, true) : null,
          icon: const Icon(Icons.check_circle_outline, size: 18),
          label: const Text('Aprobar'),
        ),
      ],
    );
  }
}

// Detalle de la propuesta

/// Abre el detalle de una propuesta: su cabecera y los artículos afectados con el
/// precio ya calculado por unidad, en una matriz artículo x lista (ver
/// [VistaPreliminarPropuesta]). Une los tres diálogos del sistema anterior.
///
/// [preliminar] es la versión del botón "Editar" (propuesta en armado, con el
/// atajo para mandarla a autorizar); [onEnviarAEspera] la cierra antes de
/// ejecutar la acción.
Future<void> abrirDetallePropuesta(
  BuildContext context, {
  required PropuestaEnAutorizacion fila,
  bool preliminar = false,
  VoidCallback? onEnviarAEspera,
}) => showDialog<void>(
  context: context,
  builder:
      (_) => VistaPreliminarPropuesta(
        fila: fila,
        preliminar: preliminar,
        onEnviarAEspera: onEnviarAEspera,
      ),
);
