import 'package:flutter/material.dart';

class CumpleanosBanner extends StatelessWidget {
  final List<String> cumpleMensajes;
  final VoidCallback onClose;

  const CumpleanosBanner({
    Key? key,
    required this.cumpleMensajes,
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (cumpleMensajes.isEmpty) return SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFE1E3F6),
            Color(0xFFD1F5E0),
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Color(0xFF6C3483), width: 2),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF6C3483).withOpacity(0.10),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text('🎂', style: TextStyle(fontSize: 36)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "¡Hoy celebramos cumpleaños!",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Color(0xFF6C3483),
                    shadows: [
                      Shadow(
                        color: Color(0xFF2ECC71).withOpacity(0.13),
                        blurRadius: 4,
                        offset: const Offset(1, 1),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Color(0xFF6C3483), size: 28),
                tooltip: "Cerrar",
                onPressed: onClose,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: BoxDecoration(
              color: Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Color(0xFF2ECC71).withOpacity(0.18), width: 1.2),
            ),
            child: Column(
              children: [
                ...cumpleMensajes.map((mensaje) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Text('🎉', style: TextStyle(fontSize: 22)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          mensaje,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Color(0xFF512DA8),
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text('¡Felicidades!', style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2ECC71),
                letterSpacing: 1.2,
              )),
              SizedBox(width: 8),
              Text('🥳', style: TextStyle(fontSize: 22)),
            ],
          ),
        ],
      ),
    );
  }
}