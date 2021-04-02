import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_js_platform_interface/flutter_js_platform_interface.dart';
import '../flutter_js.dart';
import './xhr.dart';

var _fetchDebug = false;

setFetchDebug(bool value) => _fetchDebug = value;

extension JavascriptRuntimeFetchExtension on FlutterJsPlatform {
  Future<FlutterJsPlatform> enableFetch() async {
    debug('Before enable xhr');
    enableXhr();
    debug('After enable xhr');
    final fetchPolyfill =
        await rootBundle.loadString('packages/flutter_js/assets/js/fetch.js');
    debug('Loaded fetchPolyfill');
    final evalFetchResult = evaluate(fetchPolyfill);
    debug('Eval Fetch Result: $evalFetchResult');
    return this;
  }
}

void debug(String message) {
  if (_fetchDebug) {
    print('JavascriptRuntimeFetchExtension: $message');
  }
}
