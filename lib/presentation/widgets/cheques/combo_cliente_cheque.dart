/// El combo de cliente con buscador del modulo de cheques: lo usan el formulario
/// de alta y edicion y el reporte de cobranzas.
///
/// Se extrajo del formulario para compartirlo sin copiarlo. La lista entera viene
/// de `clientesChequeProvider` (una sola vez por empresa) y se filtra aqui, en
/// memoria.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/cheques_provider.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/socio_negocio_entity.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/piezas_cheques.dart';

/// Como se nombra a un cliente en el combo.
String etiquetaCliente(SocioNegocioEntity c) {
  if (c.nombreCompleto.trim().isNotEmpty) return c.nombreCompleto.trim();
  if (c.razonSocial.trim().isNotEmpty) return c.razonSocial.trim();
  return c.datoCliente.trim().isEmpty ? c.codCliente : c.datoCliente.trim();
}

/// Cuantas opciones se pintan a la vez: la lista de clientes de una empresa
/// tiene miles y pintarlas todas congelaria el celular.
const int maximoOpcionesCliente = 40;

/// Combo de cliente **con buscador**. La lista entera viene de
/// `clientesChequeProvider` (una sola vez por empresa) y se filtra aqui, en
/// memoria, por nombre o codigo; solo se pintan las primeras
/// [maximoOpcionesCliente].
///
/// Siempre dice por que no ofrece nada: la lista carga, la empresa aun no esta
/// resuelta, la empresa no tiene clientes o lo escrito no coincide con ninguno.
/// Un desplegable que simplemente no aparece deja al usuario sin saber que pasa.
class ComboClienteCheque extends ConsumerStatefulWidget {
  const ComboClienteCheque({
    super.key,
    required this.codEmpresa,
    required this.eligio,
    required this.textoInicial,
    required this.alElegir,
    required this.alEscribir,
    required this.validar,
    this.ayuda,
    this.opcional = false,
  });

  /// La empresa de la que salen los clientes; null mientras no se sabe cual es.
  final int? codEmpresa;

  /// Ya hay un cliente elegido de la lista. Si es asi, un texto que no coincide
  /// con nada (el nombre de un cheque guardado) no es un aviso.
  final bool eligio;
  final String textoInicial;
  final ValueChanged<SocioNegocioEntity> alElegir;
  final VoidCallback alEscribir;
  final FormFieldValidator<String> validar;

  /// El texto de ayuda bajo el campo; sin el, el del formulario.
  final String? ayuda;

  /// Elegir cliente no es obligatorio (el reporte de cobranzas: vacio = todos).
  /// Una empresa sin clientes ya no es un error que impide continuar.
  final bool opcional;

  @override
  ConsumerState<ComboClienteCheque> createState() => _ComboClienteChequeState();
}

class _ComboClienteChequeState extends ConsumerState<ComboClienteCheque> {
  /// La lista de la que salieron [_ordenados] y [_claves]: ordenar y pasar a
  /// minusculas miles de nombres se hace una vez, no en cada tecla.
  List<SocioNegocioEntity>? _origen;
  List<SocioNegocioEntity> _ordenados = const [];
  List<String> _claves = const [];

  /// Cuantas coinciden en la ultima busqueda (para avisar que hay mas).
  int _coincidencias = 0;

  void _preparar(List<SocioNegocioEntity> lista) {
    if (identical(lista, _origen)) return;
    _origen = lista;
    final copia = [...lista]..sort(
      (a, b) => etiquetaCliente(a).toLowerCase().compareTo(
        etiquetaCliente(b).toLowerCase(),
      ),
    );
    _ordenados = copia;
    _claves = [
      for (final c in copia)
        '${etiquetaCliente(c)} ${c.codCliente} ${c.razonSocial}'.toLowerCase(),
    ];
  }

  static List<String> _palabras(String texto) =>
      texto
          .toLowerCase()
          .split(RegExp(r'\s+'))
          .where((p) => p.isNotEmpty)
          .toList();

  Iterable<SocioNegocioEntity> _opciones(String texto) {
    final palabras = _palabras(texto);
    final salida = <SocioNegocioEntity>[];
    var total = 0;
    for (var i = 0; i < _ordenados.length; i++) {
      if (palabras.every(_claves[i].contains)) {
        total++;
        if (salida.length < maximoOpcionesCliente) salida.add(_ordenados[i]);
      }
    }
    _coincidencias = total;
    return salida;
  }

  /// Si [texto] encuentra a alguien. Sin texto no hay nada que buscar.
  bool _hayCoincidencias(String texto) {
    final palabras = _palabras(texto);
    if (palabras.isEmpty) return true;
    return _claves.any((k) => palabras.every(k.contains));
  }

