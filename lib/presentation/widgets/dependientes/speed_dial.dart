import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

class CustomSpeedDial extends StatelessWidget {
  final bool visible;
  final List<String> operacionHabilitada;
  final String nombreSeccion;
  final VoidCallback? onAgregar;
  final VoidCallback? onEditar;
  final VoidCallback? onEliminar;
  final void Function(String?)? updateOperation;
  final Map<String, String?>? selectedOperation;
  final IconData? mainIcon;
  final bool showLabels;
  final SpeedDialDirection direction;
  final Size? buttonSize;
  final Size? childrenButtonSize;

  const CustomSpeedDial({
    Key? key,
    this.visible = true,
    this.operacionHabilitada = const ['editar'],
    required this.nombreSeccion,
    this.onAgregar,
    this.onEditar,
    this.onEliminar,
    this.updateOperation,
    this.selectedOperation,
    this.mainIcon = Icons.settings,
    this.showLabels = false,
    this.direction = SpeedDialDirection.left,
    this.buttonSize = const Size(38, 38),
    this.childrenButtonSize = const Size(32, 32),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SpeedDial(
      visible: visible,
      buttonSize: buttonSize!,
      childrenButtonSize: childrenButtonSize!,
      backgroundColor: Colors.deepPurple,
      foregroundColor: Colors.white,
      overlayOpacity: 0.2,
      direction: direction,
      icon: mainIcon,
      activeIcon: Icons.close,
      spacing: 3,
      
      spaceBetweenChildren: 4,
      children: [
        if (operacionHabilitada.contains('agregar'))
          SpeedDialChild(
            child: const Icon(Icons.add, size: 24),
            backgroundColor: Colors.green,
            label: showLabels ? 'Agregar' : null,
            onTap: () {
              if (updateOperation != null) {
                updateOperation!('agregar');
              }
              if (onAgregar != null) onAgregar!();
            },
          ),
        if (operacionHabilitada.contains('editar'))
          SpeedDialChild(
            child: const Icon(Icons.edit, size: 24),
            backgroundColor: Colors.blue,
            label: showLabels ? 'Editar' : null,
            onTap: () {
              if (updateOperation != null) {
                updateOperation!(selectedOperation?[nombreSeccion] == 'editar' 
                    ? null 
                    : 'editar');
              }
              if (onEditar != null) onEditar!();
            },
          ),
        if (operacionHabilitada.contains('eliminar'))
          SpeedDialChild(
            child: const Icon(Icons.delete, size: 24),
            backgroundColor: Colors.redAccent,
            label: showLabels ? 'Eliminar' : null,
            onTap: () {
              if (updateOperation != null) {
                updateOperation!(selectedOperation?[nombreSeccion] == 'eliminar' 
                    ? null 
                    : 'eliminar');
              }
              if (onEliminar != null) onEliminar!();
            },
          ),
      ],
      //child: _buildRotatingIcon(),
    );
  }
//para controlar la animación del icono principal
 /* Widget _buildRotatingIcon() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      builder: (context, value, child) {
        return Transform.rotate(
          angle: value * 2 * 3.1416,
          child: const Icon(Icons.settings, size: 26),
        );
      },
    );
  }*/
}