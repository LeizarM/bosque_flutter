/// Las dos superficies del listado de propuestas: la planilla de escritorio y
/// las tarjetas del teléfono.
///
/// No usa `BosqueFlatTable` (con diez columnas «Aprobado / rechazado por» queda en
/// 40 px): sigue la planilla de lotes de producción, con cabecera fija, columnas
/// de ancho declarado, un scroll horizontal controlado y filas del mismo alto.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/presentation/widgets/precios/propuesta_en_autorizacion.dart';

/// Que hace cada accion de una fila. Las dos superficies reciben lo mismo: una
/// propuesta no puede hacer una cosa en la tabla y otra en la tarjeta.
@immutable
class ManejadoresPropuesta {
  const ManejadoresPropuesta({
    required this.ver,
    required this.pdf,
    required this.editar,
    required this.aprobar,
    required this.rechazar,
    required this.enviarAEspera,
    required this.generar,
  });

  final void Function(PropuestaEnAutorizacion) ver;

  /// El PDF de la propuesta (el "Exportar" del sistema anterior).
  final void Function(PropuestaEnAutorizacion) pdf;
  final void Function(PropuestaEnAutorizacion) editar;
  final void Function(PropuestaEnAutorizacion) aprobar;
  final void Function(PropuestaEnAutorizacion) rechazar;
  final void Function(PropuestaEnAutorizacion) enviarAEspera;
  final void Function(PropuestaEnAutorizacion) generar;
}

const double _altoBanda = 24;
const double _altoCabecera = 40;
const double _altoFila = 60;

// La planilla

class TablaPropuestas extends StatefulWidget {
  const TablaPropuestas({
    super.key,
    required this.filas,
    required this.acciones,
    required this.manejadores,
    required this.padding,
    this.ocupado = false,
  });

  final List<PropuestaEnAutorizacion> filas;

  /// Que puede hacer este usuario con cada propuesta. Se recibe resuelto: la
  /// tabla no lee permisos.
  final AccionesPropuesta Function(PropuestaEnAutorizacion) acciones;

  final ManejadoresPropuesta manejadores;
  final EdgeInsets padding;

  /// Hay una escritura del circuito en vuelo: mientras tanto ninguna fila acepta
  /// otra (dos aprobaciones seguidas duplicaban el registro en el sistema anterior).
  final bool ocupado;

  @override
  State<TablaPropuestas> createState() => _TablaPropuestasState();
}

class _TablaPropuestasState extends State<TablaPropuestas> {
  final _scrollH = ScrollController();

  @override
  void dispose() {
    _scrollH.dispose();
    super.dispose();
  }

  // Columnas

