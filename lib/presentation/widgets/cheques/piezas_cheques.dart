/// Piezas comunes del modulo de cheques: el panel que contiene los
/// formularios, el campo de fecha, el menu de acciones de una fila, la etiqueta
/// de estado y los dos bloques de error.
///
/// Se escribieron aqui y no se importaron de `widgets/garantias/` porque aquellas
/// llevan el tema propio de Garantias (tipografia y cifras) y cualquier cambio
/// alla se colaria en este modulo. El comportamiento es el mismo.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:bosque_flutter/core/theme/cheques_tema.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/core/utils/formato_moneda.dart';
import 'package:bosque_flutter/domain/entities/cheque_fila_entity.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/piezas_visuales_cheques.dart';

// ═══════════════════════════════════════════════════════════════════════════
// TEXTOS
// ═══════════════════════════════════════════════════════════════════════════

/// Un dato de texto o un guion si no viene. Un dato vacio no se deja en blanco
/// en una tabla: parece que no cargo.
String textoODash(String? t) => (t == null || t.trim().isEmpty) ? '—' : t.trim();

/// «Bs 1,500.50». El monto es un `float` en la base y puede traer error de
/// punto flotante: se redondea al mostrar.
String textoMontoCheque(ChequeFilaEntity c) {
  final m = c.cheque.monto;
  if (m == null) return '—';
  final unidad =
      c.descMoneda.trim().isNotEmpty
          ? c.descMoneda.trim()
          : FormatoMoneda.unidad(c.cheque.moneda);
  final cifra = FormatoMoneda.monto.format(m);
  return unidad.isEmpty ? cifra : '$unidad $cifra';
}

/// El tipo del cheque. **Nunca el codigo crudo**: en la base de prueba la
/// mayoria tiene el `tipo` corrupto (bytes dentro de un nvarchar) y el unico
/// texto confiable es `descTipo`, que el JOIN deja en null cuando no lo
/// encuentra.
String textoTipoCheque(ChequeFilaEntity c) => textoODash(c.descTipo);

/// «Quien lo entrego»: `datoEmpleado` ya trae el texto, tambien para el cliente
/// (« - Entregado por el Cliente -», con espacios y guiones de adorno).
String textoEntregadoPor(ChequeFilaEntity c) {
  final t = c.datoEmpleado.replaceAll(RegExp(r'^[\s-]+|[\s-]+$'), '');
  return t.isEmpty ? '—' : t;
}

final DateFormat _formatoFecha = DateFormat('dd/MM/yyyy');

String textoFecha(DateTime? f) => f == null ? '—' : _formatoFecha.format(f);

// ═══════════════════════════════════════════════════════════════════════════
// ETIQUETA DE ESTADO
// ═══════════════════════════════════════════════════════════════════════════

/// El estado del cheque. El texto es el del servidor (`descEstado`); el tono sale
/// del codigo: pendiente va en aviso, con un punto; cerrado, en exito, con un
/// check. El color no es el unico canal: el texto y el icono dicen lo mismo.
class EtiquetaEstadoCheque extends StatelessWidget {
  const EtiquetaEstadoCheque({
    super.key,
    required this.estado,
    required this.texto,
  });

