import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_js_example/json_viewer.dart';

class AjvResultScreen extends StatelessWidget {
  const AjvResultScreen(this.jsonString, {super.key, this.notRoot = false});

  final String jsonString;
  final bool notRoot;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Ajv Result')),
        body: SafeArea(
          child: SingleChildScrollView(
              //child: JsonViewerWidget(json.decode(jsonString), notRoot: notRoot )
              child: JsonViewerRoot(
            jsonObj: json.decode(jsonString),
            expandDeep: 4,
          )),
        ));
  }
}
