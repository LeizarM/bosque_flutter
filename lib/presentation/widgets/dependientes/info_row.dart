import 'package:flutter/material.dart';

class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;
  final EdgeInsetsGeometry? padding;
  final IconData? icon;
  final Color? iconColor;
  final TextOverflow overflow; // <-- Agrega esto

  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.labelStyle,
    this.valueStyle,
    this.padding,
    this.icon,
    this.iconColor,
    this.overflow = TextOverflow.ellipsis, // <-- Valor por defecto
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultLabelStyle = theme.textTheme.bodyLarge?.copyWith(
      fontWeight: FontWeight.bold,
      color: theme.colorScheme.onSurface,
    );
    final defaultValueStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurface.withOpacity(0.8),
    );

    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(
              icon, 
              size: 20, 
              color: iconColor ?? theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: labelStyle ?? defaultLabelStyle,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value.isEmpty ? 'SIN REGISTROS' : value,
              style: valueStyle ?? defaultValueStyle,
              overflow: TextOverflow.ellipsis,
              
            ),
          ),
        ],
      ),
    );
  }
}