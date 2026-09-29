/// La grilla editable de porcentajes: las listas de precio de cada sucursal, con
/// el margen de cada una. La usan las pestañas "por familia" y "por grupo" (el
/// margen que se aplica a TODAS las familias del grupo).
///
/// Un bloque por sucursal: la regla (el margen no baja al subir el número de
/// lista) se lee DENTRO de cada sucursal; el bloque dice el rango y si rompe el
/// orden. No hay "quitar porcentaje": una lista sin margen es una sin precio.
/// El diseño cambia con el ancho del bloque (LayoutBuilder; el sidebar se come
/// 260 px y por grupo la grilla vive en medio panel), sin scroll horizontal.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/presentation/widgets/precios/porcentajes_datos.dart';

/// Ancho minimo de la celda de una lista: el rotulo y un campo con "100,00 %".
const double _anchoMinimoLista = 150;

/// Ancho de la columna de la sucursal en escritorio.
const double _anchoSucursal = 230;

class TablaPorcentajes extends StatelessWidget {
  const TablaPorcentajes({
    super.key,
    required this.filas,
    required this.valores,
    required this.onCambio,
    this.clavesEnConflicto = const <String>{},
    this.habilitado = true,
    this.mostrarPendientes = true,
    this.resaltarCambios = true,
  });

  final List<FilaPorcentaje> filas;

  /// Lo que hay escrito en cada campo, por idClasificacion. Una clave ausente
  /// significa "sin tocar" y vale el valor que trajo el backend; un valor null
  /// significa que lo escrito **no es un numero** y esa fila no se puede
  /// guardar.
  final Map<BigInt, double?> valores;

  /// Avisa el valor nuevo de una fila. Null cuando el texto dejó de ser un número:
  /// la pantalla apaga el botón de guardar en vez de escribir un cero.
  final void Function(BigInt idClasificacion, double? valor) onCambio;

  /// Las filas que rompen la regla de porcentajes ascendentes, por
  /// [FilaPorcentaje.claveConflicto]. Se pintan con el color de error del tema.
  final Set<String> clavesEnConflicto;

  /// En falso mientras hay una escritura en vuelo: los campos se bloquean para
  /// que nadie edite una grilla que se esta guardando.
  final bool habilitado;

  /// Marcar las listas que todavia no tienen fila en tpr_porcentaje. En la
  /// edicion por grupo no significa nada -el idPorcen de la grilla no es el de
  /// ninguna familia- y se apaga.
  final bool mostrarPendientes;

  /// Pintar en color los campos que difieren de lo guardado, con el valor de
  /// antes debajo: es lo que se va a escribir al guardar. En la edicion por
  /// grupo no hay "lo guardado" -la grilla nace en cero- y se apaga.
  final bool resaltarCambios;

  double? _valorDe(FilaPorcentaje fila) =>
      valores.containsKey(fila.idClasificacion)
          ? valores[fila.idClasificacion]
          : fila.porcen;

  /// Las filas por sucursal, cada una en orden de lista. Las sucursales van
  /// por su lista mas baja -Central 1-4, Cochabamba 5-8, Santa Cruz 9-12-, que
  /// es el orden en que se las piensa; el codigo de sucursal no lo sigue.
  static List<List<FilaPorcentaje>> _porSucursal(List<FilaPorcentaje> filas) {
    final grupos = <int, List<FilaPorcentaje>>{};
    for (final f in filas) {
      (grupos[f.codSucursal] ??= <FilaPorcentaje>[]).add(f);
    }
    final lista = [
      for (final g in grupos.values) g..sort((a, b) => a.vpp.compareTo(b.vpp)),
    ];
    lista.sort((a, b) => a.first.vpp.compareTo(b.first.vpp));
    return lista;
  }

