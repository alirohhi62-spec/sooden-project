import 'package:bms/core/utils/extension.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import '../../../core/di/app_binding.dart';
import '../../../core/utils/globals.dart';
import '../../../data/enums/connection_error_code.dart';
import '../../components/primary_button.dart';
import '../../../core/values/theme.dart';
import '../../logic/not_found_logic.dart';
import '../logger/logger_screen.dart';
import '../../../panel12/panel12_screen.dart';
import '../tabs/settings/pages/locations_screen.dart';

class NotFoundScreen extends StatefulWidget {
  late ConnectionErrorCode _mErrorCode;

  NotFoundScreen({super.key, required ConnectionErrorCode errorCode}) {
    _mErrorCode = errorCode;
  }

  @override
  State<StatefulWidget> createState() => _NotFoundScreenState();
}

class _NotFoundScreenState extends State<NotFoundScreen> {
  late NotFoundLogic logic;

  @override
  void initState() {
    logic = Get.put(NotFoundLogic());

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<NotFoundLogic>(
      assignId: true,
      builder: (logic) {
        return Scaffold(
          appBar: buildAppBar(),
          body: buildBody(logic),
        );
      },
    );
  }

  AppBar buildAppBar() {
    return AppBar(toolbarHeight: 30, actions: _appBarActions());
  }

  List<Widget> _appBarActions() {
    return <Widget>[
      IconButton(
        icon: const Icon(Icons.slideshow_outlined),
        tooltip: 'حالت نمایشی',
        onPressed: Panel12DemoPage.open,
      ),
      isLoggerEnable
          ? IconButton(
              icon: const Icon(Icons.history),
              onPressed: () {
                Get.to(() => LoggerScreen());
              },
            )
          : Container(),
    ];
  }

  Column buildBody(NotFoundLogic logic) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      mainAxisSize: MainAxisSize.max,
      children: [
        Lottie.asset('assets/lottie/not_found.json', repeat: true, height: 100.0.dp),
        Padding(
          padding: const EdgeInsets.only(right: 30, left: 30),
          // نگه داشتن طولانی: حالت نمایشی پنل (با رمز نصاب)
          child: GestureDetector(
            onLongPress: Panel12DemoPage.open,
            child: Text('error_not_found_device'.tr,
                textAlign: TextAlign.center, style: AppTheme().textPrimary2Regular),
          ),
        ),  Padding(
          padding: const EdgeInsets.only(right: 16, left: 16,top: 20),
          child: Text('Error \n ${widget._mErrorCode.value}',
              textAlign: TextAlign.center, style: AppTheme().textPrimary4Medium),
        ),
        Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            mainAxisSize: MainAxisSize.max,
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: PrimaryButton(
                    text: 'try_again'.tr,
                    onTap: () {
                      logic.onTryAgain();
                    }),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: PrimaryButton(
                    text: 'locations'.tr,
                    onTap: () {
                      goToLocationScreens();
                    }),
              )
            ])
      ],
    );
  }
  Future<dynamic>? goToLocationScreens() =>  Get.to(() => const LocationsScreen(), binding: AppBindings());

}
