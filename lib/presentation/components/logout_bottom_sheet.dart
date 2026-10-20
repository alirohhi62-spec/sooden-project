import 'package:bms/presentation/components/primary_button.dart';
import 'package:bms/presentation/components/secondary_button.dart';
import 'package:bms/core/utils/extension.dart';
import 'package:bms/core/values/theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';

showLogoutSheet(VoidCallback positiveCallback) {
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
                        'logout'.tr,
                        style: AppTheme().textPrimary4Medium,
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'logout_message'.tr,
                    style: AppTheme().textPrimary4Regular,
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: PrimaryButton(
                            text: 'logout'.tr,
                            background: AppTheme().red,
                            onTap: () {
                              Navigator.pop(context);
                              positiveCallback.call();
                            }),
                      ),
                      SizedBox(width: 8.0.dp),
                      Expanded(
                        flex: 1,
                        child: SecondaryButton(
                            text: 'cancel'.tr,
                            onTap: () {
                              Navigator.pop(context);
                            }),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        });
      });
}
