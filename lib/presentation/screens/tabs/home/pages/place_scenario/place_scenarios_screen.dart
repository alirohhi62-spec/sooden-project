import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:bms/core/utils/extension.dart';
import 'package:bms/core/values/theme.dart';
import 'package:bms/data/data_sources/local_data_sources/database/model/place.dart';
import 'package:bms/data/data_sources/local_data_sources/database/model/scenario.dart';
import 'package:bms/data/data_sources/local_data_sources/database/model/scenario_det.dart';
import 'package:bms/data/enums/floor_code.dart';
import 'package:bms/presentation/components/appbar.dart';
import 'package:bms/presentation/screens/logger/logger_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../../../core/utils/communication_constants.dart';
import '../../../../../../core/values/colors.dart';
import '../../../../../components/user_name_sheet.dart';
import '../../../../../logic/place_scenarios_logic.dart';
import 'new_place_scenarios_screen.dart';

class PlaceScenariosScreen extends StatefulWidget {
  late PlaceScenariosLogic logic;
  late Place place;
  late FloorCode floor;
  late int currentLocationId;

  PlaceScenariosScreen(this.place, this.floor, this.currentLocationId, {super.key});

  @override
  State<StatefulWidget> createState() => _PlaceScenariosScreenState();
}

class _PlaceScenariosScreenState extends State<PlaceScenariosScreen> {
  @override
  void initState() {
    widget.logic = Get.put(PlaceScenariosLogic(
        place: widget.place, floor: widget.floor, currentLocationId: widget.currentLocationId));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PlaceScenariosLogic>(builder: (logic) {
      return Scaffold(
        appBar: buildAppBar(logic),
        body: buildContent(logic),
        floatingActionButton: buildFab(),
      );
    });
  }

