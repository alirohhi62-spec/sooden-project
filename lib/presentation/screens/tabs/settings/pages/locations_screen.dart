import 'package:bms/core/utils/extension.dart';
import 'package:bms/core/values/theme.dart';
import 'package:bms/data/data_sources/local_data_sources/database/model/location.dart';
import 'package:bms/presentation/components/appbar.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../../../../logic/locations_logic.dart';
import 'new_location_screen.dart';

class LocationsScreen extends StatefulWidget {
  const LocationsScreen({super.key});

  @override
  State<StatefulWidget> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends State<LocationsScreen> {
  late LocationsLogic logic;

  @override
  void initState() {
    logic = Get.put(LocationsLogic());

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LocationsLogic>(
      builder: (logic) {
        return Scaffold(
          appBar: appBar('locations'.tr),
          body: Column(
            children: [
              ListView.builder(
                  shrinkWrap: true,
                  itemCount: logic.locationList.length,
                  itemBuilder: (context, index) => _item(logic.locationList[index])),
              Padding(
                padding:
                    EdgeInsets.only(left: 16.0.dp, right: 16.0.dp, bottom: 16.0.dp, top: 8.0.dp),
                child: InkWell(
                  onTap: () => Get.to(() => NewLocationScreen()),
                  child: DottedBorder(
                    color: AppTheme().textColor2,
                    dashPattern: const [3, 6],
                    strokeWidth: 1,
                    borderType: BorderType.RRect,
                    radius: const Radius.circular(8),
                    child: SizedBox(
                      height: 60,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add,
                            color: AppTheme().textColor2,
                          ),
                          SizedBox(width: 8.0.dp),
                          Text(
                            'مکان جدید',
                            style: AppTheme().textSecondary3Regular,
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  _item(Location location) {
    return Padding(
      padding:
          EdgeInsetsDirectional.only(start: 12.0.dp, end: 12.0.dp, top: 4.0.dp, bottom: 4.0.dp),
      child: InkWell(
        onTap: () {
          showConnectDialog(location);
        },
        child: Card(
          color: AppTheme().cardBackground,
          elevation: 0,
          child: Padding(
            padding: EdgeInsets.all(12.0.dp),
            child: Row(children: [
              Expanded(
                  child: Text(
                location.name ?? '',
                style: AppTheme().textPrimary2Medium,
              )),
              buildConnectBadge(location),
              PopupMenuButton(
                itemBuilder: (context) {
                  return buildMenuItems(location);
                },
              ),
            ]),
          ),
        ),
      ),
    );
  }

  StatelessWidget buildConnectBadge(Location location) {
    if(!location.isSelected!){
      return Container();
    }else {
      return Card(
        elevation: 0,
        color: const Color(0x1145A852),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: Row(
                children: [
                  SvgPicture.asset(
                    'assets/icons/circle.svg',
                    width: 8,
                    height: 8,
                    color: const Color(0xFF45A852),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'connect'.tr,
                    style: const TextStyle(
                      color: Color(0xFF45A852),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  List<PopupMenuItem<String>> buildMenuItems(Location location) {
    return [
      PopupMenuItem(
        value: 'connect',
        child: Text('connect'.tr),
        onTap: () {
          showConnectDialog(location);
        },
      ),
      PopupMenuItem(
        value: 'edit',
        child: Text('edit'.tr),
        onTap: () {
          goToNewLocationScreen(location);
        },
      ),
      PopupMenuItem(
        value: 'delete',
        child: Text('delete'.tr),
        onTap: () {
          logic.deleteLocation(location);
        },
      )
    ];
  }

  void showConnectDialog(Location location) {
    if(location.isSelected!) return;

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('تغیر مکان ', style: AppTheme().textPrimary2Medium),
            content: Text('آیا میخواهید به ${location.name} متصل شوید؟',
                style: AppTheme().textPrimary2Regular),
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
                  logic.connectToLocation(location);
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }

  void goToNewLocationScreen(Location location) {
    Future.delayed(const Duration(milliseconds: 200), () async {
      /*String? wifiName = await NetworkInfo().getWifiName();
      print(wifiName);*/

      Get.to(() => NewLocationScreen(locationToEdit: location));
    });
  }
}
