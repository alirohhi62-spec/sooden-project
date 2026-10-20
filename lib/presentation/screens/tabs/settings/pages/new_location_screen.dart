import 'package:bms/core/utils/extension.dart';
import 'package:bms/core/values/colors.dart';
import 'package:bms/core/values/theme.dart';
import 'package:bms/data/data_sources/local_data_sources/database/model/location.dart';
import 'package:bms/presentation/components/appbar.dart';
import 'package:bms/presentation/components/primary_button.dart';
import 'package:bms/presentation/components/rita_text_field.dart';
import 'package:bms/presentation/screens/tabs/settings/pages/qr_reader_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:bms/panel12/panel12_screen.dart';

import '../../../../../core/utils/globals.dart';
import '../../../../logic/new_location_logic.dart';
import '../../../logger/logger_screen.dart';

class NewLocationScreen extends StatefulWidget {
  late Location? locationToEdit;

  NewLocationScreen({this.locationToEdit, super.key});

  @override
  State<StatefulWidget> createState() => _NewLocationScreenState();
}

class _NewLocationScreenState extends State<NewLocationScreen> {
  late NewLocationLogic logic;

  @override
  void initState() {
    logic = Get.put(NewLocationLogic(widget.locationToEdit));

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<NewLocationLogic>(
      assignId: true,
      builder: (logic) {
        return Scaffold(
          appBar: buildAppBar(),
          body: Padding(
            padding: EdgeInsets.all(16.0.dp),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              'location_info'.tr,
                              style: AppTheme().textSecondary4Medium,
                            ),
                          ],
                        ),
                        Card(
                          elevation: 0,
                          color: AppTheme().cardBackground,
                          child: Padding(
                            padding: EdgeInsets.all(12.0.dp),
                            child: Column(
                              children: [
                                RitaTextField(
                                  controller: logic.locationNameController,
                                  hint: 'location_name'.tr,
                                ),
                                SizedBox(height: 12.0.dp),
                                Row(
                                  children: [
                                    Text(
                                      'static_ip'.tr,
                                      style: AppTheme().textSecondary4Medium,
                                    ),
                                  ],
                                ),
                                Card(
                                  color: AppTheme().cardBackground,
                                  elevation: 0,
                                  child: Column(
                                    children: [
                                      RitaTextField(
                                        controller: logic.staticIpController,
                                        hint: '192.168.0.0'.tr,
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 12.0.dp),
                                PrimaryButton(
                                    text: 'ذخیره',
                                    background:
                                        logic.visibleOtherFields() ? AppTheme().green : null,
                                    enable: !logic.isLoading,
                                    onTap: () async {
                                      FocusManager.instance.primaryFocus?.unfocus();

                                      logic.checkConnection();
                                    }),
                                Visibility(
                                    visible: logic.isLoading, child: buildProgressIndicator())
                              ],
                            ),
                          ),
                        ),
                        Visibility(
                          visible: logic.visibleOtherFields(),
                          child: Column(
                            children: [
                              SizedBox(height: 16.0.dp),
                              Row(
                                children: [
                                  Text(
                                    'direct_connection'.tr,
                                    style: AppTheme().textSecondary4Medium,
                                  ),
                                ],
                              ),
                              Card(
                                color: AppTheme().cardBackground,
                                elevation: 0,
                                child: Padding(
                                  padding: EdgeInsets.all(12.0.dp),
                                  child: Column(
                                    children: [
                                      RitaTextField(
                                        controller: logic.wifiNameController,
                                        hint: 'نام وای‌فای'.tr,
                                        keyboardType: TextInputType.text,
                                      ),
                                      SizedBox(height: 8.0.dp),
                                      RitaTextField(
                                        controller: logic.wifiPasswordController,
                                        hint: 'پسورد وای‌فای'.tr,
                                        keyboardType: TextInputType.visiblePassword,
                                      ),
                                      SizedBox(height: 12.0.dp),
                                      SizedBox(height: 12.0.dp),
                                      PrimaryButton(
                                        text: 'تنظیم',
                                        onTap: () {
                                          logic.onSetDeviceNamePassword();
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: 16.0.dp),
                              Row(
                                children: [
                                  Text(
                                    'modem_connection'.tr,
                                    style: AppTheme().textSecondary4Medium,
                                  ),
                                ],
                              ),
                              Card(
                                color: AppTheme().cardBackground,
                                elevation: 0,
                                child: Padding(
                                  padding: EdgeInsets.all(12.0.dp),
                                  child: Column(
                                    children: [
                                      RitaTextField(
                                        controller: logic.macAddressController,
                                        enabled: false,
                                        hint: 'mac_address'.tr,
                                      ),
                                      SizedBox(height: 8.0.dp),
                                      RitaTextField(
                                        controller: logic.modemNameController,
                                        hint: 'modem_name'.tr,
                                        keyboardType: TextInputType.text,
                                      ),
                                      SizedBox(height: 8.0.dp),
                                      RitaTextField(
                                        controller: logic.modemPasswordController,
                                        hint: 'modem_password'.tr,
                                        keyboardType: TextInputType.visiblePassword,
                                      ),
                                      SizedBox(height: 8.0.dp),
                                      RitaTextField(
                                        enabled: false,
                                        controller: logic.panelIpOnModemController,
                                        hint: 'modem_ip'.tr,
                                      ),
                                      SizedBox(height: 12.0.dp),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: PrimaryButton(
                                              text: 'تست اتصال',
                                              loading: logic.mSetModemIpLoading,
                                              onTap: () => logic.setModemConfig(),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          InkWell(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Padding(
                                              padding: const EdgeInsets.all(4.0),
                                              child: SvgPicture.asset('assets/icons/qr.svg'),
                                            ),
                                            onTap: () {
                                              Get.to(() => QRReaderScreen((ssid, password) {
                                                    setState(() {
                                                      logic.modemNameController.text = ssid;
                                                      logic.modemPasswordController.text = password;
                                                    });

                                                    logic.setModemConfig();
                                                  }));
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: 16.0.dp),
                              Row(
                                children: [
                                  Text(
                                    'static_ip'.tr,
                                    style: AppTheme().textSecondary4Medium,
                                  ),
                                ],
                              ),
                              Card(
                                color: AppTheme().cardBackground,
                                elevation: 0,
                                child: Padding(
                                  padding: EdgeInsets.all(12.0.dp),
                                  child: Column(
                                    children: [
                                      RitaTextField(
                                        controller: logic.staticIpController,
                                        hint: '192.168.0.0'.tr,
                                      ),
                                      SizedBox(height: 12.0.dp),
                                      PrimaryButton(
                                        text: 'تنظیم کردن',
                                        onTap: () {
                                          logic.setStaticIpConfig();
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: 20.0.dp),

                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Visibility(
                  visible: (logic.visibleOtherFields()),
                  child: PrimaryButton(
                    text: 'goto_main'.tr,
                    onTap: () {
                      logic.goToMainClicked();
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildProgressIndicator() {
    return Column(
      children: [
        SizedBox(height: 40.0.dp),
        const SpinKitWave(
          color: AppColors.loadingColor,
          size: 50.0,
          duration: Duration(milliseconds: 800),
        ),
      ],
    );
  }

  AppBar buildAppBar() {
    return appBar(widget.locationToEdit == null ? 'new_location'.tr : 'location_settings'.tr,
        actions: <Widget>[
          // حالت نمایشی پنل (با رمز نصاب)، برای تست و نمایش بدون پنل واقعی
          IconButton(
            icon: const Icon(Icons.slideshow_outlined),
            tooltip: 'حالت نمایشی',
            onPressed: Panel12DemoPage.open,
          ),
          isLoggerEnable
              ? IconButton(
                  icon: const Icon(Icons.history),
                  onPressed: () {
                    Get.to(() => LoggerScreen());
                  },
                )
              : Container(),
        ]);
  }
}
