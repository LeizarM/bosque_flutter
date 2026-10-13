/// Almacenaje de documentos (`tarc_*`), vista `tmtoDocumento/almacenar`: las
/// cajas del archivo físico, lo que guarda cada una y hasta 3 fotos opcionales. Su tarea
/// principal es contestar «¿en qué sucursal, caja y estante está este documento?».
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/archivo_documental_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/caja_archivo_entity.dart';
import 'package:bosque_flutter/domain/entities/contenido_caja_entity.dart';
import 'package:bosque_flutter/presentation/widgets/archivo-documental/catalogos_archivo.dart';
import 'package:bosque_flutter/presentation/widgets/archivo-documental/comun_archivo.dart';
import 'package:bosque_flutter/presentation/widgets/archivo-documental/detalle_caja.dart';
import 'package:bosque_flutter/presentation/widgets/archivo-documental/dialogos_archivo.dart';
import 'package:bosque_flutter/presentation/widgets/archivo-documental/filtros_archivo.dart';
import 'package:bosque_flutter/presentation/widgets/archivo-documental/paleta_archivo.dart';
import 'package:bosque_flutter/presentation/widgets/archivo-documental/reportes_archivo.dart';
import 'package:bosque_flutter/presentation/widgets/archivo-documental/resumen_archivo.dart';
import 'package:bosque_flutter/presentation/widgets/archivo-documental/tabla_cajas.dart';
import 'package:bosque_flutter/presentation/widgets/precios/cabeza_y_lista.dart';

// Estado local: los filtros y la caja abierta arrancan limpios en cada visita.
final _filtroProvider = StateProvider.autoDispose<FiltroArchivo>((ref) => const FiltroArchivo());
final _cajaAbiertaProvider = StateProvider.autoDispose<int?>((ref) => null);

/// No es autoDispose: una escritura puede terminar con la pantalla ya cerrada.
final _enCursoProvider = StateProvider<Set<int>>((ref) => <int>{});

