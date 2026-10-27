import 'package:bosque_flutter/data/models/ttk_bingo_carton_model.dart';
import 'package:bosque_flutter/data/models/ttk_bingo_celda_model.dart';
import 'package:bosque_flutter/data/models/ttk_bingo_ganador_model.dart';
import 'package:bosque_flutter/data/models/ttk_bingo_juego_model.dart';
import 'package:bosque_flutter/data/models/ttk_bingo_model.dart';
import 'package:bosque_flutter/data/models/ttk_bingo_participante_model.dart';
import 'package:bosque_flutter/data/models/ttk_bingo_publico_model.dart';
import 'package:bosque_flutter/data/models/ttk_bingo_sorteo_model.dart';
import 'package:bosque_flutter/data/models/ttk_empleado_bingo_model.dart';
import 'package:bosque_flutter/data/models/ttk_estado_encargado_model.dart';
import 'package:bosque_flutter/data/models/ttk_estado_publico_model.dart';
import 'package:bosque_flutter/data/models/ttk_evento_model.dart';
import 'package:bosque_flutter/data/models/ttk_participante_model.dart';
import 'package:bosque_flutter/data/models/ttk_participante_ticket_model.dart';
import 'package:bosque_flutter/data/models/ttk_ranking_carton_model.dart';
import 'package:bosque_flutter/data/models/ttk_tipo_ticket_model.dart';
import 'package:bosque_flutter/data/models/ttk_vale_impresion_model.dart';
import 'package:bosque_flutter/core/network/tiempo_real.dart';
import 'package:bosque_flutter/domain/entities/ttk_bingo_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_participante_entity.dart';
import 'package:flutter_test/flutter_test.dart';

