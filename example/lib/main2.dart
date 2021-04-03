import 'package:flutter/material.dart';
import 'package:flutter_js/flutter_js.dart';
import 'package:flutter_js_example/ajv_example.dart';
//import 'package:flutter_qjs/flutter_qjs.dart';

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

  late FlutterJsPlatform javascriptRuntime;

  FlutterJsHomeScreen() {
    javascriptRuntime = getJavascriptRuntime();
    executeJS();
    javascriptRuntime.onMessage('ConsoleLog2', (args) {
      print('ConsoleLog2 (Dart Side): $args');
      // return json.encode(args);
    });
    executeJS();
    Future.delayed(Duration(seconds: 2), executeJS);
  }

  String executeJS() {
    final rs = javascriptRuntime
        .evaluate("""Math.trunc(Math.random() * 100).toString();""");
    return rs.stringResult;
  }
}

class _FlutterJsHomeScreenState extends State<FlutterJsHomeScreen> {
  String _jsResult = '';

  //FlutterQjs engine;

  @override
  void initState() {
    // engine = FlutterQjs(
    //   stackSize: 1024 * 1024, // change stack size here.
    // );
    // engine.dispatch();
    super.initState();
  }

  @override
  dispose() {
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
            Text('JS Evaluate Result: $_jsResult\n'),
            SizedBox(
              height: 20,
            ),
            Padding(
              padding: EdgeInsets.all(10),
              child: Text(
                  'Click on the big JS Yellow Button to evaluate the expression bellow using the flutter_js plugin'),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Math.trunc(Math.random() * 100).toString();",
                style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.bold),
              ),
            ),
            RaisedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => AjvExample(
                    widget.javascriptRuntime,
                  ),
                ),
              ),
              child: const Text('See Ajv Example'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.transparent,
        child: Image.asset('assets/js.ico'),
        onPressed: () {
          var val = widget.executeJS();
          Future.delayed(Duration(seconds: 1), () {
            var val2 = widget.executeJS();
            print('VAL 2: $val2');
          });
          setState(() {
            _jsResult = val;
          });
        },
      ),
    );
  }
}
