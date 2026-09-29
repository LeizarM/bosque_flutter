import 'dart:typed_data';

import 'package:bosque_flutter/domain/entities/armado_propuesta_entity.dart';
import 'package:bosque_flutter/domain/entities/articulo_precio_entity.dart';
import 'package:bosque_flutter/domain/entities/articulo_propuesto_entity.dart';
import 'package:bosque_flutter/domain/entities/clasificacion_precio_entity.dart';
import 'package:bosque_flutter/domain/entities/color_producto_entity.dart';
import 'package:bosque_flutter/domain/entities/costo_incremento_entity.dart';
import 'package:bosque_flutter/domain/entities/costo_iva_it_entity.dart';
import 'package:bosque_flutter/domain/entities/grupo_fam_tipo_rango_gram_entity.dart';
import 'package:bosque_flutter/domain/entities/grupo_familia_sap_entity.dart';
import 'package:bosque_flutter/domain/entities/historial_costo_familia_entity.dart';
import 'package:bosque_flutter/domain/entities/porcentaje_precio_entity.dart';
import 'package:bosque_flutter/domain/entities/presentacion_producto_entity.dart';
import 'package:bosque_flutter/domain/entities/producto_familia_entity.dart';
import 'package:bosque_flutter/domain/entities/proveedor_ext_sap_entity.dart';
import 'package:bosque_flutter/domain/entities/rango_gramaje_entity.dart';
import 'package:bosque_flutter/domain/entities/tc_ancla_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_producto_entity.dart';
import 'package:bosque_flutter/domain/entities/vista_propuesta_entity.dart';

/// Contrato del modulo de Precios (tpr): propuestas de reprecio, circuito de
/// autorizacion y catalogos del modulo.
///
/// Reglas que valen para TODOS los metodos:
///
/// * Todas las llamadas son POST, tambien las lecturas, y siempre mandan un
///   cuerpo JSON.
/// * Los listados devuelven lista vacia cuando el backend responde 204: es
///   exito sin datos, nunca un error. Las consultas de una sola fila devuelven
///   null en ese mismo caso.
/// * Un 400 llega como el mensaje de negocio del backend, que se muestra al
///   usuario tal cual, sin traducir.
/// * El usuario de auditoria NO viaja en el cuerpo: el backend lo toma del
///   token JWT. Mandarlo desde el cliente no cambia nada y era la via por la
///   que se podia colgar un costo o un precio de la propuesta de otra persona.
///
/// Sobre los `Map<String, dynamic>` que devuelven algunas lecturas: son las
/// respuestas que el backend arma con DTO de despliegue (descripciones
/// resueltas por JOIN, nombres de sucursal, pivotes). No tienen tabla detras y
/// por eso no tienen entity en este paso; cada metodo documenta las claves que
/// trae. Las lecturas que SI corresponden a una tabla devuelven su entity.
abstract class PreciosRepository {
  // ======================= PROPUESTAS: LECTURAS ==========================

  /// Propuestas con su estado de autorizacion, que es la grilla principal de
  /// la pantalla.
  ///
  /// Claves: idAutorizacion, idPropuesta, tipo, titulo, datoPersonaP,
  /// audFechaPropuesta, estado, datoPersonaA, audFechaAutorizacion,
  /// datoPersonaG, audFecGenerado.
  ///
  /// El estado viene como texto ya resuelto, no como el entero esAprobada.
  Future<List<Map<String, dynamic>>> obtenerPropuestasParaAutorizar();

  /// Estados posibles de una propuesta, para los combos.
  ///
  /// Claves: codTipos, nombre, codGrupo. Salen de una constante del backend y
  /// no de la base: el catalogo real vive en la vista v_tipos grupo 38, armada
  /// con literales dentro del propio CREATE VIEW.
  Future<List<Map<String, dynamic>>> obtenerEstadosPropuesta();

  /// Costo de flete de transporte por sucursal.
  ///
  /// Claves: idIncre, codSucursal, nombre (el de la sucursal), valor.
  ///
  /// No devuelve [CostoIncrementoEntity] porque el nombre de la sucursal, que
  /// es justamente lo que se muestra, no es una columna de tpr_costoIncre.
  Future<List<Map<String, dynamic>>> obtenerCostosFlete();

