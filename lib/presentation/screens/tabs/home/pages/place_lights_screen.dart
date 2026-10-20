import 'package:bms/core/utils/extension.dart';
import 'package:bms/core/values/theme.dart';
import 'package:bms/data/data_sources/local_data_sources/database/model/device.dart';
import 'package:bms/data/data_sources/local_data_sources/database/model/place.dart';
import 'package:bms/presentation/components/appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:get/get.dart';

import '../../../../../data/enums/device_code.dart';
import '../../../../../data/enums/floor_code.dart';
import '../../../../components/user_name_sheet.dart';
import '../../../../logic/place_lights_logic.dart';

class PlaceLightsScreen extends StatefulWidget {
  late PlaceLightsLogic logic;
  late FloorCode floor;
  late Place place;

  PlaceLightsScreen({super.key, required this.floor, required this.place});

  @override
  State<StatefulWidget> createState() => _PlaceLightsScreenState();
}

class _PlaceLightsScreenState extends State<PlaceLightsScreen> {
  @override
  void initState() {
    widget.logic = Get.put(PlaceLightsLogic(floor: widget.floor, place: widget.place));

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PlaceLightsLogic>(
      assignId: true,
      builder: (logic) {
        return Scaffold(
          appBar: appBar(logic.title),
          body: Padding(
            padding: EdgeInsets.all(16.0.dp),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 150.0.dp,
                    crossAxisSpacing: 8.0.dp,
                    mainAxisSpacing: 8.0.dp,
                    childAspectRatio: 1.5,
                  ),
                  itemCount: logic.devices.length,
                  itemBuilder: (ctx, index) => _item(logic.devices[index])),
            ),
          ),
        );
      },
    );
  }

  _item(Device device) {
    return Card(
      elevation: 0,
      color: AppTheme().cardBackground,
      shape: AppTheme().borderStyle,
      child: InkWell(
        onLongPress: () {
          showEditNameSheet(device.getName(), (newName) => widget.logic.renameDevice(device, newName));
        },
        onTap: () {
          widget.logic.changeLightDevicesValue(device);
        },
        child: Padding(
          padding: EdgeInsets.all(8.0.dp),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                      child: Row(
                    children: [
                      SvgPicture.asset(
                        DeviceCode.get(device.code!).icon!,
                        width: 24.0.dp,
                        height: 24.0.dp,
                        color: (device.value ?? '') == '1' ? const Color(0xffFCAE39) : AppTheme().secondaryColor,
                      ),
                    ],
                  )),
                  FlutterSwitch(
                      value: (device.value ?? '') == '1' ? true : false,
                      height: 24.0.dp,
                      width: 48.0.dp,
                      activeColor: AppTheme().secondaryColor,
                      onToggle: (newState) => widget.logic.changeLightDevicesValue(device)),
                ],
              ),
              SizedBox(
                height: 24.0.dp,
              ),
              Text(
                device.getName(),
                style: AppTheme().textPrimary2Medium,
              )
            ],
          ),
        ),
      ),
    );
  }
}