class ArchivoDocumentalScreen extends ConsumerWidget {
  const ArchivoDocumentalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, r) {
        final compacto = r.maxWidth < anchoMinimoTabla;
        final margen = compacto ? Esp.l : Esp.xl;
        final estado = ref.watch(archivoDocumentalProvider);
        final filtro = ref.watch(_filtroProvider);
        final abierta = ref.watch(_cajaAbiertaProvider);
        final resultados = filtro.aplicar(estado.cajas, estado.contenido);
        final codigosArchivo = [for (final a in estado.archivos) a.codArchivo];
        final codigosEmpresa = [for (final e in estado.empresas) e.codEmpresa];

        final caja = abierta == null ? null : estado.caja(abierta);
        if (caja != null) {
          final coinciden = <int>{
            if (filtro.hayAlgo)
              for (final res in resultados)
                if (res.caja.codCaja == caja.codCaja)
                  for (final l in res.coincidencias) l.codContenido,
          };
          final archivo = estado.archivos.where((a) => a.codArchivo == caja.codArchivo).firstOrNull;
          final sucursal = [
            if ((archivo?.nombreSucursal ?? '').trim().isNotEmpty) archivo!.nombreSucursal!.trim(),
            if ((archivo?.ciudadSucursal ?? '').trim().isNotEmpty) archivo!.ciudadSucursal!.trim(),
          ].join(' · ');
          return PopScope(
            // Atrás cierra primero la caja y vuelve al listado.
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) ref.read(_cajaAbiertaProvider.notifier).state = null;
            },
            child: Scaffold(
              body: DetalleCaja(
                caja: caja,
                lineas: estado.lineasDe(caja.codCaja),
                coinciden: coinciden,
                compacto: compacto,
                margen: margen,
                semillaArchivo: semillaDeArchivo(caja.codArchivo, codigosArchivo),
                semillaEmpresa: (cod) => semillaDeEmpresa(cod, codigosEmpresa),
                sucursal: sucursal.isEmpty ? null : 'Sucursal: $sucursal',
                onVolver: () => ref.read(_cajaAbiertaProvider.notifier).state = null,
                onEditarCaja: () => _fichaCaja(context, ref, compacto: compacto, caja: caja),
                onEliminarCaja: () => _eliminarCaja(context, ref, caja),
                onAgregarLinea: () => _fichaLinea(context, ref, compacto: compacto, codCaja: caja.codCaja),
                onAccionLinea:
                    (l, a) =>
                        a == AccionLinea.editar
                            ? _fichaLinea(context, ref, compacto: compacto, codCaja: caja.codCaja, linea: l)
                            : _eliminarLinea(context, ref, l),
              ),
            ),
          );
        }

        // Las cifras son del archivo elegido en los chips (o de todos).
        final cajasDelArchivo = [
          for (final c in estado.cajas)
            if (filtro.codArchivo == null || c.codArchivo == filtro.codArchivo) c,
        ];

        return Scaffold(
          floatingActionButton:
              compacto
                  ? FloatingActionButton.extended(
                    backgroundColor: tonoDe(context, TonosArchivo.caja).fuerte,
                    foregroundColor: tonoDe(context, TonosArchivo.caja).sobreFuerte,
                    onPressed: () => _fichaCaja(context, ref, compacto: true),
                    icon: const Icon(Icons.add),
                    label: const Text('Nueva caja'),
                  )
                  : null,
          body: CabezaYLista(
            altoCompacto: 480,
            cabeza: [
              Padding(
                padding: EdgeInsets.fromLTRB(margen, Esp.l, margen, Esp.m),
                child: EncabezadoArchivo(
                  compacto: compacto,
                  cargando: estado.cargando,
                  onNueva: () => _fichaCaja(context, ref, compacto: false),
                  onReportes: () => _reportes(context, ref, compacto),
                  onCatalogos: () => _catalogos(context, compacto),
                  onRefrescar: () => ref.read(archivoDocumentalProvider.notifier).cargar(),
                ),
              ),
              if (estado.cargado && estado.cajas.isNotEmpty) ...[
                Padding(
                  padding: EdgeInsets.fromLTRB(margen, 0, margen, Esp.m),
                  child: CifrasArchivo(
                    cajas: cajasDelArchivo,
                    documentos: cajasDelArchivo.fold<int>(0, (s, c) => s + c.lineas),
                    archivos: filtro.codArchivo == null ? estado.archivos.length : 1,
                    compacto: compacto,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(margen, 0, margen, Esp.m),
                  child: ChipsArchivo(
                    archivos: estado.archivos,
                    cajas: estado.cajas,
                    elegido: filtro.codArchivo,
                    onElegir:
                        (cod) =>
                            ref.read(_filtroProvider.notifier).state =
                                cod == null
                                    ? filtro.copyWith(limpiarArchivo: true)
                                    : filtro.copyWith(codArchivo: cod),
                  ),
                ),
              ],
              Padding(
                padding: EdgeInsets.fromLTRB(margen, 0, margen, Esp.m),
                child: FiltrosArchivo(
                  compacto: compacto,
                  filtro: filtro,
                  onFiltro: (f) => ref.read(_filtroProvider.notifier).state = f,
                  tipos: estado.tipos,
                  empresas: estado.empresas,
                ),
              ),
              const Divider(height: 1),
            ],
            lista: _lista(context, ref, estado, resultados, filtro, compacto, margen, codigosArchivo),
          ),
        );
      },
    );
  }

  Widget _lista(
    BuildContext context,
    WidgetRef ref,
    ArchivoDocumentalState estado,
    List<ResultadoCaja> resultados,
    FiltroArchivo filtro,
    bool compacto,
    double margen,
    List<int> codigosArchivo,
  ) {
    if (!estado.cargado && estado.error == null) {
      return EsqueletoLista(filas: 8, altoFila: compacto ? 120 : 68);
    }
    if (!estado.cargado) {
      return Padding(
        padding: EdgeInsets.all(margen),
        child: MensajeError(
          error: estado.error,
          onReintentar: () => ref.read(archivoDocumentalProvider.notifier).cargar(),
        ),
      );
    }
    if (estado.cajas.isEmpty) {
      return const MensajeVacio(
        icono: Icons.inventory_2_outlined,
        titulo: 'Todavía no hay cajas registradas',
        detalle: 'Crea la primera con «Nueva caja», o pide a sistemas la carga inicial de los Excel.',
      );
    }
    if (resultados.isEmpty) {
      return MensajeVacio(
        icono: Icons.search_off,
        titulo: 'Ninguna caja coincide',
        detalle:
            'Prueba con menos palabras o quita filtros: hay ${estado.cajas.length} cajas '
            'con ${documentosLegible(estado.contenido.length)} en el archivo.',
      );
    }

    final enCurso = ref.watch(_enCursoProvider);
    final documentosVistos = resultados.fold<int>(
      0,
      (s, r) => s + (r.filtrada ? r.coincidencias.length : r.lineas.length),
    );
    void accion(ResultadoCaja r, AccionCaja a) {
      switch (a) {
        case AccionCaja.abrir:
          ref.read(_cajaAbiertaProvider.notifier).state = r.caja.codCaja;
        case AccionCaja.editar:
          _fichaCaja(context, ref, compacto: compacto, caja: r.caja);
        case AccionCaja.eliminar:
          _eliminarCaja(context, ref, r.caja);
      }
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(margen, Esp.m, margen, compacto ? 88 : Esp.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (estado.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: Esp.s),
              child: MensajeError(
                error: estado.error,
                compacto: true,
                onReintentar: () => ref.read(archivoDocumentalProvider.notifier).cargar(),
              ),
            ),
          SizedBox(
            height: 2,
            child:
                estado.cargando
                    ? LinearProgressIndicator(color: tonoDe(context, TonosArchivo.caja).fuerte)
                    : null,
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: Esp.s, top: Esp.xs),
            child: Text(
              filtro.hayAlgo
                  ? '${resultados.length} de ${estado.cajas.length} cajas · ${documentosLegible(documentosVistos)} coinciden'
                  : '${estado.cajas.length} cajas · ${documentosLegible(estado.contenido.length)}',
              style: context.apagado(),
            ),
          ),
          Expanded(
            child:
                compacto
                    ? _ListaMovil(
                      filas: resultados,
                      enCurso: enCurso,
                      codigosArchivo: codigosArchivo,
                      onAccion: accion,
                    )
                    : TablaCajas(
                      filas: resultados,
                      enCurso: enCurso,
                      codigosArchivo: codigosArchivo,
                      onAccion: accion,
                    ),
          ),
        ],
      ),
    );
  }

  // ── Acciones ────────────────────────────────────────────────────────────

  Future<void> _fichaCaja(BuildContext context, WidgetRef ref, {required bool compacto, CajaArchivoEntity? caja}) {
    final contenedor = ProviderScope.containerOf(context, listen: false);
    final estado = contenedor.read(archivoDocumentalProvider);
    final repo = contenedor.read(archivoDocumentalRepositoryProvider);
    final alta = caja == null;

    return abrirFicha<void>(
      context,
      compacto: compacto,
      builder:
          (asa) => DialogoCaja(
            editar: caja,
            archivos: estado.archivos,
            codArchivoInicial: contenedor.read(_filtroProvider).codArchivo,
            siguienteNumero: repo.siguienteNumero,
            mostrarAsa: asa,
            onGuardar: (c) async {
              final id = await contenedor.read(archivoDocumentalProvider.notifier).guardarCaja(c);
              if (alta) contenedor.read(_cajaAbiertaProvider.notifier).state = id;
              if (context.mounted) {
                avisar(context, alta ? '${tituloCaja(c)} creada: ya puedes registrar lo que guarda.' : '${tituloCaja(c)} actualizada.');
              }
            },
          ),
    );
  }

  Future<void> _eliminarCaja(BuildContext context, WidgetRef ref, CajaArchivoEntity caja) async {
    final contenedor = ProviderScope.containerOf(context, listen: false);
    final nombre = '${tituloCaja(caja).toLowerCase()} de ${oGuion(caja.nombreArchivo)}';
    if (caja.lineas > 0) {
      mostrarAviso(
        context,
        'La $nombre tiene ${documentosLegible(caja.lineas)}: elimínalos o muévelos a otra caja antes de eliminarla.',
        tono: TonoAviso.aviso,
      );
      return;
    }
    final ok = await confirmar(
      context,
      titulo: 'Eliminar la $nombre',
      detalle:
          caja.fotos > 0
              ? 'La caja está vacía. También se eliminan sus ${caja.fotos} fotos.'
              : 'La caja está vacía y no tiene fotos.',
      textoConfirmar: 'Eliminar caja',
      destructiva: true,
    );
    if (!ok || !context.mounted) return;

    final marca = contenedor.read(_enCursoProvider.notifier);
    marca.state = {...marca.state, caja.codCaja};
    try {
      await contenedor.read(archivoDocumentalProvider.notifier).eliminarCaja(caja.codCaja);
      contenedor.read(_cajaAbiertaProvider.notifier).state = null;
      if (context.mounted) avisar(context, 'Se eliminó la $nombre.');
    } catch (e) {
      if (context.mounted) mostrarAviso(context, textoParaUsuario(e), tono: TonoAviso.error);
    } finally {
      marca.state = {...marca.state}..remove(caja.codCaja);
    }
  }

  Future<void> _fichaLinea(
    BuildContext context,
    WidgetRef ref, {
    required bool compacto,
    required int codCaja,
    ContenidoCajaEntity? linea,
  }) {
    final contenedor = ProviderScope.containerOf(context, listen: false);
    final estado = contenedor.read(archivoDocumentalProvider);
    return abrirFicha<void>(
      context,
      compacto: compacto,
      builder:
          (asa) => DialogoContenido(
            editar: linea,
            codCaja: codCaja,
            cajas: estado.cajas,
            tipos: estado.tipos,
            empresas: estado.empresas,
            mostrarAsa: asa,
            onGuardar: (l) async {
              await contenedor.read(archivoDocumentalProvider.notifier).guardarContenido(l);
              if (context.mounted) {
                final movida = linea != null && l.codCaja != linea.codCaja;
                avisar(
                  context,
                  linea == null
                      ? 'Documento agregado.'
                      : (movida ? 'Documento movido a otra caja.' : 'Documento actualizado.'),
                );
              }
            },
          ),
    );
  }

  Future<void> _eliminarLinea(BuildContext context, WidgetRef ref, ContenidoCajaEntity linea) async {
    final contenedor = ProviderScope.containerOf(context, listen: false);
    final ok = await confirmar(
      context,
      titulo: 'Eliminar el documento',
      detalle: '«${linea.detalle}» deja de figurar en la caja. Queda archivado en el historial de la base.',
      textoConfirmar: 'Eliminar documento',
      destructiva: true,
    );
    if (!ok || !context.mounted) return;
    try {
      await contenedor.read(archivoDocumentalProvider.notifier).eliminarContenido(linea.codContenido);
      if (context.mounted) avisar(context, 'Documento eliminado.');
    } catch (e) {
      if (context.mounted) mostrarAviso(context, textoParaUsuario(e), tono: TonoAviso.error);
    }
  }

  Future<void> _catalogos(BuildContext context, bool compacto) => abrirFicha<void>(
    context,
    compacto: compacto,
    anchoMaximo: 720,
    builder: (asa) => CatalogosArchivo(mostrarAsa: asa),
  );

  Future<void> _reportes(BuildContext context, WidgetRef ref, bool compacto) {
    final contenedor = ProviderScope.containerOf(context, listen: false);
    final estado = contenedor.read(archivoDocumentalProvider);
    final repo = contenedor.read(archivoDocumentalRepositoryProvider);
    return abrirFicha<void>(
      context,
      compacto: compacto,
      builder:
          (asa) => ReportesArchivo(
            archivos: estado.archivos,
            tipos: estado.tipos,
            empresas: estado.empresas,
            filtroInicial: contenedor.read(_filtroProvider),
            generar: repo.generarReporte,
            ver: contenedor.read(visorPdfArchivoProvider),
            mostrarAsa: asa,
          ),
    );
  }
}