  /// Proveedores del catalogo SAP, para el combo de familias.
  ///
  /// El backend devuelve solo idProveedorSap y proveedorExtSap: el resto de
  /// los campos de la entity llega vacio y no hay que mostrarlo.
  Future<List<ProveedorExtSapEntity>> obtenerProveedoresSap();

  /// Familias de producto con su descripcion resuelta.
  ///
  /// Claves: codigoFamilia, proveedorSap, grpFamilia, presentacion, tipo,
  /// rangoGramaje, gramaje, formato, color, estado, costoTM,
  /// idPropuestaAprobada.
  ///
  /// Los parametros en null NO filtran. Ojo: un 0 no es lo mismo que null,
  /// filtra por cero y no devuelve nada; por eso los ids son nulables y no se
  /// mandan cuando no se usan.
  Future<List<Map<String, dynamic>>> obtenerFamilias({
    int? codigoFamilia,
    BigInt? idGrpFamiliaSap,
    BigInt? idProveedorSap,
    BigInt? idPresentacion,
    BigInt? idTipo,
    BigInt? idRangoGram,
    String? formato,
    String? gramaje,
    BigInt? idColor,
    int? estado,
  });

  /// Familias que pertenecen a un grupo de familia SAP.
  ///
  /// Claves: codigoFamilia, proveedorExtSap, grpFam.
  Future<List<Map<String, dynamic>>> obtenerFamiliasPorGrupo(
    BigInt idGrpFamiliaSap,
  );

  /// Articulos del catalogo que pertenecen a una o varias familias.
  ///
  /// El backend espera los codigos como una cadena separada por comas; esa
  /// cadena la arma la implementacion a partir de [codigosFamilia].
  ///
  /// La respuesta trae codArticulo, codigoFamilia, datoArt, stock y utm; los
  /// demas campos de la entity llegan vacios porque esta lectura no los
  /// devuelve.
  Future<List<ArticuloPrecioEntity>> obtenerArticulosPorFamilias(
    List<int> codigosFamilia,
  );

  /// Una familia con su descripcion resuelta. Devuelve null si el codigo no
  /// existe. Mismas claves que [obtenerFamilias].
  Future<Map<String, dynamic>?> obtenerFamilia(int codigoFamilia);

  /// Alta ([alta] en true) o edicion de una familia. El codigo lo elige quien
  /// la carga: la PK no es automatica. El alta la crea activa, sin costo y con
  /// un precio en 0 por lista activa; la edicion reescribe la ficha entera,
  /// incluido el estado, y nunca el costo ni la propuesta aprobada.
  ///
  /// [porcentajes] es la grilla "Porcentaje por familia" de la ficha: de cada
  /// uno viajan idClasificacion y porcen, y el backend los guarda en la misma
  /// transaccion que la familia. En la edicion van solo los que cambiaron; el
  /// servidor decide si cada uno es alta o modificacion. Null = no se tocan.
  Future<BigInt> registrarFamilia(
    ProductoFamiliaEntity familia, {
    required bool alta,
    List<PorcentajePrecioEntity>? porcentajes,
  });

  /// Las listas de precio activas con el porcentaje en cero, para la grilla
  /// del alta de una familia. Mismas claves que [obtenerPorcentajesPorFamilia],
  /// salvo idPorcen, que no viene. El backend no ordena.
  Future<List<Map<String, dynamic>>> obtenerListasParaPorcentaje();

  /// Da de baja ([activa] en false) o reactiva una familia sin abrir la ficha.
  Future<void> cambiarEstadoFamilia(int codigoFamilia, {required bool activa});

  /// Elimina una familia que nunca se uso (creada por error). Si ya tiene
  /// movimiento, el backend la rechaza con el motivo en el mensaje del error.
  Future<void> eliminarFamilia(int codigoFamilia);

  /// Cambia el grupo y el proveedor SAP de una familia. Null o cero = sin
  /// asignar.
  Future<void> asignarSapFamilia(
    int codigoFamilia, {
    BigInt? idGrpFamiliaSap,
    BigInt? idProveedorSap,
  });

