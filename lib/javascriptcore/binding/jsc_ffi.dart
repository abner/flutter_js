import 'dart:ffi';
import 'dart:io';

final DynamicLibrary jscLib = Platform.isAndroid
    ? DynamicLibrary.open("libjsc.so")
    : Platform.isIOS || Platform.isMacOS
        ? DynamicLibrary.open("JavaScriptCore.framework/JavaScriptCore")
        : null;
