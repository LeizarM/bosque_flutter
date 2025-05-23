import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EditableSaldoPendienteCell extends StatefulWidget {
  final double valorOriginal;
  final String valorActual;
  final Function(String, Function(bool)) onChanged;

  const EditableSaldoPendienteCell({
    Key? key,
    required this.valorOriginal,
    required this.valorActual,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<EditableSaldoPendienteCell> createState() => _EditableSaldoPendienteCellState();
}

class _EditableSaldoPendienteCellState extends State<EditableSaldoPendienteCell> {
  late TextEditingController _controller;
  bool _hasError = false;
  FocusNode _focusNode = FocusNode();
  bool _isEditing = false;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.valorActual);
    
    // Agregar listeners para mejor gestión del estado de edición
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() {
      _isEditing = _focusNode.hasFocus;
    });
  }

  @override
  void didUpdateWidget(EditableSaldoPendienteCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Solo actualizar el texto si no estamos editando activamente
    if (!_isEditing && oldWidget.valorActual != widget.valorActual) {
      _controller.text = widget.valorActual;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 1100;
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Container(
        width: isDesktop ? 150 : (isMobile ? 100 : 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: _isEditing || _isHovering 
                    ? [BoxShadow(
                        color: Colors.blue.withOpacity(0.2),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      )]
                    : null,
              ),
              child: TextFormField(
                controller: _controller,
                focusNode: _focusNode,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                style: TextStyle(
                  fontWeight: _isEditing ? FontWeight.bold : FontWeight.normal,
                  fontSize: isDesktop ? 15 : (isMobile ? 13 : 14),
                  color: _hasError 
                      ? Colors.red.shade700 
                      : (_isEditing ? Colors.blue.shade800 : Colors.black87),
                ),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: _hasError 
                          ? Colors.red.shade400 
                          : (_isEditing ? Colors.blue.shade400 : Colors.grey.shade400),
                      width: _isEditing ? 2 : 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: _isHovering ? Colors.blue.shade300 : Colors.grey.shade400,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Colors.blue.shade500,
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.red.shade400, width: 2),
                  ),
                  filled: true,
                  fillColor: _isEditing 
                      ? Colors.blue.shade50 
                      : (_isHovering ? Colors.grey.shade50 : Colors.white),
                  suffixIcon: _isEditing 
                      ? Icon(
                          Icons.edit, 
                          size: 16, 
                          color: Colors.blue.shade400,
                        ) 
                      : null,
                ),
                onChanged: (value) {
                  // Pasar el valor completo del campo, no solo el último caracter
                  widget.onChanged(value, (hasError) {
                    if (mounted) {
                      setState(() {
                        _hasError = hasError;
                      });
                    }
                  });
                },
                // Agregamos un listener para capturar cuando termina la edición
                onEditingComplete: () {
                  _focusNode.unfocus();
                },
              ),
            ),
            if (_hasError)
              Padding(
                padding: const EdgeInsets.only(top: 2, left: 8),
                child: Text(
                  'No puede ser mayor al saldo original',
                  style: TextStyle(
                    color: Colors.red.shade700, 
                    fontSize: isDesktop ? 11 : 10,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else if (_isEditing)
              Padding(
                padding: const EdgeInsets.only(top: 2, left: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.info_outline, 
                      size: 12, 
                      color: Colors.blue.shade400,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Máx: ${widget.valorOriginal.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.blue.shade700, 
                        fontSize: isDesktop ? 11 : 10,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }
}
