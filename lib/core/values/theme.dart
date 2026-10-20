import 'package:bms/core/utils/extension.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
//import 'package:gsform/gs_form/core/form_style.dart';

class AppTheme {
  AppTheme._privateConstructor();

  BuildContext? context;

  static final AppTheme _instance = AppTheme._privateConstructor();

  factory AppTheme() {
    return _instance;
  }

  static init(BuildContext context) {
    _instance.context = context;
  }

  ThemeData getThem() {
    return ThemeData(
      fontFamily: 'dana',
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: secondaryColor, // Use a color from your ColorScheme
        selectionColor: const Color(0xB6B0B0B0), // Use a color from your ColorScheme
        selectionHandleColor: disableColor, // Use a color from your ColorScheme
      ),
      colorScheme: ColorScheme.fromSeed(
        primary: primaryColor,
        secondary: secondaryColor,
        seedColor: Colors.deepPurple,
        brightness: Brightness.light,
        background: AppTheme().backgroundColor,
        surface: AppTheme().backgroundColor,
      ),
      useMaterial3: true,
    );
  }

  Color get primaryColor => _AppColors.primaryColor;

  Color get secondaryColor => _AppColors.secondaryColor;

  Color get green => _AppColors.green;

  Color get red => _AppColors.red;

  Color get blue => _AppColors.blue;

  Color get blueOpacity => _AppColors.blueOpacity;

  Color get rectangleColorGreen => _AppColors.rectangleColorGreen;

  Color get rectangleColorRed => _AppColors.rectangleColorRed;

  Color get amber => _AppColors.amber;

  Color get white => _AppColors.white;

  Color get disableColor => const Color(0xFF888888);

  Color get black => _AppColors.black;

  Color get backgroundColor =>
      isDarkMode() ? _AppColors.backgroundDark : _AppColors.backgroundLight;

  Color get iconcolor => isDarkMode() ? _AppColors.iconColorDark : _AppColors.iconColorLight;

  Color get textColor1 => isDarkMode() ? _AppColors.textColor1Dark : _AppColors.textColor1Light;

  Color get textColor2 => isDarkMode() ? _AppColors.textColor2Dark : _AppColors.textColor2Light;

  Color get cardBackground =>
      isDarkMode() ? _AppColors.cardBackgroundDark : _AppColors.cardBackgroundLight;

  Color get divider => isDarkMode() ? _AppColors.dividerDark : _AppColors.dividerLight;

  //<editor-fold desc="Text Primary">
  TextStyle get textPrimary6Regular =>
      TextStyle(color: textColor1, fontWeight: FontWeight.w200, fontSize: 8.0.sp);

  TextStyle get textPrimary6Medium =>
      TextStyle(color: textColor1, fontWeight: FontWeight.w500, fontSize: 8.0.sp);

  TextStyle get textPrimary6DemiBold =>
      TextStyle(color: textColor1, fontWeight: FontWeight.w600, fontSize: 8.0.sp);

  TextStyle get textPrimary6Bold =>
      TextStyle(color: textColor1, fontWeight: FontWeight.w800, fontSize: 8.0.sp);

  TextStyle get textPrimary5Regular =>
      TextStyle(color: textColor1, fontWeight: FontWeight.w200, fontSize: 10.0.sp);

  TextStyle get textPrimary5Medium =>
      TextStyle(color: textColor1, fontWeight: FontWeight.w500, fontSize: 10.0.sp);

  TextStyle get textPrimary5DemiBold =>
      TextStyle(color: textColor1, fontWeight: FontWeight.w600, fontSize: 10.0.sp);

  TextStyle get textPrimary5Bold =>
      TextStyle(color: textColor1, fontWeight: FontWeight.w800, fontSize: 10.0.sp);

  TextStyle get textPrimary4Regular =>
      TextStyle(color: textColor1, fontWeight: FontWeight.w200, fontSize: 12.0.sp);

  TextStyle get textPrimary4Medium =>
      TextStyle(color: textColor1, fontWeight: FontWeight.w500, fontSize: 12.0.sp);

  TextStyle get textPrimary4DemiBold =>
      TextStyle(color: textColor1, fontWeight: FontWeight.w600, fontSize: 12.0.sp);

  TextStyle get textPrimary4Bold =>
      TextStyle(color: textColor1, fontWeight: FontWeight.w800, fontSize: 12.0.sp);

  TextStyle get textPrimary3Regular =>
      TextStyle(color: textColor1, fontWeight: FontWeight.w200, fontSize: 14.0.sp);

  TextStyle get textPrimary3Medium =>
      TextStyle(color: textColor1, fontWeight: FontWeight.w500, fontSize: 14.0.sp);

  TextStyle get textPrimary3DemiBold =>
      TextStyle(color: textColor1, fontWeight: FontWeight.w700, fontSize: 14.0.sp);

  TextStyle get textPrimary3Bold =>
      TextStyle(color: textColor1, fontWeight: FontWeight.w800, fontSize: 14.0.sp);

  TextStyle get textPrimary2Regular =>
      TextStyle(color: textColor1, fontWeight: FontWeight.w200, fontSize: 16.0.sp);

  TextStyle get textPrimary2Medium =>
      TextStyle(color: textColor1, fontWeight: FontWeight.w500, fontSize: 16.0.sp);

  TextStyle get textPrimary2DemiBold =>
      TextStyle(color: textColor1, fontWeight: FontWeight.w700, fontSize: 16.0.sp);

  TextStyle get textPrimary2Bold =>
      TextStyle(color: textColor1, fontWeight: FontWeight.w800, fontSize: 16.0.sp);

  TextStyle get textPrimary1Regular =>
      TextStyle(color: textColor1, fontWeight: FontWeight.w200, fontSize: 18.0.sp);

  TextStyle get textPrimary1Medium =>
      TextStyle(color: textColor1, fontWeight: FontWeight.w500, fontSize: 18.0.sp);

  TextStyle get textPrimary1DemiBold =>
      TextStyle(color: textColor1, fontWeight: FontWeight.w700, fontSize: 18.0.sp);

  TextStyle get textPrimary1Bold =>
      TextStyle(color: textColor1, fontWeight: FontWeight.w800, fontSize: 18.0.sp);

  //</editor-fold>

  //<editor-fold desc="Text Secondary">
  TextStyle get textSecondary6Regular =>
      TextStyle(color: textColor2, fontWeight: FontWeight.w200, fontSize: 8.0.sp);

  TextStyle get textSecondary6Medium =>
      TextStyle(color: textColor2, fontWeight: FontWeight.w500, fontSize: 8.0.sp);

  TextStyle get textSecondary6DemiBold =>
      TextStyle(color: textColor2, fontWeight: FontWeight.w700, fontSize: 8.0.sp);

  TextStyle get textSecondary6Bold =>
      TextStyle(color: textColor2, fontWeight: FontWeight.w800, fontSize: 8.0.sp);

  TextStyle get textSecondary5Regular =>
      TextStyle(color: textColor2, fontWeight: FontWeight.w200, fontSize: 10.0.sp);

  TextStyle get textSecondary5Medium =>
      TextStyle(color: textColor2, fontWeight: FontWeight.w500, fontSize: 10.0.sp);

  TextStyle get textSecondary5DemiBold =>
      TextStyle(color: textColor2, fontWeight: FontWeight.w700, fontSize: 10.0.sp);

  TextStyle get textSecondary4Regular =>
      TextStyle(color: textColor2, fontWeight: FontWeight.w200, fontSize: 12.0.sp);

  TextStyle get textSecondary4Medium =>
      TextStyle(color: textColor2, fontWeight: FontWeight.w500, fontSize: 12.0.sp);

  TextStyle get textSecondary4DemiBold =>
      TextStyle(color: textColor2, fontWeight: FontWeight.w700, fontSize: 12.0.sp);

  TextStyle get textSecondary4Bold =>
      TextStyle(color: textColor2, fontWeight: FontWeight.w800, fontSize: 12.0.sp);

  TextStyle get textSecondary3Regular =>
      TextStyle(color: textColor2, fontWeight: FontWeight.w200, fontSize: 14.0.sp);

  TextStyle get textSecondary3Medium =>
      TextStyle(color: textColor2, fontWeight: FontWeight.w500, fontSize: 14.0.sp);

  TextStyle get textSecondary3DemiBold =>
      TextStyle(color: textColor2, fontWeight: FontWeight.w700, fontSize: 14.0.sp);

  TextStyle get textSecondary3Bold =>
      TextStyle(color: textColor2, fontWeight: FontWeight.w800, fontSize: 14.0.sp);

  TextStyle get textSecondary2Regular =>
      TextStyle(color: textColor2, fontWeight: FontWeight.w200, fontSize: 16.0.sp);

  TextStyle get textSecondary2Medium =>
      TextStyle(color: textColor2, fontWeight: FontWeight.w500, fontSize: 16.0.sp);

  TextStyle get textSecondary2DemiBold =>
      TextStyle(color: textColor2, fontWeight: FontWeight.w700, fontSize: 16.0.sp);

  TextStyle get textSecondary2Bold =>
      TextStyle(color: textColor2, fontWeight: FontWeight.w800, fontSize: 16.0.sp);

  TextStyle get textSecondary1Regular =>
      TextStyle(color: textColor2, fontWeight: FontWeight.w200, fontSize: 18.0.sp);

  TextStyle get textSecondary1Medium =>
      TextStyle(color: textColor2, fontWeight: FontWeight.w500, fontSize: 18.0.sp);

  TextStyle get textSecondary1DemiBold =>
      TextStyle(color: textColor2, fontWeight: FontWeight.w700, fontSize: 18.0.sp);

  TextStyle get textSecondary1Bold =>
      TextStyle(color: textColor2, fontWeight: FontWeight.w800, fontSize: 18.0.sp);

  //</editor-fold>

  //<editor-fold desc="Text Primary Color">
  TextStyle get textPrimaryColors6Regular =>
      TextStyle(color: primaryColor, fontWeight: FontWeight.w200, fontSize: 8.0.sp);

  TextStyle get textPrimaryColors6Medium =>
      TextStyle(color: primaryColor, fontWeight: FontWeight.w500, fontSize: 8.0.sp);

  TextStyle get textPrimaryColors6DemiBold =>
      TextStyle(color: primaryColor, fontWeight: FontWeight.w700, fontSize: 8.0.sp);

  TextStyle get textPrimaryColors6Bold =>
      TextStyle(color: primaryColor, fontWeight: FontWeight.w800, fontSize: 8.0.sp);

  TextStyle get textPrimaryColors5Regular =>
      TextStyle(color: primaryColor, fontWeight: FontWeight.w200, fontSize: 10.0.sp);

  TextStyle get textPrimaryColors5Medium =>
      TextStyle(color: primaryColor, fontWeight: FontWeight.w500, fontSize: 10.0.sp);

  TextStyle get textPrimaryColors5DemiBold =>
      TextStyle(color: primaryColor, fontWeight: FontWeight.w700, fontSize: 10.0.sp);

  TextStyle get textPrimaryColors5Bold =>
      TextStyle(color: primaryColor, fontWeight: FontWeight.w800, fontSize: 10.0.sp);

  TextStyle get textPrimaryColors4Regular =>
      TextStyle(color: primaryColor, fontWeight: FontWeight.w200, fontSize: 12.0.sp);

  TextStyle get textPrimaryColors4Medium =>
      TextStyle(color: primaryColor, fontWeight: FontWeight.w500, fontSize: 12.0.sp);

  TextStyle get textPrimaryColors4DemiBold =>
      TextStyle(color: primaryColor, fontWeight: FontWeight.w700, fontSize: 12.0.sp);

  TextStyle get textPrimaryColors4Bold =>
      TextStyle(color: primaryColor, fontWeight: FontWeight.w800, fontSize: 12.0.sp);

  TextStyle get textPrimaryColors3Regular =>
      TextStyle(color: primaryColor, fontWeight: FontWeight.w200, fontSize: 14.0.sp);

  TextStyle get textPrimaryColors3Medium =>
      TextStyle(color: primaryColor, fontWeight: FontWeight.w500, fontSize: 14.0.sp);

  TextStyle get textPrimaryColors3DemiBold =>
      TextStyle(color: primaryColor, fontWeight: FontWeight.w700, fontSize: 14.0.sp);

  TextStyle get textPrimaryColors3Bold =>
      TextStyle(color: primaryColor, fontWeight: FontWeight.w800, fontSize: 14.0.sp);

  TextStyle get textPrimaryColors2Regular =>
      TextStyle(color: primaryColor, fontWeight: FontWeight.w200, fontSize: 16.0.sp);

  TextStyle get textPrimaryColors2Medium =>
      TextStyle(color: primaryColor, fontWeight: FontWeight.w500, fontSize: 16.0.sp);

  TextStyle get textPrimaryColors2DemiBold =>
      TextStyle(color: primaryColor, fontWeight: FontWeight.w700, fontSize: 16.0.sp);

  TextStyle get textPrimaryColors2Bold =>
      TextStyle(color: primaryColor, fontWeight: FontWeight.w800, fontSize: 16.0.sp);

  TextStyle get textPrimaryColors1Regular =>
      TextStyle(color: primaryColor, fontWeight: FontWeight.w200, fontSize: 18.0.sp);

  TextStyle get textPrimaryColors1Medium =>
      TextStyle(color: primaryColor, fontWeight: FontWeight.w500, fontSize: 18.0.sp);

  TextStyle get textPrimaryColors1Bold =>
      TextStyle(color: primaryColor, fontWeight: FontWeight.w800, fontSize: 18.0.sp);

  TextStyle get textPrimaryColors1DemiBold =>
      TextStyle(color: primaryColor, fontWeight: FontWeight.w700, fontSize: 18.0.sp);

  //</editor-fold>

  //<editor-fold desc="Text White Color">
  TextStyle get textWhite6Regular =>
      TextStyle(color: white, fontWeight: FontWeight.w200, fontSize: 8.0.sp);

  TextStyle get textWhite6Medium =>
      TextStyle(color: white, fontWeight: FontWeight.w500, fontSize: 8.0.sp);

  TextStyle get textWhite6DemiBold =>
      TextStyle(color: white, fontWeight: FontWeight.w700, fontSize: 8.0.sp);

  TextStyle get textWhite6Bold =>
      TextStyle(color: white, fontWeight: FontWeight.w800, fontSize: 8.0.sp);

  TextStyle get textWhite5Regular =>
      TextStyle(color: white, fontWeight: FontWeight.w200, fontSize: 10.0.sp);

  TextStyle get textWhite5Medium =>
      TextStyle(color: white, fontWeight: FontWeight.w500, fontSize: 10.0.sp);

  TextStyle get textWhite5DemiBold =>
      TextStyle(color: white, fontWeight: FontWeight.w700, fontSize: 10.0.sp);

  TextStyle get textWhite5Bold =>
      TextStyle(color: white, fontWeight: FontWeight.w800, fontSize: 10.0.sp);

  TextStyle get textWhite4Regular =>
      TextStyle(color: white, fontWeight: FontWeight.w200, fontSize: 12.0.sp);

  TextStyle get textWhite4Medium =>
      TextStyle(color: white, fontWeight: FontWeight.w500, fontSize: 12.0.sp);

  TextStyle get textWhite4DemiBold =>
      TextStyle(color: white, fontWeight: FontWeight.w700, fontSize: 12.0.sp);

  TextStyle get textWhite4Bold =>
      TextStyle(color: white, fontWeight: FontWeight.w800, fontSize: 12.0.sp);

  TextStyle get textWhite3Regular =>
      TextStyle(color: white, fontWeight: FontWeight.w200, fontSize: 14.0.sp);

  TextStyle get textWhite3Medium =>
      TextStyle(color: white, fontWeight: FontWeight.w500, fontSize: 14.0.sp);

  TextStyle get textWhite3DemiBold =>
      TextStyle(color: white, fontWeight: FontWeight.w700, fontSize: 14.0.sp);

  TextStyle get textWhite3Bold =>
      TextStyle(color: white, fontWeight: FontWeight.w800, fontSize: 14.0.sp);

  TextStyle get textWhite2Regular =>
      TextStyle(color: white, fontWeight: FontWeight.w200, fontSize: 16.0.sp);

  TextStyle get textWhite2Medium =>
      TextStyle(color: white, fontWeight: FontWeight.w500, fontSize: 16.0.sp);

  TextStyle get textWhite2DemiBold =>
      TextStyle(color: white, fontWeight: FontWeight.w700, fontSize: 16.0.sp);

  TextStyle get textWhite2Bold =>
      TextStyle(color: white, fontWeight: FontWeight.w800, fontSize: 16.0.sp);

  TextStyle get textWhite1Regular =>
      TextStyle(color: white, fontWeight: FontWeight.w200, fontSize: 18.0.sp);

  TextStyle get textWhite1Medium =>
      TextStyle(color: white, fontWeight: FontWeight.w500, fontSize: 18.0.sp);

  TextStyle get textWhite1DemiBold =>
      TextStyle(color: white, fontWeight: FontWeight.w700, fontSize: 18.0.sp);

  TextStyle get textWhite1Bold =>
      TextStyle(color: white, fontWeight: FontWeight.w800, fontSize: 18.0.sp);

