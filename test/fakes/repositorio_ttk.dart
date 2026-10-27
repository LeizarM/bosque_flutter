import 'dart:async';

import 'package:bosque_flutter/domain/entities/ttk_bingo_aviso_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_bingo_carton_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_bingo_celda_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_bingo_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_bingo_ganador_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_bingo_juego_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_bingo_participante_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_bingo_publico_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_bingo_sorteo_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_empleado_bingo_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_estado_encargado_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_estado_publico_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_evento_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_participante_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_participante_ticket_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_ranking_carton_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_tipo_ticket_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_vale_impresion_entity.dart';
import 'package:bosque_flutter/domain/repositories/ttk_bingo_repository.dart';
import 'package:bosque_flutter/domain/repositories/ttk_bingo_vivo_repository.dart';
import 'package:bosque_flutter/domain/repositories/ttk_tickets_repository.dart';

/// Datos de ejemplo del módulo Tickets / Bingo para las pruebas de pantalla:
/// sin backend, sin login y sin WebSocket.
final BigInt _uno = BigInt.one;
final DateTime _fecha = DateTime(2026, 12, 20);

TtkRespuesta _ok(String m) => (id: BigInt.one, mensaje: m);

final eventosFalsos = <TtkEventoEntity>[
  TtkEventoEntity(
    codEvento: _uno,
    nombre: 'Aniversario 2026',
    lugar: 'Salón Los Pinos',
    fecha: _fecha,
    usaTickets: true,
    usaBingo: true,
    estado: 'BORRADOR',
    estadoTexto: 'Borrador',
    totalParticipantes: 4,
    totalEmpleados: 2,
    totalRecientes: 1,
    totalInvitados: 1,
    totalTipos: 2,
    totalTickets: 9,
    codBingo: _uno,
    estadoBingo: 'EN_JUEGO',
    puedeEditar: true,
    puedeEmitir: true,
    puedeEliminar: true,
  ),
  TtkEventoEntity(
    codEvento: BigInt.two,
    nombre:
        'Fiesta de fin de año con nombre bastante largo para probar el ancho',
    fecha: DateTime(2025, 12, 15),
    estado: 'EMITIDO',
    estadoTexto: 'Tickets emitidos',
    totalParticipantes: 180,
    totalEmpleados: 160,
    totalRecientes: 12,
    totalInvitados: 8,
    totalTipos: 3,
    totalTickets: 540,
    puedeVolverBorrador: true,
    puedeImprimir: true,
    puedeCerrar: true,
  ),
  TtkEventoEntity(
    codEvento: BigInt.from(3),
    nombre: 'Día del trabajador',
    fecha: DateTime(2025, 5, 1),
    estado: 'CERRADO',
    estadoTexto: 'Cerrado',
    puedeImprimir: true,
  ),
];

final tiposFalsos = <TtkTipoTicketEntity>[
  TtkTipoTicketEntity(
    codTipoTicket: _uno,
    codEvento: _uno,
    nombre: 'Almuerzo',
    leyenda: 'Válido el día del evento',
    cantEmpleado: 1,
    cantReciente: 1,
    cantInvitado: 1,
    colorHex: '#F4C430',
    orden: 1,
    totalVales: 4,
    totalParticipantes: 4,
    puedeEditar: true,
  ),
  TtkTipoTicketEntity(
    codTipoTicket: BigInt.two,
    codEvento: _uno,
    nombre: 'Bebida',
    cantEmpleado: 2,
    cantReciente: 1,
    orden: 2,
    totalVales: 5,
    totalParticipantes: 3,
    puedeEditar: true,
  ),
  TtkTipoTicketEntity(
    codTipoTicket: BigInt.from(3),
    codEvento: _uno,
    nombre: 'Bingo',
    cantEmpleado: 1,
    cantReciente: 1,
    cantInvitado: 1,
    colorHex: '#82C99A',
    orden: 3,
    totalVales: 4,
    totalParticipantes: 4,
    puedeEditar: true,
    daCartonBingo: true,
  ),
];

