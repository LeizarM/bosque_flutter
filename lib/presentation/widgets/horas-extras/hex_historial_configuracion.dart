/// «Historial de cambios» de la configuración (D22): la bitácora de una
/// entidad paginada en el servidor, con los textos del SP. La usan Parámetros
/// (por pestaña) y Aprobadores; quién la lee lo decide el backend.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/hex_configuracion_provider.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/core/utils/tablas_utils.dart';
import 'package:bosque_flutter/domain/entities/hex_configuracion_evento_entity.dart';
import 'package:bosque_flutter/domain/repositories/hex_configuracion_repository.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_escrituras.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_formatos.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_listado.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_piezas.dart';

/// Filas por página de la bitácora.
const int _tamano = 20;

/// Cada `flex` es la mitad de los px que pide su columna (como la tabla de
/// reportes): cuándo y quién, el registro, la acción y el campo, los valores.
const int _flexCuando = 80;
const int _flexRegistro = 100;
const int _flexCambio = 70;
const int _flexValores = 120;

/// El ancho de lista desde el que la bitácora va en tabla; por debajo,
/// tarjetas ([usaTablaHex]).
const double anchoTablaHistorialHex =
    2.0 * (_flexCuando + _flexRegistro + _flexCambio + _flexValores) +
    2 * Esp.m;

/// La sección «Historial de cambios» de [entidad] (y de [idRegistro], si
/// viene), con filtro por fecha del cambio. Va dentro del desplazamiento de
/// la pantalla: en el ancho, la tabla mide hasta [altoMaximo].
class HistorialConfiguracionHex extends ConsumerStatefulWidget {
  const HistorialConfiguracionHex({
    super.key,
    required this.entidad,
    required this.altoMaximo,
    this.idRegistro,
  });

  /// Una de [EntidadConfiguracionHex].
  final String entidad;
  final double altoMaximo;
  final BigInt? idRegistro;

  @override
  ConsumerState<HistorialConfiguracionHex> createState() =>
      _HistorialConfiguracionHexState();
}

