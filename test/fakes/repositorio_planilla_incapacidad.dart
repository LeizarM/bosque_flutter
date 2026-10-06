import 'package:bosque_flutter/domain/entities/planilla_incapacidad_entity.dart';
import 'package:bosque_flutter/domain/repositories/planilla_incapacidad_repository.dart';

/// Repositorio en memoria de la Planilla de Incapacidad.
class RepoPlanillaIncapacidadFalso implements PlanillaIncapacidadRepository {
  RepoPlanillaIncapacidadFalso({List<PlanillaIncapacidadEntity>? filas})
    : filas = filas ?? bajasDeMuestra();

  List<PlanillaIncapacidadEntity> filas;
  bool fallarAlMarcar = false;
  final marcadas = <(int, bool)>[];

  @override
  Future<List<PlanillaIncapacidadEntity>> listar({
    required DateTime desde,
    required DateTime hasta,
  }) async => [...filas];

  @override
  Future<void> marcarRevisado({
    required int idPIT,
    required bool revisado,
  }) async {
    if (fallarAlMarcar) {
      throw Exception(
        'Esa baja ya no está en la planilla de incapacidad. Actualiza la lista.',
      );
    }
    marcadas.add((idPIT, revisado));
  }
}

PlanillaIncapacidadEntity bajaDeMuestra({
  required int id,
  String nombre = 'Gutiérrez Mamani Juan Carlos Alberto',
  String motivo = 'FRACTURA EN EL PIE IZQUIERDO CON INMOVILIZACION TOTAL',
  double salario = 16100,
  int dias = 19,
  bool revisado = false,
  String seguro = 'CORDES ESPPAPEL - LA PAZ',
}) {
  final diario = salario / 30;
  final cordes = dias <= 3 ? 0 : dias - 3;
  return PlanillaIncapacidadEntity(
    idPIT: id,
    codPermiso: 1000 + id,
    numSeguro: id.isEven ? '0' : '9876543210',
    motivo: motivo,
    datoEmpleado: nombre,
    salarioMensual: salario,
    salarioDiario: diario,
    porcentajeAl75: diario * 0.75,
    nroBaja: 0,
    desde: DateTime(2026, 6, id, 8, 30),
    hasta: DateTime(2026, 6, id + dias - 1, 18, 30),
    diasBaja: dias,
    diasAsumidosCordes: cordes,
    totalDescuento: cordes * diario * 0.75,
    fueRevisado: revisado,
    fechaRevisado: revisado ? DateTime(2026, 7, 2, 9, 15) : null,
    codSeguro: 1,
    seguro: seguro,
  );
}

List<PlanillaIncapacidadEntity> bajasDeMuestra() => [
  bajaDeMuestra(id: 1),
  bajaDeMuestra(id: 2, nombre: 'Huanca Soto Maria Elizabeth', motivo: 'ATENCION MEDICA', salario: 3162.5, dias: 2),
  bajaDeMuestra(id: 3, nombre: 'Siñani Gutierrez Luis Fernando', salario: 7082.5, dias: 27, revisado: true, seguro: 'CORDES ESPPAPEL - COCHABAMBA'),
];
