import 'package:bms/core/utils/communication_constants.dart';
import 'package:bms/core/utils/extension.dart';
import 'package:bms/core/values/theme.dart';
import 'package:bms/presentation/components/appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../../data/data_sources/local_data_sources/database/model/device.dart';
import '../../../logic/security_logic.dart';

class SecurityScreen extends StatefulWidget {
  late SecurityLogic logic;

  SecurityScreen({super.key});

  @override
  State<StatefulWidget> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  @override
  void initState() {
    widget.logic = Get.put(SecurityLogic());

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SecurityLogic>(
        assignId: true,
        builder: (logic) {
          return Scaffold(
            appBar: appBar('security'.tr),
            body: Padding(
              padding: EdgeInsets.all(16.0.dp),
              child: Column(
                children: [_buildCameraCard(), _buildBurglarAlarmCard()],
              ),
            ),
          );
        });
  }

  Card _buildCameraCard() {
    return Card(
      color: AppTheme().cardBackground,
      shape: AppTheme().borderStyle,
      elevation: 0,
      child: InkWell(
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        onTap: () {},
        child: Padding(
          padding: EdgeInsets.all(12.0.dp),
          child: Row(
            children: [
              Expanded(
                  child: Text(
                    'مشاهده دوربین ها',
                    style: AppTheme().textPrimary2Bold,
                  )),
              SvgPicture.asset(
                'assets/icons/cctv-camera.svg',
                width: 80.0.dp,
                height: 80.0.dp,
                color: AppTheme().divider,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Card _buildBurglarAlarmCard() {
    return Card(
      color: AppTheme().cardBackground,
      shape: AppTheme().borderStyle,
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(12.0.dp),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                    child: Text(
                      'دزدگیر ها ',
                      style: AppTheme().textPrimary2Bold,
                    )),
                SvgPicture.asset(
                  'assets/icons/burglar-alarm.svg',
                  width: 60.0.dp,
                  height: 60.0.dp,
                  color: AppTheme().divider,
                ),
              ],
            ),
            VisibilityDetector(
                key: const Key("unique key"),
                onVisibilityChanged: (VisibilityInfo info) {
                  if(info.visibleFraction==1){
                    widget.logic.requestBurglarAlarmStatus();
                  }
                },
                child: _widgetToTrack()),
          ],
        ),
      ),
    );
  }

  _widgetToTrack() {
   return SizedBox(
      height: 300, // Add this
      child: GridView.count(
        crossAxisCount: 3,
        children: List.generate(widget.logic.zoneList.length, (index) {
          return _buildBurglarAlarmItems(widget.logic.zoneList[index]);
        }),
      ),
    );
  }

  Center _buildBurglarAlarmItems(Device device) {
    return Center(
        child: TextButton(
          onPressed: () {
            widget.logic.changeDeviceValue(device);
          },
          style: TextButton.styleFrom(
            backgroundColor:
            (device.value ?? '') == SocketConstants.burglarAlarmIsOn ? const Color(0xd85dc27f) : AppTheme().secondaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
          child: Text(device.code.toString(), style: AppTheme().textSecondary1Bold),
        ));
  }
}
