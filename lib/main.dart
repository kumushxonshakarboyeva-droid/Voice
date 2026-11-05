import 'package:flutter/material.dart';

import 'app.dart';
import 'services/app_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = AppController();
  await controller.initialize();
  runApp(VoiceLifeApp(controller: controller));
}