  @override
  Widget build(BuildContext context) {
    if (filas.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final grupo in _porSucursal(filas))
          Padding(
            padding: const EdgeInsets.only(bottom: Esp.m),
            child: _BloqueSucursal(
              filas: grupo,
              valorDe: _valorDe,
              clavesEnConflicto: clavesEnConflicto,
              habilitado: habilitado,
              mostrarPendientes: mostrarPendientes,
              resaltarCambios: resaltarCambios,
              onCambio: onCambio,
            ),
          ),
      ],
    );
  }
}

class _BloqueSucursal extends StatelessWidget {
  const _BloqueSucursal({
    required this.filas,
    required this.valorDe,
    required this.clavesEnConflicto,
    required this.habilitado,
    required this.mostrarPendientes,
    required this.resaltarCambios,
    required this.onCambio,
  });

  final List<FilaPorcentaje> filas;
  final double? Function(FilaPorcentaje) valorDe;
  final Set<String> clavesEnConflicto;
  final bool habilitado;
  final bool mostrarPendientes;
  final bool resaltarCambios;
  final void Function(BigInt idClasificacion, double? valor) onCambio;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final enConflicto = filas.any(
      (f) => clavesEnConflicto.contains(f.claveConflicto),
    );

    final cabecera = _CabeceraSucursal(
      filas: filas,
      valorDe: valorDe,
      enConflicto: enConflicto,
      mostrarPendientes: mostrarPendientes,
    );
    final listas = _ListasDeSucursal(
      filas: filas,
      valorDe: valorDe,
      clavesEnConflicto: clavesEnConflicto,
      habilitado: habilitado,
      mostrarPendientes: mostrarPendientes,
      resaltarCambios: resaltarCambios,
      onCambio: onCambio,
    );

    return Container(
      padding: const EdgeInsets.all(Esp.m),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        border: Border.all(
          color: enConflicto ? cs.error : cs.outlineVariant,
          width: enConflicto ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(Esquina.media),
      ),
      // La forma la decide el ancho del bloque y no el de la ventana: en la edicion por
      // grupo la grilla vive en medio panel aunque la ventana sea ancha.
      child: LayoutBuilder(
        builder: (context, r) {
          final alLado =
              r.maxWidth >=
              _anchoSucursal +
                  Esp.m +
                  filas.length * (_anchoMinimoLista + Esp.m);
          return alLado
              ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: _anchoSucursal, child: cabecera),
                  const SizedBox(width: Esp.m),
                  Expanded(child: listas),
                ],
              )
              : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [cabecera, const SizedBox(height: Esp.m), listas],
              );
        },
      ),
    );
  }
}

/// El nombre de la sucursal, el rango que quedo y lo que hay que mirar.
class _CabeceraSucursal extends StatelessWidget {
  const _CabeceraSucursal({
    required this.filas,
    required this.valorDe,
    required this.enConflicto,
    required this.mostrarPendientes,
  });

  final List<FilaPorcentaje> filas;
  final double? Function(FilaPorcentaje) valorDe;
  final bool enConflicto;
  final bool mostrarPendientes;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    // Una lista sin cargar trae un cero que nadie escribio: no entra en el
    // rango hasta que se le ponga un valor.
    bool sinCargar(FilaPorcentaje f) =>
        mostrarPendientes && f.esAlta && mismoPorcentaje(valorDe(f)!, f.porcen);
    final valores = [
      for (final f in filas)
        if (valorDe(f) != null && !sinCargar(f)) valorDe(f)!,
    ];
    final pendientes =
        mostrarPendientes ? filas.where((f) => f.esAlta).length : 0;
    final cantidad = filas.length == 1 ? '1 lista' : '${filas.length} listas';