final participantesFalsos = <TtkParticipanteEntity>[
  TtkParticipanteEntity(
    codParticipante: _uno,
    codEvento: _uno,
    codEmpleado: BigInt.from(10),
    nombreCompleto: 'Quispe Mamani Juan Carlos',
    cargo: 'Operador de máquina',
    fechaIngreso: DateTime(2015, 3, 2),
    categoria: 'E',
    categoriaTexto: 'Empleado',
    totalVales: 3,
    resumenVales: 'Almuerzo x1 · Bebida x2',
    puedeEditar: true,
  ),
  TtkParticipanteEntity(
    codParticipante: BigInt.two,
    codEvento: _uno,
    codEmpleado: BigInt.from(11),
    nombreCompleto: 'Rojas Vargas María Fernanda de los Ángeles',
    cargo: 'Asistente de RRHH',
    fechaIngreso: DateTime(2026, 10, 1),
    categoria: 'R',
    categoriaTexto: 'Reciente',
    categoriaManual: true,
    totalVales: 2,
    resumenVales: 'Almuerzo x1 · Bebida x1',
    puedeEditar: true,
  ),
  TtkParticipanteEntity(
    codParticipante: BigInt.from(3),
    codEvento: _uno,
    nombreCompleto: 'Ana Gutiérrez',
    nombreInvitado: 'Ana Gutiérrez',
    documento: '4567890',
    codEmpleadoAnfitrion: BigInt.from(10),
    nombreAnfitrion: 'Quispe Mamani Juan Carlos',
    categoria: 'I',
    categoriaTexto: 'Invitado',
    totalVales: 1,
    resumenVales: 'Almuerzo x1',
    puedeEditar: true,
  ),
];

class TtkTicketsFalso implements TtkTicketsRepository {
  final List<String> llamadas = [];

  /// Cada llamada en lote: tipo, cantidad, participantes y categoría.
  final List<(BigInt, int?, List<BigInt>?, String?)> lotes = [];

  @override
  Future<TtkRespuesta> cambiarValesLote({
    required BigInt codEvento,
    required BigInt codTipoTicket,
    int? cantidad,
    List<BigInt>? participantes,
    String? categoria,
  }) async {
    lotes.add((codTipoTicket, cantidad, participantes, categoria));
    return _ok('Vales actualizados para 2 participantes.');
  }

  @override
  Future<List<TtkEventoEntity>> listarEventos({
    BigInt? codEvento,
    String? estado,
    int? anio,
  }) async =>
      codEvento == null
          ? eventosFalsos
          : eventosFalsos.where((e) => e.codEvento == codEvento).toList();

  @override
  Future<TtkRespuesta> guardarEvento(TtkEventoEntity evento) async =>
      _ok('Evento guardado.');
  @override
  Future<TtkRespuesta> eliminarEvento(BigInt codEvento) async =>
      _ok('Evento eliminado.');
  @override
  Future<TtkRespuesta> emitirEvento(BigInt codEvento) async =>
      _ok('Tickets emitidos.');
  @override
  Future<TtkRespuesta> volverBorrador(BigInt codEvento) async =>
      _ok('Volvió a borrador.');
  @override
  Future<TtkRespuesta> cerrarEvento(BigInt codEvento) async =>
      _ok('Evento cerrado.');
  @override
  Future<List<TtkTipoTicketEntity>> listarTipos(BigInt codEvento) async =>
      tiposFalsos;
  @override
  Future<TtkRespuesta> guardarTipo(TtkTipoTicketEntity tipo) async =>
      _ok('Tipo guardado.');
  @override
  Future<TtkRespuesta> eliminarTipo(BigInt codTipoTicket) async =>
      _ok('Tipo eliminado.');
  @override
  Future<List<TtkParticipanteEntity>> listarParticipantes(
    BigInt codEvento, {
    String? categoria,
    String? buscar,
  }) async =>
      participantesFalsos
          .where((p) => categoria == null || p.categoria == categoria)
          .toList();
  @override
  Future<List<TtkParticipanteEntity>> empleadosDisponibles(
    BigInt codEvento, {
    String? buscar,
  }) async => [
    TtkParticipanteEntity(
      codEmpleado: BigInt.from(20),
      nombreCompleto: 'Choque Flores Pedro',
      cargo: 'Chofer',
      fechaIngreso: DateTime(2020, 1, 1),
      categoria: 'E',
      categoriaTexto: 'Empleado',
    ),
  ];
  @override
  Future<TtkRespuesta> generarParticipantes(BigInt codEvento) async =>
      _ok('Se agregaron 120 empleados.');
  @override
  Future<TtkRespuesta> guardarParticipante(
    TtkParticipanteEntity participante, {
    bool conCategoria = true,
  }) async {
    llamadas.add('guardarParticipante:$conCategoria');
    return _ok('Participante guardado.');
  }

