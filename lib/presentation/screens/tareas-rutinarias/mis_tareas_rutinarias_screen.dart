// Destino final: lib/presentation/screens/tareas-rutinarias/mis_tareas_rutinarias_screen.dart
import 'package:bosque_flutter/core/constants/tareas_a_requerimiento.dart';
import 'package:bosque_flutter/core/constants/tareas_breakpoints.dart';
import 'package:bosque_flutter/core/state/bit_tarea_ruti_provider.dart';
import 'package:bosque_flutter/core/state/dependientes_jefe_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/theme/tareas_colors.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/cerrar_ruta.dart';
import 'package:bosque_flutter/domain/entities/bit_tarea_ruti_entity.dart';
import 'package:bosque_flutter/presentation/screens/estructura-organizacional/tareas_rutinarias_catalogo_screen.dart';
import 'package:bosque_flutter/presentation/widgets/shared/permission_widget.dart';
import 'package:bosque_flutter/presentation/widgets/tareas-rutinarias/tarea_pendiente_tile.dart';
import 'package:bosque_flutter/core/theme/tareas_tema.dart';
import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/dio_client.dart';
import 'package:bosque_flutter/core/ui/visor_pdf.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/presentation/widgets/tareas-rutinarias/pagina_tareas.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bosque_flutter/presentation/widgets/tareas-rutinarias/tabla_modulo.dart';
import 'package:bosque_flutter/core/utils/formatear_fecha.dart';

/// Reemplaza al wizard único "Tareas.xhtml" del sistema legacy: ahí un mismo
/// bean god-object (`WizardTareas`) mostraba, fila por fila, un botón
/// distinto según `idATR` (tipo de acción) y abría un diálogo embebido
/// distinto por tipo. Aquí se mantiene la misma idea — la fila decide a
/// dónde navega — pero cada destino es su propia pantalla en vez de un
/// diálogo dentro de un formulario de 1800 líneas.
///
/// idBitTarea vive en `dbo.tb_vista` como codVista=78 ("tacTareas/Tareas"):
/// se reutiliza esa vista/ACL en vez de crear una nueva, así los 134
/// usuarios que ya tienen acceso hoy lo conservan sin que Marcelo tenga que
/// tocar `tb_vistaUsuario`.
class MisTareasRutinariasScreen extends ConsumerStatefulWidget {
  const MisTareasRutinariasScreen({super.key});

  @override
  ConsumerState<MisTareasRutinariasScreen> createState() =>
      _MisTareasRutinariasScreenState();
}

