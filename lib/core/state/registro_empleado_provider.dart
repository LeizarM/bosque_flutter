import 'dart:typed_data';

import 'package:bosque_flutter/core/state/empleados_dependientes_provider.dart';
import 'package:bosque_flutter/data/repositories/registro_empleado_impl.dart';
import 'package:bosque_flutter/domain/entities/Ciudad_entity.dart';
import 'package:bosque_flutter/domain/entities/afiliacion_seguro_entity.dart';
import 'package:bosque_flutter/domain/entities/banco_entity.dart';
import 'package:bosque_flutter/domain/entities/cargo_sucursal_entity.dart';
import 'package:bosque_flutter/domain/entities/educacion_entity.dart';
import 'package:bosque_flutter/domain/entities/email_entity.dart';
import 'package:bosque_flutter/domain/entities/empleado_cargo_entity.dart';
import 'package:bosque_flutter/domain/entities/empleado_entity.dart';
import 'package:bosque_flutter/domain/entities/experiencia_laboral_entity.dart';
import 'package:bosque_flutter/domain/entities/formacion_entity.dart';
import 'package:bosque_flutter/domain/entities/licencia_conducir_entity.dart';
import 'package:bosque_flutter/domain/entities/nro_cuenta_bancaria_entity.dart';
import 'package:bosque_flutter/domain/entities/persona_entity.dart';
import 'package:bosque_flutter/domain/entities/relacion_laboral_entity.dart';
import 'package:bosque_flutter/domain/entities/seguro_entity.dart';
import 'package:bosque_flutter/domain/entities/telefono_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_educacion_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_licencia_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_relacion_laboral_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_seguro_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

//provider para obtener la lista de empleados con filtros
final getListaEmpleados = FutureProvider.family<
  List<EmpleadoEntity>,
  (String?, int?, int, int, int?)
>((ref, params) async {
  final repo = RegistroEmpleadoImpl();
  final empleados = await repo.getLstEmpleados(
    params.$1,
    params.$2,
    params.$3,
    params.$4,
    params.$5,
  );
  return empleados;
});
//Provider para registrar empleado
final registrarEmpleadoProvider =
    FutureProvider.family<EmpleadoEntity, EmpleadoEntity>((
      ref,
      empleado,
    ) async {
      final repo = RegistroEmpleadoImpl();
      final registrado = await repo.registrarEmpleado(empleado);
      return registrado;
    });
//provider para obtener la lista de personas que no son empleados
final getLstPersona = FutureProvider.family<List<PersonaEntity>, String>((
  ref,
  buscarPersona,
) async {
  final repo = RegistroEmpleadoImpl();
  final personas = await repo.getLstPersonas(buscarPersona);
  return personas;
});
//provider para obtener los datos de una persona por su codPersona
/*final obtenerPersonaProvider = FutureProvider.family<PersonaEntity, int>(
  (ref, codPersona) async {
    final repo = RegistroEmpleadoImpl();
    return await repo.obtenerPersona(codPersona);
  },
);*/
//provider combinado pais y ciudad
final currentNacionalidadProvider = StateProvider<int?>((ref) => null);
final ciudadesCombinadasProvider = FutureProvider<List<CiudadEntity>>((
  ref,
) async {
  const int COD_PAIS_BOLIVIA = 1;

  // 1. Obtener la nacionalidad seleccionada (Esto hace que el provider sea reactivo)
  final int nacionalidadId = ref.watch(currentNacionalidadProvider) ?? 0;

  // 2. Obtener las ciudades de la nacionalidad actual (usando .future para esperar el resultado)
  final ciudadesNac = await ref.watch(ciudadProvider(nacionalidadId).future);

  // 3. Obtener condicionalmente las ciudades de Bolivia (ID 1)
  List<CiudadEntity> ciudadesBol = [];
  if (nacionalidadId != 0 && nacionalidadId != COD_PAIS_BOLIVIA) {
    ciudadesBol = await ref.watch(ciudadProvider(COD_PAIS_BOLIVIA).future);
  }

  // 4. Combinar listas, priorizando las de la nacionalidad seleccionada (para asegurar unicidad)
  final Set<int> addedIds = ciudadesNac.map((c) => c.codCiudad).toSet();
  final List<CiudadEntity> ciudadesFinal = [...ciudadesNac];

  for (final ciudad in ciudadesBol) {
    if (!addedIds.contains(ciudad.codCiudad)) {
      ciudadesFinal.add(ciudad);
    }
  }

  return ciudadesFinal;
});
//provider para el manejo de telefonos
/*final telefonoProvider = FutureProvider.family<List<TelefonoEntity>,int>((ref, codPersona)async{
 final repo = RegistroEmpleadoImpl();
  final telefonos = await repo.obtenerTelefono(codPersona);
  return telefonos;
});*/
//provider para el manejo de educacion
final registrarEducacionProvider =
    FutureProvider.family<EducacionEntity, EducacionEntity>((
      ref,
      educacion,
    ) async {
      final repo = RegistroEmpleadoImpl();
      final registrado = await repo.registrarEducacion(educacion);
      return registrado;
    });
