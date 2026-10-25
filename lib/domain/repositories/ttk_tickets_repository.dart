import 'package:bosque_flutter/domain/entities/ttk_evento_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_participante_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_participante_ticket_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_tipo_ticket_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_vale_impresion_entity.dart';

/// Resultado de una escritura: el id que devolvió el SP y su `errormsg`,
/// que es el texto que se le muestra al usuario.
typedef TtkRespuesta = ({BigInt id, String mensaje});

/// Eventos, tipos de vale, participantes y vales (pantalla `ttkEventos/Eventos`).
abstract class TtkTicketsRepository {
  Future<List<TtkEventoEntity>> listarEventos({
    BigInt? codEvento,
    String? estado,
    int? anio,
  });
  Future<TtkRespuesta> guardarEvento(TtkEventoEntity evento);
  Future<TtkRespuesta> eliminarEvento(BigInt codEvento);
  Future<TtkRespuesta> emitirEvento(BigInt codEvento);
  Future<TtkRespuesta> volverBorrador(BigInt codEvento);
  Future<TtkRespuesta> cerrarEvento(BigInt codEvento);

  Future<List<TtkTipoTicketEntity>> listarTipos(BigInt codEvento);
  Future<TtkRespuesta> guardarTipo(TtkTipoTicketEntity tipo);
  Future<TtkRespuesta> eliminarTipo(BigInt codTipoTicket);

  Future<List<TtkParticipanteEntity>> listarParticipantes(
    BigInt codEvento, {
    String? categoria,
    String? buscar,
  });
  Future<List<TtkParticipanteEntity>> empleadosDisponibles(
    BigInt codEvento, {
    String? buscar,
  });
  Future<TtkRespuesta> generarParticipantes(BigInt codEvento);

  /// Sin [conCategoria] la categoría no viaja y el SP no la marca como manual.
  Future<TtkRespuesta> guardarParticipante(
    TtkParticipanteEntity participante, {
    bool conCategoria = true,
  });
  Future<TtkRespuesta> eliminarParticipante(BigInt codParticipante);
  Future<TtkRespuesta> restablecerParticipante(BigInt codParticipante);

  Future<List<TtkParticipanteTicketEntity>> listarVales({
    BigInt? codParticipante,
    BigInt? codEvento,
  });
  Future<TtkRespuesta> cambiarVale(TtkParticipanteTicketEntity vale);
  Future<TtkRespuesta> restablecerVale(
    BigInt codParticipante,
    BigInt codTipoTicket,
  );

  /// Fija (o vuelve a la cantidad por defecto, con [cantidad] null) un tipo de
  /// vale para [participantes], para todos o para una [categoria].
  Future<TtkRespuesta> cambiarValesLote({
    required BigInt codEvento,
    required BigInt codTipoTicket,
    int? cantidad,
    List<BigInt>? participantes,
    String? categoria,
  });
  Future<List<TtkValeImpresionEntity>> valesParaImprimir(
    BigInt codEvento, {
    BigInt? codParticipante,
    BigInt? codTipoTicket,
  });
}
