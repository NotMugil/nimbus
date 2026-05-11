import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  HiveService._();

  static const String facesBoxName = 'nimbus.faces.v1';

  static Future<void> init() async {
    await Hive.initFlutter();
  }

  static Future<Box<String>> openStringBox(String name) {
    return Hive.openBox<String>(name);
  }

  static Future<Box<String>> openFacesBox() {
    return openStringBox(facesBoxName);
  }
}
