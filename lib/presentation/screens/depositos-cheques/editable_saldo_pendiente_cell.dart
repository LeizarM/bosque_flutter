import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EditableSaldoPendienteCell extends StatefulWidget {
  final double valorOriginal;
  final String valorActual;
  final void Function(String, void Function(bool)) onChanged;
  
  const EditableSaldoPendienteCell({
    required this.valorOriginal,
    required this.valorActual,
    required this.onChanged,
    Key? key,
  }) : super(key: key);

  @override
  State<EditableSaldoPendienteCell> createState() => _EditableSaldoPendienteCellState();
}

class _EditableSaldoPendienteCellState extends State<EditableSaldoPendienteCell> {
  late TextEditingController _controller;
  String? _errorText;
  final FocusNode _focusNode = FocusNode();
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.valorActual);
    
    // Agregar listener para detectar cuando pierde el foco
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _validateAndFormat();
      }
    });
  }

  @override
  void didUpdateWidget(covariant EditableSaldoPendienteCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Solo actualiza el texto si el valor cambió y el campo NO tiene el foco
    if (oldWidget.valorActual != widget.valorActual && !_focusNode.hasFocus) {
      _controller.text = widget.valorActual;
      _validateValue(widget.valorActual);
    }
  }

  void _validateAndFormat() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      _controller.text = '0.00';
      widget.onChanged('0.00', (show) => _setError(show));
      return;
    }

    final value = double.tryParse(text);
    if (value != null) {
      // Validate value is not greater than original
      if (value > widget.valorOriginal) {
        // Reset to original value if larger
        _controller.text = widget.valorOriginal.toStringAsFixed(2);
        _setError(true);
        widget.onChanged(widget.valorOriginal.toStringAsFixed(2), (show) => _setError(show));
      } else {
        // Formatear a 2 decimales
        _controller.text = value.toStringAsFixed(2);
        _validateValue(value.toStringAsFixed(2));
      }
    }
  }

  void _validateValue(String value) {
    final val = double.tryParse(value) ?? 0.0;
    final isInvalid = val > widget.valorOriginal;
    
    _setError(isInvalid);
    widget.onChanged(value, (show) => _setError(show));
  }

  void _setError(bool hasError) {
    setState(() {
      _hasError = hasError;
      _errorText = hasError ? 'Máximo: ${widget.valorOriginal.toStringAsFixed(2)}' : null;
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 120,
          child: TextFormField(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            focusNode: _focusNode,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            onChanged: (value) {
              // Prevent typing values larger than original
              final val = double.tryParse(value) ?? 0.0;
              if (val > widget.valorOriginal) {
                _setError(true);
              } else {
                _validateValue(value);
              }
            },
            onFieldSubmitted: (_) => _validateAndFormat(),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderSide: BorderSide(
                  color: _hasError ? Colors.red : Colors.grey.shade400,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: _hasError ? Colors.red : Colors.grey.shade400,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: _hasError ? Colors.red : Theme.of(context).primaryColor,
                  width: 2,
                ),
              ),
              errorBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red, width: 2),
              ),
              focusedErrorBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red, width: 2),
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              suffixText: 'Bs',
              suffixStyle: TextStyle(
                color: _hasError ? Colors.red : Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
            style: TextStyle(
              color: _hasError ? Colors.red : null,
              fontWeight: _hasError ? FontWeight.w500 : null,
            ),
          ),
        ),
        if (_errorText != null)
          Container(
            width: 160, // Wider container to handle error text overflow
            margin: const EdgeInsets.only(top: 4),
            child: Text(
              _errorText!,
              style: const TextStyle(
                color: Colors.red, 
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2, // Allow up to 2 lines for the error message
              overflow: TextOverflow.ellipsis, // Use ellipsis for longer messages
            ),
          ),
      ],
    );
  }
}
