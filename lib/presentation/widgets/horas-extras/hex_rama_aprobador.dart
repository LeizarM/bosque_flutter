/// «Ver rama» de un aprobador (D34) y la vista previa de «Asignar aprobador»:
/// los empleados activos debajo del cargo de un encargado, en orden de árbol,
/// y quién firma a cada uno. Todo lo calcula el SP (R).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/hex_configuracion_provider.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/hex_aprobador_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_rama_empleado_entity.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_comun.dart';

/// Desde este ancho del panel la rama va en tabla; por debajo, tarjetas.
const double anchoTablaRamaHex = 560;

// Proporciones de las columnas de la tabla de la rama.
const int _flexEmpleado = 3;
const int _flexCargo = 3;
const int _flexSucursal = 2;
const int _flexFirma = 4;

/// De quién es la rama que se ve: el encargado de la fila. En una de jefe de
/// área (nivel 2, D35) u observador (nivel 3, D45) es el encargado aprobado u
/// observado, no el jefe ni el observador.
BigInt? codRamaAprobadorHex(HexAprobadorEntity a) =>
    a.nivel >= 2 ? a.codEmpleadoAprobado : a.codEmpleadoAprobador;

/// Abre la rama de [a]: hoja inferior en el teléfono y diálogo en el ancho.
Future<void> mostrarRamaAprobadorHex(
  BuildContext context,
  HexAprobadorEntity a,
) {
  final cod = codRamaAprobadorHex(a);
  if (cod == null) return Future.value();
  return mostrarPanelHex(
    context,
    panel: (control) => _RamaHex(aprobador: a, cod: cod, control: control),
  );
}

/// El texto de la rama en la lista: «N empleados».
String cantidadRamaHex(int n) => cuentaHex(n, 'empleado', 'empleados');

/// La columna «Alcance»: el `textoAlcance` del SP (D35) o, si no vino, la
/// cuenta de la rama.
String textoAlcanceHex(HexAprobadorEntity a) =>
    textoUsableHex(a.textoAlcance) ?? cantidadRamaHex(a.cantidadRama);

class _RamaHex extends ConsumerWidget {
  const _RamaHex({
    required this.aprobador,
    required this.cod,
    required this.control,
  });

  final HexAprobadorEntity aprobador;
  final BigInt cod;
  final ScrollController? control;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = aprobador;
    final contenido = ref
        .watch(hexRamaAprobadorProvider(cod))
        .when(
          skipLoadingOnReload: true,
          loading:
              () => const [
                SizedBox(
                  height: hexAltoEstado,
                  child: EsqueletoLista(filas: 3),
                ),
              ],
          error:
              (err, _) => [
                SizedBox(
                  height: hexAltoEstado,
                  child: vistaErrorHex(
                    err,
                    reintentar:
                        () => ref.invalidate(hexRamaAprobadorProvider(cod)),
                  ),
                ),
              ],
          data:
              (filas) => [
                if (filas.isEmpty)
                  const SizedBox(height: hexAltoEstado, child: _RamaVaciaHex())
                else
                  LayoutBuilder(
                    builder:
                        (context, c) =>
                            c.maxWidth >= anchoTablaRamaHex
                                ? _TablaRamaHex(filas)
                                : Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    for (final e in filas) _TarjetaRamaHex(e),
                                  ],
                                ),
                  ),
              ],
        );
    final aviso = textoUsableHex(a.avisoCargo);
    final jefe = a.nivel >= 2;
    final dueno = jefe ? a.nombreAprobado : a.nombreAprobador;
    final alcance = textoUsableHex(a.textoAlcance);
    return PanelHex(
      control: control,
      cabecera: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rama de ${oGuionHex(dueno)}', style: context.tituloSeccion()),
          const SizedBox(height: 2),
          Text(
            jefe
                ? [
                  '${oGuionHex(a.nivelTexto)}: ${oGuionHex(a.nombreAprobador)}',
                  alcance ?? cantidadRamaHex(a.cantidadRama),
                ].join(' · ')
                : [
                  oGuionHex(a.nivelTexto),
                  if (textoUsableHex(a.cargo) != null) a.cargo!.trim(),
                  cantidadRamaHex(a.cantidadRama),
                ].join(' · '),
            style: context.apagado(),
          ),
          if (aviso != null) ...[
            const SizedBox(height: Esp.xs),
            AvisoCargoHex(aviso),
          ],
        ],
      ),
      hijos: contenido,
    );
  }
}