class _MisTareasRutinariasScreenState
    extends ConsumerState<MisTareasRutinariasScreen> {
  // Esta pantalla muestra SOLO lo que falta hacer.
  //
  // Antes tenia tres filtros de estado (Pendientes / Respondidas / Todas). Se
  // fueron los dos ultimos a pedido de Marcelo (2026-09-08): una tarea ya
  // respondida no vuelve a tocarse, y con las diarias generandose todos los
  // dias el historial solo le come lugar a lo que si hay que hacer hoy.
  //
  // El historial completo no se perdio: vive en el PDF (RptTareaXDia), que es
  // el boton del PDF de esta misma barra. **Es tambien el unico lugar donde se
  // puede verificar una respuesta ya dada**: desde aca, una tarea respondida
  // por error ya no se ve ni se corrige.

  /// Frecuencia elegida (`tac_frecuencia.idFrec`), o `null` para todas.
  ///
  /// Marcelo lo pidió mirando su propia lista: 28 pendientes mezclando diarias
  /// que hay que hacer hoy con mensuales que vencen en tres semanas. El filtro
  /// de estado no separa eso — las dos son "pendiente".
  int? _frecuencia;

  /// idBitTarea que está guardándose ahora mismo, para dejar inertes sus tres
  /// botones y no mandar dos escrituras de la misma tarea con dos clicks.
  int? _guardandoId;

  bool _generandoPdf = false;

  /// Descarga el historial de tareas rutinarias en PDF — RptTareaXDia del
  /// legacy (`WizardTareas.prepararTareaRutinariaXEmpleado`), el único reporte
  /// propio de este módulo que faltaba migrar.
  ///
  /// Sin `codEmpleado` en el body: el backend lo resuelve del JWT. Pedir el de
  /// otra persona existe en el endpoint pero exige el botón `btnEmpAll`, y esa
  /// pantalla todavía no está construida — desde aquí siempre es el propio.
  Future<void> _descargarReporte() async {
    if (_generandoPdf) return;
    setState(() => _generandoPdf = true);
    try {
      final bytes = await DioClient.descargarReportePdf(
        endpoint: AppConstants.tarMisTareasReportePdf,
        // El historial completo de alguien con años de antigüedad recorre
        // muchas filas; los 30 s del BaseOptions no siempre alcanzan.
        receiveTimeout: const Duration(minutes: 2),
      );
      if (!mounted) return;
      HapticFeedback.selectionClick();
      await mostrarPdf(
        context,
        bytes: bytes,
        titulo: 'Mis tareas rutinarias',
        nombreArchivo: 'tareas_rutinarias.pdf',
      );
    } catch (_) {
      if (!mounted) return;
      HapticFeedback.lightImpact();
      mostrarAviso(
        context,
        'No se pudo generar el reporte.',
        tono: TonoAviso.error,
      );
    } finally {
      if (mounted) setState(() => _generandoPdf = false);
    }
  }

  Future<void> _navegarPorTipo(
    BuildContext context,
    BitTareaRutiEntity tarea,
  ) async {
    // fueRealizado==12 es "en curso"/pendiente de hacer (ver hallazgo de
    // WizardTareas.xhtml: los botones de Arqueo/Coches se deshabilitan
    // cuando fueRealizado!=12). Ya completada, no se vuelve a navegar: lo
    // que queda es agregarle una observación (y en el arqueo, ver su PDF).
    if (tarea.fueRealizado == 13) {
      mostrarAviso(
        context,
        'Esta tarea ya está hecha. Solo puedes agregarle una observación.',
        tono: TonoAviso.aviso,
      );
      return;
    }

    // Los flujos a requerimiento (Caja Fuerte, Coches, Caja Chica) ya no llegan
    // hasta aquí: perteneceAMiLista los deja fuera de la lista.
    //
    // Los case 4/6/7 quedan por si alguien da de alta una tarea NUEVA de ese
    // tipo desde el ABM: esa sí la seguiría generando el Job (no estaría marcada
    // esARequerimiento) y tiene que poder abrirse desde la lista.
    final String ruta;
    final Map<String, Object?> extra;
    switch (tarea.idATR) {
      case 6:
        ruta = '/dashboard/tacTareas/Coches';
        extra = {
          'idTarRuti': tarea.idTarRuti,
          'idBitTarea': tarea.idBitTarea,
          'nombreTarea': tarea.nombreTareaRutinaria ?? 'Coches',
        };
        break;
      case 4:
        ruta = '/dashboard/tacTareas/CajaFuerte';
        extra = {
          'idTarRuti': tarea.idTarRuti,
          'idBitTarea': tarea.idBitTarea,
          'nombreTarea': tarea.nombreTareaRutinaria ?? 'Caja Fuerte',
        };
        break;
      case 2:
        ruta = '/dashboard/tacTareas/ArqueoCaja';
        extra = {
          'idTarRuti': tarea.idTarRuti,
          'idBitTarea': tarea.idBitTarea,
          'nombreTarea': tarea.nombreTareaRutinaria ?? 'Arqueo de Caja',
        };
        break;
      case 7:
        ruta = '/dashboard/tacTareas/CajaChica';
        extra = {
          'idBitTarea': tarea.idBitTarea,
          'nombreTarea': tarea.nombreTareaRutinaria ?? 'Caja Chica',
        };
        break;
      case 3:
        // La misma revisión del día que la tarea 39, pero cerrando SU
        // ocurrencia: "Verficar Arqueo de Caja" y las de Cierre de Operaciones
        // que quedaron pendientes. Desde el archivo SQL 63 no hay otra ruta.
        ruta = '/dashboard/tacTareas/VerificarCierre';
        extra = {
          'idBitTarea': tarea.idBitTarea,
          'nombreTarea': tarea.nombreTareaRutinaria ?? 'Cierre de Operaciones',
          // La revisión abre en el día de la ocurrencia, no en hoy.
          'fecha': tarea.fechaPresentacion,
          'modo': 'cierre',
        };
        break;
      case 12:
        ruta = '/dashboard/tacTareas/TraspasoCajaAxa';
        extra = {
          'idBitTarea': tarea.idBitTarea,
          'nombreTarea':
              tarea.nombreTareaRutinaria ?? 'Verificar traspaso Caja AXA',
          'fecha': tarea.fechaPresentacion,
        };
        break;
      case 5:
        ruta = '/dashboard/tacTareas/VerificarCierre';
        extra = {
          'idBitTarea': tarea.idBitTarea,
          'fecha': tarea.fechaPresentacion,
          'nombreTarea':
              tarea.nombreTareaRutinaria ?? 'Verificar Cierre de Operaciones',
        };
        break;
      case 11:
        // Verificar Traspaso de Efectivo Entre Sistemas: TesBase
        // (ttes_TesBase, tesorería), NO tac_traspasoMovCaja. La de Caja AXA es
        // el case 12, arriba. Los nombres se parecen tanto que ya se
        // confundieron una vez — ver el archivo SQL 51.
        ruta = '/dashboard/tacTareas/TraspasoEfectivoTesBase';
        extra = {
          'idBitTarea': tarea.idBitTarea,
          'nombreTarea':
              tarea.nombreTareaRutinaria ??
              'Verificar traspaso de efectivo entre sistemas',
          'fecha': tarea.fechaPresentacion,
        };
        break;
      case 8:
      case 9:
      case 10:
        // Planilla de Incapacidad y Evaluación Gerencia (Actas): viven en
        // subsistemas fuera del alcance de esta migración.
        mostrarAviso(
          context,
          'Este tipo de tarea se gestiona todavía desde el sistema anterior.',
          tono: TonoAviso.aviso,
        );
        return;
      default:
        // Tarea simple: no navega a ningún lado. Se responde con los tres
        // botones de su propia tarjeta (ver [_marcarSimple]), así que la
        // tarjeta ni siquiera le pasa un onTap — este caso solo existe por si
        // llega un idATR desconocido.
        return;
    }

    await context.push(ruta, extra: extra);

    // Al volver, la lista se lee de nuevo. Sin esto, la tarea recién hecha
    // seguía apareciendo como pendiente (el provider sigue vivo mientras esta
    // pantalla está debajo en la pila) y su botón la abría otra vez: así se
    // grababa un segundo arqueo para la misma tarea (Marcelo, 2026-10-05: "una
    // vez que realiza esas tareas que ya no la vuelva hacer").
    if (mounted) await ref.read(bitTareaRutiProvider.notifier).cargar();
  }

  /// idBitTarea cuyo PDF de arqueo se está generando.
  int? _pdfArqueoDe;

  /// El PDF del arqueo ya hecho: lo único, además de una observación, que se
  /// puede pedir de esa tarea. El servidor busca el arqueo por la tarea.
  Future<void> _verPdfArqueo(BitTareaRutiEntity tarea) async {
    if (_pdfArqueoDe != null) return;
    setState(() => _pdfArqueoDe = tarea.idBitTarea);
    try {
      final bytes = await DioClient.descargarReportePdf(
        endpoint: AppConstants.tarArqueoCajaReportePdf,
        data: {'idBitTarea': tarea.idBitTarea},
      );
      if (!mounted) return;
      final fecha = tarea.fechaPresentacion;
      await mostrarPdf(
        context,
        bytes: bytes,
        titulo: 'Arqueo de caja',
        nombreArchivo:
            fecha == null
                ? 'arqueo_caja.pdf'
                : 'arqueo_caja_${FormatearFecha.formatearFecha(fecha).replaceAll('/', '-')}.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      HapticFeedback.lightImpact();
      final motivo = e.toString().replaceFirst('Exception: ', '').trim();
      mostrarAviso(
        context,
        motivo.isEmpty ? 'No se pudo generar el PDF del arqueo.' : motivo,
        tono: TonoAviso.error,
      );
    } finally {
      if (mounted) setState(() => _pdfArqueoDe = null);
    }
  }

  /// Agregar una observación a una tarea ya hecha. Se agrega, no se reemplaza:
  /// lo que ya tenía se muestra arriba, de solo lectura.
  Future<void> _agregarObservacion(BitTareaRutiEntity tarea) async {
    final agregada = await showDialog<bool>(
      context: context,
      builder: (_) => _DialogoObservacion(tarea: tarea),
    );
    if (agregada == true && mounted) {
      HapticFeedback.selectionClick();
      mostrarAviso(context, 'Observación agregada.', tono: TonoAviso.exito);
    }
  }

  /// Responde una tarea simple desde su propia tarjeta.
  ///
  /// Reemplaza al `AlertDialog` "¿Se realizó esta tarea?": abrirlo, leerlo,
  /// elegir y esperar el cierre costaba cuatro interacciones por tarea, y las
  /// tareas simples se responden de a muchas seguidas. Aquí es una sola
  /// pulsación y la tarjeta se actualiza en el lugar, sin sacar a nadie de la
  /// lista ni perder la posición del scroll.
  ///
  /// No pide confirmación a propósito: la respuesta es reversible con otra
  /// pulsación (los tres botones quedan a la vista con el elegido relleno), y
  /// pedir "¿seguro?" por cada una devolvería el problema que este cambio
  /// vino a resolver.
  Future<void> _marcarSimple(BitTareaRutiEntity tarea, int fueRealizado) async {
    if (_guardandoId != null) return;
    setState(() => _guardandoId = tarea.idBitTarea);
    final codUsuario = ref.read(userProvider)?.codUsuario ?? 0;
    final ok = await ref
        .read(bitTareaRutiProvider.notifier)
        .guardar(
          tarea.copyWith(fueRealizado: fueRealizado, audUsuario: codUsuario),
        );
    if (!mounted) return;
    setState(() => _guardandoId = null);
    if (ok) {
      HapticFeedback.selectionClick(); // marcar de a muchas: toque liviano
    } else {
      HapticFeedback.lightImpact(); // rechazo, nunca heavyImpact
      // El motivo real viaja entero desde el procedimiento: @errormsg →
      // respuestaEscritura (400 con ese texto) → postAndReturnId, que conserva
      // response.data['message'] → mensajeError. Hasta aquí llegaba bien y la
      // pantalla lo tiraba, mostrando siempre la misma frase. Importa ahora que
      // hay rechazos con causa —plazo vencido, ocurrencia ajena—: un candado
      // que no dice por qué cierra es peor que no tenerlo.
      final motivo =
          ref
              .read(bitTareaRutiProvider)
              .mensajeError
              ?.replaceFirst('Exception: ', '')
              .trim();
      mostrarAviso(
        context,
        motivo == null || motivo.isEmpty
            ? 'No se pudo actualizar la tarea.'
            : motivo,
        tono: TonoAviso.error,
      );
    }
  }

  /// Agrupa en Vencidas / Pendientes, lo más urgente siempre arriba y sin
  /// importar cómo esté ordenada la lista de entrada. Solo agrega un
  /// encabezado si el grupo tiene algo.
  /// Entrada suave y acotada — fade + deslizamiento corto, sin
  /// AnimationController propio: TweenAnimationBuilder resuelve una sola vez
  /// por ítem insertado y se queda en su valor final ante cualquier rebuild.
  Widget _tarjetaAnimada(
    BitTareaRutiEntity t,
    int indiceFila, {
    bool compacta = false,
  }) {
    return TweenAnimationBuilder<double>(
      key: ValueKey('tarea-${t.idBitTarea}'),
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 200 + (indiceFila.clamp(0, 8) * 20)),
      curve: Curves.easeOut,
      builder:
          (context, valor, child) => Opacity(
            opacity: valor,
            child: Transform.translate(
              offset: Offset(0, (1 - valor) * 8),
              child: child,
            ),
          ),
      child: Builder(
        builder:
            (context) => TareaPendienteTile(
              tarea: t,
              onTap: () => _navegarPorTipo(context, t),
              onMarcar: (valor) => _marcarSimple(t, valor),
              onObservacion: () => _agregarObservacion(t),
              onVerPdf: t.idATR == 2 ? () => _verPdfArqueo(t) : null,
              generandoPdf: _pdfArqueoDe == t.idBitTarea,
              guardando: _guardandoId == t.idBitTarea,
              compacta: compacta,
            ),
      ),
    );
  }

  /// Reagrupa la lista plana de [_agruparPorUrgencia] (encabezados y tareas
  /// mezclados) en filas de grilla: cada encabezado queda solo en su fila, y
  /// las tareas que le siguen se juntan de a [columnas].
  ///
  /// Se hace aquí y no con un SliverGrid porque los encabezados y las tarjetas
  /// se intercalan: un SliverGrid necesitaria un sliver por grupo y romperia
  /// el ListView.builder unico que ya sostiene el scroll y las animaciones de
  /// entrada. Con `columnas == 1` devuelve grupos de a uno, o sea exactamente
  /// el comportamiento de siempre en telefono.
  List<Object> _enFilasDe(List<Object> planas, int columnas) {
    final filas = <Object>[];
    var pendientes = <_Fila>[];

    void volcar() {
      for (var i = 0; i < pendientes.length; i += columnas) {
        final hasta =
            (i + columnas) < pendientes.length
                ? i + columnas
                : pendientes.length;
        filas.add(pendientes.sublist(i, hasta));
      }
      pendientes = <_Fila>[];
    }

    for (final fila in planas) {
      if (fila is _Encabezado) {
        volcar();
        filas.add(fila);
      } else {
        pendientes.add(fila as _Fila);
      }
    }
    volcar();
    return filas;
  }

  List<Object> _agruparPorUrgencia(
    List<BitTareaRutiEntity> items,
    List<BitTareaRutiEntity> hechas,
  ) {
    // Las vencidas ya no llegan aquí: se filtran en [porResponder] (Marcelo,
    // 2026-10-05: "estas tareas que ya vencieron que no se muestren, en
    // reporte se verá que no cumplió"). Los encabezados se conservan porque
    // la planilla de escritorio se arma a partir de ellos.
    //
    // "Hechas" va abajo: son las de pantalla propia ya completadas y todavía
    // en su plazo, que solo admiten una observación y, el arqueo, su PDF
    // (ver [hechaEnPlazo]).
    return [
      if (items.isNotEmpty) ...[
        _Encabezado(
          'Pendientes',
          Icons.schedule_outlined,
          TareasColors.pendienteTexto,
          items.length,
        ),
        ...items.map(_Fila.new),
      ],
      if (hechas.isNotEmpty) ...[
        _Encabezado(
          'Hechas',
          Icons.task_alt,
          TareasColors.realizadoTexto,
          hechas.length,
        ),
        ...hechas.map(_Fila.new),
      ],
    ];
  }

  /// Lo que se busca con la mirada al entrar: cuántas quedan por responder y,
  /// si hay, cuántas vencieron sin responder. Esas ya no están en la lista
  /// —no se pueden responder— pero se cuentan: si no, quien tiene cuarenta
  /// vencidas y ninguna pendiente leería "Estás al día". Mientras no se leyó,
  /// nada: un "0 pendientes" provisorio se lee como "estás al día".
  String? _resumenEncabezado(bool cargado, int pendientes, int vencidas) {
    if (!cargado) return null;
    final partes = [
      if (pendientes > 0)
        pendientes == 1 ? '1 pendiente' : '$pendientes pendientes',
      if (vencidas > 0)
        vencidas == 1
            ? '1 venció sin responder'
            : '$vencidas vencieron sin responder',
    ];
    return partes.isEmpty ? 'Estás al día' : partes.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bitTareaRutiProvider);
    final notifier = ref.read(bitTareaRutiProvider.notifier);
    final miCodEmpleado = ref.watch(userProvider)?.codEmpleado;

    // El listado es genérico (mismo endpoint que usaría un supervisor viendo
    // todo el organigrama); aquí se filtra del lado del cliente a "las mías",
    // igual que el resto de listados operativos de esta app (multas,
    // talonarios, etc. tampoco segmentan por usuario en el backend). Qué
    // cuenta como "mía" está en [perteneceAMiLista].
    final mias =
        state.items.where((t) => perteneceAMiLista(t, miCodEmpleado)).toList();

    // Lo unico que llega a la pantalla: lo que falta hacer y TODAVIA se puede
    // hacer. Las vencidas sin responder solo se cuentan (ver [porResponder]).
    final hoy = DateTime.now();
    final porHacer = mias.where((t) => porResponder(t, hoy)).toList();
    final vencidasSinResponder =
        mias.where(_sinResponder).length - porHacer.length;

    // Las que ya se hicieron y siguen en su plazo: quedan a la vista solo para
    // lo que todavía admiten (ver [hechaEnPlazo]).
    final hechas = mias.where((t) => hechaEnPlazo(t, hoy)).toList();

    // Las frecuencias que esta persona REALMENTE tiene pendientes, con su
    // conteo. No se ofrecen las seis del catálogo: un chip "Bimestral (0)" es
    // una promesa vacía.
    final porFrecuencia = <int, int>{};
    for (final t in porHacer) {
      if (t.idFrec != null) {
        porFrecuencia[t.idFrec!] = (porFrecuencia[t.idFrec!] ?? 0) + 1;
      }
    }
    final frecuenciasPresentes =
        porFrecuencia.keys.toList()..sort((a, b) {
          // Orden por urgencia real, no por id: diario primero, anual último.
          const orden = {6: 0, 2: 1, 1: 2, 4: 3, 5: 4, 3: 5};
          return (orden[a] ?? 9).compareTo(orden[b] ?? 9);
        });

    // Si la frecuencia elegida se quedo sin tareas —se respondio la ultima
    // diaria— se vuelve sola a "Todas", en vez de mostrar una lista vacia con
    // un chip marcado que ya no se puede desmarcar.
    final frecuenciaActiva =
        (_frecuencia != null && porFrecuencia.containsKey(_frecuencia))
            ? _frecuencia
            : null;

    final propias =
        porHacer
            .where((t) => frecuenciaActiva == null || t.idFrec == frecuenciaActiva)
            .toList()
          ..sort((a, b) {
          final fa = a.fechaPresentacion ?? DateTime(2100);
          final fb = b.fechaPresentacion ?? DateTime(2100);
          return fa.compareTo(fb);
        });

    // Antes era una sola lista plana, ordenada solo por fecha — con varias
    // "Vencida" seguidas se leía como una pared roja sin estructura. Agrupar
    // por urgencia real (vencidas primero, siempre) le da al ojo un punto de
    // entrada: "esto ya" vs "esto viene" vs "esto ya quedó atrás".
    final hechasVisibles =
        hechas
            .where(
              (t) => frecuenciaActiva == null || t.idFrec == frecuenciaActiva,
            )
            .toList()
          ..sort((a, b) {
            final fa = a.fechaPresentacion ?? DateTime(2100);
            final fb = b.fechaPresentacion ?? DateTime(2100);
            return fa.compareTo(fb);
          });
    final filas = _agruparPorUrgencia(propias, hechasVisibles);


    return TareasScope(
      // El ancho del cajón decide si "Mi equipo" lleva su nombre o solo el
      // icono: el sidebar del dashboard se come 260 px.
      child: LayoutBuilder(
        builder: (context, cajon) => Scaffold(
        appBar: AppBarTareas(
          titulo: 'Mis tareas rutinarias',
          subtitulo: _resumenEncabezado(
            state.cargado,
            porHacer.length,
            vencidasSinResponder,
          ),
          insignia: InsigniaTarea.modulo(context, Icons.checklist_rtl),
          acciones: [
            // "Mi equipo" dejó de ser un ítem del menú (archivo SQL 59) y un
            // botón flotante: va aquí, y solo para quien puede usarlo.
            _BotonMiEquipo(conTexto: !Aire.de(cajon.maxWidth).esChico),
            // Mismo botón/permiso que ya gatea el catálogo desde Estructura
            // Organizacional (cargos_screen.dart) — aquí solo se agrega un
            // segundo acceso directo, sin tb_vista ni endpoint nuevo, para
            // quien lo tenga concedido no tenga que salir del módulo Tareas
            // para llegar a "Tareas Rutinarias por Cargo" (hallazgo de
            // Marcelo, 2026-09-07: "no veo la parte de abm... en el mismo
            // modulo").
            PermissionWidget(
              buttonName: 'btnTareasRutXCargo',
              child: IconButton(
                tooltip: 'Tareas rutinarias por cargo',
                icon: const Icon(Icons.assignment_outlined),
                onPressed: () {
                  final codEmpresa = ref.read(userProvider)?.codEmpresa ?? 0;
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder:
                          (_) => TareasRutinariasCatalogoScreen(
                            codEmpresa: codEmpresa,
                          ),
                    ),
                  );
                },
              ),
            ),
            IconButton(
              tooltip: 'Descargar mi historial en PDF',
              icon:
                  _generandoPdf
                      ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.picture_as_pdf_outlined),
              onPressed: _generandoPdf ? null : _descargarReporte,
            ),
            PermissionWidget(
              buttonName: 'btnEmpAll',
              child: IconButton(
                tooltip: 'Ver de todos los empleados',
                icon: const Icon(Icons.groups_outlined),
                onPressed:
                    () => mostrarAviso(
                      context,
                      'El reporte por todos los empleados está en construcción.',
                      tono: TonoAviso.aviso,
                    ),
              ),
            ),
          ],
          // Ya no hay filtros de ESTADO: la pantalla es "lo que falta hacer"
          // y punto. Queda solo el de frecuencia, y solo si hay mas de una.
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(
              frecuenciasPresentes.length > 1 ? 44 : 0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // La fila de frecuencia solo aparece si hay más de una: con
                // todas las tareas diarias, un único chip "Diario" no filtra
                // nada y solo roba una franja de pantalla.
                if (frecuenciasPresentes.length > 1)
                  SizedBox(
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: [
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: Text(
                              'Frecuencia',
                              style: Theme.of(
                                context,
                              ).textTheme.labelMedium?.copyWith(
                                color:
                                    Theme.of(context).appBarTheme.foregroundColor
                                        ?.withValues(alpha: 0.7) ??
                                    Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                        Center(
                          child: ChoiceChip(
                            selected: frecuenciaActiva == null,
                            onSelected:
                                (_) => setState(() => _frecuencia = null),
                            showCheckmark: false,
                            label: const Text('Todas'),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                        const SizedBox(width: 8),
                        for (final id in frecuenciasPresentes) ...[
                          Center(
                            child: ChoiceChip(
                              selected: frecuenciaActiva == id,
                              // Volver a tocar el chip elegido lo desmarca:
                              // sin eso habría que ir hasta "Todas" para
                              // deshacer, que es un viaje de ida y vuelta por
                              // una fila que puede estar scrolleada.
                              onSelected:
                                  (elegido) => setState(
                                    () => _frecuencia = elegido ? id : null,
                                  ),
                              showCheckmark: false,
                              visualDensity: VisualDensity.compact,
                              backgroundColor: TareasColors.frecuencia(
                                context,
                                id,
                              ),
                              label: Text(
                                '${TareaPendienteTile.nombreFrecuencia[id] ?? 'Otra'}'
                                ' (${porFrecuencia[id]})',
                                style: TextStyle(
                                  color:
                                      frecuenciaActiva == id
                                          ? null
                                          : TareasColors.frecuenciaTexto(
                                            context,
                                            id,
                                          ),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        body: LayoutBuilder(
          builder: (context, cajon) {
            // El ancho del cajón y no el de la ventana: el sidebar del
            // dashboard se come 260 px, y con MediaQuery la planilla
            // aparecía cuando ya no entraba.
            final anchoDisponible = cajon.maxWidth;
            final columnas = TareasBreakpoints.columnasLista(anchoDisponible);
            final filasGrilla = _enFilasDe(filas, columnas);
            final esTabla = anchoDisponible >= TareasBreakpoints.splitMin;
            return RefreshIndicator(
          onRefresh: notifier.cargar,
          // AnimatedSwitcher: pasar de "cargando" a la lista (o al vacío) es un
          // cambio de estado real — un cross-fade evita el salto seco que se
          // siente como que la pantalla "parpadeó" en vez de haber cargado.
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child:
                !state.cargado
                    ? (state.cargando
                        ? const Center(
                          key: ValueKey('cargando'),
                          child: CircularProgressIndicator(),
                        )
                        // Un error de lectura no es "no tienes tareas".
                        : EstadoTareas.error(
                          key: const ValueKey('error'),
                          titulo: 'No se pudieron leer tus tareas',
                          error: state.errorCarga,
                          onReintentar: notifier.cargar,
                        ))
                    : filas.isEmpty
                    ? _EstadoVacio(
                      key: const ValueKey('vacio'),
                      // "Estas al dia" solo si REALMENTE tiene tareas y las respondio
                      // todas. A quien nunca le asignaron ninguna hay que
                      // decirle eso, no felicitarlo.
                      tieneAsignadas: mias.isNotEmpty,
                      vencidas: vencidasSinResponder,
                    )
                    : esTabla
                    // En una resolucion de escritorio esto es una planilla de
                    // pendientes: una fila por tarea, la respuesta siempre en
                    // la misma columna. Como tarjetas, los tres botones caian
                    // en una posicion distinta en cada una y responder treinta
                    // era perseguir el boton por la pantalla.
                    ? Padding(
                      key: const ValueKey('tabla'),
                      padding: const EdgeInsets.fromLTRB(
                        Esp.l,
                        Esp.m,
                        Esp.l,
                        Esp.m,
                      ),
                      child: MarcoTabla(
                        child: Column(
                          children: [
                            const EncabezadoTabla(
                              anchos: _anchosTareas,
                              titulos: [
                                'Tarea',
                                'Vence',
                                'Frecuencia',
                                'Respuesta',
                              ],
                            ),
                            Expanded(
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                itemCount: filas.length,
                                itemBuilder: (context, i) {
                                  final fila = filas[i];
                                  if (fila is _Encabezado) {
                                    return _SeparadorGrupo(encabezado: fila);
                                  }
                                  final t = (fila as _Fila).tarea;
                                  return _FilaTablaTarea(
                                    key: ValueKey('tarea-${t.idBitTarea}'),
                                    tarea: t,
                                    rayado: i.isOdd,
                                    guardando: _guardandoId == t.idBitTarea,
                                    onAbrir: () => _navegarPorTipo(context, t),
                                    onMarcar: (valor) => _marcarSimple(t, valor),
                                    onObservacion: () => _agregarObservacion(t),
                                    onVerPdf:
                                        t.idATR == 2
                                            ? () => _verPdfArqueo(t)
                                            : null,
                                    generandoPdf:
                                        _pdfArqueoDe == t.idBitTarea,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    : ListView.builder(
                      key: const ValueKey('lista'),
                      padding: const EdgeInsets.fromLTRB(
                        Esp.xs,
                        Esp.s,
                        Esp.xs,
                        Esp.m,
                      ),
                      itemCount: filasGrilla.length,
                      itemBuilder: (context, i) {
                        final fila = filasGrilla[i];
                        if (fila is _Encabezado) {
                          final color = fila.tono(context);
                          return Padding(
                            padding: EdgeInsets.fromLTRB(
                              16,
                              i == 0 ? 4 : 20,
                              16,
                              8,
                            ),
                            child: Row(
                              children: [
                                Icon(fila.icono, size: 16, color: color),
                                const SizedBox(width: 6),
                                Text(
                                  '${fila.titulo} (${fila.cantidad})',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.labelLarge?.copyWith(
                                    color: color,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        // Una fila de la grilla: entre 1 y `columnas` tarjetas.
                        // Con columnas==1 el Row tiene un solo hijo Expanded, o
                        // sea que en teléfono se comporta igual que antes.
                        final grupo = fila as List<_Fila>;
                        return Row(
                          // start y no stretch: stretch necesita alto acotado y
                          // la unica forma de dárselo seria IntrinsicHeight, que
                          // revienta si una tarjeta trae un LayoutBuilder (ver
                          // el doc de FranjaAcento). Las tarjetas ya salen del
                          // mismo alto porque el título va a una sola línea.
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (var c = 0; c < columnas; c++)
                              Expanded(
                                child:
                                    c < grupo.length
                                        ? _tarjetaAnimada(
                                          grupo[c].tarea,
                                          i,
                                          // Densidad de escritorio en cuanto
                                          // hay más de una columna: es el mismo
                                          // umbral en el que la pantalla deja
                                          // de ser un teléfono.
                                          compacta: columnas > 1,
                                        )
                                        // Relleno para que la última fila
                                        // incompleta no estire sus tarjetas al
                                        // ancho de toda la pantalla.
                                        : const SizedBox.shrink(),
                              ),
                          ],
                        );
                      },
                    ),
          ),
        );
          },
        ),
      ),
      ),
    );
  }
}

/// "Mi equipo": programar tareas rutinarias a los dependientes del cargo.
///
/// Antes era un ítem del menú para los 134 usuarios de la vista 78 y un botón
/// flotante que tapaba la última fila, y la pantalla le explicaba recién
/// adentro a quien no era jefe que no podía usarla. Marcelo (2026-09-11):
/// "muévelo ahí como un botón y que solo te aparezca si el umbral de tu cargo
/// es <=3". Mientras no se sabe, no aparece.
class _BotonMiEquipo extends ConsumerWidget {
  /// Con el nombre al lado del icono. En un cajón angosto, solo el icono.
  final bool conTexto;

  const _BotonMiEquipo({required this.conTexto});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final puede =
        ref.watch(puedeProgramarAMiEquipoProvider).valueOrNull ?? false;
    if (!puede) return const SizedBox.shrink();

    void abrir() => context.push('/dashboard/tacTareas/Dependientes');

    if (!conTexto) {
      return IconButton(
        tooltip: 'Mi equipo',
        icon: const Icon(Icons.supervisor_account_outlined),
        onPressed: abrir,
      );
    }
    return Padding(
      padding: const EdgeInsets.only(right: Esp.xs),
      child: TextButton.icon(
        onPressed: abrir,
        icon: const Icon(Icons.supervisor_account_outlined),
        label: const Text('Mi equipo'),
      ),
    );
  }
}

/// Una fila de tarea dentro de un grupo — wrapper mínimo para que
/// `ListView.builder` distinga tarea vs. encabezado con un solo `is`.
/// Los tres subconjuntos que se pueden mirar en "Mis tareas rutinarias".
///
/// El corte real está en `fueRealizado`, que tiene CUATRO valores y no dos:
/// 12 (o null) sin responder, 13 sí, 0 no, 14 no aplica. El 0 es el que se
/// escapaba: el diálogo viejo guardaba "No" como 0 y el filtro definía
/// pendiente como `!= 13`, así que una tarea ya respondida "No" seguía
/// apareciendo entre las pendientes para siempre. Aquí "pendiente" es lo que
/// de verdad falta responder.
/// Una ocurrencia sin responder.
///
/// `fueRealizado`: 12 (o null) pendiente, 13 si, 0 no, 14 no aplica. El `0`
/// importa y es el que costo un bug: responder "No" tambien es responder, y
/// durante un tiempo se leia como pendiente.
bool _sinResponder(BitTareaRutiEntity t) =>
    t.fueRealizado == null || t.fueRealizado == 12;

/// Si una ocurrencia se muestra en "Mis tareas": sin responder y todavía en
/// plazo.
///
/// Las vencidas no se muestran (Marcelo, 2026-10-05). Es lo que hacía el
/// sistema anterior —las sacaba de la consulta— y lo que pide la regla del
/// plazo (archivo SQL 66): mostrarlas sería ofrecer un botón que el servidor
/// rechaza. El incumplimiento no se pierde: la bitácora de cumplimiento
/// (`p_list_tac_BitTareaRuti` 'B') cuenta toda pendiente con la fecha pasada
/// como "no realizada".
bool porResponder(BitTareaRutiEntity t, DateTime hoy) =>
    _sinResponder(t) && !t.fueraDePlazo(hoy);

/// Si una ocurrencia ya hecha se sigue mostrando, en el grupo "Hechas".
///
/// Solo las de pantalla propia (arqueo, traspasos, revisión del cierre…) y
/// solo mientras dure su plazo: el mismo tiempo que habrían estado como
/// pendientes. Una tarea hecha ya no se vuelve a hacer; lo único que admite es
/// una observación y, el arqueo, ver su PDF (Marcelo, 2026-10-05: "una vez que
/// realiza esas tareas que ya no la vuelva hacer. Máximo agregar una
/// observación"). Las simples no entran: ya muestran su respuesta al
/// responderla y el historial está en el PDF.
bool hechaEnPlazo(BitTareaRutiEntity t, DateTime hoy) =>
    t.fueRealizado == 13 &&
    TareaPendienteTile.tipoDeAccion(t.idATR) != null &&
    !t.fueraDePlazo(hoy);

/// Si una ocurrencia es de la lista de esta persona, respondida o no.
///
/// Cada condición tapa algo que llegó a verse en pantalla:
///
///  * **Es suya.** El listado trae las de toda la empresa. Con `miCodEmpleado`
///    en null —`userProvider` todavía cargando— no entra ninguna: falla
///    cerrado, en vez de dejar tocable la lista del organigrama entero contra
///    un endpoint de escritura (hallazgo de auditoría, 2026-09-07).
///  * **Está activa.** `estado = 0` es como la base cierra sin borrar: los
///    duplicados por renombre de cargo (archivo SQL 52), lo generado después
///    de una baja (38) y las diarias de domingo (67). Nada filtraba esto, y
///    esas filas seguían apareciendo como vencidas. Sin `estado` se muestra:
///    no se esconde una tarea por un dato que falta.
///  * **No es un flujo a requerimiento.** Caja Fuerte, Coches y Caja Chica se
///    abren desde el menú y su ocurrencia se crea al entrar al submódulo. Si el
///    trabajo quedaba a medias, la fila se quedaba aquí como pendiente de un
///    botón que ya no lleva a ningún lado (Marcelo, 2026-09-14). El corte es
///    por idTarRuti, nunca por idATR: ver [TareasARequerimiento].
bool perteneceAMiLista(BitTareaRutiEntity t, int? miCodEmpleado) =>
    miCodEmpleado != null &&
    t.codEmpleado == miCodEmpleado &&
    t.estado != 0 &&
    !TareasARequerimiento.contiene(t.idTarRuti);

class _Fila {
  final BitTareaRutiEntity tarea;
  const _Fila(this.tarea);
}

/// El título de un grupo (Vencidas/Pendientes/Completadas), con su color
/// semántico resuelto recién en `build` (necesita `BuildContext` por el
/// tema claro/oscuro — ver `TareasColors`).
class _Encabezado {
  final String titulo;
  final IconData icono;
  final Color Function(BuildContext) tono;
  final int cantidad;
  const _Encabezado(this.titulo, this.icono, this.tono, this.cantidad);
}

class _EstadoVacio extends StatelessWidget {
  /// `true` = tiene tareas asignadas y ya las respondio todas.
  /// `false` = no le asignaron ninguna todavia.
  ///
  /// "No queda nada por hacer" y "no hay nada" se ven igual y significan
  /// cosas opuestas: la primera es una buena noticia y lleva el tono de
  /// realizado; la segunda es neutra.
  final bool tieneAsignadas;

  /// Las que vencieron sin responder. Con alguna, la pantalla vacía NO es
  /// "Estás al día": no queda nada que se pueda hacer, pero no porque se haya
  /// hecho todo.
  final int vencidas;

  const _EstadoVacio({
    super.key,
    required this.tieneAsignadas,
    this.vencidas = 0,
  });

  @override
  Widget build(BuildContext context) {
    if (vencidas > 0) {
      return EstadoTareas(
        icono: Icons.event_busy_outlined,
        titulo: 'No tienes tareas por responder',
        detalle:
            vencidas == 1
                ? 'Una tarea venció sin responderse. Ya no se puede '
                    'responder y queda en la bitácora como no cumplida.'
                : '$vencidas tareas vencieron sin responderse. Ya no se '
                    'pueden responder y quedan en la bitácora como no '
                    'cumplidas.',
      );
    }
    return tieneAsignadas
        ? const EstadoTareas(
          icono: Icons.task_alt,
          tono: TonoEstadoTareas.listo,
          titulo: 'Estás al día',
          detalle:
              'Respondiste todo lo que tenías. Lo ya respondido queda en el '
              'reporte PDF.',
        )
        : const EstadoTareas(
          icono: Icons.inbox_outlined,
          titulo: 'Todavía no tienes tareas rutinarias',
          detalle: 'Cuando te asignen una, va a aparecer aquí.',
        );
  }
}

/// Los anchos de la planilla de "Mis tareas rutinarias".
const _anchosTareas = <AnchoCol>[
  AnchoCol.flexible(), // tarea
  AnchoCol.fijo(104), // vence
  AnchoCol.fijo(112), // frecuencia
  AnchoCol.fijo(310), // respuesta
];

/// El corte de grupo ("Pendientes (3)") dentro de la planilla.
///
/// Ocupa la fila entera y no una columna: es el unico corte de jerarquia que
/// tiene esta pantalla, y partirlo en columnas lo volveria un dato mas.
class _SeparadorGrupo extends StatelessWidget {
  final _Encabezado encabezado;

  const _SeparadorGrupo({required this.encabezado});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = encabezado.tono(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.7),
        border: Border(
          top: BorderSide(color: scheme.outlineVariant),
          bottom: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          Icon(encabezado.icono, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            '${encabezado.titulo} (${encabezado.cantidad})',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Una tarea como fila de planilla.
class _FilaTablaTarea extends StatelessWidget {
  final BitTareaRutiEntity tarea;
  final bool rayado;
  final bool guardando;
  final VoidCallback onAbrir;
  final void Function(int fueRealizado) onMarcar;

  /// Ya hecha: lo único que admite. Ver [AccionesTareaHecha].
  final VoidCallback onObservacion;
  final VoidCallback? onVerPdf;
  final bool generandoPdf;

  const _FilaTablaTarea({
    super.key,
    required this.tarea,
    required this.rayado,
    required this.guardando,
    required this.onAbrir,
    required this.onMarcar,
    required this.onObservacion,
    this.onVerPdf,
    this.generandoPdf = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Mismo switch que usa la tarjeta: si la tarea abre una pantalla propia,
    // la columna de respuesta es un boton "Abrir" y no los tres de Si/No.
    final tipo = TareaPendienteTile.tipoDeAccion(tarea.idATR);
    final esEspecial = tipo != null;
    final completada = tarea.fueRealizado == 13;
    final idFrec = tarea.idFrec;

    return FilaTabla(
      anchos: _anchosTareas,
      fondo:
          rayado
              ? scheme.surfaceContainerHighest.withValues(alpha: 0.3)
              : null,
      celdas: [
        Row(
          children: [
            if (esEspecial) ...[
              InsigniaTarea.deTipo(context, tarea.idATR, tam: 28),
              const SizedBox(width: Esp.s),
            ],
            Expanded(
              child: Text(
                tarea.nombreTareaRutinaria ?? 'Tarea rutinaria',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  decoration: completada ? TextDecoration.lineThrough : null,
                  decorationColor: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        Text(
          tarea.fechaPresentacion == null
              ? '-'
              : FormatearFecha.formatearFecha(tarea.fechaPresentacion!),
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        idFrec == null
            ? const SizedBox.shrink()
            : Align(
              alignment: Alignment.centerLeft,
              child: PildoraTareas.frecuencia(
                context,
                idFrec,
                TareaPendienteTile.nombreFrecuencia[idFrec] ?? 'Otra',
              ),
            ),
        guardando
            ? const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
            )
            // Hecha: ya no se abre. En lugar del botón de la pantalla, lo único
            // que admite.
            : esEspecial && completada
            ? Align(
              alignment: Alignment.centerLeft,
              child: AccionesTareaHecha(
                onObservacion: onObservacion,
                onVerPdf: onVerPdf,
                generandoPdf: generandoPdf,
              ),
            )
            : esEspecial
            ? Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: onAbrir,
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.open_in_new, size: 16),
                label: Text(tipo.etiqueta),
              ),
            )
            : RespuestaTarea(
              seleccion: tarea.fueRealizado,
              habilitado: !guardando,
              onElegir: onMarcar,
            ),
      ],
    );
  }
}

/// El diálogo "Observación" de una tarea ya hecha.
///
/// Lo que la tarea ya tiene se muestra arriba, de solo lectura: lo nuevo se
/// agrega al final (el servidor le pone fecha y hora), no se edita ni se borra
/// lo anterior. Si el servidor rechaza, el motivo se muestra aquí mismo y el
/// diálogo no se cierra, para no perder lo escrito.
class _DialogoObservacion extends ConsumerStatefulWidget {
  final BitTareaRutiEntity tarea;

  const _DialogoObservacion({required this.tarea});

  @override
  ConsumerState<_DialogoObservacion> createState() =>
      _DialogoObservacionState();
}

class _DialogoObservacionState extends ConsumerState<_DialogoObservacion> {
  final _texto = TextEditingController();
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  Future<void> _agregar() async {
    final obs = _texto.text.trim();
    if (obs.isEmpty) {
      setState(() => _error = 'Escribe la observación que quieres agregar.');
      return;
    }
    setState(() {
      _guardando = true;
      _error = null;
    });
    final motivo = await ref
        .read(bitTareaRutiProvider.notifier)
        .agregarObservacion(widget.tarea.idBitTarea, obs);
    if (!mounted) return;
    if (motivo == null) {
      // cerrarRuta y no pop: el campo tiene el foco y cerrar la ruta con el
      // foco adentro es el error "inactive element: Focus" de la web.
      cerrarRuta(context, true);
      return;
    }
    setState(() {
      _guardando = false;
      _error = motivo;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final scheme = tema.colorScheme;
    final previa = widget.tarea.obs?.trim() ?? '';

    return AlertDialog(
      title: const Text('Agregar observación'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.tarea.nombreTareaRutinaria ?? 'Tarea rutinaria',
                style: tema.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: Esp.xs),
              Text(
                'La tarea ya está hecha y no se vuelve a hacer. La '
                'observación se agrega al final de las que tenga, con la '
                'fecha y la hora.',
                style: tema.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              if (previa.isNotEmpty) ...[
                const SizedBox(height: Esp.m),
                Text(
                  'Ya tiene',
                  style: tema.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: Esp.xs),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 120),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      previa,
                      style: tema.textTheme.bodySmall,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: Esp.m),
              TextField(
                controller: _texto,
                autofocus: true,
                enabled: !_guardando,
                minLines: 3,
                maxLines: 6,
                maxLength: 500,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Observación',
                  border: const OutlineInputBorder(),
                  errorText: _error,
                  errorMaxLines: 3,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _guardando ? null : () => cerrarRuta(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _guardando ? null : _agregar,
          child:
              _guardando
                  ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text('Agregar'),
        ),
      ],
    );
  }
}
