import 'package:bosque_flutter/core/state/button_permissions_provider.dart';
import 'package:bosque_flutter/core/state/empleados_dependientes_provider.dart';
import 'package:bosque_flutter/core/state/permisos_vacacion_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/solicitud_permiso_entity.dart';
import 'package:bosque_flutter/presentation/widgets/permisos-rrhh/permisos_rrhh_comunes.dart';
import 'package:bosque_flutter/presentation/widgets/permisos-vacaciones/solicitud_permiso_vacacion.dart';
import 'package:bosque_flutter/presentation/widgets/shared/permission_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

/// El kardex de permisos de una persona dentro de su ficha: lo que pidió por la
/// app y lo que RR.HH. le cargó a mano, en una sola línea de tiempo.

class MisSolicitudesWidget extends ConsumerStatefulWidget {
  final int codEmpleado;

  const MisSolicitudesWidget({super.key, required this.codEmpleado});

  @override
  ConsumerState<MisSolicitudesWidget> createState() =>
      _MisSolicitudesWidgetState();
}

class _MisSolicitudesWidgetState extends ConsumerState<MisSolicitudesWidget> {
  /// **Arranca en el año corriente y no en «Todos».** El histórico completo
  /// está a un toque, pero no se paga al abrir: esta lista no se purga nunca.
  ///
  /// **Esconder por año sólo es seguro porque el SP no obedece del todo.** El
  /// filtro recorta lo que ya pasó; lo pendiente y lo aprobado que todavía no
  /// ocurrió salen siempre, sea cual sea el año elegido (ver la acción 'A' de
  /// `p_list_SolicitudVacacion`). Sin esa regla, quien pide en agosto la
  /// vacación de enero que viene guarda y ve desaparecer la fila que acaba de
  /// crear —la lista se recarga con el año corriente—, lo lee como que no se
  /// guardó, y encima se queda sin el botón para editarla.
  late int? _anio = DateTime.now().year;
  int? _mes;

  /// Cuál boleta se está bajando, para no dejar apretar dos veces la misma.
  int? _bajando;

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(userProvider);

    // SUPUESTO D4 — pendiente de confirmación de RR.HH. (ver plan §5).
    //
    // Acá vivía un set hardcodeado de codEmpleado {2, 218, 21, 50, 47}: un ACL en
    // código compitiendo con el de la base. Se reemplaza por el permiso real,
    // `btnReImprimirBoleta` de la vista 24, que es el que el backend empezó a
    // exigir en /vacacion/RptPermisoVacacion.
    //
    // Por qué había que cambiarlo: de esos 5, sólo 2, 50 y 218 tienen el botón.
    // Los empleados 21 (aaneiva) y 47 (pvillafuerte) NO lo tienen, así que con el
    // gate nuevo verían el botón y recibirían un 403. Si deben conservar el
    // acceso, se les otorga `btnReImprimirBoleta` en tb_usuarioBtn — no se
    // vuelve a poner una lista en el código.
    //
    // La boleta PROPIA no depende de este permiso: el backend la habilita por
    // identidad, y el subárbol de cargos por jerarquía.
    final bool tieneReImprimirBoleta = ref
        .watch(buttonPermissionsProvider)
        .maybeWhen(
          data:
              (_) => ref
                  .read(buttonPermissionsProvider.notifier)
                  .tienePermiso('btnReImprimirBoleta'),
          orElse: () => false,
        );

    final bool canRequest =
        currentUser != null &&
        (currentUser.codEmpleado == widget.codEmpleado ||
            currentUser.tipoUsuario.toUpperCase() == 'ROLE_ADM' ||
            currentUser.tipoUsuario.toUpperCase() == 'ADM' ||
            tieneReImprimirBoleta);

    final filtro = (codEmpleado: widget.codEmpleado, anio: _anio, mes: _mes);
    final asyncSolicitudes = ref.watch(misSolicitudesProvider(filtro));
    final hPad = ResponsiveUtilsBosque.getHorizontalPadding(context);

