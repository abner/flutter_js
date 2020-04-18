

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_js/flutter_js.dart';
import 'ajv_result_screen.dart';
import 'form.dart';

class AjvExample extends StatefulWidget {
  AjvExample({Key key}) : super(key: key);

  _AjvExampleState createState() => _AjvExampleState();
}

class _AjvExampleState extends State<AjvExample> {

  String _jsResult = '';
  int _idJsEngine = -1;

  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();
  GlobalKey<FormState> _formKey = GlobalKey();
  GlobalKey<FormWidgetState> _formWidgetKey = GlobalKey();

  Future<dynamic> _loadingFuture;

  @override
  void initState() {
    super.initState();
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
                    var ajv = new global.Ajv({ allErrors: true, coerceTypes: true });
                    ajv.addSchema(
                      {
                        required: ["name", "age","id", "email"], 
                        "properties": {
                          "id": {
                            "minimum": 0,
                            "type": "number" 
                          },
                          "email": {
                            "type": "string",
                            "format": "email"
                          },
                          "age": {
                            "minimum": 0,
                            "type": "number" 
                          }
                     
                        }
                    }, "obj1");
      """, _idJsEngine);
    } on PlatformException catch (e) {
      print('Failed to init js engine: ${e.details}');
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;
  }

  _validateFunctionFor() {
    return (String field, String valor, Map<String, String> data) {
      var formData = {};
      formData.addAll(data);
      formData.removeWhere((key, value) => value.trim().isEmpty);
      final expression = """ajv.validate(
                         "obj1",
                         ${json.encode(formData)}
                         );
                         ajv.errors;
                         """;
      FlutterJs.evaluate(expression, _idJsEngine, convertTo: "array")
          .then((res) {
        _jsResult = res;

        if (res == null || res == 'null') {
          _formWidgetKey.currentState.setErrorAsync(field, []);
          return null;
        }

        final List<ValidationResult> result =
            ValidationResult.listFromJson(json.decode(res));
        _formWidgetKey.currentState.setErrorAsync(
            field,
            result
                .where((element) =>
                    element.message.contains("'$field'") ||
                    element.dataPath == ".$field")
                .toList());
      });
      return null;
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: const Text('Ajv Example'),
        ),
        body: FutureBuilder(
          future: _loadingFuture,
          builder: (_, snapshot) =>
              snapshot.connectionState == ConnectionState.waiting
                  ? Center(child: Text('Aguarde...'))
                  : SingleChildScrollView(
                      child: Column(
                        children: <Widget>[
                          FormWidget(
                              operation: FormWidgetOperation.New,
                              formWidgetKey: _formWidgetKey,
                              formKey: _formKey,
                              validateFunction: _validateFunctionFor(),
                              fields: [
                                'id',
                                'name',
                                'email',
                                'age',
                              ]),
                        ],
                      ),
                    ),
        ),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.info_outline),
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
    );
  }
}