  @override
  Future<TtkRespuesta> eliminarParticipante(BigInt codParticipante) async =>
      _ok('Quitado.');
  @override
  Future<TtkRespuesta> restablecerParticipante(BigInt codParticipante) async =>
      _ok('Restablecido.');
  @override
  Future<List<TtkParticipanteTicketEntity>> listarVales({
    BigInt? codParticipante,
    BigInt? codEvento,
  }) async => [
    TtkParticipanteTicketEntity(
      codParticipanteTicket: _uno,
      codParticipante: codParticipante,
      codTipoTicket: _uno,
      nombreTipo: 'Almuerzo',
      colorHex: '#F4C430',
      cantidad: 1,
      cantidadDefecto: 1,
      rangoTexto: 'Sin numerar',
      puedeEditar: true,
    ),
  ];
  @override
  Future<TtkRespuesta> cambiarVale(TtkParticipanteTicketEntity vale) async =>
      _ok('Cantidad actualizada.');
  @override
  Future<TtkRespuesta> restablecerVale(
    BigInt codParticipante,
    BigInt codTipoTicket,
  ) async => _ok('Restablecido.');
  @override
  Future<List<TtkValeImpresionEntity>> valesParaImprimir(
    BigInt codEvento, {
    BigInt? codParticipante,
    BigInt? codTipoTicket,
  }) async => [];
}

// ═══════════════════════════════════════════════════════════════════════════
// BINGO
// ═══════════════════════════════════════════════════════════════════════════

const _letras = 'BINGO';
const _marcados = [3, 17, 33, 48, 61, 9, 22, 40, 55, 70, 12, 28];

final bingoFalso = TtkBingoEntity(
  codBingo: _uno,
  codEvento: _uno,
  nombreEvento: 'Aniversario 2026',
  fechaEvento: _fecha,
  nroBolillos: 75,
  filas: 5,
  columnas: 5,
  letras: _letras,
  conComodin: true,
  nroJuegos: 8,
  nroCartones: 300,
  codTipoTicket: BigInt.from(3),
  nombreTipoTicket: 'Bingo',
  valesBingo: 312,
  cartonesObjetivo: 312,
  cartonesFaltantes: 12,
  maxCartonesEmpleado: 1,
  tamRanking: 10,
  estado: 'EN_JUEGO',
  estadoTexto: 'En juego',
  nroGeneracion: 1,
  cartonesGenerados: 300,
  cartonesAsignados: 210,
  cartonesDisponibles: 90,
  empleadosConCarton: 210,
  juegosFinalizados: 2,
  nroJuegoActual: 3,
  nombreJuegoActual: 'Letra L',
  rangos: 'B 1-15 · I 16-30 · N 31-45 · G 46-60 · O 61-75',
  mensajeEstado:
      'Juego 3 en curso: Letra L. Hay 12 vales sin cartón: use «Generar» para crear los que faltan.',
  puedeConfigurar: false,
  puedeAsignar: true,
  puedeImprimir: true,
);

