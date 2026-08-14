import 'dart:async';

import 'package:bosque_flutter/core/state/permisos_rrhh_provider.dart';
import 'package:bosque_flutter/domain/entities/simulacion_permiso_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_permiso_vacacion_entity.dart';
import 'package:bosque_flutter/presentation/widgets/permisos-rrhh/desglose_dias_no_habiles.dart';
import 'package:bosque_flutter/presentation/widgets/permisos-rrhh/permisos_rrhh_comunes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Programa **un permiso** a nombre del empleado: el modal «Registro de
/// permisos» del sistema anterior.
Future<void> mostrarProgramarPermiso({
  required BuildContext context,
  required int codEmpleado,
  required String datoEmpleado,
}) => _mostrar(context, _Programacion.permiso, codEmpleado, datoEmpleado);

/// Programa **una vacación individual**: el modal «Registro de vacación
/// individual».
Future<void> mostrarProgramarVacacion({
  required BuildContext context,
  required int codEmpleado,
  required String datoEmpleado,
}) => _mostrar(context, _Programacion.vacacion, codEmpleado, datoEmpleado);

/// Cuál de los dos modales es.
///
/// **Son la misma hoja porque son el mismo formulario.** En el sistema anterior
/// están duplicados (`regPermisoModal` y `regVacIndivModal`) y del lado del
/// servidor caen los dos en `p_abm_Permiso`: lo único que cambia es el
/// `tipoPermiso` —uno lo elige la persona de un combo, el otro lo pone el
/// servidor en `'vac'`— y, por lo tanto, cuál botón del ACL hace falta y a qué
/// ruta se pega (`/permisos/registrar` contra `/vacacion/registrar`). Duplicar
/// la hoja sería duplicar también el cálculo en vivo y la confirmación.
enum _Programacion { permiso, vacacion }

Future<void> _mostrar(
  BuildContext context,
  _Programacion que,
  int codEmpleado,
  String datoEmpleado,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  constraints: const BoxConstraints(maxWidth: 640),
  builder:
      (_) => _PermisoIndividualSheet(
        que: que,
        codEmpleado: codEmpleado,
        datoEmpleado: datoEmpleado,
      ),
);

/// El alta de un permiso o de una vacación individual, con los días calculados
/// **por el servidor** mientras se elige el rango.
///
/// ## El número que se muestra es el que se graba
///
/// Los tres campos calculados del modal viejo (`Horas de permiso`, `Días de
/// permiso`, `Total días de vacación`) los resolvía un motor en Java que
/// avanzaba de media hora en media hora. **Ese no es el motor que está grabando
/// hoy**: las filas que escribe lo ya migrado llevan los números de
/// `dbo.f_CalcularDiasHabilesPermiso`, y las dos cuentas no coinciden. Acá los
/// números salen de `/permiso-rrhh/permisos/calcular`, que es esa misma función,
/// y el backend vuelve a calcularlos dentro de la transacción antes de escribir:
/// no hay forma de que la pantalla diga un número y se grabe otro.
///
/// Consecuencia que hay que saber antes de que alguien la reporte como falla:
/// el modal viejo de **permiso** no descuenta feriados (el de vacación sí), así
/// que para un permiso que cae en feriado esta pantalla da **menos** días que el
/// ERP. Es la corrección de un error, no una regresión.
///
/// ## El radio «Horario Estándar / Continuo» no es un dato
///
/// La función SQL no recibe ese parámetro: lo deduce de la hora de fin —después
/// de las 17:30 el día cuenta 600 minutos y una hora de almuerzo, si no 480 y
/// media—. Mandarlo en el cuerpo sería un campo que el servidor ignora, o sea un
/// control que miente. Acá el radio hace lo único que puede hacer sin mentir:
/// **mueve la ventana de horas que se puede elegir** (estándar hasta 17:30,
/// continuo hasta 19:00) y, si la hora de fin queda fuera, la recorta — con lo
/// cual el número cambia de verdad, que es lo que la persona espera al tocarlo.
class _PermisoIndividualSheet extends ConsumerStatefulWidget {
  const _PermisoIndividualSheet({
    required this.que,
    required this.codEmpleado,
    required this.datoEmpleado,
  });

  final _Programacion que;
  final int codEmpleado;
  final String datoEmpleado;

