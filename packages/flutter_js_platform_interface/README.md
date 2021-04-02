# flutter_js_platform_interface

A common platform interface for the [`flutter_js`][1] plugin.

This interface allows platform-specific implementations of the `flutter_js`
plugin, as well as the plugin itself, to ensure they are supporting the
same interface.

# Usage

To implement a new platform-specific implementation of `flutter_js`, extend
[`FlutterJsPlatform`][2] with an implementation that performs the
platform-specific behavior, and when you register your plugin, set the default
`FlutterJsPlatform` by calling
`FlutterJsPlatform.instance = MyFlutterJsPlatform()`.

[1]: ../../flutter_js
[2]: lib/flutter_js_platform_interface.dart