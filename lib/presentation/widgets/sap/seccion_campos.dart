import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Un campo de texto de una [SeccionCampos].
class CampoSeccion {
  const CampoSeccion(
    this.controlador,
    this.etiqueta, {
    this.obligatorio = true,
    this.ayuda,
    this.teclado,
    this.formatos,
  });

  final TextEditingController controlador;
  final String etiqueta;
  final bool obligatorio;
  final String? ayuda;
  final TextInputType? teclado;
  final List<TextInputFormatter>? formatos;
}

/// Un grupo de campos de los formularios de SAP: dos por fila cuando hay lugar, uno debajo del
/// otro en teléfono.
class SeccionCampos extends StatelessWidget {
  const SeccionCampos({
    super.key,
    required this.titulo,
    required this.campos,
    required this.compacto,
    this.ayuda,
  });

  final String titulo;
  final String? ayuda;
  final List<CampoSeccion> campos;
  final bool compacto;

  Widget _campo(CampoSeccion c) => TextFormField(
    controller: c.controlador,
    keyboardType: c.teclado,
    inputFormatters: c.formatos,
    decoration: InputDecoration(
      labelText: c.etiqueta,
      helperText: c.ayuda,
      border: const OutlineInputBorder(),
      isDense: true,
    ),
    validator:
        c.obligatorio ? (v) => v == null || v.trim().isEmpty ? 'Obligatorio' : null : null,
  );

  @override
  Widget build(BuildContext context) {
    final filas = <Widget>[];
    final porFila = compacto ? 1 : 2;
    for (var i = 0; i < campos.length; i += porFila) {
      final tramo = campos.sublist(i, (i + porFila).clamp(0, campos.length));
      filas.add(
        Padding(
          padding: const EdgeInsets.only(bottom: Esp.m),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var j = 0; j < porFila; j++) ...[
                if (j > 0) const SizedBox(width: Esp.m),
                Expanded(child: j < tramo.length ? _campo(tramo[j]) : const SizedBox.shrink()),
              ],
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: Esp.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(titulo, style: context.tituloSeccion()),
          if (ayuda != null) Text(ayuda!, style: context.apagado()),
          const SizedBox(height: Esp.m),
          ...filas,
        ],
      ),
    );
  }
}
