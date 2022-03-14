import 'package:flutter/material.dart';

import 'package:iot_project_demo/user_interface.dart';
import 'package:iot_project_demo/data_managers.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeSettings();  // initialize application settings

  runApp(const App());
}
