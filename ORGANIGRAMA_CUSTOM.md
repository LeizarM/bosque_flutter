# 📊 Organigrama Custom Optimizado - Documentación

## ✅ Implementación Completada

Se ha implementado un **organigrama completamente custom** que respeta estrictamente el ordenamiento por **nivel** y **posición**.

---

## 🎯 Características Principales

### 1. **Ordenamiento Estricto por Nivel y Posición**
```dart
// PASO 1: Agrupar por nivel
final Map<int, List<CargoEntity>> cargosPorNivel = {};

// PASO 2: Ordenar cada nivel por posición
cargosPorNivel.forEach((nivel, cargos) {
  cargos.sort((a, b) => a.posicion.compareTo(b.posicion));
});
```

**Resultado:**
- Los nodos se posicionan **horizontalmente de izquierda a derecha** según su `posicion`
- Nodos con la misma posición pero diferente padre aparecen en el orden correcto
- **No hay interferencia del algoritmo de layout**: posiciones 100% determinísticas

---

## 📐 Algoritmo de Posicionamiento

### **Lógica Simple y Predecible:**

```
Para cada nivel:
  X inicial = 100px
  Y = 80 + (nivel * 140px)
  
  Para cada cargo en el nivel (ordenado por posición):
    Posición del nodo = (X, Y)
    X += ancho_nodo + espaciado_horizontal
```

### **Ejemplo con tus datos:**

```
Nivel 3, Padre: SUPERVISOR DE MANTENIMIENTO Y ABASTO (149)

RECEPCIONISTA (152)
├─ nivel: 3
├─ posicion: 6
└─ X: 100, Y: 500  ← MÁS A LA IZQUIERDA

PERSONAL DE SERVICIO Y LIMPIEZA (153)
├─ nivel: 3
├─ posicion: 8
└─ X: 340, Y: 500  ← MEDIO

SERENO (151)
├─ nivel: 3
├─ posicion: 9
└─ X: 580, Y: 500  ← MÁS A LA DERECHA
```

---

## 🎨 Configuración Visual

### **Dimensiones de Nodos:**
```dart
const double nodeWidth = 180;     // Ancho del nodo
const double nodeHeight = 95;     // Alto del nodo
```

### **Espaciado:**
```dart
const double horizontalSpacing = 60;   // Entre hermanos
const double verticalSpacing = 140;    // Entre niveles
```

### **Ajustar separación:**
Si los nodos están muy juntos o muy separados, modifica estas constantes en `organigrama_custom.dart` (líneas 35-38).

---

## 🔧 Funcionalidades Implementadas

| Funcionalidad | Estado | Descripción |
|---------------|--------|-------------|
| ✅ **Ordenamiento** | Implementado | Por nivel → por posición |
| ✅ **Hover** | Implementado | Escala 1.05x + sombra azul |
| ✅ **Selección** | Implementado | Click para seleccionar (borde azul) |
| ✅ **Collapse/Expand** | Implementado | Doble-click en nodos con hijos |
| ✅ **Drag & Drop** | Implementado | Long-press + arrastrar para reparentar |
| ✅ **Padres inactivos** | Implementado | Borde naranja + sin línea de conexión |
| ✅ **Zoom/Pan** | Implementado | InteractiveViewer integrado |
| ✅ **Auto-escala** | Implementado | Ajuste automático al viewport |
| ✅ **Tooltips** | Implementado | Información detallada al hover |
| ✅ **Conexiones ortogonales** | Implementado | Líneas verticales-horizontales |

---

## 📊 Estructura de Datos Esperada

### **Requisitos del JSON:**
```json
{
  "codCargo": 151,
  "codCargoPadre": 149,
  "descripcion": "SERENO",
  "nivel": 3,              // ← IMPORTANTE: Define la fila vertical
  "posicion": 9,           // ← IMPORTANTE: Define el orden horizontal
  "estado": 1,             // 1=activo, 0=inactivo
  "tieneEmpleadosActivos": 1,
  "numHijosActivos": 0
}
```

### **Cómo Ordenar tus Datos en el Backend:**

```sql
-- Ejemplo para ordenar correctamente
SELECT 
  codCargo,
  descripcion,
  nivel,
  posicion
FROM cargos
WHERE codEmpresa = 6
ORDER BY nivel ASC, posicion ASC;
```

**Resultado esperado:**
```
nivel | posicion | descripcion
------|----------|---------------------------
0     | 1        | GERENTE GENERAL
1     | 1        | GERENTE ADMINISTRATIVO
1     | 1        | GERENTE DE SISTEMAS
2     | 2        | ASESOR LEGAL
2     | 3        | SUPERVISOR DE LOGÍSTICA
3     | 6        | RECEPCIONISTA             ← Más a la izquierda
3     | 8        | PERSONAL DE LIMPIEZA      ← Medio
3     | 9        | SERENO                    ← Más a la derecha
```

---

## 🎯 Validación del Ordenamiento

### **Verificar en la UI:**

1. Abre el organigrama
2. Busca nodos en el **mismo nivel** (misma altura Y)
3. Verifica que estén ordenados **de izquierda a derecha** por `posicion`