//provider para obtener la lista de educacion de un empleado
final educacionProvider = FutureProvider.family<List<EducacionEntity>, int>((
  ref,
  codEmpleado,
) async {
  final repo = RegistroEmpleadoImpl();
  final educacion = await repo.obtenerEducacion(codEmpleado);
  return educacion;
});
//provider para eliminar una educacion por su codigo
final eliminarEducacionProvider = FutureProvider.family<void, int>((
  ref,
  codEducacion,
) async {
  final repo = RegistroEmpleadoImpl();
  await repo.eliminarEducacion(codEducacion);
});
//provider para obtener la lista de tipos de educacion
final obtenerTipoEducacion = FutureProvider<List<TipoEducacionEntity>>((
  ref,
) async {
  final repo = RegistroEmpleadoImpl();
  final tipoEducacion = await repo.obtenerTipoEducacion();
  return tipoEducacion;
});
//guardar datos temporalmente para educacion
final tempEducacionListProvider = StateProvider<List<EducacionEntity>>(
  (ref) => [],
);

//guardar datos temporalmente para formacion
final tempFormacionListProvider = StateProvider<List<FormacionEntity>>(
  (ref) => [],
);

//guardar datos temporalmente para experiencia laboral
final tempExperienciaListProvider =
    StateProvider<List<ExperienciaLaboralEntity>>((ref) => []);

final tempRegistroFuncionesListProvider =
    StateProvider<List<Map<String, dynamic>>>((ref) => []);

//OBTENER CARGO X SUCURSAL
final cargoXsucursalProvider =
    FutureProvider.family<List<CargoSucursalEntity>, int>((
      ref,
      codSucursal,
    ) async {
      final repo = RegistroEmpleadoImpl();
      final cargoXSuc = await repo.obtenerCargoXsucursal(codSucursal);
      return cargoXSuc;
    });
//REGISTRAR RELACION LABORAL
final registrarRelacionLaboral =
    FutureProvider.family<RelacionLaboralEntity, RelacionLaboralEntity>((
      ref,
      relacion,
    ) async {
      final repo = RegistroEmpleadoImpl();
      final registrarRelEmp = await repo.registrarRelacionLaboral(relacion);
      return registrarRelEmp;
    });
final tempRelacionLaboralListProvider =
    StateProvider<List<RelacionLaboralEntity>>((ref) => []);
final tempCuentasBancariasProvider =
    StateProvider<List<NroCuentaBancariaEntity>>((ref) => []);

//OBTENER BANCOS
final obtenerBancos = FutureProvider<List<BancoEntity>>((ref) async {
  final repo = RegistroEmpleadoImpl();
  final listaBancos = await repo.getBancos();
  return listaBancos;
});
//provider para obtener la lista de tipos de educacion
final getTipoRelacionLaboral = FutureProvider<List<TipoRelacionLaboralEntity>>((
  ref,
) async {
  final repo = RegistroEmpleadoImpl();
  final tipoRelLab = await repo.getTipoRelacionLaboral();
  return tipoRelLab;
});
//Reporte nomina empleados
final rptNominaEmpleados = FutureProvider<Uint8List>((ref) async {
  final repo = RegistroEmpleadoImpl();
  return await repo.rptNominaEmpleados();
});
//guardar datos temporales persona
final tempPersonaProvider = StateProvider<PersonaEntity?>((ref) => null);
//guardar datos temporales telefono
final tempTelefonoListProvider = StateProvider<List<TelefonoEntity>>(
  (ref) => [],
);
// guardar datos temporales email
final tempEmailListProvider = StateProvider<List<EmailEntity>>((ref) => []);
//Provider para registrar el cargo del empleado
final registrarEmpleadoCargoProvider =
    FutureProvider.family<EmpleadoCargoEntity, EmpleadoCargoEntity>((
      ref,
      empleadoCargo,
    ) async {
      final repo = RegistroEmpleadoImpl();
      final registrarCargo = await repo.registroEmpleadoCargo(empleadoCargo);
      return registrarCargo;
    });