  /// Trae de SAP los proveedores y los grupos de familia nuevos y actualiza el
  /// nombre de los proveedores. Puede tardar: consulta SAP.
  Future<void> sincronizarCatalogosSap();

  /// El historial del costo de una familia, la aprobacion mas reciente
  /// primero. Lista vacia si no tiene cambios registrados.
  Future<List<HistorialCostoFamiliaEntity>> obtenerHistorialCosto(
    int codigoFamilia,
  );

  /// Precios vigentes por tonelada de una familia, ya listos para armar la
  /// grilla de repreciacion.
  ///
  /// Claves: codigoFamilia, idPresentacion, proveedorExtSap, grpFam, formato,
  /// gramaje, color, codSucursal, nombre, idClasificacion, nombrePrecio,
  /// idPrecio, vpp, porcentaje, listNum, precio, precioNew, iva, it.
  Future<List<Map<String, dynamic>>> obtenerPreciosTonPorFamilia(
    int codigoFamilia,
  );

  /// La vista preliminar con las mismas filas que el PDF: porcentaje, precio
  /// actual y propuesto por tonelada de cada articulo (por familia), o el
  /// precio que toma cada articulo (por articulo). Trae ademas los precios por
  /// unidad que lleva el Excel de la generacion.
  Future<VistaPropuestaEntity> obtenerVistaPropuesta(BigInt idPropuesta);

  // ====================== PROPUESTAS: ESCRITURAS =========================

  // Aca estaban registrarPropuesta, registrarCostoIncremento,
  // registrarPrecioPropuesta y registrarCostoSugerido. Se quitaron el
  // 2026-09-25 junto con sus endpoints: ninguna pantalla las usaba -la
  // cabecera, el flete, el costo y los precios se escriben desde el asistente,
  // que recalcula- y el servidor no les pedia ningun permiso.

  // ======================= ARMADO DE UNA PROPUESTA =======================
  //
  // El asistente "Nueva propuesta". El precio lo calcula SIEMPRE el servidor:
  // [calcularFamiliaArmado] es la vista previa y no escribe, y
  // [guardarFamiliaArmado] vuelve a calcular y graba todo en una transaccion.
  // Con [idPropuesta] en null la propuesta todavia no existe: nace con la
  // primera familia o el primer articulo que se guarda, y entonces viajan
  // tambien titulo, observaciones y (por familia) los fletes.

  /// Fletes por sucursal. Con [idPropuesta] en null, las sucursales con el
  /// flete de la ultima propuesta por familia como sugerencia.
  Future<FletesArmadoEntity> obtenerFletesArmado(BigInt? idPropuesta);

  /// Familias que ya estan en la propuesta, con su costo y cuantas listas.
  Future<List<FamiliaArmadaEntity>> obtenerFamiliasArmadas(BigInt idPropuesta);

  /// La grilla de una familia con el precio calculado. No escribe. Con [costo]
  /// en null usa el costo ya guardado en la propuesta, si lo hay.
  /// [porcentajes] (por idClasificacion) reemplaza el margen de esas listas
  /// solo para el calculo.
  Future<CalculoFamiliaEntity> calcularFamiliaArmado({
    BigInt? idPropuesta,
    required int codigoFamilia,
    double? costo,
    List<FleteArmadoEntity>? fletes,
    Map<BigInt, double>? porcentajes,
  });

  /// Carga (o recarga) la familia en la propuesta, creandola si hace falta.
  /// Devuelve la grilla tal como quedo grabada, con el id de la propuesta.
  /// Los [porcentajes] distintos de los vigentes se registran en
  /// tpr_porcentaje en la misma transaccion.
  Future<CalculoFamiliaEntity> guardarFamiliaArmado({
    BigInt? idPropuesta,
    String? titulo,
    String? obs,
    List<FleteArmadoEntity>? fletes,
    required int codigoFamilia,
    required double costo,
    Map<BigInt, double>? porcentajes,
  });

