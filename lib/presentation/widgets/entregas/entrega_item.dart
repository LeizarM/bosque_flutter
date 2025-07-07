import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/entregas_entity.dart';
import 'package:flutter/material.dart';

class EntregaItem extends StatefulWidget {
  final EntregaEntity entrega;
  final List<EntregaEntity> productosAdicionalesEntrega;
  final bool rutaIniciada;
  final VoidCallback onTap;
  final bool disabled;
  final bool todosEntregados;
  final bool algunoEntregado;

  const EntregaItem({
    super.key,
    required this.entrega,
    this.productosAdicionalesEntrega = const [],
    required this.rutaIniciada,
    required this.onTap,
    this.disabled = false,
    this.todosEntregados = false,
    this.algunoEntregado = false,
  });

  @override
  State<EntregaItem> createState() => _EntregaItemState();
}

class _EntregaItemState extends State<EntregaItem> {
  bool _isProductosExpanded = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // Obtener dimensiones responsivas
    final bool isMobile = ResponsiveUtilsBosque.isMobile(context);
    final bool isTablet = ResponsiveUtilsBosque.isTablet(context);
    final double horizontalPadding = ResponsiveUtilsBosque.getHorizontalPadding(context);
    
    // Determinar estado visual
    final bool entregado = widget.todosEntregados;
    final bool parcial = !widget.todosEntregados && widget.algunoEntregado;
    
    // Colores y estilos según el estado
    final Color backgroundColor = entregado
        ? colorScheme.primaryContainer.withAlpha(80)
        : parcial
            ? colorScheme.secondaryContainer.withAlpha(80)
            : widget.disabled
                ? colorScheme.surfaceTint.withAlpha(30)
                : colorScheme.surface;
    
    final Color borderColor = entregado
        ? colorScheme.primary
        : parcial
            ? colorScheme.secondary
            : widget.disabled
                ? colorScheme.outline
                : colorScheme.primary;
    
    final IconData iconData = entregado
        ? Icons.check_circle
        : parcial
            ? Icons.incomplete_circle
            : widget.disabled
                ? Icons.hourglass_empty
                : Icons.local_shipping;
    
    final Color iconColor = entregado
        ? colorScheme.primary
        : parcial
            ? colorScheme.secondary
            : widget.disabled
                ? colorScheme.outline
                : colorScheme.primary;
    
    // Obtener la lista completa de productos
    final productos = widget.productosAdicionalesEntrega.isEmpty 
        ? [widget.entrega] 
        : widget.productosAdicionalesEntrega;
    
    // Ajustar tamaños de fuente según el dispositivo
    final double titleFontSize = ResponsiveUtilsBosque.getResponsiveValue(
      context: context,
      defaultValue: 18.0,
      mobile: 16.0,
      tablet: 17.0,
      desktop: 18.0,
    );
    
    final double subtitleFontSize = ResponsiveUtilsBosque.getResponsiveValue(
      context: context,
      defaultValue: 14.0,
      mobile: 13.0,
      tablet: 13.5,
      desktop: 14.0,
    );
    