  final String? estado;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final codigo = (estado ?? '').trim();
    final cerrado = codigo == 'CER';
    final pendiente = codigo == 'PEN';
    // Se achica en vez de desbordar una columna de ancho fijo con texto grande.
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: PastillaCheque(
        texto: texto.trim().isEmpty ? textoODash(estado) : texto.trim(),
        tono:
            cerrado
                ? SemanticaCheque.exito
                : (pendiente ? SemanticaCheque.aviso : SemanticaCheque.neutro),
        punto: pendiente,
        icono: cerrado ? Icons.check_circle_rounded : null,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ERRORES DEL SERVIDOR
// ═══════════════════════════════════════════════════════════════════════════

/// Las lineas de un mensaje del backend. Un 400 con varios errores los trae
/// separados por salto de linea y asi se muestran, **completos y tal cual**.
List<String> lineasDeError(String texto) => [
  for (final l in texto.split('\n'))
    if (l.trim().isNotEmpty) l.trim(),
];

/// El error de la ultima escritura, pegado al formulario que lo provoco. Se
/// queda hasta que el usuario vuelve a guardar: un aviso que se va solo dejaria
/// a quien tiene cuatro errores sin tiempo de leer el tercero.
class ErrorServidorCheque extends StatelessWidget {
  const ErrorServidorCheque(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final estilo = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: cs.onErrorContainer);
    final lineas = lineasDeError(texto);

    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(Esp.m),
        decoration: BoxDecoration(
          color: cs.errorContainer,
          borderRadius: BorderRadius.circular(Esquina.chica),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline, size: 20, color: cs.onErrorContainer),
            const SizedBox(width: Esp.s),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (lineas.length <= 1)
                    Text(lineas.isEmpty ? texto : lineas.single, style: estilo)
                  else
                    for (final l in lineas)
                      Padding(
                        padding: const EdgeInsets.only(bottom: Esp.xs),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('•  ', style: estilo),
                            Expanded(child: Text(l, style: estilo)),
                          ],
                        ),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Error de una pantalla o de una seccion entera, con reintento. Parecido a
/// `MensajeError` de `core/ui`, pero **sin pasar por `humanizar`**: ese esta
/// escrito para los mensajes de otros procedimientos y tomaria por fallo tecnico
/// frases del negocio que el servidor de cheques ya redacto para el usuario.
class ErrorCheques extends StatelessWidget {
  const ErrorCheques({
    super.key,
    required this.titulo,
    required this.texto,
    required this.onReintentar,
  });

  final String titulo;
  final String texto;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Esp.xxl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_outlined, size: 44, color: cs.error),
              const SizedBox(height: Esp.m),
              Text(
                titulo,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: Esp.s),
              for (final l in lineasDeError(texto))
                Text(
                  l,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              const SizedBox(height: Esp.l),
              FilledButton.tonalIcon(
                onPressed: onReintentar,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DATO DE FICHA
// ═══════════════════════════════════════════════════════════════════════════

/// Par etiqueta / valor de una ficha de datos.
class DatoCheque extends StatelessWidget {
  const DatoCheque({
    super.key,
    required this.etiqueta,
    required this.valor,
    this.cifra = false,
    this.destacado = false,
    this.extra,
  });

  final String etiqueta;
  final String valor;

  /// Algo bajo el valor: la situacion de cobro bajo la fecha, por ejemplo.
  final Widget? extra;

  /// Cifras de ancho fijo: fechas, importes y numeros que se comparan.
  final bool cifra;

  final bool destacado;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(etiqueta, style: context.apagado()),
        const SizedBox(height: 2),
        Text(
          textoODash(valor),
          style: (destacado ? t.titleSmall : t.bodyMedium)?.copyWith(
            fontWeight: destacado ? Peso.dato : null,
            fontFeatures: cifra ? cifrasTabulares : null,
            // Cifras y fechas en la monoespaciada del modulo, como en la tabla.
            fontFamily: cifra ? ChequesTema.fuenteCifras : null,
            fontSize: cifra ? 13 : null,
          ),
        ),
        if (extra != null) ...[const SizedBox(height: 2), extra!],
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CAMPO DE FECHA
// ═══════════════════════════════════════════════════════════════════════════

/// Campo de fecha que abre el calendario. Valida como un `TextFormField`, asi el
/// `Form` lo cuenta. [primera] y [ultima] acotan el calendario; [validar] da el
/// motivo cuando la fecha elegida no sirve aunque este en el rango.
class CampoFechaCheque extends StatelessWidget {
  const CampoFechaCheque({
    super.key,
    required this.etiqueta,
    required this.valor,
    required this.onCambio,
    this.obligatorio = true,
    this.validar,
    this.primera,
    this.ultima,
    this.ayuda,
    this.permiteQuitar = false,
    this.error,
  });

  final String etiqueta;
  final DateTime? valor;
  final ValueChanged<DateTime?> onCambio;
  final bool obligatorio;
  final String? Function(DateTime?)? validar;
  final DateTime? primera;
  final DateTime? ultima;
  final String? ayuda;

  /// Con un valor puesto, muestra una X que lo quita (llama a `onCambio(null)`).
  /// Solo tiene sentido si la fecha no es obligatoria: es el caso de los filtros
  /// de los reportes, donde vacio quiere decir «sin limite».
  final bool permiteQuitar;

  /// Un motivo que el padre ya calculo (por ejemplo, «hasta» anterior a
  /// «desde») y que se muestra aunque el `Form` no se haya validado. Se
  /// recalcula en cada dibujo, asi nunca queda viejo.
  final String? error;

  @override
  Widget build(BuildContext context) {
    return FormField<DateTime>(
      // La clave lleva el valor: cuando lo cambia otro campo (la fecha de cobro
      // sigue a la del cheque) el FormField se arma de nuevo con el valor nuevo.
      key: ValueKey('$etiqueta-$valor'),
      initialValue: valor,
      validator: (v) {
        if (obligatorio && v == null) return 'Indica la fecha.';
        return validar?.call(v);
      },
      builder:
          (estado) => InkWell(
            borderRadius: BorderRadius.circular(Esquina.chica),
            onTap: () async {
              final hoy = DateTime.now();
              final desde = primera ?? DateTime(2000);
              final hasta = ultima ?? DateTime(hoy.year + 15);
              var inicial = valor ?? hoy;
              if (inicial.isBefore(desde)) inicial = desde;
              if (inicial.isAfter(hasta)) inicial = hasta;
              final elegida = await showDatePicker(
                context: context,
                initialDate: inicial,
                firstDate: desde,
                lastDate: hasta,
                helpText: etiqueta,
              );
              if (elegida == null) return;
              estado.didChange(elegida);
              onCambio(elegida);
            },
            child: InputDecorator(
              isEmpty: valor == null,
              decoration: InputDecoration(
                labelText: etiqueta,
                helperText: ayuda,
                helperMaxLines: 2,
                errorText: estado.errorText ?? error,
                errorMaxLines: 3,
                isDense: true,
                border: const OutlineInputBorder(),
                suffixIconConstraints:
                    permiteQuitar
                        ? const BoxConstraints(minWidth: 36, minHeight: 36)
                        : null,
                suffixIcon:
                    (permiteQuitar && valor != null)
                        ? IconButton(
                          tooltip: 'Quitar $etiqueta',
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => onCambio(null),
                        )
                        : const Icon(Icons.event_outlined, size: 18),
              ),
              child: Text(
                valor == null ? '' : textoFecha(valor),
                style: const TextStyle(fontFeatures: cifrasTabulares),
              ),
            ),
          ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CONTENEDOR DE FORMULARIOS
// ═══════════════════════════════════════════════════════════════════════════

/// Abre [contenido] como dialogo en pantallas anchas y a pantalla completa en
/// el telefono, donde un dialogo flotante deja el teclado tapando la mitad del
/// formulario.
///
/// El ancho se mide en cada dibujo y no solo al abrir; la clave conserva lo que
/// el usuario ya escribio si la ventana cambia de tamano con el panel abierto.
///
/// [temaDelModulo] envuelve el panel en `ChequesScope` (tipografia del modulo).
/// La pantalla de Bancos reusa este contenedor pero no lleva ese tema: pasa
/// `false` para que su dialogo se vea como su pantalla.
Future<T?> abrirPanelCheque<T>(
  BuildContext context, {
  required WidgetBuilder contenido,
  double anchoMaximo = 720,
  bool temaDelModulo = true,
}) {
  final clave = GlobalKey(debugLabel: 'abrirPanelCheque');
  return showDialog<T>(
    context: context,
    // Un toque fuera no puede borrar un formulario a medio llenar.
    barrierDismissible: false,
    builder: (ctx) {
      final pantalla = MediaQuery.sizeOf(ctx);
      // El dialogo cuelga del Navigator raiz: lo que se abre desde el State de la
      // pantalla (por encima de su ChequesScope) no hereda la tipografia.
      final panel = KeyedSubtree(
        key: clave,
        child: temaDelModulo ? ChequesScope(child: contenido(ctx)) : contenido(ctx),
      );
      if (pantalla.width < 600) return Dialog.fullscreen(child: panel);
      return Dialog(
        insetPadding: const EdgeInsets.all(Esp.xl),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Esquina.media),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: anchoMaximo,
            maxHeight: pantalla.height * 0.92,
          ),
          child: panel,
        ),
      );
    },
  );
}

/// Estructura de los paneles: encabezado fijo, cuerpo que se desplaza y pie con
/// las acciones. El pie no se mueve cuando el formulario crece.
///
/// **El cuerpo ya scrollea**: adentro no puede ir nada que pida «toda la altura»
/// (`Expanded`, `Spacer`, un `ListView` sin `shrinkWrap`).
///
/// **Esc cierra el panel** y hace lo mismo que la X. Hace falta aqui porque
/// [abrirPanelCheque] abre con `barrierDismissible: false` y Flutter ata el Esc
/// de los dialogos a ese indicador.
class MarcoPanelCheque extends StatelessWidget {
  const MarcoPanelCheque({
    super.key,
    required this.titulo,
    this.subtitulo,
    required this.cuerpo,
    this.acciones = const [],
    required this.onCerrar,
  });

  final String titulo;
  final String? subtitulo;
  final Widget cuerpo;
  final List<Widget> acciones;
  final VoidCallback onCerrar;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final chico = MediaQuery.sizeOf(context).width < 600;
    final margen = chico ? Esp.l : Esp.xl;

    return Actions(
      actions: <Type, Action<Intent>>{
        DismissIntent: CallbackAction<DismissIntent>(
          onInvoke: (_) {
            onCerrar();
            return null;
          },
        ),
      },
      child: Focus(
        autofocus: true,
        skipTraversal: true,
        child: Material(
          color: cs.surface,
          child: Column(
            // A pantalla completa el pie queda abajo; en un dialogo, pegado al
            // contenido.
            mainAxisSize: chico ? MainAxisSize.max : MainAxisSize.min,
            children: [
              Container(
                color: cs.surfaceContainerLow,
                padding: EdgeInsets.fromLTRB(margen, Esp.l, Esp.s, Esp.m),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            titulo,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: Peso.titulo),
                          ),
                          if (subtitulo != null) ...[
                            const SizedBox(height: Esp.xs),
                            Text(subtitulo!, style: context.apagado()),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Cerrar (Esc)',
                      onPressed: onCerrar,
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Flexible(
                // A pantalla completa el cuerpo ocupa el alto que sobra y el pie
                // baja al borde; en un dialogo se ajusta a su contenido.
                fit: chico ? FlexFit.tight : FlexFit.loose,
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(margen, Esp.l, margen, Esp.l),
                  child: cuerpo,
                ),
              ),
              if (acciones.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(margen, Esp.m, margen, Esp.m),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: cs.outlineVariant)),
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: Esp.s,
                    runSpacing: Esp.s,
                    children: acciones,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// El boton de guardar con su estado de «en curso».
class BotonGuardarCheque extends StatelessWidget {
  const BotonGuardarCheque({
    super.key,
    required this.etiqueta,
    required this.ocupado,
    required this.onPressed,
    this.icono = Icons.save_outlined,
    this.etiquetaOcupado = 'Guardando…',
  });

  final String etiqueta;
  final bool ocupado;
  final VoidCallback? onPressed;
  final IconData icono;
  final String etiquetaOcupado;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return FilledButton(
      onPressed: ocupado ? null : onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (ocupado)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: cs.onPrimary,
              ),
            )
          else
            Icon(icono, size: 18),
          const SizedBox(width: Esp.s),
          Flexible(
            child: Text(
              ocupado ? etiquetaOcupado : etiqueta,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MENU DE ACCIONES (⋮)
// ═══════════════════════════════════════════════════════════════════════════

@immutable
class OpcionMenuCheque {
  const OpcionMenuCheque(
    this.etiqueta,
    this.icono,
    this.alElegir, {
    this.separadorAntes = false,
    this.habilitada = true,
  });

  final String etiqueta;
  final IconData icono;
  final VoidCallback alElegir;

  /// Una linea fina arriba: separa un grupo de opciones del anterior.
  final bool separadorAntes;

  /// Apagada, la opcion se ve pero no hace nada. Sirve para apagar solo lo que
  /// necesita una sucursal sin apagar el menu entero.
  final bool habilitada;
}

/// Las opciones de un menu: cada una con el separador que pida.
List<Widget> _entradasDeMenu(List<OpcionMenuCheque> opciones) => [
  for (final o in opciones) ...[
    if (o.separadorAntes) const Divider(height: 1),
    MenuItemButton(
      leadingIcon: Icon(o.icono, size: 20),
      onPressed: o.habilitada ? o.alElegir : null,
      child: Text(o.etiqueta),
    ),
  ],
];

/// El boton ⋮ con su menu. **No es un `PopupMenuButton`**: su menu es una ruta
/// aparte que recalcula la posicion con el contexto del boton, y si la fila se
/// redibuja con otro diseno al cambiar el tamano de la ventana el menu revienta.
/// `MenuAnchor` vive dentro del boton y se va con el.
class MenuAccionesCheque extends StatefulWidget {
  const MenuAccionesCheque({
    super.key,
    required this.opciones,
    this.tooltip = 'Acciones',
    this.icono = Icons.more_vert,
    this.habilitado = true,
  });

  final List<OpcionMenuCheque> opciones;
  final String tooltip;

  /// El icono del boton: dos menus lado a lado no pueden ser los dos «⋮».
  final IconData icono;

  /// Apagado, el boton se ve pero no abre el menu.
  final bool habilitado;

  @override
  State<MenuAccionesCheque> createState() => _MenuAccionesChequeState();
}

class _MenuAccionesChequeState extends State<MenuAccionesCheque> {
  final _foco = FocusNode(debugLabel: 'MenuAccionesCheque');

  @override
  void dispose() {
    _foco.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      childFocusNode: _foco,
      menuChildren: _entradasDeMenu(widget.opciones),
      builder:
          (context, menu, _) => IconButton(
            focusNode: _foco,
            tooltip: widget.tooltip,
            icon: Icon(widget.icono),
            onPressed:
                widget.habilitado
                    ? () {
                      if (menu.isOpen) {
                        menu.close();
                      } else {
                        menu.open();
                        _foco.requestFocus();
                      }
                    }
                    : null,
          ),
    );
  }
}

/// Un boton con texto que abre un menu de opciones (la barra de escritorio: un
/// solo «Reportes» en vez de cinco botones). Mismo motivo que
/// [MenuAccionesCheque] para no usar `PopupMenuButton`: `MenuAnchor` vive dentro
/// del boton y se va con el.
class BotonMenuCheque extends StatefulWidget {
  const BotonMenuCheque({
    super.key,
    required this.etiqueta,
    required this.icono,
    required this.opciones,
    this.habilitado = true,
  });

  final String etiqueta;
  final IconData icono;
  final List<OpcionMenuCheque> opciones;

  /// Apagado, el boton se ve pero no abre el menu.
  final bool habilitado;

  @override
  State<BotonMenuCheque> createState() => _BotonMenuChequeState();
}

class _BotonMenuChequeState extends State<BotonMenuCheque> {
  final _foco = FocusNode(debugLabel: 'BotonMenuCheque');

  @override
  void dispose() {
    _foco.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      childFocusNode: _foco,
      menuChildren: _entradasDeMenu(widget.opciones),
      builder:
          (context, menu, _) => OutlinedButton(
            focusNode: _foco,
            onPressed:
                widget.habilitado
                    ? () {
                      if (menu.isOpen) {
                        menu.close();
                      } else {
                        menu.open();
                        _foco.requestFocus();
                      }
                    }
                    : null,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icono, size: 18),
                const SizedBox(width: Esp.s),
                Text(widget.etiqueta),
                const SizedBox(width: Esp.xs),
                Icon(
                  menu.isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  size: 20,
                ),
              ],
            ),
          ),
    );
  }
}
