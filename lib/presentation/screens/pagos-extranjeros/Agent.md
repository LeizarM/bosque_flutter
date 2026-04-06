# TPEX — Guía de Integración Frontend

## 1. FLUJO DE PANTALLAS (5 fases → 7 endpoints ACID)

```
FASE 1 ─ Registro y Aprobación
│
├─ Pantalla: FormularioSolicitud
│   Acción: Guardar borrador / editar
│   Endpoint: POST /pagos-extranjeros/guardar-solicitud-completa
│   Cuándo llamar: Al hacer click en "Guardar" (crear o editar)
│   idSolicitud == 0 → INSERT / idSolicitud > 0 → UPDATE
│
└─ Pantalla: DetalleSolicitud
    Acción: Aprobar solicitud
    Endpoint: POST /pagos-extranjeros/aprobar-solicitud
    Cuándo llamar: Al hacer click en "Aprobar"
    Body mínimo: { idSolicitud, estado: "APROBADA", audUsuario }

FASE 2 ─ Cotizaciones
│
└─ Pantalla: FormularioCotizacion (repetir por cada banco)
    Acción: Registrar cotización de un banco
    PRE-CARGA: POST /pagos-extranjeros/obtener-tc-vigente
              → precargar tipoCambioOfrecido como referencia
    Endpoint: POST /pagos-extranjeros/guardar-cotizacion-completa
    Body: { idSolicitud, codBanco, fechaCotizacion, montoCompra,
            idMoneda, tipoCambioOfrecido, audUsuario, cargos: [...] }

FASE 3 ─ Elección del banco ganador
│
└─ Pantalla: ComparativaCotizaciones
    Acción: Ver tabla de bancos ordenada por totalBolivianos ASC
    PRE-CARGA: POST /pagos-extranjeros/obtener-cotizaciones-solicitud
              → mostrar grilla comparativa
    Endpoint: POST /pagos-extranjeros/aceptar-cotizacion
    Body mínimo: { idCotizacion, estado: "ACEPTADA", audUsuario }

FASE 4 ─ Ejecución del pago
│
└─ Pantalla: FormularioTransaccion
    PRE-CARGA 1: POST /pagos-extranjeros/obtener-cotizaciones-solicitud
                → precargar codBanco, montoCompra, tipoCambioOfrecido
    PRE-CARGA 2: POST /pagos-extranjeros/obtener-tc-vigente
                → precargar tipoCambioReferencia (TC BCB oficial)
    Endpoint: POST /pagos-extranjeros/guardar-transaccion-completa
    Body: { idSolicitud, idCotizacion, idTipoTransaccion, codBanco,
            montoOrigen, tipoCambioAplicado, tipoCambioReferencia,
            totalFinal, audUsuario, cargos: [...] }

    Acción: Marcar como enviada al banco
    Endpoint: POST /pagos-extranjeros/cambiar-estado-transaccion
    Body: { idTransaccion, estado: "PROCESADO", audUsuario }

FASE 5 ─ Confirmación y cierre
│
└─ Pantalla: ConfirmarPago
    Endpoint: POST /pagos-extranjeros/confirmar-pago
    Body: { idTransaccion, idSolicitud, numeroTransaccion,
            fechaValor, audUsuario }
    Efecto: Transacción → CONFIRMADO + Solicitud → PAGADA (1 sola TX)
```

---

## 2. MANEJO DE RESPUESTAS (ApiResponse)

Todos los endpoints devuelven esta estructura:

```json
{
  "message": "Operación realizada exitosamente",
  "data": 7,
  "status": 201
}
```

### Estructura ApiResponse

| Campo     | Tipo              | Cuándo viene                                    |
|-----------|-------------------|-------------------------------------------------|
| `message` | String            | Siempre — mensaje del SP o del controller       |
| `data`    | Long / List / null| Long en escrituras (idGenerado), List en lecturas, null en 204 |
| `status`  | int               | 200 OK, 201 Created, 204 No Content, 400 Error  |

### Función helper recomendada (JavaScript)

