import 'package:bms/core/values/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

AppBar appBar(String title,{List<Widget>? actions}) => AppBar(
      title: Text(
        title,
        style: AppTheme().textPrimary3Medium,
      ),
      backgroundColor: Colors.transparent,
      actions: actions,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: AppTheme().backgroundColor,
        statusBarIconBrightness: Brightness.dark,
        // For Android (dark icons)
        statusBarBrightness: Brightness.light, // For// iOS (dark icons)
      ),
    );
