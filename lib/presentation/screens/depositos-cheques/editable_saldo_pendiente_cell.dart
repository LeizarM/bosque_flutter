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

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.valorActual);
  }

  @override
  void didUpdateWidget(EditableSaldoPendienteCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.valorActual != widget.valorActual) {
      _controller.text = widget.valorActual;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      child: TextFormField(
        controller: _controller,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
        ],
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          border: OutlineInputBorder(
            borderSide: BorderSide(
              color: _hasError ? Colors.red : Colors.grey,
            ),
          ),
          errorBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.red),
          ),
        ),
        onChanged: (value) {
          widget.onChanged(value, (hasError) {
            if (mounted) {
              setState(() {
                _hasError = hasError;
              });
            }
          });
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