/// Bingo recién creado: todos los parámetros del cartón se pueden editar.
final bingoEnConfiguracionFalso = TtkBingoEntity(
  codBingo: _uno,
  codEvento: _uno,
  nombreEvento: 'Aniversario 2026',
  fechaEvento: _fecha,
  letras: _letras,
  conComodin: true,
  nroJuegos: 8,
  nroCartones: 300,
  maxCartonesEmpleado: 1,
  tamRanking: 10,
  estado: 'CONFIGURACION',
  estadoTexto: 'En configuración',
  rangos: 'B 1-15 · I 16-30 · N 31-45 · G 46-60 · O 61-75',
  mensajeEstado: 'Defina las figuras de cada juego y genere los cartones.',
  puedeConfigurar: true,
  puedeGenerar: true,
);

String _figuraL() {
  final b = StringBuffer();
  for (var i = 0; i < 25; i++) {
    b.write(i % 5 == 0 || i >= 20 ? '1' : '0');
  }
  return b.toString();
}

List<TtkBingoJuegoEntity> juegosFalsos() => [
  for (var n = 1; n <= 8; n++)
    TtkBingoJuegoEntity(
      codJuego: BigInt.from(n),
      codBingo: _uno,
      nroJuego: n,
      nombre: n == 3 ? 'Letra L' : 'Cartón lleno',
      figura: n == 3 ? _figuraL() : '1' * 25,
      filas: 5,
      columnas: 5,
      conComodin: true,
      casillasFigura: n == 3 ? 9 : 24,
      estado: n < 3 ? 'FINALIZADO' : (n == 3 ? 'EN_CURSO' : 'PENDIENTE'),
      estadoTexto: n < 3 ? 'Finalizado' : (n == 3 ? 'En curso' : 'Pendiente'),
      bolillosMarcados: n == 3 ? _marcados.length : 0,
      puedeEditarFigura: n > 3,
      puedeEditarPremio: n >= 3,
      premio: n == 3 ? 'Una canasta navideña' : null,
      puedeFinalizar: n == 3,
    ),
];

/// Dos ganadores del juego 3: una empleada (con foto) y un invitado (iniciales).
List<TtkBingoGanadorEntity> ganadoresVivoFalsos() => [
  TtkBingoGanadorEntity(
    codGanador: BigInt.one,
    nroJuego: 3,
    codEmpleado: BigInt.from(102),
    nombreEmpleado: 'ANA LUCÍA RÍOS VEGA',
  ),
  TtkBingoGanadorEntity(
    codGanador: BigInt.two,
    nroJuego: 3,
    nombreEmpleado: 'Invitado Pedro Gómez',
  ),
];

List<TtkBingoSorteoEntity> tableroFalso() => [
  for (var n = 1; n <= 75; n++)
    TtkBingoSorteoEntity(
      codBingo: _uno,
      nroJuego: 3,
      nroBolillo: n,
      columna: (n - 1) ~/ 15,
      letra: _letras[(n - 1) ~/ 15],
      etiqueta: '${_letras[(n - 1) ~/ 15]}-$n',
      marcado: _marcados.contains(n),
      orden: _marcados.contains(n) ? _marcados.indexOf(n) + 1 : null,
    ),
];

TtkBingoPublicoEntity publicoFalso({
  bool hayGanador = false,
  bool puedeAvisar = false,
  int nroGanadores = 1,
}) => TtkBingoPublicoEntity(
  puedeAvisar: puedeAvisar,
  codBingo: _uno,
  nombreEvento: 'Aniversario 2026',
  estado: 'EN_JUEGO',
  estadoTexto: 'En juego',
  nroBolillos: 75,
  filas: 5,
  columnas: 5,
  letras: _letras,
  conComodin: true,
  nroJuegos: 8,
  nroJuego: 3,
  nombreJuego: 'Letra L',
  figura: _figuraL(),
  estadoJuego: 'EN_CURSO',
  totalMarcados: _marcados.length,
  ultimoBolillo: _marcados.last,
  hayGanador: hayGanador,
  premio: 'Una canasta navideña',
  textoPremio:
      hayGanador
          ? 'Premio: Una canasta navideña'
          : 'Se está jugando por Una canasta navideña',
  reglaEmpate: _reglaEmpate,
  textoEmpate:
      !hayGanador
          ? 'Si hay empate: $_reglaEmpate'
          : (nroGanadores > 1
              ? '¡Empate! $nroGanadores cartones completaron la figura. $_reglaEmpate'
              : null),
  nroGanadores: hayGanador ? nroGanadores : 0,
  mensaje:
      !hayGanador
          ? 'Juego 3: Letra L'
          : (nroGanadores > 1
              ? '¡Hay $nroGanadores ganadores del juego 3!'
              : '¡Ya salió un ganador del juego 3!'),
);

