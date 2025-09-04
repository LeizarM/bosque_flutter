import 'package:flutter/material.dart';

class BannerCustom extends StatelessWidget {
  final String message;
  final Color color;
  final IconData icon;
  final VoidCallback? onClose;
   final TextStyle? messageTextStyle;
  final int? maxLines;

  const BannerCustom({
    super.key,
    required this.message,
    this.color = Colors.red,
    this.icon = Icons.warning,
    this.onClose,
    this.messageTextStyle,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha((0.3 * 255).toInt()),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Container(
              width: 2,
              height: 25,
              color: Colors.white.withAlpha((0.2 * 255).toInt()),
            ),
            const SizedBox(width: 8),
            Expanded(
      child: Text(
        message,
        style: messageTextStyle ?? const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 16,
          letterSpacing: 0.2,
        ),
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      ),
    ),
            if (onClose != null)
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: onClose,
                splashRadius: 20,
                tooltip: 'Cerrar',
              ),
          ],
        ),
      ),
    );
  }
}