/// Los models leen los alias de columna de los SP (`sql/sp/*.sql`) tal cual:
/// banderas 0/1 → bool, PK → BigInt, fechas ISO. `toJson` es el cuerpo que
/// espera el backend: solo los parámetros del SP, sin nulls y con las PK en int.
void main() {
  group('Tickets', () {
    test('TtkEventoModel: p_list_ttk_Evento L', () {
      final m = TtkEventoModel.fromJson({
        'codEvento': 12,
        'nombre': 'Aniversario 2026',
        'descripcion': null,
        'fecha': '2026-12-20T00:00:00.000',
        'lugar': 'Salón',
        'usaTickets': 1,
        'usaBingo': 0,
        'mesesReciente': 3,
        'estado': 'BORRADOR',
        'estadoTexto': 'Borrador',
        'totalParticipantes': 10,
        'totalEmpleados': 8,
        'totalRecientes': 1,
        'totalInvitados': 1,
        'totalTipos': 2,
        'totalTickets': 25,
        'codBingo': null,
        'estadoBingo': null,
        'puedeEditar': 1,
        'puedeEmitir': 1,
        'puedeVolverBorrador': 0,
        'puedeImprimir': 0,
        'puedeCerrar': 0,
        'puedeEliminar': 1,
        'audUsuario': 34,
        'audFecha': '2026-10-01T10:00:00.000',
      });
      final e = m.toEntity();
      expect(e.codEvento, BigInt.from(12));
      expect(e.fecha, DateTime(2026, 12, 20));
      expect(e.usaTickets, isTrue);
      expect(e.usaBingo, isFalse);
      expect(e.puedeEmitir, isTrue);
      expect(e.puedeVolverBorrador, isFalse);
      expect(e.totalTickets, 25);
      expect(e.codBingo, isNull);

      final j = TtkEventoModel.fromEntity(e).toJson();
      expect(j, {
        'codEvento': 12,
        'nombre': 'Aniversario 2026',
        'fecha': '2026-12-20T00:00:00.000',
        'lugar': 'Salón',
        'usaTickets': 1,
        'usaBingo': 0,
        'mesesReciente': 3,
      });
      expect(
        j.containsKey('audUsuario'),
        isFalse,
        reason: 'audUsuario sale del token, nunca del cuerpo',
      );
    });

    test('TtkTipoTicketModel: p_list_ttk_TipoTicket L', () {
      final e =
          TtkTipoTicketModel.fromJson({
            'codTipoTicket': 3,
            'codEvento': 12,
            'nombre': 'Almuerzo',
            'leyenda': 'Válido el día del evento',
            'cantEmpleado': 1,
            'cantReciente': 1,
            'cantInvitado': 0,
            'colorHex': '#F4C430',
            'orden': 1,
            'totalVales': 10,
            'totalParticipantes': 10,
            'puedeEditar': 1,
            'daCartonBingo': 1,
          }).toEntity();
      expect(e.codTipoTicket, BigInt.from(3));
      expect(e.daCartonBingo, isTrue);
      expect(e.colorHex, '#F4C430');
      expect(e.puedeEditar, isTrue);
      final j = TtkTipoTicketModel.fromEntity(e).toJson();
      expect(j['codTipoTicket'], 3);
      expect(j['cantInvitado'], 0);
      expect(j.containsKey('totalVales'), isFalse);
    });

    test(
      'TtkParticipanteModel: L y E; sin categoría no se marca como manual',
      () {
        final e =
            TtkParticipanteModel.fromJson({
              'codParticipante': 7,
              'codEvento': 12,
              'codEmpleado': 501,
              'nombreCompleto': 'Quispe Mamani Juan',
              'nombreInvitado': null,
              'documento': null,
              'codEmpleadoAnfitrion': null,
              'nombreAnfitrion': '',
              'cargo': 'Operador',
              'fechaIngreso': '2015-03-02T00:00:00.000',
              'categoria': 'R',
              'categoriaTexto': 'Reciente',
              'categoriaManual': 1,
              'totalVales': 3,
              'resumenVales': 'Almuerzo x1 · Bebida x2',
              'observacion': null,
              'puedeEditar': 1,
            }).toEntity();
        expect(e.codEmpleado, BigInt.from(501));
        expect(e.esInvitado, isFalse);
        expect(e.categoriaManual, isTrue);
        expect(
          e.nombreAnfitrion,
          isNull,
          reason: 'el texto vacío del SP no llega como "" a la UI',
        );

        final conCategoria = TtkParticipanteModel.fromEntity(e).toJson();
        expect(conCategoria['categoria'], 'R');
        final sinCategoria = TtkParticipanteModel.fromEntity(
          e,
        ).toJson(conCategoria: false);
        expect(sinCategoria.containsKey('categoria'), isFalse);

        // Un empleado de la acción E (no tiene codParticipante).
        final emp =
            TtkParticipanteModel.fromJson({
              'codEmpleado': 9,
              'nombreCompleto': 'Choque Pedro',
              'cargo': null,
              'fechaIngreso': '2020-01-01T00:00:00.000',
              'categoria': 'E',
              'categoriaTexto': 'Empleado',
            }).toEntity();
        expect(emp.codParticipante, isNull);
        expect(emp.categoria, 'E');
        final alta =
            TtkParticipanteModel.fromEntity(
              const TtkParticipanteEntity().copyWith(categoria: 'I'),
            ).toJson();
        expect(alta, {'categoria': 'I'});
      },
    );

    test('TtkParticipanteTicketModel: L', () {
      final e =
          TtkParticipanteTicketModel.fromJson({
            'codParticipanteTicket': 1,
            'codParticipante': 7,
            'codTipoTicket': 3,
            'nombreTipo': 'Almuerzo',
            'colorHex': null,
            'cantidad': 2,
            'cantidadDefecto': 1,
            'cantidadManual': 1,
            'nroDesde': 15,
            'nroHasta': 16,
            'rangoTexto': 'N° 15 al 16',
            'puedeEditar': 0,
          }).toEntity();
      expect(e.cantidadManual, isTrue);
      expect(e.nroHasta, 16);
      expect(
        TtkParticipanteTicketModel.fromEntity(e.copyWith(cantidad: 4)).toJson(),
        {'codParticipante': 7, 'codTipoTicket': 3, 'cantidad': 4},
      );
    });

    test('TtkValeImpresionModel: ParticipanteTicket P', () {
      final j = {
        'codEvento': 12,
        'nombreEvento': 'Aniversario 2026',
        'fechaEvento': '2026-12-20T00:00:00.000',
        'lugar': 'Salón',
        'codTipoTicket': 3,
        'nombreTipo': 'Almuerzo',
        'leyenda': 'Válido el día del evento',
        'colorHex': '#F4C430',
        'codParticipante': 7,
        'nombreParticipante': 'Quispe Mamani Juan',
        'categoriaTexto': 'Empleado',
        'nroTicket': 15,
        'nroTicketTexto': '0015',
      };
      final e = TtkValeImpresionModel.fromJson(j).toEntity();
      expect(e.nroTicketTexto, '0015');
      expect(e.nroTicket, 15);
      expect(TtkValeImpresionModel.fromEntity(e).toJson(), j);
    });
  });

  group('Bingo', () {
    final bingoJson = <String, dynamic>{
      'codBingo': 1,
      'codEvento': 12,
      'nombreEvento': 'Aniversario 2026',
      'fechaEvento': '2026-12-20T00:00:00.000',
      'nroBolillos': 90,
      'filas': 5,
      'columnas': 5,
      'letras': 'BINGO',
      'conComodin': 0,
      'nroJuegos': 6,
      'nroCartones': 300,
      'codTipoTicket': 3,
      'nombreTipoTicket': 'Bingo',
      'valesBingo': 312,
      'cartonesObjetivo': 312,
      'cartonesFaltantes': 12,
      'maxCartonesEmpleado': 2,
      'tamRanking': 15,
      'estado': 'ELECCION',
      'estadoTexto': 'Elección de cartones abierta',
      'nroGeneracion': 2,
      'fechaGeneracion': '2026-12-01T09:00:00.000',
      'cartonesGenerados': 300,
      'cartonesAsignados': 120,
      'cartonesDisponibles': 180,
      'empleadosConCarton': 110,
      'juegosFinalizados': 0,
      'nroJuegoActual': null,
      'nombreJuegoActual': null,
      'rangos': 'B 1-18 · I 19-36 · N 37-54 · G 55-72 · O 73-90',
      'mensajeEstado': '180 cartones disponibles.',
      'puedeConfigurar': 1,
      'puedeGenerar': 0,
      'puedeAbrirEleccion': 0,
      'puedeIniciar': 1,
      'puedeAsignar': 1,
      'puedeFinalizar': 0,
      'puedeImprimir': 1,
    };

    test('TtkBingoModel: p_list_ttk_Bingo L y cuerpo de /bingo/guardar', () {
      final e = TtkBingoModel.fromJson(bingoJson).toEntity();
      expect(e.nroBolillos, 90);
      expect(e.conComodin, isFalse);
      expect(e.puedeIniciar, isTrue);
      expect(e.puedeGenerar, isFalse);
      expect(e.nroJuegoActual, isNull);
      expect(e.porVales, isTrue);
      expect(e.nombreTipoTicket, 'Bingo');
      expect(e.cartonesObjetivo, 312);
      expect(e.cartonesFaltantes, 12);
      final j =
          TtkBingoModel.fromEntity(
            e.copyWith(conComodin: true, tamRanking: 20),
          ).toJson();
      expect(j, {
        'codBingo': 1,
        'codEvento': 12,
        'nroBolillos': 90,
        'filas': 5,
        'columnas': 5,
        'letras': 'BINGO',
        'conComodin': 1,
        'nroJuegos': 6,
        'nroCartones': 300,
        'codTipoTicket': 3,
        'maxCartonesEmpleado': 2,
        'tamRanking': 20,
        'modalidad': 'A',
        'conAviso': 0,
        'reglaEmpate': '',
      });
      final sinVale =
          TtkBingoModel.fromEntity(e.copyWith(sinTipoTicket: true)).toJson();
      expect(
        sinVale['codTipoTicket'],
        0,
        reason: '0 quita el enlace con el vale',
      );
      expect(
        const TtkBingoEntity().nroBolillos,
        75,
        reason:
            'los valores por defecto los pone el SP; la entidad solo arranca igual',
      );
    });

    test('TtkBingoJuegoModel: L y cuerpo de /bingo/juego/guardar', () {
      final e =
          TtkBingoJuegoModel.fromJson({
            'codJuego': 4,
            'codBingo': 1,
            'nroJuego': 2,
            'nombre': 'Letra L',
            'figura': '1000010000100001000011111',
            'filas': 5,
            'columnas': 5,
            'conComodin': 1,
            'casillasFigura': 9,
            'estado': 'EN_CURSO',
            'estadoTexto': 'En curso',
            'fechaInicio': '2026-12-20T20:00:00.000',
            'fechaFin': null,
            'bolillosMarcados': 7,
            'ganadoresConfirmados': 0,
            'puedeEditarFigura': 0,
            'puedeComenzar': 0,
            'puedeFinalizar': 0,
          }).toEntity();
      expect(e.enCurso, isTrue);
      expect(e.figura.length, 25);
      expect(TtkBingoJuegoModel.fromEntity(e).toJson(), {
        'codJuego': 4,
        'nombre': 'Letra L',
        'figura': '1000010000100001000011111',
        'premio': '',
      });
    });

    test('TtkBingoCartonModel: L, D y M', () {
      final l =
          TtkBingoCartonModel.fromJson({
            'codCarton': 55,
            'codBingo': 1,
            'nroCarton': 17,
            'codEmpleado': 501,
            'nombreEmpleado': 'Quispe Mamani Juan',
            'origen': 'A',
            'origenTexto': 'Asignado por el encargado',
            'fechaAsignacion': '2026-12-02T08:30:00.000',
            'esGanador': 0,
            'puedeAsignar': 0,
            'puedeLiberar': 1,
          }).toEntity();
      expect(l.asignado, isTrue);
      expect(l.puedeLiberar, isTrue);
      // D: solo codCarton, codBingo y nroCarton (sin dueños).
      final d =
          TtkBingoCartonModel.fromJson({
            'codCarton': 56,
            'codBingo': 1,
            'nroCarton': 18,
          }).toEntity();
      expect(d.asignado, isFalse);
      expect(d.nombreEmpleado, isNull);
      expect(TtkBingoCartonModel.fromEntity(l).toJson(), {
        'codCarton': 55,
        'codEmpleado': 501,
      });
      final inv =
          TtkBingoCartonModel.fromJson({
            'codCarton': 57,
            'codBingo': 1,
            'nroCarton': 19,
            'codEmpleado': null,
            'codParticipante': 900,
            'nombreEmpleado': 'Ana Gutiérrez',
            'esInvitado': 1,
          }).toEntity();
      expect(inv.asignado, isTrue);
      expect(inv.esInvitado, isTrue);
      expect(TtkBingoCartonModel.fromEntity(inv).toJson(), {
        'codCarton': 57,
        'codParticipante': 900,
      });
    });

    test('TtkBingoCeldaModel: C / E / M / P', () {
      final j = {
        'codCarton': 55,
        'codBingo': 1,
        'nroCarton': 17,
        'codEmpleado': 501,
        'nombreEmpleado': 'Quispe Mamani Juan',
        'nroJuego': 1,
        'nombreJuego': 'Cartón lleno',
        'posicion': 12,
        'fila': 2,
        'columna': 2,
        'numero': 0,
        'esComodin': 1,
        'enFigura': 1,
        'marcado': 1,
      };
      final e = TtkBingoCeldaModel.fromJson(j).toEntity();
      expect(e.esComodin, isTrue);
      expect(e.fila, 2);
      expect(TtkBingoCeldaModel.fromEntity(e).toJson(), j);
    });

    test('TtkBingoSorteoModel: T y cuerpo de marcar', () {
      final e =
          TtkBingoSorteoModel.fromJson({
            'codSorteo': null,
            'codBingo': 1,
            'nroJuego': 3,
            'nroBolillo': 28,
            'columna': 1,
            'letra': 'I',
            'etiqueta': 'I-28',
            'marcado': 0,
            'orden': null,
          }).toEntity();
      expect(e.marcado, isFalse);
      expect(e.etiqueta, 'I-28');
      expect(TtkBingoSorteoModel.fromEntity(e).toJson(), {
        'codBingo': 1,
        'nroBolillo': 28,
      });
    });

    test('TtkBingoGanadorModel: L', () {
      final e =
          TtkBingoGanadorModel.fromJson({
            'codGanador': 2,
            'codJuego': 4,
            'codBingo': 1,
            'nroJuego': 2,
            'nombreJuego': 'Letra L',
            'codCarton': 55,
            'nroCarton': 17,
            'codEmpleado': 501,
            'nombreEmpleado': 'Quispe Mamani Juan',
            'ordenBolillo': 21,
            'nroBolillo': 66,
            'puedeAnular': 1,
          }).toEntity();
      expect(e.puedeAnular, isTrue);
      expect(e.nroBolillo, 66);
      expect(TtkBingoGanadorModel.fromEntity(e).toJson(), {
        'codBingo': 1,
        'nroCarton': 17,
      });
    });

    test(
      'DTOs: BingoParticipante (A), RankingCarton (R/V) y EmpleadoBingo (E)',
      () {
        final a =
            TtkBingoParticipanteModel.fromJson({
              'codBingo': 1,
              'codEvento': 12,
              'nombreEvento': 'Aniversario 2026',
              'fechaEvento': '2026-12-20T00:00:00.000',
              'estado': 'ELECCION',
              'estadoTexto': 'Elija su cartón',
              'filas': 5,
              'columnas': 5,
              'letras': 'BINGO',
              'conComodin': 1,
              'nroJuegos': 8,
              'maxCartonesEmpleado': 1,
              'misCartones': 0,
              'cartonesDisponibles': 40,
              'puedeElegir': 1,
              'puedeVerEnVivo': 0,
              'mensaje': 'Elija su cartón: quedan 40 disponibles.',
            }).toEntity();
        expect(a.puedeElegir, isTrue);
        expect(a.mensaje, contains('40'));

        final r =
            TtkRankingCartonModel.fromJson({
              'codCarton': 55,
              'nroCarton': 17,
              'codEmpleado': 501,
              'nombreEmpleado': 'Quispe Mamani Juan',
              'nroJuego': 3,
              'aciertos': 9,
              'totalFigura': 9,
              'faltantes': 0,
              'esBingo': 1,
              'ordenBingo': 12,
              'bolilloBingo': 28,
              'esNuevo': 1,
              'esGanadorConfirmado': 0,
              'puesto': 1,
              'mensaje':
                  '¡BINGO! El cartón 17 completó la figura con el bolillo 28.',
            }).toEntity();
        expect(r.esNuevo, isTrue);
        expect(r.avance, 1.0);

        final em =
            TtkEmpleadoBingoModel.fromJson({
              'codParticipante': 7,
              'codEmpleado': 501,
              'nombreCompleto': 'Quispe Mamani Juan',
              'cargo': 'Operador',
              'categoriaTexto': 'Empleado',
              'valesBingo': 2,
              'cartonesAsignados': 1,
              'puedeRecibir': 0,
            }).toEntity();
        expect(em.puedeRecibir, isFalse);
        expect(em.codParticipante, BigInt.from(7));
        expect(em.valesBingo, 2);
        expect(em.categoriaTexto, 'Empleado');
      },
    );

    test(
      'EstadoPublico y EstadoEncargado: lo que llega por POST y por el tópico',
      () {
        final publico = {
          'codBingo': 1,
          'nombreEvento': 'Aniversario 2026',
          'estado': 'EN_JUEGO',
          'estadoTexto': 'En juego',
          'nroBolillos': 75,
          'filas': 5,
          'columnas': 5,
          'letras': 'BINGO',
          'conComodin': 1,
          'nroJuegos': 8,
          'nroJuego': 3,
          'nombreJuego': 'Letra L',
          'figura': '1000010000100001000011111',
          'estadoJuego': 'EN_CURSO',
          'totalMarcados': 2,
          'ultimoBolillo': 28,
          'hayGanador': 0,
          'puedeAvisar': 1,
          'nroGanadores': 0,
          'mensaje': 'Juego 3: Letra L',
        };
        final tablero = [
          {
            'codSorteo': 9,
            'codBingo': 1,
            'nroJuego': 3,
            'nroBolillo': 28,
            'columna': 1,
            'letra': 'I',
            'etiqueta': 'I-28',
            'marcado': 1,
            'orden': 2,
          },
          {
            'codSorteo': null,
            'codBingo': 1,
            'nroJuego': 3,
            'nroBolillo': 29,
            'columna': 1,
            'letra': 'I',
            'etiqueta': 'I-29',
            'marcado': 0,
            'orden': null,
          },
        ];
        final p =
            TtkEstadoPublicoModel.fromJson({
              'version': 41,
              'publico': publico,
              'tablero': tablero,
            }).toEntity();
        expect(p.version, 41);
        expect(p.publico?.ultimoBolillo, 28);
        expect(p.tablero.where((b) => b.marcado).length, 1);
        expect(TtkBingoPublicoModel.fromEntity(p.publico!).toJson(), publico);

        final enc =
            TtkEstadoEncargadoModel.fromJson({
              'version': 42,
              'publico': publico,
              'tablero': tablero,
              'ranking': [
                {
                  'codCarton': 55,
                  'nroCarton': 17,
                  'aciertos': 9,
                  'totalFigura': 9,
                  'faltantes': 0,
                  'esBingo': 1,
                  'esNuevo': 1,
                  'puesto': 1,
                  'mensaje': '¡BINGO!',
                },
                {
                  'codCarton': 56,
                  'nroCarton': 18,
                  'aciertos': 7,
                  'totalFigura': 9,
                  'faltantes': 2,
                  'esBingo': 0,
                  'esNuevo': 0,
                  'puesto': 2,
                  'mensaje': 'Siga',
                },
              ],
              'aviso': 'Bolillo I-28 marcado. ¡BINGO!',
              'avisos': [
                {
                  'codAviso': 9,
                  'codBingo': 1,
                  'codJuego': 3,
                  'nroJuego': 3,
                  'codCarton': 55,
                  'nroCarton': 17,
                  'nombreEmpleado': 'Pérez Juan',
                  'impreso': 1,
                  'estado': 'P',
                  'fechaAviso': '2026-12-20T20:15:03.000',
                  'mensaje': 'El cartón 17 avisó «¡Bingo!» a las 20:15:03.',
                },
              ],
            }).toEntity();
        expect(enc.ranking, hasLength(2));
        expect(enc.bingosNuevos.single.nroCarton, 17);
        expect(enc.aviso, contains('BINGO'));
        expect(enc.publico?.puedeAvisar, isTrue);
        expect(enc.avisos.single.nroCarton, 17);
        expect(enc.avisos.single.impreso, isTrue);
        expect(enc.avisos.single.fechaAviso, DateTime(2026, 12, 20, 20, 15, 3));
        // Ida y vuelta: lo que se serializa se vuelve a leer igual.
        final otra =
            TtkEstadoEncargadoModel.fromJson(
              TtkEstadoEncargadoModel.fromEntity(enc).toJson(),
            ).toEntity();
        expect(otra.version, 42);
        expect(otra.tablero.first.etiqueta, 'I-28');
        expect(otra.bingosNuevos.single.nroCarton, 17);
        expect(otra.avisos.single.codAviso, BigInt.from(9));
        expect(otra.avisos.single.mensaje, contains('avisó'));

        // Un estado sin `publico` (bingo sin juegos) no revienta.
        expect(
          TtkEstadoPublicoModel.fromJson({'version': 1}).toEntity().tablero,
          isEmpty,
        );

        // Con ganador confirmado el público solo sabe que lo hubo.
        final conGanador =
            TtkEstadoPublicoModel.fromJson({
              'version': 43,
              'publico': {
                ...publico,
                'hayGanador': 1,
                'mensaje': '¡Ya salió un ganador del juego 3!',
              },
            }).toEntity();
        expect(conGanador.publico?.hayGanador, isTrue);
        expect(conGanador.publico?.mensaje, contains('ganador'));

        // Premio, desempate y ganadores con nombre y codEmpleado (la foto).
        final conNombres =
            TtkEstadoPublicoModel.fromJson({
              'version': 44,
              'publico': {
                ...publico,
                'hayGanador': 1,
                'premio': 'Un televisor',
                'textoPremio': 'Premio: Un televisor',
                'reglaEmpate': 'Dado; gana el mayor.',
                'textoEmpate':
                    '¡Empate! 2 cartones completaron la figura. Dado; gana el mayor.',
                'nroGanadores': 2,
              },
              'ganadores': [
                {
                  'codGanador': 3,
                  'nroJuego': 3,
                  'codEmpleado': 2,
                  'nombreEmpleado': 'RODRIGO RAMOS',
                },
                {
                  'codGanador': 4,
                  'nroJuego': 3,
                  'nombreEmpleado': 'Invitada Externa',
                },
              ],
            }).toEntity();
        expect(conNombres.publico?.textoPremio, 'Premio: Un televisor');
        expect(conNombres.publico?.nroGanadores, 2);
        expect(conNombres.publico?.textoEmpate, startsWith('¡Empate!'));
        expect(conNombres.ganadores, hasLength(2));
        expect(conNombres.ganadores.first.codEmpleado, BigInt.two);
        expect(conNombres.ganadores.last.codEmpleado, isNull);
      },
    );
  });

  group('Forma de juego y aviso «¡Bingo!»', () {
    test('bingo: modalidad, conAviso y cartones impresos ida y vuelta', () {
      final e =
          TtkBingoModel.fromJson({
            'codBingo': 1,
            'modalidad': 'P',
            'modalidadTexto': 'En pantalla',
            'conAviso': 1,
            'cartonesImpresos': 0,
          }).toEntity();
      expect(e.modalidad, 'P');
      expect(e.conAviso, isTrue);
      expect(e.formaPorCarton, isFalse);
      final j =
          TtkBingoModel.fromEntity(
            e.copyWith(modalidad: 'A', conAviso: false),
          ).toJson();
      expect(j['modalidad'], 'A');
      expect(j['conAviso'], 0);
      // Sin la columna (bingo viejo) la forma por defecto es «ambos».
      expect(TtkBingoModel.fromJson({'codBingo': 1}).toEntity().modalidad, 'A');
    });

    test('cartón, ranking y participante leen la forma y el botón', () {
      final k =
          TtkBingoCartonModel.fromJson({
            'codCarton': 80,
            'nroCarton': 12,
            'codEmpleado': 7,
            'impreso': 1,
            'formaTexto': 'Impreso',
            'puedeCambiarForma': 1,
          }).toEntity();
      expect(k.impreso, isTrue);
      expect(k.formaTexto, 'Impreso');
      expect(k.puedeCambiarForma, isTrue);
      expect(
        TtkRankingCartonModel.fromJson({
          'nroCarton': 12,
          'impreso': 1,
        }).toEntity().impreso,
        isTrue,
      );
      final p =
          TtkBingoParticipanteModel.fromJson({
            'codBingo': 1,
            'modalidad': 'I',
            'conAviso': 1,
          }).toEntity();
      expect(p.modalidad, 'I');
      expect(p.conAviso, isTrue);
    });
  });

  group('Tiempo real', () {
    test('URL del WebSocket: misma base que la API, con ws/wss', () {
      expect(
        urlTiempoReal('https://app.esppapel.com:8443'),
        'wss://app.esppapel.com:8443/ws',
      );
      expect(
        urlTiempoReal('http://192.168.3.107:9223'),
        'ws://192.168.3.107:9223/ws',
      );
      expect(urlTiempoReal('http://servidor/api/'), 'ws://servidor/api/ws');
    });

    test('Reintentos con espera creciente y tope de 30 s', () {
      expect(
        [for (var i = 0; i < 8; i++) esperaReintento(i).inSeconds],
        [1, 2, 4, 8, 16, 30, 30, 30],
      );
    });
  });
}
