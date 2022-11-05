import 'dart:async';

import 'package:flutter/services.dart';

class Example {
  static const MethodChannel _channel = MethodChannel('example');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
