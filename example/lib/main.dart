import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_js/flutter_js.dart';
import 'package:flutter_js_example/ajv_result_screen.dart';
import 'package:flutter_js_example/form.dart';
import 'package:flutter_js_example/json_viewer.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _jsResult = '';
  int _idJsEngine = -1;

  TextEditingController textController;

  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();
  GlobalKey<FormState> _formKey = GlobalKey();

  Future<dynamic> _loadingFuture;

  @override
  void initState() {
    super.initState();
    textController = TextEditingController();
    _loadingFuture = initJsEngine();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initJsEngine() async {
    try {
      _idJsEngine = await FlutterJs.initEngine();
      String ajvJS = await rootBundle.loadString("assets/js/ajv.js");

      if (Platform.isIOS) {
        await FlutterJs.evaluate("var global = window = {};", _idJsEngine);
      }
      await FlutterJs.evaluate(
          "console = { log: function(){}, error: function(){}, warn: function() {}};",
          _idJsEngine);
      await FlutterJs.evaluate(ajvJS + "", _idJsEngine);
      await FlutterJs.evaluate("""
      var ajv = new global.Ajv({ allErrors: true});
      ajv.addSchema({required: ["name", "age","id", "address"]}, "obj1");
      """, _idJsEngine);
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
        key: _scaffoldKey,
        appBar: AppBar(
          title: const Text('FlutterJS Example'),
        ),
        body: Center(
          child: FutureBuilder(
            future: _loadingFuture,
            builder: (_, snapshot) => snapshot.connectionState ==
                    ConnectionState.waiting
                ? Center(child: Text('Aguarde...'))
                : SingleChildScrollView(
                    child: Column(
                      children: <Widget>[
                        FormWidget(
                            formKey: _formKey,
                            validateFunction:
                                (field, value, data, formWidgetState) {
                              var formData = {};
                              formData.addAll(data);
                              formData.removeWhere(
                                  (key, value) => value.trim().isEmpty);
                              final expression = """ajv.validate(
                                                 "obj1",
                                                 ${json.encode(formData)}
                                                 );
                                                 ajv.errors;
                                                 """;
                              FlutterJs.evaluate(expression, _idJsEngine,
                                      convertTo: "array")
                                  .then((res) {
                                _jsResult = res;

                                if (res == null || res == 'null') {
                                  formWidgetState.setErrorAsync(field, []);
                                  return null;
                                }

                                final result = ValidationResult.listFromJson(
                                    json.decode(res));
                                Timer(
                                    Duration(milliseconds: 100),
                                    () => formWidgetState.setErrorAsync(
                                        field,
                                        result
                                            .where((element) => element.message
                                                .contains("'$field'"))
                                            .toList()));
                              });
                              return [];
                            },
                            fields: [
                              'id',
                              'name',
                              'address',
                              'age',
                            ]),
                      ],
                    ),
                  ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.warning),
          onPressed: () async {
            Navigator.of(_scaffoldKey.currentContext).push(
              MaterialPageRoute(
                builder: (context) => AjvResultScreen(
                  "{\"errors\": ${_jsResult == "" ? null : _jsResult}}",
                  notRoot: false,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class FancyFab extends StatefulWidget {
  final Function() onPressed;
  final String tooltip;
  final IconData icon;

  FancyFab({this.onPressed, this.tooltip, this.icon});

  @override
  _FancyFabState createState() => _FancyFabState();
}

class _FancyFabState extends State<FancyFab>
    with SingleTickerProviderStateMixin {
  bool isOpened = false;
  AnimationController _animationController;
  Animation<Color> _buttonColor;
  Animation<double> _animateIcon;
  Animation<double> _translateButton;
  Curve _curve = Curves.easeOut;
  double _fabHeight = 56.0;

  @override
  initState() {
    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 500))
          ..addListener(() {
            setState(() {});
          });
    _animateIcon =
        Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    _buttonColor = ColorTween(
      begin: Colors.blue,
      end: Colors.red,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(
        0.00,
        1.00,
        curve: Curves.linear,
      ),
    ));
    _translateButton = Tween<double>(
      begin: _fabHeight,
      end: -14.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(
        0.0,
        0.75,
        curve: _curve,
      ),
    ));
    super.initState();
  }

  @override
  dispose() {
    _animationController.dispose();
    super.dispose();
  }

  animate() {
    widget.onPressed();
    if (!isOpened) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
    isOpened = !isOpened;
  }

  Widget add() {
    return Container(
      child: FloatingActionButton(
        heroTag: 'addHero',
        onPressed: null,
        tooltip: 'Add',
        child: Icon(Icons.add),
      ),
    );
  }

  Widget image() {
    return Container(
      child: FloatingActionButton(
        heroTag: 'imageHero',
        onPressed: null,
        tooltip: 'Image',
        child: Icon(Icons.image),
      ),
    );
  }

  Widget inbox() {
    return Container(
      child: FloatingActionButton(
        heroTag: 'inboxHero',
        onPressed: null,
        tooltip: 'Inbox',
        child: Icon(Icons.inbox),
      ),
    );
  }

  Widget toggle() {
    return Container(
      child: FloatingActionButton(
        heroTag: 'toggleHero',
        backgroundColor: _buttonColor.value,
        onPressed: animate,
        tooltip: 'Toggle',
        child: AnimatedIcon(
          icon: AnimatedIcons.menu_close,
          progress: _animateIcon,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        Transform(
          transform: Matrix4.translationValues(
            0.0,
            _translateButton.value * 3.0,
            0.0,
          ),
          child: add(),
        ),
        Transform(
          transform: Matrix4.translationValues(
            0.0,
            _translateButton.value * 2.0,
            0.0,
          ),
          child: image(),
        ),
        Transform(
          transform: Matrix4.translationValues(
            0.0,
            _translateButton.value,
            0.0,
          ),
          child: inbox(),
        ),
        toggle(),
      ],
    );
  }
}
