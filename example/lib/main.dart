import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_js/flutter_js.dart';
import 'package:flutter_js_example/ajv_example.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldState = GlobalKey();

  MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: FlutterJsHomeScreen(),
    );
  }
}

class FlutterJsHomeScreen extends StatefulWidget {
  const FlutterJsHomeScreen({super.key});

  @override
  _FlutterJsHomeScreenState createState() => _FlutterJsHomeScreenState();
}

class _FlutterJsHomeScreenState extends State<FlutterJsHomeScreen> {
  String _jsResult = '';

  final JavascriptRuntime javascriptRuntime =
      getJavascriptRuntime(forceJavascriptCoreOnAndroid: false);

  String? _quickjsVersion;

  Future<String> evalJS() async {
    JsEvalResult jsResult = await javascriptRuntime.evaluateAsync(
      """
            if (typeof MyClass == 'undefined') {
              var MyClass = class  {
                constructor(id) {
                  this.id = id;
                }
                
                getId() { 
                  return this.id;
                }
              }
            }
            async function test() {
              var obj = new MyClass(1);
              var jsonStringified = JSON.stringify(obj);
              var value = Math.trunc(Math.random() * 100).toString();
              var asyncResult = await sendMessage("getDataAsync", JSON.stringify({"count": Math.trunc(Math.random() * 10)}));
              var err;
              try {
                await sendMessage("asyncWithError", "{}");
              } catch(e) {
                err = e.message || e;
              }
              return {"object": jsonStringified, "expression": value, "asyncResult": asyncResult, "expectedError": err};
            }
            test();
            """,
      sourceUrl: 'script.js',
    );
    javascriptRuntime.executePendingJob();
    JsEvalResult asyncResult = await javascriptRuntime.handlePromise(jsResult);
    return asyncResult.stringResult;
  }

  @override
  void initState() {
    super.initState();
    javascriptRuntime.setInspectable(true);
    javascriptRuntime.onMessage('getDataAsync', (args) async {
      await Future.delayed(const Duration(seconds: 1));
      final int count = args['count'];
      Random rnd = Random();
      final result = <Map<String, int>>[];
      for (int i = 0; i < count; i++) {
        result.add({'key$i': rnd.nextInt(100)});
      }
      return result;
    });
    javascriptRuntime.onMessage('asyncWithError', (_) async {
      await Future.delayed(const Duration(milliseconds: 100));
      return Future.error('Some error');
    });
  }

  @override
  void dispose() {
    javascriptRuntime.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FlutterJS Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'JS Evaluate Result:\n\n$_jsResult\n',
              textAlign: TextAlign.center,
            ),
            const SizedBox(
              height: 20,
            ),
            const Padding(
              padding: EdgeInsets.all(10),
              child: Text(
                  'Click on the big JS Yellow Button to evaluate the expression bellow using the flutter_js plugin'),
            ),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                "Math.trunc(Math.random() * 100).toString();",
                style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => AjvExample(
                      //widget.javascriptRuntime,
                      javascriptRuntime),
                ),
              ),
              child: const Text('See Ajv Example'),
            ),
            SizedBox.fromSize(size: const Size(double.maxFinite, 20)),
            ElevatedButton(
              child: const Text('Fetch Remote Data'),
              onPressed: () async {
                var asyncResult = await javascriptRuntime.evaluateAsync("""
                fetch('https://raw.githubusercontent.com/abner/flutter_js/master/FIXED_RESOURCE.txt').then(response => response.text());
              """);
                javascriptRuntime.executePendingJob();
                final promiseResolved =
                    await javascriptRuntime.handlePromise(asyncResult);
                var result = promiseResolved.stringResult;
                setState(() => _quickjsVersion = result);
              },
            ),
            Text(
              'QuickJS Version\n${_quickjsVersion ?? '<NULL>'}',
              textAlign: TextAlign.center,
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        //backgroundColor: Colors.transparent,
        child: Image.asset('assets/js.ico'),
        onPressed: () async {
          final result = await evalJS();
          if (!mounted) return;
          setState(() {
            _jsResult = result;
          });
        },
      ),
    );
  }
}
