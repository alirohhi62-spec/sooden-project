import 'package:bms/core/utils/extension.dart';
import 'package:bms/core/values/theme.dart';
import 'package:bms/data/data_sources/local_data_sources/database/model/place.dart';
import 'package:bms/data/data_sources/local_data_sources/database/model/scenario.dart';
import 'package:bms/data/data_sources/local_data_sources/pref/pref_helper.dart';
import 'package:bms/data/enums/headline_code.dart';
import 'package:bms/presentation/screens/tabs/home/pages/place_curtain_screen.dart';
import 'package:bms/presentation/screens/tabs/home/pages/place_lights_screen.dart';
import 'package:bms/presentation/screens/tabs/home/pages/place_scenario/place_scenarios_screen.dart';
import 'package:bms/presentation/screens/tabs/home/pages/place_temperature_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:lottie/lottie.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/utils/globals.dart';
import '../../../../data/model/headline.dart';
import '../../../components/user_name_sheet.dart';
import '../../../logic/home_logic.dart';
import '../../logger/logger_screen.dart';

class HomeScreen extends StatefulWidget {
  late HomeLogic logic;

  HomeScreen({super.key});

  @override
  State<StatefulWidget> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    widget.logic = Get.put(HomeLogic());

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomeLogic>(
      builder: (logic) {
        return Scaffold(
          appBar: AppBar(
              backgroundColor: Colors.transparent,
              systemOverlayStyle: SystemUiOverlayStyle(
                statusBarColor: AppTheme().backgroundColor,
                statusBarIconBrightness: Brightness.dark,
                // For Android (dark icons)
                statusBarBrightness: Brightness.light, // For// iOS (dark icons)
              ),
              toolbarHeight: 30,
              actions: _appBarActions(logic)),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsetsDirectional.only(start: 16.0.dp, end: 16.0.dp),
                  child: Row(
                    children: [
                      Expanded(
                          child: Text(
                        'سلام،${PrefHelper.getString(PrefHelper.userDisplayName)}',
                        style: AppTheme().textPrimary1Bold,
                      )),
                      buildFutureWeatherText(logic),
                      SizedBox(width: 8.0.dp),
                      Lottie.asset('assets/lottie/weather-normal.json',
                          width: 45.0.dp, height: 45.0.dp),
                    ],
                  ),
                ),

                Padding(
                  padding: EdgeInsetsDirectional.only(start: 12.0.dp, end: 12.0.dp),
                  child: Row(
                    children: [
                      Card(
                        color: AppTheme().cardBackground,
                        elevation: 0,
                        shape: const StadiumBorder(side: BorderSide(style: BorderStyle.none)),
                        child: Visibility(
                          visible: logic.floorsWidget.length > 1,
                          child: DropdownButton(
                            elevation: 1,
                            icon: const Icon(Iconsax.arrow_down_1),
                            underline: Container(),
                            borderRadius: const BorderRadius.all(Radius.circular(8)),
                            padding: EdgeInsetsDirectional.only(
                                start: 12.0.dp, end: 12.0.dp, top: 4.0.dp, bottom: 4.0.dp),
                            items: logic.floorsWidget,
                            value: logic.currentFloor,
                            onChanged: (floor) {
                              setState(() {
                                logic.changeFloor(floor);
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsetsDirectional.only(start: 16.0.dp, end: 16.0.dp, top: 16.0.dp),
                  child: SizedBox(
                    height: 45.0.dp,
                    child: ListView.builder(
                        itemCount: logic.places.length,
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (ctx, index) => _itemPlace(logic.places[index])),
                  ),
                ),
                Visibility(
                  visible: widget.logic.hasElevator,
                  child: buildElevator(),
                ),
                Padding(
                  padding: EdgeInsetsDirectional.only(start: 16.0.dp, end: 16.0.dp, top: 8.0.dp),
                  child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 150.0.dp,
                        crossAxisSpacing: 8.0.dp,
                        mainAxisSpacing: 8.0.dp,
                      ),
                      itemCount: logic.headlines.length,
                      itemBuilder: (ctx, index) => _itemCategory(logic.headlines[index])),
                ),
                Padding(
                  padding: EdgeInsetsDirectional.only(
                      start: 0.0.dp, end: 0.0.dp, top: 8.0.dp, bottom: 16.0.dp),
                  child: SizedBox(
                    height: 45.0.dp,
                    child: ListView.builder(
                        itemCount: logic.localScenario.length,
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (ctx, index) => _itemScenario(logic.localScenario[index])),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  SizedBox buildLoading() {
    return SizedBox(
      height: 200.0.dp,
      child: Center(
        child: Lottie.asset('assets/lottie/loading-dots.json', height: 50.0.dp),
      ),
    );
  }

  Padding buildElevator() {
    return Padding(
      padding: EdgeInsetsDirectional.only(start: 16.0.dp, end: 16.0.dp),
      child: Card(
        color: AppTheme().cardBackground,
        elevation: 0,
        shape: AppTheme().borderStyle,
        child: Padding(
          padding:
              EdgeInsetsDirectional.only(start: 16.0.dp, end: 8.0.dp, top: 8.0.dp, bottom: 8.0.dp),
          child: Row(
            children: [
              Expanded(
                  child: Text(
                'call_elevator'.tr,
                style: AppTheme().textPrimary3Bold,
              )),
              InkWell(
                customBorder: const CircleBorder(),
                child: Padding(
                  padding: EdgeInsets.all(8.0.dp),
                  child: Icon(
                    Icons.elevator_outlined,
                    size: 24.0.dp,
                    color: AppTheme().blue,
                  ),
                ),
                onTap: () {
                  widget.logic.callElevator();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _appBarActions(HomeLogic logic) {
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

  FutureBuilder<String> buildFutureWeatherText(HomeLogic logic) {
    return FutureBuilder<String>(
      future: logic.getWeather(),
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else {
          if (snapshot.hasError) {
            printError(info: snapshot.error.toString());
            return Text('خطا در دریافت اطلاعات',
                style: AppTheme().textPrimary1Medium.copyWith(fontSize: 8.sp));
          } else {
            return Text(
              '${snapshot.data}', // where snapshot.data is your returned String
              style: AppTheme().textPrimary1Medium.copyWith(fontSize: 21.sp),
            );
          }
        }
      },
    );
  }

  _itemPlace(Place place) {
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
                  place.getName(),
                  style: place.code == widget.logic.currentPlaceModel.code
                      ? AppTheme().textPrimary3Regular
                      : AppTheme().textSecondary3Regular,
                ),
              ),
              SizedBox(height: 4.0.dp),
              Visibility(
                  visible: place.code == widget.logic.currentPlaceModel.code,
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
        widget.logic.changePLace(place);
      },
      onLongPress: () {
        showEditNameSheet(place.getName(), (newName) => widget.logic.renamePlace(place, newName));
      },
    );
  }

  _itemCategory(Headline headline) {
    return Card(
      color: AppTheme().cardBackground,
      shape: AppTheme().borderStyle,
      elevation: 0,
      child: InkWell(
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        child: Padding(
          padding: EdgeInsets.all(16.0.dp),
          child: Column(
            children: [
              widget.logic.headlineIcon(headline),
              SizedBox(height: 8.0.dp),
              Expanded(
                  child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    headline.code.title!,
                    style: headline.active!
                        ? AppTheme().textPrimary3Bold
                        : AppTheme().textSecondary3Bold,
                  ),
                  SizedBox(height: 4.0.dp),
                  Text(
                    headline.code != HeadlineCode.scenarios
                        ? '${headline.countOfDevices} ${'devices'.tr}'
                        : '',
                    style: AppTheme().textSecondary5Regular,
                  ),
                ],
              )),
            ],
          ),
        ),
        onTap: () {
          switch (headline.code.value) {
            case 'U':
              if (headline.countOfDevices == 0) {
                return;
              }

              Get.to(() => PlaceLightsScreen(
                    floor: widget.logic.currentFloor,
                    place: widget.logic.currentPlaceModel,
                  ));
              break;

            case 'V':
              if (headline.countOfDevices == 0) {
                return;
              }

              Get.to(() => PlaceCurtainScreen(
                    floor: widget.logic.currentFloor,
                    place: widget.logic.currentPlaceModel,
                  ));
              break;

            case 'W':
              if (headline.countOfDevices == 0) {
                return;
              }

              Get.to(() => PlaceTemperatureScreen(
                    floor: widget.logic.currentFloor,
                    place: widget.logic.currentPlaceModel,
                  ));
              break;

            case 'X':
              Get.to(() => PlaceScenariosScreen(widget.logic.currentPlaceModel,
                  widget.logic.currentFloor, widget.logic.currentLocationId));
              break;
          }
        },
      ),
    );
  }

  _itemScenario(Scenario scenario) {
    return InkWell(
      onLongPress: () {
        _showRemoveScenarioDialog(scenario);
      },
      onTap: () {
        widget.logic.onScenarioClicked(scenario);
      },
      child: Padding(
        padding: const EdgeInsets.only(right: 16.0, left: 16),
        child: Card(
          color: AppTheme().cardBackground,
          elevation: 0,
          shape: AppTheme().borderStyle,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'سناریو ${scenario.name}',
                style: AppTheme().textSecondary3Regular,
              ),
            ),
          ),
        ),
      ),
    );
  }

  _showRemoveScenarioDialog(Scenario scenario) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('حذف سناریو', style: AppTheme().textPrimary2Medium),
            content:
                Text('آیا سناریو ${scenario.name} حذف شود؟', style: AppTheme().textPrimary2Regular),
            actions: <Widget>[
              TextButton(
                child: Text('خیر', style: AppTheme().textPrimary2Medium),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text('بلی', style: AppTheme().textPrimary2Medium),
                onPressed: () {
                  widget.logic.removeScenario(scenario);
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }
}
