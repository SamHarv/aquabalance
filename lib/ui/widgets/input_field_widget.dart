import 'package:flutter/material.dart';

import '../../config/constants.dart';

class InputFieldWidget extends StatefulWidget {
  /// Display [InputFieldWidget] which allows user to input values

  final TextEditingController controller;
  final String label;
  final ValueChanged<String> onChanged;
  final bool floatingLabel;

  const InputFieldWidget({
    super.key,
    required this.controller,
    required this.label,
    required this.onChanged,
    required this.floatingLabel,
  });

  @override
  State<InputFieldWidget> createState() => _InputFieldWidgetState();
}

class _InputFieldWidgetState extends State<InputFieldWidget> {
  @override
  Widget build(BuildContext context) {
    return TextField(
      style: inputFieldStyle,
      // keyboardType: TextInputType., // Numeric inputs
      controller: widget.controller,
      onChanged: widget.onChanged, // on changed function can be called
      decoration: InputDecoration(
        suffix: widget.floatingLabel
            ? null
            : Text(widget.label, style: inputFieldStyle),
        floatingLabelBehavior: widget.floatingLabel
            ? FloatingLabelBehavior
                  .auto // Display floating label
            : FloatingLabelBehavior
                  .never, // Remove floating label (when background not white)
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder,
        filled: true,
        fillColor: white,
        labelText: widget.label,
        labelStyle: inputFieldStyle,
      ),
    );
  }
}
