// ignore_for_file: constant_identifier_names, unused_local_variable

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_js/flutter_js.dart';
import 'package:flutter_test/flutter_test.dart';

String one = '1' * 514;
String two = '2' * 515;
String three = '3' * 516;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late JavascriptRuntime jsRuntime;

  setUp(() {
    jsRuntime = getJavascriptRuntime();
  });

  tearDown(() {
    try {
      jsRuntime.dispose();
    } on Error catch (_) {}
  });

  Future<dynamic> longString() async {
    final code = '''// js
    (async function() {
        let ret = '$one' + '$two' + '$three'
        return ret
    })()
    ''';

    const int PROMISE_TIMEOUT = 120;
    try {
      var res = await jsRuntime.evaluateAsync(code, sourceUrl: '<test eval>');
      jsRuntime.executePendingJob();
      final prom = await jsRuntime.handlePromise(res,
          timeout: const Duration(seconds: PROMISE_TIMEOUT));
      var result = await prom.rawResult;
      if (result is JSError || prom.isError) {
        throw Exception('JSError: $result');
      }
      return result;
    } on PlatformException catch (e) {
      debugPrint('Platform exception [runJsCodeAsync]: ${e.details}');
      rethrow;
    } catch (e) {
      debugPrint('Exception [runJsCodeAsync]: rethrow');
      rethrow;
    }
  }

  test('string concat with > 512 chars', () async {
    final result = await longString();
    String match = one + two + three;
    expect(result, equals(match));
  });

  test('evaluate javascript', () {
    final result = jsRuntime.evaluate('Math.pow(5,3)');
    if (kDebugMode) {
      print('${result.rawResult}, ${result.stringResult}');
      print(
          '${result.rawResult.runtimeType}, ${result.stringResult.runtimeType}');
    }
    expect(result.rawResult, equals(125));
    expect(result.stringResult, equals('125'));
  });
}