/// En teléfono las tarjetas llegan de a tandas, sin paginador con números.
class _ListaMovil extends StatefulWidget {
  const _ListaMovil({
    required this.filas,
    required this.enCurso,
    required this.codigosArchivo,
    required this.onAccion,
  });

  final List<ResultadoCaja> filas;
  final Set<int> enCurso;
  final List<int> codigosArchivo;
  final void Function(ResultadoCaja fila, AccionCaja accion) onAccion;

  @override
  State<_ListaMovil> createState() => _ListaMovilState();
}

class _ListaMovilState extends State<_ListaMovil> {
  static const _tanda = 20;
  int _visibles = _tanda;

  @override
  void didUpdateWidget(_ListaMovil anterior) {
    super.didUpdateWidget(anterior);
    if (anterior.filas.length != widget.filas.length) _visibles = _tanda;
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.filas.length;
    final hasta = _visibles.clamp(0, total);
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: hasta + 1,
      itemBuilder: (context, i) {
        if (i == hasta) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: Esp.m),
            child: Center(
              child:
                  hasta < total
                      ? FilledButton.tonalIcon(
                        style: estiloTonal(context, TonosArchivo.caja),
                        onPressed: () => setState(() => _visibles += _tanda),
                        icon: const Icon(Icons.expand_more, size: 18),
                        label: Text('Mostrar más (${total - hasta} restantes)'),
                      )
                      : Text(total == 1 ? '1 caja' : '$total cajas', style: context.apagado()),
            ),
          );
        }
        final f = widget.filas[i];
        return TarjetaCaja(
          fila: f,
          ocupado: widget.enCurso.contains(f.caja.codCaja),
          codigosArchivo: widget.codigosArchivo,
          onAccion: (a) => widget.onAccion(f, a),
        );
      },
    );
  }
}