  /// Vista previa de varias familias, cada una con su [costos] (USD por
  /// tonelada, por codigo de familia). No escribe. Cada familia vuelve con su
  /// grilla y, si no se podria guardar, con [CalculoFamiliaEntity.impedimento].
  /// Hasta 100 familias por llamada.
  Future<List<CalculoFamiliaEntity>> calcularFamiliasArmado({
    BigInt? idPropuesta,
    List<FleteArmadoEntity>? fletes,
    required Map<int, double> costos,
  });

  /// Carga varias familias en la propuesta en una transaccion: si una no se
  /// puede guardar no se guarda ninguna. Si la propuesta no existe, la crea.
  /// Los porcentajes son los vigentes: en lote no se cambian.
  Future<ResultadoArmadoEntity> guardarFamiliasArmado({
    BigInt? idPropuesta,
    String? titulo,
    String? obs,
    List<FleteArmadoEntity>? fletes,
    required Map<int, double> costos,
  });

  /// Cambia los fletes de una propuesta pendiente y recalcula sus familias.
  Future<ResultadoArmadoEntity> guardarFletesArmado({
    required BigInt idPropuesta,
    required List<FleteArmadoEntity> fletes,
  });

  /// Articulos de una propuesta por articulo.
  Future<List<ArticuloPropuestoEntity>> obtenerArticulosArmados(
    BigInt idPropuesta,
  );

  /// Agrega articulos a una propuesta por articulo, creandola si hace falta.
  /// Los que ya estaban no se repiten: vuelven contados en `omitidos`.
  Future<ResultadoArmadoEntity> agregarArticulosArmado({
    BigInt? idPropuesta,
    String? titulo,
    String? obs,
    required List<String> codArticulos,
  });

  /// Saca un articulo de una propuesta por articulo pendiente.
  Future<ResultadoArmadoEntity> quitarArticuloArmado({
    required BigInt idPropuesta,
    required BigInt idArticulo,
  });

  /// Trae de SAP los articulos nuevos y refresca stock y UTM. Puede tardar
  /// varios minutos: la implementacion espera hasta diez.
  Future<void> sincronizarArticulosSap();

  // ============================== REPORTES ===============================

  /// La propuesta en PDF, por familia o por articulo segun su tipo. Puede
  /// tardar: el servidor consulta los articulos no creados en otro servidor.
  Future<Uint8List> reportePropuesta(BigInt idPropuesta);

  /// Precios por tonelada vigentes de las familias de un grupo SAP.
  Future<Uint8List> reportePreciosGrupo(BigInt idGrpFamiliaSap);

  /// Precios por tonelada vigentes de todas las familias activas.
  Future<Uint8List> reportePreciosTodas();

  /// El catalogo de familias activas.
  Future<Uint8List> reporteFamiliasActivas();

  // ====================== CIRCUITO DE AUTORIZACION =======================

  /// Aprueba o rechaza una propuesta.
  ///
  /// Es la operacion mas sensible del modulo: con [esAprobada] en 1 los
  /// precios propuestos pasan a ser los precios de venta vigentes de toda la
  /// empresa. Los valores del dominio son 0 pendiente, 1 aprobada,
  /// 2 no aprobada, 3 en espera.
  ///
  /// El backend exige el boton btnAprobar y ejecuta las dos escrituras en una
  /// sola transaccion. Si el usuario no tiene el boton asignado, la llamada
  /// falla con el mensaje del backend.
  Future<BigInt> resolverPropuesta({
    required BigInt idPropuesta,
    required int esAprobada,
  });

  /// Deja la propuesta en espera y se la devuelve a quien la genero.
  /// Exige el boton btnPen.
  Future<BigInt> marcarEnEspera(BigInt idPropuesta);

  /// Genera una propuesta aprobada: devuelve CambioDePrecios.xlsx con los
  /// precios unitarios por lista de SAP y deja constancia de quien lo genero
  /// y cuando. Exige el boton btnGen.
  Future<Uint8List> generarPropuesta(BigInt idPropuesta);

