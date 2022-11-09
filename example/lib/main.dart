import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_js/flutter_js.dart';
import 'package:flutter_js_example/ajv_example.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  GlobalKey<ScaffoldState> scaffoldState = GlobalKey();
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FlutterJsHomeScreen(),
    );
  }
}

class FlutterJsHomeScreen extends StatefulWidget {
  @override
  _FlutterJsHomeScreenState createState() => _FlutterJsHomeScreenState();
}

class _FlutterJsHomeScreenState extends State<FlutterJsHomeScreen> {
  String _jsResult = '';

  final JavascriptRuntime javascriptRuntime = getJavascriptRuntime();

  String? _quickjsVersion;

  Process? _process;
  final bool _processInitialized = false;
  String evalJS() {
    String jsResult = javascriptRuntime.evaluate("""
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
            var obj = new MyClass(1);
            var jsonStringified = JSON.stringify(obj);
            var value = Math.trunc(Math.random() * 100).toString();
            JSON.stringify({ "object": jsonStringified, "expression": value});
            """).stringResult;
    return jsResult;
  }

  @override
  void initState() {
    super.initState();

    // widget.javascriptRuntime.onMessage('ConsoleLog2', (args) {
    //   print('ConsoleLog2 (Dart Side): $args');
    //   return json.encode(args);
    // });
  }

  @override
  dispose() {
    super.dispose();
    //widget.javascriptRuntime.dispose();
    javascriptRuntime.dispose();
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
        onPressed: () {
          setState(() {
            // _jsResult = widget.evalJS();
            // Future.delayed(Duration(milliseconds: 599), widget.evalJS);
            _jsResult = evalJS();
            Future.delayed(const Duration(milliseconds: 599), evalJS);
          });
        },
      ),
    );
  }
}