final registroCuentaBancaria = FutureProvider.family<
  NroCuentaBancariaEntity,
  NroCuentaBancariaEntity
>((ref, nroCuenta) async {
  final repo = RegistroEmpleadoImpl();
  final registrarCuentaBancaria = await repo.registrarCuentaBancaria(nroCuenta);
  return registrarCuentaBancaria;
});
//provider para obtener la lista de cuentas bancarias de un empleado
final cuentaBancariaEmpleadoProvider =
    FutureProvider.family<List<NroCuentaBancariaEntity>, int>((
      ref,
      codEmpleado,
    ) async {
      final repo = RegistroEmpleadoImpl();
      final cuenta = await repo.getCuentaBancoXEmpleado(codEmpleado);
      return cuenta;
    });
//provider para eliminar una cuenta bancaria por su codigo
final eliminarCuentaBancaria = FutureProvider.family<void, int>((
  ref,
  codCuenta,
) async {
  final repo = RegistroEmpleadoImpl();
  await repo.eliminarCuentaBancaria(codCuenta);
});
//provider para eliminar una cuenta bancaria por su codigo
final eliminarRelacionLaboral = FutureProvider.family<void, int>((
  ref,
  codRelEmplEmpr,
) async {
  final repo = RegistroEmpleadoImpl();
  await repo.eliminarRelacionLaboral(codRelEmplEmpr);
});
//provider para obtener el detalle de un empleado por su codigo

final detalleEmpleadoProvider = FutureProvider.family<EmpleadoEntity, int>((
  ref,
  codEmpleado,
) async {
  final repo = RegistroEmpleadoImpl();
  return await repo.obtenerDetalleEmpleado(codEmpleado);
});

//provider para obtener el cargo actual de un empleado por su codigo
final cargoActualEmpleadoProvider = FutureProvider.family<EmpleadoEntity, int>((
  ref,
  codEmpleado,
) async {
  final repo = RegistroEmpleadoImpl();
  return await repo.obtenerCargoActual(codEmpleado);
});
//obtener el historial de cargos de un empleado
final getHistorialCargosEmpleado =
    FutureProvider.family<List<EmpleadoEntity>, int>((ref, codEmpleado) async {
      final repo = RegistroEmpleadoImpl();
      final cargos = await repo.obtenerHistorialCargosEmpleado(codEmpleado);
      return cargos;
    });
//obtener el historial de cargos de un empleado
final getHistorialRelLabEmpleado =
    FutureProvider.family<List<RelacionLaboralEntity>, int>((
      ref,
      codEmpleado,
    ) async {
      final repo = RegistroEmpleadoImpl();
      final relacion = await repo.obtenerHistorialRelLabEmpleado(codEmpleado);
      return relacion;
    });
//provider para eliminar una cuenta bancaria por su codigo
final eliminarEmpleadoCargo =
    FutureProvider.family<void, (int, int, DateTime, int)>((ref, params) async {
      final repo = RegistroEmpleadoImpl();
      await repo.eliminarEmpleadoCargo(
        params.$1,
        params.$2,
        params.$3,
        params.$4,
      );
    });
//obtener ultima relacion laboral de un empleado
final obtenerUltimaRelacionLaboralProvider =
    FutureProvider.family<RelacionLaboralEntity, int>((ref, codEmpleado) async {
      final repo = RegistroEmpleadoImpl();
      return await repo.obtenerUltimaRelacionLaboral(codEmpleado);
    });
//OBTENER LICENCIAS DE CONDUCIR
final obtenerLicenciasConducirProvider =
    FutureProvider.family<List<LicenciaConducirEntity>, int>((
      ref,
      codPersona,
    ) async {
      final repo = RegistroEmpleadoImpl();
      return await repo.obtenerLicenciasConducir(codPersona);
    });
