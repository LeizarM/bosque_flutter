import 'package:bosque_flutter/domain/entities/afiliacion_seguro_entity.dart';
import 'package:bosque_flutter/domain/entities/banco_entity.dart';
import 'package:bosque_flutter/domain/entities/cargo_sucursal_entity.dart';
import 'package:bosque_flutter/domain/entities/educacion_entity.dart';
import 'package:bosque_flutter/domain/entities/empleado_cargo_entity.dart';
import 'package:bosque_flutter/domain/entities/empleado_entity.dart';
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

abstract class RegistroEmpleadoRepository{
  Future<List<EmpleadoEntity>>getLstEmpleados(String? search, int? esActivo, int pageNumber, int pageSize,int? codEmpresa);
  Future<EmpleadoEntity>registrarEmpleado(EmpleadoEntity empleado);
  Future<List<PersonaEntity>>getLstPersonas(String buscarPersona);
  Future<PersonaEntity> obtenerPersona(int codPersona);
  Future<List<TelefonoEntity>> obtenerTelefono(int codPersona);
  Future<EducacionEntity>registrarEducacion(EducacionEntity educacion);
  Future<List<EducacionEntity>> obtenerEducacion(int codEmpleado);
  Future<bool> eliminarEducacion(int codEducacion);
  Future<List<TipoEducacionEntity>> obtenerTipoEducacion();
  Future<List<CargoSucursalEntity>> obtenerCargoXsucursal(int codSucursal);
  Future<RelacionLaboralEntity>registrarRelacionLaboral(RelacionLaboralEntity relLab);
  Future<List<BancoEntity>> getBancos();
  Future<List<NroCuentaBancariaEntity>> getCuentaBancoXEmpleado(int codEmpleado);
  Future<NroCuentaBancariaEntity>registrarCuentaBancaria(NroCuentaBancariaEntity cuenta);
  Future<bool> eliminarCuentaBancaria(int codCuenta);
  Future<List<TipoRelacionLaboralEntity>> getTipoRelacionLaboral();
  Future<EmpleadoCargoEntity>registroEmpleadoCargo(EmpleadoCargoEntity empleado);
  Future<bool> eliminarRelacionLaboral(int codRelEmplEmpr);
  Future<EmpleadoEntity> obtenerDetalleEmpleado(int codEmpleado);
  Future<EmpleadoEntity> obtenerCargoActual(int codEmpleado);
  Future<List<EmpleadoEntity>> obtenerHistorialCargosEmpleado(int codEmpleado);
   Future<List<RelacionLaboralEntity>> obtenerHistorialRelLabEmpleado(int codEmpleado);
   Future<bool> eliminarEmpleadoCargo(int codEmpleado,int codCargoSucursal, DateTime fechaIni,int codCargoSucPlanilla);
   Future<List<LicenciaConducirEntity>> obtenerLicenciasConducir(int codPersona);
   Future<RelacionLaboralEntity> obtenerUltimaRelacionLaboral(int codEmpleado);
   Future<LicenciaConducirEntity> registrarLicenciaConducir(LicenciaConducirEntity licencia);
   Future<bool> eliminarLicenciaConducir(int codLicencia);
   Future<List<TipoLicenciaEntity>> obtenerTipoLicenciaConducir();
   Future<bool> eliminarFoto(int codEmpleado, String tipoDocumento, String nombreArchivo);
   Future<List<EmpleadoEntity>>getCargosXEmpresa(String? search, int? codEmpresa);
    Future<List<SeguroEntity>> obtenerSeguros();
    Future<AfiliacionSeguroEntity?> obtenerAfiliacionSeguro(int codEmpleado);
    Future<AfiliacionSeguroEntity> registrarAfiliacionSeguro(AfiliacionSeguroEntity afiliacion);
    Future<bool> eliminarAfiliacionSeguro(int codAfiliacion);
    Future<SeguroEntity> registrarAseguradora(SeguroEntity seguro);
    Future<bool> eliminarAseguradora(int codSeguro);
    Future<List<TipoSeguroEntity>> obtenerTipoSeguro();
     Future<EmpleadoEntity> obtenerHaberBasico(int codEmpleado);
  
} 