  // ============================ PORCENTAJES ==============================
  //
  // tpr_porcentaje: el margen sobre el costo de una familia en una lista de
  // precios. Es parte del calculo del precio, no un catalogo.
  //
  // Los porcentajes estan en PUNTOS PORCENTUALES: 12.5 es 12,5%. No es base 1
  // como las comisiones de tcom.
  //
  // Sobre por que las tres grillas devuelven mapas y no
  // [PorcentajePrecioEntity]: lo que se muestra es el cruce de tpr_porcentaje
  // con tb_sucursal y tpr_clasificacionPrecio -nombre de sucursal, nombre de
  // la lista, vpp-, y nada de eso es columna de la tabla. Devolver la entity
  // obligaria a tirar justamente los campos por los que existe la grilla. La
  // unica lectura que SI devuelve la entity es [obtenerPorcentajes], que lee
  // la tabla cruda.

  /// La grilla de porcentajes de una familia: una fila por sucursal y lista de
  /// precios. Es el contenido del dialogo dlgPorcen del sistema anterior.
  ///
  /// Claves: codSucursal, nombre (el de la sucursal), idClasificacion,
  /// nombrePrecio, vpp, idPorcen, porcentaje.
  ///
  /// Las listas de precios que la familia todavia no tiene vuelven igual, con
  /// idPorcen y porcentaje en cero: es un alta pendiente y no un error. La
  /// pantalla decide alta o modificacion mirando idPorcen.
  Future<List<Map<String, dynamic>>> obtenerPorcentajesPorFamilia(
    int codigoFamilia,
  );

  /// La grilla de destinos de la edicion masiva por grupo de familia SAP: las
  /// sucursales con sus listas de precios activas y el porcentaje en cero,
  /// para que el usuario cargue el valor a aplicar (dialogo dlgPorcGrupo).
  ///
  /// Mismas claves que [obtenerPorcentajesPorFamilia], salvo idPorcen, que en
  /// esta rama no viene: todas las filas son altas.
  ///
  /// Dos cosas que conviene saber antes de usarla:
  ///
  /// * La grilla NO depende del grupo. El backend devuelve todas las listas de
  ///   precios activas y aca no se simula lo contrario; [idGrpFamiliaSap] se
  ///   pide porque sin el la edicion masiva no tiene a que familias alcanzar,
  ///   y esas salen de [obtenerFamiliasPorGrupo].
  /// * El backend no ordena esta rama. El orden por vpp y sucursal lo tiene
  ///   que aplicar la pantalla.
  ///
  /// No existe una escritura masiva: el sistema anterior la resolvia con un
  /// procedimiento aparte (p_abm_porcentajeXGrupo) que no esta expuesto. La
  /// aplicacion a un grupo se arma llamando a [registrarPorcentaje] una vez
  /// por familia y lista de precios, y eso NO es atomico: si una falla, las
  /// anteriores ya quedaron escritas.
  Future<List<Map<String, dynamic>>> obtenerDestinosPorcentajeGrupo(
    BigInt idGrpFamiliaSap,
  );

  /// Las listas de precios que todavia no tienen porcentaje cargado para una
  /// familia. Mismas claves que [obtenerPorcentajesPorFamilia], con porcentaje
  /// siempre en cero.
  Future<List<Map<String, dynamic>>> obtenerPorcentajesFaltantes(
    int codigoFamilia,
  );

  /// Las filas crudas de tpr_porcentaje. A diferencia de las grillas, no
  /// completa las listas faltantes: devuelve solo lo que existe en la tabla.
  ///
  /// Los parametros en null no filtran. Un cero SI filtra y no devuelve nada.
  Future<List<PorcentajePrecioEntity>> obtenerPorcentajes({
    int? codigoFamilia,
    BigInt? idClasificacion,
  });

  /// Alta o modificacion del porcentaje de una familia en una lista de
  /// precios. idPorcen en cero inserta; mayor a cero actualiza.
  ///
  /// Es UNA fila por llamada, que es lo que soporta el procedimiento. En el
  /// alta hacen falta codigoFamilia e idClasificacion; en la modificacion el
  /// backend solo toca porcen y la auditoria, y no permite mover la fila a
  /// otra familia ni a otra lista.
  Future<BigInt> registrarPorcentaje(PorcentajePrecioEntity porcentaje);

  // ============================== COLOR ==================================

