import 'package:bms/core/utils/extension.dart';
import 'package:bms/core/values/theme.dart';
import 'package:bms/data/data_sources/local_data_sources/database/model/logger.dart';
import 'package:bms/presentation/components/appbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../logic/logger_logic.dart';

class LoggerScreen extends StatefulWidget {
  late LoggerLogic logic;

  LoggerScreen({super.key});

  @override
  State<StatefulWidget> createState() => _NewPlaceScenariosScreenState();
}

class _NewPlaceScenariosScreenState extends State<LoggerScreen> {
  @override
  void initState() {
    widget.logic = Get.put(LoggerLogic());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LoggerLogic>(builder: (logic) {
      return Scaffold(
        appBar: buildAppBar(),
        body: buildContent(logic),
      );
    });
  }

  Widget buildContent(LoggerLogic logic) {
    return Column(children: [
      Expanded(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Padding(
            padding: EdgeInsetsDirectional.only(start: 12.0.dp, end: 12.0.dp, top: 8.0.dp),
            child: ListView.builder(
              itemCount: widget.logic.logList.length,
              itemBuilder: (ctx, index) {
                return Row(
                  children: [
                    Expanded(
                        flex: 1,
                        child: Text(index.toString(), style: AppTheme().textPrimary4Medium)),
                    Expanded(
                      flex: 13,
                      child: Card(
                        elevation: 0,
                        color: AppTheme().cardBackground,
                        child: Padding(
                            padding: const EdgeInsets.only(
                                right: 10.0, left: 10.0, top: 10.0, bottom: 10.0),
                            child: buildRow(widget.logic.logList[index])),
                      ),
                    )
                  ],
                );
              },
            ),
          ),
        ),
      ),
    ]);
  }

  buildRow(Logger logModel) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(logModel.time ?? '', style: AppTheme().textSecondary4Regular),
            Text(logModel.className ?? '', style: AppTheme().textSecondary4Regular),
          ],
        ),
        SizedBox(height: 4.0.dp),

            Text(logModel.methodName ?? '',
                style: AppTheme().textPrimary3Regular, textAlign: TextAlign.start)
       ,
        SizedBox(height: 4.0.dp),
    Row(
    children: [
        Expanded(
          child: Text(
            logModel.value ?? '',
            style: AppTheme().textPrimary2Medium,
            textAlign: TextAlign.start,
          ),
        ),
    ],),
      ],
    );
  }

  AppBar buildAppBar() {
    return appBar('Logger', actions: <Widget>[
      IconButton(
        icon: const Icon(Icons.delete),
        onPressed: () {
          widget.logic.clearData();
        },
      ),
      IconButton(
        icon: const Icon(Icons.update),
        onPressed: () {
          widget.logic.getLogs();
        },
      ),
    ]);
  }
}