    // El rango en el orden de las listas: de la primera a la ultima. Si la
    // serie sube, se lee "18,00 % a 21,00 %" y ya dice que esta bien.
    final rango =
        valores.length < 2
            ? ''
            : ' · ${porcenTexto(valores.first)} a ${porcenTexto(valores.last)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          filas.first.sucursal,
          style: tt.titleSmall?.copyWith(fontWeight: Peso.titulo),
        ),
        const SizedBox(height: 2),
        Text('$cantidad$rango', style: context.apagado()),
        if (enConflicto || pendientes > 0) ...[
          const SizedBox(height: Esp.s),
          Wrap(
            spacing: Esp.xs,
            runSpacing: Esp.xs,
            children: [
              if (enConflicto)
                const Etiqueta(
                  texto: 'Fuera de orden',
                  tono: TonoEtiqueta.error,
                ),
              if (pendientes > 0)
                Etiqueta(
                  texto:
                      pendientes == 1
                          ? '1 sin cargar'
                          : '$pendientes sin cargar',
                  tono: TonoEtiqueta.aviso,
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Las listas de una sucursal: rotulo y campo, en orden de izquierda a derecha.
class _ListasDeSucursal extends StatelessWidget {
  const _ListasDeSucursal({
    required this.filas,
    required this.valorDe,
    required this.clavesEnConflicto,
    required this.habilitado,
    required this.mostrarPendientes,
    required this.resaltarCambios,
    required this.onCambio,
  });

  final List<FilaPorcentaje> filas;

  final double? Function(FilaPorcentaje) valorDe;
  final Set<String> clavesEnConflicto;
  final bool habilitado;
  final bool mostrarPendientes;
  final bool resaltarCambios;
  final void Function(BigInt idClasificacion, double? valor) onCambio;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, r) {
        final entran =
            ((r.maxWidth + Esp.m) / (_anchoMinimoLista + Esp.m)).floor();
        final n = filas.length;
        // Todas en un renglon si entran; si no, de a mitades -dos y dos, no
        // tres y una-, que es como se lee una serie que tiene que subir.
        final columnas =
            entran >= n ? n : entran.clamp(1, (n / 2).ceil()).toInt();
        final ancho = (r.maxWidth - (columnas - 1) * Esp.m) / columnas;

        return Wrap(
          spacing: Esp.m,
          runSpacing: Esp.m,
          children: [
            for (final f in filas)
              SizedBox(
                width: ancho,
                child: _CeldaLista(
                  fila: f,
                  valor: valorDe(f),
                  enConflicto: clavesEnConflicto.contains(f.claveConflicto),
                  habilitado: habilitado,
                  pendiente: mostrarPendientes && f.esAlta,
                  cambiado:
                      resaltarCambios &&
                      valorDe(f) != null &&
                      !mismoPorcentaje(valorDe(f)!, f.porcen),
                  onCambio: (v) => onCambio(f.idClasificacion, v),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CeldaLista extends StatelessWidget {
  const _CeldaLista({
    required this.fila,
    required this.valor,
    required this.enConflicto,
    required this.habilitado,
    required this.pendiente,
    required this.cambiado,
    required this.onCambio,
  });

  final FilaPorcentaje fila;
  final double? valor;
  final bool enConflicto;
  final bool habilitado;
  final bool pendiente;

  /// Difiere de lo guardado: se escribe al guardar.
  final bool cambiado;
  final ValueChanged<double?> onCambio;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                fila.etiquetaLista,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tt.labelLarge?.copyWith(
                  fontWeight: Peso.titulo,
                  color: enConflicto ? cs.error : null,
                ),
              ),
            ),
            if (pendiente)
              const Etiqueta(texto: 'Sin cargar', tono: TonoEtiqueta.aviso),
          ],
        ),
        const SizedBox(height: Esp.xs),
        CampoPorcentaje(
          // La clave amarra el campo a SU lista: sin ella Flutter reutiliza
          // el estado de esa posición y, al cambiar de familia, el margen
          // aparece en la lista de al lado.
          key: ValueKey(fila.idClasificacion),
          valor: valor,
          habilitado: habilitado,
          enConflicto: enConflicto,
          cambiado: cambiado,
          onCambio: onCambio,
        ),
        if (cambiado)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              fila.esAlta ? 'Nuevo' : 'Antes: ${porcenTexto(fila.porcen)}',
              style: context.apagado(),
            ),
          ),
      ],
    );
  }
}

