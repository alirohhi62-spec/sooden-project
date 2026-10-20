import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:bms/core/utils/extension.dart';
import 'package:bms/core/values/theme.dart';
import 'package:bms/data/data_sources/local_data_sources/database/model/device.dart';
import 'package:bms/data/data_sources/local_data_sources/database/model/place.dart';
import 'package:bms/presentation/components/appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../../data/enums/device_code.dart';
import '../../../../../data/enums/floor_code.dart';
import '../../../../components/user_name_sheet.dart';
import '../../../../logic/place_temperature_logic.dart';

class PlaceTemperatureScreen extends StatefulWidget {
  late PlaceTemperatureLogic logic;
  late FloorCode floor;
  late Place place;

  PlaceTemperatureScreen({super.key, required this.floor, required this.place});

  @override
  State<StatefulWidget> createState() => _PlaceTemperatureScreenState();
}

class _PlaceTemperatureScreenState extends State<PlaceTemperatureScreen> {
  double shapePointerValue = 25;

  int currentValue = 0;

  @override
  void initState() {
    widget.logic = Get.put(
        PlaceTemperatureLogic(floor: widget.floor, place: widget.place));

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PlaceTemperatureLogic>(
      assignId: true,
      builder: (logic) {
        return Scaffold(
          appBar: appBar(widget.logic.title),
          body: Padding(
            padding: EdgeInsets.all(16.0.dp),
            child: ListView.builder(
              itemCount: widget.logic.devices.length,
              itemBuilder: (ctx, index) => _item(widget.logic.devices[index]),
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
          showEditNameSheet(device.getName(),
              (newName) => widget.logic.renameDevice(device, newName));
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
                        width: 36.0.dp,
                        height: 36.0.dp,
                      )
                    ],
                  )),
                  AnimatedToggleSwitch<int>.rolling(
                    current: currentValue,
                    values: const [-1, 0, 1],
                    borderWidth: 1,
                    iconsTappable: true,
                    iconList: [
                      SvgPicture.asset(
                        'assets/icons/sun.svg',
                        width: 20,
                        height: 20,
                      ),
                      SvgPicture.asset(
                        'assets/icons/power.svg',
                        width: 20,
                        height: 20,
                      ),
                      SvgPicture.asset(
                        'assets/icons/snow.svg',
                        width: 20,
                        height: 20,
                      ),
                    ],
                    styleBuilder: (value) {
                      if (value == -1) {
                        return const ToggleStyle(indicatorColor: Colors.red);
                      }

                      if (value == 1) {
                        return const ToggleStyle(indicatorColor: Colors.blue);
                      }

                      return const ToggleStyle(indicatorColor: Colors.grey);
                    },
                    onChanged: (value) {
                      setState(() => currentValue = value);
                    },
                  ),
                ],
              ),
              SizedBox(
                height: 48.0.dp,
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      device.getName(),
                      style: AppTheme().textPrimary2Medium,
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {},
                        style: ButtonStyle(
                          shape: MaterialStateProperty.all(const CircleBorder()),
                          padding:
                              MaterialStateProperty.all(EdgeInsets.all(4.0.dp)),
                          backgroundColor: MaterialStateProperty.all(
                              AppTheme().backgroundColor),
                          overlayColor:
                              MaterialStateProperty.resolveWith<Color?>(
                                  (states) {
                            if (states.contains(MaterialState.pressed)) {
                              return AppTheme()
                                  .primaryColor;
                            return null; // <-- Splash color
                            }
                            return null;
                          }),
                        ),
                        child: Icon(
                          Iconsax.add,
                          color: AppTheme().secondaryColor,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsetsDirectional.only(
                            start: 4.0.dp, end: 4.0.dp),
                        child: Text(
                          '25°',
                          style: AppTheme().textPrimary3Bold,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {},
                        style: ButtonStyle(
                          shape: MaterialStateProperty.all(const CircleBorder()),
                          padding:
                              MaterialStateProperty.all(EdgeInsets.all(4.0.dp)),
                          backgroundColor: MaterialStateProperty.all(
                              AppTheme().backgroundColor),
                          overlayColor:
                              MaterialStateProperty.resolveWith<Color?>(
                                  (states) {
                            if (states.contains(MaterialState.pressed)) {
                              return AppTheme()
                                  .primaryColor;
                            return null; // <-- Splash color
                            }
                            return null;
                          }),
                        ),
                        child: Icon(
                          Iconsax.minus,
                          color: AppTheme().secondaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
