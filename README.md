# Flutter JS plugin

A Javascript engine to use with flutter. It uses quickjs on Android and JavascriptCore on IOS


In this very early stage version we only get the result of evaluated expressions as String.

But it is good enough to take advantage of great javascript libraries such as ajv (json schema validation), moment (DateTime parser and operations) in Flutter applications running on mobile devices, both Android and iOS.

On IOS this library relies on the native JavascriptCore provided by iOS SDK. In Android it uses the amazing and small Javascript Engine QuickJS [https://bellard.org/quickjs/](https://bellard.org/quickjs/) (A spetacular work of the Fabrice Bellard and Charlie Gordon). It was ported to be used in Android through jni in this project i recently found on Github: [https://github.com/seven332/quickjs-android](https://github.com/seven332/quickjs-android). Thanks to [seven332](https://github.com/seven332)



![](docs/flutter_js.png)


## Features:

## Instalation

### iOS

Since flutter_js uses the native JavascriptCore, no action is needed.

### Android

Change the minimum Android sdk version to 18 (or higher) in your `android/app/build.gradle` file.

```
minSdkVersion 18
```


### Example

Here is a small flutter app showing how to evaluate javascript code inside a flutter app



```dart
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_js/flutter_js.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _jsResult = '';
  int _idJsEngine = -1;
  @override
  void initState() {
    super.initState();
    initJsEngine();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initJsEngine() async {
  

    try {
      _idJsEngine = await FlutterJs.initEngine();
    } on PlatformException catch (e) {
      print('Failed to init js engine: ${e.details}');
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;


  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('FlutterJS Example'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text('JS Evaluate Result: $_jsResult\n'),
              SizedBox(height: 20,),
              Padding(padding: EdgeInsets.all(10), child: Text('Click on the big JS Yellow Button to evaluate the expression bellow using the flutter_js plugin'),),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text("Math.trunc(Math.random() * 100).toString();", style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, fontWeight: FontWeight.bold),),
              )
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.transparent, 
          child: Image.asset('assets/js.ico'),
          onPressed: () async {
            try {
              String result = await FlutterJs.evaluate(
                  "Math.trunc(Math.random() * 100).toString();", _idJsEngine);
              setState(() {
                _jsResult = result;
              });
            } on PlatformException catch (e) {
              print('ERRO: ${e.details}');
            }
          },
        ),
      ),
    );
  }
}


```