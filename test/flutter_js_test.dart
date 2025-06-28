import 'package:flutter_js/extensions/fetch.dart';
import 'package:flutter_js/extensions/xhr.dart';
import 'package:flutter_js/flutter_js.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late JavascriptRuntime jsRuntime;

  setUp(() {
    jsRuntime = getJavascriptRuntime(xhr: true);
  });

  tearDown(() {
    try {
      jsRuntime.dispose();
    } on Error catch (_) {}
  });

  test('evaluate javascript', () {
    final result = jsRuntime.evaluate('Math.pow(5,3)');
    print('${result.rawResult}, ${result.stringResult}');
    print(
        '${result.rawResult.runtimeType}, ${result.stringResult.runtimeType}');
    expect(result.rawResult, equals(125));
    expect(result.stringResult, equals('125'));
  });

  test('leak test', () async {
    final jsRt = getJavascriptRuntime();
    jsRt.evaluate('''
    delay = (delayInms) => {
      return new Promise((resolve) => setTimeout(resolve, delayInms));
    }
    ''');
    jsRt.evaluate('''
    async function asyncTest(del = 30) {
      try {
        console.log(`Starting \$\{del\}...`);
        while (del > 0) {
          console.log(del);
          await delay(1000);
          del--;
        }
        console.log(`Done \$\{del\}`);
        return `Done \$\{del\}`;
      } catch (e) {
        console.log(`Error in asyncTest: \$\{e\}`);
        return "Error";
      }
    }
    ''');
    await jsRt.enableFetch();
    jsRt.enableHandlePromises();
    jsRt.enableXhr();
    final promise = await jsRt.evaluateAsync('asyncTest(2)');
    jsRt.executePendingJob();
    JsEvalResult asyncResult = await jsRt.handlePromise(promise);
    print('${asyncResult.stringResult}, ${asyncResult.stringResult}');
    jsRt.dispose();
  });
}
