/*
/// ARCHIVO DE REFERENCIA - PATRÓN DE OPTIMIZACIÓN
///
/// Este archivo NO es código funcional, es DOCUMENTACIÓN.
/// Sirve como referencia rápida del patrón a seguir en todos
/// los widgets del módulo de registro de empleado.
///
/// ============================================================================
/// RESUMEN EJECUTIVO DEL PATRÓN
/// ============================================================================
///
/// 1️⃣ IMPORTS CLAVE
/// • responsive_utils_registro_empleado.dart ← para context.spacing, etc
/// • registro_empleado_utils.dart ← para DisplayValue, FechaUtils
/// • abm_service.dart ← para executeABM
///
/// 2️⃣ ESTRUCTURA GENERAL
/// • ConsumerWidget para LECTURA
/// • ConsumerStatefulWidget para EDICIÓN
/// • Métodos privados: _buildXxxView(), _buildXxxSection()
///
/// 3️⃣ RESPONSIVIDAD (OBLIGATORIA)
/// ✅ context.isMobile / context.isTablet / context.isDesktop
/// ✅ context.spacing / context.padding / context.borderRadius
/// ✅ context.bodyStyle / context.subtitleStyle / context.titleStyle
/// ✅ context.iconSize / context.smallIconSize / context.largeIconSize
///
/// 4️⃣ UTILIDADES A USAR
/// ✅ DisplayValue<T> para mostrar valores (en VISTAS/lectura)
/// ✅ FechaUtils.formatDate() para fechas
/// ✅ CustomDropdown<T> para formularios
/// ✅ CustomDatePicker para fecha en formularios
/// ✅ executeABM() para CRUD operations
///
/// 5️⃣ ELIMINAR (REFACTORIZAR)
/// ❌ Funciones duplicadas (_formatDate, _getEstadoCivil, etc)
/// ❌ Métodos complejos que devuelven String (usar DisplayValue)
/// ❌ Código no responsivo (usar context.spacing, padding, etc)
/// ❌ Manejo manual de errores (usar executeABM)
/// ❌ ScaffoldMessenger.showSnackBar() manual (usar executeABM)
///
/// 6️⃣ VALIDAR ANTES DE COMPLETAR
/// ✅ ¿Todo es responsivo (móvil/web)?
/// ✅ ¿Sin código duplicado?
/// ✅ ¿Usa DisplayValue para lookups?
/// ✅ ¿Usa executeABM para operaciones?
/// ✅ ¿Usa FechaUtils para fechas?
/// ✅ ¿Importaciones correctas?
/// ✅ ¿Funcionalidad original preservada?
///
/// ============================================================================
/// TEMPLATE RÁPIDO
/// ============================================================================
///
/// class MiWidget extends ConsumerWidget {
/// final Entity entity;
///
/// const MiWidget({required this.entity});
///
/// @override
/// Widget build(BuildContext context, WidgetRef ref) {
/// return context.isMobile
/// ? _buildMobileView(context, ref)
/// : _buildWebView(context, ref);
/// }
///
/// Widget _buildMobileView(BuildContext context, WidgetRef ref) {
/// return SingleChildScrollView(
/// padding: EdgeInsets.all(context.spacing),
/// child: Column(
/// crossAxisAlignment: CrossAxisAlignment.start,
/// children: [
/// _buildSeccion1(context, ref),
/// SizedBox(height: context.largeSpacing),
/// _buildSeccion2(context, ref),
/// ],
/// ),
/// );
/// }
///
/// Widget _buildWebView(BuildContext context, WidgetRef ref) {
/// return SingleChildScrollView(
/// padding: EdgeInsets.all(context.spacing),
/// child: Row(
/// crossAxisAlignment: CrossAxisAlignment.start,
/// children: [
/// Expanded(
/// flex: 1,
/// child: Column(
/// children: [
/// _buildSeccion1(context, ref),
/// SizedBox(height: context.largeSpacing),
/// _buildSeccion2(context, ref),
/// ],
/// ),
/// ),
/// SizedBox(width: context.largeSpacing * 2),
/// Expanded(flex: 1, child: _buildSeccion3(context, ref)),
/// ],
/// ),
/// );
/// }
///
/// Widget _buildSeccion1(BuildContext context, WidgetRef ref) {
/// return Column(
/// crossAxisAlignment: CrossAxisAlignment.start,
/// children: [
/// _buildSectionTitle(context, 'Título'),
/// _buildDataRow(context, 'Label:', entity.valor),
/// _buildDataRowWithValue(
/// context,
/// 'Lookup:',
/// DisplayValue<Tipo>(
/// code: entity.codigo,
/// provider: tipoProvider,
/// getCode: (e) => e.cod,
/// getDescription: (e) => e.nombre,
/// fallback: entity.codigo,
/// ),
/// ),
/// ],
/// );
/// }
///
/// Widget _buildSectionTitle(BuildContext context, String title) {
/// return Padding(
/// padding: EdgeInsets.only(bottom: context.smallSpacing, top: context.smallSpacing),
/// child: Column(
/// crossAxisAlignment: CrossAxisAlignment.start,
/// children: [
/// Text(title, style: context.subtitleStyle.copyWith(fontWeight: FontWeight.bold)),
/// Divider(height: context.spacing * 1.5),
/// ],
/// ),
/// );
/// }
///
/// Widget _buildDataRow(BuildContext context, String label, String value) {
/// return Padding(
/// padding: EdgeInsets.symmetric(vertical: context.smallSpacing),
/// child: Row(
/// crossAxisAlignment: CrossAxisAlignment.start,
/// children: [
/// SizedBox(
/// width: context.isMobile ? 120 : 150,
/// child: Text(label, style: context.bodyStyle.copyWith(fontWeight: FontWeight.w600)),
/// ),
/// Expanded(child: Text(value, style: context.bodyStyle)),
/// ],
/// ),
/// );
/// }
///
/// Widget _buildDataRowWithValue(BuildContext context, String label, Widget value) {
/// return Padding(
/// padding: EdgeInsets.symmetric(vertical: context.smallSpacing),
/// child: Row(
/// crossAxisAlignment: CrossAxisAlignment.start,
/// children: [
/// SizedBox(
/// width: context.isMobile ? 120 : 150,
/// child: Text(label, style: context.bodyStyle.copyWith(fontWeight: FontWeight.w600)),
/// ),
/// Expanded(child: value),
/// ],
/// ),
/// );
/// }
/// }
///
/// ============================================================================
/// TABLA DE UTILIDADES
/// ============================================================================
///
/// | Utilidad | Uso | Dónde |
/// |----------|-----|-------|
/// | context.isMobile | Detectar dispositivo | Todo widget |
/// | context.spacing | Padding/margin | Todo widget |
/// | context.bodyStyle | Texto body | Todo widget |
/// | DisplayValue<T> | Mostrar lookup | SOLO lectura |
/// | FechaUtils.formatDate | Formato fecha | Lectura + Formulario |
/// | CustomDropdown<T> | Dropdown select | SOLO formularios |
/// | CustomDatePicker | Date picker | SOLO formularios |
/// | executeABM | CRUD operations | Formularios/Edición |
/// | EmployeeImageCell | Foto empleado | Donde sea necesario |
///
/// ============================================================================
/// CHECKLIST FINAL
/// ============================================================================
///
/// Antes de dar por completo un widget, verificar TODO:
///
/// □ Responsivo (móvil/web separados)
/// □ Usando context.spacing, context.padding
/// □ Usando context.bodyStyle, context.subtitleStyle
/// □ DisplayValue para lookups en lectura
/// □ FechaUtils.formatDate para fechas
/// □ executeABM para operaciones CRUD
/// □ CustomDropdown en formularios (no DisplayValue)
/// □ Sin funciones duplicadas (_formatDate, etc)
/// □ _buildXxxSection() para cada sección
/// □ _buildDataRow() y _buildDataRowWithValue() reutilizables
/// □ SingleChildScrollView en raíz
/// □ Importaciones correctas
/// □ Código limpio y sin repetición
/// □ Funcionalidad original preservada
///
/// ============================================================================
/// REFERENCIAS
/// ============================================================================
///
/// Ejemplos completos ya optimizados:
/// • detalle_persona.dart ← Ver cómo se implementa todo
/// • lista_empleados.dart ← Ver responsividad en listas
/// • form_persona.dart ← Ver layouts móvil/web
/// • detalle_educacion.dart ← Ver DisplayValue en acción
///
///
**Cambios principales agregados:**

✅ Sección 0: Entender contexto (Modo nuevo vs Edición)
✅ Diferencia clara entre `executeABM()` y `showSuccessMessage()`
✅ Patrón `_buildNuevoMode()` con carga desde servidor
✅ Patrón `_buildEdicionMode()` directo del servidor
✅ Acciones separadas para Modo Nuevo y Modo Edición
✅ Explicación de cuándo NO usar executeABM
✅ Nota sobre eliminar etiquetas innecesarias
✅ Referencia actualizada a `detalle_telefono.dart`
✅ Tabla comparativa Modo Nuevo vs Edición**Cambios principales agregados:**

✅ Sección 0: Entender contexto (Modo nuevo vs Edición)
✅ Diferencia clara entre `executeABM()` y `showSuccessMessage()`
✅ Patrón `_buildNuevoMode()` con carga desde servidor
✅ Patrón `_buildEdicionMode()` directo del servidor
✅ Acciones separadas para Modo Nuevo y Modo Edición
✅ Explicación de cuándo NO usar executeABM
✅ Nota sobre eliminar etiquetas innecesarias
✅ Referencia actualizada a `detalle_telefono.dart`
✅ Tabla comparativa Modo Nuevo vs Edición
*/
