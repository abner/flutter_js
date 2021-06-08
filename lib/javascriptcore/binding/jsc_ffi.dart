import 'dart:ffi';
import 'dart:io';

class JscFfi {
  /// You can replace it with the version you want
  static DynamicLibrary lib = Platform.isIOS || Platform.isMacOS
      ? DynamicLibrary.open('JavaScriptCore.framework/JavaScriptCore')
      : Platform.isWindows
          ? DynamicLibrary.open('JavaScriptCore.dll')
          : Platform.isLinux
              ? DynamicLibrary.open('libjavascriptcoregtk-4.0.so.18')
              : DynamicLibrary.open('libjsc.so');
}