  /// Colores del catalogo, activos e inactivos.
  /// [idColor] nulo o cero devuelve todos.
  Future<List<ColorProductoEntity>> obtenerColores({BigInt? idColor});

  /// Solo los colores activos: es la lista que alimenta los combos.
  Future<List<ColorProductoEntity>> obtenerColoresActivos();

  /// Alta o modificacion. idColor en cero inserta; mayor a cero actualiza.
  Future<BigInt> registrarColor(ColorProductoEntity color);

  /// Baja de un color. El backend la rechaza con un mensaje si alguna familia
  /// lo esta usando.
  Future<BigInt> eliminarColor(ColorProductoEntity color);

  // =========================== TIPO DE PAPEL =============================

  /// Tipos de papel, activos e inactivos. [idTipo] nulo o cero devuelve todos.
  Future<List<TipoProductoEntity>> obtenerTipos({BigInt? idTipo});

  /// Solo los tipos activos, para los combos.
  Future<List<TipoProductoEntity>> obtenerTiposActivos();

  /// Alta o modificacion. idTipo en cero inserta; mayor a cero actualiza.
  Future<BigInt> registrarTipo(TipoProductoEntity tipo);

  /// Baja de un tipo. El backend la rechaza si el tipo esta en uso.
  Future<BigInt> eliminarTipo(TipoProductoEntity tipo);

  // =========================== PRESENTACION ==============================

  /// Catalogo completo de presentaciones, activas e inactivas.
  Future<List<PresentacionProductoEntity>> obtenerPresentaciones();

  /// Presentaciones filtradas. Los parametros en null no filtran.
  Future<List<PresentacionProductoEntity>> buscarPresentaciones({
    BigInt? idPresentacion,
    String? presentacion,
    int? estado,
  });

  /// Presentaciones activas, para los combos de familia.
  Future<List<PresentacionProductoEntity>> obtenerPresentacionesActivas();

  /// Una presentacion por su id. Null si no existe.
  Future<PresentacionProductoEntity?> obtenerPresentacion(
    BigInt idPresentacion,
  );

  /// Alta o modificacion. idPresentacion en cero inserta; mayor a cero
  /// actualiza.
  Future<BigInt> registrarPresentacion(PresentacionProductoEntity presentacion);

  /// Baja de una presentacion. El backend la rechaza si hay familias que la
  /// usan; en ese caso corresponde desactivarla.
  Future<BigInt> eliminarPresentacion(PresentacionProductoEntity presentacion);

  // ========================= RANGO DE GRAMAJE ============================

  /// Catalogo de rangos de gramaje, ordenado por limite inferior.
  Future<List<RangoGramajeEntity>> obtenerRangosGramaje();

  /// Un rango de gramaje por su id. Null si no existe.
  Future<RangoGramajeEntity?> obtenerRangoGramaje(BigInt idRangoGram);

  /// Los mismos rangos que [obtenerRangosGramaje], pensados para combos.
  ///
  /// El backend agrega una etiqueta "[ min - max ]" que aca no se conserva: la
  /// entity ya la arma con rangoLegible y rangoConDecimales, asi el texto es
  /// el mismo venga de donde venga la lista.
  Future<List<RangoGramajeEntity>> obtenerRangosGramajeParaCombo();

  /// Rangos configurados para un grupo de familia SAP y un tipo de papel.
  ///
  /// Los dos ids son obligatorios: esta consulta no admite "sin filtro",
  /// porque el vacio no se distinguiria de "no hay configuracion".
  Future<List<RangoGramajeEntity>> obtenerRangosPorGrupoFamiliaYTipo({
    required int idGrpFamiliaSap,
    required int idTipo,
  });

  /// Alta o modificacion. idRangoGram en cero inserta; mayor a cero actualiza.
  Future<BigInt> registrarRangoGramaje(RangoGramajeEntity rango);

  /// Baja de un rango. El backend la rechaza si el rango esta en uso.
  Future<BigInt> eliminarRangoGramaje(RangoGramajeEntity rango);

  // ======================= GRUPO DE FAMILIA SAP ==========================

