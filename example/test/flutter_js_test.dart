import 'package:flutter/foundation.dart';
import 'package:flutter_js/flutter_js.dart';
import 'package:flutter_test/flutter_test.dart';

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
