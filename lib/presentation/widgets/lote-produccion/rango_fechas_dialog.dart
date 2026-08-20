/// El rango de fechas que piden los reportes de resumen.
///
/// Los dos reportes entre fechas —produccion y resmado— piden lo mismo, asi
/// que el dialogo es uno solo y quien lo abre dice para que reporte es.
library;

import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:flutter/material.dart';

/// Pide un rango y lo devuelve, o null si se cancela.
///
/// Sin [desde] y [hasta] arranca en el mes en curso, que es el recorte que se
/// pide casi siempre.
Future<({DateTime desde, DateTime hasta})?> pedirRangoDeFechas(
  BuildContext context, {
  required String titulo,
  required String explicacion,
  DateTime? desde,
  DateTime? hasta,
  String textoAceptar = 'Generar reporte',
  IconData iconoAceptar = Icons.picture_as_pdf_outlined,
}) {
  return showDialog<({DateTime desde, DateTime hasta})>(
    context: context,
    builder: (_) => _RangoFechasDialog(
      titulo: titulo,
      explicacion: explicacion,
      desde: desde,
      hasta: hasta,
      textoAceptar: textoAceptar,
      iconoAceptar: iconoAceptar,
    ),
  );
}

class _RangoFechasDialog extends StatefulWidget {
  const _RangoFechasDialog({
    required this.titulo,
    required this.explicacion,
    required this.desde,
    required this.hasta,
    required this.textoAceptar,
    required this.iconoAceptar,
  });

  final String titulo;
  final String explicacion;
  final DateTime? desde;
  final DateTime? hasta;
  final String textoAceptar;
  final IconData iconoAceptar;

  @override
  State<_RangoFechasDialog> createState() => _RangoFechasDialogState();
}

class _RangoFechasDialogState extends State<_RangoFechasDialog> {
  late DateTime _desde;
  late DateTime _hasta;

  @override
  void initState() {
    super.initState();
    final hoy = DateTime.now();
    _desde = widget.desde ?? DateTime(hoy.year, hoy.month, 1);
    _hasta = widget.hasta ?? hoy;
  }

  Future<void> _elegir({required bool esDesde}) async {
    final hoy = DateTime.now();
    final elegida = await showDatePicker(
      context: context,
      initialDate: esDesde ? _desde : _hasta,
      firstDate: DateTime(hoy.year - 5),
      lastDate: DateTime(hoy.year + 1, 12, 31),
      helpText: esDesde ? 'Fecha inicial' : 'Fecha final',
    );
    if (elegida == null) return;
    setState(() {
      if (esDesde) {
        _desde = elegida;
        if (_hasta.isBefore(_desde)) _hasta = _desde;
      } else {
        _hasta = elegida;
        if (_desde.isAfter(_hasta)) _desde = _hasta;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.titulo),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.explicacion, style: context.apagado()),
            SizedBox(height: Esp.l),
            Row(
              children: [
                Expanded(
                  child: _CampoFecha(
                    etiqueta: 'Desde',
                    fecha: _desde,
                    onTap: () => _elegir(esDesde: true),
                  ),
                ),
                SizedBox(width: Esp.m),
                Expanded(
                  child: _CampoFecha(
                    etiqueta: 'Hasta',
                    fecha: _hasta,
                    onTap: () => _elegir(esDesde: false),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: () =>
              Navigator.pop(context, (desde: _desde, hasta: _hasta)),
          icon: Icon(widget.iconoAceptar, size: 18),
          label: Text(widget.textoAceptar),
        ),
      ],
    );
  }
}

class _CampoFecha extends StatelessWidget {
  const _CampoFecha({
    required this.etiqueta,
    required this.fecha,
    required this.onTap,
  });

  final String etiqueta;
  final DateTime fecha;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(Esquina.chica),
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: etiqueta,
        border: const OutlineInputBorder(),
        isDense: true,
        suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
      ),
      child: Text(fechaCorta(fecha), style: context.numero(fuerte: true)),
    ),
  );
}
