import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:bms/core/utils/communication_constants.dart';
import 'package:bms/core/utils/extension.dart';
import 'package:bms/core/values/theme.dart';
import 'package:bms/data/data_sources/local_data_sources/database/model/device.dart';
import 'package:bms/data/data_sources/local_data_sources/database/model/place.dart';
import 'package:bms/presentation/components/appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../../../../core/values/colors.dart';
import '../../../../../data/enums/device_code.dart';
import '../../../../../data/enums/floor_code.dart';
import '../../../../components/user_name_sheet.dart';
import '../../../../logic/place_curtain_logic.dart';

class PlaceCurtainScreen extends StatefulWidget {
  late PlaceCurtainLogic logic;
  late FloorCode floor;
  late Place place;

  PlaceCurtainScreen({super.key, required this.floor, required this.place});

  @override
  State<StatefulWidget> createState() => _PlaceCurtainScreenState();
}

class _PlaceCurtainScreenState extends State<PlaceCurtainScreen> {
  double shapePointerValue = 25;

  @override
  void initState() {
    widget.logic = Get.put(PlaceCurtainLogic(floor: widget.floor, place: widget.place));

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PlaceCurtainLogic>(
      assignId: true,
      builder: (logic) {
        return Scaffold(
          appBar: appBar(logic.title),
          body: Padding(
            padding: EdgeInsets.all(16.0.dp),
            child: ListView.builder(
                itemCount: logic.devices.length, itemBuilder: (ctx, index) => _item(logic.devices[index])),
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
        child: Padding(
          padding: EdgeInsets.all(20.0.dp),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SvgPicture.asset(
                    DeviceCode.get(device.code!).icon!,
                    width: 36.0.dp,
                    height: 36.0.dp,
                  ),
                  const Spacer(), // This pushes the icon to the right
                  Expanded(
                    child: Text(
                      '${((9 - int.parse(device.secondValue ?? "0") ) / 9 * 100).toInt()}% باز', // Reversed percentage calculation
                      style: AppTheme().textPrimary2Medium,
                    ),
                  )
                  ,
                ],
              )
              ,
              SizedBox(
                height: 30.0.dp,
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      device.getName(),
                      style: AppTheme().textPrimary2Medium,
                    ),
                  ),
                  animatedToggleSwitch(device),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  AnimatedToggleSwitch<String> animatedToggleSwitch(Device device) {
    return AnimatedToggleSwitch<String>.rolling(
      current: widget.logic.getValue(device),
      values: const [SocketConstants.curtainClose, SocketConstants.curtainStop, SocketConstants.curtainOpen],
      borderWidth: 1,
      iconsTappable: true,
      iconList: [
        SvgPicture.asset('assets/icons/arrow-right.svg',
            width: 20,
            height: 20,
            color: widget.logic.getValue(device) == SocketConstants.curtainClose
                ? AppColors.shuttersIconsInactiveColor
                : AppColors.shuttersIconsActiveColor),
        SvgPicture.asset(
          'assets/icons/pause.svg',
          width: 20,
          height: 20,
        ),
        SvgPicture.asset('assets/icons/arrow-left.svg',
            width: 20,
            height: 20,
            color: widget.logic.getValue(device) == SocketConstants.curtainOpen
                ? AppColors.shuttersIconsInactiveColor
                : AppColors.shuttersIconsActiveColor),
      ],
      styleBuilder: (value) {
        if (value == 0) {
          return const ToggleStyle(indicatorColor: AppColors.inactiveColor);
        } else {
          return const ToggleStyle(indicatorColor: AppColors.shuttersColor);
        }
      },
      onChanged: (value) {
        widget.logic.changeDeviceValue(device, value);
        // setState(() => currentValue = value);
      },
    );
  }
}