/// El campo donde se escribe el margen.
///
/// Tiene estado propio: el texto en curso no puede vivir en el mapa de la
/// pantalla (al borrar el 12 para escribir 15 pasa por "" y "1"; reconstruir
/// desde el valor numérico movería el cursor). Sí escucha lo de afuera
/// ([didUpdateWidget]): "igualar todas las listas" cambia el valor sin tocar el
/// campo.
class CampoPorcentaje extends StatefulWidget {
  const CampoPorcentaje({
    super.key,
    required this.valor,
    required this.onCambio,
    this.habilitado = true,
    this.enConflicto = false,
    this.cambiado = false,
    this.etiqueta,
  });

  /// Null significa que lo escrito no es un numero; en ese caso el campo no se
  /// toca, porque lo que hay que corregir es justamente lo que esta escrito.
  final double? valor;

  final ValueChanged<double?> onCambio;
  final bool habilitado;
  final bool enConflicto;

  /// Difiere de lo guardado: se pinta en el color terciario, igual que en el
  /// editor de la propuesta.
  final bool cambiado;
  final String? etiqueta;

  @override
  State<CampoPorcentaje> createState() => _CampoPorcentajeState();
}

class _CampoPorcentajeState extends State<CampoPorcentaje> {
  late final TextEditingController _ctrl = TextEditingController(
    text: widget.valor == null ? '' : porcenEditable(widget.valor!),
  );

  /// Lo escrito no es un número. Se guarda en el estado del campo y no se deduce
  /// del texto: el error debe verse aunque la pantalla no se reconstruya.
  late bool _invalido = widget.valor == null;

  @override
  void didUpdateWidget(CampoPorcentaje anterior) {
    super.didUpdateWidget(anterior);
    final valor = widget.valor;
    if (valor == null) return;
    final escrito = porcenDesdeTexto(_ctrl.text);
    // Solo se pisa el texto cuando el valor de afuera es OTRO; si coincide (caso
    // normal: salió de este campo) se deja el texto y el cursor donde estaban.
    if (escrito != null && mismoPorcentaje(escrito, valor)) return;
    _ctrl.text = porcenEditable(valor);
    _ctrl.selection = TextSelection.collapsed(offset: _ctrl.text.length);
    _invalido = false;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final invalido = _invalido;

    return TextField(
      controller: _ctrl,
      enabled: widget.habilitado,
      textAlign: TextAlign.right,
      // Decimal y con signo: un margen negativo es raro pero existe, y un teclado
      // sin el menos obligaría a cargarlo desde otro lado.
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: true,
      ),
      inputFormatters: [
        // La coma se admite a proposito -en Bolivia se escribe 12,5- y se
        // traduce al parsear.
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\-]')),
      ],
      style: context.numero(
        fuerte: true,
        color: widget.cambiado && !invalido ? cs.onTertiaryContainer : null,
      ),
      decoration: InputDecoration(
        isDense: true,
        labelText: widget.etiqueta,
        suffixText: '%',
        filled: widget.cambiado && !invalido && !widget.enConflicto,
        fillColor: cs.tertiaryContainer,
        border: const OutlineInputBorder(),
        errorText:
            invalido
                ? 'No es un número'
                : (widget.enConflicto ? 'Rompe el orden' : null),
        // El error de formato ya se pinta solo; el del orden ascendente no,
        // porque para el campo no hay nada mal escrito.
        enabledBorder:
            widget.enConflicto && !invalido
                ? OutlineInputBorder(
                  borderSide: BorderSide(color: cs.error, width: 1.5),
                )
                : (widget.cambiado && !invalido
                    ? OutlineInputBorder(
                      borderSide: BorderSide(color: cs.tertiary, width: 1.5),
                    )
                    : null),
      ),
      onChanged: (texto) {
        final valor = porcenDesdeTexto(texto);
        if ((valor == null) != _invalido) {
          setState(() => _invalido = valor == null);
        }
        widget.onCambio(valor);
      },
    );
  }
}
