import 'package:bms/core/utils/extension.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../core/values/theme.dart';

class SecondaryButton extends StatefulWidget {
  late String text;
  late VoidCallback onTap;
  Color? background;
  bool? enable;
  bool? loading;

  SecondaryButton({
    super.key,
    required this.text,
    required this.onTap,
    this.background,
    this.enable,
    this.loading,
  });

  @override
  State<StatefulWidget> createState() => _SecondaryButtonState();
}

class _SecondaryButtonState extends State<SecondaryButton> {
  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: (widget.enable ?? true) ? widget.onTap : null,

      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.all(8.0.dp),
            child: (widget.loading ?? false)
                ? Lottie.asset('assets/lottie/loading-dots.json', height: 21.0.dp)
                : Text(
                    widget.text,
                    style: AppTheme().textPrimary4Medium,
                  ),
          ),
        ],
      ),
    );
  }
}