  List<_Col> _columnas() => [
    _Col(
      'PROPUESTA',
      128,
      alinear: Alignment.centerLeft,
      celda:
          (context, f) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                f.numero,
                maxLines: 1,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: Peso.dato,
                  fontFeatures: cifrasTabulares,
                ),
              ),
              const SizedBox(height: 2),
              EtiquetaTipoPropuesta(fila: f),
            ],
          ),
    ),
    _Col(
      'ESTADO',
      132,
      alinear: Alignment.centerLeft,
      celda: (context, f) => ChipEstadoPropuesta(autorizacion: f.autorizacion),
    ),
    _Col(
      'ACCIONES',
      _anchoAcciones,
      alinear: Alignment.centerLeft,
      celda:
          (context, f) => _AccionesEnLinea(
            fila: f,
            acciones: widget.acciones(f),
            manejadores: widget.manejadores,
            ocupado: widget.ocupado,
          ),
    ),
    _Col(
      'TÍTULO',
      300,
      alinear: Alignment.centerLeft,
      ayuda: 'Lo que la propuesta dice que cambia. Lo escribe quien la arma.',
      celda: (context, f) => _Titulo(texto: f.titulo),
    ),

    // ── Origen ──
    _Col(
      'PROPUESTO POR',
      190,
      banda: 'ORIGEN',
      alinear: Alignment.centerLeft,
      celda: (context, f) => _Persona(nombre: f.propuestoPor),
    ),
    _Col(
      'FECHA',
      116,
      banda: 'ORIGEN',
      celda: (context, f) => _Fecha(texto: f.fechaPropuesta),
    ),

    // ── Autorizacion ──
    _Col(
      'APROBADO / RECHAZADO POR',
      212,
      banda: 'AUTORIZACIÓN',
      alinear: Alignment.centerLeft,
      ayuda:
          'Queda vacío mientras la propuesta no se resuelve: Pendiente y En '
          'Espera todavía no tienen decisión.',
      celda:
          (context, f) => _Persona(
            nombre: f.tieneResolucion ? f.resueltoPor : '',
            vacio: 'Sin resolver',
          ),
    ),
    _Col(
      'FECHA',
      116,
      banda: 'AUTORIZACIÓN',
      celda: (context, f) => _Fecha(texto: f.fechaResolucion),
    ),

    // ── Generacion ──
    _Col(
      'GENERADO POR',
      190,
      banda: 'GENERACIÓN',
      alinear: Alignment.centerLeft,
      ayuda: 'Quién exportó los precios ya aprobados hacia SAP.',
      celda:
          (context, f) => _Persona(nombre: f.generadoPor, vacio: 'Sin generar'),
    ),
    _Col(
      'FECHA',
      116,
      banda: 'GENERACIÓN',
      celda: (context, f) => _Fecha(texto: f.fechaGeneracion),
    ),
  ];

  // Dibujo

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cols = _columnas();

    return Padding(
      padding: widget.padding,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          border: Border.all(color: cs.outlineVariant),
          borderRadius: BorderRadius.circular(Esquina.media),
        ),
        clipBehavior: Clip.antiAlias,
        child: LayoutBuilder(
          builder: (context, restricciones) {
            final pedido = cols.fold(0.0, (s, c) => s + c.ancho);
            // Cuando sobra lugar la planilla se estira: una tabla angosta con
            // medio panel vacio al lado se lee como si le faltara algo.
            final ancho = math.max(pedido, restricciones.maxWidth);
            final estirar = ancho - pedido;
            final desborda = pedido > restricciones.maxWidth;

            return ScrollConfiguration(
              behavior: const ArrastreLateral(),
              child: Scrollbar(
                controller: _scrollH,
                thumbVisibility: desborda,
                child: SingleChildScrollView(
                  controller: _scrollH,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: ancho,
                    child: Column(
                      children: [
                        _banda(cols, estirar),
                        _cabecera(cols, estirar),
                        Expanded(
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            itemExtent: _altoFila,
                            itemCount: widget.filas.length,
                            itemBuilder:
                                (context, i) => _fila(i, cols, estirar),
                          ),
                        ),
                        // Deja pasar la barra de scroll horizontal sin que se
                        // apoye encima de la ultima fila.
                        SizedBox(height: desborda ? 10 : 0),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// La banda que agrupa las columnas por el momento del circuito al que
  /// pertenecen: quien propuso, quien autorizo, quien genero. Sin ella, seis
  /// columnas de nombres y fechas se leen todas iguales.
  Widget _banda(List<_Col> cols, double estirar) {
    final cs = Theme.of(context).colorScheme;
    final grupos = _agrupar(cols);

    return SizedBox(
      height: _altoBanda,
      child: Row(
        children: [
          for (final (i, g) in grupos.indexed)
            Container(
              width: g.ancho + (i == grupos.length - 1 ? estirar : 0),
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.symmetric(horizontal: Esp.s),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                border: Border(
                  bottom: BorderSide(
                    color:
                        g.nombre.isEmpty
                            ? Colors.transparent
                            : colorDeCatalogo(cs, i).fondo,
                    width: 3,
                  ),
                ),
              ),
              child: Text(
                g.nombre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: Peso.titulo,
                  letterSpacing: 0.6,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _cabecera(List<_Col> cols, double estirar) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      height: _altoCabecera,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        border: Border(bottom: BorderSide(color: cs.outlineVariant)),
      ),
      child: Row(
        children: [
          for (final (i, col) in cols.indexed)
            _celda(
              col,
              estirar: i == cols.length - 1 ? estirar : 0,
              hijo:
                  col.ayuda == null
                      ? _rotulo(col.titulo)
                      : Tooltip(
                        message: col.ayuda!,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(child: _rotulo(col.titulo)),
                            SizedBox(width: Esp.xs),
                            Icon(
                              Icons.info_outline,
                              size: 12,
                              color: cs.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
            ),
        ],
      ),
    );
  }

  Widget _rotulo(String texto) => Text(
    texto,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: Theme.of(context).textTheme.labelSmall?.copyWith(
      fontWeight: Peso.titulo,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      letterSpacing: 0.3,
    ),
  );

  /// El rayado alterno es lo que deja seguir una propuesta a lo ancho de diez
  /// columnas sin saltar de renglon.
  Widget _fila(int i, List<_Col> cols, double estirar) {
    final cs = Theme.of(context).colorScheme;
    final fila = widget.filas[i];

    return Material(
      color: i.isOdd ? cs.surfaceContainerLow : cs.surfaceContainerLowest,
      child: InkWell(
        // Tocar la fila abre el detalle: es la accion que no escribe nada y la
        // que se quiere nueve de cada diez veces.
        onTap: () => widget.manejadores.ver(fila),
        child: Row(
          children: [
            for (final (j, col) in cols.indexed)
              _celda(
                col,
                estirar: j == cols.length - 1 ? estirar : 0,
                hijo: col.celda(context, fila),
              ),
          ],
        ),
      ),
    );
  }

  Widget _celda(_Col col, {required Widget hijo, double estirar = 0}) =>
      Container(
        width: col.ancho + estirar,
        alignment: col.alinear,
        padding: EdgeInsets.symmetric(horizontal: Esp.s),
        child: hijo,
      );
}

// Piezas de la planilla

class _Col {
  const _Col(
    this.titulo,
    this.ancho, {
    required this.celda,
    this.banda = '',
    this.ayuda,
    this.alinear = Alignment.centerRight,
  });

  final String titulo;
  final double ancho;
  final Widget Function(BuildContext, PropuestaEnAutorizacion) celda;

  /// El grupo al que pertenece, para la banda de arriba.
  final String banda;

  /// Que significa la columna, cuando el rotulo no alcanza.
  final String? ayuda;

  final Alignment alinear;
}

typedef _Grupo = ({String nombre, double ancho});

/// Junta las columnas contiguas que comparten banda.
List<_Grupo> _agrupar(List<_Col> cols) {
  final grupos = <_Grupo>[];
  for (final col in cols) {
    if (grupos.isNotEmpty && grupos.last.nombre == col.banda) {
      grupos[grupos.length - 1] = (
        nombre: col.banda,
        ancho: grupos.last.ancho + col.ancho,
      );
    } else {
      grupos.add((nombre: col.banda, ancho: col.ancho));
    }
  }
  return grupos;
}

class _Titulo extends StatelessWidget {
  const _Titulo({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: texto,
    child: Text(
      texto,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodySmall,
    ),
  );
}

class _Persona extends StatelessWidget {
  const _Persona({required this.nombre, this.vacio = '--'});

  final String nombre;
  final String vacio;

  @override
  Widget build(BuildContext context) {
    final texto = nombre.trim();
    if (texto.isEmpty) {
      return Text(vacio, maxLines: 1, style: context.apagado());
    }
    return Tooltip(
      message: texto,
      child: Text(
        texto,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

class _Fecha extends StatelessWidget {
  const _Fecha({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) => Text(
    texto,
    maxLines: 1,
    style: context.numero(
      color:
          texto == '--' ? Theme.of(context).colorScheme.onSurfaceVariant : null,
    ),
  );
}

/// Cada acción de una fila con su color, para reconocerla sin leer el tooltip.
/// Matices fijos y no roles del tema: siete acciones no se distinguen con dos
/// familias de color (con semilla verde, "aprobar" y "ver" salían iguales). Solo
/// el brillo sigue al tema: en oscuro el icono se aclara y el fondo se oscurece.
enum AccionDePropuesta {
  ver(Color(0xFF1E88E5)),
  pdf(Color(0xFFF4511E)),
  editar(Color(0xFFFFA000)),
  aprobar(Color(0xFF2E7D32)),
  rechazar(Color(0xFFD32F2F)),
  enviarAEspera(Color(0xFF8E24AA)),
  generar(Color(0xFF00897B));

  const AccionDePropuesta(this.matiz);

  final Color matiz;

  /// El icono y su fondo, en el brillo del tema.
  ({Color icono, Color fondo}) tonos(ColorScheme cs) => tonosDeMatiz(matiz, cs);
}

/// El tipo de la propuesta con su color, para distinguir las de familia y las de
/// artículo. Matices fijos, como las acciones de la fila: índigo y marrón no los
/// usa ninguna acción ni estado, así que no se confunden con "ver" ni "generar".
class EtiquetaTipoPropuesta extends StatelessWidget {
  const EtiquetaTipoPropuesta({super.key, required this.fila});

  final PropuestaEnAutorizacion fila;

  static const Color _matizFamilia = Color(0xFF3949AB);
  static const Color _matizArticulo = Color(0xFF795548);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final porArticulo = fila.propuesta.tipo == 2;
    final t = tonosDeMatiz(porArticulo ? _matizArticulo : _matizFamilia, cs);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: t.fondo,
        borderRadius: BorderRadius.circular(Esquina.chica),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            porArticulo ? Icons.inventory_2_outlined : Icons.category_outlined,
            size: 13,
            color: t.icono,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              fila.etiquetaTipo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: t.icono,
                fontWeight: Peso.titulo,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Un matiz fijo llevado al brillo del tema (en oscuro el icono se aclara y el fondo
/// se oscurece). Lo usan las acciones de las propuestas y las cifras del asistente.
({Color icono, Color fondo}) tonosDeMatiz(Color matiz, ColorScheme cs) {
  final oscuro = cs.brightness == Brightness.dark;
  final icono = oscuro ? Color.lerp(matiz, Colors.white, 0.35)! : matiz;
  final fondo = Color.alphaBlend(
    matiz.withValues(alpha: oscuro ? 0.24 : 0.13),
    cs.surfaceContainerLowest,
  );
  return (icono: icono, fondo: fondo);
}

/// Ancho de la columna ACCIONES: el peor caso tiene que entrar entero. Un
/// IconButton compacto de Material 3 ocupa 40 px (no los 34 de [_Boton]) y una
/// fila Pendiente con todos los permisos (ROLE_ADM) lleva SIETE botones; con
/// 224 px desbordaba 32 px. Si se agrega un botón, sumar 40.
const double _anchoAcciones = 7 * 40 + 2 * Esp.s;

/// Las acciones de una fila en escritorio, una al lado de la otra. Solo aparecen las
/// asignadas al usuario; la que aún no corresponde queda deshabilitada **con el
/// motivo en el tooltip** (es la regla del circuito y la única forma de aprenderla).
class _AccionesEnLinea extends StatelessWidget {
  const _AccionesEnLinea({
    required this.fila,
    required this.acciones,
    required this.manejadores,
    required this.ocupado,
  });

  final PropuestaEnAutorizacion fila;
  final AccionesPropuesta acciones;
  final ManejadoresPropuesta manejadores;
  final bool ocupado;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Boton(
          accion: AccionDePropuesta.ver,
          icono: Icons.visibility_outlined,
          ayuda: 'Ver la propuesta y sus artículos',
          onPressed: () => manejadores.ver(fila),
        ),
        _Boton(
          accion: AccionDePropuesta.pdf,
          icono: Icons.picture_as_pdf_outlined,
          ayuda: 'Descargar la propuesta en PDF',
          onPressed: () => manejadores.pdf(fila),
        ),
        if (acciones.puedeEditar)
          _Boton(
            accion: AccionDePropuesta.editar,
            icono: Icons.edit_outlined,
            ayuda: 'Seguir armando la propuesta',
            onPressed: ocupado ? null : () => manejadores.editar(fila),
          ),
        if (acciones.muestraResolver) ...[
          _Boton(
            accion: AccionDePropuesta.aprobar,
            icono: Icons.check_circle_outline,
            ayuda:
                acciones.motivoResolver ??
                'Aprobar: los precios propuestos pasan a ser los vigentes',
            onPressed:
                (ocupado || !acciones.resolverHabilitado)
                    ? null
                    : () => manejadores.aprobar(fila),
          ),
          _Boton(
            accion: AccionDePropuesta.rechazar,
            icono: Icons.cancel_outlined,
            ayuda: acciones.motivoResolver ?? 'Rechazar la propuesta',
            onPressed:
                (ocupado || !acciones.resolverHabilitado)
                    ? null
                    : () => manejadores.rechazar(fila),
          ),
        ],
        if (acciones.muestraEnviarAEspera)
          _Boton(
            accion: AccionDePropuesta.enviarAEspera,
            icono: Icons.hourglass_empty,
            ayuda:
                acciones.motivoEnviarAEspera ??
                'Enviar a autorizar (queda En Espera)',
            onPressed:
                (ocupado || !acciones.enviarAEsperaHabilitado)
                    ? null
                    : () => manejadores.enviarAEspera(fila),
          ),
        if (acciones.muestraGenerar)
          _Boton(
            accion: AccionDePropuesta.generar,
            icono: Icons.file_download_outlined,
            ayuda:
                acciones.motivoGenerar ??
                'Generar el archivo para SAP (CambioDePrecios.xlsx)',
            onPressed:
                (ocupado || !acciones.generarHabilitado)
                    ? null
                    : () => manejadores.generar(fila),
          ),
      ],
    );
  }
}

/// Un boton de fila: el icono en un cuadro con el color de su accion, del tamano
/// que deja pasar siete en la celda. Apagado queda gris y sin fondo, para que lo
/// que se puede hacer se vea de un vistazo.
class _Boton extends StatelessWidget {
  const _Boton({
    required this.accion,
    required this.icono,
    required this.ayuda,
    required this.onPressed,
  });

  final AccionDePropuesta accion;
  final IconData icono;
  final String ayuda;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tonos = accion.tonos(cs);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: IconButton(
        icon: Icon(icono, size: 18),
        tooltip: ayuda,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: tonos.fondo,
          foregroundColor: tonos.icono,
          disabledBackgroundColor: Colors.transparent,
          disabledForegroundColor: cs.onSurface.withValues(alpha: 0.28),
          minimumSize: const Size(34, 34),
          maximumSize: const Size(34, 34),
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Esquina.chica),
            side: BorderSide(
              color:
                  onPressed == null
                      ? cs.outlineVariant.withValues(alpha: 0.6)
                      : tonos.icono.withValues(alpha: 0.35),
            ),
          ),
        ),
      ),
    );
  }
}

// Las tarjetas

/// La misma propuesta cuando no entra una planilla. No es la tabla encogida: deja
/// lo que se mira de un vistazo (título, estado, cuándo y quién) y manda las
/// acciones a un menú, más fácil de tocar con el pulgar. Sin scroll horizontal.
class TarjetaPropuestaAutorizacion extends StatelessWidget {
  const TarjetaPropuestaAutorizacion({
    super.key,
    required this.fila,
    required this.acciones,
    required this.manejadores,
    this.ocupado = false,
  });

  final PropuestaEnAutorizacion fila;
  final AccionesPropuesta acciones;
  final ManejadoresPropuesta manejadores;
  final bool ocupado;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(Esquina.media),
      child: InkWell(
        onTap: () => manejadores.ver(fila),
        borderRadius: BorderRadius.circular(Esquina.media),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: cs.outlineVariant),
            borderRadius: BorderRadius.circular(Esquina.media),
          ),
          padding: EdgeInsets.fromLTRB(Esp.m, Esp.m, Esp.xs, Esp.s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      fila.titulo,
                      style: Theme.of(
                        context,
                      ).textTheme.titleSmall?.copyWith(fontWeight: Peso.titulo),
                    ),
                  ),
                  SizedBox(width: Esp.s),
                  ChipEstadoPropuesta(autorizacion: fila.autorizacion),
                  _MenuAcciones(
                    fila: fila,
                    acciones: acciones,
                    manejadores: manejadores,
                    ocupado: ocupado,
                  ),
                ],
              ),
              Row(
                children: [
                  Text(fila.numero, style: context.numero()),
                  const SizedBox(width: Esp.s),
                  EtiquetaTipoPropuesta(fila: fila),
                ],
              ),
              SizedBox(height: Esp.s),
              _Renglon(
                icono: Icons.person_outline,
                texto:
                    'Propuesta por ${_oGuion(fila.propuestoPor)} '
                    'el ${fila.fechaPropuesta}',
              ),
              if (fila.tieneResolucion)
                _Renglon(
                  icono: Icons.gavel_outlined,
                  texto:
                      '${fila.autorizacion.etiquetaEstado} por '
                      '${_oGuion(fila.resueltoPor)} el ${fila.fechaResolucion}',
                ),
              if (fila.propuesta.fueGenerada || fila.generadoPor.isNotEmpty)
                _Renglon(
                  icono: Icons.file_download_outlined,
                  texto:
                      'Generada por ${_oGuion(fila.generadoPor)} '
                      'el ${fila.fechaGeneracion}',
                ),
            ],
          ),
        ),
      ),
    );
  }

  static String _oGuion(String nombre) =>
      nombre.trim().isEmpty ? 'un usuario que ya no figura' : nombre.trim();
}

