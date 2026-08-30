/// El rango de fechas que piden los reportes y los filtros entre fechas.
///
/// Vivía en `widgets/lote-produccion/` porque nació ahí, pero lo usan tres
/// módulos —producción, solicitud de corte y talonarios— así que se mudó a
/// `core/ui/`. Importar un widget de otro módulo funciona, pero deja la
/// dependencia escondida en un import y no en la carpeta.
///
/// **Por qué no `showDateRangePicker`.** El de Material se abre a pantalla
/// completa y despliega los meses uno abajo del otro: en un monitor ancho son
/// 1900 px para elegir dos fechas, con el resto de la pantalla vacío y sin
/// contexto de lo que se estaba filtrando. Acá son dos campos en un diálogo de
/// 380 px.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:bosque_flutter/core/ui/tokens_bosque.dart';

final DateFormat _formatoFecha = DateFormat('dd/MM/yyyy');

/// Pide un rango y lo devuelve, o null si se cancela.
///
/// Sin [desde] y [hasta] arranca en el mes en curso, que es el recorte que se
/// pide casi siempre.
///
/// [minima] y [maxima] acotan el calendario. Por defecto van cinco años atrás
/// y uno adelante; talonarios los corre a 2019 porque ahí empiezan sus datos y
/// con el default no se podía llegar.
Future<({DateTime desde, DateTime hasta})?> pedirRangoDeFechas(
  BuildContext context, {
  required String titulo,
  required String explicacion,
  DateTime? desde,
  DateTime? hasta,
  String textoAceptar = 'Generar reporte',
  IconData iconoAceptar = Icons.picture_as_pdf_outlined,
  DateTime? minima,
  DateTime? maxima,
}) {
  return showDialog<({DateTime desde, DateTime hasta})>(
    context: context,
    builder:
        (_) => _RangoFechasDialog(
          titulo: titulo,
          explicacion: explicacion,
          desde: desde,
          hasta: hasta,
          textoAceptar: textoAceptar,
          iconoAceptar: iconoAceptar,
          minima: minima,
          maxima: maxima,
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
    required this.minima,
    required this.maxima,
  });

  final String titulo;
  final String explicacion;
  final DateTime? desde;
  final DateTime? hasta;
  final String textoAceptar;
  final IconData iconoAceptar;
  final DateTime? minima;
  final DateTime? maxima;

  @override
  State<_RangoFechasDialog> createState() => _RangoFechasDialogState();
}

class _RangoFechasDialogState extends State<_RangoFechasDialog> {
  late DateTime _desde;
  late DateTime _hasta;
  late DateTime _minima;
  late DateTime _maxima;

  /// Lo que se está tipeando y todavía no es una fecha válida. Mientras haya
  /// algo acá, Aplicar queda bloqueado: aceptar con un campo a medio escribir
  /// guardaría la última fecha buena y no la que la persona ve.
  String? _errorDesde;
  String? _errorHasta;

  @override
  void initState() {
    super.initState();
    final hoy = DateTime.now();
    _minima = widget.minima ?? DateTime(hoy.year - 5);
    _maxima = widget.maxima ?? DateTime(hoy.year + 1, 12, 31);
    _desde = widget.desde ?? DateTime(hoy.year, hoy.month, 1);
    _hasta = widget.hasta ?? hoy;
  }

  Future<void> _elegirEnCalendario({required bool esDesde}) async {
    final elegida = await showDatePicker(
      context: context,
      initialDate: _acotada(esDesde ? _desde : _hasta),
      firstDate: _minima,
      lastDate: _maxima,
      helpText: esDesde ? 'Fecha inicial' : 'Fecha final',
    );
    if (elegida == null) return;
    _asignar(elegida, esDesde: esDesde);
  }

  DateTime _acotada(DateTime f) {
    if (f.isBefore(_minima)) return _minima;
    if (f.isAfter(_maxima)) return _maxima;
    return f;
  }

  /// Corre el otro extremo si quedó invertido, en vez de rechazar la fecha.
  /// Quien escribe un «desde» posterior al «hasta» está corriendo el rango,
  /// no equivocándose.
  void _asignar(DateTime f, {required bool esDesde}) {
    setState(() {
      if (esDesde) {
        _desde = f;
        _errorDesde = null;
        if (_hasta.isBefore(_desde)) _hasta = _desde;
      } else {
        _hasta = f;
        _errorHasta = null;
        if (_desde.isAfter(_hasta)) _desde = _hasta;
      }
    });
  }

  void _alEscribir(String texto, {required bool esDesde}) {
    final error = _validar(texto);
    if (error != null) {
      setState(() {
        if (esDesde) {
          _errorDesde = error;
        } else {
          _errorHasta = error;
        }
      });
      return;
    }
    _asignar(_formatoFecha.parseStrict(texto), esDesde: esDesde);
  }

