import 'package:bms/core/values/theme.dart';
import 'package:bms/core/values/translates.dart';
import 'package:bms/data/data_sources/local_data_sources/database/app_database.dart';
import 'package:bms/presentation/screens/splash/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:sizer/sizer.dart';

import 'core/di/app_binding.dart';
import 'core/utils/globals.dart';
import 'presentation/lifecycle_event_handler.dart';

Future<void> main() async {
  await GetStorage.init();
  _observeLifeCycle();
  Get.isLogEnable = true;
  runApp(const MyApp());
  _logger('main','run App called');
}

void _observeLifeCycle() {
  WidgetsFlutterBinding.ensureInitialized();
  WidgetsBinding.instance.addObserver(LifecycleEventHandler());
}

class MyApp extends StatelessWidget with WidgetsBindingObserver {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Sizer(builder: (
      BuildContext context,
      Orientation orientation,
      DeviceType deviceType,
    ) {
      // Alice alice = Alice(showNotification: true);
      return GetMaterialApp(
        // navigatorKey:  alice.getNavigatorKey(),
        title: 'سودن',
        themeMode: ThemeMode.light,
        initialBinding: AppBindings(),
        translations: Translates(),
        debugShowCheckedModeBanner: false,
        locale: const Locale('fa', 'IR'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en', 'US'), Locale('fa', 'IR')],
        theme: AppTheme().getThem(),
        home: FutureBuilder<AppDatabase>(
          future: AppDatabase.init(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return SplashScreen();
            }

            return Container();
          },
        ),
      );
    });
  }
}

void _logger(String key, String value) {
  doLogGlobal('main.dart', key, value);
}