const _reglaEmpate = 'Se resolverá tirando un dado; gana el número mayor.';

List<TtkRankingCartonEntity> rankingFalso({bool conBingoNuevo = false}) => [
  for (var i = 1; i <= 10; i++)
    TtkRankingCartonEntity(
      codCarton: BigInt.from(i),
      nroCarton: i * 7,
      codEmpleado: BigInt.from(100 + i),
      nombreEmpleado: 'Empleado número $i con apellido largo',
      nroJuego: 3,
      aciertos: i == 1 ? 9 : 9 - i ~/ 2,
      totalFigura: 9,
      faltantes: i == 1 ? 0 : i ~/ 2,
      esBingo: i == 1,
      esNuevo: i == 1 && conBingoNuevo,
      bolilloBingo: i == 1 ? 28 : null,
      puesto: i,
      mensaje:
          i == 1
              ? '¡BINGO! El cartón 7 completó la figura con el bolillo 28.'
              : 'Siga participando: al cartón ${i * 7} le faltan ${i ~/ 2} números.',
    ),
];

List<TtkBingoCeldaEntity> celdasFalsas(int nroCarton, {int juegos = 2}) => [
  for (var j = 1; j <= juegos; j++)
    for (var pos = 0; pos < 25; pos++)
      TtkBingoCeldaEntity(
        codCarton: BigInt.from(nroCarton),
        codBingo: _uno,
        nroCarton: nroCarton,
        nroJuego: j,
        nombreJuego: j == 1 ? 'Cartón lleno' : 'Letra L',
        posicion: pos,
        fila: pos ~/ 5,
        columna: pos % 5,
        numero:
            pos == 12
                ? 0
                : (pos % 5) * 15 + ((pos ~/ 5) * 3 + nroCarton + j) % 15 + 1,
        esComodin: pos == 12,
        enFigura: j == 1 || pos % 5 == 0 || pos >= 20,
        marcado: pos == 12 || pos % 4 == 0,
      ),
];

class TtkBingoFalso implements TtkBingoRepository {
  /// Cada asignación: cartón, participante y empleado que viajaron.
  final List<(BigInt, BigInt?, BigInt?)> asignaciones = [];
  final List<bool?> impresosAlAsignar = [];
  final List<(BigInt, bool)> formas = [];
  final List<BigInt> elegidos = [];
  final List<BigInt> cantados = [];
  final List<BigInt> atendidos = [];

  /// Estado del bingo para el participante y si el juego deja avisar «¡Bingo!».
  String estadoParticipante = 'ELECCION';
  bool puedeAvisar = false;

  /// Cuántas veces se llamó cada lectura: mide la carga que un evento genera.
  final Map<String, int> llamadas = {};
  Null _contar(String metodo) {
    llamadas[metodo] = (llamadas[metodo] ?? 0) + 1;
    return null;
  }

  /// El bingo que devuelve el listado (por defecto, uno en juego).
  TtkBingoEntity bingo = bingoFalso;

  @override
  Future<List<TtkBingoEntity>> listarBingos({
    BigInt? codBingo,
    BigInt? codEvento,
  }) async => [bingo];
  final List<TtkBingoEntity> guardados = [];
  @override
  Future<TtkRespuesta> guardarBingo(TtkBingoEntity bingo) async {
    guardados.add(bingo);
    return _ok('Configuración guardada.');
  }

  @override
  Future<TtkRespuesta> abrirEleccion(BigInt codBingo) async =>
      _ok('Elección abierta.');
  @override
  Future<TtkRespuesta> iniciarBingo(BigInt codBingo) async =>
      _ok('Bingo iniciado.');
  @override
  Future<TtkRespuesta> finalizarBingo(BigInt codBingo) async =>
      _ok('Bingo finalizado.');
  @override
  Future<List<TtkBingoJuegoEntity>> listarJuegos(BigInt codBingo) async {
    _contar('listarJuegos');
    return juegosFalsos();
  }

