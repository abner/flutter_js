import 'dart:async';

import 'package:flutter/services.dart';

class FlutterJs {
  static const MethodChannel _channel =
      const MethodChannel('io.abner.flutter_js');
    

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future<int> initEngine() async {
    final int engineId = await _channel.invokeMethod("initEngine", 1);
    return engineId;
  }

  static Future<String> evaluate(String command, int id) async {
    var arguments = {
      "engineId": id,
      "command": command
    };
    final String jsResult = await _channel.invokeMethod("evaluate", arguments); 
    print("JS RESULT : $jsResult");
    return jsResult;
  }
}