//</editor-fold>

  SystemUiOverlayStyle get systemUiOverlayStyle => SystemUiOverlayStyle(
        systemNavigationBarColor: backgroundColor,
        statusBarColor: backgroundColor,
        systemNavigationBarIconBrightness: isDarkMode() ? Brightness.light : Brightness.dark,
        statusBarIconBrightness: isDarkMode() ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDarkMode() ? Brightness.dark : Brightness.light,
      );

  isDarkMode() {
    return false;
  }

  CardTheme cardThemeLight() {
    return CardTheme(elevation: 4.0, color: AppTheme().cardBackground, shape: borderStyle);
  }

  SmoothRectangleBorder borderStyle = SmoothRectangleBorder(
      borderRadius: SmoothBorderRadius(
    cornerRadius: 20.0,
    cornerSmoothing: 1,
  ));

  CardTheme cardThemeDark() {
    return CardTheme(
        elevation: 4.0,
        color: AppTheme().cardBackground,
        shape: SmoothRectangleBorder(
            borderRadius: SmoothBorderRadius(
          cornerRadius: 10.0, //todo add .dp to these values
          cornerSmoothing: 1,
        )));
  }

/* GSFormStyle get formStyle => GSFormStyle(
      backgroundFieldColor: cardBackground,
      backgroundSectionColor: backgroundColor,
      sectionCardElevation: 0,
      titleStyle: textSecondary4Regular,
      fieldHintStyle: textSecondary5Medium,
      fieldTextStyle: textPrimary4Medium,
      sectionRadius: 0.0.sp,
      sectionCardPadding: 0.0.sp,
      errorTextStyle: TextStyle(fontSize: 10, color: AppTheme().red),
      requiredText: '*');*/
}

class _AppColors {
  static const primaryColor = Color(0xffffffff);

  static const secondaryColor = Color(0xd2464646);

  static const green = Color(0xff6CD38B);

  static const red = Color(0xffF25B73);

  static const blue = Color(0xff0092E4);

  static const blueOpacity = Color(0x262457e4);

  static const rectangleColorGreen = Color(0x336cd38b);

  static const rectangleColorRed = Color(0x33EF5350);

  static const amber = Color(0xffFCC048);

  static const white = Color(0xffffffff);

  static const black = Color(0xff000000);

  static const backgroundLight = Color(0xFFF4F4F4);

  static const textColor1Light = Color(0xff292D32);

  static const textColor2Light = Color(0xff999999);

  static const cardBackgroundLight = Color(0xFFFFFFFF);

  static const cardBackgroundDark = Color(0xff39393B);

  static const dividerLight = Color(0xffEAEAEA);

  static const backgroundDark = Color(0xff1B1B1B);

  static const textColor1Dark = Color(0xffFFFFFF);

  static const textColor2Dark = Color(0xffCCCCCC);

  static const dividerDark = Color(0xff565656);

  static const iconColorLight = Color(0xff262626);

  static const iconColorDark = Color(0xffFFFFFF);
}
