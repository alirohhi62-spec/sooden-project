import 'package:bms/core/utils/extension.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import '../../../core/utils/globals.dart';
import '../../components/primary_button.dart';
import '../../../core/values/theme.dart';
import '../../logic/error_gps_logic.dart';
import '../logger/logger_screen.dart';

class ErrorGpsScreen extends StatefulWidget {
  const ErrorGpsScreen({super.key});

  @override
  State<StatefulWidget> createState() => _ErrorGpsScreenState();
}

class _ErrorGpsScreenState extends State<ErrorGpsScreen> {
  late ErrorGpsLogic logic;

  @override
  void initState() {
    logic = Get.put(ErrorGpsLogic());

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ErrorGpsLogic>(
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

  Column buildBody(ErrorGpsLogic logic) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      mainAxisSize: MainAxisSize.max,
      children: [
        Lottie.asset('assets/lottie/not_found.json', repeat: true, height: 100.0.dp),
        Padding(
          padding: const EdgeInsets.only(right: 30, left: 30),
          child: Text('error_gps'.tr,
              textAlign: TextAlign.center, style: AppTheme().textPrimary2Regular),
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
                    text: 'open_gps'.tr,
                    onTap: () {
                      logic.openGps();
                    }),
              )
            ])
      ],
    );
  }
}