class _Renglon extends StatelessWidget {
  const _Renglon({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: Esp.xs),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icono,
          size: 14,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        SizedBox(width: Esp.s),
        Expanded(child: Text(texto, style: context.apagado())),
      ],
    ),
  );
}

/// Las acciones del telefono. Una opcion que no corresponde todavia se muestra
/// deshabilitada con su motivo debajo: sacarla dejaria a la persona buscando un
/// boton que en escritorio si esta.
class _MenuAcciones extends StatelessWidget {
  const _MenuAcciones({
    required this.fila,
    required this.acciones,
    required this.manejadores,
    required this.ocupado,
  });

  final PropuestaEnAutorizacion fila;
  final AccionesPropuesta acciones;
  final ManejadoresPropuesta manejadores;
  final bool ocupado;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<VoidCallback>(
      tooltip: 'Acciones de la propuesta',
      icon: const Icon(Icons.more_vert),
      onSelected: (accion) => accion(),
      itemBuilder:
          (context) => [
            _item(
              context,
              tipo: AccionDePropuesta.ver,
              icono: Icons.visibility_outlined,
              texto: 'Ver artículos',
              accion: () => manejadores.ver(fila),
            ),
            _item(
              context,
              tipo: AccionDePropuesta.pdf,
              icono: Icons.picture_as_pdf_outlined,
              texto: 'Descargar PDF',
              accion: () => manejadores.pdf(fila),
            ),
            if (acciones.puedeEditar)
              _item(
                context,
                tipo: AccionDePropuesta.editar,
                icono: Icons.edit_outlined,
                texto: 'Editar',
                accion: () => manejadores.editar(fila),
                habilitada: !ocupado,
              ),
            if (acciones.muestraResolver) ...[
              _item(
                context,
                tipo: AccionDePropuesta.aprobar,
                icono: Icons.check_circle_outline,
                texto: 'Aprobar',
                accion: () => manejadores.aprobar(fila),
                habilitada: !ocupado && acciones.resolverHabilitado,
                motivo: acciones.motivoResolver,
              ),
              _item(
                context,
                tipo: AccionDePropuesta.rechazar,
                icono: Icons.cancel_outlined,
                texto: 'Rechazar',
                accion: () => manejadores.rechazar(fila),
                habilitada: !ocupado && acciones.resolverHabilitado,
                motivo: acciones.motivoResolver,
              ),
            ],
            if (acciones.muestraEnviarAEspera)
              _item(
                context,
                tipo: AccionDePropuesta.enviarAEspera,
                icono: Icons.hourglass_empty,
                texto: 'Enviar a autorizar',
                accion: () => manejadores.enviarAEspera(fila),
                habilitada: !ocupado && acciones.enviarAEsperaHabilitado,
                motivo: acciones.motivoEnviarAEspera,
              ),
            if (acciones.muestraGenerar)
              _item(
                context,
                tipo: AccionDePropuesta.generar,
                icono: Icons.file_download_outlined,
                texto: 'Generar archivo para SAP',
                accion: () => manejadores.generar(fila),
                habilitada: !ocupado && acciones.generarHabilitado,
                motivo: acciones.motivoGenerar,
              ),
          ],
    );
  }

  PopupMenuItem<VoidCallback> _item(
    BuildContext context, {
    required AccionDePropuesta tipo,
    required IconData icono,
    required String texto,
    required VoidCallback accion,
    bool habilitada = true,
    String? motivo,
  }) {
    final cs = Theme.of(context).colorScheme;
    final tonos = tipo.tonos(cs);
    final tinte = habilitada ? cs.onSurface : cs.onSurfaceVariant;

    return PopupMenuItem<VoidCallback>(
      value: accion,
      enabled: habilitada,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // El mismo cuadro de color que el boton de la fila en escritorio.
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: habilitada ? tonos.fondo : Colors.transparent,
              borderRadius: BorderRadius.circular(Esquina.chica),
              border: Border.all(
                color:
                    habilitada
                        ? tonos.icono.withValues(alpha: 0.35)
                        : cs.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
            child: Icon(
              icono,
              size: 18,
              color:
                  habilitada
                      ? tonos.icono
                      : cs.onSurface.withValues(alpha: 0.28),
            ),
          ),
          SizedBox(width: Esp.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  texto,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: tinte),
                ),
                if (!habilitada && motivo != null)
                  Text(motivo, style: context.apagado()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