/// El aviso del SP cuando el aprobador no tiene cargo vigente, en ámbar.
class AvisoCargoHex extends StatelessWidget {
  const AvisoCargoHex(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) {
    final color = acentoTonoHex(context, TonoHex.pendiente);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(Icons.warning_amber_outlined, size: 16, color: color),
        ),
        const SizedBox(width: Esp.xs),
        Flexible(
          child: Text(
            texto,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

/// «Depende directo» o a cuántos niveles está del aprobador.
String _profundidadHex(int p) =>
    p <= 1 ? 'Depende directo' : 'A ${enteroHex(p)} niveles';

/// Quién firma, con ícono: sin firmante (lo dice el SP) va en ámbar.
class _FirmaHex extends StatelessWidget {
  const _FirmaHex(this.e, {this.prefijo = ''});

  final HexRamaEmpleadoEntity e;

  /// Antes del texto del SP: «Quién firma hoy: » en el árbol.
  final String prefijo;

  @override
  Widget build(BuildContext context) {
    final sinFirmante =
        textoUsableHex(e.vistoBueno) == null &&
        textoUsableHex(e.aprueba) == null;
    final color =
        sinFirmante
            ? acentoTonoHex(context, TonoHex.pendiente)
            : Theme.of(context).colorScheme.onSurface;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(
            sinFirmante ? Icons.warning_amber_outlined : Icons.draw_outlined,
            size: 16,
            color:
                sinFirmante ? color : acentoTonoHex(context, TonoHex.primario),
          ),
        ),
        const SizedBox(width: Esp.xs),
        Expanded(
          child: Text(
            '$prefijo${oGuionHex(e.textoFirma)}',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

/// La rama en el ancho: Empleado, Cargo, Sucursal y Quién firma, sin
/// desplazamiento lateral (las celdas parten renglón).
class _TablaRamaHex extends StatelessWidget {
  const _TablaRamaHex(this.filas);

  final List<HexRamaEmpleadoEntity> filas;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final encabezado = Theme.of(context).textTheme.labelLarge?.copyWith(
      color: cs.onSurfaceVariant,
      fontWeight: Peso.titulo,
    );
    Widget fila(List<(int, Widget)> celdas) => Padding(
      padding: const EdgeInsets.symmetric(vertical: Esp.s),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (flex, celda) in celdas)
            Expanded(
              flex: flex,
              child: Padding(
                padding: const EdgeInsets.only(right: Esp.m),
                child: celda,
              ),
            ),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        fila([
          (_flexEmpleado, Text('Empleado', style: encabezado)),
          (_flexCargo, Text('Cargo', style: encabezado)),
          (_flexSucursal, Text('Sucursal', style: encabezado)),
          (_flexFirma, Text('Quién firma', style: encabezado)),
        ]),
        const Divider(height: 1),
        for (final e in filas) ...[
          fila([
            (
              _flexEmpleado,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    oGuionHex(e.nombreEmpleado),
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(fontWeight: Peso.titulo),
                  ),
                  Text(
                    _profundidadHex(e.profundidad),
                    style: context.apagado(),
                  ),
                ],
              ),
            ),
            (_flexCargo, _CargoEnArbolHex(e)),
            (_flexSucursal, Text(sucursalHex(e.nombreSucursal, e.codSucursal))),
            (_flexFirma, _FirmaHex(e)),
          ]),
          Divider(height: 1, color: cs.outlineVariant),
        ],
      ],
    );
  }
}

/// Un empleado de la rama en el teléfono: nombre, cargo y sucursal, y quién
/// firma sus reportes.
class _TarjetaRamaHex extends StatelessWidget {
  const _TarjetaRamaHex(this.e);

  final HexRamaEmpleadoEntity e;