  /// Todos los grupos de familia SAP con su equivalencia de codigo por
  /// empresa.
  Future<List<GrupoFamiliaSapEntity>> obtenerGruposFamiliaSap();

  /// Un grupo de familia SAP por su id. Null si no existe.
  Future<GrupoFamiliaSapEntity?> obtenerGrupoFamiliaSap(BigInt idGrpFamiliaSap);

  /// Busqueda por los campos indicados; los que van en null no filtran.
  ///
  /// Los tres codigos son texto, no numeros: admiten letras y ceros a la
  /// izquierda.
  Future<List<GrupoFamiliaSapEntity>> buscarGruposFamiliaSap({
    BigInt? idGrpFamiliaSap,
    String? codGrpFamSap,
    String? codGrpFamSapEpp,
    String? codGrpFamSapProdPap,
    String? grpFam,
    String? alias,
  });

  /// Alta o modificacion de un grupo de familia SAP.
  ///
  /// Al modificar, un codigo por empresa vacio significa "no tocar": para
  /// limpiar esa columna hay que mandar cadena vacia y no dejarla sin valor.
  Future<BigInt> registrarGrupoFamiliaSap(GrupoFamiliaSapEntity grupo);

  /// Baja de un grupo de familia SAP.
  Future<BigInt> eliminarGrupoFamiliaSap(BigInt idGrpFamiliaSap);

  // ======================= PROVEEDOR EXTERNO SAP =========================

  /// Todos los proveedores externos SAP del catalogo.
  Future<List<ProveedorExtSapEntity>> obtenerProveedores();

  /// Proveedores filtrados; los parametros en null no filtran.
  /// El codigo SAP es texto: no convertirlo a numero para buscar.
  Future<List<ProveedorExtSapEntity>> buscarProveedores({
    BigInt? idProveedorSap,
    String? codProvExtSap,
    String? proveedorExtSap,
  });

  /// Un proveedor por su id. Null si no existe.
  Future<ProveedorExtSapEntity?> obtenerProveedor(BigInt idProveedorSap);

  /// Alta o modificacion. idProveedorSap en cero inserta; mayor a cero
  /// actualiza.
  Future<BigInt> registrarProveedor(ProveedorExtSapEntity proveedor);

  /// Baja de un proveedor. El backend la rechaza si alguna familia lo
  /// referencia.
  Future<BigInt> eliminarProveedor(ProveedorExtSapEntity proveedor);

  // ===================== PARAMETROS DE GRAMAJE ===========================
  //
  // tpr_grupoFamTipoRangoGram no tiene PK ni IDENTITY: la fila se identifica
  // por la clave natural (idGrpFamiliaSap, idTipo). Por eso ni la baja ni la
  // modificacion piden un id, y el alta siempre devuelve cero.

  /// Todas las asignaciones cargadas, crudas.
  Future<List<GrupoFamTipoRangoGramEntity>> obtenerParametrosGramaje();

  /// Las asignaciones de un grupo de familia, una por tipo de papel.
  Future<List<GrupoFamTipoRangoGramEntity>> obtenerParametrosPorGrupoFamilia(
    BigInt idGrpFamiliaSap,
  );

  /// La fila de la clave natural (idGrpFamiliaSap, idTipo). Null si ese par
  /// todavia no esta configurado.
  Future<GrupoFamTipoRangoGramEntity?> obtenerParametroGramaje({
    required int idGrpFamiliaSap,
    required int idTipo,
  });

  /// La tabla pivoteada para mostrar: un renglon por grupo de familia con sus
  /// columnas Liviano, Mediano y Pesado.
  ///
  /// Claves: grupoFamilia, liviano, mediano, pesado, idGrpFamiliaSap,
  /// idRangoGramLiviano, idRangoGramMediano, idRangoGramPesado.
  Future<List<Map<String, dynamic>>> obtenerParametrosGramajePivote();

  /// Alta o modificacion de una asignacion. El backend decide cual de las dos
  /// es consultando la clave natural, asi un segundo alta del mismo par no
  /// duplica la fila en una tabla que no tiene unique que lo impida.
  ///
  /// Devuelve siempre cero: la tabla no genera ids.
  Future<BigInt> registrarParametroGramaje(GrupoFamTipoRangoGramEntity par);