class _HistorialConfiguracionHexState
    extends ConsumerState<HistorialConfiguracionHex> {
  int _pagina = 1;
  DateTime? _desde;
  DateTime? _hasta;

  FiltroHistorialHex get _filtro => (
    entidad: widget.entidad,
    idRegistro: widget.idRegistro,
    desde: _desde,
    hasta: _hasta,
    pagina: _pagina,
    tamano: _tamano,
  );

  void _filtrar(DateTime? desde, DateTime? hasta) => setState(() {
    _desde = desde;
    _hasta = hasta;
    _pagina = 1;
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final tabla = usaTablaHex(c.maxWidth, anchoTablaHistorialHex);
      final filtro = _filtro;
      Widget enCaja(Widget hijo) =>
          SizedBox(height: hexAltoEstado, child: hijo);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: Esp.m,
            runSpacing: Esp.s,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Historial de cambios', style: context.tituloSeccion()),
              FiltroRangoHex(
                desde: _desde,
                hasta: _hasta,
                titulo: 'Cambios a mostrar',
                explicacion: 'Filtra por el día en que se hizo el cambio.',
                alCambiar: _filtrar,
              ),
            ],
          ),
          const SizedBox(height: Esp.xs),
          Text(
            'Quién cambió qué y cuándo. Lo que se elimina también queda aquí.',
            style: context.apagado(),
          ),
          const SizedBox(height: Esp.s),
          ref
              .watch(hexHistorialConfiguracionProvider(filtro))
              .when(
                skipLoadingOnReload: true,
                loading: () => enCaja(const EsqueletoLista()),
                error:
                    (e, _) => enCaja(
                      vistaErrorHex(
                        e,
                        reintentar:
                            () => ref.invalidate(
                              hexHistorialConfiguracionProvider(filtro),
                            ),
                      ),
                    ),
                data:
                    (p) => cajaTablaHex(
                      tabla: tabla,
                      filas: p.filas.length,
                      maximo: widget.altoMaximo,
                      conPaginador: true,
                      lista: _lista(p.filas, p.total, tabla),
                    ),
              ),
        ],
      );
    },
  );

  Widget _lista(
    List<HexConfiguracionEventoEntity> filas,
    int total,
    bool tabla,
  ) {
    final cuerpo = Theme.of(context).textTheme.bodyMedium;
    Widget dosLineas(String arriba, String? abajo, TextStyle? estilo) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(arriba, style: estilo),
        if (abajo != null && abajo.trim().isNotEmpty)
          Text(abajo, style: context.apagado()),
      ],
    );
    return ListadoHex<HexConfiguracionEventoEntity>(
      filas: filas,
      pagina: _pagina,
      total: total,
      tamano: _tamano,
      alCambiarPagina: (n) => setState(() => _pagina = n),
      anchoMinimoTabla: anchoTablaHistorialHex,
      desplazamientoExterno: !tabla,
      vacio: MensajeVacio(
        icono: Icons.history,
        titulo: 'Sin cambios registrados',
        detalle:
            _desde == null
                ? 'Cada cambio de esta sección queda aquí, con quién y cuándo '
                    'lo hizo.'
                : 'No hay cambios en esas fechas.',
      ),
      columnas: [
        BosqueColumn(
          label: 'Cuándo',
          flex: _flexCuando,
          cellBuilder:
              (e) => dosLineas(
                fechaHoraHex(e.audFecha),
                oGuionHex(e.nombreUsuario),
                estiloCifrasHex(cuerpo),
              ),
        ),
        BosqueColumn(
          label: 'Registro',
          flex: _flexRegistro,
          cellBuilder:
              (e) => dosLineas(
                oGuionHex(e.descripcion),
                e.entidadTexto,
                cuerpo?.copyWith(fontWeight: Peso.titulo),
              ),
        ),
        BosqueColumn(
          label: 'Cambio',
          flex: _flexCambio,
          cellBuilder: (e) => dosLineas(_accion(e), e.campoTexto, cuerpo),
        ),
        BosqueColumn(
          label: 'Valores',
          flex: _flexValores,
          cellBuilder:
              (e) => Text(
                oGuionHex(cambioHex(e.valorAnterior, e.valorNuevo)),
                style: estiloCifrasHex(Theme.of(context).textTheme.bodySmall),
              ),
        ),
      ],
      tarjeta: (e) => _TarjetaEventoHex(e, accion: _accion(e)),
    );
  }

  static String _accion(HexConfiguracionEventoEntity e) =>
      e.accionTexto.isEmpty ? e.accion : e.accionTexto;
}

/// Un cambio en el teléfono: la acción, cuándo y quién, el registro, el
/// campo y los valores.
class _TarjetaEventoHex extends StatelessWidget {
  const _TarjetaEventoHex(this.e, {required this.accion});

  final HexConfiguracionEventoEntity e;
  final String accion;

  @override
  Widget build(BuildContext context) {
    final cambio = cambioHex(e.valorAnterior, e.valorNuevo);
    final campo = e.campoTexto?.trim() ?? '';
    final registro = [
      e.entidadTexto,
      e.descripcion ?? '',
    ].where((p) => p.trim().isNotEmpty).join(' · ');
    return TarjetaHex(
      titulo: accion,
      subtitulo: '${fechaHoraHex(e.audFecha)} · ${oGuionHex(e.nombreUsuario)}',
      contenido: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (registro.isNotEmpty) Text(registro),
          if (campo.isNotEmpty) Text(campo, style: context.apagado()),
          if (cambio.isNotEmpty) ...[
            const SizedBox(height: Esp.xs),
            Text(
              cambio,
              style: estiloCifrasHex(Theme.of(context).textTheme.bodySmall),
            ),
          ],
        ],
      ),
    );
  }
}