  final List<TtkBingoJuegoEntity> juegosGuardados = [];
  @override
  Future<TtkRespuesta> guardarJuego(TtkBingoJuegoEntity juego) async {
    juegosGuardados.add(juego);
    return _ok('Juego guardado.');
  }

  @override
  Future<TtkRespuesta> generarCartones(BigInt codBingo) async =>
      _ok('Cartones generados.');
  @override
  Future<List<TtkBingoCartonEntity>> listarCartones(
    BigInt codBingo, {
    bool? soloDisponibles,
    String? buscar,
    BigInt? codEmpleado,
    BigInt? codParticipante,
  }) async => [
    for (var n = 1; n <= 30; n++)
      TtkBingoCartonEntity(
        codCarton: BigInt.from(n),
        codBingo: _uno,
        nroCarton: n,
        codEmpleado: n.isEven && n % 6 != 0 ? BigInt.from(100 + n) : null,
        codParticipante: n.isEven ? BigInt.from(500 + n) : null,
        esInvitado: n % 6 == 0,
        nombreEmpleado:
            n % 6 == 0
                ? 'Invitada Ana Gutiérrez $n'
                : (n.isEven ? 'Empleado $n de la planta de producción' : null),
        origen: n.isEven ? (n % 4 == 0 ? 'E' : 'A') : null,
        origenTexto:
            n.isEven
                ? (n % 4 == 0
                    ? 'Lo eligió el participante'
                    : 'Asignado por el encargado')
                : 'Disponible',
        fechaAsignacion: n.isEven ? DateTime(2026, 12, 1) : null,
        impreso: n.isEven && n % 4 != 0,
        formaTexto: n.isEven ? (n % 4 != 0 ? 'Impreso' : 'En pantalla') : null,
        esGanador: n == 14,
        puedeAsignar: n.isOdd,
        puedeCambiarForma: n.isEven,
        puedeLiberar: n.isEven && n != 14,
      ),
  ];
  @override
  Future<List<TtkEmpleadoBingoEntity>> empleadosParaCarton(
    BigInt codBingo, {
    String? buscar,
  }) async => [
    TtkEmpleadoBingoEntity(
      codParticipante: BigInt.from(1),
      codEmpleado: BigInt.from(5),
      nombreCompleto: 'Mamani Pedro',
      cargo: 'Portero',
      categoriaTexto: 'Empleado',
      valesBingo: 2,
      cartonesAsignados: 1,
      puedeRecibir: true,
    ),
    TtkEmpleadoBingoEntity(
      codParticipante: BigInt.from(3),
      nombreCompleto: 'Ana Gutiérrez',
      categoriaTexto: 'Invitado',
      valesBingo: 1,
      puedeRecibir: true,
    ),
    TtkEmpleadoBingoEntity(
      codParticipante: BigInt.from(4),
      codEmpleado: BigInt.from(6),
      nombreCompleto: 'Rojas Vargas María',
      categoriaTexto: 'Reciente',
      valesBingo: 1,
      cartonesAsignados: 1,
    ),
  ];
  @override
  Future<TtkRespuesta> asignarCarton(
    BigInt codCarton, {
    BigInt? codParticipante,
    BigInt? codEmpleado,
    bool? impreso,
  }) async {
    asignaciones.add((codCarton, codParticipante, codEmpleado));
    impresosAlAsignar.add(impreso);
    return _ok('Cartón asignado.');
  }

  @override
  Future<TtkRespuesta> liberarCarton(BigInt codCarton) async =>
      _ok('Cartón liberado.');
  @override
  Future<TtkRespuesta> cambiarFormaCarton(
    BigInt codCarton, {
    required bool impreso,
  }) async {
    formas.add((codCarton, impreso));
    return _ok(impreso ? 'Se entrega impreso.' : 'Se juega en pantalla.');
  }