  /// Baja de una asignacion por su clave natural. Devuelve siempre cero.
  Future<BigInt> eliminarParametroGramaje(GrupoFamTipoRangoGramEntity par);

  // ========================= LISTAS DE PRECIOS ===========================

  /// Listado plano de listas de precios. Los parametros en null no filtran.
  Future<List<ClasificacionPrecioEntity>> obtenerClasificacionesPrecio({
    BigInt? idClasificacion,
    BigInt? codSucursal,
  });

  /// Listas de precios con el nombre de su sucursal, ordenadas por estado y
  /// vpp: es la grilla del ABM.
  ///
  /// Claves: idClasificacion, codSucursal, vpp, estado, nombrePrecio,
  /// nombreSucursal.
  Future<List<Map<String, dynamic>>> obtenerClasificacionesConSucursal();

  /// Los vpp ya usados. Sirve para proponer el siguiente y para validar en
  /// pantalla antes de guardar.
  Future<List<int>> obtenerVppsUsados();

  /// Indica si el vpp ya esta usado por otra lista de precios.
  ///
  /// Al editar hay que pasar [idClasificacion] para excluir la propia fila:
  /// una lista no choca consigo misma. Que el vpp exista no es un error, es la
  /// respuesta.
  Future<bool> existeVpp({required int vpp, BigInt? idClasificacion});

  /// Alta o modificacion. idClasificacion en cero inserta; mayor a cero
  /// actualiza.
  Future<BigInt> registrarClasificacionPrecio(
    ClasificacionPrecioEntity clasificacion,
  );

  /// Activa o desactiva una lista de precios sin tocar el resto de los campos.
  ///
  /// Va aparte del registrar a proposito: esta rama solo escribe el estado y
  /// la auditoria, asi no hay forma de pisar sin querer el nombre ni el vpp.
  Future<BigInt> cambiarEstadoClasificacionPrecio({
    required BigInt idClasificacion,
    required int estado,
  });

  /// Baja fisica de una lista de precios. El backend verifica antes que no
  /// tenga precios ni porcentajes asociados.
  Future<BigInt> eliminarClasificacionPrecio(BigInt idClasificacion);

  // ============================== IVA / IT ===============================

  /// Las filas de IVA/IT, de la mas nueva a la mas vieja.
  ///
  /// En una base sana devuelve exactamente una. Mas de una fila es la senal de
  /// que el invariante de fila unica se rompio, y por eso este listado existe.
  Future<List<CostoIvaItEntity>> obtenerCostosIvaIt();

  /// La fila vigente. Null si todavia no hay IVA ni IT configurados.
  /// El total lo resuelve la entity con totalIvaIt.
  Future<CostoIvaItEntity?> obtenerCostoIvaItVigente();

  /// Filas de IVA/IT asociadas a una propuesta.
  Future<List<CostoIvaItEntity>> obtenerCostosIvaItPorPropuesta(
    BigInt idPropuesta,
  );

  /// Modifica el IVA y el IT que usa todo el calculo de precios.
  ///
  /// La tabla es un singleton y el backend lo hace cumplir: si ya hay una
  /// fila, actualiza esa aunque el cuerpo traiga otro id, y solo inserta
  /// cuando la tabla esta vacia.
  Future<BigInt> registrarCostoIvaIt(CostoIvaItEntity costo);

  // ==================== ANCLA DEL TIPO DE CAMBIO =========================
  //
  // SOLO LECTURA. tpr_tcAncla configura el reprecio nocturno automatico, que
  // hoy maneja un job externo y esta fuera del alcance de esta migracion:
  // escribirla desde la aplicacion descalibraria ese job. La pantalla solo
  // muestra como esta configurado.

  /// Anclas configuradas, una por empresa.
  Future<List<TcAnclaEntity>> obtenerAnclasTipoCambio();

  /// El ancla de una empresa, identificada por su base de datos SAP
  /// (por ejemplo SBO_IMPEXPAP). Null si esa empresa todavia no tiene ancla.
  Future<TcAnclaEntity?> obtenerAnclaTipoCambio(String companyDB);
}
