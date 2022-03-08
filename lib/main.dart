import 'package:flutter/material.dart';

import 'package:iot_project_demo/user_interface.dart';
import 'package:iot_project_demo/data_managers.dart';


Future<void> initializeSettings() async {
  Map<String, String> savedApplicationSettings = await readSettings();
  for (String settingsKey in savedApplicationSettings.keys) {
    applicationSettings[settingsKey] = savedApplicationSettings[settingsKey]!;
  }
}


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeSettings();

  runApp(const App());
}