  /// Devuelve el motivo por el que el texto no sirve, o null si sirve.
  ///
  /// Vacío no es error: es un campo a medio escribir. Se marca igual para que
  /// Aplicar quede bloqueado, pero sin gritarle a alguien que todavía está
  /// tipeando.
  String? _validar(String texto) {
    if (texto.length < 10) return '';
    final DateTime f;
    try {
      // parseStrict y no parse: el laxo acepta 32/13/2024 y lo corre a otro
      // mes en silencio, que es peor que rechazarlo.
      f = _formatoFecha.parseStrict(texto);
    } on FormatException {
      return 'Fecha inexistente';
    }
    if (f.isBefore(_minima)) {
      return 'Desde ${_formatoFecha.format(_minima)}';
    }
    if (f.isAfter(_maxima)) {
      return 'Hasta ${_formatoFecha.format(_maxima)}';
    }
    return null;
  }

  bool get _puedeAplicar => _errorDesde == null && _errorHasta == null;

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
            const SizedBox(height: Esp.l),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _CampoFechaEscribible(
                    etiqueta: 'Desde',
                    fecha: _desde,
                    error: _errorDesde,
                    onEscribir: (t) => _alEscribir(t, esDesde: true),
                    onCalendario: () => _elegirEnCalendario(esDesde: true),
                  ),
                ),
                const SizedBox(width: Esp.m),
                Expanded(
                  child: _CampoFechaEscribible(
                    etiqueta: 'Hasta',
                    fecha: _hasta,
                    error: _errorHasta,
                    onEscribir: (t) => _alEscribir(t, esDesde: false),
                    onCalendario: () => _elegirEnCalendario(esDesde: false),
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
          onPressed:
              _puedeAplicar
                  ? () => Navigator.pop(context, (desde: _desde, hasta: _hasta))
                  : null,
          icon: Icon(widget.iconoAceptar, size: 18),
          label: Text(widget.textoAceptar),
        ),
      ],
    );
  }
}

/// Campo de fecha que se puede escribir a mano **o** elegir del calendario.
///
/// Antes era solo tocable: para poner una fecha de 2019 había que retroceder
/// ochenta y pico de meses de a uno. Tipear «01/01/2019» son diez teclas.
class _CampoFechaEscribible extends StatefulWidget {
  const _CampoFechaEscribible({
    required this.etiqueta,
    required this.fecha,
    required this.error,
    required this.onEscribir,
    required this.onCalendario,
  });

  final String etiqueta;
  final DateTime fecha;
  final String? error;
  final ValueChanged<String> onEscribir;
  final VoidCallback onCalendario;

  @override
  State<_CampoFechaEscribible> createState() => _CampoFechaEscribibleState();
}

class _CampoFechaEscribibleState extends State<_CampoFechaEscribible> {
  late final TextEditingController _c = TextEditingController(
    text: _formatoFecha.format(widget.fecha),
  );

  @override
  void didUpdateWidget(_CampoFechaEscribible viejo) {
    super.didUpdateWidget(viejo);
    // Solo se pisa el texto cuando la fecha cambió desde afuera (el calendario,
    // o el otro extremo que corrió el rango). Si se pisara siempre, el cursor
    // saltaría al final en cada tecla.
    if (widget.fecha != viejo.fecha) {
      final nuevo = _formatoFecha.format(widget.fecha);
      if (_c.text != nuevo) _c.text = nuevo;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: _c,
    keyboardType: TextInputType.datetime,
    style: context.numero(fuerte: true),
    inputFormatters: [MascaraFecha()],
    decoration: InputDecoration(
      labelText: widget.etiqueta,
      hintText: 'dd/mm/aaaa',
      border: const OutlineInputBorder(),
      isDense: true,
      // Cadena vacía = a medio escribir: reserva el renglón sin acusar a nadie.
      errorText:
          (widget.error != null && widget.error!.isEmpty) ? ' ' : widget.error,
      suffixIcon: IconButton(
        icon: const Icon(Icons.calendar_today_outlined, size: 18),
        tooltip: 'Elegir del calendario',
        onPressed: widget.onCalendario,
      ),
    ),
    onChanged: widget.onEscribir,
  );
}

/// Va poniendo las barras sola mientras se tipea: 01012019 -> 01/01/2019.
///
/// Pública porque la usa también el campo de fecha suelto de talonarios: la
/// máscara tiene que ser la misma en todo el sistema o el usuario aprende dos
/// formas de escribir una fecha.
///
/// El cursor queda al final después de cada tecla. Es lo que hace cualquier
/// campo con máscara y en diez caracteres no molesta; corregir el medio se
/// resuelve borrando, que es lo que la gente hace igual.
class MascaraFecha extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue anterior,
    TextEditingValue nuevo,
  ) {
    final digitos = nuevo.text.replaceAll(RegExp(r'[^0-9]'), '');
    final recorte = digitos.length > 8 ? digitos.substring(0, 8) : digitos;

    final b = StringBuffer();
    for (var i = 0; i < recorte.length; i++) {
      if (i == 2 || i == 4) b.write('/');
      b.write(recorte[i]);
    }
    final texto = b.toString();

    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}
