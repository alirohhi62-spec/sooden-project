import 'package:bms/core/utils/constants.dart';
import 'package:bms/core/utils/util.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../panel12/sooden_splash_logo.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/utils/globals.dart';
import '../../components/user_name_sheet.dart';
import '../../widgets/first_run_note.dart';
import '../../logic/splash_logic.dart';

class SplashScreen extends StatelessWidget {
  late SplashLogic logic;

  SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    logic = Get.put(SplashLogic());

    _checkLocationPermission();

    return GetBuilder<SplashLogic>(
      assignId: true,
      builder: (logic) {
        // موشن لوگوی سودن روی مشکی؛ همزمان اتصال به پنل شروع شده است
        return const Scaffold(
          backgroundColor: Colors.black,
          body: Stack(children: [
            Center(child: SoodenSplashLogo()),
            Positioned(
              left: 0,
              right: 0,
              bottom: 56,
              child: Text('در حال اتصال به پنل…',
                  textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF5E5E63), fontSize: 12)),
            ),
          ]),
        );
      },
    );
  }

  _checkLocationPermission() async {
    await FirstRunNote.showOnce();                 // بار اول: اندروید لازم، اجازه‌ی موقعیت، وای‌فای پنل
    var permissionStatus = await Permission.locationWhenInUse.status;

    if (permissionStatus.isGranted) {
      _checkGetUsername();
    } else {
      _requestPermissions();
    }
  }

  _checkGetUsername() {
    enableGPS();
    Future.delayed(const Duration(milliseconds: Constants.splashScreenDelay), () {
      if (logic.isUserNameEmpty()) {
        showDialogUserName();
      } else {
        logic.goNextScreen();
      }
    });
  }

  void showDialogUserName() {
    showChangeUsernameSheet(callback: (userName) {
      if (!isUserNameValid(userName)) return;

      Navigator.pop(Get.context!);
      logic.storeUserName(userName);
      logic.goNextScreen();
      return;
    });
  }

  isUserNameValid(String userName) {
    if (userName.isEmpty) {
      Navigator.pop(Get.context!);
      Get.snackbar('خطا', 'باید نام را وارد کنید');
      return false;
    }
    return true;
  }

  _requestPermissions() async {
    await Permission.locationWhenInUse.onDeniedCallback(() {
      Get.snackbar('خطا', 'مجوزها اجباری است');
    }).onGrantedCallback(() {
      _checkGetUsername();
    }).request();
  }

  void _logger(String key, String value) {
    doLogGlobal('splash_screen.dart. H:$hashCode', key, value);
  }
}