```js
// utils/api.js
const BASE_URL = "http://tu-servidor/pagos-extranjeros";

export async function callApi(endpoint, body) {
  const res = await fetch(`${BASE_URL}/${endpoint}`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${getToken()}`
    },
    body: JSON.stringify(body)
  });

  const json = await res.json();

  // 204 No Content — lista vacía, no es error
  if (res.status === 204) return { data: [], message: json.message };

  // 400 Bad Request — el SP devolvió error
  if (!res.ok) throw new Error(json.message);

  return json; // { data, message, status }
}
```

### Leer el idGenerado tras un INSERT

```js
// Guardar solicitud y obtener el ID generado
const response = await callApi("guardar-solicitud-completa", payload);
const idSolicitud = response.data; // Long con el ID nuevo
```

### Leer una lista

```js
// Obtener cotizaciones de una solicitud
const response = await callApi("obtener-cotizaciones-solicitud", { idSolicitud: 7 });
const cotizaciones = response.data; // Array de objetos Cotizaciones
```

---

## 3. MANEJO DE ERRORES

### Tipos de error que puede devolver el backend

| HTTP Status | Origen                              | Qué mostrar al usuario                 |
|-------------|-------------------------------------|----------------------------------------|
| `400`       | SP devolvió error != 0              | `response.message` directamente        |
| `401`       | Token expirado / sin token          | Redirigir al login                     |
| `403`       | Rol sin permiso                     | "No tienes permiso para esta acción"   |
| `500`       | Error interno del servidor          | "Error del servidor, contacta soporte" |

### Patrón recomendado en componentes

```js
// Patrón try/catch para endpoints ACID
async function guardarSolicitud(payload) {
  try {
    setLoading(true);
    const res = await callApi("guardar-solicitud-completa", payload);
    setIdSolicitud(res.data);
    showToast("success", res.message);
  } catch (err) {
    // err.message viene directo del SP (ej: "La solicitud ya está PAGADA")
    showToast("error", err.message);
    // NO hacer nada más — el rollback ya ocurrió en el backend
  } finally {
    setLoading(false);
  }
}
```

### Errores específicos por fase

```js
// El backend devuelve mensajes de negocio en español directamente usables en UI:
// "Error en cabecera de solicitud: La solicitud ya está en estado PAGADA"
// "Error registrando cargo en transacción: El tipo de cargo no existe"
// "Error confirmando transacción: Transición no permitida: PENDIENTE → CONFIRMADO"

// El frontend NO necesita interpretar estos mensajes, solo mostrarlos con showToast
```

### Estados de transición válidos (para deshabilitar botones en UI)

```js
// Deshabilitar botón "Aprobar" si la solicitud no está en PENDIENTE
const puedeAprobar  = solicitud.estado === "PENDIENTE";
const puedeCotizar  = solicitud.estado === "APROBADA";
const puedeEjecutar = cotizaciones.some(c => c.estado === "ACEPTADA");
const puedeConfirmar= transaccion?.estado === "PROCESADO";
const estaCerrada   = solicitud.estado === "PAGADA" || solicitud.estado === "CANCELADA";
```

---

## 4. CAMPOS CALCULADOS — Nunca enviar al backend

Estos campos los calcula el SP. El frontend los muestra (lectura) pero NUNCA los manda en el body:

| Entidad            | Campo calculado         | Mostrarlo como           |
|--------------------|-------------------------|--------------------------|
| DetalleSolicitud   | `montoAPagarUsd`        | Columna en tabla         |
| SolicitudProveedor | `totalAPagarUsd`        | Subtotal por proveedor   |
| SolicitudPago      | `montoTotalSolicitud`   | Total general            |
| Cotizaciones       | `montoConvertido`       | Monto en BOB             |
| Cotizaciones       | `totalBolivianos`       | Total cotización         |
| Transacciones      | `diferenciaDeMas`       | Diferencia en USD        |
| Transacciones      | `porcentajeDiferencia`  | % de costo adicional     |
| Transacciones      | `totalCargos`           | Total de cargos          |
| CargoPago          | `montoCargo`            | Monto del cargo          |