  @override
  Widget build(BuildContext context) => TarjetaHex(
    titulo: oGuionHex(e.nombreEmpleado),
    subtitulo: [
      textoUsableHex(e.rutaCargo) ?? oGuionHex(e.cargo),
      sucursalHex(e.nombreSucursal, e.codSucursal),
      _profundidadHex(e.profundidad),
    ].join(' · '),
    contenido: _FirmaHex(e),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// ÁRBOL Y VISTA PREVIA
// ═══════════════════════════════════════════════════════════════════════════

/// Sangría por nivel del árbol; desde [_nivelesSangria] ya no crece, así una
/// rama honda no empuja el texto fuera del teléfono.
const double _sangriaAncha = 20;
const double _sangriaAngosta = 12;
const int _nivelesSangria = 4;

double _sangriaHex(int profundidad, double paso) =>
    (profundidad - 1).clamp(0, _nivelesSangria) * paso;

/// La ruta de cargos solo si dice más que el cargo (hay cargos en medio).
String? _rutaExtraHex(HexRamaEmpleadoEntity e) {
  final ruta = textoUsableHex(e.rutaCargo);
  return ruta == null || ruta == textoUsableHex(e.cargo) ? null : ruta;
}

/// El cargo de la tabla con la sangría de su nivel y, debajo, la ruta.
class _CargoEnArbolHex extends StatelessWidget {
  const _CargoEnArbolHex(this.e);

  final HexRamaEmpleadoEntity e;

  @override
  Widget build(BuildContext context) {
    final ruta = _rutaExtraHex(e);
    return Padding(
      padding: EdgeInsets.only(
        left: _sangriaHex(e.profundidad, _sangriaAngosta),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(oGuionHex(e.cargo)),
          if (ruta != null) Text(ruta, style: context.apagado()),
        ],
      ),
    );
  }
}

/// «Cargo: X · N empleados en M sucursales», contado de las filas del SP.
String resumenRamaHex(List<HexRamaEmpleadoEntity> filas) {
  final empleados = {for (final e in filas) e.codEmpleado ?? e.nombreEmpleado};
  final sucursales = {
    for (final e in filas)
      if (e.codSucursal != null || textoUsableHex(e.nombreSucursal) != null)
        e.codSucursal ?? e.nombreSucursal,
  };
  final cargo =
      filas
          .map((e) => textoUsableHex(e.cargoAprobador))
          .whereType<String>()
          .firstOrNull;
  final cuenta =
      '${cuentaHex(empleados.length, 'empleado', 'empleados')} en '
      '${cuentaHex(sucursales.length, 'sucursal', 'sucursales')}';
  return cargo == null ? cuenta : 'Cargo: $cargo · $cuenta';
}

/// La nota de la vista previa: el rol nuevo aún no cuenta en quién firma.
const String notaVistaPreviaRamaHex =
    '«Quién firma hoy» usa los roles ya vigentes: todavía no incluye el que '
    'estás asignando.';

class _RamaVaciaHex extends StatelessWidget {
  const _RamaVaciaHex();

