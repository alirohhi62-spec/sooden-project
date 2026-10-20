import 'package:bms/presentation/components/primary_button.dart';
import 'package:bms/core/utils/extension.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';

import '../../core/values/theme.dart';

showChangeUsernameSheet({String? currentName, required Function(String) callback}) {
  TextEditingController controller = TextEditingController(text: currentName ?? '');

  showModalBottomSheet(
      context: Get.context!,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(4.0.dp),
          topRight: Radius.circular(4.0.dp),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
          return Padding(
            padding: MediaQuery.of(context).viewInsets,
            child: Padding(
              padding: EdgeInsets.all(4.w),
              child: Wrap(
                alignment: WrapAlignment.center,
                children: [
                  Row(
                    children: [
                      Text(
                        'ورود نام کاربر برنامه'.tr,
                        style: AppTheme().textPrimary4Medium,
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  TextField(
                    controller: controller,
                    style: AppTheme().textPrimary4Medium,
                    decoration: InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(8.0),
                        ),
                        borderSide: BorderSide(
                          color: AppTheme().divider,
                          width: 1.0,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  PrimaryButton(
                      text: 'تایید',
                      onTap: () {
                        callback.call(controller.text);
                      }),
                ],
              ),
            ),
          );
        });
      });
}

showEditNameSheet(String defaultName, Function(String) callback) {
  TextEditingController controller = TextEditingController(text: defaultName);

  showModalBottomSheet(
      context: Get.context!,
      clipBehavior: Clip.antiAliasWithSaveLayer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(4.0.dp),
          topRight: Radius.circular(4.0.dp),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
          return Padding(
            padding: MediaQuery.of(context).viewInsets,
            child: Padding(
              padding: EdgeInsets.all(4.w),
              child: Wrap(
                alignment: WrapAlignment.center,
                children: [
                  Row(
                    children: [
                      Text(
                        'تغییر نام به:'.tr,
                        style: AppTheme().textPrimary4Medium,
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  TextField(
                    controller: controller,
                    style: AppTheme().textPrimary4Medium,
                    decoration: InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(8.0),
                        ),
                        borderSide: BorderSide(
                          color: AppTheme().divider,
                          width: 1.0,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  PrimaryButton(
                      text: 'تایید',
                      onTap: () {
                        callback.call(controller.text);
                        Navigator.pop(context);
                      }),
                ],
              ),
            ),
          );
        });
      });
}