  /// El campo sin opciones que ofrecer, con el motivo como texto de ayuda.
  /// [alerta] lo pinta como aviso (no es una espera normal).
  Widget _campoInactivo({
    required String clave,
    required String ayuda,
    FormFieldValidator<String>? validar,
    bool alerta = false,
    bool cargando = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    return TextFormField(
      key: ValueKey(clave),
      enabled: false,
      initialValue: widget.textoInicial,
      validator: validar,
      decoration: InputDecoration(
        labelText: 'Cliente',
        helperText: ayuda,
        helperMaxLines: 2,
        helperStyle: alerta ? TextStyle(color: cs.error) : null,
        isDense: true,
        border: const OutlineInputBorder(),
        suffixIcon:
            cargando
                ? const Padding(
                  padding: EdgeInsets.all(Esp.m),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
                : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final codEmpresa = widget.codEmpresa;
    if (codEmpresa == null) {
      return _campoInactivo(
        clave: 'cliente-sin-empresa',
        ayuda: 'Esperando la empresa…',
        validar: widget.validar,
        cargando: true,
      );
    }
    final async = ref.watch(clientesChequeProvider(codEmpresa));

    return async.when(
      loading:
          () => _campoInactivo(
            clave: 'cliente-cargando',
            ayuda: 'Cargando clientes…',
            validar: widget.validar,
            cargando: true,
          ),
      error:
          (e, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ErrorServidorCheque(
                'No se pudo cargar la lista de clientes: '
                '${mensajeDeErrorCheque(e)}',
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed:
                      () => ref.invalidate(clientesChequeProvider(codEmpresa)),
                  child: const Text('Reintentar'),
                ),
              ),
            ],
          ),
      data: (lista) {
        // Una empresa sin clientes: no hay a quien elegir. Salvo que el cheque
        // ya tenga el suyo (una edicion) o que elegir sea opcional, el
        // formulario no se puede guardar.
        if (lista.isEmpty) {
          const mensaje = 'No hay clientes para esta empresa.';
          final sinExigir = widget.eligio || widget.opcional;
          return _campoInactivo(
            clave: 'cliente-sin-datos',
            ayuda: mensaje,
            alerta: !sinExigir,
            validar: sinExigir ? widget.validar : (_) => mensaje,
          );
        }
        _preparar(lista);
        final cs = Theme.of(context).colorScheme;
        return LayoutBuilder(
          builder:
              (context, c) => Autocomplete<SocioNegocioEntity>(
                initialValue: TextEditingValue(text: widget.textoInicial),
                displayStringForOption: etiquetaCliente,
                optionsBuilder: (v) => _opciones(v.text.trim()),
                onSelected: widget.alElegir,
                fieldViewBuilder:
                    (context, ctrl, foco, alEnviar) =>
                        ValueListenableBuilder<TextEditingValue>(
                          valueListenable: ctrl,
                          builder: (context, valor, _) {
                            // Flutter no abre el desplegable si no hay opciones:
                            // sin este aviso, escribir algo que no existe no
                            // dice nada.
                            final texto = valor.text.trim();
                            final sinCoincidencias =
                                !widget.eligio &&
                                texto.isNotEmpty &&
                                !_hayCoincidencias(texto);
                            return TextFormField(
                              key: const ValueKey('campo-cliente'),
                              controller: ctrl,
                              focusNode: foco,
                              onChanged: (_) => widget.alEscribir(),
                              validator: widget.validar,
                              decoration: InputDecoration(
                                labelText: 'Cliente',
                                helperText:
                                    sinCoincidencias
                                        ? 'Sin coincidencias. Prueba con otra '
                                            'parte del nombre o del código.'
                                        : (widget.ayuda ??
                                            'Escribe parte del nombre o del código.'),
                                helperMaxLines: 2,
                                // Un aviso del formulario (o del reporte) se
                                // lee entero, no cortado con puntos.
                                errorMaxLines: 3,
                                helperStyle:
                                    sinCoincidencias
                                        ? TextStyle(color: cs.error)
                                        : null,
                                isDense: true,
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.search, size: 18),
                              ),
                            );
                          },
                        ),
                optionsViewBuilder:
                    (context, alElegir, opciones) => Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(Esquina.chica),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: 300,
                            maxWidth: c.maxWidth,
                          ),
                          child: ListView(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            children: [
                              // Primero, para que se lea sin recorrer la lista.
                              if (_coincidencias > opciones.length)
                                Padding(
                                  padding: const EdgeInsets.all(Esp.m),
                                  child: Text(
                                    'Hay $_coincidencias coincidencias: '
                                    'escribe más para acotar.',
                                    style: context.apagado(),
                                  ),
                                ),
                              for (final o in opciones)
                                ListTile(
                                  dense: true,
                                  title: Text(etiquetaCliente(o)),
                                  subtitle: Text(
                                    o.codCliente,
                                    style: const TextStyle(
                                      fontFeatures: cifrasTabulares,
                                    ),
                                  ),
                                  onTap: () => alElegir(o),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
              ),
        );
      },
    );
  }
}
