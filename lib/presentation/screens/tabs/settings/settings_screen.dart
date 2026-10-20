import 'package:bms/presentation/components/appbar.dart';
import 'package:bms/core/eventbus/event_bus_const.dart';
import 'package:bms/core/eventbus/event_bus_model.dart';
import 'package:bms/core/utils/extension.dart';
import 'package:bms/core/utils/globals.dart';
import 'package:bms/data/data_sources/local_data_sources/pref/pref_helper.dart';
import 'package:bms/core/values/theme.dart';

import 'package:bms/presentation/screens/tabs/settings/pages/locations_screen.dart';

 
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../../components/logout_bottom_sheet.dart';
import '../../../components/user_name_sheet.dart';
import '../../../logic/settings_logic.dart';



class SettingsScreen extends StatefulWidget {
  late SettingsLogic logic;

  SettingsScreen({super.key});

  @override
  State<StatefulWidget> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    widget.logic = Get.put(SettingsLogic());

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SettingsLogic>(
      assignId: true,
      builder: (logic) {
        return Scaffold(
          appBar: appBar('settings'.tr),
          body: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(left: 16.0.dp, right: 16.0.dp, bottom: 8.0.dp),
                child: Card(
                  color: AppTheme().cardBackground,
                  elevation: 0,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      showChangeUsernameSheet(
                          currentName: PrefHelper.getString(PrefHelper.userDisplayName),
                          callback: (text) async {
                            if (text.isEmpty) {
                              Get.snackbar('خطا', 'باید نام را وارد کنید');
                              return;
                            }

                            Navigator.pop(Get.context!);
                            PrefHelper.put(PrefHelper.userDisplayName, text);

                            eventBus.fire(EventBusModel(event : EventBusConst.eventUpdatedUserName));
                            return;
                          });
                    },
                    child: Padding(
                      padding: EdgeInsets.all(16.0.dp),
                      child: Row(
                        children: [
                          Expanded(
                              child: Text(
                            'change_username'.tr,
                            style: AppTheme().textPrimary3Medium,
                          )),
                          SvgPicture.asset(
                            'assets/icons/arrow-left.svg',
                            color: AppTheme().textColor2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 16.0.dp, right: 16.0.dp, bottom: 8.0.dp),
                child: Card(
                  color: AppTheme().cardBackground,
                  elevation: 0,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => goToLocationScreens(),
                    child: Padding(
                      padding: EdgeInsets.all(16.0.dp),
                      child: Row(
                        children: [
                          Expanded(
                              child: Text(
                            'locations'.tr,
                            style: AppTheme().textPrimary3Medium,
                          )),
                          SvgPicture.asset(
                            'assets/icons/arrow-left.svg',
                            color: AppTheme().textColor2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 16.0.dp, right: 16.0.dp, bottom: 8.0.dp),
                child: Card(
                  color: AppTheme().cardBackground,
                  elevation: 0,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => showLogoutSheet(() => logic.logout()),
                    child: Padding(
                      padding: EdgeInsets.all(16.0.dp),
                      child: Row(
                        children: [
                          Expanded(
                              child: Text(
                            'logout'.tr,
                            style: AppTheme().textPrimary3Medium.copyWith(
                                  color: AppTheme().red,
                                ),
                          )),
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

  Future<dynamic>? goToLocationScreens() =>  Get.to(() => const LocationsScreen());
}