  @override
  Future<List<TtkBingoCeldaEntity>> celdasCarton(BigInt codCarton) async =>
      celdasFalsas(codCarton.toInt());
  @override
  Future<List<TtkBingoCeldaEntity>> cartonesParaImprimir(
    BigInt codBingo, {
    BigInt? codEmpleado,
    int? nroDesde,
    int? nroHasta,
    bool? soloAsignados,
    bool? soloImpresos,
  }) async => celdasFalsas(nroDesde ?? 1);
  @override
  Future<TtkRespuesta> comenzarJuego(BigInt codJuego) async =>
      _ok('Juego en curso.');
  @override
  Future<TtkRespuesta> finalizarJuego(BigInt codJuego) async =>
      _ok('Juego finalizado.');
  @override
  Future<TtkRespuesta> marcarBolillo(BigInt codBingo, int nroBolillo) async =>
      _ok('Bolillo $nroBolillo marcado.');
  @override
  Future<TtkRespuesta> quitarBolillo(BigInt codBingo, int nroBolillo) async =>
      _ok('Bolillo $nroBolillo quitado.');
  @override
  Future<TtkRankingCartonEntity?> validarCarton(
    BigInt codBingo,
    int nroCarton,
  ) async => rankingFalso().first;
  @override
  Future<TtkRespuesta> confirmarGanador(BigInt codBingo, int nroCarton) async =>
      _ok('Ganador confirmado.');
  @override
  Future<TtkRespuesta> anularGanador(BigInt codGanador) async =>
      _ok('Ganador anulado.');
  @override
  Future<List<TtkBingoGanadorEntity>> listarGanadores(BigInt codBingo) async =>
      _contar('listarGanadores') ??
      [
        TtkBingoGanadorEntity(
          codGanador: _uno,
          codJuego: _uno,
          codBingo: _uno,
          nroJuego: 1,
          nombreJuego: 'Cartón lleno',
          codCarton: BigInt.from(14),
          nroCarton: 14,
          nombreEmpleado: 'Empleado 14 de la planta de producción',
          ordenBolillo: 40,
          nroBolillo: 66,
        ),
      ];
  @override
  Future<TtkEstadoEncargadoEntity?> estadoEncargado(BigInt codBingo) async =>
      TtkEstadoEncargadoEntity(
        version: 5,
        publico: publicoFalso(),
        tablero: tableroFalso(),
        ranking: rankingFalso(),
        aviso: 'Bolillo O-70 marcado.',
        avisos: avisosFalsos(),
      );
  @override
  Future<TtkEstadoPublicoEntity?> estadoPublico(BigInt codBingo) async =>
      _contar('estadoPublico') ??
      TtkEstadoPublicoEntity(
        version: 5,
        publico: publicoFalso(puedeAvisar: puedeAvisar),
        tablero: tableroFalso(),
      );

  /// Lo que «el backend» hace antes de responder (p. ej. empujar el estado nuevo).
  void Function()? alAtender;

  @override
  Future<TtkRespuesta> atenderAviso(BigInt codAviso) async {
    atendidos.add(codAviso);
    alAtender?.call();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return _ok('Aviso atendido.');
  }

  @override
  Future<List<TtkBingoParticipanteEntity>> misBingos() async => [
    TtkBingoParticipanteEntity(
      codBingo: _uno,
      codEvento: _uno,
      nombreEvento: 'Aniversario 2026',
      fechaEvento: _fecha,
      estado: estadoParticipante,
      estadoTexto:
          estadoParticipante == 'EN_JUEGO' ? 'En juego' : 'Elija su cartón',
      conAviso: puedeAvisar,
      letras: _letras,
      nroJuegos: 8,
      maxCartonesEmpleado: 2,
      misCartones: 1,
      cartonesDisponibles: 40,
      puedeElegir: true,
      puedeVerEnVivo: true,
      mensaje: 'Elija su cartón: quedan 40 disponibles.',
    ),
  ];
  @override
  Future<List<TtkBingoCartonEntity>> cartonesDisponibles(
    BigInt codBingo,
  ) async => [
    for (var n = 1; n <= 40; n++)
      TtkBingoCartonEntity(
        codCarton: BigInt.from(n),
        codBingo: _uno,
        nroCarton: n * 3,
      ),
  ];
  @override
  Future<List<TtkBingoCartonEntity>> misCartones({BigInt? codBingo}) async =>
      _contar('misCartones') ??
      [
        TtkBingoCartonEntity(
          codCarton: BigInt.from(77),
          codBingo: _uno,
          nroCarton: 77,
          origen: 'E',
          origenTexto: 'Lo eligió usted',
          formaTexto: 'Se juega en pantalla',
        ),
      ];

