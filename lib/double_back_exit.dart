import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';

/// دو بار زدن دکمه‌ی بازگشت برای خروج.
/// به‌جای WillPopScope (که در اندروید ۱۴ به بعد با «بازگشت پیش‌بینی‌شده» درست کار نمی‌کند)
/// از PopScope استفاده شده است.
class DoubleBackExitApp extends StatefulWidget {
  final Widget child;

  const DoubleBackExitApp({super.key, required this.child});

  @override
  State<DoubleBackExitApp> createState() => _DoubleBackExitAppState();
}

class _DoubleBackExitAppState extends State<DoubleBackExitApp> {
  DateTime? lastPressed;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;

        final now = DateTime.now();
        final firstPress =
            lastPressed == null || now.difference(lastPressed!) > const Duration(seconds: 2);

        if (firstPress) {
          lastPressed = now;
          Fluttertoast.showToast(
            msg: 'برای خروج دوباره دکمه بازگشت را فشار دهید',
            backgroundColor: Colors.black,
            textColor: Colors.white,
          );
          return;
        }
        SystemNavigator.pop();
      },
      child: widget.child,
    );
  }
}