    final double contentFontSize = ResponsiveUtilsBosque.getResponsiveValue(
      context: context,
      defaultValue: 13.0,
      mobile: 12.0,
      tablet: 12.5,
      desktop: 13.0,
    );
    
    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: horizontalPadding / 2,
        vertical: 6,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: 1),
      ),
      elevation: 2,
      color: backgroundColor,
      child: InkWell(
        onTap: widget.disabled ? null : widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(horizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabecera con información del cliente y factura
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Círculo con icono
                  Container(
                    width: isMobile ? 40 : 48,
                    height: isMobile ? 40 : 48,
                    decoration: BoxDecoration(
                      color: iconColor.withAlpha(40),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(iconData, color: iconColor, size: isMobile ? 24 : 28),
                    ),
                  ),
                  SizedBox(width: isMobile ? 8 : 12),
                  // Información del cliente y factura
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.entrega.cardName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: titleFontSize,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          children: [
                            Text(
                              'Factura: ${widget.entrega.factura}',
                              style: TextStyle(
                                fontSize: subtitleFontSize,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                            Text(
                              'Fecha: ${_formatDate(widget.entrega.docDate)}',
                              style: TextStyle(
                                fontSize: subtitleFontSize,
                                color: colorScheme.onSurface.withAlpha(200),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Estado de entrega
                  if (entregado)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Entregado',
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontSize: contentFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else if (parcial)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: colorScheme.secondary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Parcial',
                        style: TextStyle(
                          color: colorScheme.onSecondary,
                          fontSize: contentFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else if (widget.rutaIniciada && !widget.disabled)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: colorScheme.secondary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Pendiente',
                        style: TextStyle(
                          color: colorScheme.onSecondary,
                          fontSize: contentFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceTint.withAlpha(80),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Bloqueado',
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: contentFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
              
              // Dirección
              _buildInfoSection(
                context,
                'Dirección:',
                widget.entrega.addressEntregaMat.isNotEmpty 
                    ? widget.entrega.addressEntregaMat 
                    : widget.entrega.addressEntregaFac,
                Icons.location_on,
                colorScheme.primary,
                subtitleFontSize,
                contentFontSize,
              ),
              
              const SizedBox(height: 12),
              
              // Observaciones
              if (widget.entrega.obsF.isNotEmpty)
                _buildInfoSection(
                  context,
                  'Observaciones Nota:',
                  widget.entrega.obsF,
                  Icons.comment,
                  colorScheme.secondary,
                  subtitleFontSize,
                  contentFontSize,
                ),
                
              if (widget.entrega.obsF.isNotEmpty)
                const SizedBox(height: 12),
              
              // Panel expandible para productos
              _buildExpandableProductPanel(
                context, 
                productos, 
                colorScheme,
                subtitleFontSize,
                contentFontSize,
              ),
              
              const SizedBox(height: 12),
              
              // Información de entrega completada
              if (entregado && widget.entrega.direccionEntrega != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withAlpha(80),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colorScheme.primary.withAlpha(130)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: colorScheme.primary,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Información de entrega',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: subtitleFontSize,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Dirección confirmada: ${widget.entrega.direccionEntrega}',
                        style: TextStyle(
                          fontSize: contentFontSize,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ubicación: ${widget.entrega.latitud.toStringAsFixed(6)}, ${widget.entrega.longitud.toStringAsFixed(6)}',
                        style: TextStyle(
                          fontSize: contentFontSize,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Fecha y hora: ${widget.entrega.fechaEntrega.day.toString().padLeft(2, '0')}/${widget.entrega.fechaEntrega.month.toString().padLeft(2, '0')}/${widget.entrega.fechaEntrega.year} ${widget.entrega.fechaEntrega.hour.toString().padLeft(2, '0')}:${widget.entrega.fechaEntrega.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: contentFontSize,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Botón para marcar como entregado si no está entregado y la ruta está iniciada
              if (!widget.todosEntregados && widget.rutaIniciada && !widget.disabled)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Center(
                    child: ElevatedButton.icon(
                      onPressed: widget.onTap,
                      icon: const Icon(Icons.check),
                      label: const Text('Marcar como entregado'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        minimumSize: Size(isMobile ? 180 : 200, isMobile ? 36 : 40),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoSection(
    BuildContext context,
    String title,
    String content,
    IconData iconData,
    Color iconColor,
    double titleSize,
    double contentSize,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(iconData, size: 18, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: titleSize,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                content,
                style: TextStyle(
                  fontSize: contentSize,
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(220),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExpandableProductPanel(
    BuildContext context, 
    List<EntregaEntity> productos,
    ColorScheme colorScheme,
    double titleSize,
    double contentSize,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Encabezado expansible
        InkWell(
          onTap: () {
            setState(() {
              _isProductosExpanded = !_isProductosExpanded;
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(Icons.inventory_2, size: 18, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Productos (${productos.length}):',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: titleSize,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                Icon(
                  _isProductosExpanded 
                      ? Icons.keyboard_arrow_up 
                      : Icons.keyboard_arrow_down,
                  color: colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
        
        // Contenido expandible
        AnimatedCrossFade(
          firstChild: const SizedBox(height: 0),
          secondChild: Column(
            children: [
              const SizedBox(height: 8),
              ...productos.map((producto) => _buildProductItem(
                context,
                producto,
                colorScheme,
                contentSize,
              )),
            ],
          ),
          crossFadeState: _isProductosExpanded 
              ? CrossFadeState.showSecond 
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
        ),
      ],
    );
  }

  Widget _buildProductItem(
    BuildContext context,
    EntregaEntity producto,
    ColorScheme colorScheme,
    double fontSize,
  ) {
    final bool isMobile = ResponsiveUtilsBosque.isMobile(context);
    
    return Container(
      margin: EdgeInsets.only(
        bottom: 12, 
        left: isMobile ? 16 : 26
      ),
      padding: EdgeInsets.all(isMobile ? 8 : 10),
      decoration: BoxDecoration(
        color: producto.fueEntregado == 1
            ? colorScheme.primaryContainer.withAlpha(40)
            : colorScheme.surfaceTint.withAlpha(10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: producto.fueEntregado == 1
              ? colorScheme.primary.withAlpha(100)
              : colorScheme.outline.withAlpha(50),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Indicador de estado del producto
          Container(
            width: isMobile ? 14 : 16,
            height: isMobile ? 14 : 16,
            margin: EdgeInsets.only(top: 2, right: isMobile ? 8 : 10),
            decoration: BoxDecoration(
              color: producto.fueEntregado == 1
                  ? colorScheme.primary.withAlpha(50)
                  : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: producto.fueEntregado == 1
                    ? colorScheme.primary
                    : colorScheme.outline,
                width: 2,
              ),
            ),
            child: producto.fueEntregado == 1
                ? Icon(
                    Icons.check,
                    size: isMobile ? 10 : 12,
                    color: colorScheme.primary,
                  )
                : null,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Código del producto
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      producto.itemCode,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    if (producto.fueEntregado == 1)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Entregado',
                          style: TextStyle(
                            color: colorScheme.onPrimary,
                            fontSize: isMobile ? 9 : 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                // Descripción del producto
                Text(
                  producto.dscription,
                  style: TextStyle(
                    fontSize: fontSize,
                  ),
                ),
                const SizedBox(height: 4),
                // Cantidad
                Wrap(
                  spacing: 16,
                  runSpacing: 4,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Cantidad: ',
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          producto.quantity.toString(),
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Almacén: ',
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          producto.whsCode,
                          style: TextStyle(
                            fontSize: fontSize,
                            color: colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Formatear fecha
  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    return '$day/$month/$year';
  }
}