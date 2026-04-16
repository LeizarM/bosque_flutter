Migración de “Resmado” (Angular + PrimeNG) a Flutter
Objetivo
Replicar en Flutter la pantalla Registro de Resmado manteniendo el mismo flujo de datos:

Cargar catálogos: Empresas, Órdenes (DocNum) por empresa, Grupos, Artículos
Capturar cabecera: fecha, empresa, docNum, grupo, hora inicio/fin
Gestionar detalle: seleccionar artículos en un diálogo, evitar duplicados, editar cantResma, eliminar filas, calcular total
Confirmar y registrar: 1) cabecera → 2) detalle (secuencial)
Fuentes (referencia funcional):

src/app/protected/lote-produccion/pages/resmado/resmado.component.html
src/app/protected/lote-produccion/pages/resmado/resmado.component.ts
src/app/protected/lote-produccion/services/loteProduccion.service.ts.service.ts
Alcance funcional a portar
UI (equivalente a Angular)
Formulario con validaciones:
Fecha (obligatoria)
Empresa (obligatoria)
DocNum (obligatorio; habilitado solo si hay empresa)
Grupo (obligatorio)
Hora inicio / hora fin (obligatorias, formato HH:mm)
Detalle: al menos 1 ítem
Tabla de detalle:
Código, descripción (solo lectura en tabla)
cantResma editable (mínimo 1)
Eliminar fila
Footer con TOTAL = suma de cantResma
Diálogo/modal para seleccionar artículos (multi-selección, filtro global)
Confirm dialog al registrar
Mensajes tipo toast/snackbar para info/error/success
Arquitectura recomendada en Flutter
Opción sugerida: Riverpod (o Bloc si ya lo usan)
Separar en 3 capas:

Data

ResmadoApi (Dio/http) con endpoints
Modelos (DTO) y mapeo JSON
Domain / State

ResmadoController / ResmadoNotifier
Estado inmutable: catálogos, selección, detalle, loading, error
UI

ResmadoPage (pantalla)
Widgets: HeaderForm, DetalleTable, ArticuloPickerDialog
Mapeo de endpoints (Angular → Flutter)
Base URL: environment.baseUrl (en Flutter será config por flavor).

Catálogos
POST /loteProduccion/articulos → lista artículos
POST /resmado/grupoProduccion → grupos
POST /loteProduccion/lst-empresas → empresas
POST /loteProduccion/lstDocNumOrdFabXEmpresa body { codEmpresa } → docNums por empresa
Registro
POST /resmado/registroResmado body Resmado
POST /resmado/registroDetResmado body DetalleResmado[]
Modelos (contratos) a crear en Flutter
Empresa
Campos usados en UI:

codEmpresa (int)
nombre (String)
LoteProduccion (para artículos y docNum)
Campos usados:

Para artículos: codArticulo, articulo (texto mostrado), datoArt (descripción usada en detalle)
Para docNum: docNumOrdFab (y opcionalmente campos informativos: codArtEntrada, codArtSalida, db, etc.)
Resmado (cabecera)
Campos usados en el payload:

codEmpresa (int)
docNumOrdFab (int)
idGrupo (int)
fecha (DateTime)
codEmpleado (int) (viene de sesión/login)
total (num)
hraInicio (String “HH:mm”)
hraFin (String “HH:mm”)
audUsuario (int) (usuario actual)
DetalleResmado
Por fila:

codArticulo (String/int según backend)
descripcion (String)
cantResma (num/int)
audUsuario (int)
Estado y flujo (equivalente al componente Angular)
1) Inicialización (al abrir pantalla)
Flutter init:

Cargar en paralelo:
empresas
grupos
articulos
Inicializar formulario:
fecha = hoy
idGrupo = 1 (según Angular)
detalles = []
total = 0
codEmpleado / audUsuario desde servicio de sesión (ej. AuthStore)
2) Selección de empresa → carga DocNum
Cuando usuario cambia codEmpresa:

Limpiar docNumOrdFab seleccionado
Vaciar lista docNums
Llamar getDocNums(codEmpresa) y poblar dropdown
Si viene vacío, mostrar mensaje “No hay órdenes…”
3) Agregar artículos (modal)
En modal:

Mostrar lista articulos con buscador (filtro por texto)
Permitir multi-selección Al confirmar “Agregar al formulario”:
Por cada seleccionado:
Si ya existe en detalles por codArticulo → mostrar error y omitir
Si no existe → agregar fila con:
codArticulo
descripcion = datoArt
cantResma = 1
audUsuario = usuario actual
Recalcular total
4) Editar cantidad / eliminar fila
onCantResmaChanged(index, value):
si < 1 → normalizar a 1 o invalidar (según UX)
actualizar y recalcular total
removeDetalle(index):
remover y recalcular total
5) Registrar (confirm + envío secuencial)
Al presionar “Registrar”:

Validar:
campos requeridos completos
detalles.length >= 1
horas con formato correcto
Mostrar confirm dialog
Si acepta:
POST /resmado/registroResmado con cabecera
POST /resmado/registroDetResmado con lista de detalle
Si todo OK:
mostrar éxito
reset de formulario + recarga catálogos si aplica (Angular llama ngOnInit())
Nota: mantener secuencia 1→2 como en Angular (concatMap).

UI: equivalencias PrimeNG → Flutter (sugerencias)
p-calendar → showDatePicker + TextFormField readOnly
p-dropdown → DropdownButtonFormField
p-inputMask HH:mm → TextFormField + TextInputFormatter (más validador) o TimeOfDay picker y formateo a “HH:mm”
p-table → DataTable / PaginatedDataTable o ListView con filas custom
p-dialog → showDialog con AlertDialog / Dialog + lista seleccionable
p-toast / p-messages → ScaffoldMessenger (SnackBar) y/o fluttertoast
Manejo de sesión (codEmpleado / audUsuario)
En Angular viene de LoginService.codUsuario y LoginService.codEmpleado.

En Flutter:

Crear SessionStore/AuthProvider que exponga:
currentUserId
currentEmployeeId
Inyectarlo en el controller para construir payloads.
Validaciones (paridad con Angular)
fecha: requerido
codEmpresa: requerido
docNumOrdFab: requerido
idGrupo: requerido
hraInicio y hraFin: requerido; validar patrón ^\d{2}:\d{2}$ y rango 00:00–23:59
detalles: requerido y minLength 1
cantResma: requerido y min 1 por fila
Checklist de migración (paso a paso)
Config
Flavors: dev/prod con baseUrl
Networking
Cliente HTTP (Dio recomendado)
Interceptors: auth token / logging / manejo 401
Modelos
fromJson/toJson para Empresa, LoteProduccion, Resmado, DetalleResmado, GrupoProduccion
API
Implementar métodos equivalentes a:
obtenerArticulos
obtenerGrupoProduccion
obtenerEmpresas
obtenerDocNumPorEmpresa
registrarResmado
registroDetalleResmado
State
Controller con estado: catálogos, selección, detalles, total, loading, error
UI
Pantalla + formulario + tabla + modal de selección
Confirm dialog + snackbars
Flujo registro
Envío secuencial cabecera→detalle y reset
Pruebas
Unit test de total y deduplicación
Test de validación de horas
Mock API para probar flujo completo
