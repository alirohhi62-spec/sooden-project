import 'package:bms/core/utils/extension.dart';
import 'package:flutter/material.dart';

import '../../core/values/theme.dart';

class RitaTextField extends StatefulWidget {

  TextEditingController? controller;
  String? hint;
  bool? enabled;
  TextInputType? keyboardType;
  RitaTextField({super.key, this.controller, this.hint, this.enabled,this.keyboardType});

  @override
  State<StatefulWidget> createState() => _RitaTextFieldState();
}

class _RitaTextFieldState extends State<RitaTextField> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: Colors.grey,
          width: 1.0,
        ),
      ),
      child: TextField(
        keyboardType: widget.keyboardType,
        controller: widget.controller,
        enabled: widget.enabled ?? true,
        decoration: InputDecoration(
          contentPadding: EdgeInsets.all(8.0.dp),
          border: InputBorder.none,
          hintStyle: AppTheme().textSecondary4Regular,
          hintText: widget.hint ?? '',
        ),
      ),
    );
  }
}