  AppBar buildAppBar(PlaceScenariosLogic logic) {
    return appBar('${'manage_scenarios'.tr} ${logic.place.getName()} ${logic.floor.title}',
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Get.to(() => LoggerScreen());
            },
          )
        ]);
  }

  Column buildContent(PlaceScenariosLogic logic) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsetsDirectional.only(start: 16.0.dp, end: 16.0.dp, top: 16.0.dp),
          child: SizedBox(
            height: 45.0.dp,
            child: ListView.builder(
                itemCount: logic.scenarios.length,
                scrollDirection: Axis.horizontal,
                itemBuilder: (ctx, index) => _itemScenario(logic.scenarios[index])),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsetsDirectional.only(start: 16.0.dp, end: 16.0.dp, top: 8.0.dp),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Iconsax.lamp_1),
                      SizedBox(width: 8.0.dp),
                      Text(
                        'light'.tr,
                        style: AppTheme().textPrimary3Medium,
                      ),
                      const Spacer(),
                      PopupMenuButton(
                        itemBuilder: (context) {
                          return buildPopupMenuItem(logic);
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 4.0.dp),
                  Card(
                    elevation: 0,
                    color: AppTheme().cardBackground,
                    child: Padding(
                      padding:
                          const EdgeInsets.only(right: 4.0, left: 4.0, top: 16.0, bottom: 16.0),
                      child: ListView.builder(
                          itemCount: widget.logic.devicesInScenario.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (ctx, index) => buildItem(index)),
                    ),
                  ),
                  SizedBox(height: 80.0.dp),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<PopupMenuItem<String>> buildPopupMenuItem(PlaceScenariosLogic logic) {
    return [
      PopupMenuItem(
        value: 'edit',
        child: Text('edit'.tr),
        onTap: () {
          onMenuEditClicked(logic);
        },
      ),
      PopupMenuItem(
        value: 'delete',
        child: Text('delete'.tr),
        onTap: () {
          onMenuDeleteClicked(logic);
        },
      ),
    ];
  }

  buildItem(int index) {
    // If device code is 'z', do not build the item
    if (widget.logic.isHiddenLight(index)) {
      return Container();
    } else if (widget.logic.isLight(index)) {
      return _itemLight(widget.logic.devicesInScenario[index]);
    } else {
      return _itemCurtain(widget.logic.devicesInScenario[index]);
    }
  }

  void onMenuDeleteClicked(PlaceScenariosLogic logic) {
    logic.removeScenario(logic.currentScenario);
  }

  void onMenuEditClicked(PlaceScenariosLogic logic) {
    showEditNameSheet(logic.currentScenario!.name!,
        (newName) => widget.logic.renameScenario(logic.currentScenario!, newName));
  }

  Padding buildFab() {
    return Padding(
      // Fix hard-coded value
      padding: const EdgeInsets.only(right: 40.0, bottom: 16.0),
      child: Align(
        alignment: Alignment.bottomRight,
        child: FloatingActionButton(
          onPressed: () {
            goToNewScenarioScreen();
          },
          backgroundColor: AppTheme().primaryColor,
          child: Icon(
            Icons.add,
            color: AppTheme().secondaryColor,
          ),
        ),
      ),
    );
  }

  void goToNewScenarioScreen() {
    Get.to(() =>
        NewPlaceScenariosScreen(widget.logic.place, widget.logic.floor, widget.currentLocationId));
  }

  _itemScenario(Scenario scenario) {
    return InkWell(
      borderRadius: const BorderRadius.all(Radius.circular(8)),
      child: Padding(
        padding:
            EdgeInsetsDirectional.only(start: 8.0.dp, end: 8.0.dp, top: 8.0.dp, bottom: 8.0.dp),
        child: IntrinsicWidth(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsetsDirectional.only(start: 12.0.dp, end: 12.0.dp),
                child: Text(
                  scenario.name ?? '',
                  style: widget.logic.currentScenario == scenario
                      ? AppTheme().textPrimary3Regular
                      : AppTheme().textSecondary3Regular,
                ),
              ),
              SizedBox(height: 4.0.dp),
              Visibility(
                  visible: widget.logic.currentScenario == scenario,
                  child: Divider(
                    height: 5,
                    color: AppTheme().textColor1,
                    thickness: 2,
                  )),
            ],
          ),
        ),
      ),
      onTap: () {
        widget.logic.changeScenario(scenario);
      },
    );
  }

  _itemLight(ScenarioDet scenarioDet) {
    return InkWell(
      onTap: () {
        widget.logic.changeValue(scenarioDet, scenarioDet.value == 'true' ? 'false' : 'true');
      },
      child: Padding(
        padding:
            EdgeInsetsDirectional.only(start: 12.0.dp, end: 12.0.dp, top: 4.0.dp, bottom: 4.0.dp),
        child: Row(
          children: [
            Expanded(child: Text(scenarioDet.deviceName ?? '')),
            FlutterSwitch(
              value: scenarioDet.value == 'true',
              activeColor: AppTheme().secondaryColor,
              height: 25.0.dp,
              width: 50.0.dp,
              onToggle: (bool value) {
                widget.logic.changeValue(scenarioDet, value ? 'true' : 'false');
              },
            ),
          ],
        ),
      ),
    );
  }

  _itemCurtain(ScenarioDet scenarioDet) {
    return Padding(
      padding:
          EdgeInsetsDirectional.only(start: 12.0.dp, end: 12.0.dp, top: 6.0.dp, bottom: 6.0.dp),
      child: Row(
        children: [
          Expanded(
              child: Text(scenarioDet.deviceName ?? '')
          ),
          Expanded(
              child: animatedToggleSwitch(scenarioDet)
          ),
        ],
      ),
    );
  }

  AnimatedToggleSwitch<String> animatedToggleSwitch(ScenarioDet scenarioDet) {
    return AnimatedToggleSwitch<String>.rolling(
      current: widget.logic.getValue(scenarioDet),
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
            color: widget.logic.getValue(scenarioDet) == SocketConstants.curtainClose
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
            color: widget.logic.getValue(scenarioDet) == SocketConstants.curtainOpen
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
        widget.logic.changeValue(scenarioDet, value);
      },
    );
  }
}