  /// Con el juego 3, el que está en curso en [publicoFalso].
  @override
  Future<List<TtkBingoCeldaEntity>> verCarton(BigInt codCarton) async =>
      _contar('verCarton') ?? celdasFalsas(codCarton.toInt(), juegos: 3);
  @override
  Future<List<TtkBingoCeldaEntity>> misCeldas({BigInt? codBingo}) async =>
      celdasFalsas(77);
  @override
  Future<TtkRespuesta> elegirCarton(BigInt codCarton) async {
    elegidos.add(codCarton);
    return _ok('Cartón elegido.');
  }

  @override
  Future<TtkRespuesta> cantarBingo(BigInt codCarton) async {
    cantados.add(codCarton);
    return _ok('Aviso enviado: el encargado revisará el cartón $codCarton.');
  }
}

List<TtkBingoAvisoEntity> avisosFalsos() => [
  TtkBingoAvisoEntity(
    codAviso: BigInt.from(9),
    codBingo: _uno,
    nroJuego: 3,
    codCarton: BigInt.from(12),
    nroCarton: 12,
    nombreEmpleado: 'Empleado 12 de la planta de producción',
    impreso: true,
    fechaAviso: DateTime(2026, 12, 20, 20, 15, 3),
    mensaje:
        'El cartón 12 avisó «¡Bingo!» a las 20:15:03. Revíselo con «Validar».',
  ),
];

/// Canal en vivo falso: avisa «conectado» y deja empujar estados a mano.
class TtkVivoFalso implements TtkBingoVivoRepository {
  void Function(TtkEstadoEncargadoEntity)? _encargado;
  void Function(TtkEstadoPublicoEntity)? _publico;
  final List<void Function(bool)> _conexiones = [];
  int abiertas = 0;
  int cerradas = 0;

  void emitirEncargado(TtkEstadoEncargadoEntity e) => _encargado?.call(e);
  void emitirPublico(TtkEstadoPublicoEntity e) => _publico?.call(e);

  /// Corta o repone la conexión de todas las suscripciones abiertas.
  void cambiarConexion(bool conectado) {
    for (final c in _conexiones) {
      c(conectado);
    }
  }

  @override
  TtkSuscripcionVivo escucharEncargado(
    BigInt codBingo, {
    required void Function(TtkEstadoEncargadoEntity estado) alRecibir,
    required void Function(bool conectado) alCambiarConexion,
  }) {
    _encargado = alRecibir;
    _conexiones.add(alCambiarConexion);
    abiertas++;
    scheduleMicrotask(() => alCambiarConexion(true));
    return _Suscripcion(() {
      cerradas++;
      _conexiones.remove(alCambiarConexion);
    });
  }

  @override
  TtkSuscripcionVivo escucharPublico(
    BigInt codBingo, {
    required void Function(TtkEstadoPublicoEntity estado) alRecibir,
    required void Function(bool conectado) alCambiarConexion,
  }) {
    _publico = alRecibir;
    _conexiones.add(alCambiarConexion);
    abiertas++;
    scheduleMicrotask(() => alCambiarConexion(true));
    return _Suscripcion(() {
      cerradas++;
      _conexiones.remove(alCambiarConexion);
    });
  }
}

class _Suscripcion implements TtkSuscripcionVivo {
  _Suscripcion(this._alCerrar);

  final void Function() _alCerrar;

  @override
  void cerrar() => _alCerrar();
}
