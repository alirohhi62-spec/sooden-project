import 'package:bms/core/utils/extension.dart';
import 'package:bms/core/values/theme.dart';
import 'package:bms/data/data_sources/local_data_sources/database/model/scenario.dart';
import 'package:bms/presentation/components/appbar.dart';
import 'package:bms/presentation/components/primary_button.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../logic/scenario_logic.dart';

class ScenariosScreen extends StatefulWidget {

  late ScenarioLogic logic;

  bool isFinished = false;

  ScenariosScreen({super.key});

  @override
  State<StatefulWidget> createState() => _ScenariosScreenState();
}

class _ScenariosScreenState extends State<ScenariosScreen> {

  @override
  void initState() {
    widget.logic =
        Get.put(ScenarioLogic());

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ScenarioLogic>(
      assignId: true,
      builder: (logic) {
        return Scaffold(
          appBar: appBar('scenarios'.tr),
          body: Padding(
            padding: EdgeInsets.all(12.0.dp),
            child: Column(
              children: [
                ListView.builder(
                  itemCount: logic.generalScenarios?.length?? 0,
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (ctx, index) => _itemScenario(logic.generalScenarios![index]),
                ),
                SizedBox(height: 12.0.dp),
              ],
            ),
          ),
        );
      },
    );
  }

  DottedBorder _buildAddNewScenarioButton() {
    return DottedBorder(
                    color: AppTheme().textColor2,
                    dashPattern: const [3, 6],
                    strokeWidth: 1,
                    borderType: BorderType.RRect,
                    radius: const Radius.circular(8),
                    child: SizedBox(
                      height: 100,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add,
                            color: AppTheme().textColor2,
                          ),
                          SizedBox(width: 8.0.dp),
                          Text('سناریوی جدید',
                            style: AppTheme().textSecondary3Regular,)
                        ],
                      ),
                    ),
                  );
  }

  _itemScenario(Scenario scenario) {
    return Card(
      color: AppTheme().cardBackground,
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(8.0.dp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(scenario.name ?? '', style: AppTheme().textPrimary2Medium,),
            SizedBox(height: 8.0.dp),
            PrimaryButton(text: 'اجرای سناریو', onTap: (){
              widget.logic.runScenario(scenario);
            }),
          ],
        ),
      ),
    );
  }
}