### **Debug Visual:**
Cada nodo muestra en la parte inferior:
```
N:3 P:9
```
- **N**: Nivel jerárquico
- **P**: Posición (orden)

---

## 🔍 Diferencias vs GraphView

| Aspecto | GraphView (Eliminado) | Custom (Actual) |
|---------|----------------------|-----------------|
| **Orden** | ❌ No respeta posición | ✅ Respeta estrictamente |
| **Control** | ⚠️ Automático (impredecible) | ✅ 100% determinístico |
| **Performance** | ⭐⭐⭐ Buena | ⭐⭐⭐⭐ Excelente |
| **Flexibilidad** | ⚠️ Limitada | ✅ Total control |
| **Complejidad** | 🔴 Alta (algoritmos complejos) | 🟢 Baja (código simple) |

---

## 📝 Ejemplo de Uso

### **En tu base de datos:**

```sql
-- Actualizar posiciones para ordenar correctamente
UPDATE cargos SET posicion = 6 WHERE descripcion = 'RECEPCIONISTA';
UPDATE cargos SET posicion = 8 WHERE descripcion = 'PERSONAL DE SERVICIO Y LIMPIEZA';
UPDATE cargos SET posicion = 9 WHERE descripcion = 'SERENO';
```

### **Resultado en UI:**

```
Nivel 3 (Y = 500px):

┌────────────────┐          ┌──────────────────────┐          ┌──────────┐
│ RECEPCIONISTA  │  →  →  →  │  PERSONAL LIMPIEZA  │  →  →  →  │  SERENO  │
│   (pos: 6)     │          │      (pos: 8)        │          │ (pos: 9) │
│   X: 100       │          │      X: 340          │          │ X: 580   │
└────────────────┘          └──────────────────────┘          └──────────┘
```

---

## ⚙️ Personalización

### **Cambiar separación horizontal:**
```dart
// Línea 37 de organigrama_custom.dart
const double horizontalSpacing = 60;  // Actual
const double horizontalSpacing = 100; // Más espacio
const double horizontalSpacing = 30;  // Menos espacio
```

### **Cambiar separación vertical:**
```dart
// Línea 38 de organigrama_custom.dart
const double verticalSpacing = 140;  // Actual
const double verticalSpacing = 180;  // Más espacio
const double verticalSpacing = 100;  // Menos espacio
```

### **Cambiar tamaño de nodos:**
```dart
// Líneas 35-36 de organigrama_custom.dart
const double nodeWidth = 180;   // Actual
const double nodeHeight = 95;   // Actual

// Para nodos más grandes:
const double nodeWidth = 220;
const double nodeHeight = 110;
```

---

## 🐛 Troubleshooting

### **Problema: Nodos no se ordenan correctamente**
**Causa**: Los valores de `posicion` no están bien asignados
**Solución**: 
```sql
-- Verificar posiciones
SELECT codCargo, descripcion, nivel, posicion, codCargoPadre
FROM cargos
WHERE nivel = 3  -- El nivel que tiene problemas
ORDER BY posicion;

-- Si hay duplicados o valores incorrectos, actualizar:
UPDATE cargos SET posicion = [nuevo_valor] WHERE codCargo = [codigo];
```

### **Problema: Nodos están muy juntos**
**Solución**: Aumentar `horizontalSpacing` en el código

### **Problema: Organigrama muy alto**
**Solución**: Reducir `verticalSpacing` en el código

### **Problema: No puedo hacer pan (mover el organigrama)**
**Causa**: GestureDetector bloqueando InteractiveViewer
**Estado**: ✅ YA CORREGIDO con `behavior: HitTestBehavior.translucent`

---

## 📦 Archivos del Sistema

### **Creados:**
- ✅ `organigrama_custom.dart` - Widget principal del organigrama

### **Modificados:**
- ✅ `cargos_screen.dart` - Usa `OrganigramaCustom`

### **Eliminados:**
- ❌ `organigrama_cuadricula.dart` - Layout anterior
- ❌ `organigrama_graphview.dart` - GraphView que no funcionó
- ❌ `MIGRATION_GRAPHVIEW.md` - Documentación obsoleta

---

## 🎉 Resultado Final

El nuevo organigrama:
1. ✅ **Respeta estrictamente** nivel y posición
2. ✅ **Es predecible**: mismo orden de datos = mismo layout
3. ✅ **Es eficiente**: solo 50 líneas de lógica de layout
4. ✅ **Es mantenible**: código simple y claro
5. ✅ **Es flexible**: fácil de ajustar separaciones
6. ✅ **Es completo**: todas las funcionalidades implementadas

---

## 📞 Soporte

Si necesitas ajustar algo:
1. **Separaciones**: Modifica constantes en líneas 35-38
2. **Colores**: Modifica `_getNodeColor()` líneas 451-477
3. **Información mostrada**: Modifica `_buildNodeContent()` líneas 316-420
4. **Conexiones**: Modifica `ConexionesPainter` líneas 538-609

¡El organigrama ahora funciona perfectamente con tu estructura de datos! 🚀