//REGISTRAR LICENCIA DE CONDUCIR
final registrarLicenciaConducirProvider =
    FutureProvider.family<LicenciaConducirEntity, LicenciaConducirEntity>((
      ref,
      licencia,
    ) async {
      final repo = RegistroEmpleadoImpl();
      final registrarLicencia = await repo.registrarLicenciaConducir(licencia);
      return registrarLicencia;
    });
//ELIMINAR LICENCIA DE CONDUCIR
final eliminarLicenciaConducirProvider = FutureProvider.family<void, int>((
  ref,
  codLicencia,
) async {
  final repo = RegistroEmpleadoImpl();
  await repo.eliminarLicenciaConducir(codLicencia);
});
//OBTENER TIPOS DE LICENCIA DE CONDUCIR
final obtenerTipoLicenciaConducirProvider =
    FutureProvider<List<TipoLicenciaEntity>>((ref) async {
      final repo = RegistroEmpleadoImpl();
      return await repo.obtenerTipoLicenciaConducir();
    });
// ELIMINAR FOTO (PERFIL O DOCUMENTOS)
final eliminarFotoProvider = FutureProvider.family<bool, (int, String, String)>(
  (ref, params) async {
    final repo = RegistroEmpleadoImpl();
    return await repo.eliminarFoto(params.$1, params.$2, params.$3);
  },
);
//provider para obtener la lista de empleados con filtros
final getCargoXEmpresa =
    FutureProvider.family<List<EmpleadoEntity>, (String?, int?)>((
      ref,
      params,
    ) async {
      final repo = RegistroEmpleadoImpl();
      final empleados = await repo.getCargosXEmpresa(params.$1, params.$2);
      return empleados;
    });
//OBTENER LISTA DE SEGUROS
final obtenerSeguros = FutureProvider<List<SeguroEntity>>((ref) async {
  final repo = RegistroEmpleadoImpl();
  final listaSeguros = await repo.obtenerSeguros();
  return listaSeguros;
});
//provider para obtener afiliacion al seguro de un empleado por su codigo
final obtenerAfiliacionSeguro =
    FutureProvider.family<AfiliacionSeguroEntity?, int>((
      ref,
      codEmpleado,
    ) async {
      final repo = RegistroEmpleadoImpl();
      return await repo.obtenerAfiliacionSeguro(codEmpleado);
    });
//REGISTRAR AFILIACION AL SEGURO
final registrarAfiliacionSeguro = FutureProvider.family<
  AfiliacionSeguroEntity,
  AfiliacionSeguroEntity
>((ref, afiliacion) async {
  final repo = RegistroEmpleadoImpl();
  final registrarAfiliacion = await repo.registrarAfiliacionSeguro(afiliacion);
  return registrarAfiliacion;
});
//ELIMINAR AFILIACION AL SEGURO
final eliminarAfiliacionSeguro = FutureProvider.family<void, int>((
  ref,
  codAfiliacion,
) async {
  final repo = RegistroEmpleadoImpl();
  await repo.eliminarAfiliacionSeguro(codAfiliacion);
});
//REGISTRAR ASEGURADORA
final registrarSeguro = FutureProvider.family<SeguroEntity, SeguroEntity>((
  ref,
  seguro,
) async {
  final repo = RegistroEmpleadoImpl();
  final registrarAseguradora = await repo.registrarAseguradora(seguro);
  return registrarAseguradora;
});
//ELIMINAR ASEGURADORA
final eliminarSeguro = FutureProvider.family<void, int>((ref, codSeguro) async {
  final repo = RegistroEmpleadoImpl();
  await repo.eliminarAseguradora(codSeguro);
});
//provider para obtener TIPO DE SEGURO
final obtenerTipoSeguro = FutureProvider<List<TipoSeguroEntity>>((ref) async {
  final repo = RegistroEmpleadoImpl();
  final tipoSeguro = await repo.obtenerTipoSeguro();
  return tipoSeguro;
});
//OBTENDRA EL HABER BASICO DE UN EMPLEADO
final obtenerHaberBasico = FutureProvider.family<EmpleadoEntity, int>((
  ref,
  codEmpleado,
) async {
  final repo = RegistroEmpleadoImpl();
  return await repo.obtenerHaberBasico(codEmpleado);
});
