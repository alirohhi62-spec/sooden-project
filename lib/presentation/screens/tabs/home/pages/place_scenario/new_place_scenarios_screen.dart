import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:bms/core/utils/extension.dart';
import 'package:bms/core/values/theme.dart';
import 'package:bms/data/data_sources/local_data_sources/database/model/device.dart';
import 'package:bms/data/data_sources/local_data_sources/database/model/place.dart';
import 'package:bms/data/enums/place_code.dart';
import 'package:bms/presentation/components/appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../../../core/utils/communication_constants.dart';
import '../../../../../../core/values/colors.dart';
import '../../../../../../data/enums/floor_code.dart';
import '../../../../../components/rita_text_field.dart';
import '../../../../../logic/new_place_scenarios_logic.dart';

class NewPlaceScenariosScreen extends StatefulWidget {
  late NewPlaceScenariosLogic logic;
  late Place place;
  late FloorCode floor;
  late int currentLocationId;

  NewPlaceScenariosScreen(this.place, this.floor, this.currentLocationId, {super.key});

  @override
  State<StatefulWidget> createState() => _NewPlaceScenariosScreenState();
}

class _NewPlaceScenariosScreenState extends State<NewPlaceScenariosScreen> {
  @override
  void initState() {
    widget.logic = Get.put(NewPlaceScenariosLogic(
        place: widget.place, floor: widget.floor, currentLocationId: widget.currentLocationId));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<NewPlaceScenariosLogic>(builder: (logic) {
      return Scaffold(
        appBar: buildAppBar(),
        body: buildContent(logic),
      );
    });
  }

  Widget buildContent(NewPlaceScenariosLogic logic) {
    return Column(children: [
      Expanded(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsetsDirectional.only(start: 16.0.dp, end: 16.0.dp, top: 8.0.dp),
            child: Column(children: [
              Card(
                color: AppTheme().cardBackground,

                elevation: 0,
                child: Padding(
                  padding: EdgeInsets.all(12.0.dp),
                  child: Column(
                    children: [
                      RitaTextField(
                        controller: logic.scenarioNameController,
                        hint: 'scenario_name'.tr,
                      ),
                      SizedBox(height: 10.0.dp),
                      buildFloorScenario(logic)
                    ],
                  ),
                ),
              ),
              SizedBox(height: 10.0.dp),
              Row(
                children: [
                  const Icon(Iconsax.lamp_1),
                  SizedBox(width: 8.0.dp),
                  Text(
                    'light'.tr,
                    style: AppTheme().textPrimary3Medium,
                  ),
                ],
              ),
              SizedBox(height: 4.0.dp),
              Card(
                elevation: 0,
                color: AppTheme().cardBackground,
                child: Padding(
                  padding: const EdgeInsets.only(right: 4.0, left: 4.0, top: 8.0, bottom: 8.0),
                  child: ListView.builder(
                    itemCount: widget.logic.devices.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (ctx, index) {
                      return manageBuildLightItem(index);
                    },
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    ]);
  }

  manageBuildLightItem(int index) {
    final device = widget.logic.devices[index];

    // If device code is 'z', do not build the item
    if (widget.logic.isHiddenLight(device)) {
      return Container();
    }
    // Check if the current device's place is different from the previous device's place
    else if (index == 0 || device.place != widget.logic.devices[index - 1].place) {
      // Display the place name as a header
      return manageBuildHeaderAndRegularItem(device, index);
    } else {
      // Render the regular item without a header
      return manageBuildItem(device, index);
    }
  }

  manageBuildHeaderAndRegularItem(Device device, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(16.0.dp),
          child: Text(
            PlaceCode.get(device.place!).title!,
            style: AppTheme().textPrimary2Bold,
          ),
        ),
        manageBuildItem(device, index), // Render the regular item
      ],
    );
  }

  manageBuildItem(Device device, int index) {
    if (widget.logic.isLight(device)) {
      return _itemLight(index);
    } else {
      return _itemCurtain(index);
    }
  }

  InkWell buildFloorScenario(NewPlaceScenariosLogic logic) {
    return InkWell(
      onTap: () {
        logic.onScenarioForFloorChanged(!logic.isScenarioForFloor.value);
      },
      child: Obx(() {
        return buildSwitchRow("سناریو طبقه", logic.isScenarioForFloor.value, (toggleValue) {
          logic.onScenarioForFloorChanged(toggleValue);
        }); // Display the value of lastName
      }),
    );
  }

  AppBar buildAppBar() {
    return appBar('create_scenario'.tr, actions: <Widget>[
      IconButton(
        icon: const Icon(Icons.save),
        onPressed: () {
          widget.logic.createScenario();
        },
      ),
    ]);
  }

  _itemLight(int index) {
    Device device = widget.logic.devices[index];
    return InkWell(
      onTap: () {
        widget.logic.changeValue(index, device.value == 'true' ? 'false' : 'true');
      },
      child: Padding(
        padding:
            EdgeInsetsDirectional.only(start: 12.0.dp, end: 12.0.dp, top: 4.0.dp, bottom: 4.0.dp),
        child: buildSwitchRow(device.getName(), device.value == 'true', (valueToggle) {
          widget.logic.changeValue(index, valueToggle ? 'true' : 'false');
        }),
      ),
    );
  }

  Row buildSwitchRow(String title, bool value, void Function(bool) onToggle) {
    return Row(
      children: [
        Expanded(
            child: Text(
          title ?? '',
          style: AppTheme().textPrimary2Medium,
        )),
        FlutterSwitch(
          value: value,
          activeColor: AppTheme().secondaryColor,
          height: 25.0.dp,
          width: 50.0.dp,
          onToggle: (bool value) {
            onToggle(value);
          },
        ),
      ],
    );
  }

  _itemCurtain(int index) {
    Device device = widget.logic.devices[index];
    return Padding(
      padding:
          EdgeInsetsDirectional.only(start: 12.0.dp, end: 12.0.dp, top: 6.0.dp, bottom: 6.0.dp),
      child: buildToggleRow(device, index),
    );
  }

  Row buildToggleRow(Device device, int index) {
    return Row(
      children: [
        Expanded(
            child: Text(
          device.getName() ?? '',
          style: AppTheme().textPrimary2Medium,
        )),
        animatedToggleSwitch(device, index),
      ],
    );
  }

  AnimatedToggleSwitch<String> animatedToggleSwitch(Device device, int index) {
    return AnimatedToggleSwitch<String>.rolling(
      current: widget.logic.getValueCurtain(device),
      values: const [
        SocketConstants.curtainClose,
        SocketConstants.curtainStop,
        SocketConstants.curtainOpen
      ],
      borderWidth: 1,
      iconsTappable: true,
      iconList: [
        SvgPicture.asset('assets/icons/arrow-right.svg',
            width: 20,
            height: 20,
            color: widget.logic.getValueCurtain(device) == SocketConstants.curtainClose
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
            color: widget.logic.getValueCurtain(device) == SocketConstants.curtainOpen
                ? AppColors.shuttersIconsInactiveColor
                : AppColors.shuttersIconsActiveColor),
      ],
      styleBuilder: (value) {
        if (0 == value) {
          return const ToggleStyle(indicatorColor: AppColors.inactiveColor);
        } else {
          return const ToggleStyle(indicatorColor: AppColors.shuttersColor);
        }
      },
      onChanged: (value) {
        widget.logic.changeValue(index, value);
      },
    );
  }
}