  @override
  ConsumerState<_PermisoIndividualSheet> createState() =>
      _PermisoIndividualSheetState();
}

class _PermisoIndividualSheetState
    extends ConsumerState<_PermisoIndividualSheet> {
  final _motivo = TextEditingController();

  /// Los valores por defecto son los de `newVacacion()`: hoy de 08:00 a 09:00,
  /// horario estándar. Los `mindate`/`maxdate` del modal viejo nunca se
  /// asignaban, así que no hay tope de fechas que portar: el único límite real
  /// es la ventana de horas.
  late DateTime _desde = _hoyALas(8, 0);
  late DateTime _hasta = _hoyALas(9, 0);

  bool _continuo = false;

  /// El tipo elegido. **Arranca sin elegir, al revés que el modal viejo**, que
  /// deja preseleccionado el primero de la lista: un combo ya lleno invita a
  /// guardar «Baja por Enfermedad» sin haberlo leído.
  String? _tipoPermiso;

  SimulacionPermisoEntity? _calculo;
  Object? _errorCalculo;

  /// Arranca en `true` porque el primer cálculo sale solo: el rango por defecto
  /// ya es válido, y abrir el modal con los tres números en blanco haría pensar
  /// que hay que apretar algo para que aparezcan.
  bool _calculando = true;
  bool _guardando = false;

  /// El rebote del cálculo en vivo. Es el equivalente del `p:ajax
  /// event="dateSelect"` del modal viejo, pero sin pegarle al servidor por cada
  /// toque del selector.
  Timer? _rebote;

  bool get _esVacacion => widget.que == _Programacion.vacacion;

  static const int _minutoMinimo = 8 * 60;
  int get _minutoMaximo => _continuo ? 19 * 60 : 17 * 60 + 30;

  @override
  void initState() {
    super.initState();
    // **Con un `Timer` y no llamando a `_calcular()` derecho**: aquél hace
    // `setState` antes de su primer `await`, y un `setState` adentro de
    // `initState` es un `markNeedsBuild` en pleno build. El timer lo corre en
    // la vuelta siguiente del bucle de eventos, y `dispose` lo cancela.
    _rebote = Timer(Duration.zero, _calcular);
  }

  @override
  void dispose() {
    _rebote?.cancel();
    _motivo.dispose();
    super.dispose();
  }

  static DateTime _hoyALas(int hora, int minuto) {
    final hoy = DateTime.now();
    return DateTime(hoy.year, hoy.month, hoy.day, hora, minuto);
  }

  @override
  Widget build(BuildContext context) {
    final tipos = ref.watch(tiposPermisoRrhhProvider(false));

    return Padding(
      padding: EdgeInsets.only(
        left: Esp.xl,
        right: Esp.xl,
        top: Esp.s,
        // El teclado tapa el botón de guardar en cuanto se toca el motivo.
        bottom: MediaQuery.of(context).viewInsets.bottom + Esp.xl,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _esVacacion ? 'Programar vacación' : 'Programar permiso',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              widget.datoEmpleado.isEmpty
                  ? 'A nombre del empleado seleccionado'
                  : widget.datoEmpleado,
              style: context.apagado(),
            ),

            const SizedBox(height: Esp.l),
            _horario(),

            if (!_esVacacion) ...[
              const SizedBox(height: Esp.m),
              _comboDeTipos(tipos),
            ],

            const SizedBox(height: Esp.m),
            // A 360 px los dos campos de fecha y hora no entran en una fila:
            // `Wrap` los apila solo en vez de pintar la franja amarilla.
            LayoutBuilder(
              builder: (context, cajon) {
                final enFila = cajon.maxWidth >= 420;
                final desde = _fechaHora(esDesde: true);
                final hasta = _fechaHora(esDesde: false);
                return enFila
                    ? Row(
                      children: [
                        Expanded(child: desde),
                        const SizedBox(width: Esp.m),
                        Expanded(child: hasta),
                      ],
                    )
                    : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        desde,
                        const SizedBox(height: Esp.m),
                        hasta,
                      ],
                    );
              },
            ),

            const SizedBox(height: Esp.l),
            _calculados(),
            const SizedBox(height: Esp.m),
            // La resta escrita: qué días del rango no cuentan y por qué. El
            // bloque de arriba da el total; éste deja verificarlo.
            DesgloseDiasNoHabiles(
              codEmpleado: widget.codEmpleado,
              desde: _desde,
              hasta: _hasta,
            ),

            const SizedBox(height: Esp.m),
            TextField(
              controller: _motivo,
              // El largo de `trh_permiso.motivo`. El validador del sistema
              // anterior corta en 50 y con una expresión regular que rechaza la
              // eñe y las tildes; el del backend nuevo pide 2 a 100 sin más, y
              // es el que manda.
              maxLength: 100,
              maxLines: 2,
              minLines: 1,
              decoration: const InputDecoration(
                labelText: 'Motivo',
                border: OutlineInputBorder(),
                isDense: true,
                helperText: 'Queda en la fila y en la bitácora. Es obligatorio.',
              ),
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: Esp.m),
            FilledButton.icon(
              // Apagado mientras el cálculo está en vuelo o falló: sin un número
              // del servidor no se sabe qué se estaría guardando. Y apagado
              // mientras se guarda, que es lo único que el cliente puede aportar
              // contra el doble toque —la tabla no tiene ningún UNIQUE—.
              onPressed: _puedeGuardar ? _revisar : null,
              icon:
                  _guardando
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.save_outlined),
              label: Text(
                _esVacacion ? 'Programar la vacación' : 'Programar el permiso',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── HORARIO ───────────────────────────────────────────────────────────────

  Widget _horario() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SegmentedButton<bool>(
        segments: const [
          ButtonSegment(value: false, label: Text('Horario estándar')),
          ButtonSegment(value: true, label: Text('Horario continuo')),
        ],
        selected: {_continuo},
        onSelectionChanged:
            _guardando ? null : (s) => _cambiarHorario(s.first),
      ),
      const SizedBox(height: Esp.xs),
      Text(
        _continuo
            ? 'Continuo: se pueden elegir horas entre 08:00 y 19:00. Después de '
                'las 17:30 el día cuenta 10 horas y descuenta una de almuerzo.'
            : 'Estándar: se pueden elegir horas entre 08:00 y 17:30. El día '
                'cuenta 8 horas y descuenta media de almuerzo.',
        style: context.apagado(),
      ),
      const SizedBox(height: Esp.xs),
      Text(
        'El horario lo decide la hora de fin, no este selector: acá sólo se '
        'elige hasta qué hora se puede cargar.',
        style: context.apagado(),
      ),
    ],
  );

  void _cambiarHorario(bool continuo) {
    setState(() => _continuo = continuo);
    // Al pasar a estándar, un fin a las 18:30 queda fuera de la ventana. Se
    // recorta y se dice: el número cambia, así que callarlo sería cambiar el
    // dato sin avisar.
    final recortado = _dentroDeLaVentana(_hasta);
    if (recortado != _hasta) {
      setState(() => _hasta = recortado);
      avisar(
        context,
        'La hora de fin se ajustó a ${horaCorta(recortado)}, que es el tope del '
        'horario ${continuo ? 'continuo' : 'estándar'}.',
      );
    }
    _pedirCalculo();
  }

  DateTime _dentroDeLaVentana(DateTime d) {
    final minuto = d.hour * 60 + d.minute;
    if (minuto < _minutoMinimo) {
      return DateTime(d.year, d.month, d.day, _minutoMinimo ~/ 60, 0);
    }
    if (minuto > _minutoMaximo) {
      return DateTime(
        d.year,
        d.month,
        d.day,
        _minutoMaximo ~/ 60,
        _minutoMaximo % 60,
      );
    }
    return d;
  }

  /// Fecha y hora de un extremo, en un solo campo y con dos toques. Es el mismo
  /// control que la carga colectiva: son un solo instante, y partirlo en dos
  /// campos deja la pantalla pidiendo cuatro cosas para decir dos.
  Widget _fechaHora({required bool esDesde}) {
    final valor = esDesde ? _desde : _hasta;
    return CampoElegido(
      etiqueta: esDesde ? 'Desde' : 'Hasta',
      texto: '${fechaCorta(valor)}  ${horaCorta(valor)}',
      icono: Icons.schedule_outlined,
      onTap: _guardando ? null : () => _elegirFechaHora(esDesde: esDesde),
    );
  }

  Future<void> _elegirFechaHora({required bool esDesde}) async {
    final valor = esDesde ? _desde : _hasta;
    final hoy = DateTime.now();
    final dia = await showDatePicker(
      context: context,
      initialDate: valor,
      // El sistema anterior no tiene tope de fechas —sus `mindate`/`maxdate`
      // nunca se asignan—; este rango es una restricción NUEVA, puesta para que
      // un año mal tipeado no cargue un permiso en 2035.
      firstDate: DateTime(hoy.year - 1),
      lastDate: DateTime(hoy.year + 1, 12, 31),
      helpText: esDesde ? 'El permiso empieza' : 'El permiso termina',
    );
    if (!mounted || dia == null) return;

    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: valor.hour, minute: valor.minute),
      helpText: esDesde ? 'Hora de inicio' : 'Hora de fin',
    );
    if (!mounted) return;

    final pedido = DateTime(
      dia.year,
      dia.month,
      dia.day,
      hora?.hour ?? valor.hour,
      hora?.minute ?? valor.minute,
    );
    final elegido = _dentroDeLaVentana(pedido);
    setState(() {
      if (esDesde) {
        _desde = elegido;
      } else {
        _hasta = elegido;
      }
    });
    if (elegido != pedido) {
      avisar(
        context,
        'Fuera del horario ${_continuo ? 'continuo' : 'estándar'}: la hora se '
        'ajustó a ${horaCorta(elegido)}.',
      );
    }
    _pedirCalculo();
  }

  // ── EL CÁLCULO EN VIVO ────────────────────────────────────────────────────

  void _pedirCalculo() {
    _rebote?.cancel();
    // Mientras tanto no se muestra el número viejo: un total al lado de fechas
    // que ya no son las suyas es peor que un guion.
    setState(() {
      _calculo = null;
      _errorCalculo = null;
      _calculando = true;
    });
    _rebote = Timer(const Duration(milliseconds: 400), _calcular);
  }

  Future<void> _calcular() async {
    final problema = _problemaDelRango();
    if (problema != null) {
      setState(() {
        _calculo = null;
        _errorCalculo = problema;
        _calculando = false;
      });
      return;
    }

    setState(() {
      _errorCalculo = null;
      _calculando = true;
    });

    final desde = _desde;
    final hasta = _hasta;
    try {
      final r = await ref
          .read(permisosRrhhRepositoryProvider)
          .simularPermiso(
            codEmpleado: widget.codEmpleado,
            desde: desde,
            hasta: hasta,
            // No cambia los días —la función SQL no lo recibe— pero sí las
            // horas a reponer, que las calcula el servidor.
            tipoPermiso: _tipoPermiso ?? '',
          );
      // Llegó tarde: mientras viajaba, alguien cambió el rango. Pintar esta
      // respuesta pondría el número de un rango al lado de otro.
      if (!mounted || desde != _desde || hasta != _hasta) return;
      setState(() {
        _calculo = r;
        _calculando = false;
        _errorCalculo =
            r == null
                ? 'No se pudo calcular: el empleado no tiene una relación '
                    'laboral activa.'
                : null;
      });
    } catch (e) {
      if (!mounted || desde != _desde || hasta != _hasta) return;
      setState(() {
        _calculo = null;
        _errorCalculo = e;
        _calculando = false;
      });
    }
  }

  /// Lo que se puede saber sin preguntarle a nadie. Son las dos reglas que el
  /// backend también aplica, adelantadas para no gastar un viaje.
  String? _problemaDelRango() {
    if (!_hasta.isAfter(_desde)) {
      return 'La fecha y hora de fin tienen que ser posteriores a las de '
          'inicio.';
    }
    if (_desde.year != _hasta.year) {
      return 'Tiene que empezar y terminar en el mismo año: uno a caballo de '
          'dos años descuadra las dos gestiones.';
    }
    return null;
  }

  /// Las horas que este tipo de permiso obliga a reponer, **calculadas por el
  /// servidor** con la regla de `verificarTipoPermiso()` (`otro` y `pcr`).
  ///
  /// Es un aviso y no un dato —`p_abm_Permiso` tiene once parámetros y ninguno
  /// es éste—, pero igual sale de un solo lado: la regla es de una línea y por
  /// eso las dos copias coincidían, hasta el día que RR.HH. agregue un tipo que
  /// repone y se cambie en un solo repo.
  double get _horasAReponer => _calculo?.horasAReponer ?? 0;

  Widget _calculados() {
    final c = _calculo;
    final texto = _calculando || c == null;

    return Bloque(
      icono: Icons.calculate_outlined,
      titulo: _esVacacion ? 'Lo que se descuenta' : 'Lo que dura el permiso',
      explicacion:
          'Lo calcula el servidor con los feriados de la sucursal del '
          'empleado, y es el mismo número que se graba.',
      hijo: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: Esp.xl,
            runSpacing: Esp.m,
            children: [
              if (_esVacacion)
                Metrica(
                  rotulo: 'Total días de vacación',
                  texto: texto ? '…' : numeroDeDias(c.dias),
                  destacada: true,
                )
              else ...[
                Metrica(
                  rotulo: 'Horas de permiso',
                  texto: texto ? '…' : '${numeroDeDias(c.horas)} h',
                ),
                Metrica(
                  rotulo: 'Días de permiso',
                  texto: texto ? '…' : numeroDeDias(c.dias),
                  destacada: true,
                ),
                Metrica(
                  rotulo: 'Horas a reponer',
                  texto: texto ? '…' : '${numeroDeDias(_horasAReponer)} h',
                ),
              ],
            ],
          ),

          if (!texto && c.datoSucursal.isNotEmpty) ...[
            const SizedBox(height: Esp.s),
            Text('Feriados de ${c.datoSucursal}.', style: context.apagado()),
          ],

          if (_errorCalculo != null) ...[
            const SizedBox(height: Esp.s),
            AvisoDelDato(
              icono: Icons.error_outline,
              texto:
                  '${textoParaUsuario(_errorCalculo!)}\n'
                  'No se puede guardar hasta que el cálculo salga bien.',
            ),
          ],

          if (!texto && !c.entra && _errorCalculo == null) ...[
            const SizedBox(height: Esp.s),
            AvisoDelDato(
              icono: Icons.event_busy_outlined,
              texto: _porQueNoEntra(c),
            ),
          ],

          if (!texto && !_esVacacion && _horasAReponer > 0) ...[
            const SizedBox(height: Esp.s),
            AvisoDelDato(
              texto:
                  'Este tipo de permiso se repone: son '
                  '${numeroDeDias(_horasAReponer)} horas. NO quedan '
                  'registradas en ningún lado —el sistema anterior tampoco las '
                  'guarda, el campo era informativo—, así que la reposición se '
                  'sigue llevando por fuera.',
            ),
          ],
        ],
      ),
    );
  }

  /// Por qué no se puede guardar, **con el texto del servidor**.
  ///
  /// El caso que más pasa es el cruce —hay 294 pares solapados en la tabla y el
  /// sistema anterior no chequea nada—, y el mensaje viene con el rango del
  /// permiso que choca adentro, que es lo único que sirve para arreglarlo. Es
  /// palabra por palabra el que devuelve el rechazo al guardar: la pantalla no
  /// puede decir una cosa y el servidor otra.
  String _porQueNoEntra(SimulacionPermisoEntity c) =>
      c.detalle.isEmpty
          ? 'El servidor no confirmó que este rango se pueda guardar. Pruebe con '
              'otras fechas.'
          : '${c.detalle} Cambie las fechas o revise lo que ya está cargado en '
              'la nómina.';

  Widget _comboDeTipos(AsyncValue<List<TipoPermisoVacacionEntity>> tipos) =>
      tipos.when(
    loading:
        () => const InputDecorator(
          decoration: InputDecoration(
            labelText: 'Tipo de permiso',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          child: Text('Cargando…'),
        ),
    error:
        (e, _) => AvisoDelDato(
          icono: Icons.error_outline,
          texto:
              'No se pudieron traer los tipos de permiso: '
              '${textoParaUsuario(e)}',
        ),
    data:
        (lista) => DropdownButtonFormField<String>(
          value: _tipoPermiso,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Tipo de permiso',
            border: OutlineInputBorder(),
            isDense: true,
            helperText:
                'Obligatorio. La vacación se carga desde su propio botón.',
          ),
          items: [
            for (final t in lista)
              DropdownMenuItem<String>(
                value: t.codTipos,
                child: Text(
                  t.nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          // El tipo no cambia los días —la función SQL no lo recibe— pero sí
          // las horas a reponer, y ese número lo calcula el servidor. Así que
          // vuelve a preguntar, con el mismo rebote que las fechas.
          onChanged:
              _guardando
                  ? null
                  : (v) {
                    setState(() => _tipoPermiso = v);
                    _pedirCalculo();
                  },
        ),
  );

  // ── GUARDAR ───────────────────────────────────────────────────────────────

  bool get _puedeGuardar {
    final c = _calculo;
    if (_guardando || _calculando || c == null || _errorCalculo != null) {
      return false;
    }
    // **Lo dice el servidor, no el cliente**: `entra` es el mismo campo con el
    // que el DAO decide a quién incluye en la carga colectiva y con el que va a
    // aceptar o rechazar esta alta. Antes se leían cuatro campos que el
    // servidor no manda, así que el botón quedaba encendido sobre una escritura
    // que ya se sabía rechazada.
    if (!c.entra) return false;
    if (!_esVacacion && (_tipoPermiso == null || _tipoPermiso!.isEmpty)) {
      return false;
    }
    return _motivo.text.trim().length >= 2;
  }

  Future<void> _revisar() async {
    final c = _calculo;
    if (c == null) return;
    final ok = await confirmar(
      context,
      titulo: _esVacacion ? '¿Programar la vacación?' : '¿Programar el permiso?',
      mensaje: _queVaAPasar(c),
      accion: 'Programar',
    );
    if (!ok || !mounted) return;
    await _guardar();
  }

  String _queVaAPasar(SimulacionPermisoEntity c) {
    final quien =
        widget.datoEmpleado.isEmpty ? 'este empleado' : widget.datoEmpleado;
    final que = _esVacacion ? 'vacación' : 'permiso «${_nombreDelTipo()}»';
    return 'Vas a registrar ${numeroDeDias(c.dias)} días de $que a $quien, del '
        '${fechaCorta(_desde)} ${horaCorta(_desde)} al ${fechaCorta(_hasta)} '
        '${horaCorta(_hasta)}.\n\n'
        'Motivo: ${_motivo.text.trim()}\n\n'
        '${_esVacacion ? 'Esos días se le descuentan del saldo de vacación. ' : 'Queda en su kardex de permisos. '}'
        'Los días los calculó el servidor '
        '${c.datoSucursal.isEmpty ? '' : 'con los feriados de ${c.datoSucursal} '}'
        'y son los que se graban. Para deshacerlo hay que borrar la fila desde '
        'el sistema anterior.';
  }

  String _nombreDelTipo() {
    final lista = ref.read(tiposPermisoRrhhProvider(false)).valueOrNull ?? [];
    for (final t in lista) {
      if (t.codTipos == _tipoPermiso) return t.nombre;
    }
    return _tipoPermiso ?? '';
  }

  /// Escribe.
  ///
  /// **Sin flujo de dos pasos**: estas dos rutas no emiten ningún 400
  /// confirmable —el controlador no le pasa el flag al DAO y el DAO no lo
  /// tiene—, así que un «Guardar igual» acá sería un botón que no guarda nunca.
  /// Lo que el servidor no acepta lo dice el cálculo antes, con el botón
  /// apagado. El de la vacación pagada sí es real y vive en su propia hoja.
  Future<void> _guardar() async {
    setState(() => _guardando = true);
    try {
      final acciones = ref.read(permisosRrhhAccionesProvider);
      final msg =
          _esVacacion
              ? await acciones.registrarVacacion(
                codEmpleado: widget.codEmpleado,
                desde: _desde,
                hasta: _hasta,
                motivo: _motivo.text,
              )
              : await acciones.registrarPermiso(
                codEmpleado: widget.codEmpleado,
                tipoPermiso: _tipoPermiso!,
                desde: _desde,
                hasta: _hasta,
                motivo: _motivo.text,
              );
      if (!mounted) return;
      Navigator.of(context).pop();
      // El mensaje del servidor tal cual: `p_abm_Permiso` no devuelve el id
      // generado, así que lo que se puede afirmar es lo que él afirma.
      avisar(
        context,
        msg.isEmpty
            ? (_esVacacion
                ? 'La vacación quedó programada.'
                : 'El permiso quedó programado.')
            : msg,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      // Se relee: si esto fue un 409, alguien escribió en el medio y lo que la
      // pantalla muestra ya no es lo que hay.
      ref.read(permisosRrhhAccionesProvider).refrescar(widget.codEmpleado);
      avisarError(context, e);
    }
  }
}
