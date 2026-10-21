import 'package:bms/core/utils/extension.dart';
import 'package:bms/core/values/theme.dart';
import 'package:bms/double_back_exit.dart';
import 'package:bms/presentation/logic/home_logic.dart';
import 'package:bms/presentation/logic/security_logic.dart';
import 'package:bms/presentation/logic/settings_logic.dart';
import 'package:bms/presentation/screens/tabs/scenario/scenarios_screen.dart';
import 'package:bms/presentation/screens/tabs/security/security_screen.dart';
import 'package:bms/presentation/screens/tabs/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/utils/globals.dart';
import '../../../data/data_sources/remote_data_sources/socket/connection_keeper.dart';
import '../../logic/scenario_logic.dart';
import 'home/home_screen.dart';
import '../../../panel12/panel12_screen.dart';
import '../../../panel12/panel12_scenarios.dart';
import '../../../panel12/panel12_vacation.dart';
import '../../../panel12/panel12_controller.dart';

class MainScreen extends StatefulWidget {
  int currentTab = 0;
  late final HomeScreen _homeScreen = HomeScreen();

  late final ScenariosScreen _scenariosScreen = ScenariosScreen();

  late final SecurityScreen _securityScreen = SecurityScreen();

  late final SettingsScreen _settingsScreen = SettingsScreen();

  MainScreen({super.key});

  @override
  State<StatefulWidget> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  setScreen(int index) {
    switch (index) {
      case 0:
        // پنل‌های جدید (RF-12) صفحه‌ی آینه‌ی پنل را نشان می‌دهند؛
        // صفحه‌ی قبلی پنهان می‌ماند ولی فعال است چون اتصال را مدیریت می‌کند.
        return Panel12TabHost(home: widget._homeScreen);

      case 1:
        // پنل RF-12: صفحه‌ی سناریوی جدید (سناریوها روی خود پنل ذخیره می‌شوند)
        return Panel12ScenarioTabHost(home: widget._scenariosScreen);

      case 2:
        // پنل RF-12: سناریو مسافرت؛ پنل‌های قدیمی: صفحه‌ی امنیت قبلی
        return Panel12VacationTabHost(home: widget._securityScreen);

      case 3:
        return widget._settingsScreen;
    }
  }
  @override
  void dispose() async{
    super.dispose();
    doLogGlobal('main_screen', 'dispose', 'Method called');

 var homeStatus =  await  Get.delete<HomeLogic>();
    doLogGlobal('main_screen', 'dispose', 'HomeLogic $homeStatus');

    var scenarioStatus = await Get.delete<ScenarioLogic>();
    doLogGlobal('main_screen', 'dispose', 'ScenarioLogic $scenarioStatus');

    var securityStatus =  await  Get.delete<SecurityLogic>();
    doLogGlobal('main_screen', 'dispose', 'SecurityLogic $securityStatus');

    var settingsStatus = await  Get.delete<SettingsLogic>();
    doLogGlobal('main_screen', 'dispose', 'SettingsLogic $settingsStatus');


  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: DoubleBackExitApp(
              child: Stack(
                children: List<Widget>.generate(
                  4,
                  (index) {
                    return IgnorePointer(
                      ignoring: widget.currentTab != index,
                      child: Opacity(
                        opacity: widget.currentTab == index ? 1 : 0,
                        child: setScreen(index),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          // نوار کوچک وضعیت اتصال (به‌جای پرتاب به صفحه‌ی خطا)
          Obx(() {
            final st = ConnectionKeeper.instance.state.value;
            final bool show = ConnectionKeeper.instance.hasSession && st != LinkState.connected;
            return AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: show
                  ? Container(
                      width: double.infinity,
                      color: AppTheme().cardBackground,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                                strokeWidth: 1.5, color: AppTheme().textColor2),
                          ),
                          const SizedBox(width: 8),
                          Text('در حال اتصال...',
                              style: TextStyle(fontSize: 11, color: AppTheme().textColor2)),
                        ],
                      ),
                    )
                  : const SizedBox(width: double.infinity, height: 0),
            );
          }),
        ],
      ),
      bottomNavigationBar: Obx(() {
        final rf = _rf12Tab;
        return BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        backgroundColor: AppTheme().cardBackground,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.all(4.0.dp),
                child: const Icon(Iconsax.home_2),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.all(4.0.dp),
                child: const Icon(Iconsax.home_2),
              ),
              label: 'home'.tr),
          BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.all(4.0.dp),
                child: const Icon(Iconsax.video_square),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.all(4.0.dp),
                child: const Icon(Iconsax.video_square),
              ),
              label: 'scenarios'.tr),
          BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.all(4.0.dp),
                child: Icon(rf ? Icons.flight_takeoff_rounded : Iconsax.security),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.all(4.0.dp),
                child: Icon(rf ? Icons.flight_takeoff_rounded : Iconsax.security),
              ),
              label: rf ? 'مسافرت' : 'security'.tr),
          BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.all(4.0.dp),
                child: const Icon(Iconsax.setting),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.all(4.0.dp),
                child: const Icon(Iconsax.setting),
              ),
              label: 'settings'.tr),
        ],
        currentIndex: widget.currentTab,
        unselectedItemColor: AppTheme().textColor2,
        selectedItemColor: AppTheme().textColor1,
        unselectedFontSize: 10.0.sp,
        selectedFontSize: 10.0.sp,
        onTap: onItemTapped,
      );
      }),
    );
  }

  /// پنل RF-12: تب سوم «مسافرت» است
  bool get _rf12Tab {
    final c = Panel12Controller.instance;
    return c.isRf12.value || c.isSd23.value || c.isSim12.value || (!c.modelKnown.value && (c.lastRf12.value || c.lastSd23.value || c.lastSim12.value));
  }

  void onItemTapped(int index) {
    setState(() {
      widget.currentTab = index;
    });
  }
}