    return LayoutBuilder(
      builder: (context, cajon) {
        final aire = Aire.de(cajon.maxWidth);
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (canRequest) ...[
                _botonSolicitar(),
                const SizedBox(height: Esp.l),
              ],
              Text('Permisos y vacaciones', style: context.tituloSeccion()),
              const SizedBox(height: Esp.m),
              _filtros(aire),
              const SizedBox(height: Esp.m),
              asyncSolicitudes.when(
                loading: () => const Cargando(),
                error:
                    (e, _) => ErrorDelDato(
                      error: e,
                      onReintentar:
                          () => ref.invalidate(misSolicitudesProvider(filtro)),
                    ),
                data:
                    (lista) =>
                        lista.isEmpty
                            ? MensajeVacio(
                              icono: Icons.event_busy_outlined,
                              titulo: 'Sin permisos',
                              detalle:
                                  _anio == null && _mes == null
                                      ? 'No hay ninguna solicitud ni permiso '
                                          'cargado.'
                                      : 'No hay nada cargado en ${_periodo()}. '
                                          'Pruebe con otro año o con «Todos».',
                            )
                            : _lineaDeTiempo(lista, aire, canRequest),
              ),
            ],
          ),
        );
      },
    );
  }

  String _periodo() =>
      _mes == null
          ? '${_anio ?? 'todo el historial'}'
          : '${mesesLargos[_mes! - 1]}${_anio == null ? '' : ' de $_anio'}';

  // ── EL ALTA ───────────────────────────────────────────────────────────────

  Widget _botonSolicitar() => SizedBox(
    width: double.infinity,
    child: FilledButton.icon(
      icon: const Icon(Icons.edit_calendar, size: 18),
      label: const Text('Solicitar Permiso / Vacación'),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      onPressed: () {
        final currentUser = ref.read(userProvider);
        final relaciones =
            ref.read(relacionLaboralProvider(widget.codEmpleado)).value;
        int codRelReal = 0;
        if (relaciones != null && relaciones.isNotEmpty) {
          final activa = relaciones.firstWhere(
            (r) => r.esActivo == 1,
            orElse: () => relaciones.first,
          );
          codRelReal = activa.codRelEmplEmpr;
        }
        SolicitudPermisoForm.mostrar(
          context,
          codEmpleado: widget.codEmpleado,
          codRelEmplEmpr: codRelReal,
          audUsuarioI: currentUser?.codUsuario ?? 0,
          actorCodEmpleado: currentUser?.codEmpleado ?? 0,
        );
      },
    ),
  );

  // ── EL FILTRO ─────────────────────────────────────────────────────────────

  /// Cinco años atrás y uno adelante. Atrás porque el kardex viejo llega hasta
  /// ahí en la práctica, adelante porque en diciembre se piden las vacaciones de
  /// enero. Lo que quede fuera de la ventana se ve con «Todos», que es la única
  /// opción que no filtra nada.
  Widget _filtros(Aire aire) {
    final hoy = DateTime.now().year;
    final anios = [for (var a = hoy + 1; a >= hoy - 5; a--) a];

    final campos = <Widget>[
      DropdownButtonFormField<int?>(
        value: _anio,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Año',
          border: OutlineInputBorder(),
          isDense: true,
        ),
        items: [
          const DropdownMenuItem(value: null, child: Text('Todos')),
          for (final a in anios) DropdownMenuItem(value: a, child: Text('$a')),
        ],
        onChanged: (v) => setState(() => _anio = v),
      ),
      DropdownButtonFormField<int?>(
        value: _mes,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Mes',
          border: OutlineInputBorder(),
          isDense: true,
        ),
        items: [
          const DropdownMenuItem(value: null, child: Text('Todos')),
          for (var m = 1; m <= 12; m++)
            DropdownMenuItem(value: m, child: Text(mesesLargos[m - 1])),
        ],
        onChanged: (v) => setState(() => _mes = v),
      ),
    ];

    // A diferencia del kardex de RR.HH., acá el filtro busca solo al elegir: son
    // dos combos y no cuatro selectores de fecha, así que no hay forma de pegarle
    // un viaje al servidor por cada toque mientras se decide.
    return aire.esChico
        ? Column(
          children: [campos[0], const SizedBox(height: Esp.m), campos[1]],
        )
        : Row(
          children: [
            Expanded(child: campos[0]),
            const SizedBox(width: Esp.m),
            Expanded(child: campos[1]),
            const Spacer(flex: 2),
          ],
        );
  }

  // ── LA LÍNEA DE TIEMPO ────────────────────────────────────────────────────

  static const double _anchoCuando = 150;
  static const double _anchoDias = 96;

  Widget _lineaDeTiempo(
    List<SolicitudPermisoEntity> lista,
    Aire aire,
    bool canRequest,
  ) {
    // La escala de la barra es relativa a lo que hay en pantalla: con puras
    // medias jornadas todas son cortas, y basta una vacación para que el resto
    // se achique y ella mande.
    final tope = lista.fold<double>(
      0.5,
      (m, s) => s.cantidadDias > m ? s.cantidadDias : m,
    );

    if (aire.esChico) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (anio, filas) in agruparPorAnio(
            lista,
            (s) => s.desde,
          )) ...[
            _tituloDelAnio(anio),
            for (final s in filas) _tarjeta(s, canRequest),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _cabecera(),
        for (final (anio, filas) in agruparPorAnio(lista, (s) => s.desde)) ...[
          _tituloDelAnio(anio),
          for (final s in filas) _renglon(s, tope, canRequest),
        ],
      ],
    );
  }

  Widget _cabecera() => Padding(
    padding: const EdgeInsets.only(bottom: Esp.xs),
    child: Row(
      children: [
        SizedBox(width: _anchoCuando, child: _encabezado('Cuándo')),
        SizedBox(
          width: _anchoDias,
          child: _encabezado('Duración', aDerecha: true),
        ),
        const SizedBox(width: Esp.m),
        Expanded(child: _encabezado('Detalle')),
      ],
    ),
  );

  Widget _encabezado(String texto, {bool aDerecha = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: Esp.s, horizontal: Esp.s),
    child: Text(
      texto,
      textAlign: aDerecha ? TextAlign.right : TextAlign.left,
      style: context.tituloSeccion(),
    ),
  );

  /// El año encabeza su tramo a lo ancho: es lo único que ordena la lectura de
  /// una lista que abarca varios.
  Widget _tituloDelAnio(String anio) => Padding(
    padding: const EdgeInsets.only(top: Esp.l, bottom: Esp.xs),
    child: Row(
      children: [
        Text(
          anio,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: Peso.titulo,
            fontFeatures: cifrasTabulares,
            color: context.cs.primary,
          ),
        ),
        const SizedBox(width: Esp.m),
        Expanded(child: Divider(height: 1, color: context.cs.outlineVariant)),
      ],
    ),
  );

  Widget _renglon(SolicitudPermisoEntity s, double tope, bool canRequest) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: Esp.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: _anchoCuando,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    cuandoCompacto(s.desde, s.hasta),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFeatures: cifrasTabulares,
                    ),
                  ),
                  if (_horarioDe(s) case final horario?)
                    Text(
                      horario,
                      style: context.apagado()?.copyWith(
                        fontFeatures: cifrasTabulares,
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(
              width: _anchoDias,
              child: Text(
                _duracionDe(s),
                textAlign: TextAlign.right,
                maxLines: 1,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: s.cantidadDias >= 1 ? Peso.titulo : null,
                  fontFeatures: cifrasTabulares,
                ),
              ),
            ),
            const SizedBox(width: Esp.m),
            Expanded(child: _barraConDetalle(s, tope)),
            _acciones(s, canRequest),
          ],
        ),
      );

  /// La barra ocupa el renglón entero y el detalle va encima. El día completo o
  /// más va en el tono pleno y la fracción de jornada apagada: «faltó» y «salió
  /// un rato» se distinguen antes de leer el número.
  Widget _barraConDetalle(SolicitudPermisoEntity s, double tope) => Tooltip(
    message: [
      _duracionDe(s),
      _horarioDe(s),
      if (s.autorizador != null &&
          s.autorizador != '—' &&
          s.autorizador!.trim().isNotEmpty)
        'Autorizó: ${s.autorizador}',
    ].nonNulls.join('\n'),
    child: Stack(
      children: [
        Positioned.fill(
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: (s.cantidadDias / tope).clamp(0.04, 1).toDouble(),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: context.cs.primary.withValues(
                  alpha: s.cantidadDias >= 1 ? 0.30 : 0.12,
                ),
                borderRadius: BorderRadius.circular(Esp.xs),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Esp.s,
            vertical: Esp.s,
          ),
          child: _detalle(s),
        ),
      ],
    ),
  );

  Widget _detalle(SolicitudPermisoEntity s) {
    final (rotulo, tono) = _estadoDe(s);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: Esp.s,
          runSpacing: Esp.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Etiqueta(texto: rotulo, tono: tono),
            // El tipo sólo cuando NO es una vacación: si casi todo dice
            // «Vacación», marcarlas todas es no marcar ninguna. Misma regla que
            // el kardex de RR.HH.
            if (s.tipoPermiso.trim().toLowerCase() != 'vac')
              Etiqueta(
                texto: _nombreDelTipo(s.tipoPermiso),
                tono:
                    s.tipoPermiso.trim().toLowerCase() == 'pva'
                        ? TonoEtiqueta
                            .aviso // es dinero
                        : TonoEtiqueta.neutro,
              ),
            if (s.motivo.trim().isNotEmpty)
              Text(
                enOracion(s.motivo),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
          ],
        ),
        // Por qué se lo negaron o por qué se anuló. Es lo primero que se viene a
        // buscar cuando la fila no está en verde, así que se muestra siempre y no
        // detrás de un toque.
        if (s.motivoRechazo != null && s.motivoRechazo!.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: Esp.xs),
            child: Text(
              '${s.estado == 4 ? 'Motivo anulación' : 'Motivo rechazo'}: '
              '${enOracion(s.motivoRechazo!)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: s.estado == 4 ? null : context.cs.error,
              ),
            ),
          ),
      ],
    );
  }

  /// En un teléfono el renglón de cuatro columnas deja el motivo cortado en la
  /// primera palabra. Una tarjeta por permiso pone cada dato con su rótulo.
  Widget _tarjeta(SolicitudPermisoEntity s, bool canRequest) => Padding(
    padding: const EdgeInsets.only(bottom: Esp.s),
    child: DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: context.cs.outlineVariant),
        borderRadius: BorderRadius.circular(Esp.s),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Esp.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cuandoLargo(s.desde, s.hasta),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: Peso.titulo,
                          fontFeatures: cifrasTabulares,
                        ),
                      ),
                      if (_horarioDe(s) case final horario?)
                        Text(
                          horario,
                          style: context.apagado()?.copyWith(
                            fontFeatures: cifrasTabulares,
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  _duracionDe(s),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: s.cantidadDias >= 1 ? Peso.titulo : null,
                    fontFeatures: cifrasTabulares,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Esp.s),
            _detalle(s),
            Align(
              alignment: Alignment.centerRight,
              child: _acciones(s, canRequest),
            ),
          ],
        ),
      ),
    ),
  );

  // ── LO QUE SE PUEDE HACER CON UNA FILA ────────────────────────────────────

  /// **El ancho es fijo aunque la fila no tenga ningún botón.** Los botones
  /// dependen del estado —editar sólo en las pendientes, PDF y anular sólo en
  /// las aprobadas—, así que con un ancho natural cada renglón le dejaría a la
  /// barra un largo distinto y dos permisos de los mismos días se dibujarían
  /// desiguales. La barra sólo sirve si todas arrancan y terminan en la misma
  /// columna. Dos `IconButton` de 48 es lo máximo que puede coincidir.
  static const double _anchoAcciones = 96;

  Widget _acciones(SolicitudPermisoEntity s, bool canRequest) {
    // Editable sólo mientras nadie la miró: una vez que la jefatura firmó, el
    // dato ya viajó y cambiarlo por atrás es cambiarle a alguien lo que aprobó.
    final editable =
        s.estado == 1 && s.pasoActual == 'Enviado (Sin revisión)' && canRequest;
    final currentUser = ref.read(userProvider);

    return SizedBox(
      width: _anchoAcciones,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (editable && currentUser != null)
            IconButton(
              tooltip: 'Editar la solicitud',
              icon: const Icon(Icons.edit_outlined),
              iconSize: 20,
              onPressed:
                  () => SolicitudPermisoForm.mostrar(
                    context,
                    codEmpleado: widget.codEmpleado,
                    codRelEmplEmpr: s.codRelEmplEmpr,
                    audUsuarioI: currentUser.codUsuario,
                    actorCodEmpleado: currentUser.codEmpleado,
                    solicitudAEditar: s,
                  ),
            ),
          // La boleta no lleva `PermissionWidget`: el backend la habilita por
          // identidad y por jerarquía además de por el botón del ACL, así que
          // esconderla acá se la sacaría a quien sí puede bajar la suya.
          if (s.estado == 2 && s.codPermiso != null)
            IconButton(
              tooltip: 'Bajar la boleta en PDF',
              icon: const Icon(Icons.picture_as_pdf_outlined),
              iconSize: 20,
              onPressed:
                  _bajando == s.codPermiso
                      ? null
                      : () => _bajarBoleta(s.codPermiso!),
            ),
          // `(s.codSolicitud ?? 0) > 0` NO es paranoia: la acción 'A' del SP
          // une las solicitudes con los permisos que RR.HH. cargó a mano, y a
          // esos les pone `0 AS codSolicitud` y `2 AS estado`. Sin esta guarda
          // el botón salía en esas filas y mandaba a anular «la solicitud 0»,
          // que no existe. Venía de antes; se arregla acá porque es el único
          // lugar de la app que anula.
          if (s.estado == 2 && (s.codSolicitud ?? 0) > 0)
            PermissionWidget(
              buttonName: 'btnAnularVacacion',
              child: IconButton(
                tooltip: 'Anular',
                icon: const Icon(Icons.cancel_outlined),
                iconSize: 20,
                color: context.cs.error,
                onPressed: () => _mostrarDialogoAnulacion(s),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _bajarBoleta(int codPermiso) async {
    setState(() => _bajando = codPermiso);
    try {
      final pdf = await ref.read(rptPermisoVacacionProvider(codPermiso).future);
      if (!mounted) return;
      await Printing.layoutPdf(
        onLayout: (_) async => pdf,
        name: 'RptPermisoVacacion_$codPermiso',
      );
    } catch (e) {
      if (!mounted) return;
      avisarError(context, e);
    } finally {
      if (mounted) setState(() => _bajando = null);
    }
  }

  // ── TEXTOS ────────────────────────────────────────────────────────────────

  /// `09:00 – 17:30`, o `null` cuando el permiso no tiene hora.
  ///
  /// Las dos en 00:00 es como el sistema anterior guarda «el día entero», no un
  /// permiso de medianoche a medianoche; el SP hace la misma distinción para
  /// armar `fechasTxt`. Pintarlo sería inventar una precisión que el dato no
  /// tiene.
  String? _horarioDe(SolicitudPermisoEntity s) {
    final sinHora =
        s.desde.hour == 0 &&
        s.desde.minute == 0 &&
        s.hasta.hour == 0 &&
        s.hasta.minute == 0;
    return sinHora ? null : '${horaCorta(s.desde)} – ${horaCorta(s.hasta)}';
  }

  /// La duración **como la escribió el backend**: `diasSolicitadosTxt` es el
  /// mismo texto que sale en la boleta impresa que RR.HH. compara contra la
  /// pantalla, y ya distingue «6.0 días» de «4.0 hrs». Reformatearlo a «0,5 d»
  /// hacía que la misma fila dijera una cosa en escritorio, otra en el teléfono
  /// y otra en el papel. El número crudo es sólo el respaldo por si el SP no lo
  /// mandó (la regla está en `permisos_rrhh_comunes.dart`).
  String _duracionDe(SolicitudPermisoEntity s) =>
      s.diasSolicitadosTxt?.trim().isNotEmpty == true
          ? s.diasSolicitadosTxt!.trim()
          : '${numeroDeDias(s.cantidadDias)} día(s)';

  /// El rótulo del estado y su color. El texto es el que arma el SP
  /// (`pasoActual`), que distingue «Enviado (Sin revisión)» de «Esperando
  /// autorización de RRHH» — dos cosas que para quien espera no son lo mismo.
  (String, TonoEtiqueta) _estadoDe(SolicitudPermisoEntity s) => switch (s
      .estado) {
    2 => (s.pasoActual ?? 'Aprobado', TonoEtiqueta.exito),
    3 => (s.pasoActual ?? 'Rechazado', TonoEtiqueta.error),
    4 => (s.pasoActual ?? 'Anulado', TonoEtiqueta.neutro),
    _ => (s.pasoActual ?? 'Pendiente', TonoEtiqueta.aviso),
  };

  /// El nombre del tipo según el catálogo; el código crudo si el catálogo
  /// todavía no llegó o el tipo no está en él.
  String _nombreDelTipo(String codigo) {
    final tipos =
        ref
            .watch(
              tiposPermisoProvider((
                codEmpleado: widget.codEmpleado,
                codUsuarioLogueado: 0, // 0 = el catálogo completo, para rotular
              )),
            )
            .valueOrNull ??
        const [];
    for (final t in tipos) {
      if (t.codTipos.toLowerCase() == codigo.trim().toLowerCase()) {
        return t.nombre;
      }
    }
    return codigo.trim().isEmpty ? 'Sin tipo' : codigo;
  }

  // ── ANULAR ────────────────────────────────────────────────────────────────

  void _mostrarDialogoAnulacion(SolicitudPermisoEntity sol) {
    final TextEditingController motivoCtrl = TextEditingController();
    final currentUser = ref.read(userProvider);
    if (currentUser == null) return;

    showDialog(
      context: context,
      builder: (ctx) {
        bool isLoading = false;
        return StatefulBuilder(
          builder: (ctx, setStateDialogo) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Theme.of(ctx).colorScheme.error,
                  ),
                  const SizedBox(width: Esp.s),
                  const Text(
                    'Anular Solicitud',
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '¿Está seguro de anular esta solicitud aprobada?',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: Esp.m),
                  TextField(
                    controller: motivoCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Motivo de anulación (Obligatorio)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(ctx).colorScheme.error,
                    foregroundColor: Theme.of(ctx).colorScheme.onError,
                  ),
                  onPressed:
                      isLoading
                          ? null
                          : () {
                            final motivo = motivoCtrl.text.trim();
                            if (motivo.isEmpty) {
                              avisarError(
                                ctx,
                                'Debe ingresar un motivo de anulación.',
                              );
                              return;
                            }
                            setStateDialogo(() => isLoading = true);
                            ref
                                .read(accionSolicitudProvider.notifier)
                                .anular(
                                  codSolicitud: sol.codSolicitud!,
                                  audUsuarioI: currentUser.codUsuario,
                                  motivo: motivo,
                                  onSuccess: (msg) {
                                    Navigator.pop(ctx);
                                    ref.invalidate(misSolicitudesProvider);
                                    ref.invalidate(
                                      solicitudesPendientesProvider,
                                    );
                                    if (mounted) avisar(context, msg);
                                  },
                                  onError: (err) {
                                    setStateDialogo(() => isLoading = false);
                                    avisarError(ctx, err);
                                  },
                                );
                          },
                  child:
                      isLoading
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text('Confirmar Anulación'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