  @override
  Widget build(BuildContext context) => const MensajeVacio(
    icono: Icons.account_tree_outlined,
    titulo: 'No tiene a nadie en su rama.',
    detalle:
        'Si no tiene un cargo vigente en el organigrama, pide a RRHH que lo '
        'revise.',
  );
}

/// Las piezas del árbol: cada cargo (con su ruta si hay cargos en medio) y
/// debajo sus empleados. Las filas ya llegan en orden de árbol del SP.
List<Widget> _piezasArbolHex(
  BuildContext context,
  List<HexRamaEmpleadoEntity> filas,
  double paso,
) {
  final cs = Theme.of(context).colorScheme;
  final piezas = <Widget>[];
  Object? grupo;
  for (final e in filas) {
    final clave = (e.rutaCargo ?? e.codCargo ?? e.cargo, e.profundidad);
    final sangria = _sangriaHex(e.profundidad, paso);
    if (clave != grupo) {
      grupo = clave;
      final ruta = _rutaExtraHex(e);
      piezas.add(
        Padding(
          padding: EdgeInsets.only(left: sangria, top: Esp.m),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  e.profundidad <= 1
                      ? Icons.account_tree_outlined
                      : Icons.subdirectory_arrow_right,
                  size: 16,
                  color: cs.primary,
                ),
              ),
              const SizedBox(width: Esp.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      oGuionHex(e.cargo),
                      style: Theme.of(
                        context,
                      ).textTheme.labelLarge?.copyWith(fontWeight: Peso.titulo),
                    ),
                    if (ruta != null) Text(ruta, style: context.apagado()),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    piezas.add(
      Container(
        margin: EdgeInsets.only(left: sangria + Esp.s, top: Esp.xs),
        padding: const EdgeInsets.only(left: Esp.m, top: 2, bottom: 2),
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: cs.outlineVariant, width: 2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              oGuionHex(e.nombreEmpleado),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: Peso.titulo),
            ),
            Text(
              sucursalHex(e.nombreSucursal, e.codSucursal),
              style: context.apagado(),
            ),
            const SizedBox(height: 2),
            _FirmaHex(e, prefijo: 'Quién firma hoy: '),
          ],
        ),
      ),
    );
  }
  return piezas;
}

/// Alto de los estados (carga, error, vacío) cuando la vista previa va bajo
/// el formulario y no tiene un alto propio.
const double _altoEstadoPrevia = 220;

/// La rama de [codEmpleado] antes de asignarle un rol: el resumen, la nota y
/// el árbol. Con [desplazable] llena su alto y el árbol se desplaza solo (la
/// columna derecha del diálogo); sin él crece con su contenido (el teléfono).
class VistaPreviaRamaHex extends ConsumerWidget {
  const VistaPreviaRamaHex({
    super.key,
    required this.codEmpleado,
    required this.desplazable,
  });

  final BigInt codEmpleado;
  final bool desplazable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rama = ref.watch(hexRamaAprobadorProvider(codEmpleado));
    Widget estado(Widget w) =>
        desplazable ? w : SizedBox(height: _altoEstadoPrevia, child: w);
    final cuerpo = rama.when(
      loading: () => estado(const EsqueletoLista(filas: 3, altoFila: 56)),
      error:
          (err, _) => estado(
            vistaErrorHex(
              err,
              reintentar:
                  () => ref.invalidate(hexRamaAprobadorProvider(codEmpleado)),
            ),
          ),
      data: (filas) {
        if (filas.isEmpty) return estado(const _RamaVaciaHex());
        final piezas = _piezasArbolHex(
          context,
          filas,
          desplazable ? _sangriaAncha : _sangriaAngosta,
        );
        return desplazable
            ? _ArbolDesplazableHex(piezas)
            : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: piezas,
            );
      },
    );
    final filas = rama.isLoading ? null : rama.valueOrNull;
    // Las listas de los estados no toman el control primario del diálogo:
    // ya lo usa el formulario y un control no se comparte.
    return PrimaryScrollController.none(
      child: Column(
        mainAxisSize: desplazable ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (filas != null && filas.isNotEmpty) ...[
            Text(
              resumenRamaHex(filas),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: Peso.titulo),
            ),
            const SizedBox(height: Esp.xs),
            Text(notaVistaPreviaRamaHex, style: context.apagado()),
            const Divider(height: Esp.l),
          ],
          if (desplazable) Expanded(child: cuerpo) else cuerpo,
        ],
      ),
    );
  }
}

/// El árbol con su propio desplazamiento (columna derecha del diálogo).
class _ArbolDesplazableHex extends StatefulWidget {
  const _ArbolDesplazableHex(this.piezas);

  final List<Widget> piezas;

  @override
  State<_ArbolDesplazableHex> createState() => _ArbolDesplazableHexState();
}

class _ArbolDesplazableHexState extends State<_ArbolDesplazableHex> {
  final ScrollController _control = ScrollController();

  @override
  void dispose() {
    _control.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scrollbar(
    controller: _control,
    child: ListView(
      controller: _control,
      padding: const EdgeInsets.only(right: Esp.m, bottom: Esp.m),
      children: widget.piezas,
    ),
  );
}
